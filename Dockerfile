# Stage 1: Build
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git

RUN go install github.com/swaggo/swag/cmd/swag@latest

WORKDIR /app

COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./
RUN go mod download

COPY Server/MuchToDo/ .

RUN swag init -g ./cmd/api/main.go -o ./docs

RUN CGO_ENABLED=0 GOOS=linux go build -o much-to-do ./cmd/api/main.go

# Stage 2: Run
FROM alpine:3.19

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app/much-to-do .

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["./much-to-do"]
