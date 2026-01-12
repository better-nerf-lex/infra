-- Migration to add Cognito integration columns to users table
-- Run this if the database was created before these columns were added

-- Add cognito_sub column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'cognito_sub'
    ) THEN
        ALTER TABLE users ADD COLUMN cognito_sub VARCHAR(255) UNIQUE;
        RAISE NOTICE 'Added cognito_sub column to users table';
    END IF;
END $$;

-- Add email_verified column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'email_verified'
    ) THEN
        ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added email_verified column to users table';
    END IF;
END $$;

-- Make password column nullable if it isn't already
DO $$
BEGIN
    ALTER TABLE users ALTER COLUMN password DROP NOT NULL;
    RAISE NOTICE 'Made password column nullable';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Password column already nullable or error: %', SQLERRM;
END $$;

-- Verify changes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;
