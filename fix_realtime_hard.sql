-- FORCE REALTIME 🔴
-- 1. Set Replica Identity to Full (ensures all data is sent on change)
ALTER TABLE public.messages REPLICA IDENTITY FULL;

-- 2. Add to Publication (Create if not exists, though supabase_realtime usually exists)
-- We try to add it. If it throws an error saying "already exists", that's fine (but we can't easily CATCH in simple SQL script).
-- So we drop and re-add to be sure.

ALTER PUBLICATION supabase_realtime DROP TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
