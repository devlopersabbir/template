import { Module } from "@nestjs/common";
import { MailModule } from "@softvence/mail";
import { S3Module } from "@softvence/s3";
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
        MailModule.forRoot({
            transport: {
                auth: {
                    user: "",
                    pass: "",
                },
            },
        }),
    ],
    providers: [UserRepository],
    controllers: [UsersController],
})
export class UsersModule {}
