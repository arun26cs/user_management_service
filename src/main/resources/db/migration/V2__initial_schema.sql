-- User Management - Initial Database Schema
-- Version: 1.0
-- Description: Creates users, user_profiles, and sessions tables with indexes and constraints

-- Create users table
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    account_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    
    -- Constraints
    CONSTRAINT chk_account_status CHECK (account_status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'PENDING_DELETION', 'DELETED')),
    CONSTRAINT chk_failed_login_attempts CHECK (failed_login_attempts >= 0 AND failed_login_attempts <= 10)
);

-- Add comments
COMMENT ON TABLE users IS 'Core user account entity with authentication and lifecycle data';
COMMENT ON COLUMN users.user_id IS 'Keycloak user ID (external reference)';
COMMENT ON COLUMN users.account_status IS 'Account status: pending, active, suspended, pending_deletion, deleted';
COMMENT ON COLUMN users.email_verified IS 'Email verification status (Phase 1)';
COMMENT ON COLUMN users.failed_login_attempts IS 'Count of failed login attempts (Phase 2)';
COMMENT ON COLUMN users.locked_until IS 'Account lockout expiration timestamp (Phase 2)';

-- Create user_profiles table
CREATE TABLE user_profiles (
    profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    display_name VARCHAR(100) NULL,
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    preferences JSONB NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Foreign key
    CONSTRAINT fk_user_profiles_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Add comments
COMMENT ON TABLE user_profiles IS 'User profile information and preferences';
COMMENT ON COLUMN user_profiles.preferences IS 'Key-value preferences stored as JSONB (namespaced keys)';

-- Create sessions table (optional)
CREATE TABLE sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    auth_token TEXT NOT NULL,
    refresh_token TEXT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    last_activity_at TIMESTAMP NOT NULL DEFAULT NOW(),
    invalidated BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Foreign key
    CONSTRAINT fk_sessions_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Add comments
COMMENT ON TABLE sessions IS 'Authenticated user sessions (optional, Keycloak manages sessions in Minimal MVP)';

-- Create unique indexes
CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Create performance indexes
CREATE INDEX idx_users_account_status ON users(account_status);
CREATE INDEX idx_users_email_verified ON users(email_verified);
CREATE INDEX idx_users_locked_until ON users(locked_until) WHERE locked_until IS NOT NULL;
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_sessions_invalidated ON sessions(invalidated) WHERE invalidated = FALSE;

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
BEFORE UPDATE ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
