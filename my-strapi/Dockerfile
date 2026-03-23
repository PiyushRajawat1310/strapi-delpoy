# -------- BUILD STAGE --------
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

# -------- PRODUCTION STAGE --------
FROM node:18-alpine

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app ./

RUN npm install --omit=dev

EXPOSE 1337

CMD ["npm", "run", "start"]
