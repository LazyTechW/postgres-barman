#!/bin/bash

set -v

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

# Check config

docker-compose exec -T barman ls /etc/barman.d/
docker-compose exec -T barman cat /etc/barman.d/pg.conf
docker-compose exec -T barman cat /etc/barman.d/pgb.conf

for i in pg pgb
do

# Backup
docker-compose exec -T barman gosu barman barman backup $i-streaming
docker-compose exec -T barman gosu barman barman list-backup $i-streaming
docker-compose exec -T barman gosu barman tail -n 50 /var/log/barman/barman.log

# Recover

# docker-compose exec -T barman gosu barman barman recover pg-ssh first /var/lib/postgresql/data/recovered.ssh --remote-ssh-command "ssh postgres@pg"
# docker-compose exec -T pg ls /var/lib/postgresql/data/recovered.ssh

docker-compose exec -T barman gosu barman barman recover $i-streaming first /var/lib/postgresql/data/recovered.streaming --remote-ssh-command "ssh postgres@$i"
docker-compose exec -T $i ls /var/lib/postgresql/data/recovered.streaming

# docker-compose exec -T barman gosu barman barman recover pgb-ssh first /var/lib/postgresql/data/recovered.ssh --remote-ssh-command "ssh postgres@pgb"
# docker-compose exec -T pgb ls /var/lib/postgresql/data/recovered.ssh
# 
# docker-compose exec -T barman gosu barman barman recover pgb-streaming first /var/lib/postgresql/data/recovered.streaming --remote-ssh-command "ssh postgres@pgb"
# docker-compose exec -T pgb ls /var/lib/postgresql/data/recovered.streaming

done
