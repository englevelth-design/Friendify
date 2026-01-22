-- Add gender and interested_in columns to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS interested_in TEXT;

-- update RLS if needed (usually not for new columns if policy is generic)
