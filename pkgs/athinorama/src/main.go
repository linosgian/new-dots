package main

import (
	"crypto/md5"
	"encoding/json"
	"flag"
	"fmt"
	"html"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
	"unicode"

	"github.com/gocolly/colly/v2"
	"golang.org/x/text/runes"
	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"
)

// ------------------ TYPES ------------------

// DayOfWeek represents Greek day abbreviations
type DayOfWeek string

const (
	Monday    DayOfWeek = "Δευτ"
	Tuesday   DayOfWeek = "Τρι"
	Wednesday DayOfWeek = "Τετ"
	Thursday  DayOfWeek = "Πεμ"
	Friday    DayOfWeek = "Παρ"
	Saturday  DayOfWeek = "Σαβ"
	Sunday    DayOfWeek = "Κυρ"
)

// normalizeGreek strips accents and lowercases a Greek string for fuzzy matching.
func normalizeGreek(s string) string {
	t := transform.Chain(norm.NFD, runes.Remove(runes.In(unicode.Mn)), norm.NFC)
	result, _, _ := transform.String(t, strings.ToLower(s))
	return result
}

// Screening represents a single movie screening
type Screening struct {
	Time     string    `json:"time"`
	DayStart DayOfWeek `json:"day_start"`
	DayEnd   DayOfWeek `json:"day_end"`
	IsToday  bool      `json:"is_today"`
}

// Movie represents a film with its screenings
type Movie struct {
	Title         string      `json:"title"`
	OriginalTitle string      `json:"original_title,omitempty"`
	GreekTitle    string      `json:"greek_title,omitempty"`
	Director      string      `json:"director,omitempty"`
	Cast          []string    `json:"cast,omitempty"`
	Genre         string      `json:"genre,omitempty"`
	Duration      string      `json:"duration,omitempty"`
	Year          string      `json:"year,omitempty"`
	URL           string      `json:"url,omitempty"`
	ImageURL      string      `json:"image_url,omitempty"`
	Rating        string      `json:"rating,omitempty"`
	Description   string      `json:"description,omitempty"`
	TrailerURL    string      `json:"trailer_url,omitempty"`
	Screenings    []Screening `json:"screenings"`
}

// Cinema represents a cinema with its movies
type Cinema struct {
	Name    string  `json:"name"`
	Address string  `json:"address,omitempty"`
	Phone   string  `json:"phone,omitempty"`
	URL     string  `json:"url,omitempty"`
	Summer  bool    `json:"summer"`
	Movies  []Movie `json:"movies"`
}

// Area represents a cinema area with its slug and display name
type Area struct {
	Slug string `json:"slug"`
	Name string `json:"name"`
}

// MovieAreaInfo represents screenings in a specific area
type MovieAreaInfo struct {
	Area    string            `json:"area"`
	Cinemas []MovieCinemaInfo `json:"cinemas"`
}

// MovieCinemaInfo represents screenings at a specific cinema
type MovieCinemaInfo struct {
	CinemaName    string      `json:"cinema_name"`
	CinemaURL     string      `json:"cinema_url"`
	CinemaAddress string      `json:"cinema_address"`
	Screenings    []Screening `json:"screenings"`
}

// Schedule represents the complete cinema schedule
type Schedule struct {
	Area      string    `json:"area"`
	Cinemas   []Cinema  `json:"cinemas"`
	UpdatedAt time.Time `json:"updated_at"`
}

// TodaySchedule represents movies playing today
type TodaySchedule struct {
	Date    time.Time           `json:"date"`
	Cinemas []CinemaTodayMovies `json:"cinemas"`
}

// CinemaTodayMovies represents movies playing today at a cinema
type CinemaTodayMovies struct {
	CinemaName    string           `json:"cinema_name"`
	CinemaURL     string           `json:"cinema_url"`
	CinemaAddress string           `json:"cinema_address"`
	CinemaSummer  bool             `json:"cinema_summer"`
	Movies        []MovieWithTimes `json:"movies"`
}

type MovieWithTimes struct {
	Movie *Movie   `json:"movie"`
	Times []string `json:"times"`
}

// MultiAreaSchedule holds schedules for multiple areas
type MultiAreaSchedule struct {
	Areas     map[string][]Cinema `json:"areas"`
	UpdatedAt time.Time           `json:"updated_at"`
}

// ------------------ CRAWLER ------------------

type CinemaCrawler struct {
	baseURL string
	area    string
}

