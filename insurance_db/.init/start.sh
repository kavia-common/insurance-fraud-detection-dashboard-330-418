#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/insurance-fraud-detection-dashboard-330-418/insurance_db"
: "${PGHOST:?PGHOST must be set (e.g. localhost)}"
PGPORT="${PGPORT:-5432}"
STARTED_BY_SCRIPT=0
if [ -d /run/systemd/system ] && [ "$(ps -p 1 -o comm=)" = "systemd" ] && command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q postgresql; then
  if systemctl --quiet is-active postgresql; then echo "postgresql: systemd active"; else sudo systemctl start postgresql && STARTED_BY_SCRIPT=1; fi
else
  DATADIR=$(mktemp -d "/tmp/pgdata.XXXX")
  trap 'pg_ctl -D "$DATADIR" -w stop >/dev/null 2>&1 || true; rm -rf "$DATADIR"' EXIT
  initdb -D "$DATADIR"
  echo "local all all trust" > "$DATADIR/pg_hba.conf"
  pg_ctl -D "$DATADIR" -o "-c listen_addresses=localhost -c unix_socket_directories=/tmp" -w start
  STARTED_BY_SCRIPT=2
  export PGHOST="${PGHOST:-localhost}"
  export PGPORT="${PGPORT:-5432}"
  # export DATADIR for other scripts
  echo "$DATADIR" > "$WS/.init/ephemeral_pg_datadir" || true
fi
# record start marker
mkdir -p "$WS/.init" && printf "%s" "$STARTED_BY_SCRIPT" > "$WS/.init/start_marker"
