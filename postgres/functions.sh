#!/bin/bash

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# Compare 2 version numbers
verlte() {
	[  "$1" == "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
	[ "$1" == "$2" ] && return 1 || verlte $1 $2
}

major_gte() { verlt $1 ${PG_MAJOR}; }
major_lt() { verlt ${PG_MAJOR} $1; }

function configure_ssh {
  local user=$1
  local user_home=$(eval echo ~$user)
	if [[ ! -d $user_home/.ssh ]]; then
		install -d -m 0700 -o $user -g $user $user_home/.ssh
	fi

  # todo: what is this dir for?
	install -d -m 0755 -o root -g root /var/run/sshd

	if [[ -n ${AUTHORIZED_KEYS} ]] && [[ -f ${AUTHORIZED_KEYS} ]]; then
		echo "Installing SSH public key for ${user} user in $user user's authorized_keys file."
		install -m 0400 -o $user -g $user ${AUTHORIZED_KEYS} $user_home/.ssh/authorized_keys
	else
		echo "WARNING: SSH public key for ${user} user does not exist.  Taking basebackups over rsync using barman will not work!  AUTHORIZED_KEYS must be set to the location of a valid SSH public key."
	fi

	if [[ -n ${SSH_HOST_KEY} ]] && [[ -f ${SSH_HOST_KEY} ]]; then
		echo "Installing SSH host key"
		rm -f /etc/ssh/ssh_host_*_key*
		install -m 0400 -o root -g root ${SSH_HOST_KEY} /etc/ssh/

		sed -i '/^HostKey[[:space:]]/ d' /etc/ssh/sshd_config
		echo "HostKey /etc/ssh/$(basename ${SSH_HOST_KEY})" >> /etc/ssh/sshd_config
		sed -i '/^PasswordAuthentication[[:space:]]/ d' /etc/ssh/sshd_config
		echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
		sed -i '/^ChallengeResponseAuthentication[[:space:]]/ d' /etc/ssh/sshd_config
		echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
		sed -i '/^PermitRootLogin[[:space:]]/ d' /etc/ssh/sshd_config
		echo "PermitRootLogin no" >> /etc/ssh/sshd_config

    chmod 700 $user_home/.ssh
    # -R
    chown $user:$user $user_home/.ssh
		install -m 0600 -o $user -g $user ${SSH_HOST_KEY} $user_home/.ssh/id_rsa
		install -m 0600 -o $user -g $user ${SSH_HOST_KEY}.pub $user_home/.ssh/id_rsa.pub
	else
		echo "WARNING: Unable to install SSH host key.  SSH_HOST_KEY is not defined or file does not exist."
	fi

}
