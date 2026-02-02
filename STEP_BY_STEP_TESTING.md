# 🧪 User Management Service - Step-by-Step Testing Guide

## 🎯 Overview
This guide walks you through testing your User Management Service, including Keycloak user management and API testing.

## 📋 Prerequisites
- All services running: `docker compose up -d`
- Services healthy: PostgreSQL (5433), Keycloak (8090), Spring Boot (8081)

## 🔐 Step 1: Access Keycloak Admin Console

### Access Information:
- **URL**: http://localhost:8090/admin
- **Username**: admin
- **Password**: admin

### Navigate to Users:
1. Login to Keycloak Admin Console
2. Select **"visionboard"** realm (dropdown top-left)
3. Click **"Users"** in the left sidebar
4. Initially, you'll see an empty users list

### User Management Actions:
- **View all users**: Users → View all users
- **Add user**: Click "Add user" button
- **Search users**: Use the search functionality
- **User details**: Click on username to see profile, credentials, roles

## 🚀 Step 2: Test API Endpoints

### Health Check (No Auth Required)
```bash
curl -s http://localhost:8081/actuator/health
```
**Expected**: `{"status":"UP"}`

### User Profile (Auth Required)
```bash
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:8081/api/auth/profile
```
**Expected**: HTTP 401 (Unauthorized) - This confirms security is working

## 🔑 Step 3: Get Keycloak Access Token

### Method 1: Direct Token Request
```bash
curl -X POST http://localhost:8090/realms/visionboard/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=visionboard-backend" \
  -d "client_secret=yFok18tb3mjlSGj5drkbTSZhyeIxH7rJ"
```

### Method 2: Create a Test User in Keycloak Admin Console
1. In Keycloak Admin → Users → Add user
2. Set username: `testuser`
3. Set email: `test@example.com`
4. Save user
5. Go to **Credentials** tab
6. Set password: `testpass123` (temporary: off)
7. Save

### Get User Token:
```bash
curl -X POST http://localhost:8090/realms/visionboard/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=visionboard-web" \
  -d "username=testuser" \
  -d "password=testpass123"
```

## 📝 Step 4: Test User Registration API

### Register New User:
```bash
curl -X POST http://localhost:8081/api/users/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "email": "newuser@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "preferences": {
      "theme": "dark",
      "notifications": true
    }
  }'
```

## 🔍 Step 5: Verify User in Keycloak

After successful registration:
1. Go to Keycloak Admin Console
2. Navigate to Users
3. Search for the email address
4. Verify the user appears in both:
   - Keycloak Users list
   - Your application database

## 🗄️ Step 6: Check Database Records

### PostgreSQL Connection:
```bash
docker exec -it user-management-postgres psql -U postgres -d user_management_db
```

### Query Users:
```sql
SELECT * FROM users;
SELECT * FROM user_profiles;
```

## 🧪 Step 7: Full API Testing

### Test All Endpoints:
```bash
# Health Check
curl http://localhost:8081/actuator/health

# User Profile (with auth)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8081/api/auth/profile

# Update Profile
curl -X PUT http://localhost:8081/api/users/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Updated",
    "lastName": "Name",
    "preferences": {"theme": "light"}
  }'

# Get User Info
curl -H "Authorization: Bearer $TOKEN" http://localhost:8081/api/auth/user-info
```

## 🐛 Troubleshooting

### Common Issues:

1. **401 Unauthorized**: Normal for protected endpoints without token
2. **500 Internal Error**: Check application logs
   ```bash
   docker logs user-management-service --tail 50
   ```
3. **Connection Refused**: Service not running
   ```bash
   docker compose ps
   docker compose logs <service-name>
   ```

### Reset Everything:
```bash
docker compose down
docker volume rm user-management-service_postgres_data
docker compose up -d
```

## 📊 Expected Test Results

### ✅ Success Indicators:
- Health endpoint returns `{"status":"UP"}`
- Keycloak admin console accessible
- User registration creates users in both Keycloak and database
- Protected endpoints return 401 without auth
- Protected endpoints work with valid tokens

### ❌ Failure Indicators:
- Services not starting
- 500 errors on registration
- Users not appearing in Keycloak
- Database connection failures

## 🎯 Next Steps

After successful testing:
1. Document API endpoints
2. Create automated tests
3. Set up monitoring
4. Deploy to staging environment
5. Implement additional features (email verification, etc.)