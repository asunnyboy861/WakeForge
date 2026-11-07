# Pricing Configuration

## Monetization Model: Subscription (IAP)

Free download with a permanent weekly free allowance, two auto-renewable Pro tiers, and a BYO API key path that unlocks Pro features without a payment. No lifetime or one-time purchase exists, because cloud photo verification carries an ongoing per-use cost.

## Subscription Group
- **Group Name**: WakeForge Pro
- **Reference Name**: WakeForge Pro
- **Products in group**: com.zzoutuo.WakeForge.pro.monthly, com.zzoutuo.WakeForge.pro.yearly

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: WakeForge Pro Monthly
- **Product ID**: `com.zzoutuo.WakeForge.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $6.99 USD per month
- **Display Name**: `WakeForge Pro Monthly` (20 chars, ≤35 ✅)
- **Description**: `Unlimited wakes and daily photo verification.` (46 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: WakeForge Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription
- **Reference Name**: WakeForge Pro Annual
- **Product ID**: `com.zzoutuo.WakeForge.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $29.99 USD per year (64% savings vs monthly, about $0.08 per day)
- **Display Name**: `WakeForge Pro Annual` (19 chars, ≤35 ✅)
- **Description**: `Unlimited wakes, more daily photo checks, plus badges.` (55 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: WakeForge Pro (same group as monthly)
- **Restore Purchases**: ✅ Required

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - 3 task alarms per week (resets every Sunday)
  - All task families: push-ups, squats, photo, steps, mental challenge
  - Full streak tracking, best streak, and weekly report
  - On-device AI for mental challenges and report copy, unlimited
  - Morning Chain follow-through
- **Conversion hooks**:
  - "This week's 3 free wakes are done. Pro is $6.99/mo, or earn one more wake by sharing your streak."
  - "Pro adds unlimited wakes and cloud photo verification that actually understands your photo."
  - "One year of WakeForge costs less than three months of a typical subscription alarm."

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Pro (Monthly / Annual) |
|---------|:----:|:----------------------:|
| Task alarms per week | 3 | Unlimited |
| Push-up / squat rep verification | ✅ | ✅ |
| Photo task verification, on-device fallback | ✅ | ✅ |
| Photo task verification, cloud GLM (tolerant, anti-cheat) | ❌ | ✅ Daily quota (3 monthly / 5 annual) |
| Step and mental challenges | ✅ | ✅ |
| Streak, best streak, weekly report | ✅ | ✅ |
| Morning Chain | ✅ | ✅ |
| Custom alarm sounds and themes | ❌ | ✅ |
| Milestone share cards (7 / 30 / 100) | Basic | Full set |
| Backup alarm (+2 minutes) | ❌ | ✅ |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial on the Annual tier only (auto-converts to $29.99/year unless cancelled at least 24 hours before the end of the trial)
- **Available for**: Yearly tier

## Policy Pages Required
- Support Page: ✅ (must include subscription management and cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (required for auto-renewable subscriptions)
- **Total policy pages**: 3

## BYO API Key Model

- **Price**: Free (user supplies the key)
- **Unlocks**: All Pro features while a valid key is stored, including unlimited cloud photo verification billed to the user's own provider account
- **Value framing**: The subscription unlocks app features (unlimited wakes, custom sounds, backup alarm). AI generation is always unlimited for a user with their own key — never counted, never gated
- **No free-generation counting**: `freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, and `incrementGenerationCount()` must not exist in the codebase
- **Supported providers**: GLM, OpenAI, Gemini, DeepSeek, Claude, or any OpenAI-compatible base URL + model + key triple
- **Key storage**: Keychain only; never bundled in the binary, never logged

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView (both tiers shown side by side, annual preselected but monthly fully tappable)
- [x] Free trial terms included for the annual tier
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] "Cancel anytime in Settings → Subscription" disclosure on the paywall
