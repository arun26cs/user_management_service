package com.visionboard.usermanagement.repository;

import com.visionboard.usermanagement.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Repository for User entity.
 * Provides database access methods for user operations.
 */
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    /**
     * Check if a user exists with the given email (case-insensitive).
     *
     * @param email the email to check
     * @return true if user exists, false otherwise
     */
    @Query("SELECT CASE WHEN COUNT(u) > 0 THEN true ELSE false END FROM User u WHERE LOWER(u.email) = LOWER(:email)")
    boolean existsByEmailIgnoreCase(@Param("email") String email);

    /**
     * Find a user by email (case-insensitive).
     *
     * @param email the email to search for
     * @return Optional containing the user if found
     */
    @Query("SELECT u FROM User u LEFT JOIN FETCH u.profile WHERE LOWER(u.email) = LOWER(:email)")
    Optional<User> findByEmailIgnoreCase(@Param("email") String email);

    /**
     * Find a user by user ID with profile eagerly loaded.
     *
     * @param userId the user ID
     * @return Optional containing the user if found
     */
    @Query("SELECT u FROM User u LEFT JOIN FETCH u.profile WHERE u.userId = :userId")
    Optional<User> findByUserIdWithProfile(@Param("userId") UUID userId);
}
