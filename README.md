# 📬 Serverless AI Insight Bot 만들기

매일 아침 9시에 AI가 정리한 뉴스 다이제스트가 본인 이메일로 도착하는 AWS 서버리스 봇.

**아키텍처**: EventBridge (cron) → Lambda (Python) → Gemini API → SNS (이메일)

**비용**: 월 $0 (모든 리소스 AWS 프리티어 + Gemini 무료 티어 안)

**소요 시간**: 30분 (Terraform 첫 사용 기준)

---

## 사전 준비 (세션 들어오기 전 필수)

⚠️ AWS 가입은 본인인증/카드인증에 며칠 걸릴 수 있으므로 **세션 1주일 전엔 시작**하세요.

| # | 항목 | 어떻게 | 시간 | 비용 |
|---|---|---|---|---|
| 1 | AWS 계정 | https://aws.amazon.com → 가입 (**신용카드 필수**) | 15분 | $0 (프리티어) |
| 2 | IAM admin 사용자 + Access Key | 콘솔 → IAM → Users → Create user → AdministratorAccess 부착 → Security credentials → Create access key (CLI 용도) | 5분 | $0 |
| 3 | AWS CLI 설치 + `aws configure` | 아래 설치 가이드 | 5분 | $0 |
| 4 | Terraform 설치 (≥ 1.0) | 아래 설치 가이드 | 3분 | $0 |
| 5 | Gemini API 키 | https://aistudio.google.com/apikey → "Create API key" → `AIzaSy...` 복사 | 1분 | $0 |
| 6 | 본인 이메일 주소 | 메일 받을 곳 (Gmail 권장) | — | — |

🎉 Docker는 **필요 없습니다** — Lambda 코드가 Python 표준 라이브러리(urllib)만 쓰므로 외부 패키지 빌드가 없음.

### 로컬 도구 설치

**macOS**:
```bash
brew install terraform awscli
```

**Windows**:
- Terraform: https://developer.hashicorp.com/terraform/install
- AWS CLI: https://aws.amazon.com/cli/

**Linux**:
- Terraform: https://developer.hashicorp.com/terraform/install
- AWS CLI v2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### AWS 자격증명 설정

```bash
aws configure --profile my-bot
# AWS Access Key ID: [발급받은 키 ID]
# AWS Secret Access Key: [발급받은 시크릿]
# Default region name: ap-northeast-2
# Default output format: json
```

### 환경 검증 (세션 시작 전 본인 점검)

다음 4개 명령이 모두 정상 출력되면 준비 완료:

```bash
terraform version              # Terraform v1.x.x
docker version                 # Client/Server 버전 (Docker 실행 중이어야 함)
aws --version                  # aws-cli/2.x.x
AWS_PROFILE=my-bot aws sts get-caller-identity   # 본인 계정 ID/ARN 출력
```

하나라도 막히면 위 표의 해당 단계로 돌아가세요.

---

## 배포 5단계

### 1. 저장소 받기
```bash
git clone https://github.com/Gosorasora/ai-daily-digest-bot.git
cd ai-daily-digest-bot
```

### 2. Gemini API 키 발급
1. https://aistudio.google.com/apikey 접속 (Google 로그인)
2. "Create API key" 클릭
3. 키 복사 (`AIzaSy...` 형태)

### 3. 변수 파일 작성
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars`를 열어 `gemini_api_key`에 발급받은 키 붙여넣기. 그 외는 기본값 그대로 OK.

### 4. Lambda 패키지 빌드

```bash
./build.sh
```

`handler.py`를 `lambda/build/`에 복사하는 한 줄짜리 작업. Lambda 코드가 Python 표준 라이브러리만 쓰므로 외부 패키지 설치 불필요. zip은 약 2KB.

### 5. 배포

```bash
terraform init
AWS_PROFILE=my-bot terraform apply
```

`Enter a value`에 `yes` 입력. 1~2분 후 9개 리소스 생성 완료.

---

## 첫 구독자 등록 + 테스트

### 본인 이메일 구독

```bash
AWS_PROFILE=my-bot aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### 확인 메일 클릭

- 발신: `no-reply@sns.amazonaws.com`
- 제목: `AWS Notification - Subscription Confirmation`
- 본문의 `Confirm subscription` 링크 클릭
- ⚠️ Gmail은 종종 **프로모션 탭** 또는 **스팸**으로 분류 — 검색창에 `from:no-reply@sns.amazonaws.com`

### 즉시 발송 (지금 바로 메일 받기)

**가장 쉬운 방법 — AWS Console의 Test 버튼**

1. AWS Console → Lambda → `sbg-ai-digest` 함수 클릭
2. **Test** 탭 클릭
3. Event name: `manual`, Event JSON: `{}` 입력 → **Save**
4. 우측 상단 노란 **[Test]** 버튼 클릭
5. 잠시 후 메일 도착, 콘솔 하단에 Response/Logs 표시

테스트 이벤트는 한 번 저장하면 계속 남으므로, 다음부터는 **Test 버튼 한 번**으로 끝.

**CLI 방법 (선택)**
```bash
AWS_PROFILE=my-bot aws lambda invoke \
  --function-name $(terraform output -raw lambda_name) \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/out.json && cat /tmp/out.json
```

---

## 사용 / 커스터마이즈

### 다른 사람 추가
구독 명령에서 이메일 주소만 바꾸면 됩니다. 각자 확인 메일 클릭 필수.

### 콘텐츠 바꾸기 (운세, 영어, MBTI 등)
가장 단순한 방법 — `terraform.tfvars`의 `default_prompt` 한 줄만 수정:

```hcl
default_prompt = "오늘 ENFP에게 도움이 될 한 줄 조언을 알려줘."
email_subject  = "💫 오늘의 한 줄"
```

코드 변경 후 재배포:
```bash
./build.sh && AWS_PROFILE=my-bot terraform apply
```

더 깊은 커스터마이즈는 `terraform/lambda/handler.py`를 직접 수정. Hacker News fetch, YouTube 자막 요약, 유저별 프롬프트(DynamoDB), SES HTML 메일 등 모두 가능.

---

## 비용 자세히

| 사용량 | 월 비용 |
|---|---|
| 일 1회 발송, 구독자 30명 | $0 |
| 일 1회 발송, 구독자 200명 | $0 |
| 시간당 발송 (테스트), 구독자 30명 | $0 |
| 일 1회 발송, 구독자 1,000명 | ~$0.58 (SNS 이메일 한도 초과분) |

**모든 자원이 사용량 기준** — 리소스 존재만으론 0원. 방치해도 안전.

---

## 폐기

```bash
cd terraform
AWS_PROFILE=my-bot terraform destroy
```

`yes` 입력. 1분 후 모든 리소스 삭제. Gemini 키는 별도로 https://aistudio.google.com/apikey 에서 회수.

---

## 폴더 구조

```
ai-daily-digest-bot/
├── README.md                  ← 이 파일
└── terraform/                 ← 인프라
    ├── main.tf                ← SNS, Lambda, EventBridge, IAM
    ├── variables.tf           ← 설정 변수 정의
    ├── outputs.tf             ← 배포 후 출력값
    ├── terraform.tfvars.example  ← 변수 템플릿
    ├── build.sh               ← Lambda 패키지 빌드 (Docker)
    └── lambda/
        ├── handler.py         ← Lambda 핸들러 (편집 대상)
        └── requirements.txt   ← Python 의존성
```

---

## 라이선스 / 출처

원본: AWS SBG 세션 — Sora (DongHyeon Ko) · 2026.05
