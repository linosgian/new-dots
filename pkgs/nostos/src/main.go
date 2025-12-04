package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"
)

func main() {
	// Get environment variables or set default values
	streamURL := os.Getenv("STREAM_URL")
	if streamURL == "" {
		streamURL = "https://rdst.win:48051/" // Default stream URL
	}

	outputPath := os.Getenv("OUTPUT_PATH")
	if outputPath == "" {
		// Default to current directory if no OUTPUT_PATH is set
		outputPath = "."
	}

	// Get the recording duration from the environment variable or set the default to one hour
	recordingDuration := time.Hour
	durationStr := os.Getenv("RECORDING_DURATION")
	if durationStr != "" {
		duration, err := time.ParseDuration(durationStr)
		if err != nil {
			log.Printf("Invalid RECORDING_DURATION value: %v. Using default duration of 1 hour.", err)
		} else {
			recordingDuration = duration
		}
	}

	// Generate the filename based on the current date
	fileName := fmt.Sprintf("%s/%s.mp3", outputPath, time.Now().Format("02-01-06"))

	// Create a temporary file in /tmp
	tmpFileName := filepath.Join("/tmp", fmt.Sprintf("%s.mp3", time.Now().Format("02-01-06")))
	file, err := os.Create(tmpFileName)
	if err != nil {
		log.Fatalf("Error creating temporary file: %v", err)
	}
	defer file.Close()

	// Set up a timer to stop recording after the configured duration
	stopTime := time.Now().Add(recordingDuration)

	// Handle system interrupts (Ctrl+C) to cleanly stop recording
	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-signalChan
		log.Println("\nRecording stopped by user. Moving file to final location.")
		moveFile(tmpFileName, fileName)
		os.Exit(0)
	}()

	// Start a goroutine to handle the recording
	go func() {
		for time.Now().Before(stopTime) {
			// Connecting to the stream
			log.Println("Connecting to stream...")

			// Make a GET request to the stream URL
			resp, err := http.Get(streamURL)
			if err != nil {
				log.Printf("Error connecting to stream: %v. Retrying...", err)
				time.Sleep(5 * time.Second) // Wait before retrying
				continue
			}

			// Check for a successful response
			if resp.StatusCode != http.StatusOK {
				log.Printf("Failed to connect to stream. HTTP status: %s. Retrying...", resp.Status)
				resp.Body.Close()
				time.Sleep(5 * time.Second)
				continue
			}

			log.Println("Recording audio stream...")

			// Copy the stream to the file until an error occurs or timeout
			_, err = io.Copy(file, resp.Body)
			if err != nil {
				log.Printf("Error reading stream: %v. Reconnecting...", err)
			}

			// Close the response body and retry on errors
			resp.Body.Close()
		}

		log.Println("Recording stopped after configured duration. Moving file to final location.")
		moveFile(tmpFileName, fileName)
	}()

	// Wait for the recording duration to elapse
	<-time.After(recordingDuration)
	log.Println("Recording duration elapsed, stopping.")
	moveFile(tmpFileName, fileName)
}

// moveFile copies the temporary file to the final destination and removes the temporary file
func moveFile(tmpFileName, finalFileName string) {
	// Open the temporary file
	tmpFile, err := os.Open(tmpFileName)
	if err != nil {
		log.Printf("Error opening temporary file: %v", err)
		return
	}
	defer tmpFile.Close()

	// Create the final file
	finalFile, err := os.Create(finalFileName)
	if err != nil {
		log.Printf("Error creating final file: %v", err)
		return
	}
	defer finalFile.Close()

	// Copy the content from the temporary file to the final file
	_, err = io.Copy(finalFile, tmpFile)
	if err != nil {
		log.Printf("Error copying file: %v", err)
		return
	}

	// Remove the temporary file
	err = os.Remove(tmpFileName)
	if err != nil {
		log.Printf("Error deleting temporary file: %v", err)
	} else {
		log.Printf("Temporary file deleted: %s", tmpFileName)
	}

	log.Printf("File successfully moved to: %s", finalFileName)
}
