# Frontend Engineering — Autonomous AI Dev Workflow

> How to structure frontend projects so Claude Code can own implementation end-to-end.

---

## Why Frontend Is Different

Frontend has unique challenges for AI-driven development that backend doesn't:

| Challenge | Why It's Hard for AI | Mitigation |
|-----------|---------------------|------------|
| **Visual correctness** | Tests pass but UI looks wrong | Design tokens + visual regression + Storybook |
| **CSS/styling** | Infinite ways to achieve the same layout | Constrained design system, utility-first CSS |
| **State complexity** | UI state machines are implicit | Explicit state diagrams in specs |
| **Browser diversity** | Rendering varies across browsers/devices | CI matrix + responsive breakpoint specs |
| **Interactivity** | Click, drag, animation, gesture behaviors | E2E tests with interaction scripts |
| **Accessibility** | Semantic correctness isn't visible | Automated a11y audits as verification gate |

---

## FE-Specific Specification Layer

The generic workflow's L1 (Specification) needs FE-specific artifacts:

### 1. Component Spec

Define each component before Claude builds it:

```markdown
## Component: SearchBar

### Props
| Prop | Type | Default | Description |
|------|------|---------|-------------|
| placeholder | string | "Search..." | Input placeholder text |
| onSearch | (query: string) => void | required | Callback on submit |
| debounceMs | number | 300 | Debounce delay |

### States
- **idle** — Empty input, no results
- **typing** — User is typing, debounce active
- **loading** — Search request in flight
- **results** — Results displayed below
- **error** — Search failed, show retry
- **empty** — Search succeeded, zero results

### Behavior
- GIVEN idle state WHEN user types THEN transition to typing
- GIVEN typing state WHEN debounce expires THEN call onSearch, transition to loading
- GIVEN loading state WHEN results return THEN transition to results or empty
- GIVEN any state WHEN user clears input THEN transition to idle

### Accessibility
- Role: search landmark
- Input: aria-label, aria-autocomplete
- Results: aria-live="polite"
```

### 2. Screen State Machine

Every screen/page gets an explicit state diagram:

```
                    ┌─────────┐
        ┌──────────│ Loading  │
        │          └────┬─────┘
        │               │ data loaded
        │               ▼
        │          ┌─────────┐    filter/sort    ┌──────────┐
        │          │  Ready  │──────────────────▶│ Updating │
        │          └────┬─────┘                   └─────┬────┘
        │               │                               │
        │               │ error                         │ done
        │               ▼                               │
        │          ┌─────────┐                          │
        └─────────▶│  Error  │◀─────────────────────────┘
                   └─────────┘
```

This prevents the #1 FE bug: undefined states where the UI shows stale data or broken layouts.

### 3. Design Token Contract

Claude must never freestyle styles. All visual decisions come from tokens:

```typescript
// tokens.ts — THE source of truth
export const tokens = {
  color: {
    primary: '#2563EB',
    error: '#DC2626',
    text: { primary: '#111827', secondary: '#6B7280' },
    bg: { page: '#FFFFFF', surface: '#F9FAFB', overlay: 'rgba(0,0,0,0.5)' },
  },
  spacing: { xs: '4px', sm: '8px', md: '16px', lg: '24px', xl: '32px' },
  radius: { sm: '4px', md: '8px', lg: '16px', full: '9999px' },
  fontSize: { sm: '14px', md: '16px', lg: '20px', xl: '24px', '2xl': '32px' },
  shadow: {
    sm: '0 1px 2px rgba(0,0,0,0.05)',
    md: '0 4px 6px rgba(0,0,0,0.1)',
  },
  breakpoint: { sm: '640px', md: '768px', lg: '1024px', xl: '1280px' },
} as const;
```

**Rule:** If a value doesn't exist in tokens, Claude must ask — not invent.

---

## FE-Specific Verification Layer

Standard verification (typecheck + lint + test + build) is necessary but insufficient for FE. Add these tiers:

### Tier 1: Code Quality (same as generic)
```bash
tsc --noEmit                    # Type check
eslint . --max-warnings 0       # Lint
```

### Tier 2: Component Isolation
```bash
npx storybook build             # All stories render without error
npx chromatic --exit-zero-on-changes  # Visual regression baseline
```

### Tier 3: Behavioral Tests
```bash
npx jest --coverage             # Unit + integration tests
npx playwright test             # E2E interaction tests
```

### Tier 4: Visual + Accessibility
```bash
npx playwright test --project=visual  # Screenshot comparison tests
npx axe-core .                        # Accessibility audit
npx lighthouse --preset=desktop       # Performance audit
```

### Verification Gate Summary