// FetchCinemaAreas scrapes the cinema areas from athinorama.gr
func FetchCinemaAreas() ([]Area, error) {
	var areas []Area

	c := colly.NewCollector(
		colly.AllowedDomains("www.athinorama.gr", "athinorama.gr"),
	)

	c.OnHTML("ul.ajax-areas li a", func(e *colly.HTMLElement) {
		href := e.Attr("href")
		name := strings.TrimSpace(e.Text)

		// Extract slug from URL like "/cinema/guide/kentro_-_kolonaki/cinemas/"
		// Remove prefix and suffix to get just "kentro_-_kolonaki"
		slug := strings.TrimPrefix(href, "/cinema/guide/")
		slug = strings.TrimSuffix(slug, "/cinemas/")

		if slug != "" && name != "" {
			areas = append(areas, Area{
				Slug: slug,
				Name: name,
			})
		}
	})

	c.OnError(func(r *colly.Response, err error) {
		log.Printf("Failed to fetch cinema areas: %v", err)
	})

	err := c.Visit("https://www.athinorama.gr/cinema")
	if err != nil {
		return nil, err
	}

	return areas, nil
}
func NewCinemaCrawler(area string) *CinemaCrawler {
	return &CinemaCrawler{
		baseURL: "https://www.athinorama.gr",
		area:    area,
	}
}

func getScheduleWeekStart(targetDate time.Time) time.Time {
	weekday := targetDate.Weekday()
	daysSinceThursday := (int(weekday) - int(time.Thursday) + 7) % 7
	return targetDate.AddDate(0, 0, -daysSinceThursday).Truncate(24 * time.Hour)
}

func getScheduleWeekEnd(startThursday time.Time) time.Time {
	return startThursday.AddDate(0, 0, 6) // Thursday → next Wednesday
}
func weekdayToDayOfWeek(d time.Weekday) DayOfWeek {
	switch d {
	case time.Monday:
		return "Δευ"
	case time.Tuesday:
		return "Τρι"
	case time.Wednesday:
		return "Τετ"
	case time.Thursday:
		return "Πεμ"
	case time.Friday:
		return "Παρ"
	case time.Saturday:
		return "Σαβ"
	case time.Sunday:
		return "Κυρ"
	}
	return ""
}

// Replace the normalizeDayName function with this improved version

// Map Greek day abbreviations to time.Weekday
func getDayOfWeekMap() map[DayOfWeek]time.Weekday {
	return map[DayOfWeek]time.Weekday{
		Monday:    time.Monday,
		Tuesday:   time.Tuesday,
		Wednesday: time.Wednesday,
		Thursday:  time.Thursday,
		Friday:    time.Friday,
		Saturday:  time.Saturday,
		Sunday:    time.Sunday,
	}
}

// Parse day range string like "Πέμ.-Κυρ."
func parseDayRange(dayStr string) (DayOfWeek, DayOfWeek, error) {
	dayStr = strings.TrimSpace(dayStr)
	dayStr = strings.ReplaceAll(dayStr, " ", "")
	parts := strings.Split(dayStr, "-")
	if len(parts) == 2 {
		start := normalizeDayName(parts[0])
		end := normalizeDayName(parts[1])
		return start, end, nil
	} else if len(parts) == 1 {
		day := normalizeDayName(parts[0])
		return day, day, nil
	}
	return "", "", nil
}

// Get next date for a given DayOfWeek
func getDateForDay(day DayOfWeek) time.Time {
	dayMap := getDayOfWeekMap()
	targetWeekday := dayMap[day]
	now := time.Now()
	today := now.Weekday()
	daysUntil := int(targetWeekday - today)
	if daysUntil < 0 {
		daysUntil += 7
	}
	return now.AddDate(0, 0, daysUntil)
}

func normalizeDuration(raw string) string {
	// Example input: "Διάρκεια: 118'"
	raw = strings.TrimSpace(raw)

	// Remove Greek prefix
	raw = strings.TrimPrefix(raw, "Διάρκεια:")
	raw = strings.TrimSpace(raw)

	// Remove trailing apostrophe
	raw = strings.TrimSuffix(raw, "'")

	// Now raw should be just "118"
	// Validate digits only
	num := ""
	for _, r := range raw {
		if r >= '0' && r <= '9' {
			num += string(r)
		}
	}

	return num
}

