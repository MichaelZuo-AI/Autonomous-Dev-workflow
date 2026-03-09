# E2E Development Workflow with Claude Code

> **Goal:** 100% coding by Claude Code — human intervention becomes the exception, not the norm.

---

## Overall Architecture

```
L1: Specification Layer        Define what to build (specs, screens/pages, API, acceptance criteria)
L2: Context Management Layer   Maintain project knowledge across sessions (CLAUDE.md, handoffs)
L3: Execution Loop Layer       Standardized implement → verify → commit cycle
L4: Verification Layer         Automated quality gates (types, lint, tests, build, visual)
L5: Feedback & Recovery Layer  Error classification, auto-fix, escalation protocols
```

---

## L1: Specification Layer

> The bottleneck of 100% automation is input quality, not Claude's capability.

### Required Spec Files

| File | Purpose |
|------|---------|
| `specs/PRD.md` | Structured product requirements in Given/When/Then format |
| `specs/SCREENS.md` | State machine for every screen/page (loading/empty/error/success) |
| `specs/API.yaml` | OpenAPI spec — the data contract Claude codes against |
| `specs/DESIGN_TOKENS.md` | Color, typography, spacing system — no freestyle styling |
| `specs/ACCEPTANCE.md` | Executable acceptance criteria, maps 1:1 to test cases |

### Principles

- Write PRD in **Given / When / Then** format to eliminate ambiguity
- Every UI state must enumerate all states: `loading` / `empty` / `error` / `success`
- Acceptance criteria must map 1:1 to automated test cases

---

## L2: Context Management Layer

> Claude has a finite context window. Large projects require deliberate context architecture.

### CLAUDE.md — The Project Brain

Every project must have a `CLAUDE.md` at the root containing:

- **Architecture Decision Records** — what tools/libraries and why
- **Code Navigation Map** — where things live in the codebase
- **Current Sprint Context** — active feature, completed features, blockers
- **Conventions** — patterns to follow, reference implementations
- **Gotchas & Lessons Learned** — accumulated fixes and workarounds

### Task Decomposition

```
Epic  →  Feature  →  Task  →  Atomic Unit
```

Each atomic unit must:
- Have a clear "Done" signal (build pass + test pass)
- Stay within 500 LOC changed
- Have no ambiguous dependencies
- Be independently testable

### Cross-Session Handoff

Every task session ends with a `HANDOFF.md` containing:
- What was completed
- What's next
- Context to carry forward

---

## L3: Execution Loop Layer

### Standard Loop

```
1. Load Context       → CLAUDE.md + task spec + HANDOFF
2. Pre-flight Check   → dependencies complete, tests baseline exists, branch clean
3. Implement          → code generation following conventions
4. Self-Verify        → typecheck + lint + test → auto-fix up to 3x on failure
5. Integration Verify → build + smoke test (UI screenshot if applicable)
6. Commit + Update    → git commit, update CLAUDE.md, write HANDOFF
```

### Verification Scripts

| Script | Purpose |
|--------|---------|
| `scripts/verify.sh` | Pre-commit: type check + lint + test + build |

---

## L4: Verification Layer

### Three Tiers

**Tier 1 — Code Correctness** (fully automated)
- Type check + lint + test with coverage

**Tier 2 — Build Verification** (automated with error classification)
- Missing dependency → auto-install
- Config error → consult CLAUDE.md + fix
- Platform-specific issue → pattern match known fixes
- Unknown error → escalate to human

**Tier 3 — UI/Visual Verification** (progressive automation, for frontend projects)
- Phase 1: Component isolation (Storybook) + design token constraints
- Phase 2: Screenshot + Vision API comparison against design spec
- Phase 3: Full automated visual regression

---

## L5: Feedback & Recovery Layer

### Error Levels

| Level | Trigger | Strategy | SLA |
|-------|---------|----------|-----|
| **1 — Self-Healing** | Lint/type/test errors | Auto-fix → rerun (max 3x) | Same session |
| **2 — Context Reload** | Build errors with clear messages | Parse error → search docs → fix | Same session |
| **3 — Task Decomposition** | Scope too large, quality degradation | Split into smaller units, re-queue | Next session |
| **4 — Human Escalation** | Platform crashes, env issues, 3 failed attempts | Log context → pause → human fixes | 1 business day |

### Escalation Protocol

When Level 4 triggers, create `ESCALATION.md` with:
- Full error message and stack trace
- What was attempted (all 3 attempts)
- Suspected root cause and suggested fix direction
- Post-fix actions: update CLAUDE.md + add regression test
