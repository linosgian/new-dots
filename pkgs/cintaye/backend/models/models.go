package models

import "time"

type User struct {
	ID                  int64     `json:"id"`
	Username            string    `json:"username"`
	IsAdmin             bool      `json:"is_admin"`
	ShowOtherHouseholds bool      `json:"show_other_households"`
	CreatedAt           time.Time `json:"created_at"`
}

type Household struct {
	ID        int64     `json:"id"`
	Name      string    `json:"name"`
	OwnerID   int64     `json:"owner_id"`
	CreatedAt time.Time `json:"created_at"`
}

type HouseholdMember struct {
	HouseholdID int64 `json:"household_id"`
	UserID      int64 `json:"user_id"`
}

type HouseholdInvite struct {
	Code        string     `json:"code"`
	HouseholdID int64      `json:"household_id"`
	CreatedBy   int64      `json:"created_by"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
	UsedAt      *time.Time `json:"used_at,omitempty"`
}

type Recipe struct {
	ID               int64      `json:"id"`
	HouseholdID      int64      `json:"household_id"`
	HouseholdName    string     `json:"household_name,omitempty"`
	Title            string     `json:"title"`
	Description      string     `json:"description"`
	PrepTimeMinutes  *int       `json:"prep_time_minutes,omitempty"`
	CookTimeMinutes  *int       `json:"cook_time_minutes,omitempty"`
	TotalTimeMinutes *int       `json:"total_time_minutes,omitempty"`
	Servings         *int       `json:"servings,omitempty"`
	ImagePath        string     `json:"image_path,omitempty"`
	SourceURL        string     `json:"source_url,omitempty"`
	CreatedBy        int64      `json:"created_by"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
	Sections         []Section  `json:"sections,omitempty"`
	Tags             []string   `json:"tags,omitempty"`
}

type Section struct {
	ID          int64         `json:"id"`
	RecipeID    int64         `json:"recipe_id"`
	Kind        string        `json:"kind"` // "ingredients" | "instructions"
	Title       string        `json:"title,omitempty"`
	Position    int           `json:"position"`
	Ingredients []Ingredient  `json:"ingredients,omitempty"`
	Instructions []Instruction `json:"instructions,omitempty"`
}

type Ingredient struct {
	ID        int64    `json:"id"`
	SectionID int64    `json:"section_id"`
	Position  int      `json:"position"`
	Amount    *float64 `json:"amount,omitempty"`
	Unit      string   `json:"unit,omitempty"`
	Name      string   `json:"name"`
	Note      string   `json:"note,omitempty"`
}

type Instruction struct {
	ID        int64  `json:"id"`
	SectionID int64  `json:"section_id"`
	Position  int    `json:"position"`
	Body      string `json:"body"`
}

type Tag struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
}

type Comment struct {
	ID        int64     `json:"id"`
	RecipeID  int64     `json:"recipe_id"`
	UserID    int64     `json:"user_id"`
	Username  string    `json:"username,omitempty"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"created_at"`
}