func CrawlMovieDetails(movieURL string) (description, greekTitle, originalTitle, year, duration, genre, director, rating, imageURL, trailerURL string, cast []string, err error) {
	c := colly.NewCollector(
		colly.AllowedDomains("www.athinorama.gr", "athinorama.gr"),
	)

	c.OnHTML("ul.review-details", func(e *colly.HTMLElement) {
		originalTitle = strings.TrimSpace(e.ChildText("span.original-title"))
		year = strings.TrimSpace(e.ChildText("span.year"))
		duration = normalizeDuration(strings.TrimSpace(e.ChildText("span.duration")))
		rating = strings.TrimSpace(e.ChildText("span.rating-value"))
		genre = strings.TrimSpace(e.ChildText("span.genre"))
	})

	c.OnHTML("div.review-title h1", func(e *colly.HTMLElement) {
		greekTitle = strings.TrimSpace(e.Text)
	})

	c.OnHTML("div.summary p", func(e *colly.HTMLElement) {
		description = strings.TrimSpace(e.Text)
	})

	// Full-res image: swap the thumbnail dimensions path for the 1200x630 variant
	c.OnHTML("div.review-cover img", func(e *colly.HTMLElement) {
		src := e.Attr("src")
		// The site serves thumbnails at e.g. /250x300/pad/both/...
		// Full resolution is available at /1200x630/pad/both/...
		imageURL = regexp.MustCompile(`/\d+x\d+/`).ReplaceAllString(src, "/1200x630/")
		if !strings.HasPrefix(imageURL, "http") {
			imageURL = "https://www.athinorama.gr" + imageURL
		}
	})

	// Static iframe embed (most reliable with colly)
	c.OnHTML(`iframe[src*="youtube.com/embed/"]`, func(e *colly.HTMLElement) {
		if trailerURL != "" {
			return
		}
		src := e.Attr("src")
		if idx := strings.LastIndex(src, "/embed/"); idx >= 0 {
			vid := src[idx+7:]
			if q := strings.Index(vid, "?"); q >= 0 {
				vid = vid[:q]
			}
			if vid != "" {
				trailerURL = "https://www.youtube.com/watch?v=" + vid
			}
		}
	})

	// Fallback: plain anchor link to YouTube watch page
	c.OnHTML(`a[href*="youtube.com/watch"]`, func(e *colly.HTMLElement) {
		if trailerURL == "" {
			trailerURL = e.Attr("href")
		}
	})

	c.OnHTML("div.cast-crew div.cast-crew-item", func(e *colly.HTMLElement) {
		header := strings.TrimSpace(e.ChildText("h4"))
		switch header {
		case "Σκηνοθεσία:":
			director = strings.TrimSpace(e.ChildText("nav"))
		case "Με τους:":
			e.ForEach("nav a", func(_ int, a *colly.HTMLElement) {
				name := strings.TrimSpace(a.Text)
				if name != "" {
					cast = append(cast, name)
				}
			})
		}
	})

	c.OnError(func(r *colly.Response, err error) {
		log.Printf("Movie detail request failed: %v", err)
	})

	err = c.Visit(movieURL)
	return
}

// Check if today is within day range
func isTodayInRange(start, end DayOfWeek) bool {
	dayMap := getDayOfWeekMap()
	today := time.Now().Weekday()
	s := dayMap[start]
	e := dayMap[end]
	if s <= e {
		return today >= s && today <= e
	}
	return today >= s || today <= e
}

// Crawl the cinema schedule for one area
func (cc *CinemaCrawler) Crawl() (*Schedule, error) {
	schedule := &Schedule{
		Area:      cc.area,
		Cinemas:   []Cinema{},
		UpdatedAt: time.Now(),
	}

	c := colly.NewCollector(
		colly.AllowedDomains("www.athinorama.gr", "athinorama.gr"),
	)

	c.OnHTML("div.item.card-item", func(e *colly.HTMLElement) {
		cinema := Cinema{
			Name:    strings.TrimSpace(e.ChildText("h2.item-title a")),
			URL:     e.Request.AbsoluteURL(e.ChildAttr("h2.item-title a", "href")),
			Address: strings.TrimSpace(e.ChildText("address")),
			Summer:  strings.Contains(normalizeGreek(e.ChildText("div.tags")), "θερινο"),
			Movies:  []Movie{},
		}

		e.ForEach("div.schedule-item", func(_ int, movieEl *colly.HTMLElement) {
			movieURL := movieEl.Request.AbsoluteURL(movieEl.ChildAttr("a", "href"))

			movie := Movie{
				Title:      strings.TrimSpace(movieEl.ChildText("a")),
				URL:        movieURL,
				Screenings: []Screening{},
			}

			// 🎯 FETCH EXTRA MOVIE DATA HERE
			description, greekTitle, original, year, duration, genre, director, rating, imageURL, trailerURL, cast, err := CrawlMovieDetails(movieURL)
			if err == nil {
				movie.OriginalTitle = original
				movie.Year = year
				movie.Duration = duration
				movie.Genre = genre
				movie.Director = director
				movie.GreekTitle = greekTitle
				movie.Rating = rating
				movie.Description = description
				movie.ImageURL = imageURL
				movie.TrailerURL = trailerURL
				movie.Cast = cast
			} else {
				log.Println("Failed to fetch movie details:", err)
			}

			// Parse screening times
			// With:
			var timeParts []string
			movieEl.ForEach("span.time", func(_ int, span *colly.HTMLElement) {
				t := strings.TrimSpace(span.Text)
				if t != "" {
					timeParts = append(timeParts, t)
				}
			})
			scheduleText := strings.TrimSpace(strings.Join(timeParts, " "))
			parsedScreenings, err := parseScreeningTimes(scheduleText)
			if err == nil {
				movie.Screenings = append(movie.Screenings, parsedScreenings...)
			}

			cinema.Movies = append(cinema.Movies, movie)
		})

		schedule.Cinemas = append(schedule.Cinemas, cinema)
	})

	c.OnError(func(r *colly.Response, err error) {
		log.Printf("Request URL: %s failed: %v\n", r.Request.URL, err)
	})

	c.OnRequest(func(r *colly.Request) {
		log.Println("Visiting", r.URL)
	})

	url := fmt.Sprintf("%s/cinema/guide/%s/cinemas/", cc.baseURL, cc.area)
	if err := c.Visit(url); err != nil {
		return nil, err
	}

	return schedule, nil
}

