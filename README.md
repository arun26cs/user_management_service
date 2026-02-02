# User Management Service

A standalone microservice for user registration, authentication, and profile management in the Vision Board application.

## Overview

This service provides:
- User registration with email validation
- OAuth2 authentication via Keycloak integration
- User profile management
- JWT token validation and security

## Technology Stack

- **Framework:** Spring Boot 3.2.1
- **Language:** Java 17
- **Database:** PostgreSQL 15
- **Authentication:** Keycloak (OAuth2/OIDC)
- **Build Tool:** Maven
- **Containerization:** Docker

## API Endpoints

| Method | Endpoint | Description | Authentication |
|--------|----------|-------------|----------------|
| POST | `/users/register` | Register new user | Public |
| POST | `/auth/token` | Login/Get token | Public |
| GET | `/users/me` | Get user profile | Bearer Token |
| GET | `/actuator/health` | Health check | Public |

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Java 17+ (for local development)
- Maven 3.8+ (for local development)

### Run with Docker Compose
```bash
# Clone repository
git clone <repository-url>
cd user-management-service

# Start all services
docker-compose up -d

# Service will be available at http://localhost:8081
```

### Local Development Setup
```bash
# Start dependencies only
docker-compose up -d postgres keycloak

# Wait for services to be ready (check logs)
docker-compose logs -f keycloak

# Run application locally
./scripts/setup-local.sh
mvn spring-boot:run

# Or use your IDE to run UserManagementApplication.java
```

### Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit configuration (especially update secrets)
nano .env

# Important: Update these values in .env:
# - KEYCLOAK_CLIENT_SECRET
# - DB_PASSWORD (for production)
# - KEYCLOAK_ADMIN_PASSWORD (for production)
```

## Testing

### Quick Testing (Automated)
```bash
# Complete automated test procedure
./scripts/complete-test.sh

# With unit and integration tests
./scripts/complete-test.sh --with-tests
```

### Manual Testing
```bash
# Run unit tests
./scripts/test.sh -u

# Run integration tests
./scripts/test.sh -i

# Run all tests with coverage
./scripts/test.sh -c
```

### Step-by-Step Testing Guide
For detailed testing procedures, see [TESTING_GUIDE.md](TESTING_GUIDE.md) which includes:
- Infrastructure setup verification
- Service health checks
- API endpoint testing
- Troubleshooting guides

## Building

```bash
# Build JAR
mvn clean package

# Build Docker image
docker build -t user-management-service:latest .

# Or use the build script
./scripts/build.sh
```

## Configuration

### Environment Variables

The service uses environment variables for configuration. Copy `.env.example` to `.env` and update values:

```bash
cp .env.example .env
```

**Key configuration variables:**

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DB_HOST` | PostgreSQL host | `localhost` | Yes |
| `DB_PORT` | PostgreSQL port | `5433` | Yes |
| `DB_NAME` | Database name | `user_management_db` | Yes |
| `DB_USER` | Database username | `postgres` | Yes |
| `DB_PASSWORD` | Database password | `postgres` | Yes |
| `KEYCLOAK_URL` | Keycloak server URL | `http://localhost:8090` | Yes |
| `KEYCLOAK_REALM` | Keycloak realm | `visionboard` | Yes |
| `KEYCLOAK_CLIENT_ID` | Keycloak client ID | `visionboard-backend` | Yes |
| `KEYCLOAK_CLIENT_SECRET` | Keycloak client secret | - | **Yes** |
| `KEYCLOAK_ADMIN` | Keycloak admin username | `admin` | Yes |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password | `admin` | Yes |

**⚠️ Security Note:** Always update default passwords and secrets, especially for production!

## Health Checks

- **Application Health:** `GET /actuator/health`
- **Database:** Automatic health check via HikariCP
- **Keycloak:** JWT validation endpoint connectivity

## API Documentation

### Register User
```bash
curl -X POST http://localhost:8081/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

### Login
```bash
curl -X POST http://localhost:8081/auth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'grant_type=password&username=user@example.com&password=SecurePass123!&client_id=visionboard-web'
```

### Get Profile
```bash
curl -X GET http://localhost:8081/users/me \
  -H "Authorization: Bearer <jwt-token>"
```

## Deployment

### Docker
```bash
docker run -p 8081:8081 \
  -e DB_HOST=postgres \
  -e KEYCLOAK_URL=http://keycloak:8080 \
  -e KEYCLOAK_CLIENT_SECRET=your-secret \
  user-management-service:latest
```

### Kubernetes
```bash
kubectl apply -f k8s/
```

## Development

### Code Structure
```
src/main/java/com/visionboard/usermanagement/
├── controller/          # REST controllers
├── service/            # Business logic
├── domain/             # JPA entities
├── repository/         # Data access
├── dto/                # Data transfer objects
├── exception/          # Exception handling
└── config/             # Configuration classes
```

### Adding New Features
1. Create feature branch: `git checkout -b feature/new-feature`
2. Implement changes following existing patterns
3. Add tests for new functionality
4. Update API documentation
5. Submit pull request

## Monitoring and Logging

- **Logs:** Structured logging with correlation IDs
- **Metrics:** Spring Boot Actuator metrics
- **Health Checks:** Built-in health indicators
- **Tracing:** Ready for distributed tracing integration

## Security

- **Authentication:** OAuth2/OIDC via Keycloak
- **Authorization:** JWT token validation
- **CORS:** Configured for allowed origins
- **Security Headers:** Standard security headers applied
- **Input Validation:** Bean validation on all inputs
- **SQL Injection:** Prevention via JPA/Hibernate

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

This project is licensed under the MIT License.