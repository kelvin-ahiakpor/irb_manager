-- Ashesi IRB Manager — test seed
-- Run manually via psql or Supabase SQL editor.
-- Deletes all existing test applications then inserts fresh rows.

-- ── Clean up ─────────────────────────────────────────────────────────────────
DELETE FROM notifications;
DELETE FROM status_history;
DELETE FROM attachments;
DELETE FROM applications;

-- ── Seed applications ─────────────────────────────────────────────────────────
INSERT INTO applications (id, student_id, student_name, student_email, student_phone, subject, body, status, submission_method, submitted_at) VALUES

  -- PENDING — email, no phone (covers 6.4: email sent, SMS skipped)
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
   '88292024', 'Kojo Mensah', 'kelvin.ahiakpor@ashesi.edu.gh', NULL,
   'Impact of FinTech on Rural Trade',
   'This study investigates how mobile money adoption influences trading patterns of small-scale farmers in the Eastern Region.',
   'PENDING', 'email', now() - interval '15 days'),

  -- PENDING — web form, phone 1
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
   '55671923', 'Nana Adjei', 'kelvin.ahiakpor@ashesi.edu.gh', '+233505538564',
   'AI Diagnostics in Rural Clinics',
   'Examining the effectiveness of AI-assisted diagnostic tools in under-resourced clinics across rural Ghana.',
   'PENDING', 'web_form', now() - interval '12 days'),

  -- IN REVIEW — email, phone 2
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc',
   '11022025', 'Aba Williams', 'kelvin.ahiakpor@ashesi.edu.gh', '+233256907750',
   'Mental Health Awareness Among University Students',
   'A mixed-methods study on mental health stigma and help-seeking behaviour among Ashesi undergraduates.',
   'UNDER REVIEW', 'email', now() - interval '10 days'),

  -- IN REVIEW — web form, phone 3
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd',
   '33212025', 'Kwame Appiah', 'kelvin.ahiakpor@ashesi.edu.gh', '+233240807564',
   'Gamification in STEM Education',
   'Evaluating whether game-based learning platforms improve engagement and retention in secondary school STEM subjects.',
   'UNDER REVIEW', 'web_form', now() - interval '8 days'),

  -- CONDITIONALLY APPROVED — email, phone 1
  ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
   '99282024', 'Esi Ansah', 'kelvin.ahiakpor@ashesi.edu.gh', '+233505538564',
   'Student Data Privacy in EdTech Platforms',
   'Assessing data collection practices of commonly used EdTech tools and their compliance with student privacy norms.',
   'CONDITIONALLY APPROVED', 'email', now() - interval '6 days'),

  -- APPROVED — web form, phone 2
  ('ffffffff-ffff-4fff-8fff-ffffffffffff',
   '44912024', 'Yaw Boateng', 'kelvin.ahiakpor@ashesi.edu.gh', '+233256907750',
   'Classroom Feedback Systems and Learning Outcomes',
   'Measuring the impact of real-time digital feedback tools on academic performance in blended learning environments.',
   'APPROVED', 'web_form', now() - interval '4 days'),

  -- REJECTED — email, phone 3
  ('a0a0a0a0-a0a0-4a0a-8a0a-a0a0a0a0a0a0',
   '77102024', 'Ama Owusu', 'kelvin.ahiakpor@ashesi.edu.gh', '+233240807564',
   'Biometric Attendance Pilot Study',
   'Pilot deployment of fingerprint-based attendance tracking in campus lecture halls and analysis of student response.',
   'REJECTED', 'email', now() - interval '2 days'),

  -- PENDING — web form, phone 1 (extra for dashboard volume)
  ('b1b1b1b1-b1b1-4b1b-8b1b-b1b1b1b1b1b1',
   '22081923', 'Efua Sarkodee', 'kelvin.ahiakpor@ashesi.edu.gh', '+233505538564',
   'Social Media Use and Academic Performance',
   'Quantitative study correlating daily social media usage hours with GPA across three Ashesi cohorts.',
   'PENDING', 'web_form', now() - interval '1 day');
