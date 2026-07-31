# 의미 (Semantic) — 핵심 원칙

> 인터랙티브 요소가 "무엇인지·무엇을 하는지"를 시각이 아닌 접근성 트리에서도 동일하게 전달되도록 마크업한다. 스크린 리더가 읽는 이름(accessible name)이 비어 있거나, 같은 이름이 여러 번 반복돼 맥락을 잃지 않게.

**Accessible name 우선순위:** `aria-labelledby` > `aria-label` > `<label for>` > `placeholder` > 내부 텍스트. (`<img>`는 `alt`)

---

## 1. 인터랙티브 요소에는 반드시 접근 가능한 이름(label)을 붙인다

**안티패턴:**
- `<input type="text" />`처럼 라벨 자체가 없음
- `<input placeholder="이름을 입력하세요" />`처럼 placeholder만으로 라벨 대체
- 텍스트 없는 아이콘 버튼(`<button><svg/></button>`)에 `aria-label` 누락

**접근성 영향:**
- 모든 라벨이 비면 SR이 "편집(edit)" 또는 "버튼"으로만 읽어 필드 목적 모름
- placeholder는 구형 SR이 인식 못 하고, 입력 시작 시 사라져 사용자가 목적을 잊음
- 저시력 사용자에게는 placeholder의 낮은 대비도 문제

**원칙:**
- 시각적 라벨이 있으면 `<label for>` + `id`로 명시 연결
- 디자인상 라벨을 못 보일 때만 `aria-label`
- 페이지의 다른 시각 요소가 라벨 역할이면 `aria-labelledby`
- placeholder는 라벨 대체재가 아닌 보조(예시값) 수단

**예시:**
```html
<!-- ❌ -->
<input type="text" placeholder="이름을 입력하세요" />
<button><svg/></button>

<!-- ✅ -->
<label for="user-name">이름</label>
<input id="user-name" type="text" placeholder="예: 홍길동" />

<button aria-label="닫기"><svg aria-hidden="true"/></button>
```

**리뷰 시그널:**
- `<input>`/`<select>`/`<textarea>`인데 형제로 `<label htmlFor>`가 없음
- `placeholder`만 있고 라벨이 없음
- `IconButton`·아이콘만 든 `<button>`에 `aria-label`/자식 텍스트 부재
- `<label>` 안에 `for`/`htmlFor` 없거나 입력 요소를 감싸지도 않음
- 아이콘 `<svg>`에 `aria-hidden="true"` 없어 라벨이 중복 낭독

---

## 2. 같은 이름의 인터랙티브 요소가 반복되면 맥락을 덧붙인다

**안티패턴:** 리스트 카드마다 `<button>선택</button>`, `<button>자세히 보기</button>`, `<a>더보기</a>`처럼 동일 라벨이 반복. 시각적으론 옆 텍스트로 맥락이 보이지만, 마크업상으론 어떤 항목인지 연결 안 됨.

**접근성 영향:** SR rotor/요소 목록 탐색 시 "선택, 버튼 / 선택, 버튼 / 선택, 버튼"으로만 들려 어떤 항목의 선택인지 구별 불가. 시각 사용자는 근접성으로 알지만 SR 사용자는 매번 항목으로 되돌아가 다시 읽어야 함.

**원칙:**
- 시각 텍스트는 그대로 두고 항목명을 포함한 accessible name 추가
- `aria-label`로 덮어쓸 때는 시각 텍스트("선택")를 포함한 풀 문장("종이를 사용할 경우에 선택")으로 — **음성 입력 사용자가 보이는 라벨로 명령할 수 있게**
- 가능하면 `aria-labelledby`로 항목 제목 id와 버튼 id를 함께 참조해 시각/접근 텍스트 일치

**예시:**
```html
<!-- ❌ -->
<li><h3>종이를 사용할 경우</h3><button>선택</button></li>
<li><h3>연필을 사용할 경우</h3><button>선택</button></li>

<!-- ✅ aria-label -->
<button aria-label="종이를 사용할 경우에 선택">선택</button>

<!-- ✅✅ aria-labelledby (시각 텍스트 보존) -->
<li>
  <h3 id="paper-title">종이를 사용할 경우</h3>
  <button id="paper-btn" aria-labelledby="paper-title paper-btn">선택</button>
</li>
```

**리뷰 시그널:**
- `.map()` 내부에서 동일 정적 문자열 버튼/링크 반복 (`선택`, `삭제`, `자세히 보기`, `Edit`)
- 카드/행 컴포넌트의 CTA가 항목명을 prop으로 안 받음
- `aria-label`이 시각 텍스트를 무시하고 완전히 다른 문장으로 덮어씀 (음성 입력 깨짐)
- 같은 페이지에 동일 텍스트 링크 여러 개인데 `aria-label`/`aria-labelledby` 부재
- 테이블 행별 액션 버튼이 행 식별자 없이 모두 같은 라벨
