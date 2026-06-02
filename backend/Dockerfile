# Stage 1: Build the Go application
FROM golang:alpine AS builder

# Install CA certificates for external calls if needed
RUN apk --no-cache add ca-certificates

# Set the working directory
WORKDIR /app

# Copy go mod and sum files
COPY go.mod ./
# RUN go mod download # Un-comment if you have a go.sum file

# Copy the source code
COPY . .
RUN cp .env.example .env

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o muchtodo ./cmd/api

# Stage 2: Create a minimal runtime image
FROM alpine:latest

# Add non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install CA certificates and curl for health check
RUN apk --no-cache add ca-certificates curl

# Set working directory
WORKDIR /app

# Copy the binary and .env from the builder stage
COPY --from=builder /app/muchtodo .
COPY --from=builder /app/.env .

# Change ownership of the binary to the non-root user
RUN chown appuser:appgroup muchtodo

# Use the non-root user
USER appuser

# Expose the port
EXPOSE 8080

# Configure Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the binary
CMD ["./muchtodo"]
