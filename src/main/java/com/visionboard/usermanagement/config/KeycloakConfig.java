package com.visionboard.usermanagement.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.KeycloakBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for Keycloak Admin API client.
 * Creates a Keycloak client bean for admin operations.
 */
@Configuration
@RequiredArgsConstructor
@Slf4j
public class KeycloakConfig {

    private final KeycloakProperties keycloakProperties;

    /**
     * Create Keycloak Admin API client bean.
     * Uses service account (client credentials) for authentication.
     */
    @Bean
    public Keycloak keycloakAdminClient() {
        log.info("Initializing Keycloak Admin API client for realm: {}", keycloakProperties.getRealm());

        return KeycloakBuilder.builder()
                .serverUrl(keycloakProperties.getUrl())
                .realm(keycloakProperties.getRealm())
                .grantType("client_credentials")
                .clientId(keycloakProperties.getAdmin().getClientId())
                .clientSecret(keycloakProperties.getAdmin().getClientSecret())
                .build();
    }
}
