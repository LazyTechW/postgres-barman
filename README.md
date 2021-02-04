
<img src="https://travis-ci.com/LazyTechW/postgres-barman.svg?branch=v12.2" />

# Intro

This repo includes two Docker builds:

- A postgres container with barman streaming and rsync/ssh support.
- A barman container with sshd.

In the examples, it shows the following features:

- The barman container can backup more than one postgres servers.
- Both streaming and rsync/ssh strateties are supported.

# How to run the example

- Run buildBoth.bat (windows only) to build both images from 'barman' and 'postgres'.
- cd examples, and run `docker-compose up -d`

## Generate ssh keys

Go to pgSshKeys and barmanSshKeys, execute:

``` bash
ssh-keygen -f ./ssh_host_rsa_key -q -N ""
```

Then copy the content of ssh_host_rsa_key.pub to each other's authorized_keys.

## Add credential to pgpass

In the pgpass file, add the corresponding pg credentials.

## Set environment

```yaml
  # Format: dbHostName,dbHost. dbHostName is used to specify the name for barman, dbHost is used to connect to the db.
  PG_SERVERS: "pg,pg pgb,pgb"
  BARMAN_PASSWORD: ${barmanPass}
  STREAMING_PASSWORD: ${barmanStreamPass}
```

## Backup

There is a cron job to back up all with a schedule like "0 4 * * *". You may change it by set the variable in docker-compose:

``` yaml
environment:
  BARMAN_BACKUP_SCHEDULE: "0 4 * * *"
```

For testing, you may trigger manual backup by:

```bash
# Backup all
gosu barman barman backup all
# Or just backup one
gosu barman barman backup SERVER_NAME
```

## Recover

If you want to restore, cp the docker-compose.or.yaml to docker-compose.override.yaml to bring postgres container into recovery mode:

``` bash
cd examples
docker-compose down
mv pgData pgData.bak
cp docker-compose.or.yaml docker-compose.override.yaml
docker-compose up
```

``` bash
docker-compose exec barman bash
# Find the backup id
barman list-backup ssh

# barman recover SERVER_NAME BACKUP_ID /var/lib/postgresql/data --remote-ssh-command 'ssh postgres@pg'
barman recover pg-ssh latest /var/lib/postgresql/data --remote-ssh-command 'ssh postgres@pg'
# Or PITR
gosu barman barman recover ssh latest /var/lib/postgresql/data --target-time "2021-01-07 10:45:00" --remote-ssh-command 'ssh postgres@pg'
exit

docker-compose up -d
```

# Issues and PR's are hotly welcomed!

# Previous artworks

https://github.com/tbeadle/postgres/blob/master/barman/image-pre-start.d/01_update_postgresql.conf.sh



