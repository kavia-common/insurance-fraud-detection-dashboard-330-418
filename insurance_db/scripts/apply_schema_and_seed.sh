#!/usr/bin/env bash
set -euo pipefail

# This script runs SQL statements ONE AT A TIME (as required) using psql.
# It requires a Postgres connection string to Supabase.
#
# Usage:
#   export DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/postgres"
#   ./scripts/apply_schema_and_seed.sh
#
# Notes:
# - The container-provided SUPABASE_URL/SUPABASE_KEY are not enough for psql connectivity.
# - Get DATABASE_URL from Supabase project settings (Database -> Connection string).

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL is not set."
  echo "Provide your Supabase Postgres connection string, e.g.:"
  echo '  export DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/postgres"'
  exit 1
fi

PSQL_BASE=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1)

echo "Running schema (one statement at a time)..."

"${PSQL_BASE[@]}" -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto";'

"${PSQL_BASE[@]}" -c 'CREATE TABLE IF NOT EXISTS public.claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_number text UNIQUE NOT NULL,
  policy_number text NOT NULL,
  claimant_name text NOT NULL,
  claimant_email text,
  incident_date date NOT NULL,
  report_date date NOT NULL,
  claim_amount numeric(12,2) NOT NULL CHECK (claim_amount >= 0),
  incident_type text NOT NULL,
  description text,
  risk_level text NOT NULL CHECK (risk_level IN ('"'"'low'"'"','"'"'medium'"'"','"'"'high'"'"')),
  risk_score integer NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
  status text NOT NULL DEFAULT '"'"'new'"'"' CHECK (status IN ('"'"'new'"'"','"'"'in_review'"'"','"'"'approved'"'"','"'"'denied'"'"')),
  assigned_investigator text,
  outcome text CHECK (outcome IN ('"'"'fraud'"'"','"'"'not_fraud'"'"')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);'

"${PSQL_BASE[@]}" -c 'CREATE TABLE IF NOT EXISTS public.fraud_signals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id uuid NOT NULL REFERENCES public.claims(id) ON DELETE CASCADE,
  signal_type text NOT NULL,
  severity text NOT NULL CHECK (severity IN ('"'"'low'"'"','"'"'medium'"'"','"'"'high'"'"')),
  description text NOT NULL,
  rule_code text,
  metadata jsonb NOT NULL DEFAULT '"'"'{}'"'"'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);'

"${PSQL_BASE[@]}" -c 'CREATE INDEX IF NOT EXISTS idx_claims_risk_level ON public.claims(risk_level);'
"${PSQL_BASE[@]}" -c 'CREATE INDEX IF NOT EXISTS idx_claims_status ON public.claims(status);'
"${PSQL_BASE[@]}" -c 'CREATE INDEX IF NOT EXISTS idx_claims_created_at ON public.claims(created_at);'
"${PSQL_BASE[@]}" -c 'CREATE INDEX IF NOT EXISTS idx_fraud_signals_claim_id ON public.fraud_signals(claim_id);'
"${PSQL_BASE[@]}" -c 'CREATE INDEX IF NOT EXISTS idx_fraud_signals_severity ON public.fraud_signals(severity);'

"${PSQL_BASE[@]}" -c 'CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;'

"${PSQL_BASE[@]}" -c 'DROP TRIGGER IF EXISTS trg_claims_set_updated_at ON public.claims;'
"${PSQL_BASE[@]}" -c 'CREATE TRIGGER trg_claims_set_updated_at
BEFORE UPDATE ON public.claims
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();'

echo "Seeding 10 claims (one statement per INSERT)..."

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10001','POL-90001','Avery Johnson','avery.johnson@example.com','2025-01-10','2025-01-11',18500.00,'Auto','Rear-end collision; late-night incident; conflicting statements reported.','high',92,'in_review','Investigator A')
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10002','POL-90002','Jordan Lee','jordan.lee@example.com','2025-01-22','2025-02-05',42000.00,'Property','Fire damage claim; multiple prior losses; unusual accelerant indicators.','high',88,'in_review','Investigator B')
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10003','POL-90003','Casey Smith','casey.smith@example.com','2025-02-03','2025-02-04',7600.00,'Health','ER visit immediately after policy inception; inconsistent provider documentation.','high',81,'new',NULL)
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10004','POL-90004','Morgan Patel','morgan.patel@example.com','2025-02-14','2025-02-16',2300.00,'Auto','Minor fender bender; moderate documentation; no prior claims.','medium',56,'new',NULL)
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10005','POL-90005','Taylor Nguyen','taylor.nguyen@example.com','2025-02-18','2025-02-25',12950.00,'Property','Water leak; repair estimate high relative to damage photos.','medium',63,'in_review','Investigator C')
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10006','POL-90006','Riley Chen','riley.chen@example.com','2025-03-01','2025-03-02',5100.00,'Travel','Trip cancellation; documentation partial; timing slightly suspicious.','medium',49,'new',NULL)
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10007','POL-90007','Jamie Rivera','jamie.rivera@example.com','2025-03-05','2025-03-06',850.00,'Auto','Parking lot scratch; clear photos; fast reporting.','low',18,'approved',NULL)
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10008','POL-90008','Alex Kim','alex.kim@example.com','2025-03-08','2025-03-09',1200.00,'Property','Theft of bicycle; police report provided; consistent statements.','low',22,'new',NULL)
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10009','POL-90009','Sam Wilson','sam.wilson@example.com','2025-03-10','2025-03-12',300.00,'Health','Routine clinic visit; complete documentation.','low',9,'approved',NULL)
ON CONFLICT (claim_number) DO NOTHING;"

"${PSQL_BASE[@]}" -c "INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10010','POL-90010','Drew Thompson','drew.thompson@example.com','2025-03-15','2025-03-16',2100.00,'Auto','Windshield crack; consistent estimate; no anomalies.','low',14,'new',NULL)
ON CONFLICT (claim_number) DO NOTHING;"

echo "Done."
