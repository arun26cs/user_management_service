# Contributing to User Management Service

Thank you for your interest in contributing to the User Management Service! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please be respectful and inclusive in all interactions.

## Getting Started

### Prerequisites

- Java 17+
- Maven 3.8+
- Docker and Docker Compose
- Git
- IDE (IntelliJ IDEA, VS Code, or similar)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd user-management-service
   ```

2. **Set up local environment**
   ```bash
   ./scripts/setup-local.sh -f
   ```

3. **Run the application**
   ```bash
   mvn spring-boot:run
   ```

4. **Verify setup**
   ```bash
   curl http://localhost:8081/actuator/health
   ```

### Project Structure

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

## Development Process

### Branching Strategy

We follow the **GitFlow** branching model:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature branches
- `hotfix/*` - Critical production fixes
- `release/*` - Release preparation

### Feature Development

1. **Create feature branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Develop your feature**
   - Write code following our [coding standards](#coding-standards)
   - Add comprehensive tests
   - Update documentation as needed

3. **Test your changes**
   ```bash
   ./scripts/test.sh
   ./scripts/build.sh -t
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat(auth): add password reset functionality"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### Java Code Style

- **Java 17 features**: Use modern Java features where appropriate
- **Naming**: Use descriptive names for variables, methods, and classes
- **Method length**: Keep methods focused and under 50 lines when possible
- **Class size**: Keep classes focused on a single responsibility
- **Comments**: Use Javadoc for public APIs, inline comments for complex logic

### Code Formatting

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Maximum 120 characters
- **Imports**: Group imports, remove unused imports
- **Braces**: Use Egyptian braces style

### Example Code Style

```java
/**
 * Service for user management operations.
 * Handles user registration and profile retrieval.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UserRepository userRepository;
    private final KeycloakAdminService keycloakAdminService;

    /**
     * Register a new user with email validation.
     *
     * @param request registration request with user details
     * @return registration response with user information
     * @throws EmailAlreadyExistsException if email already exists
     */
    @Transactional
    public UserRegistrationResponse registerUser(UserRegistrationRequest request) {
        log.info("Registering new user: {}", request.getEmail());

        // Validation logic here
        validateEmailUniqueness(request.getEmail());
        
        // Business logic here
        UUID userId = createUserInKeycloak(request);
        User user = saveUserProfile(request, userId);
        
        return buildRegistrationResponse(user);
    }
}
```

### Dependencies

- **Spring Boot**: Follow Spring Boot conventions and best practices
- **Lombok**: Use for reducing boilerplate (getters, setters, builders)
- **Validation**: Use Bean Validation annotations (`@Valid`, `@NotNull`, etc.)
- **Testing**: Use JUnit 5, Mockito, and TestContainers

## Testing Guidelines

### Test Coverage

- **Minimum coverage**: 80% line coverage
- **Unit tests**: Test business logic in isolation
- **Integration tests**: Test complete workflows end-to-end
- **Contract tests**: Test API contracts (future)

### Test Structure

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;
    
    @Mock
    private KeycloakAdminService keycloakAdminService;
    
    @InjectMocks
    private UserService userService;

    @Test
    @DisplayName("Should register user successfully when email is unique")
    void shouldRegisterUserSuccessfully() {
        // Given
        UserRegistrationRequest request = UserRegistrationRequest.builder()
            .email("test@example.com")
            .password("SecurePass123!")
            .firstName("John")
            .lastName("Doe")
            .build();
        
        when(userRepository.existsByEmailIgnoreCase(any())).thenReturn(false);
        when(keycloakAdminService.createUser(any(), any(), any(), any()))
            .thenReturn(UUID.randomUUID());
        
        // When
        UserRegistrationResponse response = userService.registerUser(request);
        
        // Then
        assertThat(response.getEmail()).isEqualTo("test@example.com");
        verify(userRepository).save(any(User.class));
    }
}
```

### Integration Tests

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class UserControllerIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    @Test
    void shouldRegisterUserEndToEnd() {
        // Test implementation
    }
}
```

### Running Tests

```bash
# Run all tests
./scripts/test.sh

# Run unit tests only
./scripts/test.sh -u

# Run integration tests only
./scripts/test.sh -i

# Run with coverage
./scripts/test.sh -c
```

## Commit Message Format

We follow the **Conventional Commits** specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
feat(auth): add password reset functionality
fix(user): resolve email validation bug
docs(api): update registration endpoint documentation
test(service): add user service integration tests
refactor(config): improve security configuration
```

## Pull Request Process

### Before Creating PR

1. **Update your branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout feature/your-feature
   git rebase develop
   ```

2. **Run full test suite**
   ```bash
   ./scripts/test.sh
   ```

3. **Build and verify**
   ```bash
   ./scripts/build.sh -c -t
   ```

### PR Requirements

- [ ] **Tests**: All tests pass
- [ ] **Coverage**: Maintains or improves test coverage
- [ ] **Documentation**: Updates documentation if needed
- [ ] **Code style**: Follows project coding standards
- [ ] **Commits**: Uses conventional commit messages
- [ ] **Description**: Clear description of changes
- [ ] **Breaking changes**: Documents any breaking changes

### PR Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Documentation
- [ ] Code comments updated
- [ ] API documentation updated
- [ ] README updated (if needed)

## Checklist
- [ ] My code follows the project style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

### Review Process

1. **Automated checks**: CI pipeline must pass
2. **Code review**: At least one approval required
3. **Testing**: Feature must be manually tested
4. **Documentation**: Updates must be reviewed

## Release Process

### Version Numbering

We follow **Semantic Versioning** (SemVer):

- `MAJOR.MINOR.PATCH`
- `1.0.0` → `1.0.1` (patch)
- `1.0.1` → `1.1.0` (minor)
- `1.1.0` → `2.0.0` (major)

### Release Steps

1. **Create release branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/v1.1.0
   ```

2. **Update version**
   ```bash
   mvn versions:set -DnewVersion=1.1.0
   ```

3. **Update CHANGELOG**
   - Document all changes since last release
   - Move items from "Unreleased" to version section

4. **Test release**
   ```bash
   ./scripts/test.sh
   ./scripts/build.sh -c -t -d
   ```

5. **Create release PR**
   - Merge release branch to main
   - Tag the release
   - Deploy to production

## Questions or Issues?

- **Bug reports**: Create an issue with detailed reproduction steps
- **Feature requests**: Create an issue with user story format
- **Questions**: Start a discussion or reach out to maintainers

Thank you for contributing to the User Management Service!