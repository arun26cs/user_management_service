#!/bin/bash

# Complete Testing Guide for User Management Service
# This script provides step-by-step testing procedures

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
}

print_step() {
    echo -e "${GREEN}[STEP $1]${NC} $2"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=${3:-30}
    local attempt=1

    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready! ✅"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    print_error "$service_name is not responding after $((max_attempts * 2)) seconds"
    return 1
}

# Check if Docker is running
check_docker() {
    print_step "1" "Checking Docker status"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        return 1
    fi
    
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop."
        return 1
    fi
    
    print_success "Docker is running ✅"
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        print_status "Using docker-compose command"
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        print_status "Using docker compose plugin"
        COMPOSE_CMD="docker compose"
    else
        print_error "Docker Compose is not available!"
        return 1
    fi
    
    return 0
}

# Validate environment configuration
validate_environment() {
    print_step "2" "Validating environment configuration"
    
    if [[ ! -f ".env" ]]; then
        print_error ".env file not found!"
        print_status "Creating .env from template..."
        cp .env.example .env
        print_warning "Please update secrets in .env file before proceeding!"
        return 1
    fi
    
    # Run environment validation
    if ./scripts/env-manager.sh validate; then
        print_success "Environment configuration is valid ✅"
    else
        print_error "Environment configuration has issues!"
        return 1
    fi
    
    return 0
}

# Start infrastructure services
start_infrastructure() {
    print_step "3" "Starting infrastructure services"
    
    print_status "Starting PostgreSQL and Keycloak..."
    $COMPOSE_CMD up -d postgres keycloak
    
    print_status "Waiting for PostgreSQL to be ready..."
    wait_for_service "http://localhost:5433" "PostgreSQL connection check" 15 || {
        # Alternative check for PostgreSQL
        local attempt=1
        while [ $attempt -le 15 ]; do
            if $COMPOSE_CMD exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
                print_success "PostgreSQL is ready! ✅"
                break
            fi
            echo -n "."
            sleep 2
            ((attempt++))
        done
        
        if [ $attempt -gt 15 ]; then
            print_error "PostgreSQL failed to start!"
            return 1
        fi
    }
    
    print_status "Waiting for Keycloak to be ready..."
    wait_for_service "http://localhost:8090/health/ready" "Keycloak" 60
    
    return $?
}

# Verify infrastructure
verify_infrastructure() {
    print_step "4" "Verifying infrastructure services"
    
    # Check PostgreSQL
    print_status "Testing PostgreSQL connection..."
    if $COMPOSE_CMD exec -T postgres psql -U postgres -d user_management_db -c "SELECT 1;" > /dev/null 2>&1; then
        print_success "PostgreSQL connection successful ✅"
    else
        print_error "PostgreSQL connection failed!"
        return 1
    fi
    
    # Check Keycloak
    print_status "Testing Keycloak accessibility..."
    if curl -f -s "http://localhost:8090/realms/visionboard" > /dev/null; then
        print_success "Keycloak realm is accessible ✅"
    else
        print_warning "Keycloak realm not found - may need manual setup"
    fi
    
    # Check Keycloak admin console
    print_status "Testing Keycloak admin console..."
    if curl -f -s "http://localhost:8090/admin" > /dev/null; then
        print_success "Keycloak admin console is accessible ✅"
        print_status "Admin console: http://localhost:8090/admin (admin/admin)"
    else
        print_warning "Keycloak admin console accessibility check failed"
    fi
    
    return 0
}

# Build and start the application
start_application() {
    print_step "5" "Building and starting the application"
    
    print_status "Building the application..."
    if mvn clean package -DskipTests -q; then
        print_success "Application build successful ✅"
    else
        print_error "Application build failed!"
        return 1
    fi
    
    print_status "Starting user-management-service..."
    $COMPOSE_CMD up -d user-management-service
    
    print_status "Waiting for application to be ready..."
    wait_for_service "http://localhost:8081/actuator/health" "User Management Service" 45
    
    return $?
}

# Verify application
verify_application() {
    print_step "6" "Verifying application health"
    
    # Health check
    print_status "Testing application health endpoint..."
    local health_response=$(curl -s "http://localhost:8081/actuator/health")
    if echo "$health_response" | grep -q '"status":"UP"'; then
        print_success "Application health check passed ✅"
        echo "$health_response" | jq . 2>/dev/null || echo "$health_response"
    else
        print_error "Application health check failed!"
        echo "Response: $health_response"
        return 1
    fi
    
    # Check application info
    print_status "Testing application info endpoint..."
    if curl -f -s "http://localhost:8081/actuator/info" > /dev/null; then
        print_success "Application info endpoint accessible ✅"
    else
        print_warning "Application info endpoint not accessible"
    fi
    
    return 0
}

