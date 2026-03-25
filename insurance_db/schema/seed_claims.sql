-- Reference seed data (execute statements ONE AT A TIME via psql -c ...)
-- 10 claims total: 3 high, 3 medium, 4 low

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10001','POL-90001','Avery Johnson','avery.johnson@example.com','2025-01-10','2025-01-11',18500.00,'Auto','Rear-end collision; late-night incident; conflicting statements reported.','high',92,'in_review','Investigator A');

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10002','POL-90002','Jordan Lee','jordan.lee@example.com','2025-01-22','2025-02-05',42000.00,'Property','Fire damage claim; multiple prior losses; unusual accelerant indicators.','high',88,'in_review','Investigator B');

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10003','POL-90003','Casey Smith','casey.smith@example.com','2025-02-03','2025-02-04',7600.00,'Health','ER visit immediately after policy inception; inconsistent provider documentation.','high',81,'new',NULL);

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10004','POL-90004','Morgan Patel','morgan.patel@example.com','2025-02-14','2025-02-16',2300.00,'Auto','Minor fender bender; moderate documentation; no prior claims.','medium',56,'new',NULL);

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10005','POL-90005','Taylor Nguyen','taylor.nguyen@example.com','2025-02-18','2025-02-25',12950.00,'Property','Water leak; repair estimate high relative to damage photos.','medium',63,'in_review','Investigator C');

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10006','POL-90006','Riley Chen','riley.chen@example.com','2025-03-01','2025-03-02',5100.00,'Travel','Trip cancellation; documentation partial; timing slightly suspicious.','medium',49,'new',NULL);

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10007','POL-90007','Jamie Rivera','jamie.rivera@example.com','2025-03-05','2025-03-06',850.00,'Auto','Parking lot scratch; clear photos; fast reporting.','low',18,'approved',NULL);

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10008','POL-90008','Alex Kim','alex.kim@example.com','2025-03-08','2025-03-09',1200.00,'Property','Theft of bicycle; police report provided; consistent statements.','low',22,'new',NULL);

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10009','POL-90009','Sam Wilson','sam.wilson@example.com','2025-03-10','2025-03-12',300.00,'Health','Routine clinic visit; complete documentation.','low',9,'approved',NULL);

INSERT INTO public.claims
(claim_number, policy_number, claimant_name, claimant_email, incident_date, report_date, claim_amount, incident_type, description, risk_level, risk_score, status, assigned_investigator)
VALUES
('CLM-10010','POL-90010','Drew Thompson','drew.thompson@example.com','2025-03-15','2025-03-16',2100.00,'Auto','Windshield crack; consistent estimate; no anomalies.','low',14,'new',NULL);
