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
    BARMAN_SSH_SERVERNAME=ssh \
    BARMAN_USER=barman \
    BARMAN_PASSWORD= \
#    BARMAN_SLOT_NAME=barman \
    STREAMING_USER=streaming_barman \
    STREAMING_PASSWORD=
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ ]
VOLUME /var/log/supervisor
COPY functions.sh /usr/local/bin/
COPY supervisord.conf /etc/
COPY supervisord-pg.conf /etc/
RUN mkdir -p /etc/postgres/
COPY postgresql.conf /etc/postgres/
COPY pg_hba.conf /etc/postgres/
COPY entrypoint.sh /
COPY docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
# COPY image-entrypoint-initdb.d /image-entrypoint-initdb.d/
# COPY image-pre-start.d /image-pre-start.d

# Reference:
# https://github.com/tbeadle/postgres/blob/master/barman/Dockerfile-9.6
# https://github.com/docker-library/postgres/blob/master/docker-entrypoint.sh
