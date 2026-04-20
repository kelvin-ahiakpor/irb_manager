-- Fix reviewer RLS checks for OAuth users.
--
-- PostgREST requests run as authenticated/anon roles and cannot read
-- auth.users directly from RLS policies. Use the email claim already present
-- in the Supabase Auth JWT instead.

create or replace function public.current_user_email()
returns text
language sql
stable
as $$
  select lower(coalesce(
    auth.jwt() ->> 'email',
    auth.jwt() -> 'user_metadata' ->> 'email'
  ));
$$;

create or replace function public.is_reviewer()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.reviewers
    where lower(email) = public.current_user_email()
  );
$$;

drop policy if exists "Reviewers can read own row" on public.reviewers;
drop policy if exists "Reviewers full access (authenticated reviewers)" on public.reviewers;

create policy "Reviewers can read own row"
  on public.reviewers for select
  to authenticated
  using (lower(email) = public.current_user_email());

create policy "Reviewers full access (authenticated reviewers)"
  on public.reviewers for all
  to authenticated
  using (public.is_reviewer())
  with check (public.is_reviewer());
