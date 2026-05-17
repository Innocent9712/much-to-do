# ──────────────────────────────────────────
# Stage 1: Build
# ──────────────────────────────────────────
FROM golang:1.25-alpine AS builder

# Install git (needed for go mod download in some cases)
# RUN apk add --no-cache git

WORKDIR /app

# Copy dependency files first (layer caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build a static binary (no CGO = smaller, portable)
RUN CGO_ENABLED=0 GOOS=linux go build -o muchtodo ./cmd/api/

# ──────────────────────────────────────────
# Stage 2: Final runtime image
# ──────────────────────────────────────────
FROM alpine:3.19

# Security: don't run as root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only the compiled binary from builder
COPY --from=builder /app/muchtodo .
COPY .env . 

# Give ownership to non-root user
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

# Health check using wget (available in alpine)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["./muchtodo"]