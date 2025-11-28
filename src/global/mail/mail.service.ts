import appMetadata from "@metadata/app-metadata";
import { BadGatewayException, Inject, Injectable, Logger } from "@nestjs/common";
import * as nodemailer from "nodemailer";
import { MAIL_MODULE_OPTIONS, MailSendOptions } from "./options";
import type { MailModuleOptions } from "./options/module-options";
import { generateOtpEmail } from "./template/otp.template";
import { MailContext, MailTemplateType } from "./types/mail-context.type";

@Injectable()
export class MailService {
    private transporter: nodemailer.Transporter;
    private logger = new Logger(MailService.name);

    constructor(
        @Inject(MAIL_MODULE_OPTIONS)
        private readonly moduleOptions: MailModuleOptions,
    ) {
        this.transporter = nodemailer.createTransport(moduleOptions.transport, {
            logger: true,
            debug: true,
            ...(moduleOptions?.defaults || {}),
        });
    }

    /**
     * Send email with full custom options
     * ## Here is the example of how to use it
     * ```ts
     * const options: MailSendOptions = {
     *      to: "test@test.com",
     *      subject: "Test email",
     *      template: "otp",
     *      context: {
     *          otp: "123456",
     *          expire: Date.now() + 1000 * 60 * 60 * 24,
     *      },
     * };
     * await this.mailService.send(options);
     * ```
     */
    public async send(options: MailSendOptions): Promise<void> {
        const {
            to,
            subject,
            template,
            context = {},
            html,
            text,
            cc,
            bcc,
            replyTo,
            priority,
            attachments,
            headers,
            from,
        } = options;

        // 1. Render template if provided
        let finalHtml = html;
        if (template && !html) {
            finalHtml = this.moduleOptions?.templateRenderer
                ? this.moduleOptions.templateRenderer(template, context)
                : this.renderTemplate(template, context);
        }

        const mailOptions: nodemailer.SendMailOptions = {
            from: from || `"${appMetadata.displayName}" <${this.moduleOptions}>`,
            to,
            subject,
            html: finalHtml,
            text,
            cc,
            bcc,
            replyTo,
            priority,
            attachments,
            headers,
        };

        try {
            await this.transporter.sendMail(mailOptions);
            this.logger.log(`📨 Email sent → ${JSON.stringify(to)} : ${subject}`);
        } catch (error) {
            this.logger.error(`❌ Failed to send email`, error.stack);
            throw new BadGatewayException(`Failed to send email: ${error.message}`);
        }
    }

    /**
     * Default template renderer
     */
    private renderTemplate(type: MailTemplateType, context: MailContext): string {
        switch (type) {
            case "otp":
                return generateOtpEmail(context.otp!, context.expire!);
            default:
                throw new Error(`Unknown email template type: ${type}`);
        }
    }
}
