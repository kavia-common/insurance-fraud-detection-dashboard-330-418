import os
import pytest
try:
    import psycopg2
except Exception:
    pytest.skip('psycopg2 not available')
PGHOST = os.getenv('PGHOST')
PGUSER = os.getenv('PGUSER')
PGDATABASE = os.getenv('PGDATABASE')
if not (PGHOST and PGUSER and PGDATABASE):
    pytest.skip('PGHOST, PGUSER and PGDATABASE must be set to run DB connectivity test')
PGPORT = int(os.getenv('PGPORT', '5432'))
PGPASSWORD = os.getenv('PGPASSWORD', '')

def test_connect():
    conn = None
    try:
        conn = psycopg2.connect(host=PGHOST, port=PGPORT, user=PGUSER, password=PGPASSWORD or None, dbname=PGDATABASE)
        cur = conn.cursor()
        cur.execute('SELECT 1')
        assert cur.fetchone()[0] == 1
    finally:
        if conn:
            conn.close()
