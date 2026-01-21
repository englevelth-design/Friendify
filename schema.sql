-- Enable PostGIS for location features
create extension if not exists postgis;

-- Create Profiles table (public data)
create table public.profiles (
  id uuid references auth.users not null primary key,
  name text,
  age int,
  bio text,
  image_urls text[], -- Array of image strings
  interests text[],  -- Array of interest strings
  location geography(POINT), -- PostGIS location
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Turn on Row Level Security
alter table public.profiles enable row level security;

-- Allow everyone to read profiles (for swiping)
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

-- Allow users to insert/update their own profile
create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );
