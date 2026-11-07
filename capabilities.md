# WakeForge 上线前配置清单 / Launch Configuration Checklist

## 一、必须手动完成的配置（按顺序）

| # | 项目 | 具体操作 | 为什么必须手动 |
|---|------|---------|----------------|
| 1 | 真机签名与能力注册 | 用 Apple ID 登录 Xcode（Team `JP4TN5PTS3`），然后执行：`xcodebuild -project WakeForge.xcodeproj -scheme WakeForge -destination 'generic/platform=iOS' -allowProvisioningUpdates build` | 需要 Apple 开发者门户登录，AI 无法代替账号授权 |
| 2 | App Group 注册 | 上述命令会自动在 Identifiers → App Groups 注册 `group.com.zzoutuo.WakeForge`；若失败，手动新建同名 App Group 并勾选两个 target | 门户操作 |
| 3 | HealthKit 能力 | 上述命令会自动开启 HealthKit；若失败，在 Identifiers 里为 `com.zzoutuo.WakeForge` 勾选 HealthKit | 门户操作 |
| 4 | 订阅产品 | App Store Connect → 订阅 → 新建订阅组 `WakeForge Pro`，创建：`com.zzoutuo.WakeForge.pro.monthly`（$6.99/月）、`com.zzoutuo.WakeForge.pro.yearly`（$29.99/年 + 7 天免费试用） | ASC 网页操作 |
| 5 | 商店资料 | 用 `keytext.md` 填名称/副标题/关键词/描述/推广文本/审核备注；分类 Health & Fitness；版权 `Copyright © 2026 he zhou` | ASC 网页操作 |
| 6 | 云 AI 开发密钥（可选） | 如需在测试期使用共享云通道：把 `~/.local/share/glm_secrets/glm_dev_key` 的内容写入 `WakeForge/GLMProxySecret.txt`（该文件已在 `.gitignore`，Release 构建通过 `EXCLUDED_SOURCE_FILE_NAMES` 排除）。不配置时：Pro 用户走订阅 JWS 通道，其他用户可由 BYO Key 或手动作答完成照片任务 | 密钥写入需要你本人确认 |
| 7 | 真机验收 | 在 iPhone 上：允许闹钟权限 → 保存闹钟 → 锁屏等待响铃 → 点 Rise & Fight → 做俯卧撑计数 → 关闭；再试照片/步数/脑力 | 模拟器没有相机，AlarmKit 不响铃 |
| 8 | 截图 | App Store 截图由你自行完成（本流程不代做） | 个人偏好 |

## 二、已自动完成（无需操作）

| 项目 | 状态 |
|------|------|
| Xcode 工程（App + Widget Extension） | ✅ `project.yml` → xcodegen 生成 |
| App 图标（1024，无 alpha） | ✅ `Assets.xcassets/AppIcon` |
| App Group entitlement（两个 target） | ✅ 已写入工程，等待第 1 步签名生效 |
| HealthKit entitlement + 权限文案 | ✅ 已写入工程 |
| 相机 / 相册 / 闹钟用途文案 | ✅ `Info.plist` |
| Live Activity（锁屏/灵动岛） | ✅ Widget target |
| PrivacyInfo.xcprivacy | ✅ App + Widget |
| 出口合规 | ✅ `ITSAppUsesNonExemptEncryption = false` |
| StoreKit 2 订阅与付费墙 | ✅ 双产品、恢复购买、法律链接、自动续订说明 |
| BYO API Key（Keychain） | ✅ 设置页可配置任意 OpenAI 兼容端点 |
| HealthKit UI 标识（分区头/Learn More/脚注） | ✅ |
| 免费额度（每周 3 次，周日重置） | ✅ |
| 联系支持（7 个预设主题 + 后端提交） | ✅ `msg.calcs.top` |
| 政策页（Support / Privacy / Terms / Landing） | ✅ GitHub Pages 已上线 |
| GitHub 仓库 | ✅ https://github.com/asunnyboy861/WakeForge |

## 三、上线前验证要点

- 免费第 4 次唤醒出现软性 Pro 提示，不阻塞关闹钟
- 断网时照片任务降级为手动作答，闹钟仍可在 90 秒内关闭
- 年付显示 7 天试用与「$0.08/天」，月付同屏可点
- 付费墙可见 Privacy Policy / Terms of Use / 自动续订说明
- ASC 隐私标签：不追踪、不收集图像数据（姿态端侧、照片 10 秒销毁）

## 四、Technical Summary (English)

| Item | Value |
|------|-------|
| Bundle ID | `com.zzoutuo.WakeForge` |
| Widget Bundle ID | `com.zzoutuo.WakeForge.Widget` |
| App Group | `group.com.zzoutuo.WakeForge` |
| Minimum iOS | 26.0 (AlarmKit requirement) |
| Development Team | `JP4TN5PTS3` (project-level, all targets inherit) |
| Subscription IDs | `com.zzoutuo.WakeForge.pro.monthly`, `com.zzoutuo.WakeForge.pro.yearly` |
| Feedback backend | `https://msg.calcs.top/api/feedback` |
| Policy URLs | `https://asunnyboy861.github.io/WakeForge/{index,support,privacy,terms}.html` |
| Privacy manifest | Declares no tracking, no collected data, UserDefaults + file timestamp APIs |
| Signing state | Project-level team set; device profile needs one `-allowProvisioningUpdates` build |
| Simulator build | BUILD SUCCEEDED (iPhone 16, iPad Pro 13-inch M5) |

## 五、Known limitations

- AlarmKit alerts do not ring on the simulator; task flows were verified with the Debug "simulate a wake" entry.
- Rep counting needs a physical front camera. On the simulator the rep screen shows an explicit fallback.
- Cloud photo verification requires either a Pro subscription (JWS channel), a configured BYO key, or the local dev-key file.
