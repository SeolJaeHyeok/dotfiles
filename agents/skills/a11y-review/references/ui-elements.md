# UI 컴포넌트 접근성 패턴 (UI Elements)

> 코드에 해당 컴포넌트가 등장할 때만 lazy-load. 스펙 대비 누락 점검용.

---

## 모달 (Modal / Dialog)

**필수 ARIA:**
- HTML `<dialog>` + `showModal()` 1순위 (자동 최상위 스택, 포커스, ESC, 배경 비활성)
- 직접 구현 시: `role="dialog"` + `aria-modal="true"` + `aria-labelledby`(제목 id) 또는 `aria-label`
- 트리거 버튼에 `aria-haspopup="dialog"` 권장

**키보드:**
- `ESC`: 닫기
- `Tab` / `Shift+Tab`: 모달 내부에서만 순환 (focus trap)
- 열릴 때: 첫 포커스 가능 요소로 자동 포커스

**포커스 관리:**
- 열기 직전 트리거 ref 저장 → 닫을 때 `requestAnimationFrame`으로 복원
- 배경 콘텐츠는 `inert` 속성으로 비활성화

**흔한 실수:**
- `<dialog open>`나 `show()`로 열기 → 자동 기능 미적용. **반드시 `showModal()`**
- focus trap 미구현 (Tab이 배경으로 새어 나감)
- 닫힐 때 트리거로 포커스 복귀 안 됨
- 배경 스크롤·상호작용 미차단
- 제목 연결 누락 → "대화상자"라고만 읽힘

```tsx
const ref = useRef<HTMLDialogElement>(null);
return (
  <>
    <button aria-haspopup="dialog" onClick={() => ref.current?.showModal()}>모달 열기</button>
    <dialog ref={ref} aria-labelledby="modal-title">
      <h3 id="modal-title">다음에 다시 시도해 주세요</h3>
      <button onClick={() => ref.current?.close()}>확인</button>
    </dialog>
  </>
);
```

---

## 탭 (Tabs)

**필수 ARIA:**
- 컨테이너: `role="tablist"` + `aria-label`
- 각 탭: `role="tab"` + `aria-selected` + `id` + `aria-controls`(패널 id)
- 패널: `role="tabpanel"` + `id` + `aria-labelledby`(탭 id) + 비활성 시 `hidden`

**키보드:**
- `Tab`: tablist에 진입 → 활성 탭에만 포커스 (다른 탭 `tabIndex=-1`)
- `←` / `→`: 탭 사이 이동 + 선택 전환 (자동 활성)
- `Home` / `End`: 첫/마지막 탭

**포커스 관리:**
- 탭 그룹 전체를 `Tab` 한 번에 건너뛸 수 있어야 함 (roving tabindex)
- 비활성 패널은 반드시 `hidden`

**흔한 실수:**
- 탭들을 `<button>` 나열만 → 그룹·선택 상태 전달 안 됨
- `aria-controls` ↔ 패널 `id` 미연결
- 비활성 패널에 `hidden` 누락 → 모든 콘텐츠 낭독
- 화살표 키 네비게이션 미구현

```tsx
<div role="tablist" aria-label="메뉴">
  <button role="tab" id="home-tab" aria-selected={false} aria-controls="home-panel">홈</button>
  <button role="tab" id="feed-tab" aria-selected={true} aria-controls="feed-panel">피드</button>
</div>
<ul role="tabpanel" id="feed-panel" aria-labelledby="feed-tab">...</ul>
<ul role="tabpanel" id="home-panel" aria-labelledby="home-tab" hidden>...</ul>
```

---

## 아코디언 (Accordion)

**필수 ARIA:**
- 1순위: `<details>` + `<summary>` + `open` + `onToggle`
- 커스텀: 헤더 `<button>` + `aria-expanded` + `aria-controls`(패널 id), 패널 `role="region"` + `aria-labelledby`(버튼 id) + `hidden`

**키보드:**
- `Tab`: 헤더 버튼들로 이동
- `Enter` / `Space`: 토글
- 다중 패널 시: `↑`/`↓`/`Home`/`End` 헤더 간 이동

**포커스:** 패널이 열려도 포커스는 헤더에 그대로. `aria-expanded`와 패널 `hidden`은 **항상 동기화**.

**흔한 실수:**
- `<div onClick>`으로 헤더 + `aria-expanded` 누락
- `aria-expanded` 토글하는데 패널 `hidden` 갱신 안 함
- 헤더가 버튼이 아니어서 Enter/Space 동작 안 함

