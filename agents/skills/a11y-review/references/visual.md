# 시각 정보 보완 (Visual) — 핵심 원칙

> 카테고리 정의: 시각으로만 전달되는 정보(이미지·아이콘·도형·색)를 텍스트 대안으로 보완해, 화면을 보지 못하거나 시각 정보를 충분히 인지하지 못하는 사용자도 동일한 정보·기능에 도달하도록 한다.

---

## 1. 이미지와 아이콘에 적절한 대체 텍스트

**안티패턴:**
- 의미 있는 아이콘 버튼인데 `alt=""`로 비움 (`<button><img src="search-icon.svg" alt="" /></button>`)
- 장식용 이미지에 굳이 설명 (`<img src="divider.png" alt="구분선" />`)
- `figcaption`과 `alt` 동일 문구로 중복
- 텍스트 옆 아이콘에 alt가 또 있어 두 번 낭독 ("삭제 아이콘 삭제")
- 맥락 무시한 동일 alt (`alt="화살표"` 두 개 — 이전/다음 구분 불가)
- "아이콘", "버튼", "이미지" 같은 메타 단어 포함 (SR이 이미 `<img>`임을 알림)

**접근성 영향:**
- 빈 alt인 아이콘 버튼은 "버튼"으로만 읽혀 기능 파악 불가
- 중복 alt는 같은 문장 2번 듣게 해 인지 부하·탐색 시간 증가
- 동일 alt 화살표는 페이지 내 위치/방향 구분 불가
- 깨진 이미지·로딩 실패 시 alt가 fallback 텍스트로 노출되지 않으면 정보 손실

**개선 원칙:**
- **의미 있는 이미지(정보·기능 전달):** 구체적 alt. 액션을 설명하라 — "검색"(○) / "검색 아이콘"(×)
- **장식용 이미지(구분선·배경 패턴):** `alt=""` 명시적 비움. 속성 자체를 빼면 일부 SR이 파일명 낭독
- **주변에 동일 정보가 텍스트로 있을 때:** `alt=""` (figcaption·옆 텍스트가 역할 담당)
- **같은 이미지라도 맥락이 다르면 alt도 달라야** (이전/다음 화살표)
- **SVG 인라인 아이콘:** `<svg role="img" aria-label="검색">` 또는 부모 버튼에 `aria-label`. 장식용 SVG는 `aria-hidden="true"` + `focusable="false"`
- **아이콘 전용 버튼:** `<button aria-label="삭제">`로 접근 가능한 이름 보장
- **CSS `background-image`로 표시되는 의미 있는 이미지:** SR이 못 읽음 → 의미 있다면 `<img>`로 바꾸거나 `.sr-only` 텍스트 제공

**예시:**
```html
<!-- 패턴 1: 아이콘 전용 버튼 -->
<!-- ❌ -->
<button><img src="search-icon.svg" alt="" /></button>
<!-- ✅ -->
<button><img src="search-icon.svg" alt="검색" /></button>
<!-- ✅ 인라인 SVG -->
<button aria-label="검색">
  <svg aria-hidden="true" focusable="false"><!-- ... --></svg>
</button>

<!-- 패턴 2: 캡션이 있는 이미지 (중복 제거) -->
<!-- ❌ -->
<figure>
  <img src="product.jpg" alt="신제품 스마트폰" />
  <figcaption>신제품 스마트폰</figcaption>
</figure>
<!-- ✅ -->
<figure>
  <img src="product.jpg" alt="" />
  <figcaption>신제품 스마트폰</figcaption>
</figure>

<!-- 패턴 3: 텍스트 옆 장식 아이콘 -->
<!-- ❌ -->
<button><img src="trash-icon.svg" alt="삭제 아이콘" /> 삭제</button>
<!-- ✅ -->
<button><img src="trash-icon.svg" alt="" /> 삭제</button>

<!-- 패턴 4: 맥락별 다른 alt -->
<!-- ❌ -->
<a href="/prev"><img src="arrow.png" alt="화살표" /></a>
<a href="/next"><img src="arrow.png" alt="화살표" /></a>
<!-- ✅ -->
<a href="/prev"><img src="arrow.png" alt="이전 페이지로 이동" /></a>
<a href="/next"><img src="arrow.png" alt="다음 페이지로 이동" /></a>

<!-- 패턴 5: 의미 있는 정보를 배경 이미지로 넣지 말 것 -->
<!-- ❌ -->
<div class="badge" style="background-image: url('new.png')"></div>
<!-- ✅ -->
<div class="badge"><img src="new.png" alt="신상품" /></div>
<!-- 또는 -->
<div class="badge" style="background-image: url('new.png')">
  <span class="sr-only">신상품</span>
</div>
```

**리뷰 시그널 (체크리스트):**
- `<img>`에 `alt` 속성 **존재**? (없으면 파일명을 읽음 — 빈 값이라도 명시)
- 아이콘 전용 클릭 가능 요소(`button`, `a`)에 **접근 가능한 이름**(alt / aria-label / 텍스트)?
- alt에 "아이콘", "이미지", "버튼", "그림" 같은 **메타 단어** 포함? — 제거 후보
- 인접한 `figcaption`·라벨·본문 텍스트와 alt가 **중복**? (중복이면 `alt=""`)
- 텍스트와 함께 쓰인 아이콘은 `alt=""` 또는 `aria-hidden="true"`?
- 동일 이미지 자산이 여러 위치에서 쓰일 때 **맥락별 다른 alt**?
- 인라인 SVG: 의미 있을 때 `role="img"` + `aria-label`/`<title>`, 장식일 때 `aria-hidden="true"` + `focusable="false"`?
- **의미 전달이 필요한 이미지**가 `background-image`로만 그려져 SR에서 사라지지 않음?
- alt 문구가 **외형이 아니라 기능/의도**를 설명? ("아래 화살표"× / "메뉴 열기"○)
- 색상/아이콘 모양만으로 상태 구분(빨간 점 = 오류 등)할 때 텍스트 라벨/`aria-label` 동반?
