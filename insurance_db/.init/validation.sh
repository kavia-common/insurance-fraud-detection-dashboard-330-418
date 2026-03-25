#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/insurance-fraud-detection-dashboard-330-418/insurance_db"
: "${PGHOST:?PGHOST must be set (e.g. localhost)}"
: "${PGUSER:?PGUSER must be set}"
: "${PGDATABASE:?PGDATABASE must be set}"
PGPORT="${PGPORT:-5432}"
# evidence: versions
psql --version || true; pg_dump --version || true; python3 --version || true; pip3 --version || true
if command -v supabase >/dev/null 2>&1; then supabase --version || true; fi
# start DB safely
bash "$WS/.init/start" || (echo "start failed" >&2; exit 1)
# run migrations
bash "$WS/.init/migrate" || (echo "migrate failed" >&2; true)
# run healthcheck
if bash "$WS/.init/healthcheck" | grep -q OK; then echo "healthcheck: OK"; else echo "healthcheck: FAILED" >&2; fi
# run tests
if bash "$WS/.init/test"; then echo "tests: OK"; else echo "tests: failures or skipped"; fi
# evidence: list tables
if [ -n "${PGPASSWORD:-}" ]; then PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c "\dt" || true; else psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c "\dt" || true; fi
# stop DB if necessary
bash "$WS/.init/stop" || true
echo "validation: completed"
