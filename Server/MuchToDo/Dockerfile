# ============================================
# Stage 1: Build Stage
# ============================================
FROM golang:1.23-alpine AS builder

# Enable toolchain auto-download for newer Go versions if required by dependencies
ENV GOTOOLCHAIN=auto

# Install necessary build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set the working directory
WORKDIR /app

# Copy the source code
COPY . .

# Download dependencies and build the application
# CGO_ENABLED=0 for static binary
# -ldflags="-w -s" to reduce binary size
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/muchtodo \
    ./cmd/api/main.go

# ============================================
# Stage 2: Production Stage
# ============================================
FROM alpine:3.19

# Install ca-certificates for HTTPS and tzdata for timezone support
RUN apk --no-cache add ca-certificates tzdata

# Create a non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set the working directory
WORKDIR /app

# Copy the binary from the build stage
COPY --from=builder /app/muchtodo .

# Copy swagger docs if they exist
COPY --from=builder /app/docs ./docs

# Copy the entrypoint script
COPY docker-entrypoint.sh .

# Change ownership and make entrypoint executable
RUN chmod +x docker-entrypoint.sh && \
    chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 8080

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Set environment variables
ENV PORT=8080
ENV GIN_MODE=release

# Run the application using entrypoint script
ENTRYPOINT ["./docker-entrypoint.sh"]
