# Quartz 5 Static Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and verify a Quartz 5 website for the current Obsidian vault, with `總彙.base` rendered by BasesPage and automatic deployment from `origin/main` to Cloudflare Pages.

**Architecture:** Keep the Obsidian vault at the repository root and vendor Quartz 5 under `.quartz-site/`. A deterministic allowlist script stages publishable vault content into `.quartz-site/content/`; Quartz builds `.quartz-site/public/`, while Obsidian Git pushes source changes to GitHub and Cloudflare runs the same preparation and build commands.

**Tech Stack:** Obsidian 1.12.7 CLI, Obsidian Git 2.38.6, Git/GitHub SSH, nvm 0.39.0, Node.js 22.22.3, Quartz 5, BasesPage, POSIX shell, Cloudflare Pages.

## Global Constraints

- Preserve the current vault layout: `景點/`, `區域/`, `捷運站/`, `書店/`, and `總彙.base` remain in place.
- Keep `.obsidian/` out of Git and out of the generated website.
- Use Quartz 5 configuration (`quartz.config.yaml`), never Quartz 4 TypeScript configuration conventions.
- Use `zh-TW`, `shortest` link resolution, no analytics, and self-contained fonts.
- Pin runtime and dependency state with `.nvmrc`, `package-lock.json`, and `quartz.lock.json`; never use `--latest` in CI.
- Build production from `main` and publish only `.quartz-site/public/`.
- Do not enable Obsidian Git automatic commit-and-sync until the local site passes functional and visual verification.

---

### Task 1: Vendor and initialize Quartz 5

**Files:**
- Create: `.quartz-site/**` from the official Quartz 5 `v5` source archive
- Create: `.quartz-site/.nvmrc`
- Create: `.quartz-site/QUARTZ_UPSTREAM`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: official `jackyzha0/quartz` `v5` branch and local nvm Node 22.22.3.
- Produces: a self-contained Quartz project at `.quartz-site/` with `npm ci` support.

- [ ] **Step 1: Record the pre-scaffold baseline**

Run:

```bash
git status --short --branch
test ! -e .quartz-site
zsh -lic 'nvm use 22 >/dev/null && node --version && npm --version'
```

Expected: clean `main...origin/main`, `.quartz-site` absent, Node reports `v22.22.3`.

- [ ] **Step 2: Resolve and record the exact Quartz 5 upstream commit**

Run:

```bash
git ls-remote https://github.com/jackyzha0/quartz.git refs/heads/v5
```

Expected: one 40-character commit SHA followed by `refs/heads/v5`. Save that exact SHA for `QUARTZ_UPSTREAM`; do not substitute `latest`.

- [ ] **Step 3: Scaffold from the pinned source archive**

Run:

```bash
quartz_sha="$(git ls-remote https://github.com/jackyzha0/quartz.git refs/heads/v5 | awk '{print $1}')"
case "$quartz_sha" in
  (*[!0-9a-f]*|'') exit 1 ;;
esac
test "${#quartz_sha}" -eq 40
quartz_tmp="$(mktemp -d)"
curl -fL "https://github.com/jackyzha0/quartz/archive/${quartz_sha}.tar.gz" -o "$quartz_tmp/quartz.tar.gz"
tar -xzf "$quartz_tmp/quartz.tar.gz" -C "$quartz_tmp"
test -f "$quartz_tmp/quartz-${quartz_sha}/package.json"
mkdir .quartz-site
cp -R "$quartz_tmp/quartz-${quartz_sha}/." .quartz-site/
test ! -e .quartz-site/.git
```

Expected: the archive download and structural assertion succeed; `.quartz-site/` contains the pinned Quartz source without nested Git metadata. The temporary directory may remain under the operating system temporary location until normal system cleanup.

- [ ] **Step 4: Pin Node and initialize the Obsidian template**

Create `.quartz-site/.nvmrc` containing:

```text
22
```

