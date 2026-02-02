package com.visionboard.usermanagement.exception;

/**
 * Exception thrown when attempting to register with an email that already
 * exists.
 * Results in HTTP 409 Conflict response.
 */
public class EmailAlreadyExistsException extends RuntimeException {

    public EmailAlreadyExistsException(String message) {
        super(message);
    }

    public EmailAlreadyExistsException(String message, Throwable cause) {
        super(message, cause);
    }
}
