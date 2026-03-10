# Autonomous Dev Workflow

A framework for building software where **Claude Code does 80–95% of the implementation work** — humans define specs, Claude writes code, tests, and ships.

## What Is This?

This repo contains the methodology, templates, and tooling for an AI-driven development workflow. It's not an app — it's the system that builds apps.

### The 5-Layer System

1. **Specification** — Machine-readable PRDs, screen/page definitions, API contracts, acceptance criteria
2. **Context Management** — `CLAUDE.md` as project brain + cross-session handoff protocols
3. **Execution Loop** — Atomic tasks with standardized build-test-commit cycles
4. **Verification** — Automated gates: type check, lint, test, build, visual check
5. **Recovery** — Error classification with auto-fix, escalation, and learning feedback loops

## Repo Structure

```
.
├── README.md                     # You are here
├── STRATEGY.md                   # Leadership alignment doc
├── CLAUDE.md                     # Claude Code instructions for this repo
│
├── docs/
│   └── workflow.md               # Full 5-layer workflow reference
│
├── frontend-engineering/         # FE-specific autonomous dev workflow
│   ├── README.md                 # FE strategy: visual verification, components, a11y
│   └── templates/
│       ├── COMPONENT_SPEC.md.template   # Component props, states, behavior
│       ├── SCREEN_SPEC.md.template      # Page state machine + responsive layout
│       └── DESIGN_TOKENS.md.template    # Design token contract
│
├── templates/                    # Reusable templates for any project
│   ├── CLAUDE.md.template        # Project brain template
│   ├── HANDOFF.md.template       # Cross-session handoff template
│   ├── ESCALATION.md.template    # Human escalation log template
│   └── specs/
│       ├── PRD.md.template       # Product requirements (Given/When/Then)
│       ├── SCREENS.md.template   # UI state machine definitions
│       ├── API.yaml.template     # OpenAPI contract template
│       ├── DESIGN_TOKENS.md.template  # Design system tokens
│       └── ACCEPTANCE.md.template     # Acceptance criteria template
│
└── scripts/
    └── verify.sh                 # Pre-commit verification (typecheck + lint + test + build)
```

## Getting Started

This is a strategy-phase repo. See [STRATEGY.md](./STRATEGY.md) for the rollout plan.

Once a pilot project is selected:
1. Copy templates into the project repo
2. Fill in specs for the first feature
3. Let Claude Code execute against the specs

## Status

**Phase: Pre-pilot** — Aligning with leadership on approach before selecting a pilot project.