| Gate | Tool | Blocks Commit? |
|------|------|---------------|
| Type check | `tsc` | Yes |
| Lint | `eslint` | Yes |
| Unit tests | `jest` / `vitest` | Yes |
| Build | `next build` / `vite build` | Yes |
| E2E tests | `playwright` | Yes |
| Visual regression | `chromatic` / `playwright screenshots` | Yes |
| Accessibility | `axe-core` | Yes |
| Performance | `lighthouse` | No (advisory) |

---

## Component-Driven Development Loop

The execution loop for FE work follows a specific order:

```
1. Read component spec
2. Write test file (unit + interaction tests)
3. Write Storybook story (all states)
4. Implement component (tests must pass)
5. Add to page/screen integration
6. Run full verification gate
7. Commit
```

This order ensures:
- **Tests before code** — TDD prevents over-engineering
- **Stories before integration** — Components are validated in isolation
- **Integration last** — Wiring happens after the unit works

---

## Responsive & Cross-Browser Strategy

### Spec Format for Responsive Behavior

```markdown
## Screen: ProductList

### Breakpoint Behavior
| Breakpoint | Layout | Cards/Row | Sidebar |
|-----------|--------|-----------|---------|
| < 640px (sm) | Stack | 1 | Hidden, hamburger menu |
| 640-1024px (md) | Grid | 2 | Collapsed |
| > 1024px (lg) | Grid | 3-4 | Visible |

### Critical Interactions by Device
- **Mobile:** Pull-to-refresh, swipe to dismiss, bottom sheet filters
- **Desktop:** Hover states, keyboard navigation, sticky header
```

### Verification

Playwright tests run against multiple viewports:

```typescript
const viewports = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1440, height: 900 },
];

for (const vp of viewports) {
  test(`product list renders correctly on ${vp.name}`, async ({ page }) => {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto('/products');
    await expect(page).toHaveScreenshot(`product-list-${vp.name}.png`);
  });
}
```

---

## State Management Patterns for AI

Claude works best with explicit, predictable state. Recommended patterns:

| Pattern | When to Use | Why AI-Friendly |
|---------|------------|-----------------|
| **URL as state** | Filters, pagination, tabs | Deterministic — URL encodes full state |
| **React Query / SWR** | Server data | Cache logic is declarative, not hand-written |
| **useReducer + context** | Complex local state | Reducer is a pure function — easy to test |
| **Zustand** | Shared client state | Minimal boilerplate, explicit actions |

**Anti-patterns to avoid:**
- Implicit state derived from multiple sources
- State that requires reading multiple files to understand
- Event-driven state that can't be reproduced from a snapshot

---

## FE-Specific Recovery Patterns

Common FE failures and how Claude should handle them:

| Failure | Auto-Fix Strategy |
|---------|-------------------|
| Hydration mismatch | Move dynamic content to `useEffect` / `client` boundary |
| Layout shift (CLS) | Add explicit width/height to images, skeleton placeholders |
| Missing responsive style | Check breakpoint spec, add missing media query |
| Failed visual regression | Compare screenshots, check if intentional, update baseline or fix |
| a11y violation | Map violation to ARIA fix (e.g., missing label → add aria-label) |
| Bundle size regression | Run `next build --analyze`, identify and fix the import |

---

## Recommended FE Stack for AI-Driven Development

Stacks that maximize Claude's effectiveness:

| Layer | Recommended | Why |
|-------|------------|-----|
| Framework | Next.js (App Router) | File-based routing = less wiring code |
| Styling | Tailwind CSS | Utility classes = constrained design, no CSS files to manage |
| Components | Radix UI / shadcn/ui | Accessible primitives, AI can compose them |
| State | React Query + Zustand | Declarative server state + minimal client state |
| Testing | Vitest + Playwright | Fast unit tests + reliable E2E |
| Visual | Storybook + Chromatic | Component isolation + visual regression |
| a11y | axe-core + eslint-plugin-jsx-a11y | Automated accessibility verification |

**Why this stack:** Every choice reduces the surface area where Claude can make subjective or wrong decisions. Tailwind constrains styling. Radix handles a11y. React Query handles caching. The less Claude has to invent, the more reliable the output.

---

## Templates

FE-specific templates are in `templates/`:

- [`COMPONENT_SPEC.md.template`](./templates/COMPONENT_SPEC.md.template) — Component definition with props, states, behavior
- [`SCREEN_SPEC.md.template`](./templates/SCREEN_SPEC.md.template) — Page/screen state machine and responsive behavior
- [`DESIGN_TOKENS.md.template`](./templates/DESIGN_TOKENS.md.template) — Design token contract

---

## Relationship to Main Workflow

This is **not** a replacement for the [main workflow](../docs/workflow.md). It's an addendum:

- L1 (Specification): Add component specs, screen state machines, design tokens
- L2 (Context): Same — CLAUDE.md + HANDOFF.md
- L3 (Execution): Use component-driven loop instead of generic loop
- L4 (Verification): Add visual regression + a11y + responsive gates
- L5 (Recovery): Add FE-specific auto-fix patterns
