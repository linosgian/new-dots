package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"

	"cintaye/middleware"
	"cintaye/models"

	"github.com/go-chi/chi/v5"
)

type CommentHandler struct {
	db *sql.DB
}

func NewCommentHandler(db *sql.DB) *CommentHandler {
	return &CommentHandler{db: db}
}

func (h *CommentHandler) List(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	recipeID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	// Verify recipe is accessible
	if !h.recipeAccessible(r, recipeID, user) {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}

	rows, err := h.db.QueryContext(r.Context(), `
		SELECT c.id, c.recipe_id, c.user_id, u.username, c.body, c.created_at
		FROM comments c
		JOIN users u ON u.id = c.user_id
		WHERE c.recipe_id = ?
		ORDER BY c.created_at ASC
	`, recipeID)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	comments := []models.Comment{}
	for rows.Next() {
		var c models.Comment
		if err := rows.Scan(&c.ID, &c.RecipeID, &c.UserID, &c.Username, &c.Body, &c.CreatedAt); err != nil {
			jsonError(w, "internal error", http.StatusInternalServerError)
			return
		}
		comments = append(comments, c)
	}
	jsonOK(w, comments)
}

func (h *CommentHandler) Create(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	recipeID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	if !h.recipeAccessible(r, recipeID, user) {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}

	var req struct {
		Body string `json:"body"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Body == "" {
		jsonError(w, "body required", http.StatusBadRequest)
		return
	}

	result, err := h.db.ExecContext(r.Context(),
		"INSERT INTO comments (recipe_id, user_id, body) VALUES (?, ?, ?)",
		recipeID, user.ID, req.Body,
	)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	id, _ := result.LastInsertId()

	var c models.Comment
	h.db.QueryRowContext(r.Context(), `
		SELECT c.id, c.recipe_id, c.user_id, u.username, c.body, c.created_at
		FROM comments c JOIN users u ON u.id = c.user_id WHERE c.id = ?
	`, id).Scan(&c.ID, &c.RecipeID, &c.UserID, &c.Username, &c.Body, &c.CreatedAt)

	w.WriteHeader(http.StatusCreated)
	jsonOK(w, c)
}

func (h *CommentHandler) Delete(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	id, err := strconv.ParseInt(chi.URLParam(r, "commentId"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	var ownerID int64
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT user_id FROM comments WHERE id = ?", id,
	).Scan(&ownerID); err == sql.ErrNoRows {
		jsonError(w, "not found", http.StatusNotFound)
		return
	} else if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	if ownerID != user.ID {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	h.db.ExecContext(r.Context(), "DELETE FROM comments WHERE id = ?", id)
	jsonOK(w, map[string]string{"ok": "true"})
}

func (h *CommentHandler) recipeAccessible(r *http.Request, recipeID int64, user *models.User) bool {
	var count int
	h.db.QueryRowContext(r.Context(), `
		SELECT COUNT(*) FROM recipes r
		JOIN household_members hm ON hm.household_id = r.household_id
		WHERE r.id = ? AND (hm.user_id = ? OR ? = 1)
	`, recipeID, user.ID, boolToInt(user.ShowOtherHouseholds)).Scan(&count)
	return count > 0
}

type TagHandler struct {
	db *sql.DB
}

func NewTagHandler(db *sql.DB) *TagHandler {
	return &TagHandler{db: db}
}

func (h *TagHandler) List(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())

	rows, err := h.db.QueryContext(r.Context(), `
		SELECT DISTINCT t.name FROM tags t
		JOIN recipe_tags rt ON rt.tag_id = t.id
		JOIN recipes rec ON rec.id = rt.recipe_id
		JOIN household_members hm ON hm.household_id = rec.household_id
		WHERE hm.user_id = ?
		ORDER BY t.name
	`, user.ID)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	tags := []string{}
	for rows.Next() {
		var name string
		if rows.Scan(&name) == nil {
			tags = append(tags, name)
		}
	}
	jsonOK(w, tags)
}
