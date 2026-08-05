FROM node:20-slim

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci --ignore-scripts 2>/dev/null || npm install --ignore-scripts

# Copy source
COPY . .

# Build
RUN npx tsc && node scripts/copy-assets.mjs 2>/dev/null || true

# Environment defaults
ENV PORT=16384
ENV NODE_ENV=production

# Expose the single port (bridge + MCP)
EXPOSE 16384

# Start in HTTP mode
CMD ["node", "dist/index.js", "--http"]
