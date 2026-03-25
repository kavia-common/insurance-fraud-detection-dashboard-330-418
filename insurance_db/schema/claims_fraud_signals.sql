-- Reference migration (execute statements ONE AT A TIME via psql -c ...)
-- Tables:
--   - claims: core claim record with risk band + investigator workflow fields
--   - fraud_signals: detected signals tied to a claim

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_number text UNIQUE NOT NULL,
  policy_number text NOT NULL,
  claimant_name text NOT NULL,
  claimant_email text,

  incident_date date NOT NULL,
  claim_date date,
  report_date date NOT NULL,

  claim_amount numeric(12,2) NOT NULL CHECK (claim_amount >= 0),
  incident_type text NOT NULL,
  description text,

  risk_level text CHECK (risk_level IN ('low','medium','high')),
  risk_band  text CHECK (risk_band  IN ('low','medium','high')),
  risk_score integer NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),

  status text NOT NULL DEFAULT 'new'
    CHECK (status IN ('new','pending','in_review','approved','denied')),

  assigned_investigator text,

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

-- Optional trigger to keep updated_at current
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

-- RLS notes:
-- Backend typically uses service role and bypasses RLS.
-- Enable + add policies only if you plan direct client access.
--
-- ALTER TABLE public.claims ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.fraud_signals ENABLE ROW LEVEL SECURITY;
