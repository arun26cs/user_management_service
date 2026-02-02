# User Management Service - Step-by-Step Testing Guide

This guide provides a comprehensive, step-by-step procedure to test your user-management-service from infrastructure setup to API testing.

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Docker Desktop installed and running
- ✅ Java 17+ installed
- ✅ Maven 3.8+ installed
- ✅ curl command available
- ✅ jq installed (optional, for pretty JSON output)

## 🚀 Quick Start (Automated)

For a complete automated test, run:
```bash
# Basic testing (infrastructure + API)
./scripts/complete-test.sh

# Complete testing (includes unit/integration tests)
./scripts/complete-test.sh --with-tests
```

## 📝 Manual Step-by-Step Testing

### Step 1: Pre-flight Checks

#### 1.1 Check Docker Status
```bash
# Verify Docker is running
docker --version
docker info

# Check Docker Compose
docker compose version
# OR
docker-compose --version
```

#### 1.2 Validate Environment Configuration
```bash
# Check if .env file exists
ls -la .env

# If not, create from template
cp .env.example .env

# Validate environment
./scripts/env-manager.sh validate

# Show current configuration
./scripts/env-manager.sh show
```

**Expected Output:**
```
[INFO] ✅ Environment configuration is valid
```

### Step 2: Start Infrastructure Services

#### 2.1 Start PostgreSQL and Keycloak
```bash
# Start infrastructure services
docker compose up -d postgres keycloak

# Check service status
docker compose ps
```

**Expected Output:**
```
NAME                      IMAGE                     STATUS
user-management-postgres  postgres:15               Up (healthy)
user-management-keycloak  quay.io/keycloak/keycloak:23.0  Up (healthy)
```

#### 2.2 Wait for Services to be Ready
```bash
# Wait for PostgreSQL (may take 30-60 seconds)
docker compose logs -f postgres

# Wait for Keycloak (may take 2-3 minutes)
docker compose logs -f keycloak
```

**Look for these success messages:**
- PostgreSQL: `database system is ready to accept connections`
- Keycloak: `Keycloak 23.0.3 on JVM ... started`

### Step 3: Verify Infrastructure

#### 3.1 Test PostgreSQL Connection
```bash
# Test database connection
docker compose exec postgres psql -U postgres -d user_management_db -c "SELECT 1;"

# Check database tables (should show Flyway schema_version table)
docker compose exec postgres psql -U postgres -d user_management_db -c "\dt"
```

**Expected Output:**
```
 ?column? 
----------
        1
```

#### 3.2 Test Keycloak Accessibility
```bash
# Test Keycloak health endpoint
curl -f http://localhost:8090/health/ready

# Test Keycloak realm (may return 404 if realm not imported yet)
curl -f http://localhost:8090/realms/visionboard
```

**Expected Output:**
```json
{"status":"UP","checks":[...]}
```

### Step 4: Build and Start Application

#### 4.1 Build the Application
```bash
# Clean build
mvn clean package -DskipTests

# Verify JAR was created
ls -la target/user-management-service.jar
```

#### 4.2 Start the Application
```bash
# Start user management service
docker compose up -d user-management-service

# Watch application startup logs
docker compose logs -f user-management-service
```

**Look for success indicators:**
- `Started UserManagementApplication in X.XXX seconds`
- No ERROR messages in logs
- Healthy status in `docker compose ps`

### Step 5: Verify Application Health

#### 5.1 Health Check
```bash
# Test application health endpoint
curl -s http://localhost:8081/actuator/health | jq .

# Test application info
curl -s http://localhost:8081/actuator/info | jq .
```

**Expected Output:**
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP"
    }
  }
}
```

#### 5.2 Check All Services Status
```bash
# Verify all services are running
docker compose ps

# Check service logs for any errors
docker compose logs --tail=50 user-management-service
docker compose logs --tail=50 postgres
docker compose logs --tail=50 keycloak
```

### Step 6: API Endpoint Testing

#### 6.1 Test User Registration
```bash
# Create test user
curl -X POST http://localhost:8081/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!",
    "firstName": "Test",
    "lastName": "User"
  }' | jq .
