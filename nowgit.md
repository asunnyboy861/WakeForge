# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | WakeForge |
| **Git URL** | git@github.com:asunnyboy861/WakeForge.git |
| **Repo URL** | https://github.com/asunnyboy861/WakeForge |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ ENABLED (source: `/docs` folder) |

## App Store

| Item | Value |
|------|-------|
| **Apple ID** | 6832173708 |
| **App Store URL** | https://apps.apple.com/us/app/id6832173708 |
| **Custom Product Page** | https://apps.apple.com/us/app/wakeforge/id6832173708?ppid=14ef7a79-3cdc-4b9c-abaa-b0ba9544bf93 |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/WakeForge/ | ✅ Active |
| Support | https://asunnyboy861.github.io/WakeForge/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/WakeForge/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/WakeForge/terms.html | ✅ Active |

## Repository Structure

```
WakeForge/
├── WakeForge/                     # App target sources
│   ├── App/
│   ├── Models/
│   ├── Services/
│   ├── Features/
│   ├── DesignSystem/
│   ├── Intents/
│   ├── Shared/                    # Compiled into app + widget
│   ├── Resources/Assets.xcassets/
│   ├── PrivacyInfo.xcprivacy
│   └── Info.plist
├── WakeForgeWidget/               # WidgetKit + AlarmKit live activity
├── WakeForge.xcodeproj/
├── project.yml                    # xcodegen source of truth
├── docs/                          # Policy pages (GitHub Pages)
├── us.md
├── price.md
├── capabilities.md
├── icon.md
├── app_review_info.md
├── nowgit.md
├── keytext.md                     # ⚠️ excluded (.gitignore — confidential ASO)
├── COMPETITOR_REPORT.md           # ⚠️ excluded (.gitignore — confidential)
├── app_audit.md                   # ⚠️ excluded (.gitignore)
└── glmp_proxy_secret              # ⚠️ excluded (.gitignore — local dev key)
```

## Local-only files (never pushed)

- `GLMProxySecret.txt` — development key for the cloud AI proxy (approved locally only)
- `.env` — signing and image API credentials
- `keytext*.md`, `COMPETITOR_REPORT.md`, `app_audit*.md`, `improvement_plan_*.md`