// Replace the normalizeDayName function with this improved version

func normalizeDayName(day string) DayOfWeek {
	day = strings.TrimSpace(day)
	day = strings.TrimSuffix(day, ".")
	day = strings.ToLower(day)

	// Monday variants: Δευτ, Δευ
	if strings.HasPrefix(day, "δευτ") || strings.HasPrefix(day, "δευ") {
		return Monday
	}
	// Tuesday variants: Τρι, Τρ
	if strings.HasPrefix(day, "τρι") || day == "τρ" {
		return Tuesday
	}
	// Wednesday variants: Τετ, Τε
	if strings.HasPrefix(day, "τετ") || strings.HasPrefix(day, "τε") {
		return Wednesday
	}
	// Thursday variants: Πέμ, Πεμ, Πε
	if strings.HasPrefix(day, "πέμ") || strings.HasPrefix(day, "πεμ") || day == "πε" {
		return Thursday
	}
	// Friday variants: Παρ, Πα
	if strings.HasPrefix(day, "παρ") || day == "πα" {
		return Friday
	}
	// Saturday variants: Σάβ, Σαβ, Σα
	if strings.HasPrefix(day, "σάβ") || strings.HasPrefix(day, "σαβ") || day == "σα" {
		return Saturday
	}
	// Sunday variants: Κυρ, Κυ
	if strings.HasPrefix(day, "κυρ") || day == "κυ" {
		return Sunday
	}

	// Return original if no match (fallback)
	return DayOfWeek(day)
}

