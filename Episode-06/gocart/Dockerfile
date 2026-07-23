# ============================================
# Multi-stage Dockerfile for GoCart (Next.js E-Commerce)
# Stage 1: Install dependencies
# Stage 2: Build the app
# Stage 3: Production (minimal, standalone)
# ============================================

# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Generate Prisma client (safe even if not used at runtime)
RUN npx prisma generate 2>/dev/null || true
ENV NEXT_TELEMETRY_DISABLED=1
# Create public folder if it doesn't exist (Next.js expects it)
RUN mkdir -p public
RUN npm run build

# Stage 3: Production (minimal)
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Copy standalone server + static assets
COPY --from=builder --chown=appuser:appgroup /app/.next/standalone ./
COPY --from=builder --chown=appuser:appgroup /app/.next/static ./.next/static
COPY --from=builder --chown=appuser:appgroup /app/public ./public

USER appuser
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
