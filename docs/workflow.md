# E2E Development Workflow with Claude Code

> **Goal:** 100% coding by Claude Code — human intervention becomes the exception, not the norm.

---

## End-to-End Developer Lifecycle

This is the full picture — from idea to production, showing who does what.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DEVELOPER LIFECYCLE                              │
│                                                                         │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│  │  IDEATE  │───▶│  DEFINE  │───▶│  BUILD   │───▶│  VERIFY  │──┐      │
│  │          │    │          │    │          │    │          │  │      │
│  │ 🧑 Human │    │ 🧑 Human │    │ 🤖 Claude│    │ 🤖 Claude│  │      │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │      │
│                                                                 │      │
│       ┌─────────────────────────────────────────────────────────┘      │
│       │                                                                │
│       ▼                                                                │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│  │  REVIEW  │───▶│  DEPLOY  │───▶│ MONITOR  │───▶│  LEARN   │         │
│  │          │    │          │    │          │    │          │         │
│  │ 🧑 Human │    │ 🤖 Claude│    │ 🧑 Human │    │ 🤖+🧑Both│         │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

| Phase | Owner | What Happens | Output |
|-------|-------|-------------|--------|
| **Ideate** | Human | Identify user problem, decide what to build | Rough idea, priorities |
| **Define** | Human | Write specs in Given/When/Then, define screens, API contract | `specs/PRD.md`, `SCREENS.md`, `API.yaml`, `ACCEPTANCE.md` |
| **Build** | Claude | Implement code, write tests, follow conventions | Feature branch with code + tests |
| **Verify** | Claude | Run type check, lint, tests, build, visual check | All gates green, coverage report |
| **Review** | Human | Review diff, accept or request changes | Approved PR |
| **Deploy** | Claude | Merge, build, deploy to staging/production | Live deployment |
| **Monitor** | Human | Watch for issues in production, gather user feedback | Bug reports, feature requests |
| **Learn** | Both | Update CLAUDE.md with lessons, add regression tests | Updated project brain |

---

## Overall Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  L1: Specification Layer                                          │
│  Human writes: PRD → Screens → API → Design Tokens → Acceptance  │
│                          │                                        │
│                          ▼                                        │
│  L2: Context Management Layer                                     │
│  CLAUDE.md (project brain) + HANDOFF.md (session continuity)      │
│                          │                                        │
│                          ▼                                        │
│  L3: Execution Loop Layer                                         │
│  Load context → Pre-flight → Implement → Self-verify → Commit    │
│                          │                                        │
│                          ▼                                        │
│  L4: Verification Layer                                           │
│  Tier 1: Code  →  Tier 2: Build  →  Tier 3: Visual               │
│                          │                                        │
│                     pass │ fail                                    │
│                      ┌───┴───┐                                    │
│                      ▼       ▼                                    │
│                   Ship    L5: Recovery Layer                       │
│                           Auto-fix → Decompose → Escalate         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## L1: Specification Layer

> The bottleneck of 100% automation is input quality, not Claude's capability.

### Spec File Inventory

| File | Purpose | Required For | Example |
|------|---------|-------------|---------|
| `specs/PRD.md` | Product requirements in Given/When/Then | All projects | "Given user is logged in, When they tap profile..." |
| `specs/SCREENS.md` | UI state machines (loading/empty/error/success) | Frontend projects | Screen → state → component mapping |
| `specs/API.yaml` | OpenAPI contract — types, endpoints, error codes | Projects with APIs | Standard OpenAPI 3.0 spec |
| `specs/DESIGN_TOKENS.md` | Color, typography, spacing, shadows | Frontend projects | Token name → value → usage |
| `specs/ACCEPTANCE.md` | Testable criteria, mapped 1:1 to test cases | All projects | AC-001 → `should redirect after login` |

### How to Write a Good Spec

```
❌ Bad:  "Users can log in"
✅ Good: "Given the user is on the Login page,
          When they enter a valid email + password and click Sign In,
          Then they are redirected to Dashboard within 2 seconds
          And an auth token is stored in secure storage"

❌ Bad:  "Show an error if something goes wrong"
✅ Good: "Given the user enters an incorrect password,
          When they click Sign In,
          Then an inline error appears below the password field: 'Invalid password'
          And the password field border turns color-error
          And no navigation occurs"
```

