package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"cintaye/middleware"
	"cintaye/models"

	"github.com/go-chi/chi/v5"
)

type RecipeHandler struct {
	db        *sql.DB
	imagesDir string
}

func NewRecipeHandler(db *sql.DB, imagesDir string) *RecipeHandler {
	return &RecipeHandler{db: db, imagesDir: imagesDir}
}

type recipeRequest struct {
	Title            string           `json:"title"`
	Description      string           `json:"description"`
	PrepTimeMinutes  *int             `json:"prep_time_minutes"`
	CookTimeMinutes  *int             `json:"cook_time_minutes"`
	TotalTimeMinutes *int             `json:"total_time_minutes"`
	Servings         *int             `json:"servings"`
	SourceURL        string           `json:"source_url"`
	Tags             []string         `json:"tags"`
	Sections         []sectionRequest `json:"sections"`
}

type sectionRequest struct {
	Kind         string               `json:"kind"`
	Title        string               `json:"title"`
	Position     int                  `json:"position"`
	Ingredients  []ingredientRequest  `json:"ingredients"`
	Instructions []instructionRequest `json:"instructions"`
}

type ingredientRequest struct {
	Position int      `json:"position"`
	Amount   *float64 `json:"amount"`
	Unit     string   `json:"unit"`
	Name     string   `json:"name"`
	Note     string   `json:"note"`
}

type instructionRequest struct {
	Position int    `json:"position"`
	Body     string `json:"body"`
}

func (h *RecipeHandler) List(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())

	query := r.URL.Query().Get("q")
	tag := r.URL.Query().Get("tag")

	rows, err := h.db.QueryContext(r.Context(), `
		SELECT r.id, r.household_id, r.title, r.description,
		       r.prep_time_minutes, r.cook_time_minutes, r.total_time_minutes,
		       r.servings, r.image_path, r.source_url, r.created_by, r.created_at, r.updated_at
		FROM recipes r
		WHERE (
			r.household_id = (
				SELECT household_id FROM household_members WHERE user_id = ? ORDER BY ROWID LIMIT 1
			)
			OR ? = 1
		)
		AND (? = '' OR r.title LIKE '%' || ? || '%')
		AND (? = '' OR r.id IN (
			SELECT rt.recipe_id FROM recipe_tags rt
			JOIN tags t ON t.id = rt.tag_id WHERE t.name = ?
		))
		ORDER BY r.updated_at DESC
	`, user.ID,
		boolToInt(user.ShowOtherHouseholds),
		query, query,
		tag, tag,
	)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	recipes := []models.Recipe{}
	for rows.Next() {
		r, err := scanRecipeRow(rows)
		if err != nil {
			jsonError(w, "internal error", http.StatusInternalServerError)
			return
		}
		recipes = append(recipes, r)
	}

	// Attach tags to each recipe
	for i := range recipes {
		recipes[i].Tags = h.loadTags(recipes[i].ID)
	}

	jsonOK(w, recipes)
}

func (h *RecipeHandler) Get(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	scaleParam := r.URL.Query().Get("scale")
	scale := 1.0
	if scaleParam != "" {
		if s, err := strconv.ParseFloat(scaleParam, 64); err == nil && s > 0 {
			scale = s
		}
	}

	recipe, err := h.loadRecipe(r, id, user, scale)
	if err == sql.ErrNoRows {
		jsonError(w, "not found", http.StatusNotFound)
		return
	} else if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	jsonOK(w, recipe)
}

