# kompis-os/tools/session/pgsql-restore.sh
set -euo pipefail
appname="$1"
stateDir="$2"

psql -U "$appname" "$appname" <"$stateDir/dbdump.sql"
