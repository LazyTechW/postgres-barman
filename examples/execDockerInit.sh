#!/bin/bash

set -v

servers="pg pgb"
for i in $servers
do
  docker-compose exec -T $i bash '/docker-entrypoint-initdb.d/01_barman.sh'
done

