package com.visionboard.usermanagement.dto;

import lombok.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Response DTO for user registration.
 * Returned by POST /users/register endpoint.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserRegistrationResponse {

    private UUID userId;
    private String email;
    private String firstName;
    private String lastName;
    private Instant createdAt;
    private String message;
}
