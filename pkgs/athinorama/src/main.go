package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/gocolly/colly/v2"
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
	Genre         string      `json:"genre,omitempty"`
	Duration      string      `json:"duration,omitempty"`
	Year          string      `json:"year,omitempty"`
	URL           string      `json:"url,omitempty"`
	Rating        string      `json:"rating,omitempty"`
	Description   string      `json:"description,omitempty"`
	Screenings    []Screening `json:"screenings"`
}

// Cinema represents a cinema with its movies
type Cinema struct {
	Name    string  `json:"name"`
	Address string  `json:"address,omitempty"`
	Phone   string  `json:"phone,omitempty"`
	URL     string  `json:"url,omitempty"`
	Movies  []Movie `json:"movies"`
}

// MovieSearchResult represents all screenings for a specific movie across all areas
type MovieSearchResult struct {
	Movie      *Movie          `json:"movie"`
	TotalShows int             `json:"total_shows"`
	Areas      []MovieAreaInfo `json:"areas"`
	UpdatedAt  time.Time       `json:"updated_at"`
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

// CrawlMovieDetails fetches additional movie info from the movie detail page
func CrawlMovieDetails(movieURL string) (string, string, string, string, string, string, string, string, error) {
	c := colly.NewCollector(
		colly.AllowedDomains("www.athinorama.gr", "athinorama.gr"),
	)

	var (
		originalTitle string
		year          string
		duration      string
		genre         string
		director      string
		greekTitle    string
		rating        string
		description   string
	)

	c.OnHTML("ul.review-details", func(e *colly.HTMLElement) {
		originalTitle = strings.TrimSpace(e.ChildText("span.original-title"))
		year = strings.TrimSpace(e.ChildText("span.year"))
		duration = normalizeDuration(strings.TrimSpace(e.ChildText("span.duration")))
		rating = strings.TrimSpace(e.ChildText("span.rating-value"))
		genre = strings.TrimSpace(e.ChildText("span.genre"))
		director = strings.TrimSpace(e.ChildText("span.director"))
	})

	c.OnHTML("div.review-title h1", func(e *colly.HTMLElement) {
		greekTitle = strings.TrimSpace(e.Text)
	})

	c.OnHTML("div.summary p", func(e *colly.HTMLElement) {
		description = strings.TrimSpace(e.Text)
	})

	c.OnError(func(r *colly.Response, err error) {
		log.Printf("Movie detail request failed: %v", err)
	})

	err := c.Visit(movieURL)
	if err != nil {
		return "", "", "", "", "", "", "", "", err
	}

	return description, greekTitle, originalTitle, year, duration, genre, director, rating, nil
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
			description, greekTitle, original, year, duration, genre, director, rating, err := CrawlMovieDetails(movieURL)
			if err == nil {
				movie.OriginalTitle = original
				movie.Year = year
				movie.Duration = duration
				movie.Genre = genre
				movie.Director = director
				movie.GreekTitle = greekTitle
				movie.Rating = rating
				movie.Description = description
			} else {
				log.Println("Failed to fetch movie details:", err)
			}

			// Parse screening times
			scheduleText := strings.TrimSpace(movieEl.Text)
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

// Replace the parseScreeningTimes function with this improved version
func parseScreeningTimes(scheduleStr string) ([]Screening, error) {
	scheduleStr = strings.TrimSpace(scheduleStr)
	var screenings []Screening
	if scheduleStr == "" {
		return screenings, nil
	}

	// Normalize whitespace
	scheduleStr = strings.ReplaceAll(scheduleStr, "\n", " ")
	scheduleStr = regexp.MustCompile(`\s+`).ReplaceAllString(scheduleStr, " ")

	// Track already processed segments to avoid duplicates
	processedRanges := make([]struct{ start, end int }, 0)

	isProcessed := func(start, end int) bool {
		for _, pr := range processedRanges {
			// Check if there's any overlap
			if start < pr.end && end > pr.start {
				return true
			}
		}
		return false
	}

	markProcessed := func(start, end int) {
		processedRanges = append(processedRanges, struct{ start, end int }{start, end})
	}

	dayPattern := `[ΔΤΠΣΚ][α-ωά-ώ]*\.?`

	// Pattern 1: Comma-separated list of days followed by times
	// Example: "Πέμ., Παρ., Δευτ., Τρ., Τετ.: 17.50"
	listPattern := fmt.Sprintf(`((?:%s\s*,\s*)+%s)\s*:?\s*([\d.:/ ]+(?:\s*μεταγλ\.?)?)`, dayPattern, dayPattern)
	listRe := regexp.MustCompile(listPattern)
	listMatches := listRe.FindAllStringSubmatchIndex(scheduleStr, -1)

	for _, match := range listMatches {
		if len(match) < 6 {
			continue
		}

		if isProcessed(match[0], match[1]) {
			continue
		}
		markProcessed(match[0], match[1])

		daysStr := scheduleStr[match[2]:match[3]]
		timesPart := strings.TrimSpace(scheduleStr[match[4]:match[5]])

		if timesPart == "" {
			continue
		}

		// Clean up times
		timesPart = strings.TrimSuffix(timesPart, "μεταγλ.")
		timesPart = strings.TrimSuffix(timesPart, "μεταγλ")
		timesPart = strings.TrimSpace(timesPart)

		// Split times by / or :
		times := regexp.MustCompile(`[/:]+`).Split(timesPart, -1)
		var cleanTimes []string
		for _, t := range times {
			t = strings.TrimSpace(t)
			if regexp.MustCompile(`^\d{1,2}\.\d{2}$`).MatchString(t) {
				cleanTimes = append(cleanTimes, t)
			}
		}

		// Split days by comma
		dayParts := strings.Split(daysStr, ",")
		for _, dayStr := range dayParts {
			dayStr = strings.TrimSpace(dayStr)
			day := normalizeDayName(dayStr)

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

	// Pattern 2: Day ranges with times
	// Example: "Πέμ.-Σάβ.: 19.10"
	rangePattern := fmt.Sprintf(`(%s)\s*-\s*(%s)\s*:?\s*([\d.:/ ]+(?:\s*μεταγλ\.?)?)`, dayPattern, dayPattern)
	rangeRe := regexp.MustCompile(rangePattern)
	rangeMatches := rangeRe.FindAllStringSubmatchIndex(scheduleStr, -1)

	for _, match := range rangeMatches {
		if len(match) < 8 {
			continue
		}

		if isProcessed(match[0], match[1]) {
			continue
		}
		markProcessed(match[0], match[1])

		startDay := scheduleStr[match[2]:match[3]]
		endDay := scheduleStr[match[4]:match[5]]
		timesPart := strings.TrimSpace(scheduleStr[match[6]:match[7]])

		if timesPart == "" {
			continue
		}

		// Clean up times
		timesPart = strings.TrimSuffix(timesPart, "μεταγλ.")
		timesPart = strings.TrimSuffix(timesPart, "μεταγλ")
		timesPart = strings.TrimSpace(timesPart)

		times := regexp.MustCompile(`[/:]+`).Split(timesPart, -1)
		var cleanTimes []string
		for _, t := range times {
			t = strings.TrimSpace(t)
			if regexp.MustCompile(`^\d{1,2}\.\d{2}$`).MatchString(t) {
				cleanTimes = append(cleanTimes, t)
			}
		}

		start, end, _ := parseDayRange(startDay + "-" + endDay)
		for _, t := range cleanTimes {
			screenings = append(screenings, Screening{
				Time:     t,
				DayStart: start,
				DayEnd:   end,
				IsToday:  isTodayInRange(start, end),
			})
		}
	}

	// Pattern 3: Single day with times (not already processed)
	// Example: "Κυρ. 13.00" or "Πέμ.: 19.30"
	singlePattern := fmt.Sprintf(`(%s)\s*:?\s*([\d.:/ ]+(?:\s*μεταγλ\.?)?)`, dayPattern)
	singleRe := regexp.MustCompile(singlePattern)
	singleMatches := singleRe.FindAllStringSubmatchIndex(scheduleStr, -1)

	for _, match := range singleMatches {
		if len(match) < 6 {
			continue
		}

		if isProcessed(match[0], match[1]) {
			continue
		}
		markProcessed(match[0], match[1])

		dayStr := scheduleStr[match[2]:match[3]]
		timesPart := strings.TrimSpace(scheduleStr[match[4]:match[5]])

		if timesPart == "" {
			continue
		}

		// Clean up times
		timesPart = strings.TrimSuffix(timesPart, "μεταγλ.")
		timesPart = strings.TrimSuffix(timesPart, "μεταγλ")
		timesPart = strings.TrimSpace(timesPart)

		times := regexp.MustCompile(`[/:]+`).Split(timesPart, -1)
		var cleanTimes []string
		for _, t := range times {
			t = strings.TrimSpace(t)
			if regexp.MustCompile(`^\d{1,2}\.\d{2}$`).MatchString(t) {
				cleanTimes = append(cleanTimes, t)
			}
		}

		day := normalizeDayName(dayStr)
		for _, t := range cleanTimes {
			screenings = append(screenings, Screening{
				Time:     t,
				DayStart: day,
				DayEnd:   day,
				IsToday:  isTodayInRange(day, day),
			})
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
	days := []DayOfWeek{"Δευ", "Τρι", "Τετ", "Πεμ", "Παρ", "Σαβ", "Κυρ"}
	startIdx := indexOf(days, start)
	endIdx := indexOf(days, end)
	targetIdx := indexOf(days, target)

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

// ------------------ MAIN ------------------

// Global variable to hold the latest schedule
var latestSchedule *MultiAreaSchedule

func main() {
	areas := []string{
		"marousi-_kifisia",
		"xalandri",
		"irakleio",
	}
	interval := 6 * time.Hour

	// Start crawler in background
	go func() {
		RunMultiAreaCrawlerBackground(areas, interval)
	}()

	// HTTP server
	http.HandleFunc("/api/schedule", handleScheduleForDate)
	http.Handle("/", http.FileServer(http.Dir("../web"))) // serve web app

	log.Println("Server running on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

// Run crawler and update the global variable in the background
func RunMultiAreaCrawlerBackground(areas []string, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	updateSchedule(areas)
	for range ticker.C {
		updateSchedule(areas)
	}
}

func updateSchedule(areas []string) {
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

	latestSchedule = allSchedule
	log.Printf("Schedule updated at %s\n", latestSchedule.UpdatedAt.Format(time.RFC3339))
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
