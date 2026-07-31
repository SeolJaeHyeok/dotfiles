## Skill Audit Context-Aware Checkers — 2026-05-11

**컨텍스트**: wellcheck-plugins issue #45 의 남은 static audit findings 70 건을 P4/P5/P6 로 해소했다.

**핵심 결정**: 문서 문구를 억지로 줄이는 대신 checker 의 문맥 인식을 먼저 고쳤다. `trigger_collision` 은 description 전체 ASCII token 이 아니라 명시 호출 phrase / `trigger_keywords` / skill name 만 비교하도록 좁혔다. `internal_ref_missing` 과 `version_drift` 는 fenced code block 안의 템플릿 placeholder 를 실제 참조로 보지 않게 했다.

**발견**: 남은 70 건 중 67 건은 실제 stale 문서가 아니라 checker 가 예시·템플릿·워크플로 공통어를 실제 런타임 계약으로 오인한 결과였다. PR #57 의 token_length reference 분리 패턴은 `wc-brainstorm`, `wc-execute`, `wc-compound` 에도 그대로 재사용 가능했다.

**실수**: 처음에는 feature-dev 규칙에 맞춰 docs/specs 문서를 만들었지만 이 레포의 `docs` 는 gitignore 대상이다. 이 프로젝트에서는 실작업 산출물과 공유 지식은 `CHANGELOG.md` / `~/.agents/knowledge` / GitHub issue 를 우선 사용해야 한다.

**다음 번엔**: audit checker 를 추가하거나 고칠 때 “본문 prose”, “명시 호출 trigger”, “fenced template/example”, “실제 링크/참조”를 먼저 구분한다. false positive 를 줄이려면 ignore rule 보다 checker 의 입력 도메인을 좁히는 쪽을 우선한다.
