# E2E Automated Frontend Development — System Proposal

**Author:** Michael Zuo | **Date:** 2026-03-10 | **Status:** Draft — Feasibility Review

---

## System Overview

An end-to-end system where **Figma designs flow into production-ready frontend code** through a fully automated pipeline. Designers work in Figma. AI generates implementation. Humans review and accept.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         FE AUTOMATION SYSTEM                                    │
│                                                                                 │
│  ┌─────────┐    ┌─────────────┐    ┌──────────────┐    ┌────────────────────┐  │
│  │  FIGMA   │───▶│  EXTRACTION │───▶│  GENERATION  │───▶│   VERIFICATION    │  │
│  │  (input) │    │  (tokens +  │    │  (Claude     │    │   (7 automated    │  │
│  │          │    │   markup)   │    │   Code)      │    │    quality gates) │  │
│  └─────────┘    └─────────────┘    └──────────────┘    └────────┬───────────┘  │
│                                                                  │              │
│                                                          pass ┌──┴──┐ fail     │
│                                                               │     │          │
│                                                               ▼     ▼          │
│                                                           ┌──────┐ ┌────────┐  │
│                                                           │REVIEW│ │AUTO-FIX│  │
│                                                           │(human│ │(Claude │  │
│                                                           │accept│ │retries)│  │
│                                                           └──┬───┘ └────────┘  │
│                                                              │                  │
│                                                              ▼                  │
│                                                         ┌─────────┐            │
│                                                         │  SHIP   │            │
│                                                         └─────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## System Components

### Component 1: Figma Input Layer

The system requires structured Figma files. This is the contract between Design and the pipeline.

**Figma file requirements:**

| Requirement | What It Enables Downstream |
|-------------|---------------------------|
| Auto Layout on all frames | Direct translation to CSS Flexbox/Grid |
| Figma Variables for colors, spacing, typography | Auto-extraction of design tokens |
| Meaningful layer names (`header-nav`, not `Frame 47`) | Layer names → component/class names |
| Components for reused elements | Maps to React components |
| Breakpoint variants (375px, 768px, 1440px) | Responsive behavior is explicit, not guessed |
| "Ready for dev" status on completed frames | Triggers pipeline |

**Figma file structure:**

```
📁 Project
├── 📁 Design System
│   ├── Variables (colors, spacing, radius, shadows)
│   ├── Text Styles (heading-xl, body-md, caption, ...)
│   └── Components (Button, Input, Card, Modal, ...)
├── 📁 Screens
│   ├── [Screen] — Desktop (1440px)
│   ├── [Screen] — Tablet (768px)
│   └── [Screen] — Mobile (375px)
└── 📁 Prototypes (user flows)
```

### Component 2: Extraction Layer

Two extraction pipelines run from the Figma file:

#### 2a. Design Token Sync (Automated)

```
Figma Variables ──▶ Figma REST API ──▶ tokens.ts
```

A script calls `GET /v1/files/:key/variables/local`, transforms Figma Variables into a TypeScript const object:

```typescript
// Auto-generated from Figma — do not edit
export const tokens = {
  color: {
    primary: '#2563EB',
    error: '#DC2626',
    text: { primary: '#111827', secondary: '#6B7280' },
    bg: { page: '#FFFFFF', surface: '#F9FAFB' },
  },
  spacing: { xs: '4px', sm: '8px', md: '16px', lg: '24px', xl: '32px' },
  radius: { sm: '4px', md: '8px', lg: '16px', full: '9999px' },
  fontSize: { sm: '14px', md: '16px', lg: '20px', xl: '24px' },
} as const;
```

This runs on-demand or via webhook when the Figma file is published. Tokens flow into Tailwind config and component code — no hardcoded values anywhere.

#### 2b. Markup Export (Semi-automated)

```
Figma frames ──▶ Figma-to-Code plugin ──▶ raw Tailwind HTML
```

The **Figma to Code** plugin exports selected frames as Tailwind HTML. This produces flat, unstyled markup — the structural skeleton, not production code.

Alternative: **Figma Dev Mode** for manual inspection of individual elements (useful for complex interactions that plugins don't capture).

#### 2c. Screenshot Export (Automated)

```
Figma frames ──▶ Figma REST API (image export) ──▶ reference screenshots
```

`GET /v1/files/:key/images?ids=:ids&format=png` exports frame screenshots. These become the **visual regression baseline** — the system compares rendered components against these Figma screenshots.

### Component 3: Specification Layer

Engineers write lightweight specs that tell Claude **what to build**, not **how to build it**.

#### Component Spec (per component)

```markdown
## SearchBar
Props: placeholder (string), onSearch ((q: string) => void), debounceMs (number)
States: idle → typing → loading → results | error | empty
Accessibility: role=search, aria-label on input, aria-live on results
```

#### Screen Spec (per page)

```markdown
## /products
States: loading → ready | error | empty
Components: SearchBar (top), ProductGrid (main), FilterSidebar (left, hidden on mobile)
URL state: ?q= (search), ?category= (filter), ?page= (pagination)
Responsive: mobile=stack, tablet=2-col no sidebar, desktop=3-col with sidebar
```

#### Spec input format

Templates with fill-in-the-blank structure. An engineer writes a spec in ~30 minutes per screen — not code, just structured requirements.

### Component 4: Generation Layer (Claude Code)

Claude Code receives four inputs and produces production code:

```
┌─────────────────────────────────────────────────────┐
│                  CLAUDE CODE INPUT                    │
│                                                       │
│  1. tokens.ts ────────── design constraints           │
│  2. Raw Tailwind HTML ── structural skeleton          │
│  3. Component/Screen specs ── behavioral requirements │
│  4. CLAUDE.md ─────────── project conventions         │
│                                                       │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                  CLAUDE CODE OUTPUT                   │
│                                                       │
│  components/                                          │
│  ├── SearchBar.tsx ──────── component implementation   │
│  ├── SearchBar.test.tsx ─── unit + interaction tests  │
│  └── SearchBar.stories.tsx ─ all states in Storybook  │
│                                                       │
│  app/products/                                        │
│  ├── page.tsx ───────────── page integration           │
│  └── page.test.tsx ──────── page-level tests          │
│                                                       │
│  e2e/                                                 │
│  └── products.spec.ts ───── E2E user flow tests       │
│                                                       │
└─────────────────────────────────────────────────────┘
```

**Generation rules enforced via CLAUDE.md:**
- All colors/spacing/typography must reference `tokens.ts` — no hardcoded values
- Every component must have a test file and a Storybook story
- Tests are written before implementation (TDD)
- Components must pass a11y checks (ARIA, keyboard nav, screen reader)
- Responsive behavior must match spec breakpoints

**Self-correction loop:** If tests fail after generation, Claude reads the error, fixes the code, and retries — up to 10 iterations before escalating to a human.

### Component 5: Verification Layer

Seven automated gates run on every commit. All must pass before human review.

```
┌──────────────────────────────────────────────────────────────────┐
│                      VERIFICATION PIPELINE                        │
│                                                                    │
│  Gate 1: tsc --noEmit ────────────────── Type safety              │
│  Gate 2: eslint --max-warnings 0 ─────── Code standards           │
│  Gate 3: vitest run ──────────────────── Unit + integration tests │
│  Gate 4: next build ──────────────────── Production build         │
│  Gate 5: playwright test ─────────────── E2E user flows           │
│  Gate 6: playwright screenshots ──────── Visual regression        │
│          vs. Figma reference images      (pixel comparison)       │
│  Gate 7: axe-core ────────────────────── Accessibility audit      │
│                                                                    │
│  Optional: lighthouse ────────────────── Performance (advisory)   │
│                                                                    │
│  ALL PASS ──▶ PR created ──▶ Human review in Storybook            │
│  ANY FAIL ──▶ Claude auto-fix ──▶ retry ──▶ escalate if stuck     │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
```

**Visual regression detail:** Playwright renders each component/page at 3 viewports (375px, 768px, 1440px), takes screenshots, and compares against Figma-exported reference images. Pixel diff > threshold = fail.

### Component 6: Review & Accept Layer

Human review is scoped to two things:

1. **Storybook review** — Does it look right? Check all component states, responsive variants
2. **Diff review** — Is the code clean? Check architecture, naming, patterns

The engineer does NOT need to:
- Run the app locally and click through it
- Check responsive behavior manually
- Run tests manually
- Check accessibility manually

All of that is already verified by the pipeline.

### Component 7: Recovery Layer

When verification fails and Claude can't self-fix:

```
Level 1: Self-heal ── Claude reads error, fixes code, retries (up to 10x)
Level 2: Decompose ── Break the task into smaller pieces, retry each
Level 3: Escalate ─── Log full context (error, attempted fixes, spec) for human
Level 4: Learn ────── Human fix gets written back to CLAUDE.md to prevent recurrence
```

---

## End-to-End Flow (Single Feature)

```
                    DESIGNER                    ENGINEER                    SYSTEM
                    ────────                    ────────                    ──────

                    Design in Figma
                    (Auto Layout +
                     Variables +
                     Named layers)
                         │
                         │ "Ready for dev"
                         ▼
                                                Write specs
                                                (component +
                                                 screen, ~30min)
                                                     │
                                                     │ commit specs
                                                     ▼
                                                                     Token sync
                                                                     (Figma API → tokens.ts)
                                                                            │
                                                                     Markup export
                                                                     (plugin → raw HTML)
                                                                            │
                                                                     Claude Code generates:
                                                                     • Components (.tsx)
                                                                     • Tests (.test.tsx)
                                                                     • Stories (.stories.tsx)
                                                                     • Page integration
                                                                            │
                                                                     Verification (7 gates)
                                                                            │
                                                                     ┌──────┴──────┐
                                                                     │             │
                                                                  PASS          FAIL
                                                                     │          Auto-fix
                                                                     │          retry
                                                                     ▼             │
                                                Review PR             │
                                                (Storybook +          │
                                                 diff only)◀──────────┘
                                                     │
                                            Accept ──┤── Request changes
                                                     │   (Claude fixes)
                                                     ▼
                    Review in                   Merge + deploy
                    Storybook
                    "looks right" ✓
```

---

## Technical Stack

| Layer | Tool | Role in System |
|-------|------|---------------|
| Design | Figma | Single source of design truth |
| Token extraction | Figma REST API | Variables → `tokens.ts` |
| Markup extraction | Figma-to-Code plugin | Frames → raw Tailwind HTML |
| Screenshot baseline | Figma REST API (image export) | Reference images for visual regression |
| Code generation | Claude Code | Specs + tokens + markup → production components |
| Framework | Next.js (App Router) | File-based routing, minimal wiring |
| Styling | Tailwind CSS | Utility classes, constrained by tokens |
| UI primitives | Radix UI / shadcn/ui | Accessible components, composable |
| Unit tests | Vitest | Fast, TypeScript-native |
| E2E tests | Playwright | Cross-browser, visual screenshots |
| Visual regression | Playwright screenshots | Compare rendered vs. Figma reference |
| Accessibility | axe-core + eslint-plugin-jsx-a11y | Automated a11y audit |
| Component review | Storybook | Isolated visual review for all states |
| CI | GitHub Actions | Run 7 verification gates |
| Project context | CLAUDE.md | Persistent project knowledge for AI |

---

## Feasibility Assessment

### What Works Today (Proven)

| Capability | Status | Evidence |
|-----------|--------|---------|
| Figma REST API token extraction | Production-ready | API is stable, Variables endpoint available |
| Figma-to-Code Tailwind export | Usable | Open source plugin, clean output for Auto Layout files |
| Claude Code generating React components from specs | Proven | Used in current projects (MewtwoAI: 747 tests, FinancialAssistant: 51 tests) |
| TDD with Claude (tests first, then implementation) | Proven | Standard workflow in our projects |
| Automated verification (typecheck + lint + test + build) | Proven | Already running in our projects |
| Storybook for component review | Mature | Industry standard, well-supported |

### What Needs Building (1-2 weeks)

| Component | Effort | Complexity |
|-----------|--------|-----------|
| Figma token sync script | 1 day | Low — REST API call + JSON transform |
| Visual regression with Figma screenshots as baseline | 2-3 days | Medium — Playwright screenshot comparison, threshold tuning |
| CI pipeline with 7 gates | 2 days | Low — standard GitHub Actions |
| Storybook + Chromatic integration | 1 day | Low — well-documented setup |
| Spec templates + CLAUDE.md for pilot project | 0.5 day | Low — templates already drafted |
| Figma discipline guide for designers | 0.5 day | Low — documentation + 1 training session |

### Open Questions

| Question | Impact | How to Resolve |
|----------|--------|---------------|
| How accurate is Figma-to-Code plugin output for our designs? | High | Test with 3 existing screens — measure cleanup effort |
| What's the right pixel-diff threshold for visual regression? | Medium | Empirical — run on existing components, tune to avoid false positives |
| Can Claude handle complex interactive patterns (drag-drop, animations)? | Medium | Test during pilot — scope pilot to avoid these initially |
| Will designers adopt Figma discipline? | High | Design lead buy-in required — frame as "your designs get built accurately" |

---

## Pilot Plan

**Scope:** 1 feature, 3-5 screens, 1 engineer, 2 weeks.

**Week 1:**
- Set up infrastructure (token sync, CI gates, Storybook)
- Designer structures Figma file per requirements
- Engineer writes specs for all screens

**Week 2:**
- Run full pipeline: extract → generate → verify → review
- Measure: time spent, intervention rate, code quality
- Document: what worked, what broke, what to change

**Pilot output:** Data on feasibility + refined system design for Phase 1.

---

## System Boundaries

What this system **does:**
- Generate UI components from Figma designs + specs
- Produce comprehensive tests (unit, E2E, visual, a11y)
- Verify code quality through automated gates
- Maintain design-code fidelity via token sync

What this system **does not:**
- Replace product/design decisions (humans define what to build)
- Handle backend/API implementation (separate workflow)
- Auto-deploy to production without human approval
- Work with unstructured Figma files (garbage in = garbage out)
