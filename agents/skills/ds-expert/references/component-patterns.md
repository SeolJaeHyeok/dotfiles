# 컴포넌트 설계 패턴

## Compound Component 패턴

복잡한 컴포넌트를 작은 하위 컴포넌트로 분리하여 유연한 조합을 가능하게 한다.

```tsx
// 사용 예시
<Select>
  <Select.Trigger>
    <Select.Value placeholder="선택하세요" />
  </Select.Trigger>
  <Select.Content>
    <Select.Item value="1">옵션 1</Select.Item>
    <Select.Item value="2">옵션 2</Select.Item>
  </Select.Content>
</Select>
```

### 구현 패턴
```tsx
const SelectContext = createContext<SelectContextValue | null>(null)

function Select({ children, value, onValueChange }: SelectProps) {
  const [open, setOpen] = useState(false)
  return (
    <SelectContext value={{ value, onValueChange, open, setOpen }}>
      <div className="relative">{children}</div>
    </SelectContext>
  )
}

Select.Trigger = function Trigger({ children }: { children: ReactNode }) {
  const { setOpen } = use(SelectContext)!
  return <button onClick={() => setOpen(prev => !prev)}>{children}</button>
}
// ...
```

### 언제 사용하나
- 내부 구조를 사용자가 제어해야 할 때 (순서 변경, 일부 생략)
- 3개 이상의 하위 요소가 있을 때
- Boolean props가 3개 이상 필요해질 때 → Compound로 전환

## cva (class-variance-authority) 패턴

variant 기반 스타일링의 표준 패턴.

```typescript
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const badgeVariants = cva(
  // 기본 클래스 (모든 variant에 공통)
  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground",
        secondary: "bg-secondary text-secondary-foreground",
        destructive: "bg-destructive text-destructive-foreground",
        outline: "border border-input text-foreground",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />
}
```

## cn 유틸리티

Tailwind 클래스를 조건부 병합하고, 충돌을 해결한다.

```typescript
// lib/utils.ts
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

## 컴포넌트 카테고리 및 우선순위

### Tier 1: 기초 (모든 시스템에 필수)
| 컴포넌트 | 역할 |
|---------|------|
| Button | 액션 트리거 |
| Input | 텍스트 입력 |
| Label | 폼 레이블 |
| Badge | 상태/카운트 표시 |
| Separator | 구분선 |

### Tier 2: 폼 (데이터 입력)
| 컴포넌트 | 역할 |
|---------|------|
| Select | 드롭다운 선택 |
| Checkbox | 다중 선택 |
| Radio | 단일 선택 |
| Switch | 토글 |
| Textarea | 다중행 입력 |

### Tier 3: 피드백/오버레이
| 컴포넌트 | 역할 |
|---------|------|
| Dialog/Modal | 모달 대화상자 |
| Toast | 알림 메시지 |
| Tooltip | 호버 설명 |
| Alert | 인라인 알림 |
| Popover | 팝오버 컨텐츠 |

### Tier 4: 레이아웃/네비게이션
| 컴포넌트 | 역할 |
|---------|------|
| Tabs | 탭 네비게이션 |
| Accordion | 접기/펼치기 |
| Table | 데이터 테이블 |
| Card | 컨텐츠 카드 |
| Pagination | 페이지 네비게이션 |

## 접근성 체크리스트 (컴포넌트별)

### Button
- [ ] `role="button"` (비-button 요소 사용 시)
- [ ] `aria-disabled` (disabled 상태)
- [ ] `aria-pressed` (토글 버튼)
- [ ] 포커스 링 visible
- [ ] Enter/Space로 활성화

### Input
- [ ] `<label>` 연결 (htmlFor)
- [ ] `aria-required` (필수 입력)
- [ ] `aria-invalid` + `aria-describedby` (에러 상태)
- [ ] 에러 메시지가 스크린 리더에 전달

### Dialog
- [ ] `role="dialog"` + `aria-modal="true"`
- [ ] `aria-labelledby` (제목 연결)
- [ ] 포커스 트랩 (열림 시 내부에 포커스 가둠)
- [ ] Escape로 닫기
- [ ] 닫힘 시 트리거 요소로 포커스 복귀

### Select
- [ ] `role="listbox"` + `role="option"`
- [ ] 키보드: 화살표 이동, Enter 선택, Escape 닫기
- [ ] `aria-expanded` (열림/닫힘 상태)
- [ ] `aria-selected` (선택된 항목)
