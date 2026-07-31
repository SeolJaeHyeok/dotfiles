---
name: aws-expert
description: "AWS 인프라 전문가 하네스 오케스트레이터. 인프라 설계 상담, 서비스 설정 가이드 생성, IaC 코드(CDK/CloudFormation/Terraform) 생성, 트러블슈팅 지원을 수행한다. AWS 초보자도 이해할 수 있도록 친절하게 안내한다. 다음 상황에서 반드시 이 스킬을 사용할 것: AWS 관련 질문, 인프라 설계 요청, 클라우드 아키텍처 상담, EC2/Lambda/VPC/S3/RDS 등 AWS 서비스 설정, CloudFormation/CDK/Terraform 코드 생성, AWS 에러나 장애 진단, 비용 최적화 상담, 보안 설정 검토. 또한 '다시 실행', '업데이트', '수정', '이전 결과 개선', '다른 서비스 추가' 같은 후속 요청에도 트리거된다."
---

# AWS Expert Orchestrator

AWS 인프라 전문가 하네스의 오케스트레이터. 4명의 전문 에이전트를 사용자 요청에 따라 조율한다.

## 먼저 읽을 파일

요청 유형에 따라 필요한 레퍼런스만 로드한다:
- 컴퓨팅 관련: `references/compute.md`
- 네트워크 관련: `references/network.md`
- 스토리지/DB 관련: `references/storage-db.md`
- 배포/운영 관련: `references/deploy-ops.md`
- 초보자 공통 패턴: `references/beginner-patterns.md`

## 에이전트 팀

| 에이전트 | 정의 파일 | 역할 |
|---------|----------|------|
| aws-architect | `~/.agents/agents/aws-architect.md` | 인프라 설계, 아키텍처 상담 |
| aws-guide-writer | `~/.agents/agents/aws-guide-writer.md` | 단계별 설정 가이드 생성 |
| aws-iac-engineer | `~/.agents/agents/aws-iac-engineer.md` | IaC 코드 생성 (CDK/CF/TF) |
| aws-troubleshooter | `~/.agents/agents/aws-troubleshooter.md` | 에러 진단, 장애 해결 |

## 워크플로우

### Phase 0: 컨텍스트 확인

**작업 디렉토리 정책:** 모든 중간 산출물은 `~/.agents/_workspace/harness-aws-expert/{slug}/`에 저장한다. `{slug}`는 세션별 고유 식별자(작업 주제 슬러그 + 날짜)로, Phase 1에서 확정한다. CWD에는 어떤 산출물도 만들지 않는다.

1. 사용자 요청에서 기존 슬러그 단서를 찾는다:
   - 사용자가 명시 ("`vpc-design-2026-04-15` IaC 다시 생성해줘")
   - 직전 세션의 슬러그를 기억하고 있다면 그것
   - 단서 없음 → 신규 슬러그 생성 대상

2. 슬러그가 식별되면 `~/.agents/_workspace/harness-aws-expert/{slug}/` 존재 여부 확인:
   - **존재 + 사용자가 부분 수정 요청** → `$WS=~/.agents/_workspace/harness-aws-expert/{slug}/`로 고정하고 해당 에이전트만 재호출
   - **존재 + 사용자가 처음부터 다시** → 사용자에게 "기존 작업 이어서 / 새로 시작 / 다른 슬러그" 선택을 요청. "새로 시작"이면 새 슬러그(타임스탬프 접미 등)로 분기
   - **미존재 또는 슬러그 단서 없음** → 신규 슬러그 생성 (Phase 1에서 확정), 초기 실행

3. 신규 실행이라면 `mkdir -p ~/.agents/_workspace/harness-aws-expert/{slug}/`로 디렉토리를 만들고, 모든 에이전트 호출에 작업 디렉토리 절대 경로(`$WS = /Users/{user}/.agents/_workspace/harness-aws-expert/{slug}/`)를 프롬프트에 명시 전달한다. 에이전트는 이 절대 경로를 입출력 기준으로 사용한다 (홈 경로 `~`는 사용 금지 — 절대 경로만).

4. 사용자 요청을 분석하여 시나리오를 판별한다:

