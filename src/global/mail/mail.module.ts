import { DynamicModule, Global, Module } from "@nestjs/common";
import { MailModuleOptions } from "./options/module-options";
import { MAIL_MODULE_OPTIONS } from "./options";
import { MailService } from "./mail.service";

@Global()
@Module({})
export class MailModule {
    /**
     * Register mail module for root app
     * Here is the example of how to use it
     * ```ts
     * MailModule.forRoot({
     *      transport: {
     *          service: "gmail",
     *          auth: {
     *              user: "test@test.com",
     *              pass: "test",
     *          },
     *      },
     *      defaults: {},
     *      templateRenderer: (type, context) => {
     *          switch (type) {
     *              case "otp":
     *                  return generateOtpEmail(context.otp!, context.expire!);
     *              default:
     *                  throw new Error(`Unknown email template type: ${type}`);
     *          }
     *      },
     *      mailQueue: {
     *          queueName: "mail-queue",
     *          host: "localhost",
     *          port: 6379,
     *          username: "default",
     *          password: "default",
     *      },
     * });
     * ```
     */
    static forRoot(options: MailModuleOptions): DynamicModule {
        return {
            global: true,
            module: MailModule,
            providers: [
                {
                    provide: MAIL_MODULE_OPTIONS,
                    useValue: options,
                },
                MailService,
            ],
            exports: [MailService],
        };
    }
}
