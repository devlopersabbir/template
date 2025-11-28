import { MailContext, MailTemplateType } from "../types/mail-context.type";

export type MailSendOptions = {
    to: string | string[];
    subject: string;
    template?: MailTemplateType; // built-in template
    context?: MailContext; // context for templates
    html?: string; // override template with raw html
    text?: string; // send text version only
    from?: string; // override default sender
    cc?: string | string[];
    bcc?: string | string[];
    replyTo?: string;
    priority?: "high" | "normal" | "low";
    attachments?: any[];
    headers?: Record<string, string>;
};

export const MAIL_MODULE_OPTIONS = "MAIL_MODULE_OPTIONS" as const;
