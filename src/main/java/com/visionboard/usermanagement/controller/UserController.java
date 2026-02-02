package com.visionboard.usermanagement.controller;

import com.visionboard.usermanagement.dto.UserProfileResponse;
import com.visionboard.usermanagement.dto.UserRegistrationRequest;
import com.visionboard.usermanagement.dto.UserRegistrationResponse;
import com.visionboard.usermanagement.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * REST controller for user management endpoints.
 * Handles user registration and profile retrieval.
 */
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Slf4j
public class UserController {

    private final UserService userService;

    /**
     * Register a new user.
     * 
     * POST /users/register
     * 
     * @param request registration request with email, password, firstName, lastName
     * @return registration response with user details (HTTP 201)
     */
    @PostMapping("/register")
    public ResponseEntity<UserRegistrationResponse> registerUser(
            @Valid @RequestBody UserRegistrationRequest request) {

        log.info("Registration request received for email: {}", request.getEmail());

        UserRegistrationResponse response = userService.registerUser(request);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Get current user profile.
     * 
     * GET /users/me
     * 
     * Requires authentication (Bearer token).
     * 
     * @param jwt JWT token from authentication
     * @return user profile response (HTTP 200)
     */
    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getCurrentUserProfile(
            @AuthenticationPrincipal Jwt jwt) {

        // Extract user ID from JWT 'sub' claim
        String userIdString = jwt.getSubject();
        UUID userId = UUID.fromString(userIdString);

        log.info("Profile request received for user ID: {}", userId);

        UserProfileResponse response = userService.getUserProfile(userId);

        return ResponseEntity.ok(response);
    }
}
