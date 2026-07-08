package jsonld

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"golang.org/x/net/html"
)

var httpClient = &http.Client{Timeout: 15 * time.Second}

type Recipe struct {
	Title             string
	Description       string
	SourceURL         string
	ImageURL          string
	PrepTimeMinutes   *int
	CookTimeMinutes   *int
	TotalTimeMinutes  *int
	Servings          *int
	Ingredients       []string
	InstructionGroups []InstructionGroup
}

type InstructionGroup struct {
	Name  string
	Steps []string
}

// ParseURL fetches the page at url and extracts the first Schema.org Recipe.
func ParseURL(url string) (*Recipe, error) {
	resp, err := httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("fetch: %w", err)
	}
	defer resp.Body.Close()

	doc, err := html.Parse(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("parse html: %w", err)
	}

	var scripts []string
	var walk func(*html.Node)
	walk = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "script" {
			for _, a := range n.Attr {
				if a.Key == "type" && a.Val == "application/ld+json" {
					if n.FirstChild != nil {
						scripts = append(scripts, n.FirstChild.Data)
					}
				}
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
	}
	walk(doc)

	for _, s := range scripts {
		r, err := ParseText(s)
		if err == nil {
			if r.SourceURL == "" {
				r.SourceURL = url
			}
			return r, nil
		}
	}
	return nil, fmt.Errorf("no Recipe found in JSON-LD")
}

// ParseText parses raw JSON-LD text (single object or @graph array).
func ParseText(text string) (*Recipe, error) {
	var raw map[string]json.RawMessage
	if err := json.Unmarshal([]byte(strings.TrimSpace(text)), &raw); err != nil {
		return nil, err
	}

	// Handle @graph wrapper
	if graph, ok := raw["@graph"]; ok {
		var items []map[string]json.RawMessage
		if err := json.Unmarshal(graph, &items); err == nil {
			for _, item := range items {
				if r, err := parseRecipeObject(item); err == nil {
					return r, nil
				}
			}
		}
		return nil, fmt.Errorf("no Recipe in @graph")
	}

	return parseRecipeObject(raw)
}

func parseRecipeObject(obj map[string]json.RawMessage) (*Recipe, error) {
	typeVal := jsonString(obj["@type"])
	if !strings.Contains(strings.ToLower(typeVal), "recipe") {
		return nil, fmt.Errorf("not a Recipe")
	}

	r := &Recipe{}
	r.Title = jsonString(obj["name"])
	r.Description = jsonString(obj["description"])
	r.SourceURL = jsonString(obj["url"])
	if r.SourceURL == "" {
		r.SourceURL = jsonString(obj["@id"])
	}

	r.ImageURL = parseImageURL(obj["image"])
	r.PrepTimeMinutes = parseDuration(jsonString(obj["prepTime"]))
	r.CookTimeMinutes = parseDuration(jsonString(obj["cookTime"]))
	r.TotalTimeMinutes = parseDuration(jsonString(obj["totalTime"]))
	r.Servings = parseServings(obj["recipeYield"])

	// Ingredients: array of strings
	if ing, ok := obj["recipeIngredient"]; ok {
		var strs []string
		if err := json.Unmarshal(ing, &strs); err == nil {
			r.Ingredients = strs
		}
	}

	// Instructions: HowToStep[], HowToSection[], or plain strings
	if inst, ok := obj["recipeInstructions"]; ok {
		r.InstructionGroups = parseInstructions(inst)
	}

	if r.Title == "" {
		return nil, fmt.Errorf("missing recipe name")
	}
	return r, nil
}

