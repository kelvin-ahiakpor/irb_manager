-- =============================================================
-- Ashesi IRB Manager — Phase 5: pg_cron job
-- Calls the mailbox-poller Edge Function every 5 minutes.
-- Run AFTER deploying the Edge Function.
--
-- Do not commit real secrets in this file. Replace the placeholder locally
-- before running the SQL, or schedule this through a secrets-aware deployment
-- step. The mailbox-poller function must be deployed with --no-verify-jwt and
-- must validate this x-cron-secret header internally.
-- =============================================================

create extension if not exists pg_net;

-- Remove existing job if re-running
select cron.unschedule('mailbox-poller')
where exists (
  select 1 from cron.job where jobname = 'mailbox-poller'
);

select cron.schedule(
  'mailbox-poller',
  '*/5 * * * *',
  $$
  select net.http_post(
    url     := 'https://tznryskacildjctzznpe.supabase.co/functions/v1/mailbox-poller',
    headers := '{"Content-Type":"application/json","x-cron-secret":"<CRON_SECRET>"}'::jsonb,
    body    := '{}'::jsonb
  );
  $$
);
