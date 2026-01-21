-- UNIVERSAL LOVE SCRIPT ❤️
-- This script makes EVERY profile 'like' EVERY OTHER profile.
-- Run this to instantly verify Matches and Chat functionality.

INSERT INTO public.matches (user_id, match_user_id)
SELECT 
    p1.id as user_id, 
    p2.id as match_user_id
FROM 
    public.profiles p1, 
    public.profiles p2
WHERE 
    p1.id != p2.id
ON CONFLICT (user_id, match_user_id) DO NOTHING;