```

**Expected Output (HTTP 201):**
```json
{
  "userId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "email": "test@example.com",
  "firstName": "Test",
  "lastName": "User",
  "createdAt": "2026-01-31T...",
  "message": "Registration successful! You can now log in."
}
```

#### 6.2 Test User Authentication
```bash
# Login and get token
curl -X POST http://localhost:8081/auth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'grant_type=password&username=test@example.com&password=TestPass123!&client_id=visionboard-web' | jq .
```

**Expected Output (HTTP 200):**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 900,
  "refresh_expires_in": 1800,
  "token_type": "Bearer",
  "scope": "email profile"
}
```

#### 6.3 Test User Profile Retrieval
```bash
# Use the access_token from previous step
ACCESS_TOKEN="your-access-token-here"

curl -X GET http://localhost:8081/users/me \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
```

**Expected Output (HTTP 200):**
```json
{
  "userId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "email": "test@example.com",
  "firstName": "Test",
  "lastName": "User",
  "createdAt": "2026-01-31T..."
}
```

### Step 7: Run Automated Tests

#### 7.1 Unit Tests
```bash
# Run unit tests only
./scripts/test.sh -u

# Or with Maven directly
mvn test
```

#### 7.2 Integration Tests
```bash
# Run integration tests only
./scripts/test.sh -i

# Or with Maven directly
mvn verify
```

#### 7.3 All Tests with Coverage
```bash
# Run all tests with coverage
./scripts/test.sh -c

# View coverage report
open target/site/jacoco/index.html
```

### Step 8: Verify Complete System

#### 8.1 Service URLs Summary
After successful testing, these endpoints should be accessible:

| Service | URL | Credentials |
|---------|-----|-------------|
| **User Management API** | http://localhost:8081 | N/A |
| **Health Check** | http://localhost:8081/actuator/health | N/A |
| **Keycloak Admin Console** | http://localhost:8090/admin | admin/admin |
| **PostgreSQL** | localhost:5433 | postgres/postgres |

#### 8.2 Test Error Scenarios
```bash
# Test invalid registration (should return 400)
curl -X POST http://localhost:8081/users/register \
  -H "Content-Type: application/json" \
  -d '{"email": "invalid-email"}' -v

# Test unauthorized access (should return 401)
curl -X GET http://localhost:8081/users/me -v

# Test duplicate registration (should return 409)
curl -X POST http://localhost:8081/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!",
    "firstName": "Test",
    "lastName": "User"
  }' -v
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: Docker Services Not Starting
```bash
# Check Docker is running
docker info

# Check port conflicts
lsof -i :8081 -i :8090 -i :5433

# Restart Docker services
docker compose down
docker compose up -d
```

#### Issue 2: Application Not Connecting to Database
```bash
# Check database logs
docker compose logs postgres

# Test database connectivity
docker compose exec postgres pg_isready -U postgres

# Restart services in order
docker compose restart postgres
docker compose restart user-management-service
```

#### Issue 3: Keycloak Realm Not Found
```bash
# Check Keycloak logs
docker compose logs keycloak

# Import realm manually (if needed)
docker compose exec keycloak /opt/keycloak/bin/kc.sh import \
  --file=/opt/keycloak/data/import/visionboard-realm.json
```

#### Issue 4: API Tests Failing
```bash
# Check application logs
docker compose logs user-management-service

# Verify environment variables
docker compose exec user-management-service env | grep -E "DB_|KEYCLOAK_"

# Test health endpoint first
curl -v http://localhost:8081/actuator/health
```

## 🧹 Cleanup

### Stop Services
```bash
# Stop all services
docker compose down

# Stop and remove volumes (complete cleanup)
docker compose down -v

# Remove unused Docker resources
docker system prune -f
```

## 📊 Success Criteria

Your testing is successful when:

✅ **Infrastructure:**
- Docker services start without errors
- PostgreSQL accepts connections
- Keycloak admin console accessible

✅ **Application:**
- Health check returns `"status": "UP"`
- No ERROR logs in application startup
- All endpoints respond correctly

✅ **API Functionality:**
- User registration works (HTTP 201)
- User authentication works (HTTP 200 with token)
- Profile retrieval works (HTTP 200 with user data)
- Error scenarios return appropriate status codes

✅ **Tests:**
- Unit tests pass
- Integration tests pass
- No critical security vulnerabilities

## 🎯 Next Steps

After successful testing:
1. **Create Git repository** for the service
2. **Set up CI/CD pipeline** using GitHub Actions
3. **Deploy to staging environment**
4. **Create additional microservices** (todo-service, etc.)
5. **Set up API Gateway** for service routing

---

**🎉 Congratulations! Your user-management-service is now fully tested and ready for production!**