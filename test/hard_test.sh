#!/bin/bash
set -e; set -o pipefail; set -m

. $HOME/.env

my_dir=$(dirname $(readlink -f "$0"))

docker exec -t ${POSTGRES_DB} psql -U ${POSTGRES_USER} -c "TRUNCATE conn_log"

docker exec -i ${POSTGRES_DB} psql -U ${POSTGRES_USER} \
 -c "COPY conn_log FROM STDIN WITH (FORMAT csv);" < $my_dir/rows.csv

sleep 10

curl $SERVER_HOST:$SERVER_PORT/1/2 &> 1.test& 
curl $SERVER_HOST:$SERVER_PORT/1/3 &> 2.test&
curl $SERVER_HOST:$SERVER_PORT/2/1 &> 3.test&
curl $SERVER_HOST:$SERVER_PORT/366/366 &> 4.test&
curl $SERVER_HOST:$SERVER_PORT/3/3 &> 5.test&
curl $SERVER_HOST:$SERVER_PORT/99/4 &> 6.test&
curl $SERVER_HOST:$SERVER_PORT/3/1000 &> 7.test&
wait

if ! grep "{ \"dupes\": false }" 1.test; then
    echo fail 1.test
    cat 1.test
    exit 1
fi
if ! grep "{ \"dupes\": false }" 2.test; then
    echo fail 2.test
    cat 2.test
    exit 1
fi
if ! grep "{ \"dupes\": false }" 3.test; then
    echo fail 3.test
    cat 3.test
    exit 1
fi
if ! grep "{ \"dupes\": true }" 4.test; then
    echo fail 4.test
    cat 1.test
    exit 1
fi
if ! grep "{ \"dupes\": true }" 5.test; then
    echo fail 5.test
    cat 1.test
    exit 1
fi

if ! grep "{ \"dupes\": false }" 6.test; then
    echo fail 6.test
    cat 1.test
    exit 1
fi
if ! grep "{ \"dupes\": false }" 7.test; then
    echo fail 7.test
    cat 1.test
    exit 1
fi
