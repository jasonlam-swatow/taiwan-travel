# Catppuccin Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Quartz default theme with standard Catppuccin while preserving the wide Base homepage.

**Architecture:** Quartz 5 continues to load themes through `@quartz-themes/core`. The configuration selects `catppuccin`, while its dedicated npm package is recorded in the package manifest and lockfile for deterministic Cloudflare builds.

**Tech Stack:** Quartz 5, `@quartz-themes/core`, `@quartz-themes/catppuccin`, npm, SCSS

## Global Constraints

- Use Node.js 22.
- Keep `mode: both`.
- Preserve `.quartz-site/quartz/styles/custom.scss` unchanged.
- Do not modify vault notes or Bases.

---

### Task 1: Configure and lock Catppuccin

**Files:**
- Modify: `.quartz-site/quartz.config.yaml`
- Modify: `.quartz-site/package.json`
- Modify: `.quartz-site/package-lock.json`
- Verify unchanged: `.quartz-site/quartz/styles/custom.scss`

**Interfaces:**
- Consumes: Quartz 5 transformer options for `@quartz-themes/core`.
- Produces: A deterministic Quartz build using the standard Catppuccin package.

- [ ] **Step 1: Record the pre-change assertions**

Run:

```bash
rg -n 'theme: default|theme: catppuccin|@quartz-themes/catppuccin' .quartz-site/quartz.config.yaml .quartz-site/package.json
```

Expected: configuration contains `theme: default` and the package manifest does not contain `@quartz-themes/catppuccin`.

- [ ] **Step 2: Install the Catppuccin package**

Run from `.quartz-site` under Node 22:

```bash
npm install @quartz-themes/catppuccin
```

Expected: `package.json` and `package-lock.json` record the Catppuccin dependency.

- [ ] **Step 3: Select Catppuccin**

Change the theme transformer options to:

```yaml
options:
  theme: catppuccin
  mode: both
```

- [ ] **Step 4: Build and verify**

Run from the repository root under Node 22:

```bash
bash scripts/prepare-content.sh
cd .quartz-site
npm ci
npx quartz build
```

Expected: Quartz exits successfully after processing 77 Markdown files, and generated CSS contains Catppuccin selectors or variables.

- [ ] **Step 5: Confirm scope**

Run:

```bash
git diff --check
git diff -- .quartz-site/quartz/styles/custom.scss
```

Expected: no whitespace errors and no changes to `custom.scss`.

