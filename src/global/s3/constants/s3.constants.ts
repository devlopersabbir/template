import { Metadata } from "../s3.options";

export const SOFTVENCE_S3 = "SOFTVENCE_S3" as const;
export const S3_FOLDERS = ["images", "audio", "videos", "documents"] as const;
export type S3_FOLDERS = (typeof S3_FOLDERS)[number];

export const defaultMetadata: Metadata = {
    maxFileSize: 20 * 1024 * 1024, // 20 MB
    maxFiles: 20,
    actualFileName: "",
    fileHash: "",
};