### Spec Completeness Checklist

Before handing a feature to Claude, verify:

- [ ] Every user action has a Given/When/Then
- [ ] Every UI state is defined (loading, empty, error, success)
- [ ] Error cases are specified, not just happy paths
- [ ] API request/response shapes are defined in `API.yaml`
- [ ] Acceptance criteria are concrete and testable (no "should be nice")
- [ ] Design tokens cover all visual properties used

---

## L2: Context Management Layer

> Claude has a finite context window. Large projects require deliberate context architecture.

### CLAUDE.md — The Project Brain

```
┌──────────────────────────────────────┐
│           CLAUDE.md                   │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  Architecture Decisions (ADRs) │  │  ← What tools and why
│  ├────────────────────────────────┤  │
│  │  Code Navigation Map           │  │  ← Where things live
│  ├────────────────────────────────┤  │
│  │  Sprint Context                │  │  ← What's active now
│  ├────────────────────────────────┤  │
│  │  Conventions                   │  │  ← Patterns to follow
│  ├────────────────────────────────┤  │
│  │  Gotchas & Lessons Learned     │  │  ← Accumulated fixes
│  └────────────────────────────────┘  │
│                                      │
│  Read at start of every session.     │
│  Updated at end of every session.    │
└──────────────────────────────────────┘
```

**Rules for maintaining CLAUDE.md:**
- Keep it under 200 lines — concise beats comprehensive
- Every session that discovers a bug or workaround MUST add it to Gotchas
- Remove entries that are no longer relevant (stale context is worse than no context)
- Link to deeper docs rather than inlining everything

### Task Decomposition

```
Epic (weeks)
 └── Feature (days)
      └── Task (hours)
           └── Atomic Unit (single Claude session)

Example:
Epic: User Authentication
 └── Feature: Email/Password Login
      └── Task: Login form UI
           └── Atomic Unit 1: LoginForm component + snapshot test
           └── Atomic Unit 2: Form validation logic + unit tests
           └── Atomic Unit 3: Wire up auth API call + integration test
      └── Task: Auth token management
           └── Atomic Unit 4: SecureStore wrapper + unit tests
           └── Atomic Unit 5: JWT refresh interceptor + unit tests
```

**Atomic Unit rules:**

| Criteria | Target | Why |
|----------|--------|-----|
| Clear "Done" signal | Build pass + test pass | Claude knows when to stop |
| LOC budget | ≤ 500 lines changed | Keeps context window manageable |
| No ambiguous deps | All deps already merged | No blocked work |
| Independently testable | No cross-feature state | Can verify in isolation |

### Cross-Session Handoff Flow

```
Session N                              Session N+1
┌─────────────────┐                   ┌─────────────────┐
│ Load CLAUDE.md   │                   │ Load CLAUDE.md   │
│ Load HANDOFF.md  │                   │ Load HANDOFF.md  │◀── written by N
│ Load task spec   │                   │ Load task spec   │
│       │          │                   │       │          │
│       ▼          │                   │       ▼          │
│ Do the work      │                   │ Continue work    │
│       │          │                   │       │          │
│       ▼          │                   │       ▼          │
│ Write HANDOFF.md │──────────────────▶│ Write HANDOFF.md │───▶ ...
│ Update CLAUDE.md │                   │ Update CLAUDE.md │
│ Git commit + push│                   │ Git commit + push│
└─────────────────┘                   └─────────────────┘
```

**HANDOFF.md must contain:**
1. What was completed (with test coverage %)
2. What's next (ordered by priority)
3. Context to carry forward (API quirks, design changes, decisions made)

---

## L3: Execution Loop Layer

