#!/bin/bash
set -e; set -o pipefail; set -m

env_file=${env_file:-$HOME/.env}
. $env_file

my_dir=$(dirname $(readlink -f "$0"))

SERVER_HOST=${SERVER_HOST:-"0.0.0.0"}
SERVER_PORT=${SERVER_PORT:-"9696"}

pushd $my_dir
go build $my_dir/../cmd/dupes-server/
popd

env_file=$HOME/.env
cat <<EOF >> ${env_file}
export SERVER_HOST=${SERVER_HOST}
export SERVER_PORT=${SERVER_PORT}
export BIN_DIR=${BIN_DIR}
EOF

docker exec -t ${POSTGRES_DB} psql -U ${POSTGRES_USER} -c "create table if not exists conn_log ( user_id bigint, ip_addr varchar(15), ts timestamp)"

pushd $my_dir
docker build --tag dupes-server .
popd

docker run -d --name="dupes-server" $(cat $env_file | tr '\n' ' ' | sed 's/export/--env/g') -p $SERVER_PORT:$SERVER_PORT dupes-server
