#!/usr/bin/env bash

MASTER_KEY="master key goes here"
APPLICATION_ID="application id goes here"
PARSE_URL="https://parseapi.back4app.com/classes/"

date=`date '+%Y-%m-%d %H:%M:%S'`
any_failure=false

download_table_to_file () {
  result=`curl -X GET -H "X-Parse-Application-Id: ${APPLICATION_ID}" -H "X-Parse-Master-Key: ${MASTER_KEY}" -G --data-urlencode 'limit=100000000000' $PARSE_URL$1`
  echo $result >> "backups/${1}_${date}.json"
}

verify_record_numbers () {
  downloadedRecordCount=`jq '.results | length' "backups/${1}_${date}.json"`

  result=`curl -X GET -H "X-Parse-Application-Id: ${APPLICATION_ID}" -H "X-Parse-Master-Key: ${MASTER_KEY}" -G --data-urlencode "count=1" --data-urlencode 'limit=0' $PARSE_URL$1`
  queryRecordCount=`echo $result | jq '.count'`

  if [ "$downloadedRecordCount" != "$queryRecordCount" ]; then
    echo "Downloaded records: $downloadedRecordCount vs count query: $queryRecordCount" >> "backups/${1}_${date}.error"
    any_failure=true
  fi
}

schema=`curl -X GET -H "X-Parse-Application-Id: ${APPLICATION_ID}" -H "X-Parse-Master-Key: ${MASTER_KEY}" -H "Content-Type: application/json" https://parseapi.back4app.com/schemas/`
tables=`echo $schema | jq -r '.results | .[] | .className'`

for table in ${tables[@]}
do
  download_table_to_file $table
  verify_record_numbers $table
done

if [ "$any_failure" = true ] ; then
    echo "there are errors during backup"
    exit 1
fi
