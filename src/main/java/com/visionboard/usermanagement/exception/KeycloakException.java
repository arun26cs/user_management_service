package com.visionboard.usermanagement.exception;

/**
 * Exception thrown when Keycloak operations fail.
 * Results in HTTP 500 Internal Server Error response.
 */
public class KeycloakException extends RuntimeException {

    public KeycloakException(String message) {
        super(message);
    }

    public KeycloakException(String message, Throwable cause) {
        super(message, cause);
    }
}
