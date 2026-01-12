variable "ses_email_identity" {
  description = "SES verified email identity for sending Cognito verification emails"
  type        = string
  default     = "noreply@paragrafic.pl"
}
