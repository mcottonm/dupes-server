package dupes_server

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"sync"
	"time"

	"dupes-server/pkg/database"

	"github.com/gorilla/mux"

	"github.com/jackc/pgx/v4"
	log "github.com/sirupsen/logrus"
)

const (
	syncDuration = 10
	ipsMapSize   = 1 << 16
)

type DupesServer struct {
	*pgx.Conn
	rwMutex sync.RWMutex
	ipsMap  map[int]map[string]struct{}
}

func NewDupesServer() *DupesServer {
	pool, err := database.GetConnectinPool()
	if err != nil {
		log.Fatal(err)
	}
	ds := DupesServer{pool, sync.RWMutex{}, make(map[int]map[string]struct{}, ipsMapSize)}
	ds.updateIPs()
	return &ds
}

func (ds *DupesServer) updateIPs() error {
	query := `SELECT user_id, ip_addr FROM conn_log`
	log.Trace("Start query:", query)
	rows, err := ds.Query(context.Background(), query)
	tmpMap := make(map[int]map[string]struct{}, 10000)
	id := 0
	ip := ""
	for rows.Next() {
		err = rows.Scan(&id, &ip)
		if err != nil {
			return err
		}
		ips := tmpMap[id]
		if len(ips) == 0 {
			ips = make(map[string]struct{})
		}
		ips[ip] = struct{}{}
		tmpMap[id] = ips
	}
	log.Trace("End query:", query, err, len(tmpMap))
	ds.rwMutex.Lock()
	ds.ipsMap = tmpMap
	ds.rwMutex.Unlock()
	return nil
}

func (ds *DupesServer) Syncing() {
	go func() {
		for {
			if err := ds.updateIPs(); err != nil {
				log.Fatal("Sync failed", err)
			}
			time.Sleep(syncDuration * time.Second)
		}
	}()
}

type HandlerType func(http.ResponseWriter, *http.Request)

func fail(resp http.ResponseWriter, loglvl func(args ...interface{}), code int, err error) {
	resp.WriteHeader(code)
	resp.Write([]byte(err.Error() + "\n"))
	loglvl(err)
}

func logRespProgress(progress string, req *http.Request) {
	log.Infof("%s methd:%s url:%s addr:%s", progress, req.Method, req.URL, req.RemoteAddr)
}

func (ds *DupesServer) GetGetHandler() HandlerType {
	return func(resp http.ResponseWriter, req *http.Request) {
		logRespProgress("Start:", req)
		ids, err := getIds(req)
		if err != nil {
			fail(resp, log.Error, 200, err)
		}

		reqCtx := req.Context()
		workCtx, cancel := context.WithCancel(reqCtx)
		defer cancel()
		workDone := make(chan struct{})

		isDouble := false
		go func() {
			isDouble = ds.isDouble(workCtx, ids)
			workDone <- struct{}{}
		}()

		select {
		case <-reqCtx.Done():
			logRespProgress("Canceled:", req)
			return
		case <-workDone:
		}
		status, err := response(resp, isDouble)
		errtext := ""
		if err != nil {
			errtext = err.Error()
		}
		logRespProgress(fmt.Sprintf("Finish: send bytes: %d, err: %s", status, errtext), req)
	}
}

func getIds(req *http.Request) ([]int, error) {
	log.Trace("getIds:")
	id1, err := strconv.Atoi(mux.Vars(req)["id1"])
	if err != nil {
		return nil, err
	}
	id2, err := strconv.Atoi(mux.Vars(req)["id2"])
	if err != nil {
		return nil, err
	}
	return []int{id1, id2}, nil
}

func (ds *DupesServer) isDouble(ctx context.Context, ids []int) (isDouble bool) {
	ds.rwMutex.RLock()
	defer ds.rwMutex.RUnlock()
	id1 := ds.ipsMap[ids[0]]
	id2 := ds.ipsMap[ids[1]]
	c := 0
	for ip := range id1 {
		_, ok := id2[ip]
		if ok {
			c++
		}
		if c > 1 {
			return true
		}
	}
	return false
}

func response(resp http.ResponseWriter, isDouble bool) (int, error) {
	log.Trace("response:")
	return resp.Write([]byte(fmt.Sprintf("{ \"dupes\": %t }", isDouble)))
}
