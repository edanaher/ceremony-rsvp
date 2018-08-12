#!/bin/sh

## This should be run as angell to run the db setup

PSQL="@POSTGRESQL/bin/psql rsvpsite"

if ! echo @PASSWORD | $PSQL -c '\dt' | grep -q db_setup; then
  echo @PASSWORD | $PSQL -c "CREATE TABLE db_setup(name varchar PRIMARY KEY, created timestamp NOT NULL)";
fi

cd $(dirname "${BASH_SOURCE[0]}")
already_run=$(echo @PASSWORD | $PSQL -c "SELECT name FROM db_setup")
echo "already run is $already_run"
for sql in *.sql; do
  if echo $already_run | grep -q $sql; then
    continue;
  fi
  echo @PASSWORD | $PSQL --single-transaction \
                         -f $sql \
                         -c "INSERT INTO db_setup (name, created) VALUES ('${sql##*/}', 'now')"
done
