-- ============================================================
-- UNANI ACADEMY — MATERIALS TABLE + STORAGE FIX
-- Run this entire script in the Supabase SQL Editor.
-- ============================================================

-- ── 1. Add 'storage_path' column if it doesn't exist ──────────────────────────
--    (This column is used by the Flutter app to reconstruct public URLs reliably.)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'materials'
      AND column_name  = 'storage_path'
  ) THEN
    ALTER TABLE public.materials ADD COLUMN storage_path text NOT NULL DEFAULT '';
  END IF;
END $$;

-- ── 2. Ensure the materials table exists with the correct schema ───────────────
CREATE TABLE IF NOT EXISTS public.materials (
  id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  year         text NOT NULL,
  subject      text NOT NULL,
  file_name    text NOT NULL,         -- Clean display name  e.g. "anatomy_notes.pdf"
  file_url     text NOT NULL DEFAULT '',  -- Full public URL (fallback)
  storage_path text NOT NULL DEFAULT '',  -- Relative path in bucket e.g. "uploads/1234_anatomy_notes.pdf"
  created_at   timestamp with time zone DEFAULT timezone('utc', now())
);

-- ── 3. Enable RLS on materials ────────────────────────────────────────────────
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;

-- Drop old policies to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view materials"          ON public.materials;
DROP POLICY IF EXISTS "Authenticated users can insert"     ON public.materials;
DROP POLICY IF EXISTS "Authenticated users can delete"     ON public.materials;
DROP POLICY IF EXISTS "Allow public read on materials"     ON public.materials;
DROP POLICY IF EXISTS "Allow authenticated insert"         ON public.materials;
DROP POLICY IF EXISTS "Allow authenticated delete"         ON public.materials;

-- Students (unauthenticated) can read all materials
CREATE POLICY "Allow public read on materials"
  ON public.materials FOR SELECT
  USING (true);

-- Admin (authenticated) can insert
CREATE POLICY "Allow authenticated insert"
  ON public.materials FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Admin (authenticated) can delete
CREATE POLICY "Allow authenticated delete"
  ON public.materials FOR DELETE
  USING (auth.role() = 'authenticated');

-- ── 4. Ensure 'study-materials' storage bucket exists and is PUBLIC ───────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('study-materials', 'study-materials', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ── 5. Storage RLS policies ───────────────────────────────────────────────────
-- Drop old / conflicting policies
DROP POLICY IF EXISTS "Public can read study-materials"           ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can upload study-materials"  ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can delete study-materials"  ON storage.objects;
DROP POLICY IF EXISTS "Public Access"                             ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload"                      ON storage.objects;

-- Anyone (students, guests) can read files from the bucket
CREATE POLICY "Public can read study-materials"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'study-materials');

-- Authenticated users (admin) can upload files
CREATE POLICY "Authenticated can upload study-materials"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'study-materials'
    AND auth.role() = 'authenticated'
  );

-- Authenticated users (admin) can delete files
CREATE POLICY "Authenticated can delete study-materials"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'study-materials'
    AND auth.role() = 'authenticated'
  );

-- ── 6. Clean up bad records ───────────────────────────────────────────────────
-- Remove rows where file_name contains raw spaces or %20 encoding
DELETE FROM public.materials
WHERE file_name LIKE '% %'       -- has raw spaces
   OR file_name LIKE '%\%20%'    -- has URL-encoded spaces
   OR file_name LIKE '%.pat';    -- wrong extension

-- Remove rows with no storage path AND a broken/empty URL
DELETE FROM public.materials
WHERE (storage_path = '' OR storage_path IS NULL)
  AND (file_url   = '' OR file_url   IS NULL);

-- ── Done ──────────────────────────────────────────────────────────────────────
-- After running this script:
-- 1. From the admin panel, re-upload any files that were deleted above.
-- 2. Verify in the Supabase Storage UI that the 'study-materials' bucket is public.
-- 3. Test the student flow: open a subject → tap a file → PDF loads without error.
