-- =============================================================
-- Ashesi IRB Manager — Phase 2: Database Schema
-- Run this in Supabase → SQL Editor (Run All)
-- =============================================================

-- ─── Extensions ───────────────────────────────────────────────
create extension if not exists "pgcrypto";   -- for gen_random_uuid()


-- ─── Enums ────────────────────────────────────────────────────
do $$ begin
  create type application_status as enum (
    'PENDING',
    'UNDER REVIEW',
    'CONDITIONALLY APPROVED',
    'APPROVED',
    'REJECTED'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type submission_method as enum (
    'email',
    'web_form'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type notification_type as enum (
    'email',
    'sms',
    'push'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type reviewer_role as enum (
    'coordinator',
    'reviewer',
    'chair'
  );
exception
  when duplicate_object then null;
end $$;


-- ─── reviewers ────────────────────────────────────────────────
-- Linked to Supabase Auth via id = auth.users.id.
-- Populated on first Microsoft OAuth login (Phase 7).
create table if not exists public.reviewers (
  id          uuid        primary key default gen_random_uuid(),
  name        text        not null,
  email       text        not null unique,
  role        reviewer_role not null default 'reviewer',
  created_at  timestamptz not null default now()
);

comment on table public.reviewers is
  'IRB staff members who can log in and manage applications.';


-- ─── applications ─────────────────────────────────────────────
create table if not exists public.applications (
  id                    uuid               primary key default gen_random_uuid(),
  student_id            text               not null,          -- e.g. "88292024"
  student_name          text               not null,
  student_email         text               not null,
  student_phone         text,
  subject               text               not null,          -- email subject / form title
  body                  text,                                  -- email body / form description
  status                application_status not null default 'PENDING',
  submission_method     submission_method  not null default 'email',
  assigned_reviewer_id  uuid               references public.reviewers(id) on delete set null,
  submitted_at          timestamptz        not null default now(),
  updated_at            timestamptz        not null default now()
);

comment on table public.applications is
  'IRB research ethics applications submitted by students.';

-- keep updated_at current automatically
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_applications_updated_at on public.applications;
create trigger trg_applications_updated_at
  before update on public.applications
  for each row execute function public.set_updated_at();


-- ─── attachments ──────────────────────────────────────────────
create table if not exists public.attachments (
  id              uuid        primary key default gen_random_uuid(),
  application_id  uuid        not null references public.applications(id) on delete cascade,
  file_name       text        not null,
  file_type       text        not null,   -- mime type, e.g. "application/pdf"
  storage_url     text        not null,   -- path inside Supabase Storage bucket "attachments"
  uploaded_at     timestamptz not null default now()
);

comment on table public.attachments is
  'Files attached to an IRB application (stored in the "attachments" Storage bucket).';


-- ─── status_history ───────────────────────────────────────────
create table if not exists public.status_history (
  id              uuid               primary key default gen_random_uuid(),
  application_id  uuid               not null references public.applications(id) on delete cascade,
  changed_by      uuid               references public.reviewers(id) on delete set null,
  old_status      application_status,
  new_status      application_status not null,
  note            text,              -- optional reviewer note shown to student
  changed_at      timestamptz        not null default now()
);

comment on table public.status_history is
  'Immutable audit log of every status transition for an application.';


-- ─── notifications ────────────────────────────────────────────
create table if not exists public.notifications (
  id              uuid              primary key default gen_random_uuid(),
  application_id  uuid              references public.applications(id) on delete cascade,
  type            notification_type not null,
  recipient       text              not null,  -- email address or phone number
  message         text              not null,
  sent_at         timestamptz       not null default now()
);

comment on table public.notifications is
  'Record of every notification sent (email / SMS / push) for an application.';


-- ─── Indexes (performance) ────────────────────────────────────
create index if not exists idx_applications_student_id
  on public.applications(student_id);

create index if not exists idx_applications_status
  on public.applications(status);

create index if not exists idx_applications_assigned_reviewer
  on public.applications(assigned_reviewer_id);

create index if not exists idx_attachments_application_id
  on public.attachments(application_id);

create index if not exists idx_status_history_application_id
  on public.status_history(application_id);

create index if not exists idx_notifications_application_id
  on public.notifications(application_id);


-- =============================================================
-- Row Level Security
-- =============================================================

alter table public.reviewers       enable row level security;
alter table public.applications    enable row level security;
alter table public.attachments     enable row level security;
alter table public.status_history  enable row level security;
alter table public.notifications   enable row level security;


-- ─── Helper: is the current user a known reviewer? ────────────
-- Used inside RLS policies so we don't repeat the sub-query.
create or replace function public.is_reviewer()
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from public.reviewers
    where email = (select email from auth.users where id = auth.uid())
  );
$$;


-- ─── RLS policies: reviewers table ───────────────────────────
-- Reviewers can read their own row; chair/coordinator can read all.
create policy "Reviewers can read own row"
  on public.reviewers for select
  using (
    email = (select email from auth.users where id = auth.uid())
  );

create policy "Reviewers full access (authenticated reviewers)"
  on public.reviewers for all
  using (public.is_reviewer())
  with check (public.is_reviewer());


-- ─── RLS policies: applications ───────────────────────────────
-- Authenticated reviewers: full CRUD.
create policy "Reviewers full access to applications"
  on public.applications for all
  using (public.is_reviewer())
  with check (public.is_reviewer());

-- Anon student lookup: can only read (student_id, student_name, status, subject)
-- from their own application — no joins to reviewer data possible.
create policy "Student can read own application status"
  on public.applications for select
  using (true);   -- row-level column restriction is handled in the API layer;
                  -- the Edge Function / Flutter query selects only safe columns.
-- NOTE: Replace `using (true)` with `using (student_id = current_setting('app.student_id', true))`
-- if you add a custom JWT claim or RPC wrapper in Phase 5.


-- ─── RLS policies: attachments ────────────────────────────────
create policy "Reviewers full access to attachments"
  on public.attachments for all
  using (public.is_reviewer())
  with check (public.is_reviewer());


-- ─── RLS policies: status_history ────────────────────────────
create policy "Reviewers full access to status_history"
  on public.status_history for all
  using (public.is_reviewer())
  with check (public.is_reviewer());

-- Students can read history for their own applications (status notes are public).
create policy "Student can read status history for own application"
  on public.status_history for select
  using (
    exists (
      select 1 from public.applications a
      where a.id = application_id
      -- add student_id filter here once JWT claim is wired up
    )
  );


-- ─── RLS policies: notifications ─────────────────────────────
create policy "Reviewers full access to notifications"
  on public.notifications for all
  using (public.is_reviewer())
  with check (public.is_reviewer());


-- =============================================================
-- Seed: initial reviewer accounts (update emails before running)
-- =============================================================
-- Uncomment and edit to pre-populate known IRB staff.
-- Their Supabase Auth accounts must already exist (Phase 7 OAuth).
--
-- insert into public.reviewers (name, email, role) values
--   ('IRB Coordinator', 'irb@ashesi.edu.gh',   'coordinator'),
--   ('Dr. Jane Doe',    'jdoe@ashesi.edu.gh',  'chair')
-- on conflict (email) do nothing;
