# -------- BUILD STAGE --------
FROM node:18-alpine AS builder

# Install system dependencies
RUN apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    zlib-dev \
    libpng-dev \
    nasm \
    bash \
    vips-dev \
    git \
    python3

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

# -------- PRODUCTION STAGE --------
FROM node:18-alpine

RUN apk add --no-cache vips-dev

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app ./

RUN npm install --omit=dev

EXPOSE 1337

CMD ["npm", "run", "start"]
