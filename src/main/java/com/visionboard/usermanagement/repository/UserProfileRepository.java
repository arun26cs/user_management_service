package com.visionboard.usermanagement.repository;

import com.visionboard.usermanagement.domain.UserProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Repository for UserProfile entity.
 * Provides database access methods for user profile operations.
 */
@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, UUID> {

    /**
     * Find a user profile by user ID.
     *
     * @param userId the user ID
     * @return Optional containing the profile if found
     */
    Optional<UserProfile> findByUser_UserId(UUID userId);
}
