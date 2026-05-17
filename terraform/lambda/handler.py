"""
AI Digest Lambda — Gemini로 콘텐츠 생성 후 SNS로 발송.

EventBridge 스케줄, 수동 invoke, Function URL 등 어디서 호출되든 동작.
event payload로 prompt/subject를 덮어쓸 수 있어 챌린지에서 그대로 확장 가능.
"""

import json
import os

import boto3
import google.generativeai as genai

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
DEFAULT_PROMPT = os.environ.get(
    "DEFAULT_PROMPT",
    "오늘의 AI 분야 주요 뉴스 3개를 한국어로 한 줄씩 요약해줘.",
)
DEFAULT_SUBJECT = os.environ.get("EMAIL_SUBJECT", "🤖 오늘의 AI 다이제스트")
MODEL_NAME = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")

genai.configure(api_key=os.environ["GEMINI_API_KEY"])
_model = genai.GenerativeModel(MODEL_NAME)
_sns = boto3.client("sns")


def _extract_prompt(event: dict) -> str:
    if not isinstance(event, dict):
        return DEFAULT_PROMPT
    # 수동 invoke나 Function URL에서 넘긴 body 형식 모두 흡수
    if "prompt" in event:
        return event["prompt"]
    body = event.get("body")
    if isinstance(body, str):
        try:
            return json.loads(body).get("prompt", DEFAULT_PROMPT)
        except json.JSONDecodeError:
            return body or DEFAULT_PROMPT
    return DEFAULT_PROMPT


def lambda_handler(event, context):
    prompt = _extract_prompt(event)
    subject = (event or {}).get("subject", DEFAULT_SUBJECT)[:99]  # SNS subject 100자 제한

    response = _model.generate_content(prompt)
    message = response.text.strip() if response.text else "(빈 응답)"

    _sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=subject, Message=message)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {"sent": True, "subject": subject, "preview": message[:200]},
            ensure_ascii=False,
        ),
    }
