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
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	db *sql.DB
}

func NewAuthHandler(db *sql.DB) *AuthHandler {
	return &AuthHandler{db: db}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username   string `json:"username"`
		Password   string `json:"password"`
		InviteCode string `json:"invite_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Username == "" || req.Password == "" {
		jsonError(w, "invalid request", http.StatusBadRequest)
		return
	}

	// First user becomes admin and gets their own household.
	// Every subsequent user requires a valid invite code.
	var userCount int
	if err := h.db.QueryRowContext(r.Context(), "SELECT COUNT(*) FROM users").Scan(&userCount); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	isFirstUser := userCount == 0

	if !isFirstUser && req.InviteCode == "" {
		jsonError(w, "registration requires an invite code", http.StatusForbidden)
		return
	}

	// Validate invite before creating the user to avoid partial state.
	var inviteHouseholdID int64
	if !isFirstUser {
		var usedAt *time.Time
		var expiresAt *time.Time
		err := h.db.QueryRowContext(r.Context(),
			"SELECT household_id, expires_at, used_at FROM household_invites WHERE code = ?",
			req.InviteCode,
		).Scan(&inviteHouseholdID, &expiresAt, &usedAt)
		if err == sql.ErrNoRows {
			jsonError(w, "invalid invite code", http.StatusForbidden)
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
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	isAdmin := 0
	if isFirstUser {
		isAdmin = 1
	}

	result, err := h.db.ExecContext(r.Context(),
		"INSERT INTO users (username, password_hash, is_admin) VALUES (?, ?, ?)",
		req.Username, string(hash), isAdmin,
	)
	if err != nil {
		jsonError(w, "username already taken", http.StatusConflict)
		return
	}
	userID, _ := result.LastInsertId()

	var householdID int64
	if isFirstUser {
		hResult, err := h.db.ExecContext(r.Context(),
			"INSERT INTO households (name, owner_id) VALUES (?, ?)",
			req.Username, userID,
		)
		if err != nil {
			jsonError(w, "internal error", http.StatusInternalServerError)
			return
		}
		householdID, _ = hResult.LastInsertId()
	} else {
		householdID = inviteHouseholdID
		now := time.Now()
		h.db.ExecContext(r.Context(),
			"UPDATE household_invites SET used_at = ? WHERE code = ?", now, req.InviteCode,
		)
	}

	if _, err := h.db.ExecContext(r.Context(),
		"INSERT INTO household_members (household_id, user_id) VALUES (?, ?)",
		householdID, userID,
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	sessionID, err := newSessionID()
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	if _, err := h.db.ExecContext(r.Context(),
		"INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)",
		sessionID, userID, time.Now().Add(30*24*time.Hour),
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	setSessionCookie(w, sessionID)
	jsonOK(w, &models.User{ID: userID, Username: req.Username, IsAdmin: isFirstUser})
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request", http.StatusBadRequest)
		return
	}

	var user models.User
	var hash string
	var showOther, isAdmin int
	err := h.db.QueryRowContext(r.Context(),
		"SELECT id, username, password_hash, show_other_households, is_admin FROM users WHERE username = ?",
		req.Username,
	).Scan(&user.ID, &user.Username, &hash, &showOther, &isAdmin)
	if err != nil {
		jsonError(w, "invalid credentials", http.StatusUnauthorized)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(req.Password)); err != nil {
		jsonError(w, "invalid credentials", http.StatusUnauthorized)
		return
	}

	user.ShowOtherHouseholds = showOther == 1
	user.IsAdmin = isAdmin == 1

	sessionID, err := newSessionID()
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	if _, err := h.db.ExecContext(r.Context(),
		"INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)",
		sessionID, user.ID, time.Now().Add(30*24*time.Hour),
	); err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	setSessionCookie(w, sessionID)
	jsonOK(w, &user)
}

func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	cookie, err := r.Cookie("session_id")
	if err == nil {
		_, _ = h.db.ExecContext(r.Context(), "DELETE FROM sessions WHERE id = ?", cookie.Value)
	}
	http.SetCookie(w, &http.Cookie{Name: "session_id", MaxAge: -1, Path: "/"})
	jsonOK(w, map[string]string{"ok": "true"})
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	jsonOK(w, user)
}

func (h *AuthHandler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	var req struct {
		ShowOtherHouseholds *bool `json:"show_other_households"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request", http.StatusBadRequest)
		return
	}
	if req.ShowOtherHouseholds != nil {
		val := 0
		if *req.ShowOtherHouseholds {
			val = 1
		}
		if _, err := h.db.ExecContext(r.Context(),
			"UPDATE users SET show_other_households = ? WHERE id = ?", val, user.ID,
		); err != nil {
			jsonError(w, "internal error", http.StatusInternalServerError)
			return
		}
		user.ShowOtherHouseholds = *req.ShowOtherHouseholds
	}
	jsonOK(w, user)
}

func (h *AuthHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
	user := middleware.UserFromCtx(r.Context())
	if !user.IsAdmin {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	rows, err := h.db.QueryContext(r.Context(),
		"SELECT id, username, is_admin, show_other_households, created_at FROM users ORDER BY id",
	)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	users := []models.User{}
	for rows.Next() {
		var u models.User
		var isAdmin, showOther int
		if err := rows.Scan(&u.ID, &u.Username, &isAdmin, &showOther, &u.CreatedAt); err != nil {
			jsonError(w, "internal error", http.StatusInternalServerError)
			return
		}
		u.IsAdmin = isAdmin == 1
		u.ShowOtherHouseholds = showOther == 1
		users = append(users, u)
	}
	jsonOK(w, users)
}

func (h *AuthHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	actor := middleware.UserFromCtx(r.Context())
	if !actor.IsAdmin {
		jsonError(w, "forbidden", http.StatusForbidden)
		return
	}

	targetID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}
	if targetID == actor.ID {
		jsonError(w, "cannot delete yourself", http.StatusBadRequest)
		return
	}

	// Cascade: delete owned households (members, invites, recipes cascade from there),
	// then memberships, sessions, comments, finally the user.
	for _, q := range []string{
		"DELETE FROM household_members WHERE household_id IN (SELECT id FROM households WHERE owner_id = ?)",
		"DELETE FROM household_invites WHERE household_id IN (SELECT id FROM households WHERE owner_id = ?)",
		"DELETE FROM recipes WHERE household_id IN (SELECT id FROM households WHERE owner_id = ?)",
		"DELETE FROM households WHERE owner_id = ?",
		"DELETE FROM household_members WHERE user_id = ?",
		"DELETE FROM sessions WHERE user_id = ?",
		"DELETE FROM comments WHERE user_id = ?",
		"DELETE FROM users WHERE id = ?",
	} {
		if _, err := h.db.ExecContext(r.Context(), q, targetID); err != nil {
			jsonError(w, "internal error", http.StatusInternalServerError)
			return
		}
	}

	jsonOK(w, map[string]string{"ok": "true"})
}

func newSessionID() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func setSessionCookie(w http.ResponseWriter, id string) {
	http.SetCookie(w, &http.Cookie{
		Name:     "session_id",
		Value:    id,
		Path:     "/",
		HttpOnly: true,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   30 * 24 * 60 * 60,
	})
}
