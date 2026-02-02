#!/bin/bash

echo "🧪 User Management Service - Comprehensive User Testing"
echo "======================================================"

echo ""
echo "🔍 1. Checking Current State:"
echo "-----------------------------"

echo "Users in Keycloak database:"
docker exec user-management-postgres psql -U postgres -d user_management_db -c "SELECT r.name as realm, u.username, u.email FROM user_entity u JOIN realm r ON u.realm_id = r.id WHERE r.name IN ('visionboard', 'visionboard-backend') ORDER BY r.name, u.username;"

echo ""
echo "Users in Application database:"
docker exec user-management-postgres psql -U postgres -d user_management_db -c "SELECT user_id, email, account_status FROM users;"

echo ""
echo "🔑 2. Testing Token Generation:"
echo "------------------------------"

TOKEN_RESPONSE=$(curl -s -X POST http://localhost:8090/realms/visionboard-backend/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=backend-client" \
  -d "username=user1" \
  -d "password=password")

if echo "$TOKEN_RESPONSE" | grep -q "access_token"; then
  echo "✅ Token generation successful"
  TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
  echo "Token length: ${#TOKEN} characters"
else
  echo "❌ Token generation failed:"
  echo "$TOKEN_RESPONSE"
fi

echo ""
echo "🚀 3. Testing User Registration API:"
echo "-----------------------------------"

REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8081/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "apitest@example.com",
    "firstName": "API",
    "lastName": "Test",
    "preferences": {
      "theme": "dark",
      "notifications": true
    }
  }')

echo "Registration response:"
echo "$REGISTER_RESPONSE"

echo ""
echo "🔍 4. Checking Final State:"
echo "---------------------------"

echo "Users in Application database after API test:"
docker exec user-management-postgres psql -U postgres -d user_management_db -c "SELECT user_id, email, account_status FROM users;"

echo ""
echo "✅ Testing Complete!"