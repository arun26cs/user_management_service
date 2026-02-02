package com.visionboard.usermanagement.dto;

import lombok.*;

import java.time.Instant;
import java.util.List;

/**
 * Standard error response DTO.
 * Used for all error responses across the API.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ErrorResponse {

    private ErrorDetail error;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ErrorDetail {
        private String code;
        private String message;
        private Instant timestamp;
        private List<FieldError> details;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class FieldError {
        private String field;
        private String message;
    }

    /**
     * Create a simple error response without field details.
     */
    public static ErrorResponse of(String code, String message) {
        return ErrorResponse.builder()
                .error(ErrorDetail.builder()
                        .code(code)
                        .message(message)
                        .timestamp(Instant.now())
                        .build())
                .build();
    }

    /**
     * Create an error response with field validation details.
     */
    public static ErrorResponse of(String code, String message, List<FieldError> details) {
        return ErrorResponse.builder()
                .error(ErrorDetail.builder()
                        .code(code)
                        .message(message)
                        .timestamp(Instant.now())
                        .details(details)
                        .build())
                .build();
    }
}
