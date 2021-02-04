#!/bin/bash

set -v

docker-compose ps
sleep 20
docker-compose exec -T pg psql -c "SELECT version()" -U barman postgres
docker-compose exec -T pgb psql -c "SELECT version()" -U barman postgres

sleep 10
docker-compose exec -T barman gosu barman barman switch-xlog all
sleep 5
docker-compose exec -T barman gosu barman barman check all | grep -vF FAILED

docker-compose exec -T barman gosu barman barman backup all
docker-compose exec -T barman gosu barman barman list-backup all
docker-compose exec -T barman gosu barman tail -n 100 /var/log/barman/barman.log

docker-compose exec -T barman ls /etc/barman.d/
docker-compose exec -T barman cat /etc/barman.d/pg.conf
docker-compose exec -T barman cat /etc/barman.d/pgb.conf

docker-compose exec -T barman gosu barman barman recover pg-ssh first /var/lib/postgresql/data/recovered.ssh --remote-ssh-command "ssh postgres@pg"
docker-compose exec -T pg ls /var/lib/postgresql/data/recovered.ssh

docker-compose exec -T barman gosu barman barman recover pg-streaming first /var/lib/postgresql/data/recovered.streaming --remote-ssh-command "ssh postgres@pg"
docker-compose exec -T pg ls /var/lib/postgresql/data/recovered.streaming

docker-compose exec -T barman gosu barman barman recover pgb-ssh first /var/lib/postgresql/data/recovered.ssh --remote-ssh-command "ssh postgres@pgb"
docker-compose exec -T pgb ls /var/lib/postgresql/data/recovered.ssh

docker-compose exec -T barman gosu barman barman recover pgb-streaming first /var/lib/postgresql/data/recovered.streaming --remote-ssh-command "ssh postgres@pgb"
docker-compose exec -T pgb ls /var/lib/postgresql/data/recovered.streaming


