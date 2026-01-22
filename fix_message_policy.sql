-- Allow users to update messages if they are the sender (editing) OR receiver (marking as read)
create policy "Users can update their own messages or messages sent to them"
  on messages for update
  using ( auth.uid() = sender_id or auth.uid() = receiver_id )
  with check ( auth.uid() = sender_id or auth.uid() = receiver_id );
