#!/usr/bin/env bash
set -euo pipefail

if [[ "${__FILE_SOURCED:-}" == "1" ]]; then
  return 0
fi
__FILE_SOURCED=1


source "${SCRIPT_DIR}/main.sh"

cat > docker-compose.yaml <<EOF
services:
    app:
        image: ${DOCKER_USERNAME}/${PACKAGE_NAME}:${PACKAGE_VERSION}
        container_name: ${PACKAGE_NAME}
        profiles:
            - prod
        platform: linux/amd64
        build:
            context: .
            dockerfile: Dockerfile
            labels:
                - "app=${PACKAGE_NAME}"
                - "version=${PACKAGE_VERSION}"
        ports:
            - "${PORT}:${PORT}"
        env_file:
            - .env
        environment:
            - NODE_ENV=production
            - PORT=${PORT}
        depends_on:
            postgres:
                condition: service_healthy
            redis:
                condition: service_healthy
        restart: unless-stopped
        entrypoint: ["./entrypoint.sh"]
        networks:
            - ${PACKAGE_NAME}-network

    psotgres:
        image: postgres:16-alpine
        container_name: ${PACKAGE_NAME}-db
        profiles:
            - dev
            - prod
        environment:
            - POSTGRES_USER=${POSTGRES_USER}
            - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
            - POSTGRES_DB=${POSTGRES_DB}
            - PGDATA=/var/lib/postgresql/data/pgdata
        ports:
            - "5432:5432"
        volumes:
            - postgres_data:/var/lib/postgresql/data
        healthcheck:
            test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
            interval: 10s
            timeout: 5s
            retries: 5
        command:
            - "postgres"
            - "-c"
            - "max_connections=200"
            - "-c"
            - "shared_buffers=156MB"
            - "-c"
            - "effective_cache_size=1GB"

        restart: unless-stopped
        networks:
            - ${PACKAGE_NAME}-network


    redis:
        image: redis:7-alpine
        container_name: redis
        profiles:
            - dev
            - prod
        command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
        volumes:
            - redis_data:/var/lib/redis/data
        healthcheck:
            test: ["CMD", "redis-cli", "ping"]
            interval: 10s
            timeout: 3s
            retries: 5
            start_period: 5s
        restart: unless-stopped
        networks:
            - ${PACKAGE_NAME}-network

    caddy:
        image: caddy:latest
        profiles:
            - prod
        container_name: caddy_server
        ports:
            - "80:80"
            - "443:443"
            - "443:443/udp" # HTTP/3 support
        volumes:
            - ./Caddyfile:/etc/caddy/Caddyfile:ro
            - caddy_data:/data
            - caddy_config:/config
        depends_on:
            - app
        restart: always
        networks:
            - ${PACKAGE_NAME}-network

volumes:
    caddy_data:
    caddy_config:
    postgres_data:
        driver: local
     redis_data:
        driver: local

networks:
    ${PACKAGE_NAME}-network:
        driver: bridge
EOF
