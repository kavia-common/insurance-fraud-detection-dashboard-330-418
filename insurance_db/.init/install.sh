#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/insurance-fraud-detection-dashboard-330-418/insurance_db"
# ensure libpq-dev (headers for psycopg2)
if ! dpkg -s libpq-dev >/dev/null 2>&1; then
  sudo apt-get update -q && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libpq-dev
fi
# install pytest: prefer apt package for system-managed stability, else pip
if ! dpkg -s python3-pytest >/dev/null 2>&1; then
  if apt-cache show python3-pytest >/dev/null 2>&1; then
    sudo apt-get update -q && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-pytest
  else
    sudo python3 -m pip install --upgrade --no-input pytest || { echo "error: pytest pip install failed" >&2; exit 17; }
  fi
fi
# report pytest version
python3 -c "import pytest; print('pytest', getattr(pytest,'__version__','unknown'))"
# verify Python DB client: prefer psycopg2, fall back to asyncpg; install psycopg2-binary if neither present
if python3 -c "import psycopg2" >/dev/null 2>&1; then
  python3 -c "import psycopg2; print('psycopg2', getattr(psycopg2,'__version__','unknown'))"
else
  if python3 -c "import asyncpg" >/dev/null 2>&1; then
    python3 -c "import asyncpg; print('asyncpg', getattr(asyncpg,'__version__','unknown'))"
  else
    # attempt to install psycopg2-binary into system python
    sudo python3 -m pip install --upgrade --no-input psycopg2-binary || { echo "error: failed to install psycopg2-binary" >&2; exit 18; }
    python3 -c "import psycopg2; print('psycopg2', getattr(psycopg2,'__version__','unknown'))" || { echo "error: psycopg2 import failed after install" >&2; exit 19; }
  fi
fi
# print basic tool versions for traceability
command -v psql >/dev/null 2>&1 && psql --version || echo "psql not found"
python3 --version || true
python3 -m pip --version || true
