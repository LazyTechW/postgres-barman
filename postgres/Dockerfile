ARG PGVERSION=12.2-alpine

FROM postgres:${PGVERSION}

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
  && apk add -U openssh-server \
    openssh \
    barman \
    rsync \
    gosu \
    gettext \
    supervisor
#	&& rm -Rf /var/lib/apt/lists/* \
#	&& sed -i 's/\(.*pam_loginuid.so\)/#\1/' /etc/pam.d/sshd

RUN install -d -m 0700 -o postgres -g postgres ~postgres/.ssh && \
  echo 'postgres:postgres' | chpasswd && \
  gosu postgres bash -c 'echo -e "Host *\n\tCheckHostIP no\n\tStrictHostKeyChecking no" > ~/.ssh/config'

ENV \
    SSH_HOST_KEY=/private/ssh_host_rsa_key \
    AUTHORIZED_KEYS=/private/authorized_keys \
# Whether to enable streaming or ssh backup
    BARMAN_STREAM_ON=1 \
    BARMAN_SSH_ON=0 \
# This is important, used in archive_command and restore_command.
    BARMAN_SSH_HOST=barman \
    BARMAN_SSH_PORT=22 \
    BARMAN_SSH_SERVERNAME=ssh \
    BARMAN_STREAM_SERVERNAME=stream \
    BARMAN_USER=barman \
    BARMAN_PASSWORD= \
#    BARMAN_SLOT_NAME=barman \
    STREAMING_USER=streaming_barman \
    STREAMING_PASSWORD=
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ ]
VOLUME /var/log/supervisor
COPY functions.sh /usr/local/bin/
COPY supervisord.conf supervisord-pg.conf /etc/

# /etc/postgres
RUN mkdir -p /etc/postgres/
COPY postgresql.tmpl.conf /etc/postgres/
# COPY pg_hba.conf /etc/postgres/

COPY entrypoint.sh /
COPY docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
# COPY image-entrypoint-initdb.d /image-entrypoint-initdb.d/
# COPY image-pre-start.d /image-pre-start.d
RUN chmod a+x /usr/local/bin/*.sh /*.sh
RUN dos2unix /usr/local/bin/*.sh /*.sh /docker-entrypoint-initdb.d/*.sh

# Reference:
# https://github.com/tbeadle/postgres/blob/master/barman/Dockerfile-9.6
# https://github.com/docker-library/postgres/blob/master/docker-entrypoint.sh
