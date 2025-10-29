set -euo pipefail
appname="$1"

if psql -lqt | cut -d \| -f 1 | grep -qw "$appname"; then
	echo "Error: Database '$appname' already exists" >&2
	exit 1
fi

psql -tc "SELECT 1 FROM pg_user WHERE usename = '$appname'" | grep -q 1 ||
	psql -c "CREATE USER \"$appname\";"

psql -c "CREATE DATABASE \"$appname\" OWNER \"$appname\";"
