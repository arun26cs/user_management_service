#!/bin/bash

# Environment management script for User Management Service
# Usage: ./scripts/env-manager.sh [command]
#   init        - Initialize environment files
#   validate    - Validate environment configuration
#   show        - Show current environment
#   help        - Show this help

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Initialize environment files
init_env() {
    print_status "Initializing environment configuration..."
    
    # Create .env from template if it doesn't exist
    if [[ ! -f ".env" ]]; then
        cp .env.example .env
        print_status "Created .env file from template"
        print_warning "Please update the following values in .env:"
        echo "  - KEYCLOAK_CLIENT_SECRET"
        echo "  - DB_PASSWORD (for production use)"
        echo "  - KEYCLOAK_ADMIN_PASSWORD (for production use)"
    else
        print_info ".env file already exists"
    fi
    
    # Show available templates
    echo
    print_status "Available environment templates:"
    echo "  .env.example           - Development template"
    echo "  .env.staging.example   - Staging template"
    echo "  .env.production.example - Production template"
    echo
    print_info "Copy the appropriate template for your environment:"
    echo "  cp .env.staging.example .env.staging"
    echo "  cp .env.production.example .env.production"
}

# Validate environment configuration
validate_env() {
    print_status "Validating environment configuration..."
    
    if [[ ! -f ".env" ]]; then
        print_error ".env file not found! Run './scripts/env-manager.sh init' first"
        return 1
    fi
    
    # Source the .env file
    set -a
    source .env
    set +a
    
    # Check required variables
    local errors=0
    
    # Database configuration
    check_var "DB_HOST" && check_var "DB_PORT" && check_var "DB_NAME" && check_var "DB_USER" && check_var "DB_PASSWORD"
    
    # Keycloak configuration
    check_var "KEYCLOAK_URL" && check_var "KEYCLOAK_REALM" && check_var "KEYCLOAK_CLIENT_ID" && check_var "KEYCLOAK_CLIENT_SECRET"
    
    # Check for insecure defaults
    if [[ "$KEYCLOAK_CLIENT_SECRET" == "your-secret-here"* ]] || [[ "$KEYCLOAK_CLIENT_SECRET" == "dev-secret-change-for-production" ]]; then
        print_warning "⚠️  Using default/development Keycloak client secret!"
        ((errors++))
    fi
    
    if [[ "$DB_PASSWORD" == "postgres" ]] && [[ "$SPRING_PROFILES_ACTIVE" != "local" ]]; then
        print_warning "⚠️  Using default database password for non-local environment!"
        ((errors++))
    fi
    
    if [[ "$KEYCLOAK_ADMIN_PASSWORD" == "admin" ]] && [[ "$SPRING_PROFILES_ACTIVE" != "local" ]]; then
        print_warning "⚠️  Using default Keycloak admin password for non-local environment!"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_status "✅ Environment configuration is valid"
    else
        print_warning "⚠️  Environment configuration has $errors warnings"
    fi
}

# Check if variable is set
check_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    if [[ -z "$var_value" ]]; then
        print_error "Required variable $var_name is not set"
        return 1
    else
        print_info "✓ $var_name is set"
        return 0
    fi
}

# Show current environment
show_env() {
    print_status "Current environment configuration:"
    
    if [[ ! -f ".env" ]]; then
        print_error ".env file not found!"
        return 1
    fi
    
    echo
    print_info "Database Configuration:"
    echo "  DB_HOST: $(grep '^DB_HOST=' .env | cut -d'=' -f2)"
    echo "  DB_PORT: $(grep '^DB_PORT=' .env | cut -d'=' -f2)"
    echo "  DB_NAME: $(grep '^DB_NAME=' .env | cut -d'=' -f2)"
    echo "  DB_USER: $(grep '^DB_USER=' .env | cut -d'=' -f2)"
    
    echo
    print_info "Keycloak Configuration:"
    echo "  KEYCLOAK_URL: $(grep '^KEYCLOAK_URL=' .env | cut -d'=' -f2)"
    echo "  KEYCLOAK_REALM: $(grep '^KEYCLOAK_REALM=' .env | cut -d'=' -f2)"
    echo "  KEYCLOAK_CLIENT_ID: $(grep '^KEYCLOAK_CLIENT_ID=' .env | cut -d'=' -f2)"
    
    echo
    print_info "Application Configuration:"
    echo "  SPRING_PROFILES_ACTIVE: $(grep '^SPRING_PROFILES_ACTIVE=' .env | cut -d'=' -f2)"
    echo "  LOGGING_LEVEL_ROOT: $(grep '^LOGGING_LEVEL_ROOT=' .env | cut -d'=' -f2)"
}

# Show help
show_help() {
    cat << EOF
Environment Management Script for User Management Service

Usage: ./scripts/env-manager.sh [command]

Commands:
    init        Initialize environment files from templates
    validate    Validate current environment configuration
    show        Show current environment values (non-sensitive)
    help        Show this help message

Examples:
    ./scripts/env-manager.sh init       # Setup initial environment
    ./scripts/env-manager.sh validate   # Check configuration
    ./scripts/env-manager.sh show      # Display current config

Environment Files:
    .env                    - Active environment (not in git)
    .env.example           - Development template
    .env.staging.example   - Staging template  
    .env.production.example - Production template

EOF
}

# Main script logic
case "${1:-help}" in
    init)
        init_env
        ;;
    validate)
        validate_env
        ;;
    show)
        show_env
        ;;
    help|*)
        show_help
        ;;
esac