func (h *RecipeHandler) Create(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	var req recipeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Title == "" {
		jsonError(w, "title required", http.StatusBadRequest)
		return
	}

	// Get user's primary household (first one they belong to)
	var householdID int64
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT household_id FROM household_members WHERE user_id = ? LIMIT 1", user.ID,
	).Scan(&householdID); err != nil {
		jsonError(w, "no household", http.StatusBadRequest)
		return
	}

	result, err := h.db.ExecContext(r.Context(), `
		INSERT INTO recipes (household_id, title, description, prep_time_minutes, cook_time_minutes,
		                     total_time_minutes, servings, source_url, created_by)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, householdID, req.Title, req.Description, req.PrepTimeMinutes, req.CookTimeMinutes,
		req.TotalTimeMinutes, req.Servings, req.SourceURL, user.ID,
	)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	recipeID, _ := result.LastInsertId()

	if err := h.saveSections(r, recipeID, req.Sections); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	if err := h.saveTags(r, recipeID, req.Tags); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	recipe, err := h.loadRecipe(r, recipeID, user, 1.0)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	jsonOK(w, recipe)
}

func (h *RecipeHandler) Update(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	// Verify ownership (must be in same household)
	var hhID int64
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT household_id FROM recipes WHERE id = ?", id,
	).Scan(&hhID); err == sql.ErrNoRows {
		jsonError(w, "not found", http.StatusNotFound)
		return
	} else if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	if !h.userInHousehold(r, user.ID, hhID) {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	var req recipeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Title == "" {
		jsonError(w, "title required", http.StatusBadRequest)
		return
	}

	if _, err := h.db.ExecContext(r.Context(), `
		UPDATE recipes SET title=?, description=?, prep_time_minutes=?, cook_time_minutes=?,
		                   total_time_minutes=?, servings=?, source_url=?, updated_at=?
		WHERE id=?
	`, req.Title, req.Description, req.PrepTimeMinutes, req.CookTimeMinutes,
		req.TotalTimeMinutes, req.Servings, req.SourceURL, time.Now(), id,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	// Replace sections and tags
	if _, err := h.db.ExecContext(r.Context(),
		"DELETE FROM recipe_sections WHERE recipe_id = ?", id,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	if _, err := h.db.ExecContext(r.Context(),
		"DELETE FROM recipe_tags WHERE recipe_id = ?", id,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	if err := h.saveSections(r, id, req.Sections); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	if err := h.saveTags(r, id, req.Tags); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	recipe, err := h.loadRecipe(r, id, user, 1.0)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	jsonOK(w, recipe)
}

func (h *RecipeHandler) Delete(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	var hhID int64
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT household_id FROM recipes WHERE id = ?", id,
	).Scan(&hhID); err == sql.ErrNoRows {
		jsonError(w, "not found", http.StatusNotFound)
		return
	} else if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	if !h.userInHousehold(r, user.ID, hhID) {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	if _, err := h.db.ExecContext(r.Context(), "DELETE FROM recipes WHERE id = ?", id); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"ok": "true"})
}

// --- helpers ---

func (h *RecipeHandler) loadRecipe(r *http.Request, id int64, user *models.User, scale float64) (models.Recipe, error) {
	var recipe models.Recipe
	var imagePath, sourceURL, description sql.NullString
	err := h.db.QueryRowContext(r.Context(), `
		SELECT r.id, r.household_id, r.title, r.description,
		       r.prep_time_minutes, r.cook_time_minutes, r.total_time_minutes,
		       r.servings, r.image_path, r.source_url, r.created_by, r.created_at, r.updated_at
		FROM recipes r
		WHERE r.id = ? AND (
			r.household_id IN (SELECT household_id FROM household_members WHERE user_id = ?)
			OR ? = 1
		)
	`, id, user.ID, boolToInt(user.ShowOtherHouseholds),
	).Scan(
		&recipe.ID, &recipe.HouseholdID, &recipe.Title, &description,
		&recipe.PrepTimeMinutes, &recipe.CookTimeMinutes, &recipe.TotalTimeMinutes,
		&recipe.Servings, &imagePath, &sourceURL,
		&recipe.CreatedBy, &recipe.CreatedAt, &recipe.UpdatedAt,
	)
	if err != nil {
		return recipe, err
	}
	recipe.Description = description.String
	recipe.ImagePath = imagePath.String
	recipe.SourceURL = sourceURL.String

	recipe.Sections, err = h.loadSections(r, id, scale)
	if err != nil {
		return recipe, err
	}
	recipe.Tags = h.loadTags(id)
	return recipe, nil
}

func (h *RecipeHandler) loadSections(r *http.Request, recipeID int64, scale float64) ([]models.Section, error) {
	rows, err := h.db.QueryContext(r.Context(),
		"SELECT id, recipe_id, kind, COALESCE(title,''), position FROM recipe_sections WHERE recipe_id = ? ORDER BY position",
		recipeID,
	)
	if err != nil {
		return nil, err
	}

	// Collect all section rows before closing the cursor — inner queries below need
	// the connection, and running them while rows is open deadlocks with MaxOpenConns(1).
	var sections []models.Section
	for rows.Next() {
		var s models.Section
		if err := rows.Scan(&s.ID, &s.RecipeID, &s.Kind, &s.Title, &s.Position); err != nil {
			rows.Close()
			return nil, err
		}
		sections = append(sections, s)
	}
	rows.Close()

	for i := range sections {
		if sections[i].Kind == "ingredients" {
			sections[i].Ingredients, err = h.loadIngredients(r, sections[i].ID, scale)
		} else {
			sections[i].Instructions, err = h.loadInstructions(r, sections[i].ID)
		}
		if err != nil {
			return nil, err
		}
	}
	return sections, nil
}

func (h *RecipeHandler) loadIngredients(r *http.Request, sectionID int64, scale float64) ([]models.Ingredient, error) {
	rows, err := h.db.QueryContext(r.Context(),
		"SELECT id, section_id, position, amount, COALESCE(unit,''), name, COALESCE(note,'') FROM ingredients WHERE section_id = ? ORDER BY position",
		sectionID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Ingredient
	for rows.Next() {
		var ing models.Ingredient
		var amount sql.NullFloat64
		if err := rows.Scan(&ing.ID, &ing.SectionID, &ing.Position, &amount, &ing.Unit, &ing.Name, &ing.Note); err != nil {
			return nil, err
		}
		if amount.Valid {
			scaled := amount.Float64 * scale
			ing.Amount = &scaled
		}
		items = append(items, ing)
	}
	return items, nil
}

func (h *RecipeHandler) loadInstructions(r *http.Request, sectionID int64) ([]models.Instruction, error) {
	rows, err := h.db.QueryContext(r.Context(),
		"SELECT id, section_id, position, body FROM instructions WHERE section_id = ? ORDER BY position",
		sectionID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Instruction
	for rows.Next() {
		var inst models.Instruction
		if err := rows.Scan(&inst.ID, &inst.SectionID, &inst.Position, &inst.Body); err != nil {
			return nil, err
		}
		items = append(items, inst)
	}
	return items, nil
}

func (h *RecipeHandler) loadTags(recipeID int64) []string {
	rows, err := h.db.Query(
		"SELECT t.name FROM tags t JOIN recipe_tags rt ON rt.tag_id = t.id WHERE rt.recipe_id = ? ORDER BY t.name",
		recipeID,
	)
	if err != nil {
		return nil
	}
	defer rows.Close()
	var tags []string
	for rows.Next() {
		var name string
		if rows.Scan(&name) == nil {
			tags = append(tags, name)
		}
	}
	return tags
}

func (h *RecipeHandler) saveSections(r *http.Request, recipeID int64, sections []sectionRequest) error {
	for _, s := range sections {
		if s.Kind != "ingredients" && s.Kind != "instructions" {
			continue
		}
		titleVal := sql.NullString{String: s.Title, Valid: s.Title != ""}
		res, err := h.db.ExecContext(r.Context(),
			"INSERT INTO recipe_sections (recipe_id, kind, title, position) VALUES (?, ?, ?, ?)",
			recipeID, s.Kind, titleVal, s.Position,
		)
		if err != nil {
			return err
		}
		sectionID, _ := res.LastInsertId()

		if s.Kind == "ingredients" {
			for _, ing := range s.Ingredients {
				if _, err := h.db.ExecContext(r.Context(),
					"INSERT INTO ingredients (section_id, position, amount, unit, name, note) VALUES (?, ?, ?, ?, ?, ?)",
					sectionID, ing.Position, ing.Amount, ing.Unit, ing.Name, ing.Note,
				); err != nil {
					return err
				}
			}
		} else {
			for _, inst := range s.Instructions {
				if _, err := h.db.ExecContext(r.Context(),
					"INSERT INTO instructions (section_id, position, body) VALUES (?, ?, ?)",
					sectionID, inst.Position, inst.Body,
				); err != nil {
					return err
				}
			}
		}
	}
	return nil
}

func (h *RecipeHandler) saveTags(r *http.Request, recipeID int64, tags []string) error {
	for _, name := range tags {
		if name == "" {
			continue
		}
		var tagID int64
		err := h.db.QueryRowContext(r.Context(), "SELECT id FROM tags WHERE name = ?", name).Scan(&tagID)
		if err == sql.ErrNoRows {
			res, err := h.db.ExecContext(r.Context(), "INSERT INTO tags (name) VALUES (?)", name)
			if err != nil {
				return err
			}
			tagID, _ = res.LastInsertId()
		} else if err != nil {
			return err
		}
		if _, err := h.db.ExecContext(r.Context(),
			"INSERT OR IGNORE INTO recipe_tags (recipe_id, tag_id) VALUES (?, ?)", recipeID, tagID,
		); err != nil {
			return err
		}
	}
	return nil
}

func (h *RecipeHandler) userInHousehold(r *http.Request, userID, householdID int64) bool {
	var count int
	h.db.QueryRowContext(r.Context(),
		"SELECT COUNT(*) FROM household_members WHERE household_id = ? AND user_id = ?",
		householdID, userID,
	).Scan(&count)
	return count > 0
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

type recipeRow interface {
	Scan(...any) error
}

func scanRecipeRow(row recipeRow) (models.Recipe, error) {
	var r models.Recipe
	var imagePath, sourceURL, description sql.NullString
	err := row.Scan(
		&r.ID, &r.HouseholdID, &r.Title, &description,
		&r.PrepTimeMinutes, &r.CookTimeMinutes, &r.TotalTimeMinutes,
		&r.Servings, &imagePath, &sourceURL,
		&r.CreatedBy, &r.CreatedAt, &r.UpdatedAt,
	)
	if err != nil {
		return r, err
	}
	r.Description = description.String
	r.ImagePath = imagePath.String
	r.SourceURL = sourceURL.String
	return r, nil
}
