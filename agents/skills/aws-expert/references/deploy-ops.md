# AWS 배포/운영 서비스 레퍼런스

## IaC 도구 선택 가이드

| 기준 | CDK (TypeScript) | CloudFormation (YAML) | Terraform (HCL) |
|------|------------------|----------------------|-----------------|
| 학습 난이도 | 중간 (TS 필요) | 낮음 (YAML) | 중간 (HCL) |
| 타입 안전성 | 높음 | 없음 | 중간 |
| AWS 전용 | 예 | 예 | 멀티 클라우드 |
| IDE 지원 | 매우 좋음 | 보통 | 좋음 |
| 추천 대상 | 개발자 | 인프라 엔지니어 | 멀티 클라우드 팀 |

**미지정 시 기본값: CDK (TypeScript)** — IDE 자동완성, 타입 체크, 코드 재사용이 가장 뛰어남.

## CDK (Cloud Development Kit)

### 시작하기
```bash
# 설치
npm install -g aws-cdk

# 프로젝트 생성
mkdir my-infra && cd my-infra
cdk init app --language typescript

# 배포
cdk bootstrap   # 최초 1회
cdk deploy      # 배포
cdk destroy     # 삭제
```

### 핵심 개념
- **App**: 최상위 컨테이너
- **Stack**: CloudFormation 스택 1:1 매핑. 배포 단위
- **Construct**: 리소스 추상화. L1(CloudFormation 그대로), L2(편의 메서드), L3(패턴)
- L2 Construct 사용을 권장 — 보안 기본값이 내장되어 있음

### 자주 하는 실수
- `cdk bootstrap` 빼먹기 → 첫 배포 실패
- Stack 이름 변경 → 기존 리소스 삭제됨. 이름은 변경하지 말 것
- `cdk destroy`가 S3 버킷을 못 지움 → 버킷이 비어있어야 삭제 가능. `autoDeleteObjects: true` 설정

## CloudFormation

### 핵심 구조
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 설명

Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues: [dev, staging, prod]

Resources:
  # 여기에 AWS 리소스 정의

Outputs:
  # 배포 후 확인할 값
```

### 자주 하는 실수
- 스택 업데이트 시 리소스 교체(Replacement) 발생 → 변경 세트(Change Set)로 먼저 확인
- DeletionPolicy 미설정 → 스택 삭제 시 DB도 삭제됨. RDS에는 `DeletionPolicy: Snapshot` 필수
- 순환 참조 → Security Group 간 상호 참조 시 발생. Ingress 규칙을 별도 리소스로 분리

## IAM (Identity and Access Management)

### 초보자 필수 원칙

1. **루트 계정 사용 금지** — MFA 설정 후 잠금. IAM 사용자로 작업
2. **최소 권한 원칙** — 필요한 권한만 부여. `*`(전체 허용) 사용 금지
3. **그룹으로 권한 관리** — 사용자에게 직접 정책 붙이지 말 것
4. **역할(Role) 활용** — EC2, Lambda 등 서비스에는 역할을 사용

### 초보자 권장 IAM 구조
```
계정
├── Admins 그룹 (AdministratorAccess)
│   └── admin-user
├── Developers 그룹 (커스텀 정책)
│   ├── dev-user-1
│   └── dev-user-2
└── 서비스 역할
    ├── ec2-app-role (S3, DynamoDB 접근)
    └── lambda-exec-role (CloudWatch Logs)
```

### 자주 하는 실수
- Access Key를 코드에 하드코딩 → GitHub에 노출. 환경 변수 또는 역할 사용
- 과도한 권한 부여 후 축소 안 함 → IAM Access Analyzer로 미사용 권한 확인
- MFA 미설정 → 계정 탈취 위험. 최소 루트 + 관리자 계정에 MFA 필수

## 비용 관리

### 초보자 필수 설정
1. **AWS Budgets** — 월 예산 설정 (예: $50) + 80% 도달 시 이메일 알림
2. **Cost Explorer** — 서비스별 비용 추이 확인
3. **프리 티어 사용량 모니터** — Billing > Free Tier 대시보드

### 비용 폭탄 방지 체크리스트
- [ ] 미사용 EC2 인스턴스 → 종료(Terminate)
- [ ] 미연결 EBS 볼륨 → 삭제
- [ ] 미연결 탄력적 IP → 해제
- [ ] NAT Gateway → 개발 환경에서 제거
- [ ] CloudWatch Logs → 보존 기간 설정
- [ ] 미사용 RDS 스냅샷 → 삭제
