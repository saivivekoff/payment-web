# syntax=docker/dockerfile:1

# ============================================================
# Stage 1: Build — compile TypeScript and bundle with Vite
# ============================================================
FROM node:22-alpine AS builder

WORKDIR /app

# Copy dependency manifests first so this layer is cached
# unless package.json / package-lock.json actually change
COPY package.json package-lock.json ./

# Clean, reproducible install strictly from the lockfile
RUN npm ci

# Copy the rest of the source and build (tsc -b && vite build -> dist/)
COPY . .
RUN npm run build

# ============================================================
# Stage 2: Runtime — serve static files only
# ============================================================
FROM node:22-alpine AS runner

WORKDIR /app

# Static file server; version pinned for reproducible builds
RUN npm install -g serve@14

# Only the built assets make it into the final image
COPY --from=builder /app/dist ./dist

# Drop root privileges (the 'node' user ships with the base image)
USER node

EXPOSE 3000

CMD ["serve", "-s", "dist", "-l", "3000"]
