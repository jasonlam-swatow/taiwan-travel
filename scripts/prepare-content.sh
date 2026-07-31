#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
content_root="$repo_root/.quartz-site/content"

test -f "$repo_root/.quartz-site/package.json"
test -f "$repo_root/總彙.base"
test "$content_root" = "$repo_root/.quartz-site/content"

rm -rf "$content_root"
mkdir -p "$content_root"

for source_dir in 景點 區域 捷運站 書店; do
  test -d "$repo_root/$source_dir"
  cp -R "$repo_root/$source_dir" "$content_root/$source_dir"
done

cp "$repo_root/總彙.base" "$content_root/總彙.base"

cat > "$content_root/index.md" <<'EOF'
---
title: "🇹🇼 臺灣旅行"
unlisted: true
---

# 🇹🇼 臺灣旅行

![[總彙.base]]
EOF
