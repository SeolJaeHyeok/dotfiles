# 접근성 기초 (Foundation)

> 모든 a11y 리뷰어가 항상 로드. ARIA 어휘 룩업.

---

## 역할 (Role)

**정의:** UI 컴포넌트가 어떤 의미·기능을 하는지를 SR에 알려주는 속성. HTML 시맨틱 요소(`<button>`, `<input>`, `<a>`)는 기본 role을 내장. `<div>`로 커스텀하거나 표준 요소가 없을 때(탭, 스위치 등) ARIA `role` 명시.

**주요 role:**

| 컴포넌트 | HTML 시맨틱 | ARIA role |
|---|---|---|
| 입력창 | `<input>` | `textbox` |
| 체크박스 | `<input type="checkbox">` | `checkbox` |
| 라디오 | `<input type="radio">` | `radiogroup` + `radio` |
| 링크 | `<a>` | `link` |
| 버튼 | `<button>` | `button` |
| 다이얼로그 | `<dialog>` | `dialog` |
| 아코디언 | `<details>` + `<summary>` | (panel) `region` |
| 탭 | — | `tablist` + `tab` + `tabpanel` |
| 스위치 | — | `switch` |

**HTML 시맨틱 vs ARIA (우선순위):**
1. **HTML 시맨틱 우선** — 키보드 동작·포커스·상태가 무료로 따라옴
2. 시맨틱 요소를 못 쓸 때만 `role="..."` + `tabIndex={0}` + 키보드 핸들러 직접 구현

**흔한 실수:**
- `<div onClick>` 버튼 + role 누락 → SR이 그냥 텍스트로 읽음
- 탭을 단순 `<button>` 나열로만 만들어 `tablist`/`tab`/`tabpanel` 그룹화 빠짐
- `<input type="checkbox">`에 `role="checkbox"` 중복 (불필요)
- 라디오 그룹에 `role="radiogroup"`/`<fieldset>` 없이 개별 `role="radio"`만

---

## 레이블 (Label)

**정의:** 요소의 **접근 가능한 이름(accessible name)** — SR이 "이게 뭐냐"를 읽을 때 쓰는 텍스트.

**Label 제공 방법 (우선순위):**
1. **`<label htmlFor>` + `id`** — 폼 컨트롤의 표준 연결
2. **`aria-labelledby`** — 다른 가시 요소(제목)의 `id` 참조
3. **`aria-label`** — 아이콘 버튼처럼 visible text가 없을 때
4. **visible text content** — 버튼·링크 내부 텍스트
5. **`<img alt>`** — 이미지의 의미가 정보일 때. 장식용은 `alt=""`

**컴포넌트 유형별 패턴:**
- 입력창: `<label>` 또는 `aria-label`. 카드번호처럼 여러 칸은 `<fieldset><legend>`로 묶고 각 input에 `aria-label`
- 아이콘 버튼: `aria-label="검색"`, `aria-label="지난 달"`
- 이미지: 정보 전달용은 `alt`에 의미, 장식용은 `alt=""`
- 그래픽(차트/프로그레스): 현재 상태·수치를 `aria-label`로
- 선택형(체크박스/라디오/스위치): `<label>` 또는 `aria-label`

**흔한 실수:**
- 아이콘 버튼에 `aria-label` 없음 → "버튼, 버튼"
- visible 텍스트 있는데 `aria-label`을 다른 문구로 덮어씀 (혼란)
- 장식 이미지에 `alt`를 비우지 않고 파일명이 읽힘
- 입력창에 `placeholder`만 있고 `<label>` 없음
- 댓글 아이콘+숫자 버튼에서 숫자만 노출 → `aria-label={\`댓글 총 ${n}개\`}`

---

## 상태 (State)

**정의:** 컴포넌트의 현재 동작 상태(켜짐/꺼짐, 펼침/접힘, 선택/비선택, 활성/비활성)를 SR에 알려주는 `aria-*` 속성.

**주요 state:**

| 속성 | 의미 | 적용 예시 | 네이티브 |
|---|---|---|---|
| `aria-checked` | 체크 여부 | 체크박스, 스위치, 커스텀 라디오 | `<input checked>` |
| `aria-selected` | 선택된 항목 | 탭, 리스트박스 옵션 | `<option selected>` |
| `aria-expanded` | 펼침/접힘 | 아코디언, 드롭다운, 콤보박스 | `<details open>` |
| `aria-disabled` | 비활성화 | 버튼, 링크, 스위치 | `<button disabled>` |
| `aria-pressed` | 토글 버튼 눌림 | 토글 버튼 | — |
| `aria-current` | 현재 위치 | nav 현재 페이지(`page`), 달력 오늘(`date`) | — |
| `aria-busy` | 로딩/갱신 중 | 로딩 컴포넌트 | — |
| `aria-live` | 동적 업데이트 알림 | 에러·알림·로딩 메시지 | — |

**`aria-live` 값:**
- `polite` — 현재 낭독 끝나면 읽음 (검증/업데이트)
- `assertive` — 즉시 끊고 읽음 (오류·연결 끊김)
- `off` — 알리지 않음
- 동치: `role="alert"` ≡ `aria-live="assertive"`, `role="status"` ≡ `aria-live="polite"`

**코드 표현 (네이티브 vs ARIA):**
```tsx
// 네이티브 우선
<input type="checkbox" checked={true} />
<details open={true}><summary>...</summary></details>
<button disabled={true}>비활성화</button>

// 커스텀일 때만 ARIA
<span role="checkbox" aria-checked={true} tabIndex={0} />
<button aria-expanded={true}>펼침</button>
<div role="switch" aria-checked={false} aria-disabled={true} tabIndex={0} />
```

**흔한 실수:**
- `aria-expanded`는 토글했는데 패널 `hidden`은 안 바꿈 → 시각/SR 상태 어긋남. **두 값은 항상 동기화**
- 비활성 버튼을 CSS만 흐리게 처리하고 `aria-disabled`/`disabled` 누락
- 탭에 `aria-selected`만 주고 비활성 패널을 `hidden`으로 안 숨김 → SR이 모든 패널 낭독
- `aria-live="assertive"` 남발
- `<input>`에 이미 `checked`인데 `aria-checked` 또 지정 (충돌)
- 네비 현재 페이지에 `aria-current="page"` 누락
