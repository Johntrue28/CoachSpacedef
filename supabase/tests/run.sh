#!/usr/bin/env bash
# Applies the shim and every migration to an empty database and runs the access tests.
# Usage: supabase/tests/run.sh   (uses PG* environment variables; needs permission to create a database)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
db="coachspace_test_$$"
psql -v ON_ERROR_STOP=1 -q -d postgres -c "create database $db"
trap 'psql -q -d postgres -c "drop database if exists $db" >/dev/null' EXIT
psql -v ON_ERROR_STOP=1 -q -d "$db" -f "$here/shim.sql"
for migration in "$here"/../migrations/*.sql; do
  psql -v ON_ERROR_STOP=1 -q -d "$db" -f "$migration"
done
for test in "$here"/*_test.sql; do
  echo "== $(basename "$test")"
  psql -v ON_ERROR_STOP=1 -q -d "$db" -f "$test"
done
echo "All database tests passed."