// parseScreeningEntry handles a single schedule entry like:
// "Παρ., Κυρ.-Τετ.: 17.40/ 20.00/ 22.20"
// and returns screenings for all days/ranges + times
func parseScreeningEntry(daysStr, timesStr string) []Screening {
	var screenings []Screening

	timesStr = strings.TrimSuffix(timesStr, "μεταγλ.")
	timesStr = strings.TrimSuffix(timesStr, "μεταγλ")
	timesStr = strings.TrimSpace(timesStr)

	// Split times by /
	timeParts := strings.Split(timesStr, "/")
	var cleanTimes []string
	timeRe := regexp.MustCompile(`^\d{1,2}\.\d{2}$`)
	for _, t := range timeParts {
		t = strings.TrimSpace(t)
		if timeRe.MatchString(t) {
			cleanTimes = append(cleanTimes, t)
		}
	}

	if len(cleanTimes) == 0 {
		return screenings
	}

	// Split by comma to get individual day tokens (e.g. "Παρ.", "Κυρ.-Τετ.")
	dayTokens := strings.Split(daysStr, ",")
	for _, token := range dayTokens {
		token = strings.TrimSpace(token)
		if token == "" {
			continue
		}

		// Check if it's a range (contains "-" between two day names)
		if strings.Contains(token, "-") {
			parts := strings.SplitN(token, "-", 2)
			start := normalizeDayName(parts[0])
			end := normalizeDayName(parts[1])
			for _, t := range cleanTimes {
				screenings = append(screenings, Screening{
					Time:     t,
					DayStart: start,
					DayEnd:   end,
					IsToday:  isTodayInRange(start, end),
				})
			}
		} else {
			day := normalizeDayName(token)
			for _, t := range cleanTimes {
				screenings = append(screenings, Screening{
					Time:     t,
					DayStart: day,
					DayEnd:   day,
					IsToday:  isTodayInRange(day, day),
				})
			}
		}
	}

	return screenings
}
func parseScreeningTimes(scheduleStr string) ([]Screening, error) {
	scheduleStr = strings.TrimSpace(scheduleStr)
	if scheduleStr == "" {
		return nil, nil
	}

	scheduleStr = strings.ReplaceAll(scheduleStr, "\n", " ")
	scheduleStr = regexp.MustCompile(`\s+`).ReplaceAllString(scheduleStr, " ")

	var screenings []Screening

	dayRe := regexp.MustCompile(`^[ΔΤΠΣΚ][α-ωά-ώΑ-ΩΆ-Ώ]*\.?$`)
	timeRe := regexp.MustCompile(`^\d{1,2}\.\d{2}$`)
	rangeRe := regexp.MustCompile(`^([ΔΤΠΣΚ][α-ωά-ώΑ-ΩΆ-Ώ]*\.?)-([ΔΤΠΣΚ][α-ωά-ώΑ-ΩΆ-Ώ]*\.?)$`)

	type segment struct {
		days  []string
		times []string
	}

	var segments []segment
	var pendingDays []string

	rawTokens := strings.Split(scheduleStr, ",")

	for _, token := range rawTokens {
		token = strings.TrimSpace(token)
		if token == "" {
			continue
		}

		// Strip μεταγλ suffix but keep the rest intact for time parsing
		token = strings.TrimSuffix(token, " μεταγλ.")
		token = strings.TrimSuffix(token, " μεταγλ")
		token = strings.TrimSpace(token)

		// Replace colon with space so "Πέμ.: 19.30" and "Πέμ. 19.30" are handled the same
		token = strings.ReplaceAll(token, ":", " ")
		token = strings.TrimSpace(token)

		// Split by whitespace first, then further split each part by "/"
		// This handles "19.10/ 21.45" (slash attached) and "19.00 / 21.30" (slash separate)
		spaceParts := regexp.MustCompile(`\s+`).Split(token, -1)
		var parts []string
		for _, sp := range spaceParts {
			// Split by slash, keeping non-empty results
			slashParts := strings.Split(sp, "/")
			for _, slp := range slashParts {
				slp = strings.TrimSpace(slp)
				if slp != "" {
					parts = append(parts, slp)
				}
			}
		}

		var dayParts []string
		var timeParts []string
		inTimes := false

		for _, part := range parts {
			if timeRe.MatchString(part) {
				inTimes = true
				timeParts = append(timeParts, part)
			} else if !inTimes {
				if rangeRe.MatchString(part) || dayRe.MatchString(part) {
					dayParts = append(dayParts, part)
				}
			}
			// after times start, ignore non-time parts (e.g. stray characters)
		}

		if len(timeParts) > 0 {
			allDays := append(pendingDays, dayParts...)
			segments = append(segments, segment{days: allDays, times: timeParts})
			pendingDays = nil
		} else {
			pendingDays = append(pendingDays, dayParts...)
		}
	}

	for _, seg := range segments {
		for _, dayToken := range seg.days {
			match := rangeRe.FindStringSubmatch(dayToken)
			var start, end DayOfWeek
			if match != nil {
				start = normalizeDayName(match[1])
				end = normalizeDayName(match[2])
			} else {
				start = normalizeDayName(dayToken)
				end = start
			}
			for _, t := range seg.times {
				screenings = append(screenings, Screening{
					Time:     t,
					DayStart: start,
					DayEnd:   end,
					IsToday:  isTodayInRange(start, end),
				})
			}
		}
	}

	return screenings, nil
}

// ------------------ TODAY SCHEDULE ------------------

func (s *Schedule) GetScheduleForDate(targetDate time.Time) *TodaySchedule {
	todaySchedule := &TodaySchedule{
		Date:    targetDate,
		Cinemas: []CinemaTodayMovies{},
	}

	for _, cinema := range s.Cinemas {
		cinemaTodayMovies := CinemaTodayMovies{
			CinemaName:    cinema.Name,
			CinemaURL:     cinema.URL,
			CinemaAddress: cinema.Address,
			CinemaSummer:  cinema.Summer,
			Movies:        []MovieWithTimes{},
		}

		movieTimesMap := make(map[string]MovieWithTimes)

		for i := range cinema.Movies {
			movie := &cinema.Movies[i]
			key := movie.Title // or movie.GreekTitle, or a combination

			targetDay := weekdayToDayOfWeek(targetDate.Weekday())

			for _, screening := range movie.Screenings {
				dayStart := screening.DayStart
				dayEnd := screening.DayEnd

				if dayInRange(targetDay, dayStart, dayEnd) {
					if existing, ok := movieTimesMap[key]; ok {
						existing.Times = append(existing.Times, screening.Time)
						movieTimesMap[key] = existing
					} else {
						movieTimesMap[key] = MovieWithTimes{
							Movie: movie,
							Times: []string{screening.Time},
						}
					}
				}
			}
		}
		for _, mt := range movieTimesMap {
			cinemaTodayMovies.Movies = append(cinemaTodayMovies.Movies, mt)
		}

		if len(cinemaTodayMovies.Movies) > 0 {
			todaySchedule.Cinemas = append(todaySchedule.Cinemas, cinemaTodayMovies)
		}
	}

	return todaySchedule
}
func dayInRange(target, start, end DayOfWeek) bool {
	// Normalize all inputs to canonical forms for comparison
	target = normalizeDayName(string(target))
	start = normalizeDayName(string(start))
	end = normalizeDayName(string(end))

	days := []DayOfWeek{Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday}
	startIdx := indexOf(days, start)
	endIdx := indexOf(days, end)
	targetIdx := indexOf(days, target)

	if startIdx == -1 || endIdx == -1 || targetIdx == -1 {
		return false
	}

	if startIdx <= endIdx {
		return targetIdx >= startIdx && targetIdx <= endIdx
	}
	// wrap around week (e.g., Πέμ - Τετ)
	return targetIdx >= startIdx || targetIdx <= endIdx
}

