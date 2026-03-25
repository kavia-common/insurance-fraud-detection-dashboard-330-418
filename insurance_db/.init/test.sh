#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/insurance-fraud-detection-dashboard-330-418/insurance_db"
python3 - <<'PY'
import os,sys
pghost=os.environ.get('PGHOST')
pguser=os.environ.get('PGUSER')
pgdb=os.environ.get('PGDATABASE')
if not (pghost and pguser and pgdb):
    print('SKIP: PGHOST/PGUSER/PGDATABASE not set')
    sys.exit(0)
try:
    import psycopg2
except Exception as e:
    print('SKIP: psycopg2 not importable:',e)
    sys.exit(0)
try:
    conn=psycopg2.connect(host=pghost, user=pguser, dbname=pgdb, password=os.environ.get('PGPASSWORD'), port=int(os.environ.get('PGPORT','5432')))
    cur=conn.cursor()
    cur.execute('SELECT 1')
    print('DB_TEST: OK')
    cur.close(); conn.close()
except Exception as e:
    print('DB_TEST: FAIL', e); sys.exit(2)
PY
