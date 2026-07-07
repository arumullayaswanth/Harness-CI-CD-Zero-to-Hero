# ============================================
# Multi-stage Dockerfile for C++ Application
# Stage 1: Build (large image with compiler)
# Stage 2: Run (tiny image with binary only)
# ============================================

# Stage 1: Build
FROM gcc:13 AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y cmake
COPY CMakeLists.txt .
COPY src/ src/
COPY tests/ tests/
RUN mkdir build && cd build && cmake .. && make

# Stage 2: Run (tiny alpine image)
FROM alpine:latest
RUN apk add --no-cache libstdc++ libgcc
WORKDIR /app
COPY --from=builder /app/build/app .
EXPOSE 8080
CMD ["./app"]
