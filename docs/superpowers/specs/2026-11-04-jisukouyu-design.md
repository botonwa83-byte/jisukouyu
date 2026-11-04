# 极速口语（SpeedTalk）设计文档

- 日期：2026-11-04
- 平台：iOS 17+，iPhone / iPad
- 技术栈：Swift 6 + SwiftUI + SwiftData，零第三方依赖

---

## 1. 产品定位

面向**国内有一定英语基础（能读不能开口）的成人**，用「每天 5 句、3 分钟」的极轻负担，把最高频、最地道的美式口语练成肌肉记忆，最终具备快速适应美国生活与工作的开口能力。

一句话：**不教语法，只练能立刻用出去的地道句子。**

设计原则：

1. **打开即学**：无菜单层级，冷启动直接进入今日卡片
2. **单次极轻**：5 句一组，3~5 分钟必须完成一轮
3. **离线可用**：除 AI 功能外全链路离线；无 Key、无网也能完整学习与打卡
4. **地道优先**：每条句子必须携带至少一个地道点（缩略、短语动词、弱读连读、场合化俚语）
5. **内容可无限扩容**：内容为纯 JSON 数据，扩容不改代码

---

## 2. 内容体系：三个并列方案，各 1800 句

### 2.1 总容量

**5400 句 = 3 个并列方案 × 3 个阶段 × 600 句**

| 层级 | 名称 | 句量 | 学习天（默认 5 句/天） |
|---|---|---|---|
| 方案 Plan | 01 / 02 / 03 | 1800 | 360 天 |
| 阶段 Stage | a / b / c | 600 | 120 天 |
| 单元 Unit | 1–4 | 150 | 30 天 |
| 日 Day | 1–120（阶段内） | 5 | — |

### 2.2 三个并列方案

三个方案是**并列关系、互不依赖**，用户首次打开 App 时选一个开练；学完可再选另一个，三个都学完累计 5400 句。

| 方案 | 名称 | 适合谁 | a 阶段 | b 阶段 | c 阶段 |
|---|---|---|---|---|---|
| **01** | 生活生存 | 准备出国生活、旅游 | 吃住行基础 | 办事与医疗 | 邻里与消费 |
| **02** | 职场校园 | 要工作、要上课 | 求职与面试 | 职场协作 | 校园学术 |
| **03** | 地道社交 | 想说得像本地人 | 高频俚语 | 社交场合 | 文化与幽默 |

- 每方案 1800 句，三方案合计 5400 句，覆盖 8 大功能分区全场景
- **a → b → c 阶段递进**：难度（level 1→3）、句长、语速、地道度逐级提升
- 每阶段 600 句分 4 个单元（各 150 句 / 30 天），每单元第 7、14、21、28 天为综合复用日（5 句全部取自前 6 天）

### 2.3 选择与推进规则

- **首次启动必选方案**：Onboarding 第三步选择 01 / 02 / 03，系统给出「每天 3 分钟，120 天拿下 600 句」的预期说明
- **随时可切换**：课表页可切换主学方案，**各方案进度独立保存**（切回继续原进度，不清零）
- **可并行**：允许同时学多个方案（今日页顶部可切换当前方案），不做任何强制解锁
- **学习天 `currentDay`**：阶段内 1–120，当日 5 句（加速档 10 句）全部完成才 +1，不完成不推进，保证 600 句阶段完整性
- **阶段推进**：`currentDay` 超过 120 → a→b→c；c 完成 → 该方案通关，展示通关证书页
- **时间预期**：
  - 默认 5 句/天 → 每阶段 120 天，每方案 360 天；学完三方案 1080 天
  - 加速 10 句/天（设置可切）→ 每阶段 60 天，每方案 180 天；三方案 540 天

### 2.4 八分区（Scene Taxonomy）

`life` 生活 · `transit` 出行 · `dining` 餐饮 · `work` 职场 · `campus` 校园 · `social` 社交 · `emergency` 应急 · `slang` 地道表达

