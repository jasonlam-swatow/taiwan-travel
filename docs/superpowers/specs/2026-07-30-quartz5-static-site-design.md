# Quartz 5 靜態網站部署設計

## 目標

將目前的「🇹🇼 臺灣旅行」Obsidian Vault 部署為免費、公開、唯讀的靜態網站。網站直接展示全部筆記與 `總彙.base`，以 Quartz 5 的 Obsidian 相容性、BasesPage 支援和可維護性為優先，不要求逐像素複製 Obsidian 的 Border 主題或插件介面。

## 已核實的 Quartz 5 能力

- Quartz 5 要求 Node.js 22 或以上；依賴首次使用 `npm i`，後續及 CI 使用 `npm ci` 從 lockfile 可重現安裝。
- Quartz 的網站內容必須位於專案的 `content/`，首頁內容固定為 `content/index.md`。
- `obsidian` template 啟用 Obsidian Flavored Markdown，並固定使用 Obsidian 預設的 `shortest` wikilink 解析策略。
- `BasesPage` 是 Quartz 5 社群插件，能把 `.base` 渲染成 build-time HTML，支援 table、list、cards、多視圖 tabs、遞迴 filters、formulas、summaries、property display names 及 cell wikilinks；map 目前僅為預留。
- 插件由 `quartz.config.yaml` 宣告，使用 `npx quartz plugin install` 從 `quartz.lock.json` 的已鎖版本安裝。
- 官方 Cloudflare Pages 設定使用 `npx quartz plugin install && npx quartz build`，輸出目錄為 `public`。

參考：

- <https://quartz.jzhao.xyz/getting-started/installation>
- <https://quartz.jzhao.xyz/getting-started/authoring-content>
- <https://quartz.jzhao.xyz/configuration>
- <https://quartz.jzhao.xyz/features/bases>
- <https://quartz.jzhao.xyz/plugins/basespage>
- <https://quartz.jzhao.xyz/hosting>
- <https://raw.githubusercontent.com/jackyzha0/quartz/v5/quartz/i18n/index.ts>
- <https://github.com/Vinzent03/obsidian-git>
- <https://publish.obsidian.md/git-doc/Authentication>

## 公開範圍

- 公開 Vault 內全部 Markdown 筆記、`總彙.base` 與日後加入的內容附件。
- 公開筆記 frontmatter，包括地址、地圖、開放時間、區域、捷運站及附近景點等欄位。
- 公開目前內容為空的區域與捷運站筆記。
- 不發布 `.obsidian`、`.git`、`.quartz-site` 原始碼、`docs/superpowers`、系統檔案、部署說明及構建輸出。

## 專案結構

現有 Vault 保持在倉庫根目錄；景點筆記位於 `景點/`。Quartz 5 專案放入 Obsidian 不顯示的隱藏資料夾：

```text
Vault 根目錄/
├── .obsidian/                 # 本機設定，不進 Git、不發布
├── .quartz-site/              # Quartz 5 專案原始碼
│   ├── .nvmrc                 # 固定 Node.js 22
│   ├── content/               # 構建前產生，不進 Git
│   ├── quartz.config.yaml
│   ├── quartz.lock.json
│   ├── package.json
│   ├── package-lock.json
│   └── public/                # 構建輸出，不進 Git
├── scripts/
│   └── prepare-content.sh     # 建立 .quartz-site/content
├── docs/superpowers/          # 規格與計畫，不發布
├── 景點/                      # Base 的資料來源
├── 總彙.base
└── 區域/、捷運站/、書店/
```

不使用 `content` symlink：本機 symlink 指向 Vault 根目錄，推送到 Cloudflare 後可能成為失效或遞迴連結。構建前以可重現腳本建立實體 `content/` 暫存副本。

## 資料流與部署

1. 使用者照常在目前 Vault 根目錄編輯筆記。
2. `scripts/prepare-content.sh` 清空並重建 `.quartz-site/content`，複製 `景點/`、`區域/`、`捷運站/`、`書店/`、`總彙.base` 及允許公開的內容附件，保留相對路徑。
3. 腳本新增 `.quartz-site/content/index.md` 作為首頁；首頁標記 `unlisted: true`，只負責將訪客導向／嵌入 `總彙.base`，因此不會被 BasesPage 收進資料表，也不在 Vault 根目錄新增會干擾篩選的筆記。
4. 在 `.quartz-site` 執行 `npm ci`、`npx quartz plugin install` 及 `npx quartz build`。
5. Cloudflare Pages 發布 `.quartz-site/public`。
6. 每次推送 GitHub 後，Cloudflare 重新執行同一流程。
7. 日常發布由 Obsidian Git 的 `Commit-and-sync` 完成；它提交 Vault 變更、pull、push 至 `origin/main`，再由 Cloudflare 接手構建。

## Quartz 配置

