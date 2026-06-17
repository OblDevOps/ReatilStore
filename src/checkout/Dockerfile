FROM node:26-alpine3.24 AS builder
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
RUN node .yarn/releases/yarn-4.11.0.cjs install
COPY . .
RUN node .yarn/releases/yarn-4.11.0.cjs build

FROM node:26-alpine3.24
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json /app/yarn.lock /app/.yarnrc.yml ./
COPY --from=builder /app/.yarn ./.yarn
RUN node .yarn/releases/yarn-4.11.0.cjs workspaces focus --production
EXPOSE 8080
USER node
CMD ["node", "dist/main.js"]
