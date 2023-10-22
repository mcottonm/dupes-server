#!/bin/bash
set -e; set -o pipefail; set -m

my_dir=$(dirname $(readlink -f "$0"))

echo "START DEPLOY DB"
$my_dir/deploy/deploy-db.sh

echo "START DEPLOY SERVER"
$my_dir/deploy/deploy-server.sh
