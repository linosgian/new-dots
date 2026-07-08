package handlers

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"cintaye/middleware"
	"cintaye/models"

	"github.com/go-chi/chi/v5"
)

type HouseholdHandler struct {
	db *sql.DB
}

func NewHouseholdHandler(db *sql.DB) *HouseholdHandler {
	return &HouseholdHandler{db: db}
}

func (h *HouseholdHandler) Create(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	if !user.IsAdmin {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Name == "" {
		jsonError(w, "name required", http.StatusBadRequest)
		return
	}

	result, err := h.db.ExecContext(r.Context(),
		"INSERT INTO households (name, owner_id) VALUES (?, ?)", req.Name, user.ID,
	)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	id, _ := result.LastInsertId()

	if _, err := h.db.ExecContext(r.Context(),
		"INSERT INTO household_members (household_id, user_id) VALUES (?, ?)", id, user.ID,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	jsonOK(w, models.Household{ID: id, Name: req.Name, OwnerID: user.ID})
}

func (h *HouseholdHandler) Mine(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())

	rows, err := h.db.QueryContext(r.Context(), `
		SELECT hh.id, hh.name, hh.owner_id, hh.created_at
		FROM households hh
		JOIN household_members hm ON hm.household_id = hh.id
		WHERE hm.user_id = ?
	`, user.ID)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	households := []models.Household{}
	for rows.Next() {
		var hh models.Household
		if err := rows.Scan(&hh.ID, &hh.Name, &hh.OwnerID, &hh.CreatedAt); err != nil {
			jsonError(w, "internal error", http.StatusInternalServerError)
			return
		}
		households = append(households, hh)
	}
	jsonOK(w, households)
}

func (h *HouseholdHandler) GenerateInvite(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	hhID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	// Verify user is a member
	var count int
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT COUNT(*) FROM household_members WHERE household_id = ? AND user_id = ?",
		hhID, user.ID,
	).Scan(&count); err != nil || count == 0 {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	b := make([]byte, 8)
	if _, err := rand.Read(b); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	code := hex.EncodeToString(b)
	expires := time.Now().Add(7 * 24 * time.Hour)

	if _, err := h.db.ExecContext(r.Context(),
		"INSERT INTO household_invites (code, household_id, created_by, expires_at) VALUES (?, ?, ?, ?)",
		code, hhID, user.ID, expires,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"code": code, "expires_at": expires})
}

func (h *HouseholdHandler) Join(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	var req struct {
		Code string `json:"code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Code == "" {
		jsonError(w, "code required", http.StatusBadRequest)
		return
	}

	var invite models.HouseholdInvite
	err := h.db.QueryRowContext(r.Context(),
		"SELECT code, household_id, created_by, expires_at, used_at FROM household_invites WHERE code = ?",
		req.Code,
	).Scan(&invite.Code, &invite.HouseholdID, &invite.CreatedBy, &invite.ExpiresAt, &invite.UsedAt)
	if err != nil {
		jsonError(w, "invalid code", http.StatusNotFound)
		return
	}

	if invite.UsedAt != nil {
		jsonError(w, "invite already used", http.StatusGone)
		return
	}
	if invite.ExpiresAt != nil && invite.ExpiresAt.Before(time.Now()) {
		jsonError(w, "invite expired", http.StatusGone)
		return
	}

	// Upsert membership
	if _, err := h.db.ExecContext(r.Context(),
		"INSERT OR IGNORE INTO household_members (household_id, user_id) VALUES (?, ?)",
		invite.HouseholdID, user.ID,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	now := time.Now()
	if _, err := h.db.ExecContext(r.Context(),
		"UPDATE household_invites SET used_at = ? WHERE code = ?", now, req.Code,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	var hh models.Household
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT id, name, owner_id, created_at FROM households WHERE id = ?", invite.HouseholdID,
	).Scan(&hh.ID, &hh.Name, &hh.OwnerID, &hh.CreatedAt); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	jsonOK(w, hh)
}

func (h *HouseholdHandler) Members(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	hhID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	var count int
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT COUNT(*) FROM household_members WHERE household_id = ? AND user_id = ?",
		hhID, user.ID,
	).Scan(&count); err != nil || count == 0 {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	rows, err := h.db.QueryContext(r.Context(), `
		SELECT u.id, u.username FROM users u
		JOIN household_members hm ON hm.user_id = u.id
		WHERE hm.household_id = ?
	`, hhID)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	members := []models.User{}
	for rows.Next() {
		var u models.User
		if err := rows.Scan(&u.ID, &u.Username); err != nil {
			jsonError(w, "internal error", http.StatusInternalServerError)
			return
		}
		members = append(members, u)
	}
	jsonOK(w, members)
}

func (h *HouseholdHandler) Rename(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	hhID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}

	var ownerID int64
	if err := h.db.QueryRowContext(r.Context(),
		"SELECT owner_id FROM households WHERE id = ?", hhID,
	).Scan(&ownerID); err == sql.ErrNoRows {
		jsonError(w, "not found", http.StatusNotFound)
		return
	} else if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	if ownerID != user.ID && !user.IsAdmin {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	var req struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Name == "" {
		jsonError(w, "name required", http.StatusBadRequest)
		return
	}

	if _, err := h.db.ExecContext(r.Context(),
		"UPDATE households SET name = ? WHERE id = ?", req.Name, hhID,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": hhID, "name": req.Name})
}

// InviteInfo is a public endpoint — no auth required — so the register page
// can show the household name before the user creates their account.
func (h *HouseholdHandler) InviteInfo(w http.ResponseWriter, r *http.Request) {
	code := chi.URLParam(r, "code")

	var name string
	var expiresAt *time.Time
	var usedAt *time.Time
	err := h.db.QueryRowContext(r.Context(), `
		SELECT hh.name, hi.expires_at, hi.used_at
		FROM household_invites hi
		JOIN households hh ON hh.id = hi.household_id
		WHERE hi.code = ?
	`, code).Scan(&name, &expiresAt, &usedAt)
	if err == sql.ErrNoRows {
		jsonError(w, "invalid invite code", http.StatusNotFound)
		return
	} else if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	if usedAt != nil {
		jsonError(w, "invite already used", http.StatusGone)
		return
	}
	if expiresAt != nil && expiresAt.Before(time.Now()) {
		jsonError(w, "invite expired", http.StatusGone)
		return
	}

	jsonOK(w, map[string]string{"household_name": name})
}
