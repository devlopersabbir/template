import { NestFactory } from "@nestjs/core";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import "reflect-metadata";
import { AppModule } from "./app.module";

async function bootstrap() {
    const app = await NestFactory.create(AppModule);
    // ✅ Swagger config with Bearer Auth

    const config = new DocumentBuilder()
        // .setTitle(appMetadata.displayName)
        // .setDescription(appMetadata.description)
        // .setVersion(appMetadata.version)
        .addBearerAuth()
        .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup("docs", app, document, {
        swaggerOptions: {
            persistAuthorization: true,
        },
    });
    await app.listen(process.env.PORT ?? 8080);
}
bootstrap();
