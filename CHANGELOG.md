# Changelog

All notable changes to the User Management Service will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial microservice architecture extraction
- Standalone Docker Compose configuration
- Kubernetes deployment manifests
- CI/CD pipelines with GitHub Actions
- Comprehensive operational scripts
- Security scanning and vulnerability checks

### Changed
- Migrated from monolith to independent microservice
- Updated configuration for standalone operation
- Enhanced Docker containerization with security best practices

### Security
- Added OWASP dependency scanning
- Implemented Trivy vulnerability scanning
- Enhanced container security with non-root user
- Added security headers and CORS configuration

## [1.0.0-SNAPSHOT] - 2026-01-30

### Added
- User registration endpoint with validation
- OAuth2 authentication via Keycloak integration
- User profile management
- JWT token validation and security
- PostgreSQL database integration with Flyway migrations
- Spring Boot Actuator for health checks and metrics
- Comprehensive error handling and validation
- Docker and Docker Compose support
- Integration and unit test coverage
- API documentation and examples

### Features
- **User Registration**: Email-based registration with password validation
- **Authentication**: OAuth2/OIDC integration with Keycloak
- **Profile Management**: User profile retrieval and management
- **Security**: JWT token validation, CORS, and input validation
- **Database**: PostgreSQL with automatic schema migrations
- **Monitoring**: Health checks, metrics, and logging
- **Testing**: Unit and integration tests with TestContainers

### API Endpoints
- `POST /users/register` - User registration
- `POST /auth/token` - Authentication and token retrieval
- `GET /users/me` - Get current user profile
- `GET /actuator/health` - Health check

### Technical Stack
- Java 17
- Spring Boot 3.2.1
- Spring Security with OAuth2
- PostgreSQL 15
- Keycloak 23.0
- Maven 3.8+
- Docker and Docker Compose

### Database Schema
- `users` table: Core user account information
- `user_profiles` table: Extended user profile data
- `sessions` table: Session management (future use)

### Security Features
- Password complexity validation
- Email format validation
- JWT token validation
- CORS configuration
- Security headers
- SQL injection prevention
- Input sanitization