Create `.quartz-site/QUARTZ_UPSTREAM` containing the exact SHA from Step 2 followed by a newline. Then run:

```bash
cd .quartz-site
zsh -lic 'nvm use && npm ci && npx quartz create --template obsidian --strategy new --baseUrl taiwan-travel.pages.dev'
```

Expected: `content/`, `quartz.config.yaml`, `package-lock.json`, and `quartz.lock.json` exist; the template resolves its plugins without errors.

- [ ] **Step 5: Extend ignore rules**

Ensure `.gitignore` includes exactly these generated paths:

```gitignore
.quartz-site/content/
.quartz-site/public/
.quartz-site/node_modules/
```

- [ ] **Step 6: Verify scaffold integrity**

Run:

```bash
test -f .quartz-site/package.json
test -f .quartz-site/package-lock.json
test -f .quartz-site/quartz.config.yaml
test -f .quartz-site/quartz.lock.json
test "$(cat .quartz-site/.nvmrc)" = "22"
test ! -e .quartz-site/.git
git check-ignore .quartz-site/content .quartz-site/public .quartz-site/node_modules
```

Expected: every assertion succeeds and all three generated paths are ignored.

- [ ] **Step 7: Commit the vendored scaffold**

```bash
git add .gitignore .quartz-site
git commit -m "build: scaffold Quartz 5 site"
```

### Task 2: Build a deterministic publish-content staging layer

**Files:**
- Create: `scripts/prepare-content.sh`
- Create: `scripts/test-prepare-content.sh`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: vault directories `景點/`, `區域/`, `捷運站/`, `書店/` and file `總彙.base`.
- Produces: `.quartz-site/content/` containing only publishable content plus a generated unlisted homepage.

- [ ] **Step 1: Write the failing staging test**

The test must:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
content_root="$repo_root/.quartz-site/content"

"$repo_root/scripts/prepare-content.sh"

test -f "$content_root/index.md"
test -f "$content_root/總彙.base"
test -f "$content_root/景點/國立故宮博物院.md"
test -f "$content_root/區域/士林區.md"
test -f "$content_root/捷運站/士林站.md"
test -f "$content_root/書店/唐山書店.md"
test ! -e "$content_root/.obsidian"
test ! -e "$content_root/.git"
test ! -e "$content_root/docs"
test ! -e "$content_root/scripts"
test ! -e "$content_root/.quartz-site"
grep -q '^unlisted: true$' "$content_root/index.md"
grep -q '^# 臺灣旅行$' "$content_root/index.md"
grep -q '!\[\[總彙.base\]\]' "$content_root/index.md"

expected_notes="$(find "$repo_root/景點" "$repo_root/區域" "$repo_root/捷運站" "$repo_root/書店" -type f -name '*.md' | wc -l | tr -d ' ')"
actual_notes="$(find "$content_root/景點" "$content_root/區域" "$content_root/捷運站" "$content_root/書店" -type f -name '*.md' | wc -l | tr -d ' ')"
test "$actual_notes" = "$expected_notes"
```

- [ ] **Step 2: Run the test and confirm it fails**

Run:

```bash
bash scripts/test-prepare-content.sh
```

Expected: FAIL because `scripts/prepare-content.sh` does not exist.

- [ ] **Step 3: Implement the minimal allowlist script**

Implement `scripts/prepare-content.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
content_root="$repo_root/.quartz-site/content"

test -f "$repo_root/.quartz-site/package.json"
test -f "$repo_root/總彙.base"

rm -rf "$content_root"
mkdir -p "$content_root"

for source_dir in 景點 區域 捷運站 書店; do
  test -d "$repo_root/$source_dir"
  cp -R "$repo_root/$source_dir" "$content_root/$source_dir"
done

cp "$repo_root/總彙.base" "$content_root/總彙.base"

cat > "$content_root/index.md" <<'EOF'
---
title: 臺灣旅行
unlisted: true
---

# 臺灣旅行