| 시나리오 | 판별 기준 | 호출 에이전트 |
|---------|----------|------------|
| 인프라 설계 상담 | "설계", "아키텍처", "어떤 서비스", "구성" | architect → (선택) iac-engineer |
| 설정 가이드 | "설정 방법", "어떻게 만들어", "가이드" | guide-writer |
| IaC 코드 생성 | "CDK", "CloudFormation", "Terraform", "코드로" | (선택: architect →) iac-engineer |
| 트러블슈팅 | "에러", "안 됨", "오류", "문제", "왜" | troubleshooter |
| 복합 요청 | 설계 + 코드 함께 요청 | architect → iac-engineer |
| 단순 질문 | 개념 설명, 비교 질문 | 에이전트 없이 직접 응답 |

### Phase 1: 요구사항 정리

사용자에게 부족한 정보를 **1개씩** 물어본다 (Rule 0). 한 번에 여러 질문을 하지 않는다. 채워야 하는 슬롯:

| 슬롯 | 질문 예시 | 기본값 |
|------|----------|-------|
| **작업 주제** | "어떤 AWS 작업이 필요한가? (설계/가이드/IaC/트러블슈팅)" | 필수 |
| **슬러그** | (자동) 주제에서 영문 kebab-case로 자동 생성, 충돌 시 사용자에게 확인 | `{topic-kebab}-{YYYY-MM-DD}` |
| (시나리오별 슬롯) | 아래 참조 | - |

**슬러그 생성 규칙:**
- 영문 소문자 + 숫자 + 하이픈만 사용 (한글·공백·특수문자 금지)
- 작업의 핵심 명사 2-4개 + 날짜 (`YYYY-MM-DD`)
- AWS 작업 예시:
  - "Next.js 앱을 위한 VPC 구성" → `vpc-design-2026-04-15`
  - "EKS 클러스터 IaC 생성" → `eks-iac-2026-04-15`
  - "Lambda 타임아웃 트러블슈팅" → `lambda-timeout-troubleshoot-2026-04-15`
  - "RDS 설정 가이드" → `rds-setup-guide-2026-04-15`
- `~/.agents/_workspace/harness-aws-expert/{slug}/`가 이미 존재하면 사용자에게 "기존 작업 이어서 / 새로 시작 / 다른 슬러그" 선택을 요청

**시나리오별 추가 슬롯:**

인프라 설계 시 필요한 정보:
- 어떤 서비스/앱을 운영하려 하는가?
- 예상 사용자 수 / 트래픽 규모 (모르면 "소규모" 가정)
- 예산 범위 (있으면)
- 선호하는 기술 (있으면)

설정 가이드 시 필요한 정보:
- 어떤 AWS 서비스를 설정하려 하는가?
- 무엇을 위해 사용하는가?

IaC 생성 시 필요한 정보:
- IaC 도구 (CDK/CloudFormation/Terraform, 미지정 시 CDK TypeScript)
- 환경 (dev/staging/prod)

트러블슈팅 시 필요한 정보:
- 에러 메시지 또는 증상
- 영향받는 AWS 서비스
- 최근 변경사항

### Phase 2: 에이전트 호출

에이전트 정의 파일(`~/.agents/agents/{name}.md`)을 읽고, 해당 내용을 Agent 도구의 prompt에 포함하여 호출한다.

**호출 규칙:**
- 모든 Agent 호출에 `model: "opus"` 파라미터를 명시한다
- 에이전트 정의 파일의 "작업 원칙"과 "출력 프로토콜"을 prompt에 반드시 포함한다
- 관련 레퍼런스 파일의 내용도 prompt에 포함한다
- **모든 에이전트 호출 프롬프트에 `$WS` 절대 경로를 명시 전달한다** (예: `$WS = /Users/{user}/.agents/_workspace/harness-aws-expert/{slug}/`). 에이전트는 이 기준으로 입출력 파일을 읽고 쓴다.
- 독립적인 에이전트는 `run_in_background: true`로 병렬 실행한다

**호출 예시:**
```
WS = "/Users/{user}/.agents/_workspace/harness-aws-expert/{slug}/"  # Phase 0에서 확정된 절대 경로

Agent(
    subagent_type="general-purpose",
    model="opus",
    description="AWS architecture design",
    prompt=f"""
    너는 aws-architect 에이전트다. 정의 파일은 ~/.agents/agents/aws-architect.md 에 있으니 먼저 읽어라.

    작업 디렉토리($WS): {WS}

    사용자 요구사항:
    ...

    결과를 {WS}architecture.md 에 저장하라.
    """
)
```

