import { S3Module } from "@global/s3/s3.module";
import { Module } from "@nestjs/common";
import { UserRepository } from "./auth.repository";
import { UsersController } from "./users.controller";

@Module({
    imports: [
        S3Module.forRoot({
            accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
            bucket: process.env.AWS_S3_BUCKET_NAME!,
            region: process.env.AWS_REGION!,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
            cache: {
                isCache: true,
                options: {},
            },
        }),
    ],
    providers: [UserRepository],
    controllers: [UsersController],
})
export class UsersModule {}
