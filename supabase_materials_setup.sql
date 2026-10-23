-- ============================================================
-- UNANI ACADEMY - MATERIALS BACKEND SETUP (FIXED)
-- ============================================================

-- 1. DATABASE FIX (STRICT)
create extension if not exists "uuid-ossp";

create table if not exists materials (
  id uuid primary key default uuid_generate_v4(),
  year text,
  subject text,
  file_name text,
  file_url text,
  created_at timestamp with time zone default now()
);

-- 2. DISABLE RLS (OR ALLOW ALL FOR TESTING)
alter table materials enable row level security;

drop policy if exists "Allow all operations" on materials;
create policy "Allow all operations"
on materials
for all
using (true)
with check (true);

-- STEP 1: FIX SELECT PERMISSION (CRITICAL)
drop policy if exists "Allow read access" on materials;
create policy "Allow read access"
on materials
for select
using (true);

-- 3. STORAGE FIX (CRITICAL) - Bucket: study-materials
-- This script ensures the bucket exists and is public
insert into storage.buckets (id, name, public)
values ('study-materials', 'study-materials', true)
on conflict (id) do update set public = true;

-- Storage Policies: Allow public read and all operations for development/testing
-- STEP 1: VERIFY STORAGE BUCKET (CRITICAL)
drop policy if exists "Allow public read access" on storage.objects;
drop policy if exists "Public read" on storage.objects;
create policy "Public read"
on storage.objects for select
using (bucket_id = 'study-materials');

drop policy if exists "Allow all operations on storage" on storage.objects;
create policy "Allow all operations on storage"
on storage.objects for all
using (bucket_id = 'study-materials')
with check (bucket_id = 'study-materials');

-- schema-level grants (Crucial for Web/CORS)
grant usage on schema storage to anon, authenticated;
grant all on all tables in schema storage to anon, authenticated;
grant all on all sequences in schema storage to anon, authenticated;
grant all on all functions in schema storage to anon, authenticated;
