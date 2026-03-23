FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then npm install -g pnpm && pnpm install --frozen-lockfile; \
  else npm install; \
  fi

# Copy Strapi source
COPY . .

# Build Strapi for production
RUN NODE_ENV=production npm run build || NODE_ENV=production yarn build

FROM node:18-alpine

ENV NODE_ENV=production
WORKDIR /app

# Copy built app
COPY --from=builder /app ./

EXPOSE 1337

# Strapi default start command
CMD ["npm", "run", "start"]