func parseInstructions(raw json.RawMessage) []InstructionGroup {
	// Try array
	var items []json.RawMessage
	if err := json.Unmarshal(raw, &items); err != nil {
		// Plain string
		var s string
		if json.Unmarshal(raw, &s) == nil {
			return []InstructionGroup{{Steps: []string{s}}}
		}
		return nil
	}

	var groups []InstructionGroup
	var defaultGroup InstructionGroup

	for _, item := range items {
		var obj map[string]json.RawMessage
		if err := json.Unmarshal(item, &obj); err != nil {
			// plain string
			var s string
			if json.Unmarshal(item, &s) == nil {
				defaultGroup.Steps = append(defaultGroup.Steps, s)
			}
			continue
		}

		t := jsonString(obj["@type"])
		switch {
		case strings.EqualFold(t, "HowToSection"):
			g := InstructionGroup{Name: jsonString(obj["name"])}
			if steps, ok := obj["itemListElement"]; ok {
				for _, step := range mustUnmarshalArray(steps) {
					var stepObj map[string]json.RawMessage
					json.Unmarshal(step, &stepObj)
					if text := jsonString(stepObj["text"]); text != "" {
						g.Steps = append(g.Steps, text)
					}
				}
			}
			groups = append(groups, g)
		case strings.EqualFold(t, "HowToStep"):
			text := jsonString(obj["text"])
			if text == "" {
				text = jsonString(obj["name"])
			}
			defaultGroup.Steps = append(defaultGroup.Steps, text)
		default:
			if text := jsonString(obj["text"]); text != "" {
				defaultGroup.Steps = append(defaultGroup.Steps, text)
			}
		}
	}

	if len(defaultGroup.Steps) > 0 {
		groups = append([]InstructionGroup{defaultGroup}, groups...)
	}
	return groups
}

var isoDurationRe = regexp.MustCompile(`(?i)PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?`)

func parseDuration(s string) *int {
	if s == "" {
		return nil
	}
	m := isoDurationRe.FindStringSubmatch(s)
	if m == nil {
		return nil
	}
	h, _ := strconv.Atoi(m[1])
	min, _ := strconv.Atoi(m[2])
	total := h*60 + min
	if total == 0 {
		return nil
	}
	return &total
}

func parseServings(raw json.RawMessage) *int {
	if raw == nil {
		return nil
	}
	var s string
	if err := json.Unmarshal(raw, &s); err == nil {
		// "4 servings" → 4
		fields := strings.Fields(s)
		if len(fields) > 0 {
			if n, err := strconv.Atoi(fields[0]); err == nil {
				return &n
			}
		}
		return nil
	}
	var n int
	if err := json.Unmarshal(raw, &n); err == nil {
		return &n
	}
	// array like ["4", "servings"]
	var arr []string
	if err := json.Unmarshal(raw, &arr); err == nil && len(arr) > 0 {
		if n, err := strconv.Atoi(arr[0]); err == nil {
			return &n
		}
	}
	return nil
}

func jsonString(raw json.RawMessage) string {
	if raw == nil {
		return ""
	}
	var s string
	json.Unmarshal(raw, &s)
	return strings.TrimSpace(s)
}

func mustUnmarshalArray(raw json.RawMessage) []json.RawMessage {
	var arr []json.RawMessage
	json.Unmarshal(raw, &arr)
	return arr
}

// parseImageURL extracts a usable image URL from the Schema.org image field,
// which can be a plain string, an ImageObject, or an array of either.
func parseImageURL(raw json.RawMessage) string {
	if raw == nil {
		return ""
	}

	// Plain string URL
	var s string
	if json.Unmarshal(raw, &s) == nil && s != "" {
		return s
	}

	// ImageObject: {"@type": "ImageObject", "url": "...", "contentUrl": "..."}
	var obj map[string]json.RawMessage
	if json.Unmarshal(raw, &obj) == nil {
		if u := jsonString(obj["url"]); u != "" {
			return u
		}
		if u := jsonString(obj["contentUrl"]); u != "" {
			return u
		}
	}

	// Array — take the first usable one
	var arr []json.RawMessage
	if json.Unmarshal(raw, &arr) == nil {
		for _, item := range arr {
			if u := parseImageURL(item); u != "" {
				return u
			}
		}
	}

	return ""
}

// unicodeFractionMap maps Unicode fraction characters to their decimal values.
var unicodeFractionMap = map[rune]float64{
	'½': 0.5,
	'⅓': 1.0 / 3,
	'⅔': 2.0 / 3,
	'¼': 0.25,
	'¾': 0.75,
	'⅕': 0.2,
	'⅖': 0.4,
	'⅗': 0.6,
	'⅘': 0.8,
	'⅙': 1.0 / 6,
	'⅚': 5.0 / 6,
	'⅛': 0.125,
	'⅜': 0.375,
	'⅝': 0.625,
	'⅞': 0.875,
}

