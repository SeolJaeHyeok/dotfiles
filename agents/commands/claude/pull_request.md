# Claude Code 전역 지침 - Pull Request 생성

이 명령은 현재 브랜치의 변경사항을 분석하여 Pull Request(또는 Merge Request)를 생성합니다.

---

## 실행 순서

### 1단계: 기본 정보 수집

아래 명령을 병렬로 실행해 필요한 정보를 수집합니다.

```bash
# 현재 브랜치명
git branch --show-current

# 기본 브랜치 감지 (main 또는 master)
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'

# 원격 저장소 URL (플랫폼 판별용)
git remote get-url origin

# 베이스 브랜치 대비 커밋 목록
git log origin/main..HEAD --oneline 2>/dev/null || git log origin/master..HEAD --oneline

# 베이스 브랜치 대비 변경 파일 목록
git diff origin/main...HEAD --name-status 2>/dev/null || git diff origin/master...HEAD --name-status
```

---

### 2단계: 플랫폼 감지 및 CLI 도구 선택

`git remote get-url origin` 결과를 기반으로 판별합니다.

| 원격 URL 패턴 | 플랫폼 | CLI 도구 | 설치 확인 |
|-------------|--------|---------|---------|
| `github.com` | GitHub | `gh` | `gh --version` |
| `gitlab.com` / 자체 GitLab | GitLab | `glab` | `glab --version` |
| `bitbucket.org` | Bitbucket | `bb` (비공식) | 수동 안내 |
| 기타 | 알 수 없음 | 수동 안내 | — |

CLI 도구가 설치되지 않은 경우:
- GitHub: `brew install gh` 또는 https://cli.github.com 안내
- GitLab: `brew install glab` 또는 https://gitlab.com/gitlab-org/cli 안내
- 그 외: PR URL을 직접 안내하거나 웹 브라우저로 열 수 있는 URL 제공

---

### 3단계: 브랜치에서 이슈 번호 추출

브랜치명 패턴에서 티켓/이슈 번호를 추출합니다.

```
패턴 예시:
  feature/MCCWC-1234-login-page     → MCCWC-1234
  fix/PROJ-567-null-pointer          → PROJ-567
  feat/MCCWC-9999                    → MCCWC-9999
  123-add-feature                    → #123 (숫자만인 경우 GitHub issue)
  feature/add-login                  → 없음
```

추출된 티켓 번호는 PR 제목과 본문에 포함합니다.

---

### 4단계: PR 제목 및 본문 생성

수집한 커밋 목록과 변경 파일을 분석해 PR 제목과 본문을 작성합니다.

**제목 규칙:**
- 티켓 번호가 있는 경우: `[TICKET-ID] 변경사항 요약`
- 티켓 번호가 없는 경우: 커밋 메시지들을 기반으로 한 줄 요약

**본문 템플릿:**

```markdown
## 개요
<!-- 이 PR에서 변경된 내용을 간략히 설명합니다 -->
{변경사항 요약}

## 변경 사항
{변경 파일 및 커밋 기반 bullet point 목록}

## 테스트 체크리스트
- [ ] 로컬에서 정상 동작 확인
- [ ] 관련 기능 회귀 테스트 확인
- [ ] 엣지 케이스 검토

## 관련 이슈
{티켓 번호가 있으면: Closes [TICKET-ID] 또는 Related: [TICKET-ID]}
```

---

### 5단계: PR 생성 실행

**GitHub (`gh` CLI)**
```bash
gh pr create \
  --title "{PR 제목}" \
  --body "$(cat <<'EOF'
{PR 본문}
EOF
)" \
  --base {베이스 브랜치} \
  --head {현재 브랜치}
```

현재 브랜치가 원격에 push되지 않은 경우 먼저 push합니다:
```bash
git push -u origin {현재 브랜치}
```

**GitLab (`glab` CLI)**
```bash
glab mr create \
  --title "{PR 제목}" \
  --description "{PR 본문}" \
  --source-branch {현재 브랜치} \
  --target-branch {베이스 브랜치}
```

---

### 6단계: 결과 안내

PR 생성 성공 시:
- PR/MR URL을 출력합니다.
- 웹 브라우저에서 열 수 있는 링크를 제공합니다.

PR 생성 실패 시:
- 오류 원인을 분석해 안내합니다.
- 인증 문제라면 `gh auth login` 또는 `glab auth login` 실행을 안내합니다.
- CLI 도구가 없다면 수동으로 PR을 열 수 있는 웹 URL을 제공합니다.

---

## 판단 흐름 요약

```
/pull_request 실행
    │
    ├─ 현재 브랜치 == 베이스 브랜치? → 중단 (베이스 브랜치에서는 PR 불가)
    │
    ├─ 변경된 커밋이 없음? → 중단 (베이스 대비 차이 없음)
    │
    ├─ 이미 열린 PR이 있음? → 기존 PR URL 안내 후 중단
    │
    ├─ 플랫폼 감지
    │       ├─ GitHub → gh pr create
    │       ├─ GitLab → glab mr create
    │       └─ 기타   → 수동 URL 안내
    │
    ├─ 원격 push 여부 확인
    │       └─ push 안 됨 → git push -u origin {브랜치} 실행
    │
    └─ PR 생성 → URL 출력
```

---

## 주의사항

- `--force push`는 절대 실행하지 않습니다.
- 베이스 브랜치는 `main` → `master` → `develop` 순으로 탐색합니다.
- PR 본문은 한국어로 작성합니다 (프로젝트 컨벤션에 따라 조정).
- 민감한 정보(토큰, 비밀번호 등)가 변경사항에 포함된 경우 경고를 표시합니다.
