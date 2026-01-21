-- Enable Realtime for the messages table
-- This allows the Flutter app to listen for new messages instantly.
alter publication supabase_realtime add table public.messages;
