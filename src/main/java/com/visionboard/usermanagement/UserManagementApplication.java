package com.visionboard.usermanagement;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main application class for User Management Minimal MVP.
 * 
 * This service provides:
 * - User registration (POST /users/register)
 * - User login via OAuth2 (POST /auth/token)
 * - User profile retrieval (GET /users/me)
 * 
 * Authentication is handled by Keycloak.
 * User data is stored in PostgreSQL.
 */
@SpringBootApplication
public class UserManagementApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserManagementApplication.class, args);
    }
}
