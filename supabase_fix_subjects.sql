-- ============================================================
-- UNANI ACADEMY - SUBJECT NAME FIX & SUBJECT_ID MIGRATION
-- ============================================================

-- 1. ADD subject_id COLUMN TO courses AND materials TABLES
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS subject_id text;
ALTER TABLE public.materials ADD COLUMN IF NOT EXISTS subject_id text;

-- 2. FIX INCORRECT SUBJECT NAMES IN courses TABLE
UPDATE public.courses SET subject = 'Moalijat', title = REPLACE(title, 'Molijat', 'Moalijat') WHERE subject = 'Molijat';
UPDATE public.courses SET subject = 'Sariyath', title = REPLACE(title, 'Sariryath', 'Sariyath') WHERE subject = 'Sariryath';
UPDATE public.courses SET subject = 'Murakkabat', title = REPLACE(title, 'Murakhbat', 'Murakkabat') WHERE subject = 'Murakhbat';

-- 3. FIX INCORRECT SUBJECT NAMES IN materials TABLE
UPDATE public.materials SET subject = 'Moalijat' WHERE subject = 'Molijat';
UPDATE public.materials SET subject = 'Sariyath' WHERE subject = 'Sariryath';
UPDATE public.materials SET subject = 'Murakkabat' WHERE subject = 'Murakhbat';

-- 4. POPULATE subject_id IN courses TABLE
UPDATE public.courses SET subject_id = 'anatomy' WHERE subject = 'Anatomy';
UPDATE public.courses SET subject_id = 'physiology' WHERE subject = 'Physiology';
UPDATE public.courses SET subject_id = 'tarika_e_tibb' WHERE subject = 'Tarika-e-Tibb';
UPDATE public.courses SET subject_id = 'umoor_e_tabiya' WHERE subject = 'Umoor-e-Tabiya';
UPDATE public.courses SET subject_id = 'mantiq_wa_falsafa' WHERE subject = 'Mantiq wa Falsafa';
UPDATE public.courses SET subject_id = 'urdu_arabic' WHERE subject = 'Urdu & Arabic';
UPDATE public.courses SET subject_id = 'community_medicine' WHERE subject = 'Community Medicine';
UPDATE public.courses SET subject_id = 'pathology' WHERE subject = 'Pathology';
UPDATE public.courses SET subject_id = 'sariyath' WHERE subject = 'Sariyath';
UPDATE public.courses SET subject_id = 'forensic_toxicology' WHERE subject = 'Forensic & Toxicology';
UPDATE public.courses SET subject_id = 'ilmul_advia' WHERE subject = 'Ilmul Advia';
UPDATE public.courses SET subject_id = 'mufradat' WHERE subject = 'Mufradat';
UPDATE public.courses SET subject_id = 'saidla' WHERE subject = 'Saidla';
UPDATE public.courses SET subject_id = 'murakkabat' WHERE subject = 'Murakkabat';
UPDATE public.courses SET subject_id = 'microbiology' WHERE subject = 'Microbiology';
UPDATE public.courses SET subject_id = 'moalijat' WHERE subject = 'Moalijat';
UPDATE public.courses SET subject_id = 'gynecology' WHERE subject = 'Gynecology';
UPDATE public.courses SET subject_id = 'obstruction' WHERE subject = 'Obstruction';
UPDATE public.courses SET subject_id = 'ent_ophthalmology' WHERE subject = 'ENT & Ophthalmology';
UPDATE public.courses SET subject_id = 'pediatric' WHERE subject = 'Pediatric';
UPDATE public.courses SET subject_id = 'research_methodology' WHERE subject = 'Research Methodology';
UPDATE public.courses SET subject_id = 'ibt' WHERE subject = 'IBT';
UPDATE public.courses SET subject_id = 'skin' WHERE subject = 'Skin';
UPDATE public.courses SET subject_id = 'surgery_1' WHERE subject = 'Surgery 1';
UPDATE public.courses SET subject_id = 'surgery_2' WHERE subject = 'Surgery 2';

