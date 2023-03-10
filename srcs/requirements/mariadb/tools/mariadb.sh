#!/bin/bash
set -x
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# logging functions
mariadb_log() {
	local type="$1"; shift
	printf '%s [%s] [Entrypoint]: %s\n' "$(date --rfc-3339=seconds)" "$type" "$*"
}
mariadb_note() {
	mariadb_log Note "$@"
}
mariadb_warn() {
	mariadb_log Warn "$@" >&2
}
mariadb_error() {
  mariadb_log ERROR "$@" >&2
  exit 1
}

docker_process_init_files() {
    mysql=(docker_process_sql)

    for sql_file in "$1"/*.sql; do
      docker_process_sql < "$sql_file"
    done
}


docker_temp_server_start() {
  "$@" &
  ps
  declare -g MARIADB_PID
	MARIADB_PID=$!
	mariadb_note "Waiting for server startup"
  local i
  whoami
  for i in {30..0}; do
    if docker_process_sql --database=mysql <<<'SELECT 1' &> /dev/null; then
      break
    fi
    sleep 1
  done
  if [ "$i" = 0 ]; then
    mariadb_error "Unable to start server."
  fi
}

docker_temp_server_stop() {
	kill "$MARIADB_PID"
	wait "$MARIADB_PID"
}

docker_setup_env() {
  # Get config
  declare -g SOCKET DATADIR
  DATADIR="/var/lib/mysql/$MARIADB_DATABASE"
  SOCKET="/var/run/mysqld/mysqld.sock"

  # Check database exist
  declare -g DATABASE_ALREADY_EXISTS
  if [ -d "$DATADIR" ]; then
    DATABASE_ALREADY_EXISTS='true'
  fi
}

docker_exec_client() {
	mysql --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" "$@"
}

docker_process_sql() {
  MYSQL_PWD=$MARIADB_ROOT_PASSWORD docker_exec_client "$@"
}

# Set the positional parameters for the script to "mysql" followed by any additional arguments
_main() {
  docker_setup_env
  if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
    # check dir permissions to reduce likelihood of half-initialized database
    ls /tmp/mariadb/conf/ > /dev/null

    mariadb_note "Starting temporary server"
    docker_temp_server_start "$@"
    mariadb_note "Temporary server started."

    docker_process_init_files /tmp/mariadb/conf

    mariadb_note "Stopping temporary server"
    docker_temp_server_stop
    mariadb_note "Temporary server stopped"

    echo
    mariadb_note "MariaDB init process done. Ready for start up."
    echo
  else
    mariadb_warn "${MARIADB_DATABASE} already exists"
  fi
  exec "$@"
}

_main "$@"
