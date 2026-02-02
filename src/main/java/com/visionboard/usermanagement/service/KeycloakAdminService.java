package com.visionboard.usermanagement.service;

import com.visionboard.usermanagement.config.KeycloakProperties;
import com.visionboard.usermanagement.exception.KeycloakException;
import jakarta.ws.rs.core.Response;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.RealmResource;
import org.keycloak.admin.client.resource.UserResource;
import org.keycloak.admin.client.resource.UsersResource;
import org.keycloak.representations.idm.CredentialRepresentation;
import org.keycloak.representations.idm.UserRepresentation;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.UUID;

/**
 * Service for Keycloak Admin API operations.
 * Handles user creation, retrieval, and management in Keycloak.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class KeycloakAdminService {

    private final Keycloak keycloakAdminClient;
    private final KeycloakProperties keycloakProperties;

    /**
     * Create a new user in Keycloak.
     *
     * @param email     user email (also used as username)
     * @param password  user password
     * @param firstName user first name
     * @param lastName  user last name
     * @return Keycloak user ID (UUID)
     * @throws KeycloakException if user creation fails
     */
    public UUID createUser(String email, String password, String firstName, String lastName) {
        try {
            log.info("Creating user in Keycloak: {}", email);

            // Get realm resource
            RealmResource realmResource = keycloakAdminClient.realm(keycloakProperties.getRealm());
            UsersResource usersResource = realmResource.users();

            // Create user representation
            UserRepresentation user = new UserRepresentation();
            user.setUsername(email);
            user.setEmail(email);
            user.setFirstName(firstName);
            user.setLastName(lastName);
            user.setEnabled(true); // Auto-enabled for Minimal MVP
            user.setEmailVerified(false); // Not verified, but account is active
            user.setAttributes(Collections.singletonMap("source", List.of("backend-api")));

            // Create password credential
            CredentialRepresentation credential = new CredentialRepresentation();
            credential.setType(CredentialRepresentation.PASSWORD);
            credential.setValue(password);
            credential.setTemporary(false); // Permanent password
            user.setCredentials(Collections.singletonList(credential));

            // Create user in Keycloak
            Response response = usersResource.create(user);

            if (response.getStatus() != 201) {
                String errorMessage = response.readEntity(String.class);
                log.error("Failed to create user in Keycloak. Status: {}, Error: {}",
                        response.getStatus(), errorMessage);
                throw new KeycloakException("Failed to create user in Keycloak: " + errorMessage);
            }

            // Extract user ID from Location header
            String locationHeader = response.getHeaderString("Location");
            String userId = locationHeader.substring(locationHeader.lastIndexOf('/') + 1);

            log.info("User created successfully in Keycloak with ID: {}", userId);

            return UUID.fromString(userId);

        } catch (Exception e) {
            log.error("Error creating user in Keycloak: {}", e.getMessage(), e);
            throw new KeycloakException("Failed to create user in Keycloak", e);
        }
    }

    /**
     * Get user from Keycloak by user ID.
     *
     * @param userId Keycloak user ID
     * @return UserRepresentation
     * @throws KeycloakException if user retrieval fails
     */
    public UserRepresentation getUserById(UUID userId) {
        try {
            log.debug("Retrieving user from Keycloak: {}", userId);

            RealmResource realmResource = keycloakAdminClient.realm(keycloakProperties.getRealm());
            UserResource userResource = realmResource.users().get(userId.toString());

            return userResource.toRepresentation();

        } catch (Exception e) {
            log.error("Error retrieving user from Keycloak: {}", e.getMessage(), e);
            throw new KeycloakException("Failed to retrieve user from Keycloak", e);
        }
    }

    /**
     * Check if user exists in Keycloak by email.
     *
     * @param email user email
     * @return true if user exists, false otherwise
     */
    public boolean userExistsByEmail(String email) {
        try {
            log.debug("Checking if user exists in Keycloak: {}", email);

            RealmResource realmResource = keycloakAdminClient.realm(keycloakProperties.getRealm());
            UsersResource usersResource = realmResource.users();

            List<UserRepresentation> users = usersResource.search(email, true);

            return !users.isEmpty();

        } catch (Exception e) {
            log.error("Error checking user existence in Keycloak: {}", e.getMessage(), e);
            return false;
        }
    }
}
