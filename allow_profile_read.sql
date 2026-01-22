-- Allow all authenticated users to read profiles (needed for chat names/avatars)
create policy "Users can read all profiles"
  on public.profiles for select
  using ( auth.role() = 'authenticated' );

-- Ensure RLS is enabled
alter table public.profiles enable row level security;
