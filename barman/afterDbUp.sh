#!/bin/bash

if [[ "$1" == "" ]]; then
  echo "$0 dbHost"
  exit -1
fi

dbHost=$1

# echo "Checking/Creating replication slot"
# gosu barman barman replication-status $serverName --minimal --target=wal-streamer | grep barman || gosu barman barman receive-wal --create-slot $serverName || echo ignore error
# gosu barman barman replication-status $serverName --minimal --target=wal-streamer | grep barman || gosu barman barman receive-wal --reset $serverName || echo ignore error

# echo "Generating Barman configurations"
# cat /etc/barman.conf.template | envsubst > /etc/barman.conf
# cat /etc/barman/barman.d/pg.conf.template | envsubst > /etc/barman/barman.d/${DB_HOST}.conf

# echo "${dbHost}:${dbPort}:*:${BARMAN_USER}:${barmanPass}" > /home/${BARMAN_USER}/.pgpass
# echo "${dbHost}:${dbPort}:*:${STREAMING_USER}:${streamingPass}" >> /home/${BARMAN_USER}/.pgpass
# chown ${BARMAN_USER}:${BARMAN_USER} /home/${BARMAN_USER}/.pgpass
# chmod 600 /home/${BARMAN_USER}/.pgpass

#----- Check

function checkPsql() {
  echo "Connect pg with user barman"
  psql -c 'SELECT version()' -U barman -h $dbHost postgres
  echo "Connect pg with user streaming_barman"
  psql -U streaming_barman -h $dbHost -c "IDENTIFY_SYSTEM" replication=1
  
  if [[ -f ~/notFirstBoot ]]; then
    echo "Not first boot, ignore switch-xlog"
  else
    barman switch-xlog --force --archive all
    touch ~/notFirstBoot
  fi
}

if [[ "$1" == "noCheck" ]]; then
  echo "Do not check psql connection."
else
  checkPsql || echo "Check psql fail."
fi
