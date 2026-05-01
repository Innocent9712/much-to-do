# ---------- Build Stage ----------
FROM golang:1.25.1-alpine AS builder

WORKDIR /app

# Install only what is needed for downloading Go modules
RUN apk add --no-cache git ca-certificates

# Copy dependency files first for better Docker caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the application code
COPY . .

# Build the Go application from cmd/api
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o muchtodo ./cmd/api


# ---------- Runtime Stage ----------
FROM alpine:3.20

WORKDIR /app

# Install certificates and wget for healthcheck, then create non-root user
RUN apk add --no-cache ca-certificates wget \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

# Copy only the compiled binary from the build stage
COPY --from=builder /app/muchtodo /app/muchtodo

# Give ownership to non-root user
RUN chown -R appuser:appgroup /app

# Run container as non-root user
USER appuser

# Application runs on port 8080
EXPOSE 8080

# Health check endpoint required by the assessment
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Start the application
CMD ["/app/muchtodo"]