分类是**横切维度**：每个阶段都覆盖多个分类，只是权重不同（01 偏 dining/transit/life，02 偏 work/campus，03 偏 social/slang/emergency）。场景 Tab 跨全部方案聚合浏览。

### 2.5 地道性硬约束

每条句子必须满足：

1. 含至少 1 个地道点：`gonna/wanna/gotta/lemme` 类缩略、短语动词（`run into` / `figure out`）、弱读连读、或场合标注的俚语
2. 提供 `focus`（这条学什么，一句话）
3. 提供 `pronunciation`：IPA 音标 + 至少 1 条连读/弱读提示
4. 提供 `variants`：至少 1 条同义更地道说法
5. 俚语与非常规表达必须标 `register`（`casual` / `neutral` / `formal` / `avoid`），避免用户在正式场合误用

### 2.6 用词精妙标准（内容质量红线）

教材腔是这类产品最大的死因。每条语料按以下 7 条校准，任一条不达标即退回重写：

1. **真人语气优先**：以母语者日常真实说法为准，禁用教材句
   - ✗ `How do you do?` / `I am fine, thank you. And you?`
   - ✓ `How's it going?` / `I'm good — you?`
2. **一句一个可执行意图**：说完就能办事，不做信息堆砌
   - ✓ `Can I get this to go?`（明确诉求，一句解决）
3. **带情绪与分寸**：优先选用有态度、有软硬的表达，让用户学会"怎么说"而不只是"说什么"
   - `Honestly, I'm not sold on it.` / `I'd love to, but I'm slammed this week.`
4. **短语动词优先于大词**：`grab` `swing by` `run by` `pick up` `sort out` 优于 `purchase` `visit` `arrange`
5. **必带中式英语反例**：`avoid` 字段写清国人最容易说错的那版
   - 目标句 `I'm a big fan of ...`；避免 `I very like ...`
6. **长度分级**：a 阶段 ≤ 10 词，b 阶段 ≤ 14 词，c 阶段 ≤ 18 词（保证单卡 3 秒读完）
7. **可迁移性**：句子结构要能换词复用，`Can I get ___ to go?` 这类句式优先

补充字段 `avoid`（错误说法）与 `transfer`（可替换句式模板）纳入 Schema。

---

## 3. 功能模块（5 Tab）

### 3.1 今日 Today
- 卡片流主战场：大字英文 → 示范朗读（慢速/常速）→ 按住录音 → 实时转写 → 即时评分 → 逐词高亮 → 滑下一条
- 5 句完成 → 打卡动画 + 今日得分 + streak 更新
- 顶部：方案切换器（01/02/03）+「a 阶段 · Day 12 · 3/5」
- 卡片背面（上滑或点「详解」）：中文释义、使用场景、地道点、发音要点、变体
- 底部「+2 到期复习」入口（可选加练，不计入当天 5 句）

### 3.2 课表 Course
- 顶层三张方案卡：01 / 02 / 03，各自显示进度（如「a 阶段 Day 12 · 已掌握 87 句」）与「继续 / 开始 / 切换」按钮
- 方案详情：三阶段 a/b/c 进度条 → 进入某阶段后按单元 → 天的纵向列表
- 每行显示 5 句缩略 + 完成状态；已完成 / 当前可学 / 未开始三态（无锁态）
- 支持回看已完成阶段/天的任意一天重练

### 3.3 场景 Scenes
- 8 分类宫格 → 分类下句子列表（跨方案聚合）
- 支持搜索（英文/中文关键词）、收藏筛选
- 单句进入精练模式，当「口语速查词典」使用

### 3.4 对练 Talk
- 场景角色扮演：咖啡点单、机场值机、餐厅投诉、同事闲聊、面试、问路、看病
- 用户语音回答 → 转写 → AI 扮演对方角色回话，并在侧栏给出「刚才那句更地道的说法」
- 每场最多 10 轮，结束生成小结（用到的表达、可改进点）
- 需 API Key；无 Key 时显示引导卡而非灰块

