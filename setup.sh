#!/bin/sh

## This should be run (at least once) as root before the script

@SUDO/bin/sudo -u postgres @POSTGRESQL/bin/createuser rsvpsite || true
@SUDO/bin/sudo -u postgres @POSTGRESQL/bin/createdb rsvpsite -O rsvpsite || true
@SUDO/bin/sudo -u postgres @POSTGRESQL/bin/psql rsvpsite -c "ALTER USER rsvpsite WITH PASSWORD '@PASSWORD'"
@SUDO/bin/sudo -u rsvpsite @OUT/db/run.sh
