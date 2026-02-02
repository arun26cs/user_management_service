package com.visionboard.usermanagement.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration properties for Keycloak integration.
 * Binds to keycloak.* properties in application.yml.
 */
@Configuration
@ConfigurationProperties(prefix = "keycloak")
@Getter
@Setter
public class KeycloakProperties {

    private String url;
    private String realm;
    private Admin admin;
    private Web web;

    @Getter
    @Setter
    public static class Admin {
        private String clientId;
        private String clientSecret;
    }

    @Getter
    @Setter
    public static class Web {
        private String clientId;
    }
}
