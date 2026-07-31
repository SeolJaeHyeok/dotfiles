## EduConsulSend ref→Zustand 마이그레이션 — 2026-03-30

**컨텍스트**: EduConsulSend 교육 자료 발송 플로우에서 useImperativeHandle/ref 3단 체인(useEducation → EduConsulSend → EduConsulModal)을 Zustand 단일 스토어로 대체하는 리팩토링.

**핵심 결정**: Zustand 단일 스토어 채택 — 프로젝트 기존 패턴(createStore + actions)과 일관, DevTools 디버깅 가능. Compound Component(기존 사례 없음)과 Props Drilling(페이지 비대화)은 기각.

**발견**: `useState` → Zustand 마이그레이션 시 상태 소멸 타이밍이 다르다. `useState`는 setter 호출 후 같은 렌더 사이클 내에서 이전 값을 유지하지만, Zustand `set`은 즉시 스토어 상태를 변경한다. 기존에 `dispatchShow(false)` 후 `onClear()`를 호출해도 `eduData`가 살아있었지만, `closeModal()`은 `isVisible`과 `data`를 동시에 null로 초기화하므로 `onClear` 실행 시 `eduData`가 이미 소멸한다.

**실수**: `dispatchShow(false)` → `closeModal()`로 1:1 치환 시, 기존 함수가 `isShow`만 변경하고 `eduData`는 유지하는 반면 새 함수는 두 상태를 동시에 초기화한다는 차이를 간과했다. 원칙: **기존 setter를 스토어 액션으로 치환할 때, setter가 변경하는 상태 범위와 액션이 변경하는 상태 범위가 일치하는지 반드시 확인할 것.**

**다음 번엔**:
- `dayjs().isSame()` 호출에 `'day'` granularity 누락 — `eduCount`와 `firstCnslCd`가 항상 잘못된 값. 별도 수정 필요.
- `eduCount > 2` → `>= 2`로 off-by-one 수정 필요.
- Zustand 스토어가 전역 싱글톤이므로 `patientEducation` 페이지에서 환자 전환 시 `resetAll` 호출 필수.
