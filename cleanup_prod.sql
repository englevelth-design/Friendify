-- PRODUCTION CLEANUP 🧹
-- Run this to wipe all test data and prepare for real users.

-- 1. Wipe Matches and Messages
TRUNCATE TABLE public.messages;
TRUNCATE TABLE public.matches;

-- 2. Delete the Ghost Users (Luna, Neon, Star)
-- Note: This only deletes their Profiles. 
-- To delete their Auth Accounts completely, you usually need the Supabase Dashboard > Authentication > Users.
DELETE FROM public.profiles 
WHERE id IN (
  '20a119ea-6f1e-4493-9031-efb1ac29cd1a', -- Luna
  '8d35661b-94c6-4d05-950c-c694bb8cd2ac', -- Neon
  '1208a0df-268e-4f51-872f-53027b4e9f3b'  -- Star
);

-- 3. (Optional) Reset your own profile if you want a clean slate
-- DELETE FROM public.profiles WHERE id = auth.uid();
