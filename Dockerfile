# Build local monorepo image
# docker build --no-cache -t  flowise .

# Run image
# docker run -d -p 3000:3000 flowise

FROM node:20-alpine

# Install system dependencies and build tools
RUN apk update && \
    apk add --no-cache \
        libc6-compat \
        python3 \
        make \
        g++ \
        build-base \
        cairo-dev \
        pango-dev \
        chromium \
        curl && \
    npm install -g pnpm

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Increase Node heap size to prevent OOM during build
ENV NODE_OPTIONS="--max-old-space-size=6144"

WORKDIR /usr/src/flowise

# Copy all source files
COPY . .

# Install dependencies
RUN pnpm install

# Build with limited concurrency and increased memory
RUN pnpm build --concurrency=1

# Create data directories with proper permissions
RUN mkdir -p /var/data/flowise/logs && \
    chown -R node:node /var/data/flowise

# Give the node user ownership of the application files
RUN chown -R node:node .

# Switch to non-root user (node user already exists in node:20-alpine)
USER node

EXPOSE 3000

CMD [ "pnpm", "start" ]