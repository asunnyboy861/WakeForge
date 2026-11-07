# Capabilities Configuration

## Analysis
Requirements detected from the guide and `us.md`:

| Keyword found | Capability |
|---|---|
| AlarmKit, alarm, wake-up alarm (guide §3.3: iOS 26+ only) | AlarmKit + `NSAlarmKitUsageDescription` |
| Live Activity, lock screen countdown, Dynamic Island, Widget Extension (§7.2) | WidgetKit extension |
| Widget + intents need shared alarm metadata | App Groups `group.com.zzoutuo.WakeForge` |
| 步数 / steps / HealthKit (§6.1) | HealthKit read |
| 相机 / camera / front camera (§7.3) | Camera usage string |
| 拍照 / photo capture | Camera (no photo-library write) |
| 订阅 / subscription / paywall (§9) | In-App Purchase (StoreKit 2) |
| 通知 / notification | Not used — AlarmKit alerts replace local notifications |
| iCloud / sync | Not used in v1 (local SwiftData only) |
| Apple Watch | Not requested |

## Auto-Configured Capabilities

| Capability | Status | Method |
|---|---|---|
| AlarmKit | ✅ Configured | `NSAlarmKitUsageDescription` in `WakeForge/Info.plist`; no extra entitlement needed |
| Widget extension (Live Activity) | ✅ Configured | `WakeForgeWidgetExtension` app-extension target, `NSExtensionPointIdentifier = com.apple.widgetkit-extension` |
| App Groups | ✅ Configured in project | `com.apple.security.application-groups = group.com.zzoutuo.WakeForge` in both entitlements files |
| HealthKit | ✅ Configured in project | `com.apple.developer.healthkit = true` + `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` |
| Camera | ✅ Configured | `NSCameraUsageDescription` |
| In-App Purchase | ✅ Configured in code | StoreKit 2 (no entitlement required) |
| Privacy manifest | ✅ Configured | `PrivacyInfo.xcprivacy` in App target (UserDefaults + FileTimestamp) and Widget target (UserDefaults) |
| Export compliance | ✅ Configured | `ITSAppUsesNonExemptEncryption = false` |
| Deep link scheme | ✅ Configured | `wakeforge://` URL type |

## Manual Configuration Required

| Capability | Status | Steps |
|---|---|---|
| Device signing (App Groups + HealthKit) | ⏳ DEFERRED | Sign into Xcode with the Apple ID for team `JP4TN5PTS3`, then run `xcodebuild -project WakeForge.xcodeproj -scheme WakeForge -destination 'generic/platform=iOS' -allowProvisioningUpdates build`. Xcode auto-registers the App Group `group.com.zzoutuo.WakeForge` and the HealthKit capability on the portal. Required before Archive/TestFlight. |
| App Group registration | ⏳ Pending (portal) | Auto-created by the command above, or add `group.com.zzoutuo.WakeForge` manually under Identifiers → App Groups |
| Subscription products in App Store Connect | ⏳ Pending | Create `com.zzoutuo.WakeForge.pro.monthly` and `com.zzoutuo.WakeForge.pro.yearly` (see `price.md`) |

## No Configuration Needed
- Push Notifications (AlarmKit alerts are system-scheduled alarms, not push)
- Background modes (no background refresh required)
- iCloud / CloudKit (v1 is local-only)
- Apple Watch
- Location services
- Photo library (capture happens through AVFoundation; images never leave memory)

## Verification
- Build (iphonesimulator, iPhone 16): ✅ **BUILD SUCCEEDED**
- Entitlements written for both targets: ✅
- Signing verification (generic/platform=iOS): ⏳ DEFERRED — provisioning profile lacks App Groups + HealthKit; requires one `-allowProvisioningUpdates` build after Xcode account sign-in
- DEVELOPMENT_TEAM: `JP4TN5PTS3` baked at project level (all targets inherit)
- PrivacyInfo.xcprivacy: App + Widget targets covered
