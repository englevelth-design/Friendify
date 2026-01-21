-- Create MATCHES table
-- A match is a single directional "like".
-- If (A, B) exists AND (B, A) exists, it is a "Match".
create table public.matches (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null, -- The liker
  match_user_id uuid references auth.users not null, -- The liked
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(user_id, match_user_id) -- Prevent duplicate likes
);

-- RLS for Matches
alter table public.matches enable row level security;

create policy "Users can insert their own matches"
  on matches for insert
  with check ( auth.uid() = user_id );

create policy "Users can view matches they are involved in"
  on matches for select
  using ( auth.uid() = user_id or auth.uid() = match_user_id );

-- Create MESSAGES table
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references auth.users not null,
  receiver_id uuid references auth.users not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS for Messages
alter table public.messages enable row level security;

create policy "Users can insert their own messages"
  on messages for insert
  with check ( auth.uid() = sender_id );

create policy "Users can view messages sent to or by them"
  on messages for select
  using ( auth.uid() = sender_id or auth.uid() = receiver_id );
