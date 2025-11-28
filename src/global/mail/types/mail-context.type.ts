import type { LiteralUnion } from "type-fest";

export type MailTemplateType = LiteralUnion<"OTP" | "SYSTEM", string>;

export type MailContext<T = any> = T | {};
