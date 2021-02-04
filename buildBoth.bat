@echo off
setlocal

cd postgres
docker build . -t lazytechw/postgres-barman:v12.2

cd ..\barman
docker build . -t lazytechw/barman-docker:v12.2

cd ..
