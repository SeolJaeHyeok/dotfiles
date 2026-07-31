# 디자인 토큰 설계 패턴

## 3계층 토큰 아키텍처

```
Global (원시값)  →  Semantic (의미)  →  Component (컴포넌트 전용)
blue-500: #3B82F6    primary: blue-500    button-bg-primary: primary
gray-900: #111827    text-default: gray-900
```

### 왜 3계층인가
- Global만 쓰면: `blue-500`이 버튼인지 링크인지 구분 불가, 다크모드 대응 불가
- Semantic까지: 대부분 충분. 컴포넌트 간 토큰 공유 가능
- Component까지: 대규모 시스템에서 컴포넌트 독립성 보장. 소규모면 과잉

## Tailwind + SCSS 토큰 통합 전략

### 원칙: Tailwind-first

```
tailwind.config.ts (단일 진실의 원천)
    ├── CSS 변수로 출력 → Tailwind 클래스에서 사용
    └── SCSS에서 CSS 변수 참조 → $var: var(--color-primary)
```

### tailwind.config.ts 예시
```typescript
import type { Config } from "tailwindcss"

const config: Config = {
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "var(--color-primary)",
          foreground: "var(--color-primary-foreground)",
        },
        secondary: {
          DEFAULT: "var(--color-secondary)",
          foreground: "var(--color-secondary-foreground)",
        },
        destructive: {
          DEFAULT: "var(--color-destructive)",
          foreground: "var(--color-destructive-foreground)",
        },
        muted: {
          DEFAULT: "var(--color-muted)",
          foreground: "var(--color-muted-foreground)",
        },
        accent: {
          DEFAULT: "var(--color-accent)",
          foreground: "var(--color-accent-foreground)",
        },
        border: "var(--color-border)",
        input: "var(--color-input)",
        ring: "var(--color-ring)",
        background: "var(--color-background)",
        foreground: "var(--color-foreground)",
      },
      borderRadius: {
        sm: "var(--radius-sm)",
        md: "var(--radius-md)",
        lg: "var(--radius-lg)",
      },
    },
  },
}
```

### CSS 변수 정의 (globals.css)
```css
:root {
  --color-background: 0 0% 100%;
  --color-foreground: 222 47% 11%;
  --color-primary: 221 83% 53%;
  --color-primary-foreground: 210 40% 98%;
  /* ... */
}

.dark {
  --color-background: 222 47% 11%;
  --color-foreground: 210 40% 98%;
  --color-primary: 217 91% 60%;
  /* ... */
}
```

### SCSS에서 참조 (Tailwind 미지원 시에만)
```scss
// 복잡한 애니메이션, mixin 등 Tailwind로 어려운 경우만
$transition-default: 150ms cubic-bezier(0.4, 0, 0.2, 1);
$focus-ring: 0 0 0 2px var(--color-background), 0 0 0 4px var(--color-ring);
```

## 색상 체계 설계

### Semantic Color 최소 세트

| 카테고리 | 토큰 | 용도 |
|---------|------|------|
| **Brand** | primary, primary-foreground | 주요 액션, CTA |
| **Brand** | secondary, secondary-foreground | 보조 액션 |
| **Feedback** | destructive, destructive-foreground | 삭제, 에러 |
| **Feedback** | success, success-foreground | 성공 |
| **Feedback** | warning, warning-foreground | 경고 |
| **Surface** | background, foreground | 페이지 배경/텍스트 |
| **Surface** | muted, muted-foreground | 비활성, 보조 텍스트 |
| **Surface** | accent, accent-foreground | 호버, 강조 배경 |
| **Border** | border, input, ring | 테두리, 포커스 링 |

### 다크 모드 설계 원칙
- 밝기만 뒤집지 말 것 — 채도와 밝기를 함께 조정
- 순수 검정(#000) 배경 피하기 — `gray-950`이나 `slate-950` 사용
- 그림자 대신 테두리로 elevation 표현

## 타이포그래피 스케일

### 권장 스케일 (Major Third, 1.25 비율)

| 토큰 | 크기 | 행간 | 용도 |
|------|------|------|------|
| text-xs | 12px | 16px | 캡션, 레이블 |
| text-sm | 14px | 20px | 보조 텍스트 |
| text-base | 16px | 24px | 본문 |
| text-lg | 18px | 28px | 소제목 |
| text-xl | 20px | 28px | 섹션 제목 |
| text-2xl | 24px | 32px | 페이지 제목 |
| text-3xl | 30px | 36px | 히어로 |

## 간격 스케일

### 4px 기반 스케일 (Tailwind 기본과 동일)

| 토큰 | 값 | 용도 |
|------|---|------|
| space-1 | 4px | 아이콘-텍스트 간격 |
| space-2 | 8px | 요소 내부 패딩 (sm) |
| space-3 | 12px | 요소 내부 패딩 (md) |
| space-4 | 16px | 요소 간 간격 |
| space-6 | 24px | 섹션 내부 간격 |
| space-8 | 32px | 섹션 간 간격 |
| space-12 | 48px | 대형 섹션 간격 |
| space-16 | 64px | 페이지 섹션 간격 |
