
FROM golang:1.25.5-alpine AS builder

WORKDIR /build

COPY Server/go.mod Server/go.sum ./
RUN go mod download

COPY Server/MuchToDo/ ./

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/api/main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates wget curl

WORKDIR /app

COPY --from=builder /build/main .
COPY --from=builder /build/docs ./docs

EXPOSE 8080

CMD ["./main"]
