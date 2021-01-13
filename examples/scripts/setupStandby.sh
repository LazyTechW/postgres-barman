#!/bin/bash

set -e

# if [[ -z "$2" ]]; then
#   echo "Usage: $0 us_host replicate_password"
#   exit
# fi

# us_port=5432
# us_host=$1
# PGPASSWORD=$2

# us_host=dba
# PGPASSWORD=bYIGvuwkJ2g

# backupService=dbb

# dbuser=replicator
# PGDATA=/var/lib/postgresql/data/pgdata
# docker_image=postgres:alpine

#---------- Copy and paste the following, whether it is windows or linux

docker-compose up -d

docker-compose rm -sf dbb
rm -rf dbbData

# echo "Mv the old data..."
# backupDir=~/dbbackup-`date "+%Y%m%d-%H%M%S-%N"`
# sudo mv ~/data/db $backupDir || echo "Ignore mv error."

docker-compose exec dba bash -c "psql -U postgres -f /scripts/createReplicator.sql"
docker-compose exec dba bash -c "psql -U postgres -f /scripts/initDb.sql"

# Replace ${PWD} with %cd% for Windows
docker run --rm -ti --network=replication_default -v ${PWD}/dbbData:/var/lib/postgresql/data/pgdata postgres:alpine bash -c "PGPASSWORD=bYIGvuwkJ2g pg_basebackup -h dba -U replicator -w -p 5432 -D /var/lib/postgresql/data/pgdata -P -Xs -R"

docker-compose up -d

# Check
docker-compose exec db psql -U postgres -c 'SELECT * from pg_stat_wal_receiver;'