// normalizeAmount converts a leading amount token to a plain float string.
// It handles: integers, ASCII fractions (1/3), decimals, unicode fractions (⅓),
// and mixed numbers (1½, "1 ½").
func normalizeAmount(s string) (float64, bool) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, false
	}

	// Check for trailing unicode fraction character (mixed: "1½" or "1 ½")
	runes := []rune(s)
	last := runes[len(runes)-1]
	if frac, ok := unicodeFractionMap[last]; ok {
		whole := strings.TrimSpace(string(runes[:len(runes)-1]))
		if whole == "" {
			return frac, true
		}
		n, err := strconv.ParseFloat(whole, 64)
		if err == nil {
			return n + frac, true
		}
		return frac, true
	}

	// Pure unicode fraction character
	if len(runes) == 1 {
		if frac, ok := unicodeFractionMap[runes[0]]; ok {
			return frac, true
		}
	}

	// ASCII fraction "1/3"
	if strings.Contains(s, "/") {
		return parseFraction(s), true
	}

	// Plain number
	n, err := strconv.ParseFloat(s, 64)
	if err == nil {
		return n, true
	}
	return 0, false
}

// ToIngredientParts splits a raw ingredient string into amount, unit, name, note.
// Handles integers, decimals, ASCII fractions (1/2), unicode fractions (½ ⅓ ¾),
// and mixed numbers (1½, "1 ½"). Best-effort: full string becomes name on failure.
func ToIngredientParts(s string) (amount *float64, unit, name, note string) {
	s = strings.TrimSpace(s)

	// Tokenize: grab the first "amount" token which may be:
	//   "1/3", "1.5", "1", "½", "⅓", "1½", "1 ½"
	// Strategy: consume digits/slash/dot/unicode-fraction chars from the front.
	amountRe := regexp.MustCompile(`^(\d+(?:[./]\d+)?(?:\s*[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞])?|[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]|\d+\s+[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞])\s*(.*)`)
	m := amountRe.FindStringSubmatch(s)
	if m == nil {
		name = s
		return
	}

	amountStr := strings.TrimSpace(m[1])
	rest := strings.TrimSpace(m[2])

	a, ok := normalizeAmount(amountStr)
	if !ok {
		name = s
		return
	}
	amount = &a

	// Common units
	units := []string{
		"tablespoon", "tablespoons", "tbsp",
		"teaspoon", "teaspoons", "tsp",
		"cup", "cups",
		"gram", "grams", "g",
		"kilogram", "kilograms", "kg",
		"ounce", "ounces", "oz",
		"pound", "pounds", "lb", "lbs",
		"liter", "liters", "l",
		"milliliter", "milliliters", "ml",
		"pinch", "dash", "handful",
		"clove", "cloves", "slice", "slices",
		"can", "cans", "bunch",
	}

	lRest := strings.ToLower(rest)
	for _, u := range units {
		if strings.HasPrefix(lRest, u+" ") || strings.EqualFold(lRest, u) {
			unit = rest[:len(u)]
			name = strings.TrimSpace(rest[len(u):])
			return
		}
	}

	// Check for parenthetical note at end: "chicken breast (boneless)"
	noteRe := regexp.MustCompile(`^(.+?)\s*\(([^)]+)\)\s*$`)
	if nm := noteRe.FindStringSubmatch(rest); nm != nil {
		name = strings.TrimSpace(nm[1])
		note = nm[2]
		return
	}

	name = rest
	return
}

func parseFraction(s string) float64 {
	if strings.Contains(s, "/") {
		parts := strings.SplitN(s, "/", 2)
		num, _ := strconv.ParseFloat(parts[0], 64)
		den, _ := strconv.ParseFloat(parts[1], 64)
		if den != 0 {
			return num / den
		}
		return num
	}
	v, _ := strconv.ParseFloat(s, 64)
	return v
}

// ReadAll reads the body of an http.Response as a string (for testing).
func ReadAll(r io.Reader) string {
	b, _ := io.ReadAll(r)
	return string(b)
}
