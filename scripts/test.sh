#!/bin/bash

# Test script for User Management Service
# Usage: ./scripts/test.sh [OPTIONS]
#   -u, --unit         Run unit tests only
#   -i, --integration  Run integration tests only
#   -c, --coverage     Generate test coverage report
#   -w, --watch        Run tests in watch mode
#   -h, --help         Show help

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
UNIT_TESTS=false
INTEGRATION_TESTS=false
COVERAGE=false
WATCH=false
ALL_TESTS=true

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
Test script for User Management Service

Usage: ./scripts/test.sh [OPTIONS]

OPTIONS:
    -u, --unit         Run unit tests only
    -i, --integration  Run integration tests only  
    -c, --coverage     Generate test coverage report
    -w, --watch        Run tests in watch mode
    -h, --help         Show this help message

EXAMPLES:
    ./scripts/test.sh                   # Run all tests
    ./scripts/test.sh -u                # Run unit tests only
    ./scripts/test.sh -i                # Run integration tests only
    ./scripts/test.sh -c                # Run all tests with coverage
    ./scripts/test.sh -u -c             # Run unit tests with coverage

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--unit)
            UNIT_TESTS=true
            ALL_TESTS=false
            shift
            ;;
        -i|--integration)
            INTEGRATION_TESTS=true
            ALL_TESTS=false
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -w|--watch)
            WATCH=true
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

print_status "Running tests for ${PROJECT_NAME}"

# Check if Docker is available for integration tests
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_warning "Docker is not running. Integration tests may fail."
        print_status "Please start Docker for TestContainers to work properly."
        return 1
    fi
    return 0
}

# Function to run unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    
    if [[ "$COVERAGE" == true ]]; then
        mvn test jacoco:report
        print_status "Unit test coverage report generated in target/site/jacoco/"
    else
        mvn test
    fi
}

# Function to run integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    # Check Docker availability
    if ! check_docker; then
        print_error "Docker is required for integration tests"
        exit 1
    fi
    
    if [[ "$COVERAGE" == true ]]; then
        mvn verify jacoco:report
        print_status "Integration test coverage report generated in target/site/jacoco/"
    else
        mvn verify -DskipUTs=true
    fi
}

# Function to run all tests
run_all_tests() {
    print_status "Running all tests (unit + integration)..."
    
    # Check Docker availability for integration tests
    check_docker || print_warning "Integration tests may fail without Docker"
    
    if [[ "$COVERAGE" == true ]]; then
        mvn verify jacoco:report
        print_status "Test coverage report generated in target/site/jacoco/"
        print_status "Open target/site/jacoco/index.html in browser to view coverage"
    else
        mvn verify
    fi
}

# Function to run tests in watch mode
run_watch_mode() {
    print_status "Running tests in watch mode..."
    print_status "Tests will re-run automatically when files change"
    print_status "Press Ctrl+C to stop"
    
    # Use mvn with continuous testing
    mvn test -Dspring.profiles.active=test -Dspring.jpa.hibernate.ddl-auto=create-drop \
        -Dmaven.test.failure.ignore=true \
        -Dmaven.test.skip=false \
        -Dmaven.failsafe.debug=true
}

# Execute tests based on options
if [[ "$WATCH" == true ]]; then
    run_watch_mode
elif [[ "$UNIT_TESTS" == true ]] && [[ "$INTEGRATION_TESTS" == true ]]; then
    run_all_tests
elif [[ "$UNIT_TESTS" == true ]]; then
    run_unit_tests
elif [[ "$INTEGRATION_TESTS" == true ]]; then
    run_integration_tests
elif [[ "$ALL_TESTS" == true ]]; then
    run_all_tests
fi

# Show test results summary
if [[ -f "target/surefire-reports/TEST-*.xml" ]] || [[ -f "target/failsafe-reports/TEST-*.xml" ]]; then
    print_status "Test execution completed!"
    
    # Count test results
    UNIT_TESTS_RUN=$(find target/surefire-reports -name "TEST-*.xml" -exec grep -l "testcase" {} \; 2>/dev/null | wc -l || echo "0")
    INTEGRATION_TESTS_RUN=$(find target/failsafe-reports -name "TEST-*.xml" -exec grep -l "testcase" {} \; 2>/dev/null | wc -l || echo "0")
    
    print_status "Summary:"
    print_status "  - Unit test classes: ${UNIT_TESTS_RUN}"
    print_status "  - Integration test classes: ${INTEGRATION_TESTS_RUN}"
    
    if [[ "$COVERAGE" == true ]]; then
        print_status "  - Coverage report: target/site/jacoco/index.html"
    fi
    
    # Show next steps
    echo
    print_status "Next steps:"
    echo "  - View detailed results: target/surefire-reports/ and target/failsafe-reports/"
    echo "  - Run specific test: mvn test -Dtest=YourTestClass"
    echo "  - Debug tests: mvn test -Dmaven.surefire.debug"
    
else
    print_warning "No test results found. Tests may not have run successfully."
fi