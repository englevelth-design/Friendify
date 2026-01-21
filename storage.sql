-- insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);

-- ALLOW READ (Public)
create policy "Public Access"
  on storage.objects for select
  using ( bucket_id = 'avatars' );

-- ALLOW UPLOAD (Auth users only)
create policy "Auth users can upload"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars' 
    and auth.role() = 'authenticated'
  );

-- ALLOW UPDATE (Users can replace their own files)
create policy "Users can update own files"
  on storage.objects for update
  using ( auth.uid() = owner )
  with check ( bucket_id = 'avatars' );
