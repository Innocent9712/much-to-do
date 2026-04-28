# Build stage
FROM golang:1.25 AS builder

WORKDIR /app

COPY . .

WORKDIR /app/Server/MuchToDo

RUN go mod download
RUN go build -o app ./cmd/api

# Run stage
FROM debian:bookworm-slim

WORKDIR /app
COPY --from=builder /app/Server/MuchToDo/app .

EXPOSE 8080

CMD ["./app"]