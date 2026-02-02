FROM amazoncorretto:17-alpine

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -S appuser && adduser -S -G appuser appuser

# Copy Maven build artifact
COPY target/user-management-service.jar app.jar

# Set ownership
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8081/actuator/health || exit 1

# JVM optimization for containers
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport -XX:+OptimizeStringConcat -XX:+UseG1GC"

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]