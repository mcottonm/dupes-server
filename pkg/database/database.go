package database

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v4"
	log "github.com/sirupsen/logrus"
)

func GetConnectinPool() (*pgx.Conn, error) {
	url := fmt.Sprintf("user=%v password=%v host=%v port=%v database=%v sslmode=disable",
		os.Getenv("POSTGRES_USER"),
		os.Getenv("POSTGRES_PASSWORD"),
		os.Getenv("POSTGRES_HOST"),
		os.Getenv("POSTGRES_PORT"),
		os.Getenv("POSTGRES_DB"),
	)
	log.Trace("try to connect: ", url)
	return pgx.Connect(context.Background(), url)
}
