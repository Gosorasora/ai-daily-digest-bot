---
marp: true
theme: default
paginate: true
title: AI Daily Digest Bot — AWS SBG 세션
---

# AI가 매일 아침 메일로 찾아오는
# AWS 서버리스 봇

Lambda + EventBridge + SNS + Gemini로 만드는 1시간 자동화

**AWS SBG · Sora**

---

# 🎯 보고 시작

오늘 아침 받은 메일 ↓

> 🤖 오늘의 AI 다이제스트
>
> 🚀 마이크로소프트가 온디바이스 AI를 탑재한 '코파일럿+ PC'와 AI 기반 혁신 기능 '리콜'을 발표하며 AI PC 시대를 본격화했습니다.
> 🤖 구글이 I/O에서 실시간 다중 모달 AI 비서 '프로젝트 아스트라'를 시연하며, 더욱 강력해진 제미나이 모델 업데이트를 발표했습니다.
> ✨ 엔비디아가 어닝 서프라이즈를 기록하며…

**라이브 시연**: AWS Console → Lambda → `Test` 버튼 → 메일 도착

---

# 🏗 아키텍처

```
┌──────────────┐
│ EventBridge  │  매일 09:00 KST cron
└──────┬───────┘
       │ trigger
       ▼
┌──────────────┐    ┌────────────┐
│ Lambda (Py)  │───▶│ Gemini API │   AI 콘텐츠 생성
└──────┬───────┘    └────────────┘
       │ publish
       ▼
┌──────────────┐
│  SNS Topic   │───▶ 구독자 메일함
└──────────────┘
```

| 컴포넌트 | 비유 |
|---|---|
| EventBridge | ⏰ 알람시계 |
| Lambda | 🐣 1초만 깨어나는 함수 |
| Gemini | 🤖 AI 글짓기 |
| SNS | 📢 방송국 (이메일 발송) |

---

# 💰 비용 / 시간

| 항목 | 청구 |
|---|---|
| Lambda 호출 (월 30회) | $0 (프리티어 100만회) |
| SNS 이메일 (구독자 200명까지) | $0 (프리티어 1,000건) |
| EventBridge cron | $0 |
| Gemini API (일 30회 이하) | $0 (무료 티어) |
| **합계** | **$0 / 월** |

**오늘 만드는 데**: 30분
**매일 받는 데**: 0분 (자동)
**Docker**: 불필요 (urllib만 사용)

---

# 🚀 시작 — 코드 받기

```bash
git clone https://github.com/Gosorasora/ai-daily-digest-bot.git
cd ai-daily-digest-bot
```

QR 코드:

```
█▀▀▀▀▀█ ▀▄▀█ █▀▀▀▀▀█
█ ███ █ ▄▀▄  █ ███ █
█ ▀▀▀ █ ▄▀▄█ █ ▀▀▀ █
▀▀▀▀▀▀▀ █▄█▀ ▀▀▀▀▀▀▀
```

(GitHub QR로 폰에서 클립보드 복사)

---

# ✅ 환경 점검 (1분)

다음 4개 모두 답해야 진행 가능:

```bash
terraform version              # Terraform v1.x.x
aws --version                  # aws-cli/2.x.x
aws sts get-caller-identity    # 본인 AWS 계정 정보
```

⚠️ **Docker는 필요 없습니다** — Lambda 코드가 Python 표준 라이브러리만 사용.

막힌 항목이 있으면 옆 사람/강사에게 도움 요청.

---

# 🔑 IAM `my-bot` 사용자 만들기 (5분)

**왜?** `terraform apply`는 AWS에 리소스 만들 권한 필요.
root 키 직접 쓰지 말고 전용 IAM 사용자로.

## 5단계

1. **AWS Console → 검색창 "IAM" 클릭**
2. **좌측 [Users] → 우상단 [Create user]**
   - User name: `my-bot`
3. **Permissions → "Attach policies directly"**
   - `[✓] AdministratorAccess`
   - → Next → Create user
4. **만든 사용자 클릭 → [Security credentials] 탭**
   - [Create access key]
   - Use case: **Command Line Interface (CLI)**
   - 확인 체크 → Next → Create access key
5. **화면의 두 값을 터미널에 입력**

---

# 🔑 IAM (계속) — 터미널 설정

```bash
aws configure --profile my-bot
```

```
AWS Access Key ID:     [붙여넣기]
AWS Secret Access Key: [붙여넣기]
Default region name:   ap-northeast-2
Default output format: json
```

**검증**:
```bash
AWS_PROFILE=my-bot aws sts get-caller-identity
```

본인 계정 ID + `user/my-bot` ARN 나오면 OK ✅

---

# 🔐 Gemini API 키 + tfvars (3분)

