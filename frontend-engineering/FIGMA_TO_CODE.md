# Figma to Code — Practical Pipeline

> How to ship designs from Figma to production code when your design team lives in Figma.

---

## The Problem

Designers produce pixel-perfect Figma files. Engineers manually translate them into code. This handoff is:
- **Slow** — reading specs, eyeballing spacing, back-and-forth on "this doesn't match the design"
- **Lossy** — details get dropped, responsive behavior gets guessed
- **Repetitive** — the same translation work happens for every screen

With Claude Code in the loop, we can collapse this entire gap.

---

## Pipeline Overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Designer   │────▶│  Figma File  │────▶│  Extraction  │────▶│  Claude Code │
│   (Figma)    │     │  (structured)│     │  (tokens +   │     │  (refactor + │
│              │     │              │     │   markup)    │     │   tests)     │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                                                                      │
                                                                      ▼
                                                               ┌──────────────┐
                                                               │  Production  │
                                                               │  Components  │
                                                               └──────────────┘
```

**Three stages:**
1. **Designer structures Figma properly** (the biggest leverage point)
2. **Extract** design tokens + raw markup from Figma
3. **Claude refactors** raw output into production components with tests

---

## Stage 1: Figma Discipline (Designer's Job)

The #1 factor in code quality is **how the Figma file is structured**. Every tool — plugin, API, or AI — produces garbage from unstructured Figma files.

### Rules for Designers

| Rule | Why | Example |
|------|-----|---------|
| **Use Auto Layout everywhere** | Translates to Flexbox/CSS Grid | Stack elements, don't absolute-position |
| **Name every layer meaningfully** | Layer names → class names / component names | `header-nav`, `product-card`, not `Frame 47` |
| **Use Figma Components** | Maps to React/Vue components | Create component for anything reused 2+ times |
| **Use Figma Variables** | Maps to design tokens (colors, spacing) | `color/primary`, `spacing/md` — not raw hex values |
| **Use Figma Styles** | Consistent typography and effects | Text styles for every heading/body level |
| **Design at real breakpoints** | Responsive behavior is explicit | Create frames at 375px, 768px, 1440px |
| **Group by component, not visual proximity** | Clean DOM hierarchy | Logical grouping, not overlapping layers |

### Figma File Structure

```
📁 Project Name
├── 📄 Cover
├── 📁 Design System
│   ├── Colors (as Variables)
│   ├── Typography (as Text Styles)
│   ├── Spacing (as Variables)
│   ├── Icons (as Components)
│   └── Base Components (Button, Input, Card, ...)
├── 📁 Pages
│   ├── 📄 Home — Desktop (1440px)
│   ├── 📄 Home — Mobile (375px)
│   ├── 📄 Product List — Desktop
│   ├── 📄 Product List — Mobile
│   └── ...
└── 📁 Prototypes (flows + interactions)
```

---

## Stage 2: Extraction Methods

Three approaches, from simplest to most powerful:

### Option A: Figma Dev Mode (Recommended Starting Point)

**What:** Figma's built-in developer handoff tool.

**How to use:**
1. Designer marks frames as "Ready for dev" in Figma
2. Developer opens Dev Mode (toggle in Figma UI)
3. Click any element → see CSS/iOS/Android code snippets
4. Copy snippets, use as reference for Claude

**What you get:**
- CSS properties for any selected element
- Spacing measurements between elements
- Color/font values (linked to variables if designer used them)
- Asset export

**Best for:** Quick reference, small teams, getting started immediately.

**Limitation:** Manual copy-paste, no bulk export, no component logic.

### Option B: Figma-to-Code Plugins

| Plugin | Output | Strengths | Weaknesses |
|--------|--------|-----------|------------|
| **Figma to Code** (Bernardo Ferrari) | HTML+Tailwind, Flutter, SwiftUI | Open source, Tailwind output is clean | No component abstraction, flat markup |
| **Locofy.ai** | React, Next.js, Gatsby, Vue, HTML | AI-powered, generates real components, responsive | Paid, can be opinionated about structure |
| **Anima** | React, Vue, HTML+CSS | Handles interactions/animations | Paid, generated code needs cleanup |
| **Builder.io** | React, Vue, Svelte, Angular, Qwik | Visual editor + code gen, AI features | More of a CMS platform than a pure converter |
| **TeleportHQ** | React, Vue, Angular, HTML | Full page generation, responsive | Less control over output structure |

**Recommended for your team:** Start with **Figma to Code** (free, Tailwind output) → feed output to Claude for refinement.

### Option C: Figma REST API (Most Powerful)

**What:** Programmatic access to the full Figma file tree — every node, style, variable, and component.

**Key endpoints:**
```
GET /v1/files/:file_key                    # Full file tree (JSON)
GET /v1/files/:file_key/nodes?ids=:ids     # Specific frames/components
GET /v1/files/:file_key/images?ids=:ids    # Export as PNG/SVG/PDF
GET /v1/files/:file_key/styles             # All styles in the file
GET /v1/files/:file_key/variables/local    # All variables (design tokens)
```

**What you can build:**
1. **Auto-extract design tokens** → generate `tokens.ts` from Figma Variables
2. **Export component tree** → JSON representation of every component + props
3. **Screenshot frames** → generate visual reference images for Claude
4. **Webhook on file update** → trigger pipeline when designer publishes changes

**Setup:**
```bash
# Get a Personal Access Token from Figma > Settings > Personal Access Tokens
export FIGMA_TOKEN="your-token-here"