⚠️ 모든 에이전트 호출은 프롬프트에 `$WS` 절대 경로를 반드시 포함한다. 에이전트는 자체적으로 `_workspace/` 같은 상대 경로를 만들지 않는다.

**순차 호출 (복합 요청):**
```
1. aws-architect 호출 → $WS/architecture.md 생성
2. architecture.md를 입력으로 aws-iac-engineer 호출 → $WS/iac/ 생성
3. (선택) architecture.md를 입력으로 aws-guide-writer 호출 → $WS/guide_*.md 생성
```

**단일 호출:**
- 시나리오에 맞는 에이전트 1개만 호출

### Phase 3: 결과 종합

에이전트 산출물을 사용자에게 제시할 때:
1. 전체 요약을 먼저 보여준다 (3줄 이내)
2. 상세 내용은 `$WS/` 파일을 참조하도록 안내한다 (절대 경로로 명시)
3. "더 궁금한 점이 있으면 물어보세요"로 후속 질문을 유도한다

### Phase 4: 후속 처리

- 사용자가 수정을 요청하면 같은 `$WS`를 재사용해 해당 에이전트만 재호출한다
- 아키텍처 변경 시 연쇄 영향이 있으면 (architecture.md 변경 → IaC 코드 재생성 필요) 알려주고 확인한다

## 데이터 흐름

```
사용자 입력
   ↓
Phase 0: 슬러그 결정 → $WS = ~/.agents/_workspace/harness-aws-expert/{slug}/
   ↓
Phase 1: 시나리오별 슬롯 수집
   ↓
Phase 2: 에이전트 호출 (프롬프트에 $WS 절대 경로 명시)
   ├── aws-architect    → $WS/architecture.md
   ├── aws-iac-engineer → $WS/iac/
   ├── aws-guide-writer → $WS/guide_{service}.md
   └── aws-troubleshooter → $WS/troubleshoot_{issue}.md
   ↓
Phase 3: 요약 + $WS 경로 안내
   ↓
Phase 4: 부분 재호출 (같은 $WS 재사용)
```

모든 중간 산출물은 `~/.agents/_workspace/harness-aws-expert/{slug}/`에 보존되어 슬러그만 알면 임의 시점에 부분 재실행 가능.

## 에러 핸들링

- 에이전트 호출 실패 시 1회 재시도 후, 재실패 시 해당 에이전트 없이 직접 응답한다
- 에이전트 간 산출물 불일치 시 차이점을 명시하고 사용자에게 선택을 요청한다
- 사용자 요청이 AWS 범위를 벗어나면 (예: GCP, Azure) 그 사실을 알리고 가능한 범위 내에서 도움을 준다

## 테스트 시나리오

### 정상 흐름
```
사용자: "Next.js 앱을 배포할 건데, 어떤 AWS 구성이 좋을까?"
→ Phase 0: 슬러그 = `nextjs-aws-design-2026-04-15`,
  $WS = ~/.agents/_workspace/harness-aws-expert/nextjs-aws-design-2026-04-15/, mkdir -p
→ Phase 1: 트래픽/예산 확인
→ architect 호출 (prompt에 $WS 명시) → $WS/architecture.md 생성
→ 사용자에게 아키텍처 제시
→ 사용자: "CDK 코드도 만들어줘"
→ iac-engineer 호출 (같은 $WS, architecture.md 입력) → $WS/iac/ 디렉토리 생성
```

### 에러 흐름
```
사용자: "Lambda 함수가 타임아웃 나요"
→ Phase 0: 슬러그 = `lambda-timeout-2026-04-15`,
  $WS = ~/.agents/_workspace/harness-aws-expert/lambda-timeout-2026-04-15/, mkdir -p
→ troubleshooter 호출 → $WS/troubleshoot_lambda-timeout.md
→ 체크리스트 제시
→ 사용자: "메모리를 늘렸는데도 안 돼요"
→ 같은 $WS에서 troubleshooter 재호출 (이전 산출물 읽고 갱신)
```
