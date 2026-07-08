package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"cintaye/jsonld"
	"cintaye/middleware"
	"cintaye/models"
)

type ImportHandler struct {
	db        *sql.DB
	imagesDir string
}

func NewImportHandler(db *sql.DB, imagesDir string) *ImportHandler {
	return &ImportHandler{db: db, imagesDir: imagesDir}
}

func (h *ImportHandler) Import(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())

	var req struct {
		URL    string   `json:"url"`
		URLs   []string `json:"urls"`
		JSONLD string   `json:"jsonld"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request", http.StatusBadRequest)
		return
	}

	// Batch URL import
	if len(req.URLs) > 0 {
		type result struct {
			URL    string         `json:"url"`
			Recipe *models.Recipe `json:"recipe,omitempty"`
			Error  string         `json:"error,omitempty"`
		}
		results := make([]result, 0, len(req.URLs))
		for _, u := range req.URLs {
			recipe, err := h.importURL(r, u, user)
			if err != nil {
				results = append(results, result{URL: u, Error: err.Error()})
			} else {
				results = append(results, result{URL: u, Recipe: &recipe})
			}
		}
		jsonOK(w, results)
		return
	}

	// Single import
	var parsed *jsonld.Recipe
	var err error
	switch {
	case req.URL != "":
		parsed, err = jsonld.ParseURL(req.URL)
	case req.JSONLD != "":
		parsed, err = jsonld.ParseText(req.JSONLD)
	default:
		jsonError(w, "url or jsonld required", http.StatusBadRequest)
		return
	}
	if err != nil {
		jsonError(w, "could not parse recipe: "+err.Error(), http.StatusUnprocessableEntity)
		return
	}

	recipe, err := h.saveRecipe(r, parsed, user)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	w.Header().Set("Content-Type", "application/json")
	jsonOK(w, recipe)
}

// importURL parses and saves a single URL, returning the created Recipe.
func (h *ImportHandler) importURL(r *http.Request, url string, user *models.User) (models.Recipe, error) {
	parsed, err := jsonld.ParseURL(url)
	if err != nil {
		return models.Recipe{}, fmt.Errorf("could not parse recipe: %w", err)
	}
	return h.saveRecipe(r, parsed, user)
}

// saveRecipe persists a parsed JSON-LD recipe and returns the full model.
func (h *ImportHandler) saveRecipe(r *http.Request, parsed *jsonld.Recipe, user *models.User) (models.Recipe, error) {
	var householdID int64
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT household_id FROM household_members WHERE user_id = ? LIMIT 1", user.ID,
	).Scan(&householdID); err != nil {
		return models.Recipe{}, fmt.Errorf("no household")
	}

	result, err := h.db.ExecContext(r.Context(), `
		INSERT INTO recipes (household_id, title, description, prep_time_minutes, cook_time_minutes,
		                     total_time_minutes, servings, source_url, created_by)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, householdID, parsed.Title, parsed.Description,
		parsed.PrepTimeMinutes, parsed.CookTimeMinutes, parsed.TotalTimeMinutes,
		parsed.Servings, parsed.SourceURL, user.ID,
	)
	if err != nil {
		return models.Recipe{}, err
	}
	recipeID, _ := result.LastInsertId()

	if parsed.ImageURL != "" {
		if filename, err := downloadImage(parsed.ImageURL, recipeID, h.imagesDir); err == nil {
			h.db.ExecContext(r.Context(),
				"UPDATE recipes SET image_path = ? WHERE id = ?", filename, recipeID,
			)
		}
	}

	if len(parsed.Ingredients) > 0 {
		secRes, err := h.db.ExecContext(r.Context(),
			"INSERT INTO recipe_sections (recipe_id, kind, title, position) VALUES (?, 'ingredients', NULL, 1)",
			recipeID,
		)
		if err != nil {
			return models.Recipe{}, err
		}
		sectionID, _ := secRes.LastInsertId()
		for i, raw := range parsed.Ingredients {
			amount, unit, name, note := jsonld.ToIngredientParts(raw)
			h.db.ExecContext(r.Context(),
				"INSERT INTO ingredients (section_id, position, amount, unit, name, note) VALUES (?, ?, ?, ?, ?, ?)",
				sectionID, i+1, amount, unit, name, note,
			)
		}
	}

	for pos, group := range parsed.InstructionGroups {
		titleVal := sql.NullString{String: group.Name, Valid: group.Name != ""}
		secRes, err := h.db.ExecContext(r.Context(),
			"INSERT INTO recipe_sections (recipe_id, kind, title, position) VALUES (?, 'instructions', ?, ?)",
			recipeID, titleVal, pos+1,
		)
		if err != nil {
			return models.Recipe{}, err
		}
		sectionID, _ := secRes.LastInsertId()
		for j, step := range group.Steps {
			h.db.ExecContext(r.Context(),
				"INSERT INTO instructions (section_id, position, body) VALUES (?, ?, ?)",
				sectionID, j+1, step,
			)
		}
	}

	rh := &RecipeHandler{db: h.db}
	return rh.loadRecipe(r, recipeID, user, 1.0)
}

func downloadImage(imageURL string, recipeID int64, dir string) (string, error) {
	client := &http.Client{Timeout: 20 * time.Second}
	resp, err := client.Get(imageURL)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("image fetch %d", resp.StatusCode)
	}

	ext := ".jpg"
	ct := strings.ToLower(resp.Header.Get("Content-Type"))
	switch {
	case strings.Contains(ct, "png"):
		ext = ".png"
	case strings.Contains(ct, "webp"):
		ext = ".webp"
	case strings.Contains(ct, "gif"):
		ext = ".gif"
	}
	if ext == ".jpg" {
		if u := strings.ToLower(imageURL); strings.Contains(u, ".png") {
			ext = ".png"
		} else if strings.Contains(u, ".webp") {
			ext = ".webp"
		}
	}

	filename := fmt.Sprintf("%d_%d%s", recipeID, time.Now().UnixMilli(), ext)
	dst := filepath.Join(dir, filename)

	f, err := os.Create(dst)
	if err != nil {
		return "", err
	}
	defer f.Close()

	if _, err := io.Copy(f, resp.Body); err != nil {
		os.Remove(dst)
		return "", err
	}
	return filename, nil
}
