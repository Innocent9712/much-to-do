# ============================================
# STAGE 1: Build the Go binary
# ============================================
# We use a specific Go version on Alpine (lightweight Linux)
FROM golang:1.26-alpine AS builder

# Install git and ca-certificates (needed for fetching Go modules)
RUN apk add --no-cache git ca-certificates

# Set working directory inside the container
WORKDIR /app

# Copy only dependency files first (for caching)
COPY go.mod go.sum ./

# Download dependencies. This layer gets cached unless go.mod/go.sum change
RUN go mod download

# Install swag CLI tool to dynamically generate swagger docs at build-time
RUN go install github.com/swaggo/swag/cmd/swag@v1.16.6

# Copy the rest of the application source code
COPY . .

# Generate Swagger API documentation before building
RUN swag init -g ./cmd/api/main.go -o ./docs

# Build the binary: static binary for Linux, no CGO
# Using BuildKit cache mounts to speed up compilation
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build -v -ldflags="-w -s" -o much-to-do ./cmd/api/main.go

# ============================================
# STAGE 2: Create the runtime image with shell
# ============================================
# Use Alpine instead of distroless so we have /bin/sh to build MONGO_URI
FROM alpine:3.21

# Set working directory
WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /app/much-to-do .

# Copy swagger docs only if they exist in the builder stage
# This prevents build failure if docs were not generated
RUN if [ -d "/app/docs" ]; then cp -r /app/docs ./docs; fi

# Create non-root user (security best practice)
RUN adduser -D -u 65532 appuser

# Declare build-time arguments for all application environment variables
ARG PORT
ARG MONGO_URI
ARG DB_NAME
ARG JWT_SECRET_KEY
ARG JWT_EXPIRATION_HOURS
ARG ENABLE_CACHE
ARG REDIS_ADDR
ARG REDIS_PASSWORD
ARG LOG_LEVEL
ARG LOG_FORMAT

# Set environment variables inside the container from build arguments with fallback defaults
ENV PORT=${PORT:-8080}
ENV MONGO_URI=${MONGO_URI}
ENV DB_NAME=${DB_NAME:-much_todo_db}
ENV JWT_SECRET_KEY=${JWT_SECRET_KEY}
ENV JWT_EXPIRATION_HOURS=${JWT_EXPIRATION_HOURS:-72}
ENV ENABLE_CACHE=${ENABLE_CACHE:-true}
ENV REDIS_ADDR=${REDIS_ADDR}
ENV REDIS_PASSWORD=${REDIS_PASSWORD}
ENV LOG_LEVEL=${LOG_LEVEL:-INFO}
ENV LOG_FORMAT=${LOG_FORMAT:-json}

USER appuser

# Expose the port your app listens on
EXPOSE 8080

# Health check: use wget since Alpine has it (distroless didn't)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# Start the application
ENTRYPOINT ["/app/much-to-do"]