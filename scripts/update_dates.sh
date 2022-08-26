#!/bin/bash

SCRIPT_DIR=`dirname "$0"`

# check number of arguments
if [[ $# -ne 4 ]];
then
    echo "$0: wrong number of arguments ($#)"
    echo "usage: $0 <collection name> <adc_created_date field name> <adc_updated_date field name>"
    exit 1
fi

COLLECTION_NAME="$1"
CREATED_AT_NAME="$2"
UPDATED_AT_NAME="$3"
DATE_FORMAT="$4"

# create log file
LOG_FOLDER=${SCRIPT_DIR}/../log
mkdir -p $LOG_FOLDER
TIME1=`date +%Y-%m-%d_%H-%M-%S`
LOG_FILE=${LOG_FOLDER}/${TIME1}_${FILE_NAME}.log

# make available to docker-compose.yml
export FILE_FOLDER

# Notes:
# sudo -E: make environment variables available to the command run as root
# docker-compose --rm: delete container afterwards 
# docker-compose -e: these variables will be available inside the container
# (but not accessible in docker-compose.yml)
# "ireceptor-dataloading" is the service name defined in docker-compose.yml 
# sh -c '...' is the command executed inside the container
# $DB_HOST and $DB_DATABASE are defined in docker-compose.yml and will be
# substituted only when the python command is executed, INSIDE the container
sudo -E docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service run --rm \
                               -e COLLECTION_NAME="$COLLECTION_NAME" \
                               -e UPDATED_AT_NAME="$UPDATED_AT_NAME" \
                               -e CREATED_AT_NAME="$CREATED_AT_NAME" \
                               -e DATE_MASK="$DATE_MASK" \
			ireceptor-dataloading  \
				sh -c 'python /app/dataload/update_dates.py \
					$DB_HOST \
					$DB_DATABASE \
					$COLLECTION_NAME
					$CREATED_AT_NAME \
					$UPDATED_AT_NAME \
					"$DATE_MASK"'\
 	2>&1 | tee $LOG_FILE


