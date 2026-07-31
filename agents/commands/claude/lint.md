# Claude Code 전역 지침 - Lint

## 사전 린트 작업 (Pre-Lint)

코드를 수정한 후에는 반드시 아래 절차에 따라 린트 및 타입 검사를 수행하고 오류를 수정해야 합니다.

---

### 1단계: 패키지 매니저 감지

프로젝트 루트의 lockfile을 확인해 패키지 매니저를 판별합니다.

| 파일 | 패키지 매니저 | run 명령 | exec 명령 |
|------|-------------|----------|----------|
| `bun.lockb` / `bun.lock` | bun | `bun run` | `bunx` |
| `pnpm-lock.yaml` | pnpm | `pnpm run` | `pnpm dlx` |
| `yarn.lock` | yarn | `yarn` | `yarn dlx` |
| `package-lock.json` | npm | `npm run` | `npx` |
| lockfile 없음 | npm (기본값) | `npm run` | `npx` |

---

### 2단계: 린트 실행

**JavaScript / TypeScript 프로젝트 (`package.json`이 존재하는 경우)**

`package.json`의 `scripts`를 확인해 아래 순서로 lint 명령을 선택합니다.

```
우선순위: lint > lint:check > lint:ci > eslint > check
```

스크립트가 존재하면:
```bash
{패키지매니저} {스크립트명}
# 예: yarn lint | pnpm run lint | bun run lint:check
```

스크립트가 없으면 설정 파일 기반으로 직접 실행합니다.

```bash
# Biome (biome.json 또는 .biome.json 존재 시)
npx @biomejs/biome check .

# ESLint (.eslintrc.* 또는 eslint.config.* 존재 시)
npx eslint --ext .ts,.tsx,.js,.jsx .

# 위 설정 파일도 없으면 lint 생략 (린터 미구성 프로젝트)
```

---

### 3단계: TypeScript 타입 체크

`tsconfig.json`이 존재하는 경우 반드시 실행합니다.

`package.json`의 `scripts`에서 아래 순서로 확인합니다.
```
우선순위: type-check > typecheck > tsc
```

스크립트가 존재하면:
```bash
{패키지매니저} {스크립트명}
# 예: yarn type-check | pnpm run typecheck
```

스크립트가 없으면 직접 실행합니다.
```bash
npx tsc --noEmit
```

---

### 4단계: 기타 언어 프로젝트

**Python** (`pyproject.toml` / `setup.py` / `requirements.txt` 존재 시)
```bash
# ruff가 설치된 경우 (우선)
ruff check .

# flake8이 설치된 경우
flake8 .

# 타입 체크
mypy . 2>/dev/null || true
```

**Go** (`go.mod` 존재 시)
```bash
go vet ./...
```

**Rust** (`Cargo.toml` 존재 시)
```bash
cargo clippy
```

---

### 판단 흐름 요약

```
코드 변경 완료
    │
    ├─ package.json 있음?
    │       ├─ YES → [패키지매니저 감지] → [lint 스크립트 있음?]
    │       │               ├─ YES → {pm} {lint-script}
    │       │               └─ NO  → [설정파일 감지] → 직접 실행 or 생략
    │       └─ NO  → 언어별 린터 실행 (Python/Go/Rust)
    │
    ├─ tsconfig.json 있음?
    │       ├─ YES → [type-check 스크립트 있음?]
    │       │               ├─ YES → {pm} {typecheck-script}
    │       │               └─ NO  → npx tsc --noEmit
    │       └─ NO  → 생략
    │
    └─ 오류 있음? → 수정 후 재실행 → 오류 없을 때까지 반복
```

---

### 주의사항

- lint/type-check 오류가 있으면 **반드시 수정**하고 재실행합니다.
- 자동 수정이 가능한 경우(`--fix`, `--write`) 적용 후 변경 사항을 확인합니다.
- lint 설정이 아예 없는 프로젝트라면 생략하고 사용자에게 알립니다.
- `node_modules`, `dist`, `.next`, `build` 등 빌드 산출물 디렉토리는 린트 대상에서 제외합니다.
