# App Review Information

## Demo Account
No account or sign-in is required. The app is fully usable on first launch. Reviewers can create an alarm, run a task, and see the streak without any setup.

## AlarmKit
WakeForge schedules alarms exclusively through AlarmKit (iOS 26+). The app adds `NSAlarmKitUsageDescription` to Info.plist and requests authorization on the first save. AlarmKit alerts break through Focus and Silent mode. Tapping the secondary "Rise & Fight" button opens the task screen. When a task is verified, the app calls `AlarmManager.stop` and `AlarmManager.cancel` as a dual-safety path for the known iOS 26.2 `stopIntent` issue.

Physical buttons can stop a system alarm — this is the platform behavior. WakeForge does not claim otherwise; instead it records an escape and shows a make-up task the next time the app opens, and it always releases the alarm within 90 seconds if no task is completed.

## Subscription Testing
- `com.zzoutuo.WakeForge.pro.monthly` — $6.99 / month
- `com.zzoutuo.WakeForge.pro.yearly` — $29.99 / year, 7-day free trial
- Both belong to the "WakeForge Pro" subscription group
- Free tier: 3 task alarms per week (permanent, not a trial)
- Paywall shows both prices, per-day math, auto-renewal disclosure, Privacy Policy, Terms of Use, Restore Purchases, and Manage Subscription

## HealthKit
The app uses HealthKit read-only access to `stepCount` so a step task can be verified.
- Settings contains a section headed "Apple Health (HealthKit)" with the HealthKit icon
- The row "HealthKit Integration" has a "Learn More" button opening `HealthKitInfoView`
- The toggle is labeled "Verify step tasks with HealthKit"
- WakeForge never writes to Apple Health

## AI Features
- **Apple Intelligence** is the default free backend for mental challenges and report copy on supported devices. No key is required.
- **Cloud photo verification** is a Pro feature served through the project's Cloudflare Worker proxy; the app never calls a model provider directly and never embeds a key in the binary.
- **BYO API key (optional)**: Settings → AI & BYO lets a user enter a base URL, model, and key for an OpenAI-compatible endpoint. Keys live in the Keychain. With a user key, AI features are unlimited and never counted.
- Photo verification always falls back to an explicit user confirmation if no cloud channel is reachable, so no AI path is a dead end.
- No specific AI brand is advertised in the UI; no ChatGPT/OpenAI wording appears in user-facing strings.

## Privacy
- Camera frames are processed on device with Vision; video never leaves the phone and is never stored.
- Task photos are held in memory, compressed under 1MB, sent only to the verification endpoint when the user is subscribed, and discarded 10 seconds after verification. `photoDeleted` is recorded with each wake event.
- The Privacy manifest declares no tracking and no collected data types.

## China App Store Compliance
The app does not include ChatGPT functionality and does not reference ChatGPT/OpenAI in user-facing UI or metadata. The AI layer is a generic provider router plus the project's Cloudflare Worker channel.

## Required Links (in-app)
- Privacy Policy: https://asunnyboy861.github.io/WakeForge/privacy.html
- Terms of Use: https://asunnyboy861.github.io/WakeForge/terms.html
- Support: https://asunnyboy861.github.io/WakeForge/support.html

All three are reachable from Settings → Legal and from the Paywall.

## Notes for Testers
The app is a "morning discipline tool", not a medical or weight-loss product. It makes no health claims.

On the simulator there is no front camera and AlarmKit alerts do not ring; the Debug build includes a "Debug: simulate a wake" entry to walk the task flow.
