-- ============================================================
-- UNANI ACADEMY - CLEANUP INCORRECT EXTENSIONS (.pat)
-- ============================================================

-- This script deletes rows from the 'materials' table that have 
-- an incorrect '.pat' extension instead of '.pdf'.

-- 1. Identify and delete rows with .pat extension in file_name or file_url
DELETE FROM public.materials 
WHERE file_name ILIKE '%.pat' 
   OR file_url ILIKE '%.pat';

-- 2. (Optional) If you also want to clean up other malformed entries
-- DELETE FROM public.materials WHERE file_url NOT ILIKE '%.pdf';

-- NOTE: You will still need to manually delete the actual files from 
-- Supabase Storage in the "study-materials" bucket if they exist there.
