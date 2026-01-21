-- Fix RLS to allow "Ghost Replies"
-- Currently, you can only insert messages where YOU are the sender.
-- We need to allow you to insert messages where YOU are the RECEIVER (so the ghost can "reply" to you locally).

DROP POLICY IF EXISTS "Users can insert their own messages" ON public.messages;

CREATE POLICY "Users can send or receive messages"
  ON public.messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id 
    OR 
    auth.uid() = receiver_id
  );
