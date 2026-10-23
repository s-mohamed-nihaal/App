-- Seed Data for Unani Academy Courses
-- Run this AFTER running supabase_setup.sql

-- =====================
-- FIRST YEAR SUBJECTS
-- =====================
INSERT INTO public.courses (title, price, year, file_url) VALUES
('Anatomy', 299, 'Year 1', ''),
('Physiology', 299, 'Year 1', ''),
('Tarika-e-Tibb', 149, 'Year 1', ''),
('Umoor-e-Tabiya', 149, 'Year 1', ''),
('Mantiq wa Falsafa', 99, 'Year 1', ''),
('Urdu & Arabic', 150, 'Year 1', '');

-- =====================
-- SECOND YEAR SUBJECTS
-- =====================
INSERT INTO public.courses (title, price, year, file_url) VALUES
('Community Medicine', 150, 'Year 2', ''),
('Pathology', 399, 'Year 2', ''),
('Sariryath', 199, 'Year 2', ''),
('Forensic & Toxicology', 149, 'Year 2', ''),
('Ilmul Advia', 99, 'Year 2', ''),
('Mufradat', 99, 'Year 2', ''),
('Saidla', 99, 'Year 2', ''),
('Murakhbat', 99, 'Year 2', ''),
('Microbiology', 49, 'Year 2', '');

-- =====================
-- FINAL YEAR SUBJECTS
-- =====================
INSERT INTO public.courses (title, price, year, file_url) VALUES
('Molijat', 599, 'Final Year', ''),
('Gynecology', 199, 'Final Year', ''),
('Obstruction', 199, 'Final Year', ''),
('ENT & Ophthalmology', 199, 'Final Year', ''),
('Pediatric', 199, 'Final Year', ''),
('Research Methodology', 99, 'Final Year', ''),
('IBT', 149, 'Final Year', ''),
('Skin', 99, 'Final Year', ''),
('Surgery 1', 199, 'Final Year', ''),
('Surgery 2', 199, 'Final Year', '');