func indexOf(days []DayOfWeek, d DayOfWeek) int {
	for i, day := range days {
		if day == d {
			return i
		}
	}
	return -1
}

// ------------------ MULTI-AREA CRAWLER ------------------

func RunMultiAreaCrawler(areas []string, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	log.Println("Starting multi-area cinema crawler...")
	runAllAreas(areas)

	for range ticker.C {
		runAllAreas(areas)
	}
}

func runAllAreas(areas []string) {
	allSchedule := &MultiAreaSchedule{
		Areas:     make(map[string][]Cinema),
		UpdatedAt: time.Now(),
	}

	for _, area := range areas {
		crawler := NewCinemaCrawler(area)
		schedule, err := crawler.Crawl()
		if err != nil {
			log.Printf("Error crawling area %s: %v\n", area, err)
			continue
		}
		allSchedule.Areas[area] = schedule.Cinemas
	}

	scheduleJSON, _ := json.MarshalIndent(allSchedule, "", "  ")
	log.Printf("Multi-area schedule updated at %s\n", allSchedule.UpdatedAt.Format(time.RFC3339))
	fmt.Println(string(scheduleJSON))

	for area, cinemas := range allSchedule.Areas {
		log.Printf("\n=== TODAY'S SCHEDULE FOR AREA: %s ===", area)
		todaySchedule := &TodaySchedule{
			Date:    time.Now(),
			Cinemas: []CinemaTodayMovies{},
		}

		for ci := range cinemas {
			cinema := &cinemas[ci]

			cinemaToday := CinemaTodayMovies{
				CinemaName:    cinema.Name,
				CinemaAddress: cinema.Address,
				CinemaURL:     cinema.URL,
				CinemaSummer:  cinema.Summer,
				Movies:        []MovieWithTimes{},
			}

			// map full movie struct → times
			movieTimesMap := make(map[*Movie][]string)

			for mi := range cinema.Movies {
				movie := &cinema.Movies[mi]
				for _, screening := range movie.Screenings {
					if screening.IsToday {
						movieTimesMap[movie] = append(movieTimesMap[movie], screening.Time)
					}
				}
			}

			for movie, times := range movieTimesMap {
				if len(times) > 0 {
					cinemaToday.Movies = append(cinemaToday.Movies, MovieWithTimes{
						Movie: movie,
						Times: times,
					})
				}
			}

			if len(cinemaToday.Movies) > 0 {
				todaySchedule.Cinemas = append(todaySchedule.Cinemas, cinemaToday)
			}
		}

		todayJSON, _ := json.MarshalIndent(todaySchedule, "", "  ")
		fmt.Println(string(todayJSON))
	}
}

// ------------------ SOCIAL SHARING (OG TAGS) ------------------

func slugify(s string) string {
	var result strings.Builder
	for _, r := range strings.ToLower(strings.TrimSpace(s)) {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			result.WriteRune(r)
		} else if r == ' ' || r == '-' || r == '_' {
			result.WriteRune('-')
		}
	}
	slug := result.String()
	slug = regexp.MustCompile(`-+`).ReplaceAllString(slug, "-")
	slug = strings.Trim(slug, "-")
	return slug
}

func findMovieBySlug(slug string) *Movie {
	if latestSchedule == nil {
		return nil
	}
	for _, cinemas := range latestSchedule.Areas {
		for ci := range cinemas {
			for mi := range cinemas[ci].Movies {
				movie := &cinemas[ci].Movies[mi]
				displayTitle := movie.GreekTitle
				if displayTitle == "" {
					displayTitle = movie.Title
				}
				if slugify(displayTitle) == slug {
					return movie
				}
			}
		}
	}
	return nil
}

