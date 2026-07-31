## Biome → ESLint 9 + Prettier 3 전환 — 2026-03-31

**컨텍스트**: cdp-web-react 프로젝트에서 Biome 기반 linting/formatting을 ESLint 9 (flat config) + Prettier 3으로 전환

**핵심 결정**:
- Biome의 `recommended: false` 설정에 맞춰 ESLint에서도 recommended preset을 사용하지 않고 12개 규칙만 명시적으로 매핑. 처음에 recommended를 포함했더니 937개 에러 발생 — 원래 Biome에서 의도적으로 끄고 있던 규칙들이었음
- `eslint-plugin-prettier` 대신 `eslint-config-prettier`로 충돌 방지만 하고 Prettier는 별도 실행
- `eslint-plugin-import` → `eslint-plugin-import-x`로 교체 (flat config 네이티브 지원)

**발견**:
- `.prettierrc`에 `jsxSingleQuote: true`가 누락되면 JSX 속성의 quote style이 바뀌어 대규모 diff 발생. Biome의 formatter 설정을 Prettier로 매핑할 때 `jsxSingleQuote`, `endOfLine`, `quoteProps`를 반드시 확인
- `@trivago/prettier-plugin-sort-imports`가 설치만 되고 `.prettierrc`의 `plugins` 배열에 미등록이라 dead code였음

**실수**:
- Biome 제거 후 pre-commit hook이 여전히 `biome check`를 참조하여 커밋 불가. Linting 도구 제거와 pre-commit hook 수정은 반드시 동시에 이루어져야 함 — 순차 커밋 불가

**다음 번엔**:
- `react-hooks/rules-of-hooks`가 `warn`으로 다운그레이드됨 (기존 24개 violations). 별도 작업으로 코드 수정 후 `error`로 복원 필요
- `@next/next/no-assign-module-variable`도 `warn`으로 다운그레이드됨. sendbirdCalls.ts 수정 필요
- 향후 커스텀 린트 규칙 작성 시 flat config 기반으로 진행 가능 (eslint.config.mjs에 규칙 추가)
