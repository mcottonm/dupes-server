#!/bin/bash
set -e; set -o pipefail; set -m

. $HOME/.env

docker exec -t ${POSTGRES_DB} psql -U ${POSTGRES_USER} -c "TRUNCATE conn_log"

docker exec -i ${POSTGRES_DB} psql -U ${POSTGRES_USER} -c "COPY conn_log FROM STDIN WITH (FORMAT csv);" <<EOF
1, 127.0.0.1, 2023-10-21 17:51:59
2, 127.0.0.1, 2023-10-21 17:52:59
1, 127.0.0.1, 2023-10-21 17:52:59
1, 127.0.0.2, 2023-10-21 17:53:59
2, 127.0.0.2, 2023-10-21 17:54:59
2, 127.0.0.3, 2023-10-21 17:55:59
3, 127.0.0.3, 2023-10-21 17:55:59
3, 127.0.0.1, 2023-10-21 17:56:59
4, 127.0.0.1, 2023-10-21 17:57:59
EOF

sleep 10

curl $SERVER_HOST:$SERVER_PORT/1/2 &> 1.test& 
curl $SERVER_HOST:$SERVER_PORT/1/3 &> 2.test&
curl $SERVER_HOST:$SERVER_PORT/2/1 &> 3.test&
curl $SERVER_HOST:$SERVER_PORT/2/3 &> 4.test&
curl $SERVER_HOST:$SERVER_PORT/3/2 &> 5.test&
curl $SERVER_HOST:$SERVER_PORT/1/4 &> 6.test&
curl $SERVER_HOST:$SERVER_PORT/3/1 &> 7.test&
wait

if ! grep "{ \"dupes\": true }" 1.test; then
    echo fail 1.test
    cat 1.test
    exit 1
fi
if ! grep "{ \"dupes\": false }" 2.test; then
    echo fail 2.test
    cat 2.test
    exit 1
fi
if ! grep "{ \"dupes\": true }" 3.test; then
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

echo SUCCESS
