-- ============================================================
-- UNANI ACADEMY - COMPLETE SUPABASE SCHEMA (Run this in SQL Editor)
-- ============================================================

-- 1. DROP OLD tables if they exist (clean slate)
DROP TABLE IF EXISTS public.purchases CASCADE;
DROP TABLE IF EXISTS public.courses CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- 2. Create USERS table
CREATE TABLE public.users (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name text NOT NULL,
  email text,
  phone text,
  created_at timestamp with time zone DEFAULT timezone('utc', now())
);
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- 3. Create COURSES table (with year + subject columns)
CREATE TABLE public.courses (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  subject text,
  year text NOT NULL,   -- "Year 1", "Year 2", "Final Year"
  price integer NOT NULL DEFAULT 0,
  file_url text NOT NULL DEFAULT '',
  created_at timestamp with time zone DEFAULT timezone('utc', now())
);
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view courses" ON public.courses FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert" ON public.courses FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update" ON public.courses FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete" ON public.courses FOR DELETE USING (auth.role() = 'authenticated');

-- 4. Create PURCHASES table
CREATE TABLE public.purchases (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  course_id uuid REFERENCES public.courses(id) ON DELETE CASCADE NOT NULL,
  purchased_at timestamp with time zone DEFAULT timezone('utc', now()),
  UNIQUE(user_id, course_id)
);
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own purchases" ON public.purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own purchases" ON public.purchases FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. Storage Bucket for Course Files
INSERT INTO storage.buckets (id, name, public)
VALUES ('course-files', 'course-files', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;
CREATE POLICY "Public can view course files" ON storage.objects FOR SELECT USING (bucket_id = 'course-files');
CREATE POLICY "Authenticated can upload course files" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'course-files' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated can delete course files" ON storage.objects FOR DELETE USING (bucket_id = 'course-files' AND auth.role() = 'authenticated');

-- ============================================================
-- SEED DATA - Run AFTER setting up schema
-- ============================================================
INSERT INTO public.courses (title, subject, year, price, file_url) VALUES
-- Year 1
('Anatomy Notes', 'Anatomy', 'Year 1', 299, ''),
('Physiology Notes', 'Physiology', 'Year 1', 299, ''),
('Tarika-e-Tibb Notes', 'Tarika-e-Tibb', 'Year 1', 149, ''),
('Umoor-e-Tabiya Notes', 'Umoor-e-Tabiya', 'Year 1', 149, ''),
('Mantiq wa Falsafa Notes', 'Mantiq wa Falsafa', 'Year 1', 99, ''),
('Urdu & Arabic Notes', 'Urdu & Arabic', 'Year 1', 150, ''),
-- Year 2
('Community Medicine Notes', 'Community Medicine', 'Year 2', 150, ''),
('Pathology Notes', 'Pathology', 'Year 2', 399, ''),
('Sariryath Notes', 'Sariryath', 'Year 2', 199, ''),
('Forensic & Toxicology Notes', 'Forensic & Toxicology', 'Year 2', 149, ''),
('Ilmul Advia Notes', 'Ilmul Advia', 'Year 2', 99, ''),
('Mufradat Notes', 'Mufradat', 'Year 2', 99, ''),
('Saidla Notes', 'Saidla', 'Year 2', 99, ''),
('Murakhbat Notes', 'Murakhbat', 'Year 2', 99, ''),
('Microbiology Notes', 'Microbiology', 'Year 2', 49, ''),
-- Final Year
('Molijat Notes', 'Molijat', 'Final Year', 599, ''),
('Gynecology Notes', 'Gynecology', 'Final Year', 199, ''),
('Obstruction Notes', 'Obstruction', 'Final Year', 199, ''),
('ENT & Ophthalmology Notes', 'ENT & Ophthalmology', 'Final Year', 199, ''),
('Pediatric Notes', 'Pediatric', 'Final Year', 199, ''),
('Research Methodology Notes', 'Research Methodology', 'Final Year', 99, ''),
('IBT Notes', 'IBT', 'Final Year', 149, ''),
('Skin Notes', 'Skin', 'Final Year', 99, ''),
('Surgery 1 Notes', 'Surgery 1', 'Final Year', 199, ''),
('Surgery 2 Notes', 'Surgery 2', 'Final Year', 199, '');
