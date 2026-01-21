-- 1. Create MATCHES table
-- References public.profiles instead of auth.users to allow "Ghost Users"
create table if not exists public.matches (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  match_user_id uuid references public.profiles(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(user_id, match_user_id)
);

-- RLS for Matches
alter table public.matches enable row level security;

create policy "Users can insert their own matches"
  on matches for insert
  with check ( auth.uid() = user_id );

create policy "Users can view matches they are involved in"
  on matches for select
  using ( auth.uid() = user_id or auth.uid() = match_user_id );

-- 2. Create MESSAGES table
create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references public.profiles(id) not null,
  receiver_id uuid references public.profiles(id) not null,

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

-- 3. UNIVERSAL LOVE (Force Mutual Matches for testing)
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
