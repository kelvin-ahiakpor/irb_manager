-- =============================================================
-- Ashesi IRB Manager — Phase 3: Storage RLS Policies
-- Bucket "attachments" (private, 50MB limit, PDF/image/Word only)
-- was created via API. Run this in Supabase → SQL Editor.
-- =============================================================

-- Reviewers can download files
create policy "Reviewers can read attachments"
  on storage.objects for select
  using (
    bucket_id = 'attachments'
    and public.is_reviewer()
  );

-- Reviewers can upload files
create policy "Reviewers can upload attachments"
  on storage.objects for insert
  with check (
    bucket_id = 'attachments'
    and public.is_reviewer()
  );

-- Reviewers can delete files (e.g. clean up after a rejected app)
create policy "Reviewers can delete attachments"
  on storage.objects for delete
  using (
    bucket_id = 'attachments'
    and public.is_reviewer()
  );