```tsx
// 권장
<details open={isOpen} onToggle={handleToggle}>
  <summary>한도제한계좌는 어떻게 해제할 수 있나요?</summary>
  <p>금융거래목적을 확인할 수 있는 증빙서류를 제출하여 ...</p>
</details>

// 커스텀
<button id="btn-1" aria-expanded={isOpen} aria-controls="panel-1" onClick={toggle}>
  한도제한계좌는 어떻게 해제할 수 있나요?
</button>
<div id="panel-1" role="region" aria-labelledby="btn-1" hidden={!isOpen}>...</div>
```

---

## 라디오 (Radio)

**필수 ARIA:**
- 그룹: `<fieldset>` + `<legend>` (1순위) 또는 `role="radiogroup"` + `aria-labelledby`
- 옵션: `<input type="radio" name="...">` — 동일 `name`이 그룹의 핵심
- 각 input에 `<label htmlFor>` + `id` 연결
- 커스텀: `role="radio"` + `aria-checked` + `tabIndex={0}` + Space

**키보드:**
- `Tab`: 라디오 그룹에 진입(선택된 옵션에 포커스) → 다음 Tab은 그룹 밖
- `←`/`↑`: 이전 옵션 + 선택
- `→`/`↓`: 다음 옵션 + 선택
- (커스텀) `Space`: 토글

**포커스:** 그룹 내 선택된 옵션 1개만 포커스 가능 (roving tabindex). 미선택 시 첫 옵션이 받음.

**흔한 실수:**
- 같은 그룹 옵션들이 다른 `name` → 다중 선택 가능
- `<fieldset>/<legend>` 없이 개별 input만
- `<label>` 미연결
- 커스텀 라디오에 `tabIndex` 미설정

```tsx
<fieldset>
  <legend>사용하실 국가를 선택해주세요</legend>
  <input type="radio" name="country" id="ko" defaultChecked />
  <label htmlFor="ko">대한민국</label>
  <input type="radio" name="country" id="au" />
  <label htmlFor="au">호주</label>
</fieldset>
```

---

## 체크박스 (Checkbox)

**필수 ARIA:**
- 1순위: `<input type="checkbox">` + `<label htmlFor>` + `id`
- 그룹: `<fieldset>` + `<legend>`
- 커스텀: `role="checkbox"` + `aria-checked` + `tabIndex={0}` + Space. 부분선택은 `aria-checked="mixed"`

**키보드:**
- `Tab`: 각 체크박스 개별 포커스
- `Space`: 토글

**포커스:** 라디오와 달리 화살표 이동 X — Tab으로만, 각각 독립 toggle.

**흔한 실수:**
- `<input>` 옆 단순 텍스트, `<label>` 미연결 → 클릭 영역 좁고 SR이 이름 못 읽음
- 그룹화 누락
- 커스텀에서 Space 핸들러 누락
- 부분선택을 boolean으로만 처리, `aria-checked="mixed"` 미사용

```tsx
<fieldset>
  <legend>수신 동의 설정</legend>
  <input type="checkbox" id="email" defaultChecked />
  <label htmlFor="email">이메일 수신 동의</label>
  <input type="checkbox" id="sms" />
  <label htmlFor="sms">문자 수신 동의</label>
</fieldset>
```

---

## 스위치 (Switch)

**필수 ARIA:**
- `role="switch"` (checkbox와 구별 — "선택됨/해제됨"이 아닌 "켜짐/꺼짐"으로 낭독)
- 상태: `<input>`이면 `checked`, 그 외 `aria-checked`
- 레이블: visible 텍스트 명확하면 추가 불필요. 외부 텍스트는 `aria-labelledby`, 아이콘만은 `aria-label`
- 커스텀: `tabIndex={0}` 필수

**키보드:**
- `Tab`: 포커스
- `Space`: 토글 (일부 패턴은 `Enter`도 허용)

**흔한 실수:**
- `<span>` + 토글 이미지만 → SR이 스위치로 인식 못 함
- `role="checkbox"`로 만들어 "선택됨/선택 해제됨"으로 낭독
- 외부 텍스트 레이블을 `aria-labelledby`로 연결 안 함
- 시각만 비활성, `aria-disabled`/`disabled` 누락

```tsx
<label>
  <input type="checkbox" role="switch" id="notification-switch" checked={isOn} hidden />
  <img src={`./toggle-icon-${isOn ? "on" : "off"}.png`} alt="" />
  알림 설정
</label>

// 커스텀
<span role="switch" aria-checked={isOn} tabIndex={0} aria-label="다크 모드">
  <img src="./toggle-icon.png" alt="" />
</span>
```
