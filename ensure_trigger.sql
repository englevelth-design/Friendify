-- 1. Redefine the function function to ensure it sets defaults correctly
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, age, bio, image_urls, interests, profile_complete)
  VALUES (
    new.id,
    new.raw_user_meta_data ->> 'name',
    NULL, -- Age default
    '', -- Bio default
    ARRAY[]::text[], -- Empty images
    ARRAY[]::text[], -- Empty interests
    FALSE -- EXPLICITLY set profile_complete to FALSE
  );
  RETURN new;
END;
$$;

-- 2. Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 3. Just in case, update all existing users again to be sure
UPDATE profiles
SET profile_complete = TRUE
WHERE profile_complete IS NULL;