# Fetch a file's design tokens
curl -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/FILE_KEY/variables/local"
```

**Best for:** Teams wanting full automation. Build once, use on every project.

---

## Stage 3: Claude Refactors into Production Code

Raw Figma-to-code output is never production-ready. It's **flat markup** — no components, no state, no tests. This is where Claude adds the real value.

### The Prompt Pattern

```
Here is raw Tailwind HTML exported from our Figma design for [ScreenName]:

[paste Figma-to-code output]

Here is our component spec:

[paste COMPONENT_SPEC.md]

Here are our design tokens:

[paste tokens.ts]

Refactor this into:
1. React components following our project conventions
2. Use our design tokens (import from @/tokens) — replace any hardcoded values
3. Add TypeScript props interfaces
4. Make it responsive per the spec breakpoints
5. Write unit tests for each component
6. Write Storybook stories showing all states
```

### What Claude Does

| Input | Claude's Job | Output |
|-------|-------------|--------|
| Raw HTML/Tailwind | Extract component boundaries | `components/SearchBar.tsx` |
| Hardcoded colors/spacing | Map to design tokens | `tokens.primary` instead of `#2563EB` |
| Flat markup | Add state management | `useState`, handlers, loading states |
| No tests | Write tests | `SearchBar.test.tsx` |
| No stories | Write Storybook stories | `SearchBar.stories.tsx` |
| Single viewport | Add responsive behavior | Breakpoint-aware layout |
| No a11y | Add accessibility | ARIA attributes, keyboard nav |

---

## End-to-End Workflow

Here's the complete flow for shipping a new screen:

```
Day 1: Designer
├── Design screen in Figma (structured with Auto Layout + Variables)
├── Create mobile + desktop variants
├── Mark as "Ready for dev"
└── Share Figma link

Day 1-2: Spec Writer (Human)
├── Write COMPONENT_SPEC.md for each new component
├── Write SCREEN_SPEC.md with state machine
├── Extract design tokens (manual or via API script)
└── Commit specs to repo

Day 2: Code Generation
├── Export Tailwind markup via Figma-to-Code plugin
├── Feed to Claude with specs + tokens
├── Claude generates:
│   ├── Component files (.tsx)
│   ├── Test files (.test.tsx)
│   ├── Story files (.stories.tsx)
│   └── Page integration
├── Run verification gate (typecheck + lint + test + build + visual)
└── Commit

Day 2-3: Review
├── Designer reviews in Storybook → "does this match?"
├── Engineer reviews code diff → approve or request changes
└── Merge + deploy
```

**Target:** 1-2 day turnaround from "design ready" to "code shipped."

---

## Automation Script: Figma Tokens → Code

A starter script to auto-extract design tokens from Figma:

```typescript
// scripts/sync-figma-tokens.ts
// Usage: FIGMA_TOKEN=xxx npx tsx scripts/sync-figma-tokens.ts FILE_KEY

const FILE_KEY = process.argv[2];
const TOKEN = process.env.FIGMA_TOKEN;

async function fetchVariables() {
  const res = await fetch(
    `https://api.figma.com/v1/files/${FILE_KEY}/variables/local`,
    { headers: { 'X-Figma-Token': TOKEN! } }
  );
  return res.json();
}

async function main() {
  const data = await fetchVariables();
  const variables = Object.values(data.meta.variables) as any[];
  const collections = Object.values(data.meta.variableCollections) as any[];

  const tokens: Record<string, any> = {};

  for (const v of variables) {
    const collection = collections.find((c: any) => c.id === v.variableCollectionId);
    const modeId = collection.defaultModeId;
    const value = v.resolvedValuesByMode[modeId];

    // Build nested token path from name (e.g., "color/primary" → tokens.color.primary)
    const parts = v.name.split('/');
    let current = tokens;
    for (let i = 0; i < parts.length - 1; i++) {
      current[parts[i]] = current[parts[i]] || {};
      current = current[parts[i]];
    }
    current[parts[parts.length - 1]] = formatValue(v.resolvedType, value);
  }

  const output = `// Auto-generated from Figma — do not edit manually
// Source: https://www.figma.com/file/${FILE_KEY}
// Generated: ${new Date().toISOString()}

export const tokens = ${JSON.stringify(tokens, null, 2)} as const;
`;

  console.log(output);
}

function formatValue(type: string, value: any): string {
  if (type === 'COLOR') {
    const { r, g, b, a } = value.resolvedValue;
    const hex = [r, g, b].map((c: number) => Math.round(c * 255).toString(16).padStart(2, '0')).join('');
    return a < 1 ? `rgba(${Math.round(r*255)},${Math.round(g*255)},${Math.round(b*255)},${a})` : `#${hex}`;
  }
  if (type === 'FLOAT') return `${value.resolvedValue}px`;
  return String(value.resolvedValue);
}

main();
```

```bash
# Run it
FIGMA_TOKEN=your-token npx tsx scripts/sync-figma-tokens.ts YOUR_FILE_KEY > src/tokens.ts
```

---

## Choosing Your Approach

| Team Size | Figma Maturity | Recommended Approach |
|-----------|---------------|---------------------|
| 1-3 devs | Low (no Auto Layout, no Variables) | Dev Mode + manual copy to Claude |
| 1-3 devs | High (structured files) | Figma-to-Code plugin + Claude refactor |
| 4-10 devs | High | Figma API token sync + plugin export + Claude |
| 10+ devs | High + design system | Full API pipeline + CI integration + Claude |

**Start simple. Automate what hurts.**

The biggest ROI is always **Stage 1** — getting designers to structure Figma files properly. Everything downstream gets 10x better when the input is clean.