### 3.5 我的 Progress
- 连续打卡 streak、累计学习天、已掌握句数（masteryLevel ≥ 4，跨方案合计）
- 三方案进度环 + 当前阶段进度
- 成就徽章墙（本地判定）：首次打卡、连续 7/30/100 天、累计满 100/500/1800/3600/5400 句、阶段通关、方案通关、满分跟读、首次 AI 对练…
- 复习队列入口
- 设置入口

### 3.6 设置 Settings
- AI：Base URL、Model、API Key（Keychain）、连接测试、每日配额、用量显示
- 学习：每日目标（5 句 / 10 句加速）、示范语速、自动播放
- 声音：美音音色选择
- 通知：本地每日提醒时间（默认 20:00）
- 关于 / 隐私说明

### 3.7 首次启动 Onboarding
3 步：欢迎 → 选择方案 01/02/03（单选，可后续切换）→ 设 AI（可跳过）。完成后落到今日。

---

## 4. 学习与打卡逻辑

三组独立状态（**按方案分别保存**）：

- **学习天 `currentDay`**（阶段内 1–120）：当日 5 句（加速档 10 句）全部完成才 +1
- **阶段 `currentStage`**：`currentDay` 超过 120 → a→b→c；c 完成后该方案通关
- **连续打卡 `streak`**（自然日，全局共用）：当天有任何学习行为即打卡，换方案不清零

规则：

- **超前学习**：完成当天任务后若时间充裕可「再学一组」，直接推进 `currentDay`，一日最多推进 2 天
- **断签**：自然日无任何学习行为则 streak 清零，但各方案 `currentDay` `currentStage` 不变（不惩罚课程进度）
- **切换方案**：今日页顶部或课表页切换，切换后立即加载该方案当前进度，互不影响
- **复习队列**：SM-2 简化算法，答对升级间隔（1/3/7/16/35 天），答错重置；每日最多插入 5 条，跨方案统一排队

---

## 5. 数据模型（SwiftData）

语料只读、打包在 Bundle；数据库只存用户侧数据，升级语料不破坏进度。

```swift
@Model final class UserProfile {
    var activePlan: String         // "01" | "02" | "03"，今日页当前方案
    var streak: Int
    var longestStreak: Int
    var lastStudyDate: Date?
    var startDate: Date
    var dailyGoal: Int             // 5 或 10
    var speechRate: Double
    var voiceIdentifier: String?
    var aiBaseURL: String
    var aiModel: String
    var aiQuotaPerDay: Int         // 默认 30
    var aiQuotaUsed: Int
    var aiQuotaDate: Date?
    var reminderHour: Int
    var targetScenes: [String]
}

/// 每个方案一条，三方案的进度完全独立
@Model final class PlanProgress {
    var planID: String             // "01" | "02" | "03"
    var currentStage: String       // "a" | "b" | "c"
    var currentDay: Int            // 1...120（阶段内）
    var completedDays: Int         // 当前阶段已完成天数
    var startedAt: Date?
    var finishedAt: Date?
    var isCompleted: Bool          // 该方案 1800 句全部完成
}

@Model final class PhraseProgress {
    var phraseID: String           // 唯一键，如 "01-a-012-3"
    var masteryLevel: Int          // 0...5
    var bestScore: Int
    var attemptCount: Int
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var isFavorite: Bool
    var lastTranscript: String?
}

@Model final class DailyLog {
    var dateKey: String            // "2026-11-04"
    var plan: String
    var stage: String
    var day: Int
    var completedCount: Int
    var totalScore: Int
    var isCheckedIn: Bool
}

@Model final class AttemptRecord {
    var phraseID: String
    var createdAt: Date
    var transcript: String
    var localScore: Int
    var aiScore: Int?
    var wordsPerSecond: Double?
    var duration: Double
}

@Model final class ConversationSession {
    var sceneID: String
    var startedAt: Date
    var turnCount: Int
    var messagesJSON: Data
    var summary: String?
}

@Model final class AchievementRecord {
    var achievementID: String
    var unlockedAt: Date
}
```

---

## 6. 语料 Schema（Bundle JSON）

`phrases.json`：全量 5400 条，每条带方案 / 阶段 / 单元 / 天。