![[總彙.base]]
EOF
```

Because repository editing policy requires patch-based source changes, create this script with `apply_patch`; the heredoc above is the required file content, not a shell file-writing instruction for implementation.

- [ ] **Step 4: Run the staging test**

Run:

```bash
bash scripts/test-prepare-content.sh
```

Expected: exit 0.

- [ ] **Step 5: Verify repeatability**

Run the script twice and compare sorted checksums:

```bash
bash scripts/prepare-content.sh
find .quartz-site/content -type f -print0 | sort -z | xargs -0 shasum > /tmp/taiwan-content-before.sha
bash scripts/prepare-content.sh
find .quartz-site/content -type f -print0 | sort -z | xargs -0 shasum > /tmp/taiwan-content-after.sha
diff -u /tmp/taiwan-content-before.sha /tmp/taiwan-content-after.sha
```

Expected: no diff.

- [ ] **Step 6: Commit the staging layer**

```bash
git add scripts/prepare-content.sh scripts/test-prepare-content.sh .gitignore
git commit -m "build: stage publishable vault content"
```

### Task 3: Configure Quartz 5 and BasesPage

**Files:**
- Modify: `.quartz-site/quartz.config.yaml`
- Modify: `.quartz-site/quartz.lock.json`

**Interfaces:**
- Consumes: generated `.quartz-site/content/` and the Quartz 5 plugin registry.
- Produces: a zh-TW Obsidian-compatible site configuration with BasesPage, UnlistedPages, and NoteProperties.

- [ ] **Step 1: Capture the generated configuration before edits**

Run:

```bash
cd .quartz-site
zsh -lic 'nvm use >/dev/null && npx quartz plugin list'
sed -n '1,260p' quartz.config.yaml
```

Expected: the Obsidian template plugins are listed and the YAML parses through the Quartz CLI.

- [ ] **Step 2: Add required plugins through the Quartz CLI**

Run sequentially:

```bash
cd .quartz-site
zsh -lic 'nvm use >/dev/null && npx quartz plugin add github:quartz-community/bases-page'
zsh -lic 'nvm use >/dev/null && npx quartz plugin add github:quartz-community/unlisted-pages'
zsh -lic 'nvm use >/dev/null && npx quartz plugin add github:quartz-community/note-properties'
```

Expected: each command succeeds, updates `quartz.config.yaml`, and records a resolved version in `quartz.lock.json`.

- [ ] **Step 3: Apply exact general configuration**

Set these YAML values while preserving template plugins and their generated ordering:

```yaml
configuration:
  pageTitle: "臺灣旅行"
  enableSPA: true
  enablePopovers: true
  analytics: null
  locale: zh-TW
  baseUrl: taiwan-travel.pages.dev
  ignorePatterns:
    - ".DS_Store"
  theme:
    fontOrigin: local
```

For the remaining generated theme keys, preserve the Obsidian template defaults. Configure the BasesPage entry with:

```yaml
options:
  defaultViewType: table
  linkResolution: shortest
