#!/bin/bash

# set -eo pipefail

. /usr/local/bin/functions.sh

#---------- Create barman users

pg_hba=${PGDATA}/pg_hba.conf

function add_user {
	local user=${!1}
	local pw=${!2}
	local db=${3}
	local options="${4}"

        echo "====="
	echo "Creating ${user} user in database."
	local cmd="CREATE USER ${user} WITH ${options}"
	local auth
	if [[ -n ${pw} ]]; then
		cmd+=" ENCRYPTED PASSWORD '<password>'"
		auth="md5"
		echo "Be sure to add the following to the .pgpass file on the barman server:"
		echo "$(hostname):${PGPORT:-5432}:${PGDATABASE}:${user}:<password>"
	else
		auth="trust"
		echo "${user} is being created without any password!!!"
	fi

	echo "Running ${cmd}"
	psql -U postgres -c "${cmd/<password>/${pw//\'/\'\'}}"

	echo "Adding ${user} to pg_hba.conf"
        # When pg_hba file is mounted from Docker, sed -i will not work since it changes the node id.
        # sed -i '/^host ${db} ${user}/d' $pg_hba
	grep -F "host ${db} ${user} 0.0.0.0/0 ${auth}" $pg_hba || echo "host ${db} ${user} 0.0.0.0/0 ${auth}" >> $pg_hba
	grep -F "host ${db} ${user} ::/0 ${auth}" $pg_hba || echo "host ${db} ${user} ::/0 ${auth}" >> $pg_hba
}

function update_user {
	local user=${!1}
	local pw=${!2}
	local db=${3}
	local options="${4}"

        echo "====="
	echo "Update ${user} user in database."
	local cmd="ALTER USER ${user} WITH ${options}"
	local auth
	if [[ -n ${pw} ]]; then
		cmd+=" ENCRYPTED PASSWORD '<password>'"
		auth="md5"
		echo "Be sure to add the following to the .pgpass file on the barman server:"
		echo "$(hostname):${PGPORT:-5432}:${PGDATABASE}:${user}:<password>"
	else
		auth="trust"
		echo "${user} is being created without any password!!!"
	fi

	echo "Running ${cmd}"
	psql -U postgres -c "${cmd/<password>/${pw//\'/\'\'}}"
}

add_user BARMAN_USER BARMAN_PASSWORD all SUPERUSER
add_user STREAMING_USER STREAMING_PASSWORD replication REPLICATION

update_user BARMAN_USER BARMAN_PASSWORD all SUPERUSER
update_user STREAMING_USER STREAMING_PASSWORD replication REPLICATION

#---------- Create replication slot

echo "Creating replication slot 'barman'"
psql -U postgres -v ON_ERROR_STOP=1 -c "SELECT * FROM pg_create_physical_replication_slot('barman');" || echo Ignore error.

# if not verlt ${PG_MAJOR} 9.4; then
#   if [[ -n ${BARMAN_SLOT_NAME} ]]; then
#     echo "Creating replication slot ${BARMAN_SLOT_NAME} for barman."
#     psql -v ON_ERROR_STOP=1 -c "SELECT * FROM pg_create_physical_replication_slot('${BARMAN_SLOT_NAME//\'/\'\'}');"
#   else
#     echo "BARMAN_SLOT_NAME is empty; not creating replication slot."
#   fi
# fi

#---------- Copy postgresql conf

# Override existing config.
cp /etc/postgres/postgresql.tmpl.conf $PGDATA/postgresql.conf

