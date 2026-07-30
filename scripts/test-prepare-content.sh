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
