#!/bin/bash

set -v

echo ==========Check general

docker-compose ps
docker-compose exec -T pg psql -c "SELECT version()" -U barman postgres
docker-compose exec -T pgb psql -c "SELECT version()" -U barman postgres
# Here test the barman alias defined in ~/.ssh/config
docker-compose exec -T pg gosu postgres ssh barman -C true
docker-compose exec -T pgb gosu postgres ssh barman -C true
docker-compose exec -T barman gosu barman ssh postgres@pg -C true
docker-compose exec -T barman gosu barman ssh postgres@pgb -C true

docker-compose exec -T barman gosu barman barman switch-xlog --force --archive --archive-timeout 30 all

# Barman check
docker-compose exec -T barman gosu barman barman check all
docker-compose exec -T barman gosu barman barman check all | grep -vF FAILED &> /dev/null

echo ==========Check config

docker-compose exec -T barman ls /etc/barman.d/
docker-compose exec -T barman cat /etc/barman.d/pg.conf
docker-compose exec -T barman cat /etc/barman.d/pgb.conf

echo ==========Check backup and recover

for i in pg pgb
do

for j in ssh streaming
do

echo =====$i-$j

# Backup
docker-compose exec -T barman gosu barman barman backup -w $i-$j
docker-compose exec -T barman gosu barman barman list-backup $i-$j
echo
docker-compose exec -T barman gosu barman tail -n 50 /var/log/barman/barman.log
echo

# Recover

target=$(docker-compose exec -T barman gosu barman barman list-backup $i-$j | head -n 1 | cut -d ' ' -f2)
echo Recover target: $target

docker-compose exec -T barman gosu barman barman recover $i-$j $target /var/lib/postgresql/data/recovered.$j --remote-ssh-command "ssh postgres@$i"
docker-compose exec -T $i ls /var/lib/postgresql/data/recovered.$j

done
done
