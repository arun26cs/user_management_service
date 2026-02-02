package com.visionboard.usermanagement.service;

import com.visionboard.usermanagement.domain.User;
import com.visionboard.usermanagement.domain.UserProfile;
import com.visionboard.usermanagement.dto.UserRegistrationRequest;
import com.visionboard.usermanagement.dto.UserRegistrationResponse;
import com.visionboard.usermanagement.exception.EmailAlreadyExistsException;
import com.visionboard.usermanagement.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for UserService.
 */
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private KeycloakAdminService keycloakAdminService;

    @InjectMocks
    private UserService userService;

    private UserRegistrationRequest validRequest;
    private UUID testUserId;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();

        validRequest = UserRegistrationRequest.builder()
                .email("test@example.com")
                .password("SecureP@ss123")
                .firstName("Test")
                .lastName("User")
                .build();
    }

    @Test
    void testRegisterUser_ValidData_Success() {
        // Arrange
        when(userRepository.existsByEmailIgnoreCase(anyString())).thenReturn(false);
        when(keycloakAdminService.createUser(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(testUserId);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            return user;
        });

        // Act
        UserRegistrationResponse response = userService.registerUser(validRequest);

        // Assert
        assertNotNull(response);
        assertEquals(testUserId, response.getUserId());
        assertEquals("test@example.com", response.getEmail());
        assertEquals("Test", response.getFirstName());
        assertEquals("User", response.getLastName());
        assertEquals("Registration successful! You can now log in.", response.getMessage());

        // Verify interactions
        verify(userRepository).existsByEmailIgnoreCase("test@example.com");
        verify(keycloakAdminService).createUser("test@example.com", "SecureP@ss123", "Test", "User");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void testRegisterUser_DuplicateEmail_ThrowsException() {
        // Arrange
        when(userRepository.existsByEmailIgnoreCase("test@example.com")).thenReturn(true);

        // Act & Assert
        EmailAlreadyExistsException exception = assertThrows(
                EmailAlreadyExistsException.class,
                () -> userService.registerUser(validRequest));

        assertEquals("An account with this email already exists", exception.getMessage());

        // Verify Keycloak was never called
        verify(keycloakAdminService, never()).createUser(anyString(), anyString(), anyString(), anyString());
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void testRegisterUser_EmailCaseInsensitive() {
        // Arrange
        UserRegistrationRequest upperCaseRequest = UserRegistrationRequest.builder()
                .email("TEST@EXAMPLE.COM")
                .password("SecureP@ss123")
                .firstName("Test")
                .lastName("User")
                .build();

        when(userRepository.existsByEmailIgnoreCase(anyString())).thenReturn(false);
        when(keycloakAdminService.createUser(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(testUserId);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        UserRegistrationResponse response = userService.registerUser(upperCaseRequest);

        // Assert
        assertNotNull(response);
        assertEquals("TEST@EXAMPLE.COM", response.getEmail());

        // Verify email was checked case-insensitively
        verify(userRepository).existsByEmailIgnoreCase("TEST@EXAMPLE.COM");
    }
}
