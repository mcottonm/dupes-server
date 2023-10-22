#!/bin/bash
set -e; set -o pipefail; set -m

function my_ip() {
  local default_iface=$(ip route get 1 | grep -o "dev.*" | awk '{print $2}')
  ip addr show dev $default_iface | awk '/inet /{print $2}' | cut -f '1' -d '/'
}

POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-$(openssl rand -hex 16 2>/dev/null)}
POSTGRES_USER='core_db'
POSTGRES_HOST="0.0.0.0"
POSTGRES_PORT=5432
POSTGRES_DB='core_db'

env_file=$HOME/.env
cat <<EOF > ${env_file}
export POSTGRES_USER=${POSTGRES_USER}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
export POSTGRES_HOST=${POSTGRES_HOST}
export POSTGRES_PORT=${POSTGRES_PORT}
export POSTGRES_DB=${POSTGRES_DB}
EOF

buffers=$(($(grep 'MemTotal:' /proc/meminfo | sed -r 's/[^[:digit:]]+//g') / (3<<20)))
if ((0 == buffers)); then
  exit 22
fi

docker run -d --name="${POSTGRES_DB}" $(cat $env_file | tr '\n' ' ' | sed 's/export/--env/g') -p 5432:5432 \
    postgres -c shared_buffers=${buffers}GB -c effective_io_concurrency=200 \
  -c max_worker_processes=32 -c enable_seqscan=off \
  -c enable_bitmapscan=off -c jit=off

#try to avoid wsl docker bridge
POSTGRES_HOST=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $POSTGRES_DB)
cat <<EOF > ${env_file}
export POSTGRES_USER=${POSTGRES_USER}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
export POSTGRES_HOST=${POSTGRES_HOST}
export POSTGRES_PORT=${POSTGRES_PORT}
export POSTGRES_DB=${POSTGRES_DB}
EOF

# the container does not have time to rise, so we sleep.
sleep 10