```json
{
  "version": 1,
  "phrases": [
    {
      "id": "01-a-012-1",
      "plan": "01",
      "stage": "a",
      "unit": 1,
      "day": 12,
      "index": 1,
      "en": "I'm gonna grab a coffee. Want anything?",
      "zh": "我去买杯咖啡，你要带点什么吗？",
      "scene": "dining",
      "level": 1,
      "focus": "gonna = going to，口语中几乎必缩",
      "register": "casual",
      "tags": ["缩略", "同事闲聊"],
      "pronunciation": {
        "ipa": "/aɪm ˈɡʌnə ɡræb ə ˈkɔːfi/",
        "notes": [
          "gonna 读 /ˈɡʌnə/，不要读成 /ˈɡoʊɪŋ tuː/",
          "grab a 连读 /ˈɡræbə/"
        ]
      },
      "variants": ["I'm grabbing a coffee — want one?"],
      "avoid": "I am going to buy a cup of coffee. Do you want anything?",
      "transfer": "I'm gonna grab ___ — want anything?",
      "context": "办公室午后，随口问同事要不要带咖啡"
    }
  ]
}
```

`curriculum.json`：课纲映射，保证 5400 句的确定性编排。

```json
{
  "version": 1,
  "plans": [
    {
      "id": "01",
      "title": "生活生存",
      "subtitle": "先活下来，再活得顺",
      "stages": [
        {
          "id": "a",
          "title": "吃住行基础",
          "units": [
            {
              "index": 1,
              "title": "第一周：打招呼与点单",
              "days": [
                { "day": 1, "title": "开口第一句", "phraseIDs": ["01-a-001-1", "01-a-001-2", "01-a-001-3", "01-a-001-4", "01-a-001-5"] }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

### 6.1 内容生产批次（9 批 × 600 句）

| 批次 | 内容 | 说明 |
|---|---|---|
| P1 | 01-a 600 句 | 支撑全链路跑通的完整阶段 |
| P2 | 01-b 600 句 | 补 JSON，不改代码 |
| P3 | 01-c 600 句 | 01 方案完结（1800 句） |
| P4–P6 | 02-a / 02-b / 02-c | 02 方案 1800 句 |
| P7–P9 | 03-a / 03-b / 03-c | 03 方案 1800 句 |

UI 与数据结构从 P1 起就支持全部 5400 句与三方案并列（未开始的方案显示「开始学习」），扩容不改代码。

---

## 7. 本地评分引擎

目标：离线、零成本、100ms 内出分，让用户每天都能拿到即时反馈。

**流程**

1. 归一化：转小写、去标点、合并空白、数字转英文读法
2. 口语变体对齐表：`gonna↔going to`、`wanna↔want to`、`gotta↔got to`、`lemme↔let me`、`'em↔them`、`ain't↔is not` 等，双方任一形式互判为匹配
3. 词级对齐：动态规划求最小编辑序列（保留替换 / 插入 / 删除三类操作）
4. 三指标：
   - 完整度 = 匹配词数 / 标准词数
   - 准确度 = 1 − (替换 + 插入) / max(标准词数, 识别词数)
   - 流利度 = 语速落于 2.0–3.5 词/秒且停顿少得 1.0，偏离线性衰减
5. 总分 = 100 × (0.5 × 完整度 + 0.3 × 准确度 + 0.2 × 流利度)
6. 等级：≥85 A / 70–84 B / <70 C
7. 输出逐词状态：`matched` / `missing` / `extra` / `replaced(期望, 实际)`

**mastery 更新**：单次 ≥80 分则 masteryLevel +1（上限 5），<60 分 −1（下限 0）。

---

## 8. AI 层

### 8.1 抽象

```swift
protocol LLMProvider {
    func reviewPronunciation(target: String, transcript: String, ipa: String?) async throws -> PronunciationReview
    func chat(messages: [ChatMessage], scene: ConversationScene) -> AsyncThrowingStream<String, Error>
    func explain(phrase: Phrase) async throws -> PhraseExplanation
    func ping() async throws -> Bool
}
```

实现：`OpenAICompatibleProvider`（`URLSession` + `chat/completions`），Base URL / Model / Key 全部可配 → 同时支持 OpenAI、DeepSeek、通义、中转代理。

### 8.2 纠音

- 发送：标准句、用户转写文本、目标 IPA、当前分数
- **不发送录音音频**，只发文本
- 用 `response_format: json_object` 拿结构化结果：发音要点、具体音标偏差、连读/重音建议、更地道说法
- 触发方式：用户主动点「AI 精细点评」，非自动调用

### 8.3 对练

- 每场景一个 System Prompt（角色、语气、只回 1–3 句、结尾留话口）
- 流式返回，边收边显示
- 每轮附带一行「更地道说法」建议，独立字段不走流式

### 8.4 配额与降级

- 每日默认 30 次（纠音与对练各计 1 次），本地计数按自然日重置
- 无 Key → AI 入口显示引导卡（跳设置），不置灰
- 401 / 403 → 提示 Key 无效；429 → 提示限流；超时 15s → 提示重试
- 任一失败均回落本地评分，学习闭环不中断

---

## 9. 技术架构

```
SpeedTalk/
├── App/            SpeedTalkApp、AppRouter、AppContainer（依赖注入）
├── Core/
│   ├── Models/     SwiftData 实体
│   ├── Content/    ContentStore（JSON 加载/校验）、CurriculumService、DailySelector、ReviewScheduler
│   ├── Speech/     AudioSessionManager、SpeechRecognizer、SpeechPlayer（AVSpeechSynthesizer）
│   ├── Scoring/    TextNormalizer、WordAligner、LocalScorer、ScoreReport
│   ├── AI/         LLMProvider、OpenAICompatibleProvider、PromptBuilder、KeychainStore、AIUsageTracker
│   └── DesignSystem/ Theme、Typography、Card、ScoreGauge、Waveform
├── Features/
│   ├── Today/      TodayView、PhraseCardView、PracticeFlowView、ScoreResultView
│   ├── Course/     CourseView（三方案）、PlanDetailView、StageView、DayDetailView
│   ├── Scenes/     SceneGridView、PhraseListView、PhraseDetailView
│   ├── Talk/       ScenePickerView、ChatView、SessionSummaryView
│   ├── Progress/   ProgressView、AchievementWall、ReviewQueueView
│   ├── Settings/   SettingsView、AIConfigView
│   └── Onboarding/ OnboardingFlow
└── Resources/      phrases.json、curriculum.json、Assets.xcassets
```

**工程管理**：`project.yml`（XcodeGen）生成 `SpeedTalk.xcodeproj`。Bundle ID：`com.speedtalk.app`。

**状态管理**：轻量 MVVM + `@Observable`，不使用 TCA / Combine 重依赖。依赖通过 `AppContainer` 构造注入，便于测试。

**语音链路**

- 录音：`AVAudioEngine` 取 PCM buffer，写入 `AVAudioFile`（临时文件，评分后删除）
- 识别：`SFSpeechRecognizer(locale: en-US)`，优先 `requiresOnDeviceRecognition = true`，不可用时回落在线
- 示范：`AVSpeechSynthesizer` + `en-US` 高质量音色，慢速/常速两档（rate 0.42 / 0.52）
- 会话：统一 `AudioSessionManager` 管理 `record` / `playback` 切换，避免打断

---

## 10. iPad 适配

- 根视图 `NavigationSplitView`：侧栏 5 Tab，详情区内容
- iPhone 用 `TabView`
- 卡片流最大宽度 720pt 居中；常规宽度（≥ 900pt）下卡片与详解左右并排
- 横竖屏均支持；分栏 + 触控板指针悬停效果

---

## 11. 错误处理与降级

| 场景 | 处理 |
|---|---|
| 麦克风权限拒绝 | 评分按钮置灰 + 「去设置开启」按钮 + 一键跳 `UIApplication.openSettingsURLString` |
| 语音识别权限拒绝 | 同上，另提供「键盘输入跟读」备选路径 |
| 识别不可用（区域/网络） | 提示 + 自动切「输入模式」，本地评分仍可用 |
| 录音无声 / 音量过低 | 检测 RMS，提示「没听到声音，再试一次」 |
| AI 未配置 | 引导卡，不阻断本地学习 |
| AI 请求失败 | Toast + 重试 + 回落本地评分 |
| 语料加载失败 | 启动自检，页面级错误态 + 重试 |
| 音频会话冲突 | `AudioSessionManager` 统一 intercept 处理 |

---

## 12. 测试策略

**单元测试（Swift Testing）**

- `TextNormalizer`：标点、大小写、数字
- `WordAligner`：漏词、多词、替换、口语变体互认（gonna/going to）
- `LocalScorer`：满分、部分、全错、语速异常
- `CurriculumService`：3 方案 × 3 阶段 × 120 天 × 5 句、ID 唯一、scene 合法、引用完整、逐日无缺
- `ReviewScheduler`：间隔升级、答错重置、每日上限
- `DailySelector`：同日幂等、阶段推进（a→b→c）、方案各自独立推进、切换方案不丢进度、断签不影响进度
- `KeychainStore`：写入 / 读取 / 删除
- `PromptBuilder`：纠音与对练 Prompt 字段完备

**集成/冒烟（模拟器）**

今日 → 播放示范 → 录音 → 识别 → 评分 → 打卡 → 切换方案验证进度独立；无 Key 时 AI 降级路径。

---

## 13. 里程碑

| 里程碑 | 范围 | 验收 |
|---|---|---|
| M1 骨架与内容 | XcodeGen 工程、设计系统、01-a 600 句语料、今日卡片流、示范朗读 | 模拟器可滑卡、可听发音 |
| M2 跟读与打卡 | 录音、实时转写、本地评分、逐词高亮、打卡与 streak | 全链路出分并打卡 |
| M3 课程与复习 | 三方案并列课表、阶段推进、场景库、复习队列、成就、设置 | 5400 句体系可逐级推进，切换方案进度独立 |
| M4 AI 能力 | 纠音、对练、Keychain、配额、降级 | AI 闭环可用，断网不崩 |
| M5 打磨上架 | iPad 适配、单元测试补齐、权限文案、启动图与图标 | 真机 / 双端模拟器通过 |
| M6 内容扩容 | P2–P9 剩余 4800 句按批补入 | 不改代码，仅换 JSON |

---

## 14. 明确不做（YAGNI）

- 无后端、无账号体系、无云同步
- 无社交、无好友、无排行榜、无打卡分享
- 无内购、无订阅、无付费墙
- 无服务端推送（仅本地通知提醒）
- 不做音标入门课（目标用户已有基础）

---

## 15. 隐私与合规

- 麦克风与语音识别权限文案明确说明「仅用于跟读评分，录音不出设备」
- 音频文件仅临时存储，评分完成即删除；仅保留转写文本（可选，用户可关闭历史保存）
- 发送给 AI 的只有文本，绝不含音频
- API Key 仅存 Keychain，不写入日志
- App 内提供隐私说明页面

---

## 16. 界面文案风格指南

文案本身也是产品力。全 App 文案遵循同一套语气：

| 原则 | 说明 | 示例 |
|---|---|---|
| 短 | 一行说完，不超过 20 字 | ✗「欢迎使用极速口语学习系统」 ✓「今天 5 句，3 分钟」 |
| 动词开头 | 直接给动作 | ✓「按住说」「换下一句」「听听标准音」 |
| 不喊口号 | 不用感叹号堆情绪 | ✗「太棒了！！！」 ✓「这遍到位了」 |
| 给下一步 | 错误提示必须带出口 | ✗「识别失败」 ✓「没听清，靠近一点再来一次」 |
| 反馈有分寸 | 分数评价具体到点，不空夸 | ✗「非常优秀」 ✓「连读稳了，`want anything` 再收一点」 |
| 中英混排规范 | 英文词加空格，音标用斜杠 | ✓「`gonna` 读 /ˈɡʌnə/」 |

页面标题命名：**今日 · 课表 · 场景 · 对练 · 我的**（四个字以内，不用"中心""模块""系统"）。
