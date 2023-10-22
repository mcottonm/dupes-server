package main

import (
	"fmt"
	"net/http"
	"os"

	server "dupes-server/pkg/dupes-server"

	"github.com/gorilla/mux"
	"github.com/jessevdk/go-flags"
	log "github.com/sirupsen/logrus"
)

var opts struct {
	Host    string `long:"host" env:"SERVER_HOST" description:"host" required:"yes"`
	Port    string `long:"port" env:"SERVER_PORT" description:"port" required:"yes"`
	Verbose bool   `short:"v" long:"verbose" value-name:"VERBOSE" description:"log level trace"`
}

func main() {
	if _, err := flags.Parse(&opts); err != nil {
		log.WithError(err).Error("Can't parse opts")
		flags.NewParser(&opts, flags.Default).WriteHelp(os.Stdout)
		os.Exit(22)
	}
	if opts.Verbose {
		log.SetLevel(log.TraceLevel)
	} else {
		log.SetLevel(log.DebugLevel)
	}
	router := mux.NewRouter()
	server := server.NewDupesServer()
	server.Syncing()
	router.HandleFunc("/{id1:[0-9]+}/{id2:[0-9]+}", server.GetGetHandler()).Methods("GET")
	log.Infof("listen: %s:%s", opts.Host, opts.Port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s:%s", opts.Host, opts.Port), router))
}
