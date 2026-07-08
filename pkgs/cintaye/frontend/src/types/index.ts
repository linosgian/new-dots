export interface User {
  id: number
  username: string
  is_admin: boolean
  show_other_households: boolean
  created_at: string
}

export interface Household {
  id: number
  name: string
  owner_id: number
  created_at: string
}

export interface Ingredient {
  id: number
  section_id: number
  position: number
  amount?: number
  unit?: string
  name: string
  note?: string
}

export interface Instruction {
  id: number
  section_id: number
  position: number
  body: string
}

export interface Section {
  id: number
  recipe_id: number
  kind: 'ingredients' | 'instructions'
  title?: string
  position: number
  ingredients?: Ingredient[]
  instructions?: Instruction[]
}

export interface Recipe {
  id: number
  household_id: number
  title: string
  description?: string
  prep_time_minutes?: number
  cook_time_minutes?: number
  total_time_minutes?: number
  servings?: number
  image_path?: string
  source_url?: string
  created_by: number
  created_at: string
  updated_at: string
  sections?: Section[]
  tags?: string[]
}

export interface Comment {
  id: number
  recipe_id: number
  user_id: number
  username?: string
  body: string
  created_at: string
}

// Request shapes

export interface IngredientRequest {
  position: number
  amount?: number
  unit?: string
  name: string
  note?: string
}

export interface InstructionRequest {
  position: number
  body: string
}

export interface SectionRequest {
  kind: 'ingredients' | 'instructions'
  title?: string
  position: number
  ingredients?: IngredientRequest[]
  instructions?: InstructionRequest[]
}

export interface RecipeRequest {
  title: string
  description?: string
  prep_time_minutes?: number
  cook_time_minutes?: number
  total_time_minutes?: number
  servings?: number
  source_url?: string
  tags?: string[]
  sections: SectionRequest[]
}
