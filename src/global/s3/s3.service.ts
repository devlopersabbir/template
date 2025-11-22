import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { BadRequestException, Inject, Injectable } from "@nestjs/common";
import Cache from "node-cache";
import { createHash } from "node:crypto";
import { v4 as uuidv4 } from "uuid";
import { defaultMetadata } from "./constants/s3.constants";
import type { Metadata, S3ModuleOptions } from "./s3.options";
import { S3_MODULE_OPTIONS } from "./s3.options";
import { S3Response } from "./types.index";

@Injectable()
export class S3Service {
    private s3: S3Client;
    private cache: Cache | null;

    constructor(
        @Inject(S3_MODULE_OPTIONS)
        private readonly options: S3ModuleOptions,
    ) {
        if (this.options.cache && this.options.cache.isCache) {
            this.cache = new Cache({
                stdTTL: this.options.cache?.options?.stdTTL || 86400, // default 1 day
                checkperiod: this.options.cache?.options?.checkperiod || 120,
            });
        } else {
            this.cache = null;
        }

        this.s3 = new S3Client({
            region: options.region,
            credentials: {
                accessKeyId: options.accessKeyId,
                secretAccessKey: options.secretAccessKey,
            },
        });
    }

    async uploadFiles(
        files: Express.Multer.File[],
        metadata: Metadata = { ...defaultMetadata },
    ): Promise<S3Response[]> {
        if (!files || files.length === 0) throw new BadRequestException("No file(s) uploaded");
        if (files.length > metadata.maxFiles!)
            throw new BadRequestException(`You can upload a maximum of ${metadata.maxFiles} files`);

        const results: S3Response[] = [];
        for (const file of files) {
            results.push(await this.uploadFile(file, metadata));
        }
        return results;
    }

    async uploadFile(
        file: Express.Multer.File,
        metadata: Metadata = { ...defaultMetadata },
    ): Promise<S3Response> {
        const meta = { ...defaultMetadata, ...metadata };
        const isSmallFile = file.size < meta.maxFileSize!;
        let fileHash: string | null = null;
        let cacheKey: string | undefined;

        // Handle cache
        if (this.cache && isSmallFile) {
            fileHash = createHash("sha256").update(file.buffer).digest("hex");
            cacheKey = `S3FileHash-${fileHash}`;
            const cachedData = this.cache.get<S3Response>(cacheKey);
            if (cachedData) {
                return { ...cachedData, cached: true };
            }
        }

        // Build S3 key
        const ext = file.originalname.split(".").pop();
        const folder = this.getFolderByMimeType(file.mimetype);
        const uniqueName = `${fileHash ?? uuidv4()}.${ext}`;
        const s3Key = `${folder}/${uniqueName}`;

        try {
            await this.s3.send(
                new PutObjectCommand({
                    Bucket: this.options.bucket,
                    Key: s3Key,
                    Body: file.buffer,
                    ContentType: file.mimetype,
                }),
            );

            const url = `https://${this.options.bucket}.s3.${this.options.region}.amazonaws.com/${s3Key}`;

            const response: S3Response = {
                url,
                bucket: this.options.bucket,
                region: this.options.region,
                originalName: file.originalname,
                size: file.size,
                mimeType: file.mimetype,
                extension: ext!,
                folder,
                hash: fileHash || undefined,
                cached: false,
                cacheKey,
                uploadedAt: new Date(),
                metadata,
            };

            // Store in cache if small
            if (this.cache && isSmallFile && fileHash && cacheKey) {
                this.cache.set(cacheKey, response);
            }

            return response;
        } catch (err) {
            console.error(err);
            throw new BadRequestException("Failed to upload file to S3");
        }
    }

    private getFolderByMimeType(mimeType: string): string {
        if (mimeType.startsWith("image/")) return "images";
        if (mimeType.startsWith("audio/")) return "audio";
        if (mimeType.startsWith("video/")) return "videos";
        return "documents";
    }
}
