FROM node:26.12.1-alpine AS ui-builder

RUN mkdir /app \
    && npm install --global --allow-scripts=pnpm pnpm@12.16.1

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml /app/

RUN apk add --update --no-cache g++ make git \
    && pnpm install --frozen-lockfile \
    && apk del g++ make

COPY . /app

RUN pnpm run build

FROM nginx:1.31.7-alpine
COPY  --from=ui-builder /app/dist /etc/nginx/html
COPY  --from=ui-builder /app/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx"]
