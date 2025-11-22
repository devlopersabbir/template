import { Options } from "node-cache";
export type S3CacheOptions = {
    isCache?: boolean;
    options?: Options;
};
export type S3ModuleOptions = {
    region: string;
    bucket: string;
    accessKeyId: string;
    secretAccessKey: string;
    endpoint?: string;
    cache?: S3CacheOptions;
};

export type Metadata = {
    maxFileSize?: number;
    maxFiles?: number;
    actualFileName?: string;
    fileHash?: string;
};

export type S3UploadOptions = {
    limit: number;
    fileTypes: "jpeg"; // TODO: add rest of the file type so, that user can make it retricts
    // and others things if needs...
};

export const S3_MODULE_OPTIONS = "S3_MODULE_OPTIONS";
