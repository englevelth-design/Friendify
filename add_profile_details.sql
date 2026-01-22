-- Add new profile fields for enhanced onboarding
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS education TEXT,
ADD COLUMN IF NOT EXISTS family_plans TEXT,
ADD COLUMN IF NOT EXISTS pets TEXT,
ADD COLUMN IF NOT EXISTS drinking TEXT,
ADD COLUMN IF NOT EXISTS smoking TEXT,
ADD COLUMN IF NOT EXISTS languages TEXT[],
ADD COLUMN IF NOT EXISTS looking_for TEXT;

-- looking_for is mandatory: "Why are you on Firefly?"
