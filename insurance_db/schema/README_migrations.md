# Supabase migrations/seeds (how to apply)

This repo includes reference SQL files:

- `001_create_claims_and_fraud_signals.sql`
- `002_seed_10_claims.sql`

## Important: Supabase REST keys are not enough for psql

The `.env` values `SUPABASE_URL` and `SUPABASE_KEY` are used by the application runtime (Supabase JS client).

To execute SQL migrations/seeds via `psql`, you must provide a **Supabase Postgres connection string** (DATABASE_URL), e.g.:

```bash
export DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/postgres"
```

Then run statements ONE AT A TIME:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";"
# ...repeat for each statement...
```

Or use the provided helper script:

```bash
export DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/postgres"
./scripts/apply_schema_and_seed.sh
```
