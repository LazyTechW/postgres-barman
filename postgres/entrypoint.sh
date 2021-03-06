#!/bin/bash

set -eo pipefail

chown postgres:postgres $PGDATA

source /usr/local/bin/functions.sh

#----- Generate pg conf

cat > /var/lib/postgresql/.ssh/config <<-EOF
Host *
  CheckHostIP no
  StrictHostKeyChecking no
Host barman
  HostName ${BARMAN_SSH_HOST}
  Port ${BARMAN_SSH_PORT}
  User barman
EOF
chmod 600 /var/lib/postgresql/.ssh/config
chown postgres:postgres /var/lib/postgresql/.ssh/config

# archive_command can only be run on SSH not STREAMING.
if [[ "${BARMAN_SSH_ON}" == "1" ]]; then
cat > /etc/postgres/archive.conf <<-EOF
archive_mode = on
archive_command = 'barman-wal-archive barman ${BARMAN_SSH_SERVERNAME} %p'
restore_command = 'barman-wal-restore -P barman ${BARMAN_SSH_SERVERNAME} %f %p'
EOF
else
cat > /etc/postgres/archive.conf <<-EOF
archive_mode = off
EOF
fi

configure_ssh postgres

#----- Check restore mode

if [[ "${RESTORE_MODE}" != "" ]]; then
  sed -i '/\[include\]/d' /etc/supervisord.conf
  sed -i '/files=/d' /etc/supervisord.conf
fi

mkdir -p /var/log/supervisor/{postgres,sshd}
export CMD_ARG="$@"
exec supervisord -c /etc/supervisord.conf


