-- Add is_read column to messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;

-- Optional: Create an index for performance if querying unread messages often
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON public.messages(is_read);