# Run API tests
run_api_tests() {
    print_step "7" "Running API tests"
    
    print_status "Testing user registration endpoint..."
    
    # Test data
    local test_email="test-$(date +%s)@example.com"
    local registration_payload='{
        "email": "'$test_email'",
        "password": "TestPass123!",
        "firstName": "Test",
        "lastName": "User"
    }'
    
    # Test user registration
    print_status "1. Testing POST /users/register"
    local reg_response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$registration_payload" \
        "http://localhost:8081/users/register")
    
    local reg_http_code="${reg_response: -3}"
    local reg_body="${reg_response%???}"
    
    if [[ "$reg_http_code" == "201" ]]; then
        print_success "User registration successful ✅ (HTTP $reg_http_code)"
        echo "$reg_body" | jq . 2>/dev/null || echo "$reg_body"
        
        # Extract user ID for further tests
        local user_id=$(echo "$reg_body" | jq -r '.userId' 2>/dev/null)
        print_status "Created user ID: $user_id"
    else
        print_error "User registration failed! (HTTP $reg_http_code)"
        echo "Response: $reg_body"
        return 1
    fi
    
    # Test authentication
    print_status "2. Testing POST /auth/token"
    local auth_payload="grant_type=password&username=$test_email&password=TestPass123!&client_id=visionboard-web"
    
    local auth_response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$auth_payload" \
        "http://localhost:8081/auth/token")
    
    local auth_http_code="${auth_response: -3}"
    local auth_body="${auth_response%???}"
    
    if [[ "$auth_http_code" == "200" ]]; then
        print_success "User authentication successful ✅ (HTTP $auth_http_code)"
        
        # Extract access token
        local access_token=$(echo "$auth_body" | jq -r '.access_token' 2>/dev/null)
        if [[ "$access_token" != "null" ]] && [[ -n "$access_token" ]]; then
            print_status "Access token obtained successfully"
            
            # Test profile endpoint
            print_status "3. Testing GET /users/me"
            local profile_response=$(curl -s -w "%{http_code}" \
                -H "Authorization: Bearer $access_token" \
                "http://localhost:8081/users/me")
            
            local profile_http_code="${profile_response: -3}"
            local profile_body="${profile_response%???}"
            
            if [[ "$profile_http_code" == "200" ]]; then
                print_success "User profile retrieval successful ✅ (HTTP $profile_http_code)"
                echo "$profile_body" | jq . 2>/dev/null || echo "$profile_body"
            else
                print_error "User profile retrieval failed! (HTTP $profile_http_code)"
                echo "Response: $profile_body"
            fi
        else
            print_warning "Could not extract access token from response"
        fi
    else
        print_error "User authentication failed! (HTTP $auth_http_code)"
        echo "Response: $auth_body"
    fi
    
    return 0
}

# Run unit tests
run_unit_tests() {
    print_step "8" "Running unit tests"
    
    print_status "Executing Maven unit tests..."
    if mvn test -q; then
        print_success "Unit tests passed ✅"
    else
        print_error "Unit tests failed!"
        return 1
    fi
    
    return 0
}

# Run integration tests
run_integration_tests() {
    print_step "9" "Running integration tests"
    
    print_status "Executing Maven integration tests..."
    if mvn verify -DskipUTs=false -q; then
        print_success "Integration tests passed ✅"
    else
        print_error "Integration tests failed!"
        return 1
    fi
    
    return 0
}

# Show service URLs and next steps
show_summary() {
    print_header "TESTING COMPLETE - SERVICE URLS"
    
    echo -e "${GREEN}✅ Services are running:${NC}"
    echo "  • User Management Service: http://localhost:8081"
    echo "  • Health Check: http://localhost:8081/actuator/health"
    echo "  • Keycloak Admin: http://localhost:8090/admin (admin/admin)"
    echo "  • PostgreSQL: localhost:5433 (postgres/postgres)"
    echo
    
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "  • View logs: $COMPOSE_CMD logs -f user-management-service"
    echo "  • Stop services: $COMPOSE_CMD down"
    echo "  • View API documentation in README.md"
    echo "  • Run specific tests: ./scripts/test.sh"
    echo
    
    echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
    echo "  • Check logs if services fail: $COMPOSE_CMD logs <service-name>"
    echo "  • Restart services: $COMPOSE_CMD restart"
    echo "  • Clean restart: $COMPOSE_CMD down && $COMPOSE_CMD up -d"
    echo
}

# Main execution
main() {
    print_header "USER MANAGEMENT SERVICE - COMPLETE TESTING PROCEDURE"
    
    # Pre-flight checks
    check_docker || exit 1
    validate_environment || exit 1
    
    # Infrastructure setup
    start_infrastructure || exit 1
    verify_infrastructure || exit 1
    
    # Application setup
    start_application || exit 1
    verify_application || exit 1
    
    # API testing
    run_api_tests || print_warning "API tests had issues"
    
    # Automated tests
    if [[ "${1:-}" == "--with-tests" ]]; then
        run_unit_tests || print_warning "Unit tests failed"
        run_integration_tests || print_warning "Integration tests failed"
    else
        print_status "Skipping automated tests (use --with-tests to include them)"
    fi
    
    # Summary
    show_summary
    
    print_success "🎉 Testing procedure completed successfully!"
}

# Show help
show_help() {
    cat << EOF
Complete Testing Guide for User Management Service

Usage: $0 [OPTIONS]

OPTIONS:
    --with-tests    Include unit and integration tests
    --help         Show this help message

This script will:
1. Check Docker status
2. Validate environment configuration
3. Start PostgreSQL and Keycloak
4. Verify infrastructure services
5. Build and start the application
6. Verify application health
7. Run API endpoint tests
8. Optionally run unit and integration tests

Examples:
    $0                  # Basic testing (infrastructure + API)
    $0 --with-tests     # Complete testing including unit/integration tests

EOF
}

# Parse arguments
case "${1:-}" in
    --help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac