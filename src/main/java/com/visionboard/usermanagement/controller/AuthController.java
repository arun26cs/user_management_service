package com.visionboard.usermanagement.controller;

import com.visionboard.usermanagement.config.KeycloakProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

/**
 * REST controller for authentication endpoints.
 * Proxies OAuth2 token requests to Keycloak.
 */
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final KeycloakProperties keycloakProperties;
    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * OAuth2 token endpoint (login).
     * 
     * POST /auth/token
     * 
     * Proxies the request to Keycloak token endpoint.
     * 
     * @param requestBody form data with grant_type, username, password, client_id
     * @return OAuth2 token response from Keycloak
     */
    @PostMapping(value = "/token", consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE)
    public ResponseEntity<Map<String, Object>> token(@RequestParam Map<String, String> requestBody) {

        log.info("Token request received for username: {}", requestBody.get("username"));

        try {
            // Build Keycloak token endpoint URL
            String keycloakTokenUrl = String.format(
                    "%s/realms/%s/protocol/openid-connect/token",
                    keycloakProperties.getUrl(),
                    keycloakProperties.getRealm());

            // Prepare form data
            MultiValueMap<String, String> formData = new LinkedMultiValueMap<>();
            formData.add("grant_type", requestBody.get("grant_type"));
            formData.add("username", requestBody.get("username"));
            formData.add("password", requestBody.get("password"));
            formData.add("client_id", requestBody.get("client_id"));

            // Add scope if provided
            if (requestBody.containsKey("scope")) {
                formData.add("scope", requestBody.get("scope"));
            }

            // Prepare headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(formData, headers);

            // Proxy request to Keycloak
            ResponseEntity<Map> keycloakResponse = restTemplate.exchange(
                    keycloakTokenUrl,
                    HttpMethod.POST,
                    request,
                    Map.class);

            log.info("Token issued successfully for username: {}", requestBody.get("username"));

            // Return Keycloak response
            return ResponseEntity.status(keycloakResponse.getStatusCode())
                    .body((Map<String, Object>) keycloakResponse.getBody());

        } catch (Exception e) {
            log.error("Error during token request: {}", e.getMessage(), e);

            // Return error response
            Map<String, Object> errorResponse = Map.of(
                    "error", "invalid_grant",
                    "error_description", "Invalid user credentials");

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }
    }
}
