@echo off
setlocal

for %%i in (pg pgb) do (
  docker-compose exec -T %%i bash /docker-entrypoint-initdb.d/01_barman.sh
)