func handleMoviePage(w http.ResponseWriter, r *http.Request) {
	slug := strings.TrimPrefix(r.URL.Path, "/movie/")
	slug = strings.TrimSuffix(slug, "/")

	if slug == "" {
		http.NotFound(w, r)
		return
	}

	movie := findMovieBySlug(slug)
	if movie == nil {
		http.NotFound(w, r)
		return
	}

	displayTitle := movie.GreekTitle
	if displayTitle == "" {
		displayTitle = movie.Title
	}

	description := movie.Description
	if len(description) > 300 {
		description = description[:300] + "..."
	}

	scheme := r.Header.Get("X-Forwarded-Proto")
	if scheme == "" {
		scheme = "http"
		if r.TLS != nil {
			scheme = "https"
		}
	}
	host := r.Header.Get("X-Forwarded-Host")
	if host == "" {
		host = r.Host
	}

	imageURL := movie.ImageURL
	if imageURL != "" && !strings.HasPrefix(imageURL, "http") {
		imageURL = fmt.Sprintf("%s://%s%s", scheme, host, imageURL)
	}

	pageURL := fmt.Sprintf("%s://%s/movie/%s", scheme, host, slug)

	// Preserve original query params in the redirect URL
	q := r.URL.Query()
	q.Set("movie", displayTitle)
	redirectTo := "/?" + q.Encode()

	// For JS context (script tag): JSON-escape to keep & as-is (html.Entities are NOT decoded in script tags)
	redirectJS, _ := json.Marshal(redirectTo)
	// For HTML context (meta tags, href): HTML-escape
	escapedTitle := html.EscapeString(displayTitle)
	escapedDescription := html.EscapeString(description)
	escapedImage := html.EscapeString(imageURL)
	escapedPageURL := html.EscapeString(pageURL)
	escapedHref := html.EscapeString(redirectTo)

	htmlContent := fmt.Sprintf(`<!DOCTYPE html>
<html lang="el">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>%s | Cinema Screenings</title>
    <meta property="og:title" content="%s">
    <meta property="og:description" content="%s">
    <meta property="og:image" content="%s">
    <meta property="og:type" content="video.movie">
    <meta property="og:url" content="%s">
    <meta name="twitter:card" content="summary_large_image">
    <style>
        html, body { margin:0; padding:0; background: linear-gradient(135deg, #1a1a2e 0%%, #16213e 100%%); min-height:100vh; }
    </style>
    <script>window.location.replace(%s);</script>
</head>
<body>
    <p><a href="%s">%s</a></p>
</body>
</html>`, escapedTitle, escapedTitle, escapedDescription, escapedImage, escapedPageURL, string(redirectJS), escapedHref, escapedTitle)

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(htmlContent))
}

// ------------------ MAIN ------------------

// Global variable to hold the latest schedule
var latestSchedule *MultiAreaSchedule

const scheduleCacheFile = "./schedule_cache.json"

func saveScheduleCache(s *MultiAreaSchedule) {
	data, err := json.Marshal(s)
	if err != nil {
		log.Printf("Failed to marshal schedule for cache: %v", err)
		return
	}
	if err := os.WriteFile(scheduleCacheFile, data, 0644); err != nil {
		log.Printf("Failed to write schedule cache: %v", err)
	}
}

func loadScheduleCache() *MultiAreaSchedule {
	data, err := os.ReadFile(scheduleCacheFile)
	if err != nil {
		return nil
	}
	var s MultiAreaSchedule
	if err := json.Unmarshal(data, &s); err != nil {
		log.Printf("Failed to parse schedule cache: %v", err)
		return nil
	}
	return &s
}

const imageCacheDir = "./image_cache"

func cacheImage(imageURL string) (string, error) {
	if imageURL == "" {
		return "", nil
	}

	// Generate a stable filename from the URL
	hash := fmt.Sprintf("%x", md5.Sum([]byte(imageURL)))
	ext := filepath.Ext(strings.Split(imageURL, "?")[0])
	if ext == "" {
		ext = ".jpg"
	}
	filename := hash + ext
	localPath := filepath.Join(imageCacheDir, filename)
	servedPath := "/images/" + filename

	// Return cached path if already downloaded
	if _, err := os.Stat(localPath); err == nil {
		return servedPath, nil
	}

	// Download and save
	resp, err := http.Get(imageURL)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("bad status: %s", resp.Status)
	}

	f, err := os.Create(localPath)
	if err != nil {
		return "", err
	}
	defer f.Close()

	_, err = io.Copy(f, resp.Body)
	if err != nil {
		os.Remove(localPath) // clean up partial file
		return "", err
	}

	return servedPath, nil
}

func init() {
	os.MkdirAll(imageCacheDir, 0755)
}