### Detailed Execution Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SINGLE SESSION EXECUTION                         │
│                                                                      │
│  ┌─────────────┐                                                     │
│  │ 1. LOAD     │  Read CLAUDE.md + HANDOFF.md + task spec            │
│  │    CONTEXT   │  Understand: what was done, what's next, patterns   │
│  └──────┬──────┘                                                     │
│         ▼                                                            │
│  ┌─────────────┐                                                     │
│  │ 2. PRE-     │  ✓ Dependencies from previous tasks are merged?     │
│  │    FLIGHT    │  ✓ Test baseline exists and passes?                 │
│  │    CHECK     │  ✓ Branch is clean, no uncommitted changes?         │
│  └──────┬──────┘  ✗ If any fail → fix or escalate before proceeding  │
│         ▼                                                            │
│  ┌─────────────┐                                                     │
│  │ 3. WRITE    │  Write failing tests first (TDD)                    │
│  │    TESTS     │  Cover: happy path + error cases + edge cases       │
│  │    FIRST     │  Map tests to ACCEPTANCE.md criteria                │
│  └──────┬──────┘                                                     │
│         ▼                                                            │
│  ┌─────────────┐                                                     │
│  │ 4. IMPLEMENT│  Write minimum code to pass tests                   │
│  │    CODE      │  Follow conventions from CLAUDE.md                  │
│  │              │  Reference existing patterns in codebase            │
│  └──────┬──────┘                                                     │
│         ▼                                                            │
│  ┌─────────────┐     ┌──────────┐                                    │
│  │ 5. SELF-    │────▶│ PASS?    │──── Yes ──▶ Step 6                 │
│  │    VERIFY    │     └────┬─────┘                                    │
│  │              │          │ No                                       │
│  │  typecheck   │          ▼                                          │
│  │  lint        │     ┌──────────┐                                    │
│  │  test        │     │ AUTO-FIX │──── retry (max 3x)                │
│  │  build       │     └──────────┘                                    │
│  └─────────────┘          │ Still failing after 3x                   │
│                           ▼                                          │
│                      Escalate (→ L5)                                 │
│                                                                      │
│  ┌─────────────┐                                                     │
│  │ 6. COMMIT   │  git add → git commit → git push                   │
│  │    & HANDOFF │  Update CLAUDE.md if new lessons learned            │
│  │              │  Write HANDOFF.md for next session                  │
│  └─────────────┘                                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step Details

#### Step 1: Load Context

Claude reads these files in order:
1. `CLAUDE.md` — project conventions, ADRs, gotchas
2. `HANDOFF.md` — what the last session did, what's next
3. Task spec from `specs/` — the specific feature/acceptance criteria
4. Reference files — existing code patterns mentioned in CLAUDE.md

#### Step 2: Pre-flight Check

| Check | Command | If Fails |
|-------|---------|----------|
| Branch clean | `git status` | Stash or commit pending changes |
| Tests pass | `npm test` | Fix failures before starting new work |
| Dependencies available | Check imports | Install or flag missing packages |
| Spec complete | Review spec | Ask human for missing details |

#### Step 3: Write Tests First

```
For each acceptance criterion in ACCEPTANCE.md:
  → Write a test that captures the expected behavior
  → Run the test → confirm it FAILS (red)
  → This is the "contract" Claude implements against
```

#### Step 4: Implement Code

```
For each failing test:
  → Write the minimum code to make it pass
  → Follow patterns from CLAUDE.md conventions section
  → Reuse existing components/utilities — don't reinvent
  → No magic strings — use constants
```

#### Step 5: Self-Verify Loop

```
┌──────────────────────────────────────────┐
│                                          │
│  Run: typecheck → lint → test → build    │
│           │                              │
│           ▼                              │
│     All pass? ──── Yes ──▶ Done ✅       │
│           │                              │
│           No                             │
│           │                              │
│           ▼                              │
│     Attempt ≤ 3?                         │
│      │         │                         │
│     Yes        No                        │
│      │         │                         │
│      ▼         ▼                         │
│   Auto-fix   Escalate ❌                 │
│   & retry    (→ L5 Recovery)             │
│      │                                   │
│      └──────── loop back ───────────┘    │
│                                          │
└──────────────────────────────────────────┘
```

**Auto-fix strategies by error type:**

| Error Type | Auto-fix Strategy | Example |
|-----------|------------------|---------|
| Type error | Read error message, fix type mismatch | `Type 'string' is not assignable to type 'number'` |
| Lint error | Apply auto-fix or adjust code | `eslint --fix`, then manual fix if needed |
| Test failure | Read assertion diff, fix logic | Expected `true`, received `false` → fix condition |
| Build error | Parse error, install dep or fix config | `Module not found` → `npm install [pkg]` |
| Import error | Fix path or add export | `Cannot find module './utils'` → check path |

