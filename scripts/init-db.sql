-- Initialize database for user management service
-- This script is executed during Docker container startup

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE user_management_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'user_management_db')\gexec

-- Connect to the user_management_db
\c user_management_db;

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant permissions (if needed)
GRANT ALL PRIVILEGES ON DATABASE user_management_db TO postgres;