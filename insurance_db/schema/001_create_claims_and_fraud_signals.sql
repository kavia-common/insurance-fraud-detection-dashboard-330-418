-- Migration: Create claims and fraud_signals tables for the Insurance Fraud Detection demo.
-- Note: This is a reference migration file. When executing against Supabase Postgres,
-- run statements ONE AT A TIME (psql -c ...) as per project rules.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.claims (
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
  risk_level text NOT NULL CHECK (risk_level IN ('low','medium','high')),
  risk_score integer NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new','in_review','approved','denied')),
  assigned_investigator text,
  outcome text CHECK (outcome IN ('fraud','not_fraud')),

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

CREATE INDEX IF NOT EXISTS idx_claims_risk_level ON public.claims(risk_level);
CREATE INDEX IF NOT EXISTS idx_claims_status ON public.claims(status);
CREATE INDEX IF NOT EXISTS idx_claims_created_at ON public.claims(created_at);
CREATE INDEX IF NOT EXISTS idx_fraud_signals_claim_id ON public.fraud_signals(claim_id);
CREATE INDEX IF NOT EXISTS idx_fraud_signals_severity ON public.fraud_signals(severity);

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
