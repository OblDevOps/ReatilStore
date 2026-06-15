FROM node:26-alpine3.24 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig*.json ./
COPY src ./src
RUN npm run build

FROM node:26-alpine3.24
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev
ENV PORT=8080
EXPOSE 8080
USER node
CMD ["node", "dist/app.js"]
