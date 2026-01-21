import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { PrismaPg } from "@prisma/adapter-pg";
import { Prisma, PrismaClient } from "@prisma/client/extension";
import { PrismaClientOptions } from "@prisma/client/runtime/client";
import "dotenv/config";

@Injectable()
export class PrismaService
    extends PrismaClient<PrismaClientOptions, "query" | "error">
    implements OnModuleInit, OnModuleDestroy
{
    private readonly logger = new Logger(PrismaService.name);
    // * Expose Prisma utils (enums, filters, etc.)
    readonly utils = Prisma;

    constructor() {
        const connectionString = process.env.DATABASE_URL || "";
        const adapter = new PrismaPg({ connectionString });
        super({ adapter, log: [{ emit: "event", level: "error" }] });
        this.logger.debug("🛠️  PrismaService initialized");
    }

    async onModuleInit() {
        await this.$connect();
        this.logger.debug("🚀 Prisma connected");
    }

    async onModuleDestroy() {
        // await this.$disconnect();
        this.logger.error("🚫 Prisma disconnected");
    }
}
