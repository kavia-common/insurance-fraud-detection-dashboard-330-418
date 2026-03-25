# insurance_db (Supabase/Postgres)

This container represents the Supabase Postgres database backing the Insurance Fraud Detection demo.

## What the backend API expects (schema alignment)

The backend (`fraud_detection_api`) reads/writes these tables:

### `public.claims`

Core fields:
- `id` (uuid, PK)
- `claim_number` (text, unique, required)
- `policy_number` (text, required)
- `claimant_name` (text, required)
- `claimant_email` (text, optional)
- `incident_date` (date, required) **(older naming)**
- `claim_date` (date, optional) **(newer naming, backend supports either)**
- `report_date` (date, required)
- `claim_amount` (numeric, required)
- `incident_type` (text, required)
- `description` (text, optional)

Risk fields:
- `risk_score` (int 0..100, required)
- `risk_level` (text: low|medium|high, optional)
- `risk_band` (text: low|medium|high, optional)
  - Backend detects which column exists and uses it.

Workflow fields:
- `status` (text) supported values:
  - queue: `new`, `pending`, `in_review`
  - reviewed: `approved`, `denied`
- `outcome` (text: `fraud` | `not_fraud`, optional)
- `outcome_at` (timestamptz, optional) used for “reviewed today” reporting when present
- `investigator_notes` (text, optional)
- `assigned_investigator` (text, optional)

Timestamps:
- `created_at` (timestamptz, default now)
- `updated_at` (timestamptz, default now; auto-updated via trigger)

### `public.fraud_signals`

- `id` (uuid, PK)
- `claim_id` (uuid, FK -> claims.id)
- `signal_type` (text)
- `severity` (text: low|medium|high)
- `description` (text)
- `rule_code` (text, optional)
- `metadata` (jsonb)
- `created_at` (timestamptz)

## Required environment variables

This container currently includes:

- `SUPABASE_URL`
- `SUPABASE_KEY`

These are **not sufficient** to run SQL via `psql` directly; to run migrations/seeds using `psql`, you also need a **Postgres connection string** (or individual `PGHOST/PGUSER/PGDATABASE/PGPASSWORD/PGPORT` values).

In many Supabase setups, this comes from one of:
- Supabase Project Settings → Database → Connection string (`postgresql://...`)
- A local file like `db_connection.txt` containing a `psql postgresql://...` command

**Note:** `db_connection.txt` was not found in this repository/workspace. Add it (recommended), or provide the connection string via env var(s).

## Service role vs RLS (important)

- The backend typically uses a **Supabase service role key** (often stored as `SUPABASE_KEY` in the backend environment for demos).
- **Service role keys bypass Row Level Security (RLS)**.
- If you enable RLS, you must create appropriate policies for whichever role is accessing the tables (e.g. `authenticated` users for direct browser access).

In this repo, the SQL migration includes **commented** example RLS enablement/policies. Keep them disabled unless you specifically need client-side direct DB access.

## How to run SQL statements (ONE AT A TIME)

Once you have the connection string, run each statement individually, for example:

```bash
export DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/postgres"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "SELECT 1;"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "CREATE TABLE ...;"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "INSERT INTO ...;"
```

This project’s migration and seed statements are documented in:
- `schema/001_create_claims_and_fraud_signals.sql`
- `schema/002_seed_10_claims.sql`

## If you want a db_connection.txt (recommended)

Create a file `db_connection.txt` with content like:

```txt
psql "postgresql://USER:PASSWORD@HOST:5432/postgres" -v ON_ERROR_STOP=1
```

Then you can run:

```bash
$(cat db_connection.txt) -c "SELECT 1;"
```
