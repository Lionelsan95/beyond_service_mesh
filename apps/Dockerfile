ARG GO_VERSION=1.26.0
FROM golang:${GO_VERSION}-alpine3.22 AS build
WORKDIR /src
COPY go.mod ./
COPY internal ./internal
COPY order-service ./order-service
COPY inventory-service ./inventory-service
COPY payment-service ./payment-service
COPY notification-service ./notification-service
ARG SERVICE
RUN test -n "$SERVICE" && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/service ./${SERVICE}

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/service /service
# Kubernetes runAsNonRoot can verify this numeric distroless identity. A named
# user (for example "nonroot") may otherwise fail before the container starts.
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/service"]
