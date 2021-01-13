#!/bin/bash

set -eo pipefail

chown postgres:postgres $PGDATA

source /usr/local/bin/functions.sh

configure_ssh postgres
mkdir -p /var/log/supervisor/{postgres,sshd}
export CMD_ARG="$@"
exec supervisord -c /etc/supervisord.conf