- 使用 Quartz 5 `obsidian` template，不使用 Quartz 4 的 TypeScript 配置格式。
- 本機使用 nvm 0.39.0 與已安裝的 Node.js 22.22.3；`.nvmrc` 寫入 `22`，所有本機 Quartz 命令前先執行 `nvm use`。
- `configuration.pageTitle` 設為「臺灣旅行」。
- `configuration.locale` 設為 Quartz 5 `TRANSLATIONS` registry 已明確列出的 `zh-TW`。
- `configuration.baseUrl` 初始設為 `taiwan-travel.pages.dev`，不含 `https://` 與前後斜線；若 Cloudflare 專案實際使用其他名稱，只修改此一設定。
- `configuration.analytics` 設為 `null`。
- 啟用 SPA、popover、Explorer、Search、Darkmode、Graph、Backlinks、NoteProperties、ContentPage、FolderPage、TagPage、Assets、Static 和 BasesPage。
- 啟用 UnlistedPages，使生成的 `index.md` 保持可直接訪問但不出現在 Base、Explorer、Search、Graph、folder 和 tag listings；BasesPage 官方文件明確排除 `unlisted` 頁面。
- BasesPage 的 `linkResolution` 與 CrawlLinks 都使用 `shortest`。
- 字型使用 Quartz 支援的 local/self-contained 模式，避免訪客載入 Google Fonts；顏色採 Quartz 預設或輕度調整，不移植 Border CSS。
- 使用 `ignorePatterns` 作為第二層保護；主要發布邊界仍由 `prepare-content.sh` 的 allowlist 控制。

## Base 行為

- `總彙.base` 使用其第一個 `table` view。
- 保留欄位順序：`file.name`、`區域`、`捷運站`、`開放時間`、`附近景點`、`tags`。
- 保留已在 Obsidian 中生效的 `file.folder == "景點"` 篩選。
- 以 Obsidian CLI 查詢結果與 Quartz 5 BasesPage 輸出交叉驗證兩端均只列出 `景點/` 筆記；只有確認 expression engine 不相容後，才對 Base 作最小且同時相容於 Obsidian 的調整。
- Base 是構建時生成的靜態 HTML；訪客可使用渲染器提供的排序與 tab 互動，但不能修改或寫回 Vault。

## 安全與版本管理

- GitHub 倉庫使用私有可見性；只有 Cloudflare 的生成網站公開。
- Git remote 固定為 `git@github.com:jasonlam-swatow/taiwan-travel.git`，預設分支及 Cloudflare production branch 均為 `main`。
- `.obsidian` 不進 Git，避免上傳工作區、同步和插件配置。
- `.quartz-site/content` 與 `.quartz-site/public` 不進 Git，避免重複資料和意外發布管理文件。
- Quartz 本體由 `package-lock.json` 鎖定；社群插件由 `quartz.lock.json` 鎖定。CI 使用 `npm ci` 與 `npx quartz plugin install`，不使用 `--latest`。
- 構建腳本採 allowlist，只接受公開內容類型與明確內容路徑；未知的隱藏資料夾、部署檔案和管理文件預設不複製。
- 任一步內容準備、依賴安裝、插件安裝或構建失敗時立即停止，不發布不完整輸出。
- Obsidian Git 只操作既有 repository，不執行 Initialize 或 Clone；首次 upstream 已設定為 `origin/main`。自動 commit-and-sync 在網站驗證完成後才啟用。

## 本機驗證

- 使用 Node.js 22 或以上執行完整安裝與構建。
- 執行 `npx quartz build --serve`，通過 HTTP 預覽而非直接開啟 HTML。
- 驗證首頁、`總彙.base`、至少一篇 `景點/` 筆記、一篇區域筆記、一篇捷運站筆記和一篇書店筆記。
- 驗證中文檔名、全形括號、en dash 檔名和 wikilinks 的實際網址。
- 驗證搜尋、Explorer、Graph、Backlinks、NoteProperties、深淺色切換與 Base 表格。
- 在桌面及手機寬度目視驗證；Base 表格必須可操作，不得造成整頁不可用的橫向溢出。

## 驗收標準

- `npm ci`、插件安裝及 Quartz build 均退出碼為 0。
- `public` 中存在首頁、Base 頁、搜尋索引及必要靜態資源。
- Base 表格列出預期的 `景點/` 筆記，指定六個欄位可見，內部連結可點擊。
- 所抽查的中文 wikilinks 均跳轉到正確 HTML 頁面，沒有 `.md` 原始路徑或本機絕對路徑。
- `.obsidian`、`.git`、Quartz 原始碼、`scripts`、README、規格與計畫文件不出現在公開內容或搜尋索引。
- 本機預覽在桌面和手機尺寸可正常導航和閱讀。

## 非目標

- 不提供登入、編輯、留言、資料庫或將網站操作同步回 Obsidian。
- 不購買網域。
- 不逐像素複製 Border 主題。
- 不移植 Iconic 或 Style Settings 插件。
- 不在首期加入分析、廣告或其他第三方追蹤。

## 外部發布邊界

本機搭建和驗證完成後，建立 GitHub 私有倉庫、推送內容及連接 Cloudflare Pages 都屬於外部操作。執行前需要使用者完成相應帳號授權；在授權不可用時，交付可直接推送與部署的本機倉庫，不以未完成的遠端發布冒充已上線。
