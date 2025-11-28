import nodemailer from "nodemailer";
import SMTPTransport from "nodemailer/lib/smtp-transport";
import { MailContext, MailTemplateType } from "../types/mail-context.type";

export type MailModuleOptions = {
    transport: SMTPTransport | SMTPTransport.Options;
    defaults?: nodemailer.Transporter["options"];
    templateRenderer?: (type: MailTemplateType, context: MailContext) => string; // allow override template engine
    mailQueue?:
        | boolean
        | {
              queueName: string;
              host: string;
              port: number;
              username: string;
              password: string;
          };
};
