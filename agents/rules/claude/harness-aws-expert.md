# 하네스: AWS 전문가

> 이 파일은 `~/.agents/rules/claude/CLAUDE.md`의 하네스 인덱스에서 참조됨. AWS 인프라 작업이 트리거되면 로드한다.

**목표:** AWS 지식이 부족한 사용자에게 인프라 설계, 설정 가이드, IaC 코드, 트러블슈팅을 친절하게 안내한다.

**에이전트:**
| 에이전트 | 역할 |
|---------|------|
| aws-architect | 요구사항 기반 인프라 아키텍처 설계 |
| aws-guide-writer | 단계별 AWS 서비스 설정 가이드 작성 |
| aws-iac-engineer | CDK/CloudFormation/Terraform 코드 생성 |
| aws-troubleshooter | AWS 에러 진단 및 해결 안내 |

**스킬:**
| 스킬 | 용도 | 사용 에이전트 |
|------|------|-------------|
| aws-expert | 오케스트레이터 — 시나리오별 에이전트 조율 | 전체 |

**실행 규칙:**
- AWS 관련 인프라 작업 요청 시 `/aws-expert` 스킬을 통해 에이전트를 호출하라
- 단순 AWS 개념 질문은 에이전트 없이 직접 응답해도 무방
- 모든 에이전트는 `model: "opus"` 사용
- **중간 산출물 위치 (고정)**: `~/.agents/_workspace/harness-aws-expert/{slug}/` — 슬러그는 Phase 1에서 확정되는 세션별 식별자 (예: `vpc-design-2026-04-15`, `eks-troubleshoot-2026-04-15`). CWD에 산출물 생성 금지
- 산출 파일 구성: `architecture.md / iac/ / guide_{service}.md / troubleshoot_{issue}.md`
- 모든 에이전트 호출 시 오케스트레이터가 절대 경로 `$WS = /Users/{user}/.agents/_workspace/harness-aws-expert/{slug}/`를 프롬프트에 명시 전달
- 부분 재실행 지원: 슬러그만 알면 임의 시점 재진입 가능. 아키텍처 변경 → IaC 재생성 연쇄 시 사용자 확인 후 진행

**디렉토리 구조:**
```
~/.agents/
├── _workspace/                              ← 모든 AWS 세션의 중간 산출물 베이스
│   └── harness-aws-expert/
│       └── {slug}/                          ← 세션별 격리
│           ├── architecture.md
│           ├── iac/
│           │   ├── bin/, lib/, cdk.json, ...
│           │   └── README.md
│           ├── guide_{service}.md
│           └── troubleshoot_{issue}.md
├── agents/
│   ├── aws-architect.md
│   ├── aws-guide-writer.md
│   ├── aws-iac-engineer.md
│   └── aws-troubleshooter.md
└── skills/
    └── aws-expert/
        ├── SKILL.md
        └── references/
            ├── compute.md
            ├── network.md
            ├── storage-db.md
            ├── deploy-ops.md
            └── beginner-patterns.md
```

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-04-06 | 초기 구성 | 전체 | AWS 전문가 하네스 신규 구축 |
| 2026-04-15 | 작업 디렉토리 통합 | SKILL.md, 4 agents, harness rule | 4개 하네스 통합 패턴(`~/.agents/_workspace/harness-{name}/{slug}/`)에 맞춰 절대 경로·슬러그 격리로 전환 |