#### Step 6: Commit & Handoff

```bash
# Commit
git add -A
git commit -m "feat(auth): implement login form with validation

- LoginForm component with email/password fields
- Client-side validation with inline errors
- Tests: 12 passing (coverage: 94%)

Acceptance: AC-001, AC-002, AC-003"
git push

# Then write HANDOFF.md and update CLAUDE.md
```

---

## L4: Verification Layer

### Verification Pipeline

```
Code Change
    │
    ▼
┌──────────────────────────────────────────────────────┐
│ TIER 1: Code Correctness (every project)             │
│                                                      │
│  typecheck ──▶ lint ──▶ unit tests ──▶ coverage      │
│  (tsc)        (eslint)  (jest/vitest)   (≥80%)       │
│                                                      │
│  Fully automated. Must all pass.                     │
└───────────────────────┬──────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────┐
│ TIER 2: Build Verification (every project)           │
│                                                      │
│  npm run build ──▶ Error Classification              │
│                         │                            │
│            ┌────────────┼────────────┐               │
│            ▼            ▼            ▼               │
│       Missing dep   Config err   Unknown err         │
│       npm install   consult       escalate to        │
│       auto-retry    CLAUDE.md     human (L5)         │
│                     + fix                            │
│                                                      │
│  Automated with fallback to human.                   │
└───────────────────────┬──────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────┐
│ TIER 3: UI/Visual (frontend projects only)           │
│                                                      │
│  Option A: Storybook + Design Tokens (Phase 1)       │
│  ├── Every component has a story                     │
│  ├── Visual review in isolation                      │
│  └── All styles from token system only               │
│                                                      │
│  Option B: Screenshot + Vision API (Phase 2+)        │
│  ├── Capture page/screen after build                 │
│  ├── Pass to Claude Vision with design spec          │
│  └── Claude judges: "Does this match intent?"        │
│                                                      │
│  Option C: Visual Regression (Phase 3+)              │
│  ├── Snapshot comparison against baseline             │
│  ├── Pixel-diff with threshold                       │
│  └── Auto-approve if within tolerance                │
│                                                      │
│  Progressive automation — start with A, add B then C │
└──────────────────────────────────────────────────────┘
```

### Verification by Project Type

| Project Type | Tier 1 | Tier 2 | Tier 3 |
|-------------|--------|--------|--------|
| Web app (Next.js, React) | tsc + eslint + vitest | `npm run build` | Storybook + screenshot |
| Mobile app (React Native) | tsc + eslint + jest | `expo export` / `xcodebuild` | Simulator screenshot |
| API / Backend (Node, Python) | tsc/mypy + lint + test | `npm run build` / `docker build` | N/A (integration tests instead) |
| CLI tool | tsc + lint + test | `npm run build` | N/A |
| Full-stack | All of the above | All of the above | Frontend portion only |

---

## L5: Feedback & Recovery Layer

### Error Escalation Flow

```
Error Detected
      │
      ▼
┌───────────────┐
│ LEVEL 1       │  Lint error? Type error? Test failure?
│ Self-Healing  │  ──▶ Auto-fix → rerun (max 3 attempts)
│               │  ──▶ Resolved? ✅ Continue
└───────┬───────┘
        │ Not resolved
        ▼
┌───────────────┐
│ LEVEL 2       │  Build error with clear message?
│ Context Reload│  ──▶ Parse error → search CLAUDE.md + docs
│               │  ──▶ Apply known fix pattern → rebuild
│               │  ──▶ Resolved? ✅ Update CLAUDE.md with fix
└───────┬───────┘
        │ Not resolved
        ▼
┌───────────────┐
│ LEVEL 3       │  Task too big? Quality degrading?
│ Decompose     │  ──▶ Split current task into smaller atomic units
│               │  ──▶ Commit what works, write HANDOFF for remainder
│               │  ──▶ Next session picks up the pieces
└───────┬───────┘
        │ Not resolved
        ▼
┌───────────────┐
│ LEVEL 4       │  Platform crash? Env issue? 3 attempts failed?
│ Human         │  ──▶ Write ESCALATION.md with full context
│ Escalation    │  ──▶ Pause work on this task
│               │  ──▶ Human investigates + fixes
│               │  ──▶ Post-fix: update CLAUDE.md + add regression test
└───────────────┘
```

