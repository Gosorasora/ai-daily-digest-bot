"""
AI Digest Lambda — Gemini로 콘텐츠 생성 후 SNS로 발송.

EventBridge 스케줄, AWS Console Test 버튼, 수동 invoke 어디서 호출되든 동작.
event payload로 prompt/subject를 덮어쓸 수 있다.

순수 Python 표준 라이브러리(urllib)만 사용 — 외부 패키지 의존성 없음.
"""

import json
import os
import urllib.request

import boto3  # Lambda Python 런타임에 기본 포함

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
GEMINI_API_KEY = os.environ["GEMINI_API_KEY"]
DEFAULT_PROMPT = os.environ.get(
    "DEFAULT_PROMPT",
    "오늘의 AI 분야 주요 뉴스 3개를 한국어로 한 줄씩 요약해줘.",
)
DEFAULT_SUBJECT = os.environ.get("EMAIL_SUBJECT", "🤖 오늘의 AI 다이제스트")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")

_sns = boto3.client("sns")


def _extract_prompt(event: dict) -> str:
    if not isinstance(event, dict):
        return DEFAULT_PROMPT
    if "prompt" in event:
        return event["prompt"]
    body = event.get("body")
    if isinstance(body, str):
        try:
            return json.loads(body).get("prompt", DEFAULT_PROMPT)
        except json.JSONDecodeError:
            return body or DEFAULT_PROMPT
    return DEFAULT_PROMPT


def _call_gemini(prompt: str) -> str:
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/"
        f"models/{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}"
    )
    payload = {"contents": [{"parts": [{"text": prompt}]}]}
    req = urllib.request.Request(
        url,
        method="POST",
        headers={"Content-Type": "application/json"},
        data=json.dumps(payload).encode("utf-8"),
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read())
    return data["candidates"][0]["content"]["parts"][0]["text"]


def lambda_handler(event, context):
    prompt = _extract_prompt(event)
    subject = (event or {}).get("subject", DEFAULT_SUBJECT)[:99]  # SNS subject 100자 제한

    message = _call_gemini(prompt).strip() or "(빈 응답)"
    _sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=subject, Message=message)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {"sent": True, "subject": subject, "preview": message[:200]},
            ensure_ascii=False,
        ),
    }