```

Ensure CrawlLinks also uses `shortest`.

- [ ] **Step 4: Validate plugin lock and configuration**

Run:

```bash
cd .quartz-site
zsh -lic 'nvm use >/dev/null && npm ci && npx quartz plugin install && npx quartz plugin list'
rg -n 'bases-page|unlisted-pages|note-properties' quartz.config.yaml quartz.lock.json
```

Expected: dependency and plugin installation exit 0; all three plugins appear in config and lock files.

- [ ] **Step 5: Commit configuration**

```bash
git add .quartz-site/quartz.config.yaml .quartz-site/quartz.lock.json .quartz-site/package-lock.json
git commit -m "feat: configure Quartz Bases site"
```

### Task 4: Build and functionally verify the static site

**Files:**
- Generated only: `.quartz-site/public/**`

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces: verified static HTML in `.quartz-site/public/`.

- [ ] **Step 1: Verify the Base in Obsidian before Quartz conversion**

Run from a login shell:

```bash
obsidian base:query path="總彙.base" view="表格" format=json
```

Expected: JSON results consist only of notes under `景點/`; save the result count for comparison with Quartz output.

- [ ] **Step 2: Run the production build**

```bash
bash scripts/prepare-content.sh
cd .quartz-site
zsh -lic 'nvm use >/dev/null && npm ci && npx quartz plugin install && npx quartz build'
```

Expected: every command exits 0 and `.quartz-site/public/index.html` exists.

- [ ] **Step 3: Verify required artifacts and forbidden leakage**

Run:

```bash
test -f .quartz-site/public/index.html
find .quartz-site/public -type f | rg '總彙|%E7%B8%BD%E5%BD%99'
rg -l '國立故宮博物院' .quartz-site/public
! rg -l '\.obsidian|docs/superpowers|prepare-content\.sh|QUARTZ_UPSTREAM' .quartz-site/public
```

Expected: homepage, Base page, and Palace Museum content exist; forbidden repository-management content returns no matches.

- [ ] **Step 4: Serve over HTTP and verify routes**

Start:

```bash
cd .quartz-site
zsh -lic 'nvm use >/dev/null && npx quartz build --serve'
```

Verify with HTTP requests against `http://localhost:8080` for the homepage, Base page, `景點/國立故宮博物院`, `區域/士林區`, `捷運站/士林站`, and `書店/唐山書店`. Expected: HTTP 200 and no route resolves to a raw `.md` file or local absolute filesystem path.

- [ ] **Step 5: Verify interactive site data**

Inspect generated HTML and content index for Explorer, Search, Graph, Backlinks, NoteProperties, Darkmode, and BasesPage resources. Expected: each configured feature has corresponding generated markup or resource data.

- [ ] **Step 6: Record build verification**

Add a short dated verification section to the root `README.md` only after the commands above pass, including Node version, Quartz upstream SHA, note count, and build command. Do not place README into staged site content.

- [ ] **Step 7: Commit verified documentation**

```bash
git add README.md
git commit -m "docs: document Quartz build workflow"
```

### Task 5: Perform browser visual QA

**Files:**
- Modify only if needed after evidence: `.quartz-site/quartz.config.yaml` or Quartz-supported custom style file already present in the scaffold.

**Interfaces:**
- Consumes: the local HTTP site from Task 4.
- Produces: desktop and mobile visual verification of navigation and Base usability.

- [ ] **Step 1: Read the browser-control skill before using the browser**

Follow `browser:control-in-app-browser` and open `http://localhost:8080` in the in-app browser.

- [ ] **Step 2: Verify desktop behavior**

At a desktop viewport, inspect homepage, Base table, one detailed scenic note, Explorer, Search, Graph, backlinks, property rendering, dark mode, and popovers. Expected: Chinese text is readable, navigation works, Base columns and links render, and no raw YAML is exposed as page body.

- [ ] **Step 3: Verify mobile behavior**

At a mobile viewport, inspect the same homepage, Base table, and one detailed note. Expected: navigation remains usable and wide Base content scrolls or adapts without making the whole page unusable.

- [ ] **Step 4: Fix only observed visual defects**

If evidence shows a defect, add the smallest Quartz-supported configuration or CSS adjustment, rebuild, and repeat Steps 2–3. Do not port Border or Iconic wholesale.

- [ ] **Step 5: Commit any evidence-driven visual correction**

```bash
git add .quartz-site/quartz.config.yaml .quartz-site/quartz.layout.yaml .quartz-site/quartz/styles/custom.scss
git commit -m "style: refine Quartz vault presentation"
```

Stage only files that actually exist and changed.

### Task 6: Push the build source and connect Cloudflare Pages

**Files:**
- Modify: `README.md` only if the final Cloudflare URL differs from `taiwan-travel.pages.dev`
- Modify: `.quartz-site/quartz.config.yaml` only if `baseUrl` changes

**Interfaces:**
- Consumes: verified `main` branch and GitHub repository `jasonlam-swatow/taiwan-travel`.
- Produces: public Cloudflare Pages deployment that rebuilds on every push to `main`.

- [ ] **Step 1: Run final pre-push verification**

```bash
bash scripts/test-prepare-content.sh
bash scripts/prepare-content.sh
cd .quartz-site
zsh -lic 'nvm use >/dev/null && npm ci && npx quartz plugin install && npx quartz build'
cd ..
git diff --check
git status --short --branch
```

Expected: tests and build exit 0; only intentional source changes are present; generated content and public output remain ignored.

- [ ] **Step 2: Push verified source**

```bash
git push origin main
git fetch origin main
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)"
```

Expected: local and remote `main` SHAs match.

- [ ] **Step 3: Create the Cloudflare Pages project**

Using the authenticated Cloudflare dashboard, connect the private GitHub repository and set:

```text
Production branch: main
Framework preset: None
Build command: bash scripts/prepare-content.sh && cd .quartz-site && npm ci && npx quartz plugin install && npx quartz build
Build output directory: .quartz-site/public
Environment variable: NODE_VERSION=22
```

Expected: Cloudflare clones the repository, installs locked dependencies/plugins, builds, and serves the `public` output.

- [ ] **Step 4: Verify the deployed site**

Open the assigned `*.pages.dev` URL and repeat the critical homepage, Base, Chinese link, search, and mobile checks from Tasks 4–5. Expected: behavior matches local preview.

- [ ] **Step 5: Reconcile the actual URL**

If Cloudflare assigns a hostname other than `taiwan-travel.pages.dev`, change only `configuration.baseUrl` and the README URL, rebuild locally, commit with `fix: set deployed Quartz base URL`, and push once more.

### Task 7: Hand daily publishing to Obsidian Git

**Files:**
- No tracked file changes required; `.obsidian/` remains ignored.

**Interfaces:**
- Consumes: working `origin/main` tracking and deployed Cloudflare project.
- Produces: a verified Obsidian Git commit-and-sync workflow.

- [ ] **Step 1: Verify Obsidian Git integration through CLI**

```bash
zsh -lic 'obsidian plugin id=obsidian-git'
zsh -lic 'obsidian commands filter=obsidian-git'
```

Expected: Git 2.38.6 is enabled and commit, pull, push, and commit-and-sync command IDs are listed.

- [ ] **Step 2: Test a no-change push**

Execute the Obsidian Git push command through Obsidian CLI using the enumerated command ID. Expected: no authentication error and Git reports the branch is up to date.

- [ ] **Step 3: Configure conservative automation**

In Obsidian Git settings, retain pull-before-push, enable auto-pull on startup only on this Mac, and choose a 10–15 minute commit-and-sync interval only after the manual test succeeds. Do not enable SSH-based Obsidian Git automation on mobile while iCloud is also syncing the vault.

- [ ] **Step 4: Verify end-to-end deployment trigger**

Make one harmless content correction selected by the user, run Obsidian Git Commit-and-sync, and confirm Cloudflare starts and completes a new deployment for the resulting GitHub commit.

---

## Final Verification Checklist

- [ ] `git status --short --branch` is clean and tracks `origin/main`.
- [ ] `.obsidian/`, `.quartz-site/content/`, `.quartz-site/public/`, and `.quartz-site/node_modules/` are ignored and untracked.
- [ ] Content staging test passes twice with identical checksums.
- [ ] Node 22 `npm ci`, Quartz plugin install, and Quartz build all exit 0.
- [ ] Obsidian Base query and Quartz Base page contain the same `景點/` dataset.
- [ ] Local desktop and mobile browser checks pass.
- [ ] Cloudflare production deployment passes and uses the correct `baseUrl`.
- [ ] Obsidian Git manually pushes without authentication errors.
- [ ] The final deployed URL is documented in `README.md`.
