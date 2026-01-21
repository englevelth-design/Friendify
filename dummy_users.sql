-- TEMPORARY: Remove the strict link between profiles and auth.users
-- This allows us to create "Ghost Users" who can't log in but appear in the app.
ALTER TABLE public.profiles DROP CONSTRAINT profiles_id_fkey;

INSERT INTO public.profiles (id, name, age, bio, interests, image_urls, location)
VALUES 
  (
    gen_random_uuid(), 
    'Luna Voltage', 
    24, 
    'Electric vibes only. Looking for someone to light up the sky with. ⚡', 
    ARRAY['EDM', 'Night Walks', 'Neon Art'], 
    ARRAY['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop'],
    ST_SetSRID(ST_MakePoint(-73.935242, 40.730610), 4326) -- New York
  ),
  (
    gen_random_uuid(), 
    'Neon Rider', 
    27, 
    'Cruising through the city at night. 🏍️', 
    ARRAY['Motorcycles', 'Synthwave', 'Photography'], 
    ARRAY['https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop'],
    ST_SetSRID(ST_MakePoint(-118.243683, 34.052235), 4326) -- LA
  ),
  (
    gen_random_uuid(), 
    'Star Gazer', 
    22, 
    'Lost in the cosmos. 🌌', 
    ARRAY['Astronomy', 'Sci-Fi', 'Coffee'], 
    ARRAY['https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=500&auto=format&fit=crop'],
    ST_SetSRID(ST_MakePoint(-0.127758, 51.507351), 4326) -- London
  );
