#!/usr/bin/env bash

# --- Configuration ---
# Set your PostgreSQL connection variables here or export them before running.
PGUSER="${PGUSER:-postgres}"
# PGPASSWORD="your_password" # Better to use ~/.pgpass or export PGPASSWORD in your environment

echo "Starting PostgreSQL Collation Refresh and Index Check..."
echo "Connecting to $PGHOST:$PGPORT as $PGUSER..."
echo "----------------------------------------------------"

# Fetch a list of all non-template databases
DATABASES=$(psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d postgres -tAc "SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true;")

if [ -z "$DATABASES" ]; then
    echo "❌ No databases found or connection failed."
    exit 1
fi

for DB in $DATABASES; do
    echo "Processing Database: [$DB]"

    # 1. Refresh Collation Version
    echo "  -> Refreshing collation version..."
    psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d postgres -c "ALTER DATABASE \"$DB\" REFRESH COLLATION VERSION;" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "  ✅ Collation refreshed."
    else
        echo "  ⚠️  Failed to refresh collation (Check if PG version is 15+ or if there are permission issues)."
    fi

    # 2. Check Index Corruption
    echo "  -> Checking B-Tree index integrity..."

    # Ensure the amcheck extension exists in the target database
    psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d "$DB" -c "CREATE EXTENSION IF NOT EXISTS amcheck;" >/dev/null 2>&1

    # SQL query to run bt_index_check() on all valid B-Tree indexes
    # bt_index_check throws a hard ERROR if it detects corruption, which ON_ERROR_STOP=1 will catch.
    CHECK_QUERY="
    SELECT bt_index_check(i.indexrelid)
    FROM pg_index i
    JOIN pg_class c ON i.indexrelid = c.oid
    JOIN pg_am am ON c.relam = am.oid
    WHERE am.amname = 'btree' 
      AND c.relkind = 'i' 
      AND i.indisready 
      AND i.indisvalid;
    "

    # Execute the check
    psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d "$DB" -v ON_ERROR_STOP=1 -c "$CHECK_QUERY" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "  ✅ All B-Tree indexes are healthy."
    else
        echo "  ❌ WARNING: Index corruption detected or check failed in [$DB]!"
        echo "     Run 'REINDEX DATABASE \"$DB\";' to fix potential corruption."
    fi
    echo "----------------------------------------------------"
done

echo "Script complete."
