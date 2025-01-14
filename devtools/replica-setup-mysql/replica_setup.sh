#!/bin/bash

usage() {
    echo "Usage: $0 --mysql_host <host> --mysql_port <port> --mysql_user <user> --mysql_password <password> [--myduck_host <host>] [--myduck_port <port>] [--myduck_user <user>] [--myduck_password <password>] [--myduck_in_docker <true|false>]"
    exit 1
}

MYDUCK_HOST=${MYDUCK_HOST:-127.0.0.1}
MYDUCK_PORT=${MYDUCK_PORT:-3306}
MYDUCK_USER=${MYDUCK_USER:-root}
MYDUCK_PASSWORD=${MYDUCK_PASSWORD:-}
MYDUCK_SERVER_ID=${MYDUCK_SERVER_ID:-2}
MYDUCK_IN_DOCKER=${MYDUCK_IN_DOCKER:-false}
GTID_MODE="ON"

while [[ $# -gt 0 ]]; do
    case $1 in
        --mysql_host)
            MYSQL_HOST="$2"
            shift 2
            ;;
        --mysql_port)
            MYSQL_PORT="$2"
            shift 2
            ;;
        --mysql_user)
            MYSQL_USER="$2"
            shift 2
            ;;
        --mysql_password)
            MYSQL_PASSWORD="$2"
            shift 2
            ;;
        --myduck_host)
            MYDUCK_HOST="$2"
            shift 2
            ;;
        --myduck_port)
            MYDUCK_PORT="$2"
            shift 2
            ;;
        --myduck_user)
            MYDUCK_USER="$2"
            shift 2
            ;;
        --myduck_password)
            MYDUCK_PASSWORD="$2"
            shift 2
            ;;
        --myduck_server_id)
            MYDUCK_SERVER_ID="$2"
            shift 2
            ;;
        --myduck_in_docker)
            MYDUCK_IN_DOCKER="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            usage
            ;;
    esac
done

source checker.sh

# Check if all parameters are set
if [[ -z "$MYSQL_HOST" || -z "$MYSQL_PORT" || -z "$MYSQL_USER" ]]; then
    echo "Error: Missing required MySQL connection variables: MYSQL_HOST, MYSQL_PORT, MYSQL_USER."
    usage
fi

# Step 1: Check if mysqlsh exists, if not, install it
if ! command -v mysqlsh &> /dev/null; then
    echo "mysqlsh not found, attempting to install..."
    bash install_mysql_shell.sh
    check_command "mysqlsh installation"
else
    echo "mysqlsh is already installed."
fi

# Step 2: Check if replication has already been started
echo "Checking if replication has already been started..."
check_if_myduck_has_replica
if [[ $? -ne 0 ]]; then
    echo "Replication has already been started. Exiting."
    exit 1
fi

# Step 3: Check MySQL configuration
echo "Checking MySQL configuration..."
check_mysql_config
check_command "MySQL configuration check"

# Step 3: Prepare MyDuck Server for replication
echo "Preparing MyDuck Server for replication..."
source prepare.sh
check_command "preparing MyDuck Server for replication"

# Step 4: Check if the MySQL server is empty
echo "Checking if source MySQL server is empty..."
check_if_source_mysql_is_empty
SOURCE_IS_EMPTY=$?

# Step 5: Copy the existing data if the MySQL instance is not empty
if [[ $SOURCE_IS_EMPTY -ne 0 ]]; then
    echo "Copying a snapshot of the MySQL instance to MyDuck Server..."
    source snapshot.sh
    check_command "copying a snapshot of the MySQL instance"
else
    echo "This MySQL instance is empty. Skipping snapshot."
fi

# Step 6: Establish replication
echo "Starting replication..."
source start_replication.sh
check_command "starting replication"
