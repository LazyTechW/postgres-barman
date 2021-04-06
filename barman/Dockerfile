ARG PGVERSION=12.2-alpine

FROM postgres:${PGVERSION}

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
  && apk add -U barman \
    openssh-server \
    openssh \
    gettext \
    gosu \
    supervisor \
  && pip3 install barman-exporter

# For wait-for
#     netcat-openbsd \

RUN adduser -D -s /bin/bash barman && \
  install -d -m 0700 -o barman -g barman ~barman/.ssh && \
  echo 'barman:barman' | chpasswd && \
  gosu barman bash -c 'echo -e "Host *\n\tCheckHostIP no\n\tStrictHostKeyChecking no" > ~/.ssh/config'

# Set up some defaults for file/directory locations used in entrypoint.sh.
ENV \
#	BARMAN_VERSION=2.10 \
#	BARMAN_CRON_SRC=/private/cron.d \
  SSH_HOST_KEY=/private/ssh_host_rsa_key \
  AUTHORIZED_KEYS=/private/authorized_keys \
  BARMAN_DATA_DIR=/var/lib/barman \
  BARMAN_LOG_DIR=/var/log/barman \
#	BARMAN_SSH_KEY_DIR=/private/ssh \
#	BARMAN_PGPASSFILE=/private/pgpass \
  # PG_SERVERS must be seperated by space
  PG_SERVERS="" \
  BARMAN_PARALLEL_JOBS=1 \
  BARMAN_COMPRESSION=gzip \
  BARMAN_CRON_SCHEDULE="* * * * *" \
# Note: you must apply tzinfo here. For example, the following setting will run backup at 12pm at UTF+8.
  BARMAN_BACKUP_SCHEDULE="0 4 * * *" \
  BARMAN_STREAM_ON=1 \
  BARMAN_SSH_ON=0 \
  BARMAN_LOG_LEVEL=INFO \
  BARMAN_USER=barman \
  BARMAN_PASSWORD=postgres \
  BARMAN_DATABASE=postgres \
  STREAMING_USER=streaming_barman \
  STREAMING_PASSWORD=standby \
#  BARMAN_SLOT_NAME=barman \
#  BARMAN_BACKUP_METHOD=postgres \
  BARMAN_RETENTION_POLICY="REDUNDANCY 1" \
  BARMAN_EXPORTER_SCHEDULE="*/5 * * * *" \
  BARMAN_EXPORTER_LISTEN_ADDRESS="0.0.0.0" \
#  BARMAN_EXPORTER_LISTEN_PORT=9780 \
  BARMAN_EXPORTER_CACHE_TIME=3600
VOLUME ${BARMAN_DATA_DIR}
VOLUME ${BARMAN_LOG_DIR}

# ENTRYPOINT [ "sh -c '/wait-for pg:5432 -- /entrypoint.sh'" ]
ENTRYPOINT [ "/entrypoint.sh" ]

COPY afterDbUp.sh functions.sh /usr/local/bin/
COPY entrypoint.sh\
 barman.tmpl.conf\
 supervisord.tmpl.conf\
 server.tmpl.conf\
 server-ssh.tmpl.conf\
 wait-for /

# ADD https://raw.githubusercontent.com/eficode/wait-for/master/wait-for /wait-for
# COPY wait-for /wait-for
RUN chmod a+x /wait-for /usr/local/bin/*.sh /*.sh
RUN dos2unix /wait-for /usr/local/bin/*.sh /*.sh

#----- Manually install the latest barman_exporter
ADD https://raw.githubusercontent.com/ahes/prometheus-barman-exporter/master/barman_exporter/barman_exporter.py /

EXPOSE 9780

# Reference
# https://github.com/ubc/barman-docker/blob/master/Dockerfile

