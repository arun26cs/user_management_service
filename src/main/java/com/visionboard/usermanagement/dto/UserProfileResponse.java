package com.visionboard.usermanagement.dto;

import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Response DTO for user profile.
 * Returned by GET /users/me endpoint.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfileResponse {

    private UUID userId;
    private String email;
    private String firstName;
    private String lastName;
    private Instant createdAt;
}
