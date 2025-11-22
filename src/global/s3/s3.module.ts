import { DynamicModule, Module } from "@nestjs/common";
import { S3ModuleOptions, S3_MODULE_OPTIONS } from "./s3.options";
import { S3Service } from "./s3.service";

@Module({})
export class S3Module {
    static forRoot(options: S3ModuleOptions): DynamicModule {
        return {
            module: S3Module,
            global: true,
            providers: [
                {
                    provide: S3_MODULE_OPTIONS,
                    useValue: options,
                },
                S3Service,
            ],
            exports: [S3Service],
        };
    }
}