func main() {
	skipCrawl := flag.Bool("skip-crawl", false, "skip crawling and serve cached schedule only (fast dev restart)")
	flag.Parse()

	if cached := loadScheduleCache(); cached != nil {
		latestSchedule = cached
		log.Printf("Loaded schedule from cache (updated %s)", cached.UpdatedAt.Format(time.RFC3339))
	}

	if *skipCrawl {
		if latestSchedule == nil {
			log.Fatal("--skip-crawl requires a schedule_cache.json; run once without the flag first")
		}
		log.Println("Skipping crawl, serving cached schedule")
	} else {
		areas, err := FetchCinemaAreas()
		if err != nil {
			log.Printf("Failed to fetch cinema areas: %v. Using fallback areas.", err)
			areas = []Area{
				{Slug: "marousi-_kifisia", Name: "ΜΑΡΟΥΣΙ- ΚΗΦΙΣΙΑ"},
				{Slug: "xalandri", Name: "ΧΑΛΑΝΔΡΙ"},
				{Slug: "irakleio", Name: "ΗΡΑΚΛΕΙΟ"},
			}
		}
		interval := 6 * time.Hour
		go RunMultiAreaCrawlerBackground(areas, interval)
	}

	// HTTP server
	http.HandleFunc("/api/schedule", handleScheduleForDate)
	http.HandleFunc("/movie/", handleMoviePage)             // social sharing (OG tags) + redirect
	http.Handle("/", http.FileServer(http.Dir("../web")))   // serve web app
	http.Handle("/images/", http.StripPrefix("/images/", http.FileServer(http.Dir(imageCacheDir))))

	log.Println("Server running on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

// Run crawler and update the global variable in the background
func RunMultiAreaCrawlerBackground(areas []Area, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	updateSchedule(areas)
	for range ticker.C {
		updateSchedule(areas)
	}
}

func updateSchedule(areas []Area) {
	allSchedule := &MultiAreaSchedule{
		Areas:     make(map[string][]Cinema),
		UpdatedAt: time.Now(),
	}

	for _, area := range areas {
		crawler := NewCinemaCrawler(area.Slug)
		schedule, err := crawler.Crawl()
		if err != nil {
			log.Printf("Error crawling area %s: %v\n", area, err)
			continue
		}

		// Cache all movie images
		for ci := range schedule.Cinemas {
			for mi := range schedule.Cinemas[ci].Movies {
				movie := &schedule.Cinemas[ci].Movies[mi]
				if movie.ImageURL != "" {
					localPath, err := cacheImage(movie.ImageURL)
					if err != nil {
						log.Printf("Failed to cache image for %s: %v", movie.Title, err)
					} else {
						movie.ImageURL = localPath
					}
				}
			}
		}

		allSchedule.Areas[area.Name] = schedule.Cinemas
	}

	latestSchedule = allSchedule
	log.Printf("Schedule updated at %s\n", latestSchedule.UpdatedAt.Format(time.RFC3339))
	saveScheduleCache(latestSchedule)
}

// Handler: full multi-area schedule
func handleScheduleForDate(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	if latestSchedule == nil {
		http.Error(w, "Schedule not loaded yet", http.StatusServiceUnavailable)
		return
	}

	query := r.URL.Query()
	dateStr := query.Get("date")
	var targetDate time.Time
	var err error

	if dateStr == "" {
		targetDate = time.Now()
	} else {
		targetDate, err = time.Parse("2006-01-02", dateStr) // ISO format: YYYY-MM-DD
		if err != nil {
			http.Error(w, "Invalid date format, use YYYY-MM-DD", http.StatusBadRequest)
			return
		}
	}

	result := make(map[string]*TodaySchedule)
	for area, cinemas := range latestSchedule.Areas {
		s := &Schedule{
			Area:    area,
			Cinemas: cinemas,
		}
		result[area] = s.GetScheduleForDate(targetDate)
	}

	json.NewEncoder(w).Encode(result)
}

// Handler: today's schedule
func handleTodaySchedule(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*") // allow all origins

	if latestSchedule == nil {
		http.Error(w, "Schedule not loaded yet", http.StatusServiceUnavailable)
		return
	}

	today := time.Now()
	todaySchedule := make(map[string]*TodaySchedule) // area -> today's schedule

	for area, cinemas := range latestSchedule.Areas {
		ts := &TodaySchedule{
			Date:    today,
			Cinemas: []CinemaTodayMovies{},
		}

		// iterate by index to get stable pointers
		for ci := range cinemas {
			cinema := &cinemas[ci]

			cinemaToday := CinemaTodayMovies{
				CinemaName:    cinema.Name,
				CinemaURL:     cinema.URL,
				CinemaAddress: cinema.Address,
				CinemaSummer:  cinema.Summer,
				Movies:        []MovieWithTimes{},
			}

			// map full movie struct -> list of times
			movieTimesMap := make(map[*Movie][]string)

			for mi := range cinema.Movies {
				movie := &cinema.Movies[mi]

				for _, screening := range movie.Screenings {
					if screening.IsToday {
						movieTimesMap[movie] = append(movieTimesMap[movie], screening.Time)
					}
				}
			}

			for movie, times := range movieTimesMap {
				if len(times) > 0 {
					cinemaToday.Movies = append(cinemaToday.Movies, MovieWithTimes{
						Movie: movie,
						Times: times,
					})
				}
			}

			if len(cinemaToday.Movies) > 0 {
				ts.Cinemas = append(ts.Cinemas, cinemaToday)
			}
		}

		todaySchedule[area] = ts
	}

	json.NewEncoder(w).Encode(todaySchedule)
}
