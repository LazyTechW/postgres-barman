@echo off
setlocal

cd postgres
docker build . -t postgres-barman

cd ..\barman
docker build . -t barman-docker

cd ..
