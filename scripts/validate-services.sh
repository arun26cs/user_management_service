#!/bin/bash

# Quick service validation script
# Usage: ./scripts/validate-services.sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[CHECK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if service is responding
check_service() {
    local url=$1
    local service_name=$2
    local expected_pattern=$3
    
    print_status "Checking $service_name..."
    
    local response=$(curl -s "$url" 2>/dev/null || echo "ERROR")
    
    if [[ "$response" == "ERROR" ]]; then
        print_error "$service_name is not responding at $url"
        return 1
    elif [[ -n "$expected_pattern" ]] && ! echo "$response" | grep -q "$expected_pattern"; then
        print_warning "$service_name is responding but may not be healthy"
        echo "Response: $response"
        return 1
    else
        echo -e "${GREEN}✅ $service_name is healthy${NC}"
        return 0
    fi
}

echo "🔍 Validating User Management Service Environment"
echo "================================================"

# Check Docker services
print_status "Checking Docker services..."
if docker compose ps --format json | jq -e '.[] | select(.Health == "healthy" or .State == "running")' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker services are running${NC}"
    docker compose ps
else
    print_error "Docker services are not running properly"
    echo "Run: docker compose up -d"
    exit 1
fi

echo
echo "🌐 Validating Service Endpoints"
echo "================================"

# Check PostgreSQL (indirect through application)
check_service "http://localhost:8081/actuator/health" "Application Health" '"status":"UP"'

# Check Keycloak
check_service "http://localhost:8090/health/ready" "Keycloak Health" '"status":"UP"'

# Check Keycloak realm
check_service "http://localhost:8090/realms/visionboard" "Keycloak Realm" "visionboard"

echo
echo "🔗 Service URLs"
echo "==============="
echo "• User Management: http://localhost:8081"
echo "• Health Check: http://localhost:8081/actuator/health"
echo "• Keycloak Admin: http://localhost:8090/admin"
echo "• Database: localhost:5433 (postgres/postgres)"

echo
echo "🚀 Ready for API Testing!"
echo "========================="
echo "Run: ./scripts/complete-test.sh"