-- Handle Packages
UPDATE public.courses SET subject_id = 'package_first_year' WHERE title ILIKE '%First Year Package%' OR title ILIKE '%Year 1 Package%';
UPDATE public.courses SET subject_id = 'package_second_year' WHERE title ILIKE '%Second Year Combo%' OR title ILIKE '%Year 2 Combo%';
UPDATE public.courses SET subject_id = 'package_final_year' WHERE title ILIKE '%Final Year Combo%';

-- 5. POPULATE subject_id IN materials TABLE
UPDATE public.materials SET subject_id = 'anatomy' WHERE subject = 'Anatomy';
UPDATE public.materials SET subject_id = 'physiology' WHERE subject = 'Physiology';
UPDATE public.materials SET subject_id = 'tarika_e_tibb' WHERE subject = 'Tarika-e-Tibb';
UPDATE public.materials SET subject_id = 'umoor_e_tabiya' WHERE subject = 'Umoor-e-Tabiya';
UPDATE public.materials SET subject_id = 'mantiq_wa_falsafa' WHERE subject = 'Mantiq wa Falsafa';
UPDATE public.materials SET subject_id = 'urdu_arabic' WHERE subject = 'Urdu & Arabic';
UPDATE public.materials SET subject_id = 'community_medicine' WHERE subject = 'Community Medicine';
UPDATE public.materials SET subject_id = 'pathology' WHERE subject = 'Pathology';
UPDATE public.materials SET subject_id = 'sariyath' WHERE subject = 'Sariyath';
UPDATE public.materials SET subject_id = 'forensic_toxicology' WHERE subject = 'Forensic & Toxicology';
UPDATE public.materials SET subject_id = 'ilmul_advia' WHERE subject = 'Ilmul Advia';
UPDATE public.materials SET subject_id = 'mufradat' WHERE subject = 'Mufradat';
UPDATE public.materials SET subject_id = 'saidla' WHERE subject = 'Saidla';
UPDATE public.materials SET subject_id = 'murakkabat' WHERE subject = 'Murakkabat';
UPDATE public.materials SET subject_id = 'microbiology' WHERE subject = 'Microbiology';
UPDATE public.materials SET subject_id = 'moalijat' WHERE subject = 'Moalijat';
UPDATE public.materials SET subject_id = 'gynecology' WHERE subject = 'Gynecology';
UPDATE public.materials SET subject_id = 'obstruction' WHERE subject = 'Obstruction';
UPDATE public.materials SET subject_id = 'ent_ophthalmology' WHERE subject = 'ENT & Ophthalmology';
UPDATE public.materials SET subject_id = 'pediatric' WHERE subject = 'Pediatric';
UPDATE public.materials SET subject_id = 'research_methodology' WHERE subject = 'Research Methodology';
UPDATE public.materials SET subject_id = 'ibt' WHERE subject = 'IBT';
UPDATE public.materials SET subject_id = 'skin' WHERE subject = 'Skin';
UPDATE public.materials SET subject_id = 'surgery_1' WHERE subject = 'Surgery 1';
UPDATE public.materials SET subject_id = 'surgery_2' WHERE subject = 'Surgery 2';

-- 6. NORMALIZE YEAR NAMES
UPDATE public.courses SET year = 'First Year' WHERE year = 'Year 1';
UPDATE public.courses SET year = 'Second Year' WHERE year = 'Year 2';
UPDATE public.materials SET year = 'First Year' WHERE year = 'Year 1';
UPDATE public.materials SET year = 'Second Year' WHERE year = 'Year 2';

-- 7. CLEAN UP DUPLICATES (Optional: if any rows have same subject_id and year)
-- This is a simple deduplication keeping the latest record
DELETE FROM public.courses a USING public.courses b
WHERE a.id < b.id 
AND a.subject_id = b.subject_id 
AND a.year = b.year
AND a.subject_id IS NOT NULL;

-- 8. FIX PURCHASES TABLE (IF IT HAS course_name COLUMN)
-- We check for course_name column and update it
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'purchases' AND column_name = 'course_name') THEN
    UPDATE public.purchases SET course_name = 'Moalijat' WHERE course_name = 'Molijat';
    UPDATE public.purchases SET course_name = 'Sariyath' WHERE course_name = 'Sariryath';
    UPDATE public.purchases SET course_name = 'Murakkabat' WHERE course_name = 'Murakhbat';
  END IF;
END $$;
