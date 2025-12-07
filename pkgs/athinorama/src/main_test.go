package main

import (
	"testing"
)

func TestParseScreeningTimes(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected []struct {
			time     string
			dayStart DayOfWeek
			dayEnd   DayOfWeek
		}
	}{
		{
			name:  "Multiple comma-separated days with colon and single time",
			input: "Πέμ., Παρ., Δευτ., Τρ., Τετ.: 17.50, Σάβ. 13.00/ 15.30/ 17.50, Κυρ. 13.00/ 15.30 μεταγλ.",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				{"17.50", Thursday, Thursday},
				{"17.50", Friday, Friday},
				{"17.50", Monday, Monday},
				{"17.50", Tuesday, Tuesday},
				{"17.50", Wednesday, Wednesday},
				{"13.00", Saturday, Saturday},
				{"15.30", Saturday, Saturday},
				{"17.50", Saturday, Saturday},
				{"13.00", Sunday, Sunday},
				{"15.30", Sunday, Sunday},
			},
		},
		{
			name:  "Single day with colon and time, another with space",
			input: "Πέμ.: 19.30, Σάβ. 17.00",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				{"19.30", Thursday, Thursday},
				{"17.00", Saturday, Saturday},
			},
		},
		{
			name:  "Day range with multiple times, comma-separated days",
			input: "Πέμ.-Σάβ.: 19.10/ 21.45, Κυρ., Τρ., Τετ. 20.30",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				// First: comma-separated days "Κυρ., Τρ., Τετ. 20.30"
				{"20.30", "Κυρ", "Κυρ"},
				{"20.30", "Τρι", "Τρι"},
				{"20.30", "Τετ", "Τετ"},
				// Then: day range "Πέμ.-Σάβ.: 19.10/ 21.45"
				{"19.10", "Πεμ", "Σαβ"},
				{"21.45", "Πεμ", "Σαβ"},
			},
		},
		{
			name:  "Short day abbreviations",
			input: "Κυ., Τρ. 20.30",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				{"20.30", Sunday, Sunday},
				{"20.30", Tuesday, Tuesday},
			},
		},
		{
			name:  "Day range without colon",
			input: "Δευ-Τετ 18.30",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				{"18.30", Monday, Wednesday},
			},
		},
		{
			name:  "Multiple times with slash separator",
			input: "Παρ. 19.00 / 21.30 / 23.45",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				{"19.00", Friday, Friday},
				{"21.30", Friday, Friday},
				{"23.45", Friday, Friday},
			},
		},
		{
			name:  "Complex multi-day with metagl suffix",
			input: "Πέμ.-Κυρ.: 18.00/ 20.30 μεταγλ., Δευτ., Τρι. 20.30",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				// First: comma-separated days "Δευτ., Τρι. 20.30"
				{"20.30", "Δευτ", "Δευτ"},
				{"20.30", "Τρι", "Τρι"},
				// Then: day range "Πέμ.-Κυρ.: 18.00/ 20.30 μεταγλ."
				{"18.00", "Πεμ", "Κυρ"},
				{"20.30", "Πεμ", "Κυρ"},
			},
		},
		{
			name:  "All short abbreviations",
			input: "Δευ., Τρ., Τε., Πε., Πα., Σα., Κυ. 21.00",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				{"21.00", Monday, Monday},
				{"21.00", Tuesday, Tuesday},
				{"21.00", Wednesday, Wednesday},
				{"21.00", Thursday, Thursday},
				{"21.00", Friday, Friday},
				{"21.00", Saturday, Saturday},
				{"21.00", Sunday, Sunday},
			},
		},
		{
			name:  "Mixed abbreviation lengths",
			input: "Πέμ., Παρ., Σάβ., Κυρ.: 19.00, Δευ., Τρι., Τετ. 21.00",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				{"19.00", Thursday, Thursday},
				{"19.00", Friday, Friday},
				{"19.00", Saturday, Saturday},
				{"19.00", Sunday, Sunday},
				{"21.00", Monday, Monday},
				{"21.00", Tuesday, Tuesday},
				{"21.00", Wednesday, Wednesday},
			},
		},
		{
			name:  "Complex mixed single days and comma lists",
			input: "Πέμ. : 17.30/ 22.15, Παρ. 21.10, Σάβ., Τρ., Τετ. 18.40, Κυρ. 16.00, Δευτ. 22.00",
			expected: []struct {
				time     string
				dayStart DayOfWeek
				dayEnd   DayOfWeek
			}{
				// First: comma-separated days "Σάβ., Τρ., Τετ. 18.40"
				{"18.40", "Σαβ", "Σαβ"},
				{"18.40", "Τρι", "Τρι"},
				{"18.40", "Τετ", "Τετ"},
				// Then: single days
				{"17.30", "Πεμ", "Πεμ"},
				{"22.15", "Πεμ", "Πεμ"},
				{"21.10", "Παρ", "Παρ"},
				{"16.00", "Κυρ", "Κυρ"},
				{"22.00", "Δευτ", "Δευτ"},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := parseScreeningTimes(tt.input)
			if err != nil {
				t.Fatalf("parseScreeningTimes() error = %v", err)
			}

			if len(result) != len(tt.expected) {
				t.Errorf("Expected %d screenings, got %d", len(tt.expected), len(result))
				t.Logf("Input: %s", tt.input)
				t.Logf("Got screenings:")
				for i, s := range result {
					t.Logf("  [%d] Time: %s, DayStart: %s, DayEnd: %s", i, s.Time, s.DayStart, s.DayEnd)
				}
				return
			}

			for i, expected := range tt.expected {
				if result[i].Time != expected.time {
					t.Errorf("Screening[%d].Time = %s, want %s", i, result[i].Time, expected.time)
				}
				if result[i].DayStart != expected.dayStart {
					t.Errorf("Screening[%d].DayStart = %s, want %s", i, result[i].DayStart, expected.dayStart)
				}
				if result[i].DayEnd != expected.dayEnd {
					t.Errorf("Screening[%d].DayEnd = %s, want %s", i, result[i].DayEnd, expected.dayEnd)
				}
			}
		})
	}
}

