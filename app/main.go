package main

import (
	"embed"
	"io/fs"
	"log"
	"math/rand"
	"net/http"
	"strconv"
	"time"
)

// Version of the app, known at build time.
var Version = "N/A"

//go:embed public
var publicFS embed.FS

// main starts a simple app serving static files with some logic put into
// middlewares.
func main() {
	public, err := fs.Sub(publicFS, "public")
	if err != nil {
		log.Fatal(err)
	}

	m := http.NewServeMux()

	m.Handle(
		"/",
		versionResponseHeader(waitForIt(http.FileServer(http.FS(public)))),
	)

	s := &http.Server{
		Addr:         ":8080",
		Handler:      m,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: time.Minute,
	}

	log.Fatal(s.ListenAndServe())
}

// waitForIt is a middleware that sleeps to simulate long requests.
//
// pass ?seconds=<int> to make it hang for said amount of time.
func waitForIt(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		sleepValue := r.FormValue("sleep")
		sleep, _ := strconv.ParseFloat(sleepValue, 64)
		if sleep > 0. && sleep < 90. {
			time.Sleep(time.Duration(rand.Float64()*sleep) * time.Second)
		}

		handler.ServeHTTP(w, r)
	})
}

// versionResponseHeader is a middleware that puts the app version in the response.
func versionResponseHeader(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("app-version", Version)
		handler.ServeHTTP(w, r)
	})
}
