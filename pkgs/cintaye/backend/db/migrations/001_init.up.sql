CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  show_other_households INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE households (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  owner_id INTEGER NOT NULL REFERENCES users(id),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE household_members (
  household_id INTEGER NOT NULL REFERENCES households(id),
  user_id INTEGER NOT NULL REFERENCES users(id),
  PRIMARY KEY (household_id, user_id)
);

CREATE TABLE household_invites (
  code TEXT PRIMARY KEY,
  household_id INTEGER NOT NULL REFERENCES households(id),
  created_by INTEGER NOT NULL REFERENCES users(id),
  expires_at DATETIME,
  used_at DATETIME
);

CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  expires_at DATETIME NOT NULL
);

CREATE TABLE recipes (
  id INTEGER PRIMARY KEY,
  household_id INTEGER NOT NULL REFERENCES households(id),
  title TEXT NOT NULL,
  description TEXT,
  prep_time_minutes INTEGER,
  cook_time_minutes INTEGER,
  total_time_minutes INTEGER,
  servings INTEGER,
  image_path TEXT,
  source_url TEXT,
  created_by INTEGER NOT NULL REFERENCES users(id),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE recipe_sections (
  id INTEGER PRIMARY KEY,
  recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK(kind IN ('ingredients', 'instructions')),
  title TEXT,
  position INTEGER NOT NULL
);

CREATE TABLE ingredients (
  id INTEGER PRIMARY KEY,
  section_id INTEGER NOT NULL REFERENCES recipe_sections(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  amount REAL,
  unit TEXT,
  name TEXT NOT NULL,
  note TEXT
);

CREATE TABLE instructions (
  id INTEGER PRIMARY KEY,
  section_id INTEGER NOT NULL REFERENCES recipe_sections(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  body TEXT NOT NULL
);

CREATE TABLE tags (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

CREATE TABLE recipe_tags (
  recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  tag_id INTEGER NOT NULL REFERENCES tags(id),
  PRIMARY KEY (recipe_id, tag_id)
);

CREATE TABLE comments (
  id INTEGER PRIMARY KEY,
  recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id),
  body TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
