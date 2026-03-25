-- Migration: Create claims and fraud_signals tables for the Insurance Fraud Detection demo.
-- Note: This is a reference migration file. When executing against Supabase Postgres,
-- run statements ONE AT A TIME (psql -c ...) as per project rules.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Claims represent the primary work item for investigators.
-- This schema intentionally supports both older and newer naming used by the backend:
-- - risk_level (older) + risk_band (newer)
-- - incident_date (older) + claim_date (newer)
-- as well as workflow fields required by API endpoints:
-- - status supports queueing and reviewed states
-- - outcome + outcome_at for investigator decision submission
-- - investigator_notes for notes captured at review time
CREATE TABLE IF NOT EXISTS public.claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_number text UNIQUE NOT NULL,
  policy_number text NOT NULL,
  claimant_name text NOT NULL,
  claimant_email text,

  -- Dates: older schema used incident_date; newer code may refer to claim_date.
  incident_date date NOT NULL,
  claim_date date,
  report_date date NOT NULL,

  claim_amount numeric(12,2) NOT NULL CHECK (claim_amount >= 0),
  incident_type text NOT NULL,
  description text,

  -- Risk: support both risk_level and risk_band (backend detects either).
  risk_level text CHECK (risk_level IN ('low','medium','high')),
  risk_band  text CHECK (risk_band  IN ('low','medium','high')),
  risk_score integer NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),

  -- Workflow status:
  -- Backend queue expects: new|pending|in_review
  -- Reviewed states: approved|denied
  status text NOT NULL DEFAULT 'new'
    CHECK (status IN ('new','pending','in_review','approved','denied')),

  assigned_investigator text,

  -- Investigator decision:
  outcome text CHECK (outcome IN ('fraud','not_fraud')),
  outcome_at timestamptz,
  investigator_notes text,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.fraud_signals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id uuid NOT NULL REFERENCES public.claims(id) ON DELETE CASCADE,
  signal_type text NOT NULL,
  severity text NOT NULL CHECK (severity IN ('low','medium','high')),
  description text NOT NULL,
  rule_code text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes tuned to API query patterns:
-- - /api/claims sort/filter
-- - /api/queue selects by status and orders by risk_score
-- - /api/reports/summary aggregates by risk/outcome/status and uses updated/outcome timestamps
CREATE INDEX IF NOT EXISTS idx_claims_risk_level ON public.claims(risk_level);
CREATE INDEX IF NOT EXISTS idx_claims_risk_band ON public.claims(risk_band);

CREATE INDEX IF NOT EXISTS idx_claims_status ON public.claims(status);
CREATE INDEX IF NOT EXISTS idx_claims_risk_score ON public.claims(risk_score);
CREATE INDEX IF NOT EXISTS idx_claims_status_risk_score ON public.claims(status, risk_score DESC);

CREATE INDEX IF NOT EXISTS idx_claims_created_at ON public.claims(created_at);
CREATE INDEX IF NOT EXISTS idx_claims_updated_at ON public.claims(updated_at);
CREATE INDEX IF NOT EXISTS idx_claims_outcome ON public.claims(outcome);
CREATE INDEX IF NOT EXISTS idx_claims_outcome_at ON public.claims(outcome_at);

CREATE INDEX IF NOT EXISTS idx_fraud_signals_claim_id ON public.fraud_signals(claim_id);
CREATE INDEX IF NOT EXISTS idx_fraud_signals_severity ON public.fraud_signals(severity);

-- Keep updated_at current on any update
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_claims_set_updated_at ON public.claims;

CREATE TRIGGER trg_claims_set_updated_at
BEFORE UPDATE ON public.claims
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------
-- RLS (Row Level Security)
-- ---------------------------
-- The backend in this demo typically uses a Supabase "service role" key, which bypasses RLS.
-- If you want to enable RLS for direct client access, uncomment and tailor the policies below.
--
-- ALTER TABLE public.claims ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.fraud_signals ENABLE ROW LEVEL SECURITY;
--
-- Example: allow authenticated users to read (adjust to your auth model)
-- CREATE POLICY "claims_read_authenticated"
--   ON public.claims
--   FOR SELECT
--   TO authenticated
--   USING (true);
--
-- CREATE POLICY "fraud_signals_read_authenticated"
--   ON public.fraud_signals
--   FOR SELECT
--   TO authenticated
--   USING (true);