func TestNormalizeDayName(t *testing.T) {
	tests := []struct {
		input    string
		expected DayOfWeek
	}{
		// Monday
		{"Δευτ", Monday},
		{"Δευτ.", Monday},
		{"Δευ", Monday},
		{"Δευ.", Monday},
		{"δευτ", Monday},

		// Tuesday
		{"Τρι", Tuesday},
		{"Τρι.", Tuesday},
		{"Τρ", Tuesday},
		{"Τρ.", Tuesday},
		{"τρι", Tuesday},
		{"τρ", Tuesday},

		// Wednesday
		{"Τετ", Wednesday},
		{"Τετ.", Wednesday},
		{"Τε", Wednesday},
		{"Τε.", Wednesday},
		{"τετ", Wednesday},

		// Thursday
		{"Πέμ", Thursday},
		{"Πέμ.", Thursday},
		{"Πεμ", Thursday},
		{"Πεμ.", Thursday},
		{"Πε", Thursday},
		{"Πε.", Thursday},
		{"πέμ", Thursday},
		{"πεμ", Thursday},

		// Friday
		{"Παρ", Friday},
		{"Παρ.", Friday},
		{"Πα", Friday},
		{"Πα.", Friday},
		{"παρ", Friday},

		// Saturday
		{"Σάβ", Saturday},
		{"Σάβ.", Saturday},
		{"Σαβ", Saturday},
		{"Σαβ.", Saturday},
		{"Σα", Saturday},
		{"Σα.", Saturday},
		{"σάβ", Saturday},
		{"σαβ", Saturday},

		// Sunday
		{"Κυρ", Sunday},
		{"Κυρ.", Sunday},
		{"Κυ", Sunday},
		{"Κυ.", Sunday},
		{"κυρ", Sunday},
		{"κυ", Sunday},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := normalizeDayName(tt.input)
			if result != tt.expected {
				t.Errorf("normalizeDayName(%q) = %s, want %s", tt.input, result, tt.expected)
			}
		})
	}
}
func TestParseDayRange(t *testing.T) {
	tests := []struct {
		input         string
		expectedStart DayOfWeek
		expectedEnd   DayOfWeek
	}{
		{"Πέμ.-Κυρ.", Thursday, Sunday},
		{"Δευ-Τετ", Monday, Wednesday},
		{"Παρ", Friday, Friday},
		{"Κυρ.", Sunday, Sunday},
		{"Τρ.-Πε.", Tuesday, Thursday},
		{"Σάβ.-Δευ.", Saturday, Monday},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			start, end, err := parseDayRange(tt.input)
			if err != nil {
				t.Fatalf("parseDayRange(%q) error = %v", tt.input, err)
			}
			if start != tt.expectedStart {
				t.Errorf("parseDayRange(%q) start = %s, want %s", tt.input, start, tt.expectedStart)
			}
			if end != tt.expectedEnd {
				t.Errorf("parseDayRange(%q) end = %s, want %s", tt.input, end, tt.expectedEnd)
			}
		})
	}
}
