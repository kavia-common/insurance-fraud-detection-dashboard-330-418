#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/insurance-fraud-detection-dashboard-330-418/insurance_db"
mkdir -p "$WS/migrations" "$WS/scripts"
cat > "$WS/migrations/0001_init.sql" <<'SQL'
CREATE TABLE IF NOT EXISTS test_table (id serial PRIMARY KEY, created_at timestamptz DEFAULT now());
SQL
cat > "$WS/scripts/migrate.sh" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
WS="${WS}"
: "${PGHOST:?PGHOST must be set (e.g. localhost)}"
: "${PGUSER:?PGUSER must be set}"
: "${PGDATABASE:?PGDATABASE must be set}"
PGPORT="${PGPORT:-5432}"
if command -v supabase >/dev/null 2>&1 && [ -d "$WS/supabase" ] && [ -f "$WS/supabase/config.toml" ]; then
  cd "$WS" && supabase db push --skip-generate || { echo "supabase db push failed" >&2; exit 4; }
  exit 0
fi
if ! command -v psql >/dev/null 2>&1; then echo "error: psql not found" >&2; exit 5; fi
if [ -n "${PGPASSWORD:-}" ]; then PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f "$WS/migrations/0001_init.sql"; else psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f "$WS/migrations/0001_init.sql"; fi
BASH
chmod +x "$WS/scripts/migrate.sh"
cat > "$WS/scripts/healthcheck.sh" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
: "${PGHOST:?}"
: "${PGUSER:?}"
: "${PGDATABASE:?}"
PGPORT="${PGPORT:-5432}"
if ! command -v psql >/dev/null 2>&1; then echo "error: psql not found" >&2; exit 6; fi
if [ -n "${PGPASSWORD:-}" ]; then PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c '\q' >/dev/null 2>&1 && echo OK || { echo DOWN; exit 7; }; else psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c '\q' >/dev/null 2>&1 && echo OK || { echo DOWN; exit 8; }; fi
BASH
chmod +x "$WS/scripts/healthcheck.sh"
cat > "$WS/scripts/start-db.sh" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
if [ -d /run/systemd/system ] && [ "$(ps -p 1 -o comm=)" = "systemd" ] && command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q postgresql; then
  sudo systemctl start postgresql && echo systemd_started && exit 0
fi
if ! command -v initdb >/dev/null 2>&1 || ! command -v pg_ctl >/dev/null 2>&1; then echo "error: initdb/pg_ctl required for fallback" >&2; exit 9; fi
DATADIR=$(mktemp -d "/tmp/pgdata.XXXX")
trap 'pg_ctl -D "$DATADIR" -w stop >/dev/null 2>&1 || true; rm -rf "$DATADIR"' EXIT
initdb -D "$DATADIR"
echo "local all all trust" > "$DATADIR/pg_hba.conf"
pg_ctl -D "$DATADIR" -o "-c listen_addresses=localhost" -w start
echo "ephemeral:$DATADIR"
BASH
chmod +x "$WS/scripts/start-db.sh"
cat > "$WS/scripts/stop-db.sh" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
if [ -d /run/systemd/system ] && [ "$(ps -p 1 -o comm=)" = "systemd" ] && command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q postgresql; then
  sudo systemctl stop postgresql || true; exit 0
fi
if [ -n "${DATADIR:-}" ] && [ -d "$DATADIR" ]; then pg_ctl -D "$DATADIR" -w stop || true; rm -rf "$DATADIR" || true; fi
BASH
chmod +x "$WS/scripts/stop-db.sh"
