#!/bin/bash

# Usage:
# Test with SSH_ON
# ./test 1
# Test with SSH_OFF
# ./test 0

function title() {
set +v
echo
echo ==========$@
echo
set -v
}

set -v

#==========
title Bring up cluster

BARMAN_SSH_ON=$1
[[ -z "${BARMAN_SSH_ON}" ]] && BARMAN_SSH_ON=0

# Change .env based on the BARMAN_SSH_ON
sed -i "/BARMAN_SSH_ON/d" ./.env
if [[ "$BARMAN_SSH_ON" == "1" ]]; then
  echo "BARMAN_SSH_ON=1" >> ./.env
fi

docker-compose up -d --remove-orphans

docker-compose exec barman /wait-for pg:5432 -- echo "DB is up"
bash execDockerInit.sh

#==========
title Check general

docker-compose ps
docker-compose exec -T pg psql -c "SELECT version()" -U barman postgres
docker-compose exec -T pgb psql -c "SELECT version()" -U barman postgres

# Here test the barman alias defined in ~/.ssh/config
docker-compose exec -T pg gosu postgres ssh barman -C true
docker-compose exec -T pgb gosu postgres ssh barman -C true
docker-compose exec -T barman gosu barman ssh postgres@pg -C true
docker-compose exec -T barman gosu barman ssh postgres@pgb -C true

# Manually exec cron, since the default cron needs 1 min.
docker-compose exec -T barman gosu barman barman cron

docker-compose exec -T barman gosu barman barman switch-xlog --force --archive --archive-timeout 30 all

# Barman check
docker-compose exec -T barman gosu barman barman check all
docker-compose exec -T barman gosu barman barman check all | grep -vF FAILED &> /dev/null

#==========
title Check config

docker-compose exec -T barman ls /etc/barman.d/
docker-compose exec -T barman cat /etc/barman.d/pg.conf
docker-compose exec -T barman cat /etc/barman.d/pgb.conf
if [[ "${BARMAN_SSH_ON}" == "1" ]]; then
docker-compose exec -T barman cat /etc/barman.d/pg-ssh.conf
docker-compose exec -T barman cat /etc/barman.d/pgb-ssh.conf
fi

#==========
title Check backup and recover

if [[ "${BARMAN_SSH_ON}" == "1" ]]; then
  barman_methods="ssh streaming"
else
  barman_methods="streaming"
fi


for i in pg pgb
do

# Cleanup old backups. For testing only.
docker-compose exec -T $i rm -rf /var/lib/postgresql/data/recovered.ssh
docker-compose exec -T $i rm -rf /var/lib/postgresql/data/recovered.streaming

for j in $barman_methods
do

#----------
title $i-$j

# Backup
docker-compose exec -T barman gosu barman barman backup -w $i-$j
echo
docker-compose exec -T barman gosu barman barman list-backup $i-$j
echo

echo ----------
docker-compose exec -T barman gosu barman tail -n 50 /var/log/barman/barman.log
echo ----------

# Recover

target=$(docker-compose exec -T barman gosu barman barman list-backup $i-$j | head -n 1 | cut -d ' ' -f2)
echo Recover target: $target

docker-compose exec -T barman gosu barman barman recover $i-$j $target /var/lib/postgresql/data/recovered.$j --remote-ssh-command "ssh postgres@$i"
docker-compose exec -T $i ls /var/lib/postgresql/data/recovered.$j

# Must remove it, otherwise it will be a problem for backup later on.
docker-compose exec -T $i rm -rf /var/lib/postgresql/data/recovered.$j

done
done

#==========

title Cleanup

# Recover .env
sed -i "/BARMAN_SSH_ON/d" ./.env
