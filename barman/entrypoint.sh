#!/bin/bash

set -eo pipefail

source /usr/local/bin/functions.sh
configure_ssh ${BARMAN_USER}

echo "Setting ownership/permissions on ${BARMAN_DATA_DIR} and ${BARMAN_LOG_DIR}"

install -d -m 0700 -o ${BARMAN_USER} -g ${BARMAN_USER} ${BARMAN_DATA_DIR}
install -d -m 0755 -o ${BARMAN_USER} -g ${BARMAN_USER} ${BARMAN_LOG_DIR}

#---------- barman conf

mkdir -p /etc/barman.d
for r in $PG_SERVERS
do
  export dbHostName=$(echo $r | cut -d ',' -f1)
  export dbHost=$(echo $r | cut -d ',' -f2)
  export sshPort=$(echo $r | cut -d ',' -f3)
  envsubst < /server.tmpl.conf > /etc/barman.d/${dbHostName}.conf
done

#----- cron

sed -i '/gosu barman/d' /etc/crontabs/root
# echo "Generating cron schedules"
# gosu barman barman receive-wal --create-slot ${DB_HOST}; 
echo "${BARMAN_CRON_SCHEDULE} gosu barman barman cron" >> /etc/crontabs/root
echo "${BARMAN_BACKUP_SCHEDULE} gosu barman barman backup all" >> /etc/crontabs/root

#----- pgpass

envsubst </pgpass >/home/${BARMAN_USER}/.pgpass
chown ${BARMAN_USER}:${BARMAN_USER} /home/${BARMAN_USER}/.pgpass
chmod 600 /home/${BARMAN_USER}/.pgpass

#----- Supervisord

envsubst </supervisord.tmpl.conf >/etc/supervisord.conf

echo "Initializing done"

mkdir -p /var/log/supervisor/{sshd,barman-exporter,crond}

echo "Started Barman exporter on ${BARMAN_EXPORTER_LISTEN_ADDRESS}:${BARMAN_EXPORTER_LISTEN_PORT}"
exec supervisord -c /etc/supervisord.conf

# exec "$@"
