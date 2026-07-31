## Lambda 환경변수 필수화로 인한 프로덕션 장애 — 2026-03-31

**컨텍스트**: sentry-auto-fixer의 보안 강화 작업 중, `GITHUB_WEBHOOK_SECRET`을 기본 필수로 변경(커밋 `8644c6e`). Lambda 환경변수에 해당 값이 미설정된 상태에서 배포되어 전체 서비스 시작 실패.

**핵심 결정**: 변수명을 `APP_GITHUB_WEBHOOK_SECRET`으로 변경하여 프로젝트 컨벤션(`APP_GITHUB_*` prefix)에 맞춤. Lambda에는 사용자가 이미 해당 이름으로 설정 완료.

**실수**:
- `env.ts`에 필수 환경변수를 추가하면서 기존 컨벤션(`APP_GITHUB_*` → 커밋 `6c2a7d1`, `06aa946`에서 확립)을 무시하고 `GITHUB_WEBHOOK_SECRET`으로 명명
- Lambda 환경변수 설정 없이 코드만 배포하여 `process.exit(1)` → 전체 서비스 다운 (14:16~복구까지)

**발견**:
- `env.ts`의 zod 검증 실패는 `process.exit(1)`로 hard fail — Lambda에서는 모든 엔드포인트가 불능
- `validate-env.ts`(구 스키마)와 `env.ts`(현 스키마)가 공존하여 혼동 가능성 있음

**다음 번엔**:
1. `env.ts`에 필수 환경변수 추가 시 **반드시 Lambda 환경변수 동시 설정** (또는 ALLOW_UNSIGNED_WEBHOOKS 같은 우회 경로 제공)
2. 환경변수 네이밍은 기존 이력 확인: GitHub = `APP_GITHUB_*`, Sentry = `SENTRY_*`
3. 배포 전 `DEPLOYMENT.md`와 env 스키마 동기화 여부 확인
4. 장기적으로: deploy workflow에 env validation dry-run 추가 검토, `validate-env.ts` 중복 정리