### Error Level Details

| Level | Trigger Examples | Strategy | SLA | CLAUDE.md Update? |
|-------|-----------------|----------|-----|-------------------|
| **1 — Self-Healing** | `TS2322: Type 'string' not assignable`, ESLint `no-unused-vars`, Jest `expect(x).toBe(y)` failed | Read error → fix code → rerun | Same session | No (routine fix) |
| **2 — Context Reload** | `Module not found`, `Cannot find module`, webpack/vite config error | Search CLAUDE.md + package docs → fix | Same session | Yes (add to Gotchas) |
| **3 — Decompose** | Session exceeding 500 LOC, multiple unrelated failures, scope creep | Commit partial work, split remaining into new atomic units | Next session | Yes (update Sprint Context) |
| **4 — Human Escalation** | Native crash with no clear fix, environment/permissions issue, CI infra failure | Write ESCALATION.md, pause, wait for human | 1 business day | Yes (after human fixes) |

### ESCALATION.md Format

```markdown
## Escalation — [YYYY-MM-DD] — [task name]

### Error
[Full error message + stack trace]

### What was attempted
1. [Attempt 1: what was tried → what happened]
2. [Attempt 2: what was tried → what happened]
3. [Attempt 3: what was tried → what happened]

### Context for human
- Relevant files: [paths]
- Suspected root cause: [hypothesis]
- Suggested fix direction: [if any]

### Post-fix checklist
- [ ] Root cause identified and fixed
- [ ] CLAUDE.md updated with the fix
- [ ] Regression test added
- [ ] ESCALATION.md archived or deleted
```

---

## Putting It All Together — Full Feature Flow

This is what a complete feature looks like end-to-end:

```
Day 1: DEFINE (Human)
│
├── Write PRD entry for "User Login" in specs/PRD.md
├── Define Login screen states in specs/SCREENS.md
├── Add auth endpoints to specs/API.yaml
├── Set form styling tokens in specs/DESIGN_TOKENS.md
├── Write acceptance criteria AC-001 through AC-008 in specs/ACCEPTANCE.md
│
▼
Day 1–2: BUILD (Claude — 3 sessions)
│
├── Session 1: LoginForm component
│   ├── Load context (CLAUDE.md + specs)
│   ├── Write tests for AC-001, AC-002, AC-003
│   ├── Implement LoginForm + validation
│   ├── Self-verify: tsc ✅ lint ✅ test ✅ build ✅
│   ├── Commit + push
│   └── Write HANDOFF.md → "Next: auth API integration"
│
├── Session 2: Auth API integration
│   ├── Load context (CLAUDE.md + HANDOFF.md)
│   ├── Write tests for AC-004, AC-005
│   ├── Implement auth service + API calls
│   ├── Self-verify: tsc ✅ lint ✅ test ✅ build ✅
│   ├── Commit + push
│   └── Write HANDOFF.md → "Next: token storage"
│
├── Session 3: Token storage + refresh
│   ├── Load context (CLAUDE.md + HANDOFF.md)
│   ├── Write tests for AC-006, AC-007, AC-008
│   ├── Implement secure storage + JWT refresh
│   ├── Self-verify: tsc ✅ lint ✅ test ✅ build ✅
│   ├── Commit + push
│   └── Write HANDOFF.md → "Feature complete, ready for review"
│
▼
Day 2: REVIEW (Human)
│
├── Review PR diff (3 commits, ~400 LOC)
├── Approve or request changes
│
▼
Day 2: DEPLOY (Claude)
│
├── Merge PR
├── Build + deploy to staging
├── Smoke test on staging
│
▼
Day 3+: MONITOR (Human) + LEARN (Both)
│
├── Human watches for production issues
├── If bug found → new task → Claude fixes + adds regression test
└── Update CLAUDE.md with any lessons learned
```

---

*Last updated: 2026-03-09 | This is a living document — update as the workflow evolves.*
