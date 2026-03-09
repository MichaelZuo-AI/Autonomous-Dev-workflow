# Autonomous Mobile Development with Claude Code

**Author:** Michael Zuo | **Date:** 2026-03-09 | **Status:** Draft — Seeking Alignment

---

## Problem

Mobile app development is slow and expensive. A typical feature cycle — spec, implement, review, QA, fix, ship — takes days to weeks, with most time spent on mechanical work (boilerplate, styling, test writing, build debugging) rather than product decisions.

## Thesis

Claude Code can own 80–95% of the implementation work for mobile apps if we invest in **structured inputs** and **automated verification**. The human role shifts from writing code to defining specs and accepting results.

## How It Works

A 5-layer system ensures Claude can operate autonomously with high quality:

| Layer | Purpose | Key Artifact |
|-------|---------|-------------|
| **Specification** | Machine-readable requirements eliminate ambiguity | PRD in Given/When/Then format, screen state machines |
| **Context Management** | Claude retains project knowledge across sessions | `CLAUDE.md` (project brain) + session handoff notes |
| **Execution Loop** | Standardized build-test-commit cycle | Atomic tasks (< 500 LOC), self-verify before commit |
| **Verification** | Automated quality gates replace manual QA | Type check + lint + tests + build + visual check |
| **Recovery** | Errors are classified and auto-resolved when possible | 4-level escalation: self-heal → reload → decompose → human |

## What Changes for the Team

| Before | After |
|--------|-------|
| Engineers write code, review PRs | Engineers write specs, accept results |
| QA tests manually on devices | Automated test suites + screenshot verification |
| Context lives in people's heads | Context lives in `CLAUDE.md` — survives turnover |
| One feature per engineer per sprint | Multiple features in parallel via Claude sessions |

## Phased Rollout

| Phase | Automation | Human Role | Goal |
|-------|-----------|------------|------|
| **Phase 1** | ~80% — Claude writes all code, tests, commits | Review build output + UI, final acceptance | Establish baseline, learn failure patterns |
| **Phase 2** | ~90% — Add automated build + test verification | Visual acceptance only | Remove human from build loop |
| **Phase 3** | ~95% — Add screenshot + vision-based UI checks | Handle only exceptional escalations | Human intervention becomes the exception |

We start Phase 1 immediately. Each phase builds on lessons from the previous one.

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Claude produces subtly wrong UI | Design token system constrains styling; Storybook isolates components for review |
| Context lost between sessions | Mandatory `CLAUDE.md` updates + handoff notes after every task |
| Spec quality bottleneck | Given/When/Then templates + acceptance criteria checklist lower the bar for writing good specs |
| Native/platform issues Claude can't fix | Escalation protocol logs full context for human; fix gets written back to `CLAUDE.md` to prevent recurrence |
| Token cost at scale | Concise context management + atomic tasks keep per-session costs bounded |

## Success Metrics

- **Time-to-feature:** Baseline current feature cycle time, target 3x reduction by end of Phase 1
- **Human intervention rate:** Track how often Claude escalates to human. Target: < 20% of tasks in Phase 1, < 5% by Phase 3
- **Test coverage:** Maintain >= 80% coverage as a gate for every commit
- **Rework rate:** Measure how often Claude's output needs human correction after acceptance

## Next Steps

1. Select a pilot app/feature to validate Phase 1
2. Write initial specs (PRD, screens, design tokens) for the pilot
3. Set up repo scaffolding (CLAUDE.md, scripts, test infrastructure)
4. Run 2-week sprint with Claude doing all implementation
5. Retrospective: measure metrics, decide on Phase 2 timeline

---

*This is a living document. Updates will reflect lessons learned as we progress through each phase.*
