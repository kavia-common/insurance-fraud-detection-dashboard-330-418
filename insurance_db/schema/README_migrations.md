# Supabase migrations/seeds (how to apply)

This repo includes reference SQL files:

- `001_create_claims_and_fraud_signals.sql`
- `002_seed_10_claims.sql`

## What these migrations provide (aligned with backend API)

The schema is aligned with backend endpoints:
- `/api/claims` (list/search/sort/filter)
- `/api/queue` (reads claims in statuses `new|pending|in_review` ordered by `risk_score`)
- `/api/claims/:id/outcome` (writes `outcome`, `status`, optional `investigator_notes`, and `outcome_at`)
- `/api/reports/summary` (aggregates by risk band, status, outcomes, and “reviewed today” via `outcome_at` when present)

To remain compatible across iterations, the schema supports both:
- `risk_level` and `risk_band`
- `incident_date` and `claim_date`

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

## RLS note (service role vs client role)

The backend typically uses a Supabase **service role** key, which bypasses RLS.

If you decide to enable RLS for direct client-side access, you must add policies for the appropriate role(s). The migration includes commented examples you can adapt.
