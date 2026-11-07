# WakeForge — iOS Development Guide

**Bundle ID**: `com.zzoutuo.WakeForge` (skill preset from `.env`; the guide's own bundle suggestion is intentionally overridden)
**Minimum iOS**: 26.0 (AlarmKit is the only supported alarm engine — no notification-based fallback)
**Category**: Health & Fitness (US market)
**Subtitle**: Earn your morning, no snooze
**Tagline**: No snooze. Just reps.

---

## Executive Summary

WakeForge is the alarm you cannot cheat. When the alarm fires, the user must complete a morning task verified on-device before the alarm can stop. Three verification families ship in v1:

1. **Rep tasks** (push-ups / squats) — 100% on-device Vision body-pose counting with dual-joint anti-cheat. Zero latency, zero cost, zero image upload.
2. **Photo tasks** (sky through the window, watered plant, made bed, breakfast) — semantic verification through GLM-5.3-Flash (cloud, paid quota), with Apple Foundation Models on-device as a free fallback.
3. **Step + mental challenges** — HealthKit step count, and short on-device generated quiz/semantic answers.

The differentiator is **reliability**: every task family has a 3-level degradation chain that ends in a 90-second "cool-down" release of the alarm. Every morning ends with the alarm off. This directly answers the #1 complaint against the market leader ("the quiz bug made my alarm impossible to stop").

A second differentiator is **audience breadth**: photo tasks let non-athletes (students, remote workers, older users) use the product, expanding the addressable market ~5x beyond push-up-only competitors.

**Target audience**: 18–40 self-improvement oriented iOS users in the US who already pay for habit/fitness apps and are heavy TikTok/Reels consumers.

**Monetization**: free tier (3 wakes per week, forever) + Pro subscription ($6.99/mo, $29.99/yr with 7-day trial) + BYO API Key mode (free Pro features when the user supplies their own model key).

---

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| **Erly** (market leader, ~$50K/mo, 200K downloads, 4.8★) | Proven AlarmKit implementation; viral TikTok motion; simple push-up concept | Cloud OpenAI video verification (slow, expensive, privacy-hostile); quiz bug makes the alarm impossible to stop in some states; paywall after a long onboarding; $9.99/mo | On-device rep counting (10x faster, free, private); 3-level degradation chain with a guaranteed 90-second release; 3-screen onboarding with pricing shown up front; 30% cheaper |
| **Alarmy** | Huge install base; many task types; brand recognition | Legacy alarm engine; photo verification is pixel matching, so a new angle or lighting fails; ad-heavy | Semantic (tolerant) photo verification; no ads; native AlarmKit Focus breakthrough |
| **Wayk** | AlarmKit based; clean UI | Occasional alarms that never ring; no post-wake verification ("wake up, then go back to bed") | Morning Chain follow-through check; failsafe keeper; secondary backup alarm |
| **PushClock** | Solid on-device rep counting | Fitness-only; no life tasks; confusing pricing | Rep tasks plus life tasks in one product; transparent 3-tier pricing |

**Positioning statement**: The only alarm that verifies your morning on-device, never traps you, and works even if you never do a push-up.

---

## ⚠️ Feature Inventory (MANDATORY)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | 3-screen onboarding | 1. Launch app → 2. Screen 1 shows a 3-second loop (alarm → 10 reps → off) → 3. Screen 2 pick default task (push-ups preselected) → 4. Screen 3 sees free quota + pricing → 5. Tap "Start free" | Task selection | Onboarding state machine; persists completion flag | Alarm list view | `UserDefaults.hasCompletedOnboarding`, `selectedTaskType` | Fresh install reaches the alarm list in ≤3 screens and ≤90 seconds; free quota is visible on screen 3 |
| 2 | Alarm list | 1. Open app → 2. See streak flame and alarm cards → 3. Toggle an alarm or tap "+ New Alarm" | Toggle, tap | Load profiles from SwiftData; reconcile against `AlarmManager.alarms` | Cards with time, task icon, switch | `AlarmProfile` (SwiftData) | Every persisted profile either exists in AlarmKit or is flagged "needs repair"; toggles update both stores |
| 3 | Create / edit alarm | 1. Tap + → 2. Wheel time picker defaults to last time −15 min → 3. Horizontally swipe task cards → 4. Difficulty slider (Easy/Standard/Hell) → 5. Save | Hour/minute, task type, target, repeat days, difficulty | Build `AlarmProfile`, then schedule through AlarmKit with `WFTaskMetadata` | Confirmation sheet + system alarm permission prompt | `AlarmProfile` + App Group shared store for widget/intents | Alarm appears in system alarm list; task type survives an app relaunch and is readable from the live activity |
| 4 | Alarm fires → task page | 1. System alarm alert appears over the lock screen → 2. User taps "Rise & Fight" (secondary intent) → 3. App opens the full-screen task view for that alarm | Alarm ID, task type, target (App Group) | `TaskEngine` resolves task type and starts the matching verifier | Full-screen task view with a 0/N counter | `WakeEvent` created immediately on fire | Path from tapping the live activity button to the task page renders in ≤2 seconds |
| 5 | Rep verification (push-ups / squats) | 1. Front camera preview appears with a 3-second pose guide → 2. User performs reps → 3. Skeleton overlay + counter increments on each complete rep → 4. Target reached | Camera frames | `VNDetectHumanBodyPoseRequest` → joint angles → hysteresis counter with a dual-joint anti-cheat check | Live skeleton overlay, big counter, haptic on each rep | Frame data is never persisted; only the final rep count lands in `WakeEvent` | Rep counter reaches the target with visible skeleton; 3 consecutive "no body detected" periods route into the degradation chain instead of an error |
| 6 | Photo verification | 1. Task asks for a specific photo → 2. Camera sheet → 3. Shutter → 4. Short "Verifying…" state → 5. Pass or retry prompt | JPEG (≤1MB), task prompt | `AIProviderRouter`: GLM (paid quota + network) → Apple Foundation Models → manual fallback | Verdict badge, reason text, retry button | Image is held in memory only; `photoDeleted=true` after 10 seconds | Image never touches disk; verdict arrives within 8 seconds or an automatic fallback appears |
| 7 | Step verification | 1. Task shows today's step goal → 2. User walks → 3. Progress ring updates → 4. Goal reached | HealthKit step samples | `HKStatisticsQuery` for today's step count | Progress ring + count | `WakeEvent` | With HealthKit permission granted, progress matches the Health app within a few steps |
| 8 | Mental / semantic challenge | 1. A short question appears (generated from streak and history) → 2. User types an answer → 3. Submit | Free text | Apple Foundation Models generates and judges; deterministic local question bank as fallback | Correct/incorrect feedback | `WakeEvent` | Works offline; an incorrect answer offers a retry, and 3 failures enter the degradation chain |
| 9 | Degradation chain + 90-second release | 1. Task fails → 2. Level 1 hint (reposition camera / retry photo) → 3. Level 2 switch to another task type → 4. Level 3 starts a 90-second cool-down → 5. Alarm stops and the day is recorded as a Skip Day | Failure events | `FailsafeKeeper` state machine, max 3 levels, forced `AlarmManager.stop` / `cancel` at the end | Level-specific guidance UI, cool-down timer | `WakeEvent.outcome` | No reachable state leaves the alarm ringing for more than 90 seconds |
| 10 | Celebration + streak | 1. Task passes → 2. Gold confetti full screen → 3. "+1 🔥" and counter update → 4. Optional share card | Task result | `StreakStore` increments current/best, accumulates lifetime reps | Confetti, streak flame, share card | `StreakState` (SwiftData) + `WakeEvent.outcome=.earned` | Streak increments exactly once per earned morning; relaunch shows the same value |
| 11 | Morning Chain | 1. After celebration an invitation appears → 2. Within 21 minutes complete up to 3 micro-steps (drink water, 30-second stretch, don't touch the phone) → 3. Claim completion | Step confirmations | `MorningChainStore` countdown and completion tracking | Checklist with a live countdown | SwiftData | Completing the chain awards a badge; missing the window closes it without penalizing the streak |
| 12 | Weekly report + stats | 1. Open Stats tab → 2. See this week's earns, skip days, total reps and a physical comparison | Aggregated events | `StatsService` aggregates 7 days and converts rep volume into a relatable height/floor metaphor | Charts, badges, comparison copy | Derived from SwiftData | Numbers match the underlying `WakeEvent` rows exactly |
| 13 | Paywall | 1. Triggered on the 4th wake, or from Settings → 2. Three tier cards side by side, yearly preselected → 3. Purchase restores entitlements | Product selection | StoreKit 2 `Product.products` + `Transaction` listener | Prices, per-day math, legal links | StoreKit entitlements | Monthly and yearly products both visible with prices; "Cancel anytime" text present; restore works |
| 14 | Settings | 1. Settings tab → 2. Sections: Task Market, AI & BYO, Subscription, Privacy, Support | Taps, key input | Routing + key storage | Grouped list | Keychain, UserDefaults | Subscription management deep link opens the system sheet; BYO key saves to Keychain and never appears in logs |
| 15 | Free weekly quota | 1. Each morning consumes one free wake → 2. At 3/3 the 4th wake shows a soft Pro prompt → 3. Sharing the streak card grants one extra wake | Wake events | `QuotaStore` weekly (Sunday-start) counter | Remaining-wakes chip | UserDefaults + SwiftData | Resets every Sunday; never blocks an in-progress alarm |
| 16 | Contact support | 1. Settings → Support → 2. Pick a preset topic tile → 3. Enter message → 4. Send | Topic, message, optional email | POST to the feedback backend | Success state / error state | None | Submission returns success feedback; failure keeps the draft |
| 17 | Backup alarm | 1. Toggle in alarm editor → 2. System schedules a second alarm 2 minutes later | Toggle | Schedules a second AlarmManager entry | Listed as "+2 min backup" | `AlarmProfile.hasBackup` | Backup alarm survives app termination |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 4.1 | Task page | Physical-key escape recovery | If the system stops the alarm while the task is unfinished, the next app open shows a make-up sheet | Auto-presented sheet |
| 5.1 | Rep task | Pose guide | 3-second animated silhouette showing a 45° side-on stance before the camera starts | Auto-played |
| 5.2 | Rep task | Rep haptic | `UIImpactFeedbackGenerator` on each completed rep | Haptic |
| 6.1 | Photo task | Low-confidence retry | `confidence < 0.7` shows "Try again" plus a lighting tip instead of a failure | Inline prompt |
| 8.1 | Mental task | Question bank fallback | 12 built-in questions used when Foundation Models is unavailable | Automatic |
| 10.1 | Celebration | Share card | Renders a streak card via `ImageRenderer` and shares through `ShareLink` | Sheet |
| 11.1 | Morning Chain | Countdown expiry | At 21:00 the chain closes and the badge is forfeited | Timer |
| 12.1 | Stats | Milestones | 7 / 30 / 100-day badges | Badge row |
| 13.1 | Paywall | Cost comparison | "$119.88/yr elsewhere vs $29.99/yr here" | Static block |
| 14.1 | Settings | System subscription sheet | `AppStore.showManageSubscriptions` | Button |
| 15.1 | Quota | Share-for-wake | One extra wake per week after sharing | Button |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Alarm created → alarm appears | Create alarm | Alarm list | `AlarmProfile` | Save |
| Alarm fires → task page opens | Live Activity intent | Task engine | alarm ID + task type (App Group) | User taps secondary button |
| Task passes → alarm stops | Task engine | AlarmKit | `AlarmManager.stop(id:)` + `cancel(id:)` | Verification success |
| Task settles → streak updates | Task engine | Streak store | outcome, rep count | Any settlement |
| Quota consumed → paywall eligibility | Quota store | Paywall | wake count | 4th wake |
| Task passes → Morning Chain offered | Celebration | Morning Chain | completion timestamp | Earned morning |
| Events → weekly report | Wake events | Stats | 7-day aggregate | Stats tab |

**Verification check**: 17 primary features and 12 sub-features, matching the guide's flows (onboarding, alarm CRUD, five task families, degradation chain, celebration/streak, Morning Chain, weekly report, paywall, settings, free quota, support, backup alarm). ✅

---

## Apple Design Guidelines Compliance

- **HIG — Clarity**: one dominant action per screen; the task view has a single primary control.
- **HIG — Deference**: dark, near-black surfaces with Liquid Glass materials; content carries the color.
- **HIG — Feedback**: haptics on each rep, spring scale on counter updates, and success/error states on every submission.
- **Accessibility**: VoiceOver labels on all controls, Dynamic Type through `.fontDesign(.rounded)` text styles, and success/failure never conveyed by color alone (icon + copy always present).
- **Guideline 3.1.2(c)**: the paywall shows title, length, price, auto-renewal disclosure, Privacy Policy, and Terms links.
- **Guideline 2.1(a)**: no dead-end AI buttons; every AI task has an on-device or manual fallback.
- **Guideline 1.4.1 / health claims**: positioned as a "morning discipline tool"; no medical or weight-loss claims.
- **Guideline 5.1.1**: camera frames and pose data never leave the device; photos are discarded after verification.

---

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (default free backend)
Photo semantics, quiz generation, and report copy prefer `FoundationModels` when available (iOS 26+ on supported hardware). On unsupported devices the app falls back to the local question bank and manual confirmation — never to an error dialog.

### Cloud GLM (paid tier)
GLM-5.3-Flash is reached through the project's Cloudflare Worker proxy (`cramjam-api.calcs.top`), registered by the `glm-api-config` skill for the real bundle ID `com.zzoutuo.WakeForge`. The app never calls `api.z.ai` directly and never embeds a dev key in source. The worker issues a per-install dev key that lives in Keychain.

### BYO API Key (optional advanced mode)
Settings → AI & BYO lets the user add OpenAI / Gemini / DeepSeek / Claude / GLM or any OpenAI-compatible endpoint (base URL + model + key triple). Keys are Keychain-only. With a user key, AI features are unlimited; the app never counts free generations.

### Dead-code prevention
No `freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, or `incrementGenerationCount()` anywhere.

---

## ⚠️ App Store Compliance — Subscriptions

- Product IDs: `com.zzoutuo.WakeForge.pro.monthly`, `com.zzoutuo.WakeForge.pro.yearly`. The legacy guide's `wakeforge.pro.*` prefix is overridden to match the bundle ID.
- Paywall must display: product title, duration, price, "Auto-renews unless cancelled 24 hours before the end of the period", Privacy Policy, Terms of Use, Restore Purchases, and a working Manage Subscription path.
- Free tier is a permanent weekly allowance (3 wakes per week), not a trial — it must never be described as a trial.

---

## Technical Architecture

- **Language**: Swift 6 (language mode 5), SwiftUI, async/await.
- **Alarm engine**: AlarmKit only (`AlarmManager`, `AlarmAttributes<WFTaskMetadata>`, `LiveActivityIntent`). Deployment target 26.0.
- **Widget**: WidgetKit extension rendering the AlarmKit live activity (countdown + "Rise & Fight").
- **Vision**: `VNDetectHumanBodyPoseRequest` + AVFoundation front camera.
- **On-device AI**: `FoundationModels` (`LanguageModelSession`), guarded by `#available(iOS 26.0, *)` and availability checks.
- **Cloud AI**: Cloudflare Worker proxy (GLM-5.3-Flash) + BYO OpenAI-compatible client.
- **Data**: SwiftData (`AlarmProfile`, `WakeEvent`, `ChainRecord`), `UserDefaults` for light state, App Group shared store for widget/intent handoff.
- **Billing**: StoreKit 2 with a `Transaction.updates` listener.
- **Support**: POST to `${FEEDBACK_BACKEND_URL}` (msg.calcs.top).

---

## Module Structure

```
WakeForge/
├── App/
│   ├── WakeForgeApp.swift
│   └── RootView.swift
├── Models/
│   ├── AlarmProfile.swift
│   ├── WakeEvent.swift
│   ├── TaskType.swift
│   └── StreakModels.swift
├── Services/
│   ├── AlarmScheduler.swift
│   ├── AppGroupStore.swift
│   ├── TaskEngine.swift
│   ├── RepCounter.swift
│   ├── CameraSession.swift
│   ├── AIProviderRouter.swift
│   ├── GLMClient.swift
│   ├── BYOClient.swift
│   ├── AppleAIService.swift
│   ├── PhotoVerifyService.swift
│   ├── StepsService.swift
│   ├── QuotaStore.swift
│   ├── StreakStore.swift
│   ├── FailsafeKeeper.swift
│   └── SubscriptionManager.swift
├── Features/
│   ├── Onboarding/
│   ├── AlarmList/
│   ├── AlarmEditor/
│   ├── TaskRunner/
│   ├── Celebration/
│   ├── MorningChain/
│   ├── Stats/
│   ├── Paywall/
│   └── Settings/
├── DesignSystem/
│   ├── WFTheme.swift
│   └── Components.swift
└── Intents/
    └── WFAlarmIntents.swift

WakeForgeWidget/
└── WakeForgeWidgetBundle.swift
```

---

## ⚠️ Data Flow

```
Feature: Alarm firing → task → settlement
AlarmProfile ──schedule──> AlarmManager (AlarmKit)
        │                         │
        └── App Group store ──────┘ (alarmID → taskType/target)
                                  │
                          user taps secondary intent
                                  │
                          TaskEngine (dispatch by type)
             ┌────────────────────┼────────────────────┐
        RepCounter           PhotoVerify          Steps / Quiz
      (Vision, on-device)   (GLM → Apple AI →     (HealthKit /
                             manual fallback)      FoundationModels)
             └────────────────────┼────────────────────┘
                          TaskResult (pass/fail)
                                  │
                  AlarmManager.stop + cancel (dual safety)
                                  │
              WakeEvent(.earned/.fallback/.skipDay) + StreakStore
                                  │
                    Celebration → Morning Chain → Stats
```

```
Feature: Photo verification privacy lifecycle
Camera ──JPEG (memory)──> compress ≤1MB ──> AIProviderRouter
                                                  │
                          verdict + confidence <──┘
                                                  │
                          schedule 10s discard ──> photoDeleted = true
```

```
Feature: Free quota
WakeEvent(.earned/.fallback) ──> QuotaStore.consume() ──> weekly count
                                                          │
                              count >= 3 ──> soft Pro prompt on next wake
```

---

## Implementation Flow

1. Xcode project via xcodegen: app target + widget extension, App Group, entitlements, Info.plist usage strings.
2. Design system: Forge Orange `#FF6A00`, Sunrise Gold `#FFC24B`, Motivation Green `#34C759`, near-black surfaces, SF Pro Rounded.
3. Models + SwiftData container; App Group shared store.
4. AlarmScheduler over AlarmKit (authorization, schedule, cancel, reconcile).
5. Widget extension live activity for `AlarmAttributes<WFTaskMetadata>`.
6. Task engine + rep counter + camera session.
7. Photo / steps / mental verifiers with the degradation chain.
8. Celebration, streak, Morning Chain, stats.
9. StoreKit 2 manager, paywall, quota.
10. Settings, BYO, support.
11. Build on iPhone + iPad simulators, then push to GitHub.

---

## UI/UX Design Specifications

- **Palette**: background `#0A0A0B`, surface `#141416`, Forge Orange `#FF6A00`, Sunrise Gold `#FFC24B`, Motivation Green `#34C759`, muted gray `#8E8E93`.
- **Typography**: SF Pro Rounded; task counter ≥ 96pt `.black`; section titles 28pt bold; body 15–17pt.
- **Layout**: 20pt horizontal padding, 24pt card radius, single-thumb reachable actions, no menu deeper than 2 levels.
- **Motion**: counter spring scale 0.15s, confetti 0.8s, streak flame idle pulse; nothing else animated.
- **Localization details (US)**: week starts Sunday, feet/miles units, plain-spoken copy ("Rise & Fight", "Skip Day", "Earn your morning").

---

## Code Generation Rules

- One feature per module; MVVM; no business logic in views.
- Never hardcode prices, version strings, or API keys.
- Every verification `catch` falls through to the degradation chain — never an alert.
- Alarm stop never depends on network.
- No comments unless the logic is genuinely non-obvious.
- Apple-native first; only `FoundationModels`/`Vision`/`AlarmKit`/`StoreKit`/`HealthKit`/`SwiftData`.

---

## Build & Deployment Checklist

1. `xcodegen generate` succeeds.
2. Builds clean for `iphonesimulator`.
3. Runs on iPhone 17 simulator: onboarding → create alarm → alarm list.
4. Task page reachable via the debug "simulate wake" entry.
5. StoreKit test configuration loads both products.
6. Privacy manifest declares no tracking and no image collection.
7. Push to GitHub; policy pages deployed; keytext prepared; final audit verdict READY.
