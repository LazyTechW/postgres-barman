@echo off
setlocal

for %%i in (pg pgb) do (
  docker-compose exec -T %%i bash /docker-entrypoint-initdb.d/01_create_barman_db_users.sh
  docker-compose exec -T %%i bash /docker-entrypoint-initdb.d/02_create_replication_slot.sh
  docker-compose exec -T %%i bash /docker-entrypoint-initdb.d/03_cp_postgresql_conf.sh
)

