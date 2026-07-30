# 臺灣旅行

這個 Obsidian Vault 使用 [Quartz 5](https://quartz.jzhao.xyz/) 產生唯讀靜態網站。網站內容包括 `景點/`、`區域/`、`捷運站/`、`書店/` 與 `總彙.base`；`.obsidian/`、開發文件和建置工具不會發布。

## 本機預覽

```bash
bash scripts/prepare-content.sh
cd .quartz-site
nvm use
npm ci
npx quartz build --serve
```

瀏覽器開啟 <http://localhost:8080>。Node 版本由 `.quartz-site/.nvmrc` 固定為 22，Quartz 上游版本記錄於 `.quartz-site/QUARTZ_UPSTREAM`。

## 生產建置

```bash
bash scripts/prepare-content.sh
cd .quartz-site
npm ci
npx quartz build
```

輸出目錄是 `.quartz-site/public/`。

## Cloudflare Pages

- Production branch：`main`
- Framework preset：None
- Build command：`bash scripts/prepare-content.sh && cd .quartz-site && npm ci && npx quartz build`
- Build output directory：`.quartz-site/public`
- Environment variable：`NODE_VERSION=22`

## 驗證紀錄

- 驗證日期：2026-07-30
- Node.js：22.22.3
- Quartz：5.0.0（`507ad7f3d4601d83482f61930fccf1c77f42a072`）
- Vault 筆記：76 篇
- Obsidian 與 Quartz Bases：均顯示 20 個景點
