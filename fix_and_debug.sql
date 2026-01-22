-- 1. Fix existing users who are stuck in onboarding
UPDATE profiles
SET profile_complete = TRUE
WHERE profile_complete IS NULL OR profile_complete = FALSE;

-- 2. Inspect the handle_new_user function to see if it sets profile_complete
SELECT prosrc FROM pg_proc WHERE proname = 'handle_new_user';