1. **https://aistudio.google.com/apikey** 접속 (Google 로그인)
2. **[Create API key]** 클릭 → `AIzaSy...` 형태 키 복사
3. **터미널**:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
4. **`terraform.tfvars` 열어서** `gemini_api_key` 한 줄만 수정:
```hcl
gemini_api_key = "AIzaSy...본인_키_붙여넣기"
```

나머지(prompt, schedule 등)는 기본값 그대로 OK.

---

# 🏗 배포 (5분)

```bash
./build.sh                              # handler.py를 zip으로 (즉시)
terraform init                          # provider 다운로드 (30초)
AWS_PROFILE=my-bot terraform apply      # yes 입력 → 1분 대기
```

**결과**:
- 9개 리소스 생성 (SNS, Lambda, EventBridge, IAM 등)
- 출력값에 `sns_topic_arn` 등 표시

⏳ apply 중에 다음 슬라이드로 이메일 구독 명령 준비.

---

# 📧 구독 + 확인 + 테스트 (7분)

## 구독
```bash
AWS_PROFILE=my-bot aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## 확인
- 메일함에서 `from:no-reply@sns.amazonaws.com` 검색
- 제목 `AWS Notification - Subscription Confirmation`
- **Confirm subscription** 링크 클릭
- ⚠️ Gmail 프로모션/스팸, 네이버 스팸함 확인

## 테스트
- AWS Console → Lambda → `sbg-ai-digest` → **Test** 탭
- Event name: `manual`, JSON: `{}` → Save
- **[Test] 버튼** 클릭 → 메일 도착 🎉

---

# 🎨 커스터마이즈 — 콘텐츠 바꾸기

`terraform.tfvars`에서 한 줄만:

```hcl
# 운세
default_prompt = "오늘 12간지 띠별 운세를 한 줄씩"
email_subject  = "🔮 오늘의 운세"

# ENFP 조언
default_prompt = "ENFP에게 도움될 한 줄 조언"
email_subject  = "💫 오늘의 ENFP"

# 영어 회화
default_prompt = "비즈니스 영어 표현 3개를 예문과 함께"
email_subject  = "📚 오늘의 영어"
```

재배포:
```bash
./build.sh && AWS_PROFILE=my-bot terraform apply
```

---

# 🧹 폐기 / 정리

```bash
cd terraform
AWS_PROFILE=my-bot terraform destroy
```

`yes` 입력 → 1분 후 9개 리소스 모두 삭제.

추가 정리 (선택):
- **Gemini 키**: https://aistudio.google.com/apikey → 휴지통
- **IAM `my-bot` 사용자**: AWS Console → IAM → Users → Delete
- **로컬 폴더**: `rm -rf ai-daily-digest-bot/`

방치해도 비용 0이라 그냥 매일 메일 받아도 OK.

---

# 🙋 Q & A

- **자동화 안 됨?** EventBridge 룰이 enable 됐는지, Lambda 권한이 events.amazonaws.com 허용했는지 확인
- **메일 안 옴?** `aws sns list-subscriptions-by-topic`으로 `Pending Confirmation`인지 확인
- **다음 사람 추가?** `aws sns subscribe` 명령에 이메일 주소만 바꾸면 끝
- **다른 LLM 쓰고 싶다?** `handler.py`의 `_call_gemini` 함수만 교체

GitHub: **https://github.com/Gosorasora/ai-daily-digest-bot**

감사합니다 🙏

---

# 📝 강사용 진행 메모 (슬라이드 노트)

## 시간 배분 (60분)

| 슬라이드 | 시간 | 누적 |
|---|---|---|
| 1. Title | 1분 | 1 |
| 2. Wow 데모 | 3분 | 4 |
| 3. 아키텍처 | 2분 | 6 |
| 4. 비용/시간 | 1분 | 7 |
| 5. Clone | 2분 | 9 |
| 6. 환경 점검 | 1분 | 10 |
| 7~8. **IAM** | **5분** | 15 |
| 9. Gemini + tfvars | 3분 | 18 |
| 10. 배포 | 5분 | 23 |
| 11. 구독 + 테스트 | 7분 | 30 |
| (자유 시간: 챌린지/디버그) | 20분 | 50 |
| 12. 커스터마이즈 | 3분 | 53 |
| 13. 폐기 | 2분 | 55 |
| 14. Q&A | 5분 | 60 |

## 실패 대응 백업

- `iam:CreateRole` 권한 에러 → IAM 사용자에 AdministratorAccess 부착 확인
- `429 limit:0` → `gemini_model = "gemini-2.5-flash"` 확인 (기본값)
- 메일 안 옴 → SubscriptionArn이 `arn:aws:...`로 시작하는지 확인 (`PendingConfirmation`이면 미확인)
- `terraform: command not found` → 사전 준비물 미완 → 옆 사람 봇에 구독만 시켜 일단 메일 받게 하고 휴식 시간에 설치
- `aws sts get-caller-identity` 실패 → IAM 슬라이드 5단계 다시 확인
