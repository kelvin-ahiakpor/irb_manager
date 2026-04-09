-- Phase 8B: add FCM device token column to reviewers
alter table public.reviewers
  add column if not exists device_token text;

comment on column public.reviewers.device_token is
  'Firebase Cloud Messaging token for push notifications. Updated on each login.';
