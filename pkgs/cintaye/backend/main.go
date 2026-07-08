package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"

	"cintaye/db"
	"cintaye/handlers"
	mw "cintaye/middleware"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	dbPath := envOr("DB_PATH", "cintaye.db")
	imagesDir := envOr("IMAGES_DIR", filepath.Join("..", "data", "images"))
	addr := envOr("ADDR", ":8080")

	if err := os.MkdirAll(imagesDir, 0755); err != nil {
		log.Fatalf("create images dir: %v", err)
	}

	database, err := db.Open(dbPath)
	if err != nil {
		log.Fatalf("open db: %v", err)
	}
	defer database.Close()

	auth := handlers.NewAuthHandler(database)
	household := handlers.NewHouseholdHandler(database)
	recipe := handlers.NewRecipeHandler(database, imagesDir)
	comment := handlers.NewCommentHandler(database)
	tag := handlers.NewTagHandler(database)
	image := handlers.NewImageHandler(database, imagesDir)
	importer := handlers.NewImportHandler(database, imagesDir)

	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(mw.Session(database))

	// Serve uploaded images
	r.Handle("/images/*", http.StripPrefix("/images/", http.FileServer(http.Dir(imagesDir))))

	r.Route("/api", func(r chi.Router) {
		// Public (no auth required)
		r.Post("/auth/register", auth.Register)
		r.Post("/auth/login", auth.Login)
		r.Get("/invites/{code}", household.InviteInfo)

		// Authenticated routes
		r.Group(func(r chi.Router) {
			r.Use(mw.RequireAuth)

			r.Post("/auth/logout", auth.Logout)
			r.Get("/auth/me", auth.Me)
			r.Patch("/users/me", auth.UpdateMe)

			r.Post("/households", household.Create)
			r.Get("/households/mine", household.Mine)
			r.Post("/households/{id}/invite", household.GenerateInvite)
			r.Get("/households/{id}/members", household.Members)
			r.Patch("/households/{id}", household.Rename)
			r.Post("/households/join", household.Join)

			r.Get("/recipes", recipe.List)
			r.Post("/recipes", recipe.Create)
			r.Post("/recipes/import", importer.Import)
			r.Get("/recipes/{id}", recipe.Get)
			r.Put("/recipes/{id}", recipe.Update)
			r.Delete("/recipes/{id}", recipe.Delete)
			r.Post("/recipes/{id}/image", image.Upload)

			r.Get("/recipes/{id}/comments", comment.List)
			r.Post("/recipes/{id}/comments", comment.Create)
			r.Delete("/comments/{commentId}", comment.Delete)

			r.Get("/tags", tag.List)
		})
	})

	log.Printf("listening on %s", addr)
	if err := http.ListenAndServe(addr, r); err != nil {
		log.Fatal(err)
	}
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
