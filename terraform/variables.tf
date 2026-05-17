variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Used as prefix for all resource names"
  type        = string
  default     = "sbg-ai-digest"
}

variable "gemini_api_key" {
  description = "Google AI Studio API key for Gemini (https://aistudio.google.com/apikey)"
  type        = string
  sensitive   = true
}

variable "schedule_expression" {
  description = "EventBridge schedule. cron(min hour day month day-of-week year) — UTC. Default: every day 09:00 KST = 00:00 UTC."
  type        = string
  default     = "cron(0 0 * * ? *)"
}

variable "default_prompt" {
  description = "Default prompt for Gemini when EventBridge fires with no payload"
  type        = string
  default     = "오늘의 AI/클라우드 분야 주요 뉴스 3개를 한국어로 한 줄씩 요약해줘. 각 항목 앞에 이모지 하나씩 붙여줘."
}

variable "email_subject" {
  description = "Subject line for outgoing SNS email"
  type        = string
  default     = "🤖 오늘의 AI 다이제스트"
}

variable "gemini_model" {
  description = "Gemini model name. gemini-2.0-flash often hits limit:0 on new keys; gemini-2.5-flash works on free tier."
  type        = string
  default     = "gemini-2.5-flash"
}
