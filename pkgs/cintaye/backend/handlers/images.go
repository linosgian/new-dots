package handlers

import (
	"database/sql"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"cintaye/middleware"

	"github.com/go-chi/chi/v5"
)

type ImageHandler struct {
	db        *sql.DB
	imagesDir string
}

func NewImageHandler(db *sql.DB, imagesDir string) *ImageHandler {
	return &ImageHandler{db: db, imagesDir: imagesDir}
}

func (h *ImageHandler) Upload(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	// Verify user belongs to recipe's household
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

	var count int
	h.db.QueryRowContext(r.Context(),
		"SELECT COUNT(*) FROM household_members WHERE household_id = ? AND user_id = ?",
		hhID, user.ID,
	).Scan(&count)
	if count == 0 {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 10<<20) // 10 MB
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		jsonError(w, "file too large", http.StatusRequestEntityTooLarge)
		return
	}

	file, header, err := r.FormFile("image")
	if err != nil {
		jsonError(w, "image field required", http.StatusBadRequest)
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(header.Filename))
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".webp": true, ".gif": true}
	if !allowed[ext] {
		jsonError(w, "unsupported image type", http.StatusBadRequest)
		return
	}

	filename := fmt.Sprintf("%d_%d%s", id, time.Now().UnixMilli(), ext)
	dst := filepath.Join(h.imagesDir, filename)

	out, err := os.Create(dst)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer out.Close()

	if _, err := io.Copy(out, file); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	// Delete old image if present
	var oldPath string
	h.db.QueryRowContext(r.Context(), "SELECT COALESCE(image_path,'') FROM recipes WHERE id = ?", id).Scan(&oldPath)
	if oldPath != "" {
		os.Remove(filepath.Join(h.imagesDir, oldPath))
	}

	if _, err := h.db.ExecContext(r.Context(),
		"UPDATE recipes SET image_path = ?, updated_at = ? WHERE id = ?",
		filename, time.Now(), id,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"image_path": filename})
}
