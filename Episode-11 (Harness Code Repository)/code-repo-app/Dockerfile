# Multi-stage build — small final image, non-root user
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .

FROM node:20-alpine
WORKDIR /app
# Run as non-root (security best practice)
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app .
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "app.js"]
