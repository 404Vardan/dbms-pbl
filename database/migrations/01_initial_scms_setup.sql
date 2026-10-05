-- =============================================================================
-- SCMS — Combined Complete Setup Script
-- Runs schema.sql, triggers.sql, security.sql, reports.sql in exact sequence.
-- Paste this entire script into your Supabase SQL Editor to initialize
-- all 14 domain tables, business triggers, RLS policies, and reporting views.
-- =============================================================================

\i database/schema.sql
\i database/triggers.sql
\i database/security.sql
\i database/reports.sql
