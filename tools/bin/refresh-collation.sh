#!/usr/bin/env bash

# Exit on any unexpected errors
set -e

echo "Starting Postgres Maintenance: Freeze -> Collation Refresh -> Integrity Check"
echo "---------------------------------------------------------------------------"

# Get all connectable databases
DATABASES=$(psql -tAc "SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true;")

for DB in $DATABASES; do
    echo "Processing Database: [$DB]"

    # 1. PREPARE: Vacuum Freeze and Analyze
    # This prepares the data for long-term storage/stability
    echo "  -> Freezing and Analyzing..."
    psql -d "$DB" -c "VACUUM FREEZE ANALYZE;" >/dev/null

    # 2. REFRESH: Update Collation Version
    # This tells Postgres the OS-level C-library (glibc) version is now acknowledged
    echo "  -> Refreshing collation version..."
    psql -d "$DB" -c "ALTER DATABASE \"$DB\" REFRESH COLLATION VERSION;" >/dev/null 2>&1

    # 3. CHECK: Verify Index Integrity
    # We use amcheck to see if the collation change actually broke any B-Trees
    echo "  -> Verifying B-Tree indexes..."
    psql -d "$DB" -c "CREATE EXTENSION IF NOT EXISTS amcheck;" >/dev/null

    # We use a subshell to catch the error without exiting the whole script
    CHECK_RESULT=$(psql -d "$DB" -v ON_ERROR_STOP=1 -c "
        SELECT bt_index_check(c.oid)
        FROM pg_class c
        JOIN pg_am am ON c.relam = am.oid
        WHERE c.relkind = 'i' AND am.amname = 'btree' AND c.relispartition = false;
    " 2>&1)

    # shellcheck disable=SC2181
    if [[ $? -eq 0 ]]; then
        echo "  ✅ Database [$DB] is healthy."
    else
        echo "  ❌ CORRUPTION DETECTED in [$DB]!"
        echo "     Details: $CHECK_RESULT"
        echo "     Action: Consider running 'REINDEX DATABASE \"$DB\"' immediately."
    fi
    echo "---------------------------------------------------------------------------"
done

echo "Maintenance Task Complete."
