# insurance_db (Supabase/Postgres)

This container represents the Supabase Postgres database backing the Insurance Fraud Detection demo.

## Required environment variables

This container currently includes:

- `SUPABASE_URL`
- `SUPABASE_KEY`

These are **not sufficient** to run SQL via `psql` directly; to run migrations/seeds using `psql`, you also need a **Postgres connection string** (or individual `PGHOST/PGUSER/PGDATABASE/PGPASSWORD/PGPORT` values).

In many Supabase setups, this comes from one of:
- Supabase Project Settings → Database → Connection string (`postgresql://...`)
- A local file like `db_connection.txt` containing a `psql postgresql://...` command

**Note:** `db_connection.txt` was not found in this repository/workspace. Add it (recommended), or provide the connection string via env var(s).

## How to run SQL statements (ONE AT A TIME)

Once you have the connection string, run each statement individually, for example:

```bash
export DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/postgres"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "SELECT 1;"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "CREATE TABLE ...;"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "INSERT INTO ...;"
```

This project’s migration and seed statements are documented in:
- `schema/claims_fraud_signals.sql` (reference only; execute statement-by-statement)
- `schema/seed_claims.sql` (reference only; execute statement-by-statement)

## If you want a db_connection.txt (recommended)

Create a file `db_connection.txt` with content like:

```txt
psql "postgresql://USER:PASSWORD@HOST:5432/postgres" -v ON_ERROR_STOP=1
```

Then you can run:

```bash
$(cat db_connection.txt) -c "SELECT 1;"
```
