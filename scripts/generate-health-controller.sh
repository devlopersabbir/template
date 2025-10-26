#!/usr/bin/env bash
set -euo pipefail

# Ensure members_json is available
: "${members_json:?members_json is not set}"

cat > src/health.controller.ts <<EOF
import { Controller, Get } from '@nestjs/common';
import appMetadata from "@metadata/app-metadata";
import { Controller, Get, Res } from "@nestjs/common";
import { ApiOkResponse } from "@nestjs/swagger";
import type { Response } from "express";

@Controller()
export class HealthController {
    @ApiOkResponse({
        description: "Returns service health status for monitoring",
        schema: {
            example: {
                status: "healthy",
                timestamp: "2025-05-27T12:00:00.000Z",
                version: "0.3.1",
                uptime: 3600,
            },
        },
    })
    @Get("api/health")
    health(@Res() res: Response) {
        res.status(200).json({
            status: "ok",
            name: appMetadata.displayName,
            version: appMetadata.version,
            description: appMetadata.description,
            environment: process.env.NODE_ENV,
            uptime: process.uptime(),
            timestamp: new Date().toISOString(),
            team: {
                name: "Dev Ninja",
                leader: "Niloy",
                members: [
${members_json}
                ],
            },
        });
    }
}

// Don't forget to add this controller to your app.module.ts!
EOF