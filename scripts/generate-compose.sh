#!/usr/bin/env bash
set -euo pipefail

cat > Dockerfile <<EOF
services:
    app_live:
        image: ${DOCKER_USERNAME}/${PACKAGE_NAME}:${PACKAGE_VERSION}
        container_name: ${PACKAGE_NAME}_live
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
            db:
                condition: service_healthy
            redis:
                condition: service_healthy
        restart: unless-stopped
        healthcheck:
            test: ["CMD", "curl", "-f", "http://localhost:${PORT}/api/health"]
            interval: 10s
            timeout: 5s
            retries: 5
            start_period: 30s
        networks:
            - backend
        labels:
            - "app=${PACKAGE_NAME}"
            - "container_type=live"
        stop_grace_period: 30s
        logging:
            driver: "json-file"
            options:
                max-size: "10m"
                max-file: "3"

    app_candidate:
        image: ${DOCKER_USERNAME}/${PACKAGE_NAME}:${PACKAGE_VERSION}
        container_name: ${PACKAGE_NAME}_candidate
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
            - "${PORT}"
        env_file:
            - .env
        environment:
            - NODE_ENV=production
            - PORT=${PORT}
        depends_on:
            db:
                condition: service_healthy
            redis:
                condition: service_healthy
        restart: "no"
        healthcheck:
            test: ["CMD", "curl", "-f", "http://localhost:${PORT}/api/health"]
            interval: 10s
            timeout: 5s
            retries: 5
            start_period: 30s
        networks:
            - backend
        labels:
            - "app=${PACKAGE_NAME}"
            - "container_type=candidate"
        stop_grace_period: 30s
        logging:
            driver: "json-file"
            options:
                max-size: "10m"
                max-file: "3"

    db:
        image: postgres:17-alpine
        container_name: ${PACKAGE_NAME}_db
        profiles:
            - dev
            - prod
        environment:
            - POSTGRES_USER=postgres
            - POSTGRES_PASSWORD=postgres
            - POSTGRES_DB=mydb
            - POSTGRES_INITDB_ARGS="-E UTF8 --locale=C"
            - PGDATA=/var/lib/postgresql/data/pgdata
        ports:
            - "5432:5432"
        volumes:
            - pg:/var/lib/postgresql/data
        healthcheck:
            test: ["CMD-SHELL", "pg_isready -U postgres -d mydb"]
            interval: 10s
            timeout: 5s
            retries: 5
            start_period: 20s
        restart: unless-stopped
        networks:
            - backend
        shm_size: 256mb
        logging:
            driver: "json-file"
            options:
                max-size: "10m"
                max-file: "3"

    redis:
        image: redis:7-alpine
        container_name: ${PACKAGE_NAME}_redis
        profiles:
            - dev
            - prod
        command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
        volumes:
            - redis:/data
        healthcheck:
            test: ["CMD", "redis-cli", "ping"]
            interval: 10s
            timeout: 3s
            retries: 5
            start_period: 5s
        restart: unless-stopped
        networks:
            - backend
        logging:
            driver: "json-file"
            options:
                max-size: "10m"
                max-file: "3"

    caddy:
        image: caddy:2-alpine
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
            app_live:
                condition: service_healthy
        restart: unless-stopped
        networks:
            - backend
        logging:
            driver: "json-file"
            options:
                max-size: "10m"
                max-file: "3"
        healthcheck:
            test:
                [
                    "CMD",
                    "wget",
                    "--no-verbose",
                    "--tries=1",
                    "--spider",
                    "http://localhost:2019/metrics",
                ]
            interval: 30s
            timeout: 10s
            retries: 3
            start_period: 10s

volumes:
    pg:
        driver: local
        labels:
            - "app=${PACKAGE_NAME}"
    redis:
        driver: local
        labels:
            - "app=${PACKAGE_NAME}"
    caddy_data:
        driver: local
        labels:
            - "app=${PACKAGE_NAME}"
    caddy_config:
        driver: local
        labels:
            - "app=${PACKAGE_NAME}"

networks:
    backend:
        driver: bridge
        labels:
            - "app=${PACKAGE_NAME}"
EOF