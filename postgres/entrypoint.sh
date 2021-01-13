#!/bin/bash

set -eo pipefail

chown postgres:postgres $PGDATA

source /usr/local/bin/functions.sh

#----- Generate pg conf
cat > /etc/postgres/archive.conf <<-EOF
archive_mode = on
archive_command = 'barman-wal-archive barman ${BARMAN_SSH_SERVERNAME} %p'
restore_command = 'barman-wal-restore barman ${BARMAN_SSH_SERVERNAME} %f %p'
EOF

configure_ssh postgres

#----- Check restore mode

if [[ "${RESTORE_MODE}" != "" ]]; then
  sed -i '/\[include\]/d' /etc/supervisord.conf
  sed -i '/files=/d' /etc/supervisord.conf
fi

mkdir -p /var/log/supervisor/{postgres,sshd}
export CMD_ARG="$@"
exec supervisord -c /etc/supervisord.conf


