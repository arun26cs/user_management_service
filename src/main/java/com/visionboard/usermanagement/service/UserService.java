package com.visionboard.usermanagement.service;

import com.visionboard.usermanagement.domain.User;
import com.visionboard.usermanagement.domain.UserProfile;
import com.visionboard.usermanagement.dto.UserProfileResponse;
import com.visionboard.usermanagement.dto.UserRegistrationRequest;
import com.visionboard.usermanagement.dto.UserRegistrationResponse;
import com.visionboard.usermanagement.exception.EmailAlreadyExistsException;
import com.visionboard.usermanagement.exception.UserNotFoundException;
import com.visionboard.usermanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Service for user management operations.
 * Handles user registration and profile retrieval.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UserRepository userRepository;
    private final KeycloakAdminService keycloakAdminService;

    /**
     * Register a new user.
     * 
     * Steps:
     * 1. Validate email uniqueness in PostgreSQL
     * 2. Create user in Keycloak
     * 3. Store user profile in PostgreSQL
     *
     * @param request registration request
     * @return registration response with user details
     * @throws EmailAlreadyExistsException if email already exists
     */
    @Transactional
    public UserRegistrationResponse registerUser(UserRegistrationRequest request) {
        log.info("Registering new user: {}", request.getEmail());

        // Step 1: Check email uniqueness in PostgreSQL
        if (userRepository.existsByEmailIgnoreCase(request.getEmail())) {
            log.warn("Email already exists: {}", request.getEmail());
            throw new EmailAlreadyExistsException("An account with this email already exists");
        }

        // Step 2: Create user in Keycloak
        UUID keycloakUserId = keycloakAdminService.createUser(
                request.getEmail(),
                request.getPassword(),
                request.getFirstName(),
                request.getLastName());

        // Step 3: Store user in PostgreSQL
        User user = User.builder()
                .userId(keycloakUserId)
                .email(request.getEmail().toLowerCase())
                .accountStatus(User.AccountStatus.ACTIVE) // Auto-activated for Minimal MVP
                .emailVerified(false) // Not verified, but account is active
                .build();

        UserProfile profile = UserProfile.builder()
                .user(user)
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .timezone("UTC")
                .language("en")
                .build();

        user.setProfile(profile);
        userRepository.save(user);

        log.info("User registered successfully: {} with ID: {}", request.getEmail(), keycloakUserId);

        // Return response
        return UserRegistrationResponse.builder()
                .userId(keycloakUserId)
                .email(request.getEmail())
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .createdAt(user.getCreatedAt())
                .message("Registration successful! You can now log in.")
                .build();
    }

    /**
     * Get user profile by user ID.
     *
     * @param userId Keycloak user ID
     * @return user profile response
     * @throws UserNotFoundException if user not found
     */
    @Transactional(readOnly = true)
    public UserProfileResponse getUserProfile(UUID userId) {
        log.debug("Retrieving user profile for user ID: {}", userId);

        User user = userRepository.findByUserIdWithProfile(userId)
                .orElseThrow(() -> new UserNotFoundException("User profile not found"));

        UserProfile profile = user.getProfile();

        return UserProfileResponse.builder()
                .userId(user.getUserId())
                .email(user.getEmail())
                .firstName(profile.getFirstName())
                .lastName(profile.getLastName())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
