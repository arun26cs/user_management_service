#!/bin/bash

# Setup script for local development environment
# Usage: ./scripts/setup-local.sh [OPTIONS]
#   -f, --full     Full setup including dependencies
#   -q, --quick    Quick setup (assumes dependencies exist)
#   -h, --help     Show help

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="user-management-service"

# Default options
FULL_SETUP=false
QUICK_SETUP=false

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Function to show help
show_help() {
    cat << EOF
Setup script for User Management Service local development

Usage: ./scripts/setup-local.sh [OPTIONS]

OPTIONS:
    -f, --full     Full setup including Docker containers
    -q, --quick    Quick setup (assumes containers are running)
    -h, --help     Show this help message

EXAMPLES:
    ./scripts/setup-local.sh           # Interactive setup
    ./scripts/setup-local.sh -f        # Full automated setup
    ./scripts/setup-local.sh -q        # Quick setup

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--full)
            FULL_SETUP=true
            shift
            ;;
        -q|--quick)
            QUICK_SETUP=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

print_status "Setting up ${PROJECT_NAME} for local development"

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Java
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')
        print_status "Java version: ${JAVA_VERSION}"
        
        # Check if Java 17+
        JAVA_MAJOR=$(echo $JAVA_VERSION | cut -d'.' -f1)
        if [[ "$JAVA_MAJOR" -lt 17 ]]; then
            print_error "Java 17+ is required. Current version: ${JAVA_VERSION}"
            exit 1
        fi
    else
        print_error "Java is not installed. Please install Java 17+ and try again."
        exit 1
    fi
    
    # Check Maven
    if command -v mvn &> /dev/null; then
        MVN_VERSION=$(mvn -version | head -n1 | awk '{print $3}')
        print_status "Maven version: ${MVN_VERSION}"
    else
        print_error "Maven is not installed. Please install Maven 3.8+ and try again."
        exit 1
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_status "Docker version: ${DOCKER_VERSION}"
        
        if ! docker info > /dev/null 2>&1; then
            print_warning "Docker is installed but not running"
        fi
    else
        print_warning "Docker is not installed. Some features may not work."
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
        print_status "Docker Compose version: ${COMPOSE_VERSION}"
    else
        print_warning "Docker Compose is not installed. Using docker compose instead."
    fi
}

# Function to setup environment file
setup_environment() {
    print_status "Setting up environment configuration..."
    
    if [[ ! -f ".env" ]]; then
        # Copy from template
        cp .env.example .env
        print_status "Created .env file from template"
        print_warning "Please review and update the values in .env file, especially:"
        print_warning "  - KEYCLOAK_CLIENT_SECRET"
        print_warning "  - DB_PASSWORD (for production)"
        print_warning "  - KEYCLOAK_ADMIN_PASSWORD (for production)"
    else
        print_status ".env file already exists"
        
        # Check if important secrets are still default values
        if grep -q "your-secret-here" .env; then
            print_warning "⚠️  Default secrets detected in .env file!"
            print_warning "Please update KEYCLOAK_CLIENT_SECRET in .env file"
        fi
        
        if grep -q "dev-secret-change-for-production" .env; then
            print_warning "⚠️  Development secrets detected!"
            print_warning "Update secrets before deploying to production"
        fi
    fi
}

# Function to start dependencies
start_dependencies() {
    print_status "Starting PostgreSQL and Keycloak containers..."
    
    # Start only dependencies (not the application)
    docker-compose up -d postgres keycloak
    
    print_status "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    print_status "Waiting for PostgreSQL to be ready..."
    timeout 60 bash -c 'until docker-compose exec postgres pg_isready -U postgres; do sleep 2; done'
    
    # Wait for Keycloak
    print_status "Waiting for Keycloak to be ready..."
    timeout 120 bash -c 'until curl -f http://localhost:8090/health/ready > /dev/null 2>&1; do sleep 5; done'
    
    print_status "Dependencies are ready!"
}

# Function to setup database
setup_database() {
    print_status "Setting up database..."
    
    # Run Flyway migrations
    mvn flyway:migrate -Dflyway.url=jdbc:postgresql://localhost:5433/user_management_db \
                       -Dflyway.user=postgres \
                       -Dflyway.password=postgres
                       
    print_status "Database schema setup completed"
}

# Function to setup Keycloak
setup_keycloak() {
    print_status "Setting up Keycloak configuration..."
    
    # Check if realm already exists
    if curl -f http://localhost:8090/realms/visionboard > /dev/null 2>&1; then
        print_status "Keycloak realm already exists"
    else
        print_warning "Keycloak realm 'visionboard' not found"
        print_status "Please import the realm configuration manually or check the docker-compose setup"
    fi
}

# Function to verify setup
verify_setup() {
    print_status "Verifying setup..."
    
    # Check if dependencies are running
    if docker-compose ps | grep -q "postgres.*Up"; then
        print_status "✓ PostgreSQL is running"
    else
        print_error "✗ PostgreSQL is not running"
    fi
    
    if docker-compose ps | grep -q "keycloak.*Up"; then
        print_status "✓ Keycloak is running"
    else
        print_error "✗ Keycloak is not running"
    fi
    
    # Test database connection
    if mvn flyway:info -Dflyway.url=jdbc:postgresql://localhost:5433/user_management_db \
                       -Dflyway.user=postgres \
                       -Dflyway.password=postgres > /dev/null 2>&1; then
        print_status "✓ Database connection successful"
    else
        print_error "✗ Database connection failed"
    fi
    
    # Test Keycloak endpoint
    if curl -f http://localhost:8090/health/ready > /dev/null 2>&1; then
        print_status "✓ Keycloak is accessible"
    else
        print_error "✗ Keycloak is not accessible"
    fi
}

# Main setup process
main() {
    check_prerequisites
    setup_environment
    
    if [[ "$QUICK_SETUP" == true ]]; then
        print_status "Quick setup mode - assuming dependencies are running"
        verify_setup
    elif [[ "$FULL_SETUP" == true ]]; then
        start_dependencies
        setup_database
        setup_keycloak
        verify_setup
    else
        # Interactive mode
        echo
        print_status "Setup options:"
        echo "1. Full setup (start containers + setup database)"
        echo "2. Quick setup (verify existing containers)"
        echo "3. Exit"
        
        read -p "Choose an option [1-3]: " choice
        
        case $choice in
            1)
                start_dependencies
                setup_database
                setup_keycloak
                verify_setup
                ;;
            2)
                verify_setup
                ;;
            3)
                print_status "Setup cancelled"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                exit 1
                ;;
        esac
    fi
    
    # Show next steps
    echo
    print_status "Setup completed! Next steps:"
    echo
    echo "  1. Start the application:"
    echo "     mvn spring-boot:run"
    echo
    echo "  2. Or run in your IDE:"
    echo "     Run UserManagementApplication.java"
    echo
    echo "  3. Test the setup:"
    echo "     curl http://localhost:8081/actuator/health"
    echo
    echo "  4. Access services:"
    echo "     - Application: http://localhost:8081"
    echo "     - Keycloak Admin: http://localhost:8090 (admin/admin)"
    echo "     - PostgreSQL: localhost:5433"
    echo
    echo "  5. Run tests:"
    echo "     ./scripts/test.sh"
    echo
}

# Run main function
main