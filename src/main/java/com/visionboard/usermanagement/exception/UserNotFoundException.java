package com.visionboard.usermanagement.exception;

/**
 * Exception thrown when a user is not found.
 * Results in HTTP 404 Not Found response.
 */
public class UserNotFoundException extends RuntimeException {

    public UserNotFoundException(String message) {
        super(message);
    }

    public UserNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
}
