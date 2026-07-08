package middleware

import (
	"context"
	"database/sql"
	"net/http"
	"time"

	"cintaye/models"
)

type contextKey string

const UserKey contextKey = "user"

func Session(db *sql.DB) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			cookie, err := r.Cookie("session_id")
			if err != nil {
				next.ServeHTTP(w, r)
				return
			}

			var user models.User
			var showOther, isAdmin int
			err = db.QueryRowContext(r.Context(), `
				SELECT u.id, u.username, u.show_other_households, u.is_admin
				FROM sessions s
				JOIN users u ON u.id = s.user_id
				WHERE s.id = ? AND s.expires_at > ?
			`, cookie.Value, time.Now()).Scan(&user.ID, &user.Username, &showOther, &isAdmin)
			if err != nil {
				next.ServeHTTP(w, r)
				return
			}

			user.ShowOtherHouseholds = showOther == 1
			user.IsAdmin = isAdmin == 1

			// Refresh session TTL
			_, _ = db.ExecContext(r.Context(),
				"UPDATE sessions SET expires_at = ? WHERE id = ?",
				time.Now().Add(30*24*time.Hour), cookie.Value,
			)

			ctx := context.WithValue(r.Context(), UserKey, &user)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func RequireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if UserFromCtx(r.Context()) == nil {
			http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func UserFromCtx(ctx context.Context) *models.User {
	u, _ := ctx.Value(UserKey).(*models.User)
	return u
}
