import { Metadata } from "./s3.options";

export type S3Response = {
    url: string; // Full S3 URL
    bucket: string; // Bucket name
    region: string; // Bucket region

    // File info
    originalName: string; // Original file name
    size: number; // File size in bytes
    mimeType: string; // File MIME type
    extension: string; // File extension
    folder: string; // Folder assigned (images, videos, etc.)
    hash?: string; // SHA256 hash (if cached or small file)

    // Cache info
    cached?: boolean; // True if returned from cache
    cacheKey?: string; // Node-cache key if cached

    // Timestamp
    uploadedAt: Date; // Timestamp when uploaded

    // Metadata
    metadata?: Metadata; // User-provided metadata (maxSize, etc.)
};
