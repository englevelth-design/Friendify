-- FORCE REALTIME (FINAL) 🔴
-- 1. Set Replica Identity to Full
ALTER TABLE public.messages REPLICA IDENTITY FULL;

-- 2. Add to Publication (using a safer method that ignores if it exists, or just direct add since we know it's missing)
-- Since the previous error said "is not part of the publication", we can safe ADD it.

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
