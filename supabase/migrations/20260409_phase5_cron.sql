-- =============================================================
-- Ashesi IRB Manager — Phase 5: pg_cron job
-- Calls the mailbox-poller Edge Function every 5 minutes.
-- Run AFTER deploying the Edge Function.
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
    headers := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6bnJ5c2thY2lsZGpjdHp6bnBlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTY4NzI1MiwiZXhwIjoyMDkxMjYzMjUyfQ.rPuoqkhJxJ90mlFuK03JP7tR_yHFbcwyKVPleBmwBQg"}'::jsonb,
    body    := '{}'::jsonb
  );
  $$
);
