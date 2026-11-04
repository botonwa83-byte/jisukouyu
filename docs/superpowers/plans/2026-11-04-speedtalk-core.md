# 极速口语 SpeedTalk 核心学习闭环实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 交付一个可编译运行的 iOS App，实现「选方案 → 每天 5 句卡片流 → 跟读 → 本地评分 → 打卡」的完整学习闭环，并把纯逻辑抽成可 `swift test` 的 Swift Package。

**Architecture:** 双目标结构。`Core/` 是零依赖 Swift Package（Swift 5 语言模式，支持 macOS 14 + iOS 17），承载内容模型、语料加载、选题算法、复习调度、评分引擎等纯逻辑，可直接在 Mac 上用 `swift test` 做 TDD。`SpeedTalk/` 是 SwiftUI App，负责 SwiftData 持久化、语音链路（AVFoundation / Speech）、界面；通过 `SpeedTalkCore` 复用逻辑。App 层按 Feature 分目录，MVVM + `@Observable`，依赖由 `AppContainer` 构造注入。

**Tech Stack:** Swift 5 语言模式 / SwiftUI / SwiftData / AVFoundation / Speech.framework / Swift Testing / XcodeGen。零第三方依赖。

**Spec:** `docs/superpowers/specs/2026-11-04-jisukouyu-design.md`

## Global Constraints

- 部署目标 iOS 17.0，`TARGETED_DEVICE_FAMILY = "1,2"`（iPhone + iPad），Bundle ID `com.speedtalk.app`，显示名「极速口语」
- 零第三方依赖：网络用 `URLSession`，不使用 Alamofire / TCA / RxSwift
- 内容口径：3 方案（01 生活生存 / 02 职场校园 / 03 地道社交）× 3 阶段（a/b/c）× 600 句 = 5400 句；每阶段 120 天，每天 5 句
- 语料 ID 格式固定为 `"{plan}-{stage}-{day:3位}-{index}"`，例如 `01-a-012-1`
- 句子长度红线：a 阶段 ≤ 10 词，b 阶段 ≤ 14 词，c 阶段 ≤ 18 词
- 每条语料必须含：`focus`、`pronunciation.ipa`、`pronunciation.notes`（≥1）、`variants`（≥1）、`avoid`、`register`
- 无后端、无账号、无社交、无内购；除 AI 功能外全离线
- 录音不上传、不长期保存；仅文本可发送给 AI
- 界面文案遵守 Spec 第 16 节：短句、动词开头、不用感叹号、错误提示必带下一步动作
- 本机未安装 iOS 模拟器运行时：逻辑验证用 `swift test --package-path Core`，App 编译验证用 `xcodebuild ... build -destination 'generic/platform=iOS Simulator'`；如需真机/模拟器运行，先执行 `xcodebuild -downloadPlatform iOS`
- 每个 Task 结束后提交一次 git（仓库在 Task 1 初始化）；如暂不需要版本管理，可跳过 `git commit` 步骤

---

## 文件结构

```
Package + App 同仓结构：

Core/
├── Package.swift
├── Sources/SpeedTalkCore/
│   ├── Models/        Phrase.swift、Scene.swift、Curriculum.swift
│   ├── Content/       ContentLoader.swift、PhraseLibrary.swift、CurriculumService.swift
│   ├── Selection/     DailySelector.swift、ReviewScheduler.swift、ProgressEngine.swift、StreakCalculator.swift
│   ├── Scoring/       TextNormalizer.swift、WordAligner.swift、LocalScorer.swift、ScoreReport.swift
│   └── Resources/     phrases.json、curriculum.json
└── Tests/SpeedTalkCoreTests/
    ├── ScoringTests.swift
    ├── ContentTests.swift
    ├── SelectionTests.swift
    └── StreakTests.swift

SpeedTalk/
├── App/               SpeedTalkApp.swift、AppContainer.swift、RootView.swift
├── Core/
│   ├── Persistence/   UserProfile.swift、PlanProgress.swift、PhraseProgress.swift、DailyLog.swift、AchievementRecord.swift、ModelContainerFactory.swift
│   ├── Speech/        AudioSessionManager.swift、SpeechPlayer.swift、SpeechRecognizer.swift
│   ├── Notifications/ ReminderScheduler.swift
│   └── DesignSystem/  Theme.swift、Components.swift
├── Features/
│   ├── Onboarding/    OnboardingView.swift
│   ├── Today/         TodayView.swift、TodayViewModel.swift、PhraseCardView.swift、PhraseDetailView.swift
│   ├── Practice/      PracticeView.swift、PracticeViewModel.swift、ScoreResultView.swift、WordHighlightView.swift
│   ├── Course/        CourseView.swift、PlanDetailView.swift、StageListView.swift
│   ├── Scenes/        SceneGridView.swift、PhraseListView.swift、PhraseDetailScreen.swift
│   ├── Progress/      MeView.swift、AchievementWall.swift、ReviewQueueView.swift
│   └── Settings/      SettingsView.swift、NotificationSettingsView.swift
├── Resources/         Assets.xcassets
└── Info/              （由 XcodeGen 生成 Info.plist 键值，无需手写文件）

project.yml
```

---

### Task 1: 工程骨架跑通编译

**Files:**
- Create: `Core/Package.swift`
- Create: `Core/Sources/SpeedTalkCore/SpeedTalkCore.swift`
- Create: `Core/Tests/SpeedTalkCoreTests/SmokeTests.swift`
- Create: `project.yml`
- Create: `SpeedTalk/App/SpeedTalkApp.swift`
- Create: `.gitignore`

**Interfaces:**
- Consumes: 无
- Produces: 模块名 `SpeedTalkCore`；`SpeedTalkCore.version: String`；可编译的 `SpeedTalk` scheme

- [ ] **Step 1: 初始化 git 与目录**

```bash
cd /Users/robert/Documents/trae_projects/jisukouyu
git init
mkdir -p Core/Sources/SpeedTalkCore Core/Tests/SpeedTalkCoreTests Core/Sources/SpeedTalkCore/Resources
mkdir -p SpeedTalk/App SpeedTalk/Core/Persistence SpeedTalk/Core/Speech SpeedTalk/Core/Notifications SpeedTalk/Core/DesignSystem
mkdir -p SpeedTalk/Features/Onboarding SpeedTalk/Features/Today SpeedTalk/Features/Practice
mkdir -p SpeedTalk/Features/Course SpeedTalk/Features/Scenes SpeedTalk/Features/Progress SpeedTalk/Features/Settings
mkdir -p SpeedTalk/Resources
```

- [ ] **Step 2: 写 `.gitignore`**

```
.DS_Store
*.xcodeproj
xcuserdata/
.build/
DerivedData/
*.xcworkspace/xcuserdata/
```

- [ ] **Step 3: 写 `Core/Package.swift`**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeedTalkCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SpeedTalkCore", targets: ["SpeedTalkCore"])
    ],
    targets: [
        .target(
            name: "SpeedTalkCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SpeedTalkCoreTests",
            dependencies: ["SpeedTalkCore"]
        )
    ]
)
```

- [ ] **Step 4: 写最小源码与冒烟测试**

`Core/Sources/SpeedTalkCore/SpeedTalkCore.swift`：

```swift
public enum SpeedTalkCore {
    public static let version = "1.0.0"
}
```

`Core/Tests/SpeedTalkCoreTests/SmokeTests.swift`：

```swift
import Testing
@testable import SpeedTalkCore

@Test func coreVersionIsExposed() {
    #expect(SpeedTalkCore.version == "1.0.0")
}
```

- [ ] **Step 5: 跑测试验证包可用**

Run: `swift test --package-path Core`
Expected: 编译通过，`coreVersionIsExposed` 通过

- [ ] **Step 6: 写 `project.yml`**

```yaml
name: SpeedTalk
options:
  bundleIdPrefix: com.speedtalk
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true

packages:
  SpeedTalkCore:
    path: Core

settings:
  base:
    SWIFT_VERSION: "5.0"
    MARKETING_VERSION: "1.0"
    CURRENT_PROJECT_VERSION: "1"
    CODE_SIGN_STYLE: Automatic
    DEVELOPMENT_TEAM: ""

targets:
  SpeedTalk:
    type: application
    platform: iOS
    sources:
      - path: SpeedTalk
    dependencies:
      - package: SpeedTalkCore
        product: SpeedTalkCore
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.speedtalk.app
        TARGETED_DEVICE_FAMILY: "1,2"
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_CFBundleDisplayName: 极速口语
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_NSMicrophoneUsageDescription: 用于跟读录音与发音评分。录音只保存在本机，评分后立即删除，不会上传。
        INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: 用于把你的跟读转成文字，从而计算发音得分。
        INFOPLIST_KEY_ITSCapability: ""
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"

schemes:
  SpeedTalk:
    build:
      targets:
        SpeedTalk: all
    run:
      config: Debug
```

- [ ] **Step 7: 写最小 App 入口**

`SpeedTalk/App/SpeedTalkApp.swift`：

```swift
import SwiftUI
import SpeedTalkCore

@main
struct SpeedTalkApp: App {
    var body: some Scene {
        WindowGroup {
            Text("极速口语 \(SpeedTalkCore.version)")
        }
    }
}
```

- [ ] **Step 8: 生成工程并编译**

```bash
cd /Users/robert/Documents/trae_projects/jisukouyu
xcodegen generate
xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk \
  -destination 'generic/platform=iOS Simulator' build | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: 提交**

```bash
git add -A
git commit -m "chore: scaffold SpeedTalk core package and iOS app"
```

---

### Task 2: 评分引擎（TDD）

**Files:**
- Create: `Core/Sources/SpeedTalkCore/Scoring/TextNormalizer.swift`
- Create: `Core/Sources/SpeedTalkCore/Scoring/WordAligner.swift`
- Create: `Core/Sources/SpeedTalkCore/Scoring/ScoreReport.swift`
- Create: `Core/Sources/SpeedTalkCore/Scoring/LocalScorer.swift`
- Test: `Core/Tests/SpeedTalkCoreTests/ScoringTests.swift`

**Interfaces:**
- Consumes: 无
- Produces:
  - `TextNormalizer.tokens(_ text: String) -> [String]`
  - `WordAligner.align(expected: [String], actual: [String]) -> [WordAlignment]`
  - `enum WordAlignment: Equatable { case matched(String), missing(String), extra(String), replaced(expected: String, actual: String) }`
  - `ScoreReport`（字段 `score: Int`、`grade: Grade`、`completeness: Double`、`accuracy: Double`、`fluency: Double`、`alignments: [WordAlignment]`）
  - `LocalScorer.score(expected: String, actual: String, duration: Double) -> ScoreReport`

- [ ] **Step 1: 写失败测试**

`Core/Tests/SpeedTalkCoreTests/ScoringTests.swift`：

```swift
import Testing
import Foundation
@testable import SpeedTalkCore

@Test func normalizerStripsPunctuationAndLowercases() {
    #expect(TextNormalizer.tokens("Hello, WORLD! It's 5 o'clock.") == ["hello", "world", "it's", "5", "o'clock"])
}

@Test func normalizerExpandsSpokenContractionsOnBothSides() {
    #expect(TextNormalizer.tokens("I'm gonna grab a coffee") == ["i'm", "going", "to", "grab", "a", "coffee"])
    #expect(TextNormalizer.tokens("I'm going to grab a coffee") == ["i'm", "going", "to", "grab", "a", "coffee"])
}

@Test func alignerMarksMissingWord() {
    let ops = WordAligner.align(expected: ["want", "anything"], actual: ["want"])
    #expect(ops.contains(.missing("anything")))
}

@Test func alignerMarksExtraWord() {
    let ops = WordAligner.align(expected: ["want"], actual: ["want", "some"])
    #expect(ops.contains(.extra("some")))
}

@Test func alignerMarksReplacement() {
    let ops = WordAligner.align(expected: ["coffee"], actual: ["cocoa"])
    #expect(ops.contains(.replaced(expected: "coffee", actual: "cocoa")))
}

@Test func perfectReadingScoresHigh() {
    let report = LocalScorer.score(
        expected: "I'm gonna grab a coffee.",
        actual: "I am going to grab a coffee",
        duration: 2.2
    )
    #expect(report.score >= 85)
    #expect(report.grade == .a)
}

@Test func missingHalfTheSentenceScoresLow() {
    let report = LocalScorer.score(
        expected: "Can I get this to go please",
        actual: "can i get",
        duration: 1.5
    )
    #expect(report.score < 70)
    #expect(report.completeness < 0.7)
}

@Test func silentAudioScoresZeroFluency() {
    let report = LocalScorer.score(expected: "hello there", actual: "hello there", duration: 0)
    #expect(report.fluency == 0)
}

@Test func gradeThresholds() {
    #expect(Grade(score: 85) == .a)
    #expect(Grade(score: 84) == .b)
    #expect(Grade(score: 69) == .c)
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Core 2>&1 | tail -20`
Expected: 编译失败，提示 `TextNormalizer` / `WordAligner` / `LocalScorer` 未定义

- [ ] **Step 3: 实现 `TextNormalizer`**

`Core/Sources/SpeedTalkCore/Scoring/TextNormalizer.swift`：

```swift
import Foundation

public enum TextNormalizer {
    /// 口语缩略展开表：两侧都展开后再比对，避免 "gonna" 与 "going to" 互判为错
    private static let expansions: [(String, String)] = [
        ("gonna", "going to"),
        ("wanna", "want to"),
        ("gotta", "got to"),
        ("lemme", "let me"),
        ("gimme", "give me"),
        ("kinda", "kind of"),
        ("sorta", "sort of"),
        ("dunno", "do not know"),
        ("'em", "them"),
        ("y'all", "you all")
    ]

    public static func tokens(_ text: String) -> [String] {
        let cleaned = text
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .map { character -> Character in
                if character.isLetter || character.isNumber || character == "'" { return character }
                return " "
            }

        var words = String(cleaned)
            .split(separator: " ")
            .map(String.init)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "'")) }
            .filter { !$0.isEmpty }

        for (spoken, full) in expansions {
            words = expand(words, spoken: spoken, full: full)
        }
        return words
    }

    private static func expand(_ words: [String], spoken: String, full: String) -> [String] {
        let fullWords = full.split(separator: " ").map(String.init)
        return words.flatMap { word -> [String] in
            word == spoken ? fullWords : [word]
        }
    }
}
```

- [ ] **Step 4: 实现 `WordAligner`**

`Core/Sources/SpeedTalkCore/Scoring/WordAligner.swift`：

```swift
import Foundation

public enum WordAlignment: Equatable, Sendable {
    case matched(String)
    case missing(String)
    case extra(String)
    case replaced(expected: String, actual: String)
}

public enum WordAligner {
    public static func align(expected: [String], actual: [String]) -> [WordAlignment] {
        let n = expected.count
        let m = actual.count
        guard n > 0 || m > 0 else { return [] }

        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { dp[i][0] = i }
        for j in 0...m { dp[0][j] = j }

        if n > 0 && m > 0 {
            for i in 1...n {
                for j in 1...m {
                    if expected[i - 1] == actual[j - 1] {
                        dp[i][j] = dp[i - 1][j - 1]
                    } else {
                        dp[i][j] = 1 + min(dp[i - 1][j - 1], dp[i - 1][j], dp[i][j - 1])
                    }
                }
            }
        }

        var result: [WordAlignment] = []
        var i = n
        var j = m
        while i > 0 || j > 0 {
            if i > 0, j > 0, expected[i - 1] == actual[j - 1], dp[i][j] == dp[i - 1][j - 1] {
                result.append(.matched(expected[i - 1]))
                i -= 1
                j -= 1
            } else if i > 0, j > 0, dp[i][j] == dp[i - 1][j - 1] + 1 {
                result.append(.replaced(expected: expected[i - 1], actual: actual[j - 1]))
                i -= 1
                j -= 1
            } else if i > 0, dp[i][j] == dp[i - 1][j] + 1 {
                result.append(.missing(expected[i - 1]))
                i -= 1
            } else {
                result.append(.extra(actual[j - 1]))
                j -= 1
            }
        }
        return result.reversed()
    }
}
```

- [ ] **Step 5: 实现 `ScoreReport` 与 `Grade`**

`Core/Sources/SpeedTalkCore/Scoring/ScoreReport.swift`：

```swift
import Foundation

public enum Grade: String, Sendable, Equatable {
    case a = "A"
    case b = "B"
    case c = "C"

    public init(score: Int) {
        switch score {
        case 85...: self = .a
        case 70..<85: self = .b
        default: self = .c
        }
    }

    public var title: String {
        switch self {
        case .a: return "这遍到位了"
        case .b: return "还差一点"
        case .c: return "再来一遍"
        }
    }
}

public struct ScoreReport: Sendable, Equatable {
    public let score: Int
    public let grade: Grade
    public let completeness: Double
    public let accuracy: Double
    public let fluency: Double
    public let wordsPerSecond: Double
    public let alignments: [WordAlignment]

    public init(
        score: Int,
        completeness: Double,
        accuracy: Double,
        fluency: Double,
        wordsPerSecond: Double,
        alignments: [WordAlignment]
    ) {
        self.score = score
        self.grade = Grade(score: score)
        self.completeness = completeness
        self.accuracy = accuracy
        self.fluency = fluency
        self.wordsPerSecond = wordsPerSecond
        self.alignments = alignments
    }
}
```

- [ ] **Step 6: 实现 `LocalScorer`**

`Core/Sources/SpeedTalkCore/Scoring/LocalScorer.swift`：

```swift
import Foundation

public enum LocalScorer {
    public static func score(expected: String, actual: String, duration: Double) -> ScoreReport {
        let expectedTokens = TextNormalizer.tokens(expected)
        let actualTokens = TextNormalizer.tokens(actual)
        let alignments = WordAligner.align(expected: expectedTokens, actual: actualTokens)

        var matched = 0
        var missing = 0
        var extra = 0
        var replaced = 0
        for alignment in alignments {
            switch alignment {
            case .matched: matched += 1
            case .missing: missing += 1
            case .extra: extra += 1
            case .replaced: replaced += 1
            }
        }

        let expectedCount = max(expectedTokens.count, 1)
        let actualCount = max(actualTokens.count, 1)
        let completeness = Double(matched) / Double(expectedCount)
        let accuracy = max(0, 1 - Double(replaced + extra + missing) / Double(max(expectedCount, actualCount)))
        let wps = duration > 0 ? Double(expectedTokens.count) / duration : 0
        let fluency = fluencyScore(wordsPerSecond: wps, duration: duration)

        let total = 100 * (0.5 * completeness + 0.3 * accuracy + 0.2 * fluency)
        return ScoreReport(
            score: max(0, min(100, Int(total.rounded()))),
            completeness: completeness,
            accuracy: accuracy,
            fluency: fluency,
            wordsPerSecond: wps,
            alignments: alignments
        )
    }

    static func fluencyScore(wordsPerSecond wps: Double, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        if wps < 2.0 { return max(0.2, 1 - (2.0 - wps) * 0.6) }
        if wps > 3.5 { return max(0.3, 1 - (wps - 3.5) * 0.4) }
        return 1.0
    }
}
```

- [ ] **Step 7: 跑测试直到全绿**

Run: `swift test --package-path Core 2>&1 | tail -20`
Expected: 全部测试通过。若 `perfectReadingScoresHigh` 因 "I'm" 与 "I am" 差异失败，在 `TextNormalizer.expansions` 增加 `("i'm", "i am")` 后重跑

- [ ] **Step 8: 提交**

```bash
git add -A
git commit -m "feat(core): add text normalizer, word aligner and local scorer"
```

---

### Task 3: 内容模型与课纲校验

**Files:**
- Create: `Core/Sources/SpeedTalkCore/Models/Scene.swift`
- Create: `Core/Sources/SpeedTalkCore/Models/Phrase.swift`
- Create: `Core/Sources/SpeedTalkCore/Models/Curriculum.swift`
- Create: `Core/Sources/SpeedTalkCore/Content/PhraseLibrary.swift`
- Create: `Core/Sources/SpeedTalkCore/Content/ContentLoader.swift`
- Create: `Core/Sources/SpeedTalkCore/Content/CurriculumService.swift`
- Create: `Core/Sources/SpeedTalkCore/Resources/phrases.json`
- Create: `Core/Sources/SpeedTalkCore/Resources/curriculum.json`
- Test: `Core/Tests/SpeedTalkCoreTests/ContentTests.swift`

**Interfaces:**
- Consumes: 无
- Produces:
  - `enum Scene: String, Codable, CaseIterable`（`life/transit/dining/work/campus/social/emergency/slang`，`title: String`）
  - `struct Phrase: Codable, Identifiable, Hashable, Sendable`
  - `struct Curriculum: Codable, Sendable`（`plans: [Plan]`，`Plan.stages[].units[].days[]`）
  - `struct PhraseLibrary`（`init(phrases:)`、`phrase(id:)`、`all`、`phrases(plan:stage:)`、`search(_:)`）
  - `enum ContentLoader { loadBundled() throws -> (PhraseLibrary, Curriculum) }`
  - `struct CurriculumService`（`validate() -> [String]`、`day(plan:stage:day:) -> [Phrase]`、`dayCount(plan:stage:) -> Int`）

- [ ] **Step 1: 写失败测试**

`Core/Tests/SpeedTalkCoreTests/ContentTests.swift`：

```swift
import Testing
import Foundation
@testable import SpeedTalkCore

@Test func bundledContentLoads() throws {
    let bundle = try ContentLoader.loadBundled()
    #expect(bundle.library.all.isEmpty == false)
    #expect(bundle.curriculum.plans.isEmpty == false)
}

@Test func bundledCurriculumHasNoValidationIssues() throws {
    let bundle = try ContentLoader.loadBundled()
    let issues = CurriculumService(curriculum: bundle.curriculum, library: bundle.library).validate()
    #expect(issues.isEmpty, "课纲校验问题：\(issues.joined(separator: "; "))")
}

@Test func phraseCanBeDecodedFromJSON() throws {
    let json = """
    {"id":"01-a-001-1","plan":"01","stage":"a","unit":1,"day":1,"index":1,
     "en":"I'm gonna grab a coffee.","zh":"我去买杯咖啡。","scene":"dining","level":1,
     "focus":"gonna = going to","register":"casual","tags":["缩略"],
     "pronunciation":{"ipa":"/aɪm ˈɡʌnə ɡræb ə ˈkɔːfi/","notes":["gonna 读 /ˈɡʌnə/"]},
     "variants":["I'm grabbing a coffee."],"avoid":"I am going to buy a cup of coffee.",
     "transfer":"I'm gonna grab ___.","context":"办公室随口问同事"}
    """.data(using: .utf8)!
    let phrase = try JSONDecoder().decode(Phrase.self, from: json)
    #expect(phrase.id == "01-a-001-1")
    #expect(phrase.scene == .dining)
    #expect(phrase.register == .casual)
}

@Test func librarySearchMatchesChineseAndEnglish() throws {
    let bundle = try ContentLoader.loadBundled()
    #expect(bundle.library.search("coffee").isEmpty == false)
    #expect(bundle.library.search("咖啡").isEmpty == false)
}

@Test func validationCatchesDanglingPhraseReference() {
    let phrase = Phrase.fixture(id: "01-a-001-1")
    let library = PhraseLibrary(phrases: [phrase])
    let curriculum = Curriculum(
        version: 1,
        plans: [
            .init(id: "01", title: "生活生存", subtitle: "", stages: [
                .init(id: "a", title: "吃住行基础", units: [
                    .init(index: 1, title: "第一周", days: [
                        .init(day: 1, title: "开口第一句", phraseIDs: ["01-a-001-1", "01-a-001-9"])
                    ])
                ])
            ])
        ]
    )
    let issues = CurriculumService(curriculum: curriculum, library: library).validate()
    #expect(issues.contains { $0.contains("01-a-001-9") })
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Core 2>&1 | tail -20`
Expected: 编译失败，`ContentLoader` 等未定义

- [ ] **Step 3: 写模型**

`Core/Sources/SpeedTalkCore/Models/Scene.swift`：

```swift
import Foundation

public enum Scene: String, Codable, CaseIterable, Sendable {
    case life, transit, dining, work, campus, social, emergency, slang

    public var title: String {
        switch self {
        case .life: return "生活"
        case .transit: return "出行"
        case .dining: return "餐饮"
        case .work: return "职场"
        case .campus: return "校园"
        case .social: return "社交"
        case .emergency: return "应急"
        case .slang: return "地道表达"
        }
    }

    public var symbol: String {
        switch self {
        case .life: return "house"
        case .transit: return "airplane"
        case .dining: return "fork.knife"
        case .work: return "briefcase"
        case .campus: return "graduationcap"
        case .social: return "person.2"
        case .emergency: return "exclamationmark.triangle"
        case .slang: return "text.bubble"
        }
    }
}

public enum Register: String, Codable, Sendable {
    case casual, neutral, formal, avoid

    public var title: String {
        switch self {
        case .casual: return "随口说"
        case .neutral: return "通用"
        case .formal: return "正式"
        case .avoid: return "少用"
        }
    }
}
```

`Core/Sources/SpeedTalkCore/Models/Phrase.swift`：

```swift
import Foundation

public struct Phrase: Codable, Identifiable, Hashable, Sendable {
    public struct Pronunciation: Codable, Hashable, Sendable {
        public let ipa: String
        public let notes: [String]

        public init(ipa: String, notes: [String]) {
            self.ipa = ipa
            self.notes = notes
        }
    }

    public let id: String
    public let plan: String
    public let stage: String
    public let unit: Int
    public let day: Int
    public let index: Int
    public let en: String
    public let zh: String
    public let scene: Scene
    public let level: Int
    public let focus: String
    public let register: Register
    public let tags: [String]
    public let pronunciation: Pronunciation
    public let variants: [String]
    public let avoid: String?
    public let transfer: String?
    public let context: String

    public init(
        id: String, plan: String, stage: String, unit: Int, day: Int, index: Int,
        en: String, zh: String, scene: Scene, level: Int, focus: String,
        register: Register, tags: [String], pronunciation: Pronunciation,
        variants: [String], avoid: String?, transfer: String?, context: String
    ) {
        self.id = id
        self.plan = plan
        self.stage = stage
        self.unit = unit
        self.day = day
        self.index = index
        self.en = en
        self.zh = zh
        self.scene = scene
        self.level = level
        self.focus = focus
        self.register = register
        self.tags = tags
        self.pronunciation = pronunciation
        self.variants = variants
        self.avoid = avoid
        self.transfer = transfer
        self.context = context
    }
}

extension Phrase {
    public static func fixture(id: String = "01-a-001-1") -> Phrase {
        Phrase(
            id: id, plan: "01", stage: "a", unit: 1, day: 1, index: 1,
            en: "I'm gonna grab a coffee.", zh: "我去买杯咖啡。",
            scene: .dining, level: 1, focus: "gonna = going to",
            register: .casual, tags: ["缩略"],
            pronunciation: .init(ipa: "/aɪm ˈɡʌnə ɡræb ə ˈkɔːfi/", notes: ["gonna 读 /ˈɡʌnə/"]),
            variants: ["I'm grabbing a coffee."],
            avoid: "I am going to buy a cup of coffee.",
            transfer: "I'm gonna grab ___.",
            context: "办公室随口问同事"
        )
    }
}
```

`Core/Sources/SpeedTalkCore/Models/Curriculum.swift`：

```swift
import Foundation

public struct Curriculum: Codable, Sendable {
    public struct Plan: Codable, Sendable, Identifiable {
        public struct Stage: Codable, Sendable, Identifiable {
            public struct Unit: Codable, Sendable {
                public struct Day: Codable, Sendable, Identifiable {
                    public let day: Int
                    public let title: String
                    public let phraseIDs: [String]
                    public var id: Int { day }

                    public init(day: Int, title: String, phraseIDs: [String]) {
                        self.day = day
                        self.title = title
                        self.phraseIDs = phraseIDs
                    }
                }

                public let index: Int
                public let title: String
                public let days: [Day]

                public init(index: Int, title: String, days: [Day]) {
                    self.index = index
                    self.title = title
                    self.days = days
                }
            }

            public let id: String
            public let title: String
            public let units: [Unit]

            public init(id: String, title: String, units: [Unit]) {
                self.id = id
                self.title = title
                self.units = units
            }

            public var days: [Unit.Day] { units.flatMap(\.days) }
        }

        public let id: String
        public let title: String
        public let subtitle: String
        public let stages: [Stage]

        public init(id: String, title: String, subtitle: String, stages: [Stage]) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.stages = stages
        }
    }

    public let version: Int
    public let plans: [Plan]

    public init(version: Int, plans: [Plan]) {
        self.version = version
        self.plans = plans
    }

    public func plan(id: String) -> Plan? { plans.first { $0.id == id } }
}
```

- [ ] **Step 4: 写 `PhraseLibrary` 与 `ContentLoader`**

`Core/Sources/SpeedTalkCore/Content/PhraseLibrary.swift`：

```swift
import Foundation

public struct PhraseLibrary: Sendable {
    private let byID: [String: Phrase]
    public let all: [Phrase]

    public init(phrases: [Phrase]) {
        self.all = phrases
        self.byID = Dictionary(uniqueKeysWithValues: phrases.map { ($0.id, $0) })
    }

    public func phrase(id: String) -> Phrase? { byID[id] }

    public func phrases(plan: String, stage: String) -> [Phrase] {
        all.filter { $0.plan == plan && $0.stage == stage }
            .sorted { ($0.day, $0.index) < ($1.day, $1.index) }
    }

    public func search(_ query: String) -> [Phrase] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !keyword.isEmpty else { return all }
        return all.filter {
            $0.en.lowercased().contains(keyword)
            || $0.zh.contains(keyword)
            || $0.tags.contains { $0.lowercased().contains(keyword) }
        }
    }

    public func phrases(scene: Scene) -> [Phrase] {
        all.filter { $0.scene == scene }.sorted { $0.id < $1.id }
    }
}
```

`Core/Sources/SpeedTalkCore/Content/ContentLoader.swift`：

```swift
import Foundation

public struct ContentBundle: Sendable {
    public let library: PhraseLibrary
    public let curriculum: Curriculum

    public init(library: PhraseLibrary, curriculum: Curriculum) {
        self.library = library
        self.curriculum = curriculum
    }
}

public enum ContentLoaderError: Error, CustomStringConvertible {
    case missingResource(String)

    public var description: String {
        switch self {
        case .missingResource(let name): return "找不到内容文件：\(name)"
        }
    }
}

public enum ContentLoader {
    struct PhraseFile: Decodable {
        let version: Int
        let phrases: [Phrase]
    }

    public static func loadBundled() throws -> ContentBundle {
        guard let phraseURL = Bundle.module.url(forResource: "phrases", withExtension: "json") else {
            throw ContentLoaderError.missingResource("phrases.json")
        }
        guard let curriculumURL = Bundle.module.url(forResource: "curriculum", withExtension: "json") else {
            throw ContentLoaderError.missingResource("curriculum.json")
        }
        let decoder = JSONDecoder()
        let phraseFile = try decoder.decode(PhraseFile.self, from: Data(contentsOf: phraseURL))
        let curriculum = try decoder.decode(Curriculum.self, from: Data(contentsOf: curriculumURL))
        return ContentBundle(library: PhraseLibrary(phrases: phraseFile.phrases), curriculum: curriculum)
    }
}
```

- [ ] **Step 5: 写 `CurriculumService`**

`Core/Sources/SpeedTalkCore/Content/CurriculumService.swift`：

```swift
import Foundation

public struct CurriculumService: Sendable {
    public static let stageOrder = ["a", "b", "c"]

    public let curriculum: Curriculum
    public let library: PhraseLibrary

    public init(curriculum: Curriculum, library: PhraseLibrary) {
        self.curriculum = curriculum
        self.library = library
    }

    public func dayCount(plan: String, stage: String) -> Int {
        curriculum.plan(id: plan)?
            .stages.first { $0.id == stage }?
            .days.count ?? 0
    }

    public func day(plan: String, stage: String, day: Int) -> [Phrase] {
        guard let planModel = curriculum.plan(id: plan),
              let stageModel = planModel.stages.first(where: { $0.id == stage }),
              let dayModel = stageModel.days.first(where: { $0.day == day })
        else { return [] }
        return dayModel.phraseIDs.compactMap { library.phrase(id: $0) }
    }

    public func nextStage(after stage: String, plan: String) -> String? {
        guard let planModel = curriculum.plan(id: plan) else { return nil }
        let order = planModel.stages.map(\.id)
        guard let index = order.firstIndex(of: stage), index + 1 < order.count else { return nil }
        return order[index + 1]
    }

    public func validate() -> [String] {
        var issues: [String] = []
        for plan in curriculum.plans {
            for stage in plan.stages {
                let days = stage.days
                if days.count != 120 {
                    issues.append("\(plan.id)-\(stage.id) 天数应为 120，实际 \(days.count)")
                }
                for day in days {
                    if day.phraseIDs.count != 5 {
                        issues.append("\(plan.id)-\(stage.id)-\(day.day) 句数应为 5，实际 \(day.phraseIDs.count)")
                    }
                    for id in day.phraseIDs where library.phrase(id: id) == nil {
                        issues.append("\(plan.id)-\(stage.id)-\(day.day) 引用了不存在的句子 \(id)")
                    }
                }
            }
        }
        return issues
    }
}
```

- [ ] **Step 6: 写最小语料与课纲（Task 4 会补齐 600 句）**

`Core/Sources/SpeedTalkCore/Resources/phrases.json`：

```json
{
  "version": 1,
  "phrases": [
    {
      "id": "01-a-001-1",
      "plan": "01",
      "stage": "a",
      "unit": 1,
      "day": 1,
      "index": 1,
      "en": "I'm gonna grab a coffee. Want anything?",
      "zh": "我去买杯咖啡，你要带点什么吗？",
      "scene": "dining",
      "level": 1,
      "focus": "gonna = going to，口语里几乎必缩",
      "register": "casual",
      "tags": ["缩略", "同事闲聊"],
      "pronunciation": {
        "ipa": "/aɪm ˈɡʌnə ɡræb ə ˈkɔːfi/",
        "notes": ["gonna 读 /ˈɡʌnə/，不要读成 /ˈɡoʊɪŋ tuː/", "grab a 连读 /ˈɡræbə/"]
      },
      "variants": ["I'm grabbing a coffee — want one?"],
      "avoid": "I am going to buy a cup of coffee. Do you want anything?",
      "transfer": "I'm gonna grab ___ — want anything?",
      "context": "办公室午后，随口问同事要不要带咖啡"
    },
    {
      "id": "01-a-001-2",
      "plan": "01",
      "stage": "a",
      "unit": 1,
      "day": 1,
      "index": 2,
      "en": "Could I get that to go?",
      "zh": "这个能打包带走吗？",
      "scene": "dining",
      "level": 1,
      "focus": "to go = 外带，比 take away 更美式",
      "register": "neutral",
      "tags": ["点单", "外带"],
      "pronunciation": {
        "ipa": "/kʊd aɪ ɡɛt ðæt tə ɡoʊ/",
        "notes": ["Could I 连读 /ˈkʊdaɪ/", "get that 的 t 只做口型不爆破"]
      },
      "variants": ["Can I get this to go?", "For here or to go?"],
      "avoid": "Can I take away this?",
      "transfer": "Could I get ___ to go?",
      "context": "咖啡店点完单，店员问堂食还是外带"
    },
    {
      "id": "01-a-001-3",
      "plan": "01",
      "stage": "a",
      "unit": 1,
      "day": 1,
      "index": 3,
      "en": "I'll have the same.",
      "zh": "我要一样的。",
      "scene": "dining",
      "level": 1,
      "focus": "I'll have = 点单最常用句式，比 I want 礼貌",
      "register": "neutral",
      "tags": ["点单", "高频"],
      "pronunciation": {
        "ipa": "/aɪl hæv ðə seɪm/",
        "notes": ["I'll 读成一个音节 /aɪl/", "have 弱读 /həv/"]
      },
      "variants": ["Same for me.", "I'll get the same."],
      "avoid": "I want same as him.",
      "transfer": "I'll have ___.",
      "context": "朋友先点了，你懒得选，直接跟一份"
    },
    {
      "id": "01-a-001-4",
      "plan": "01",
      "stage": "a",
      "unit": 1,
      "day": 1,
      "index": 4,
      "en": "Can I get a refill?",
      "zh": "能续一杯吗？",
      "scene": "dining",
      "level": 1,
      "focus": "refill 是美式餐厅的免费续杯，进店必会",
      "register": "casual",
      "tags": ["餐厅", "续杯"],
      "pronunciation": {
        "ipa": "/kən aɪ ɡɛt ə ˈriːfɪl/",
        "notes": ["Can I 连读 /kənaɪ/", "refill 重音在前 /ˈriːfɪl/"]
      },
      "variants": ["Could I get a refill?", "Mind topping me off?"],
      "avoid": "Can I add one more cup for free?",
      "transfer": "Can I get a refill of ___?",
      "context": "美式餐厅服务员路过，你杯子空了"
    },
    {
      "id": "01-a-001-5",
      "plan": "01",
      "stage": "a",
      "unit": 1,
      "day": 1,
      "index": 5,
      "en": "I'm just looking, thanks.",
      "zh": "我先随便看看，谢谢。",
      "scene": "life",
      "level": 1,
      "focus": "店员一靠近就用这句，礼貌拒绝不尴尬",
      "register": "neutral",
      "tags": ["购物", "拒绝"],
      "pronunciation": {
        "ipa": "/aɪm dʒʌst ˈlʊkɪŋ θæŋks/",
        "notes": ["just 弱读 /dʒəs/", "looking 的 ing 读 /ɪŋ/ 不要读成 /ɪn/"]
      },
      "variants": ["Just browsing, thanks.", "I'm good, thanks."],
      "avoid": "I only see see.",
      "transfer": "I'm just ___, thanks.",
      "context": "进店后店员问 Can I help you?"
    }
  ]
}
```

`Core/Sources/SpeedTalkCore/Resources/curriculum.json`（Task 4 补齐 120 天，先打通 1 天）：

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
              "title": "第一单元：开口与点单",
              "days": [
                {
                  "day": 1,
                  "title": "开口第一句",
                  "phraseIDs": ["01-a-001-1", "01-a-001-2", "01-a-001-3", "01-a-001-4", "01-a-001-5"]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

> 校验测试此时会报「天数应为 120」「句数」类问题，这是预期的。Step 7 先把断言放宽到只验证加载与引用完整性，Task 4 完成后恢复严格断言。

- [ ] **Step 7: 暂时按最小数据跑通测试**

把 `bundledCurriculumHasNoValidationIssues` 改为只断言无「引用不存在」类问题：

```swift
@Test func bundledCurriculumHasNoDanglingReferences() throws {
    let bundle = try ContentLoader.loadBundled()
    let issues = CurriculumService(curriculum: bundle.curriculum, library: bundle.library).validate()
    #expect(issues.contains { $0.contains("不存在的句子") } == false)
}
```

Run: `swift test --package-path Core 2>&1 | tail -20`
Expected: 全部通过

- [ ] **Step 8: 提交**

```bash
git add -A
git commit -m "feat(core): add content models, library, curriculum service and seed data"
```

---

### Task 4: 生产 01-a 全部 600 句语料

**Files:**
- Modify: `Core/Sources/SpeedTalkCore/Resources/phrases.json`（追加至 600 条）
- Modify: `Core/Sources/SpeedTalkCore/Resources/curriculum.json`（补齐 120 天）
- Test: `Core/Tests/SpeedTalkCoreTests/ContentTests.swift`（加严格断言）

**Interfaces:**
- Consumes: `Phrase`、`Curriculum` 结构（Task 3）
- Produces: 完整 `01-a` 600 句 + 120 天课纲，供后续所有 Task 使用

- [ ] **Step 1: 先加严格测试（预期失败）**

在 `ContentTests.swift` 追加：

```swift
@Test func plan01StageAHasExactly600Phrases() throws {
    let bundle = try ContentLoader.loadBundled()
    let count = bundle.library.phrases(plan: "01", stage: "a").count
    #expect(count == 600)
}

@Test func plan01StageAHas120DaysOfFive() throws {
    let bundle = try ContentLoader.loadBundled()
    let service = CurriculumService(curriculum: bundle.curriculum, library: bundle.library)
    #expect(service.dayCount(plan: "01", stage: "a") == 120)
    for day in 1...120 {
        #expect(service.day(plan: "01", stage: "a", day: day).count == 5)
    }
}

@Test func allPhrasesFollowCopyRules() throws {
    let bundle = try ContentLoader.loadBundled()
    for phrase in bundle.library.all {
        #expect(phrase.pronunciation.notes.isEmpty == false, "\(phrase.id) 缺发音提示")
        #expect(phrase.variants.isEmpty == false, "\(phrase.id) 缺变体")
        #expect(phrase.avoid?.isEmpty == false, "\(phrase.id) 缺 avoid 反例")
        #expect(phrase.focus.isEmpty == false, "\(phrase.id) 缺 focus")
        let limit = phrase.stage == "a" ? 10 : (phrase.stage == "b" ? 14 : 18)
        #expect(phrase.en.split(separator: " ").count <= limit, "\(phrase.id) 超长")
    }
}

@Test func phraseIDsAreUniqueAndWellFormed() throws {
    let bundle = try ContentLoader.loadBundled()
    let ids = bundle.library.all.map(\.id)
    #expect(Set(ids).count == ids.count)
    for phrase in bundle.library.all {
        #expect(phrase.id == String(format: "%@-%@-%03d-%d", phrase.plan, phrase.stage, phrase.day, phrase.index))
    }
}
```

Run: `swift test --package-path Core 2>&1 | tail -20`
Expected: FAIL（count 为 5，不是 600）

- [ ] **Step 2: 按单元主题表编排 120 天**

单元 1（Day 1–30，150 句）：开口与点单。主题顺序：

| Day | 主题 | Day | 主题 |
|---|---|---|---|
| 1 | 打招呼与点单 | 16 | 咖啡与续杯 |
| 2 | 堂食与外带 | 17 | 结账与分账 |
| 3 | 点主食 | 18 | 快餐 drive-thru |
| 4 | 说不要与忌口 | 19 | 打包与加热 |
| 5 | 问推荐 | 20 | 说味道 |
| 6 | 点饮料 | 21 | 便利店 |
| 7 | 综合复用（取 Day 1–6） | 22 | 超市找货 |
| 8 | 进店与浏览 | 23 | 结账排队 |
| 9 | 问价格与折扣 | 24 | 退换货 |
| 10 | 试穿 | 25 | 问路 |
| 11 | 尺码与颜色 | 26 | 打车 |
| 12 | 付款方式 | 27 | 公交地铁 |
| 13 | 要袋子与小票 | 28 | 综合复用（取 Day 22–27） |
| 14 | 综合复用（取 Day 8–13） | 29 | 酒店入住与退房 |
| 15 | 点单升级：加料与去料 | 30 | 阶段小结：Unit 1 全场景串练 |

单元 2（Day 31–60，150 句）：住所与出行。单元 3（Day 61–90，150 句）：办事与医疗。单元 4（Day 91–120，150 句）：邻里与消费。

- [ ] **Step 3: 按 Schema 逐日生产 5 句**

每条必须满足 Global Constraints 与 Spec 2.6 的 7 条用词标准。以下为 Day 2 的 5 条完整范例（其余按此密度生产）：

```json
[
  {
    "id": "01-a-002-1", "plan": "01", "stage": "a", "unit": 1, "day": 2, "index": 1,
    "en": "For here or to go?",
    "zh": "堂食还是外带？",
    "scene": "dining", "level": 1,
    "focus": "店员问你时的原话，听懂就能立刻回答",
    "register": "neutral", "tags": ["点单", "必听句"],
    "pronunciation": { "ipa": "/fər hɪr ɔr tə ɡoʊ/", "notes": ["for here 连读 /fərˈhɪr/", "or 弱读 /ər/"] },
    "variants": ["Here or to go?", "Is that for here?"],
    "avoid": "Eat here or take away?",
    "transfer": "For here or ___?",
    "context": "点完单，收银员抬头问你"
  },
  {
    "id": "01-a-002-2", "plan": "01", "stage": "a", "unit": 1, "day": 2, "index": 2,
    "en": "To go, please.",
    "zh": "外带，谢谢。",
    "scene": "dining", "level": 1,
    "focus": "最短回答，两个词解决问题",
    "register": "neutral", "tags": ["点单", "极简回答"],
    "pronunciation": { "ipa": "/tə ɡoʊ pliːz/", "notes": ["to 弱读 /tə/，不要读 /tuː/"] },
    "variants": ["Takeout, please.", "I'll take it to go."],
    "avoid": "I want take away please.",
    "transfer": "___, please.",
    "context": "回答 For here or to go?"
  },
  {
    "id": "01-a-002-3", "plan": "01", "stage": "a", "unit": 1, "day": 2, "index": 3,
    "en": "I'll take the combo.",
    "zh": "我要套餐。",
    "scene": "dining", "level": 1,
    "focus": "combo = 套餐，快餐店高频词",
    "register": "casual", "tags": ["快餐", "套餐"],
    "pronunciation": { "ipa": "/aɪl teɪk ðə ˈkɑmboʊ/", "notes": ["combo 重音在前 /ˈkɑmboʊ/"] },
    "variants": ["The combo works for me.", "I'll do the number two combo."],
    "avoid": "I want the set meal.",
    "transfer": "I'll take the ___ combo.",
    "context": "快餐店菜单上写着 Combo 1/2/3"
  },
  {
    "id": "01-a-002-4", "plan": "01", "stage": "a", "unit": 1, "day": 2, "index": 4,
    "en": "Can I swap the fries for a salad?",
    "zh": "薯条能换成沙拉吗？",
    "scene": "dining", "level": 1,
    "focus": "swap A for B = 把 A 换成 B，办事万能句式",
    "register": "neutral", "tags": ["换菜", "句式"],
    "pronunciation": { "ipa": "/kən aɪ swɑp ðə fraɪz fər ə ˈsæləd/", "notes": ["swap 的 p 只做口型", "fries for a 连读 /fraɪzfərə/"] },
    "variants": ["Could I get a salad instead of fries?", "Any way to swap the side?"],
    "avoid": "Can I change french fries to salad?",
    "transfer": "Can I swap ___ for ___?",
    "context": "套餐默认配薯条，你想吃轻一点"
  },
  {
    "id": "01-a-002-5", "plan": "01", "stage": "a", "unit": 1, "day": 2, "index": 5,
    "en": "That's it, thanks.",
    "zh": "就这些，谢谢。",
    "scene": "dining", "level": 1,
    "focus": "点完单收尾的固定说法，比 No more 自然",
    "register": "casual", "tags": ["点单", "收尾"],
    "pronunciation": { "ipa": "/ðæts ɪt θæŋks/", "notes": ["That's it 连成一串 /ˈðætsɪt/"] },
    "variants": ["That's all, thanks.", "I think that's everything."],
    "avoid": "No more, thank you.",
    "transfer": "That's it for ___.",
    "context": "店员问 Anything else?"
  }
]
```

- [ ] **Step 4: 补齐 curriculum.json 的 120 天**

每天 5 个 `phraseIDs`，格式 `01-a-{day:3位}-{1...5}`；每 30 天归入一个新 `unit`（`index` 1–4，`title` 用单元名）；第 7/14/21/28 天为复用日，其 IDs 指向当天 5 句（复用句仍独立编号，内容抄自前 6 天对应位置）。

- [ ] **Step 5: 跑测试验证 600 句完整**

Run: `swift test --package-path Core 2>&1 | tail -30`
Expected: 全部通过。若有「超长」「缺 avoid」「ID 格式」失败，按报错逐条修

- [ ] **Step 6: 报告内容质量抽查**

Run:

```bash
python3 -c "
import json
d = json.load(open('Core/Sources/SpeedTalkCore/Resources/phrases.json'))
ps = d['phrases']
print('total', len(ps))
print('scenes', sorted({p['scene'] for p in ps}))
print('registers', sorted({p['register'] for p in ps}))
print('avg words', round(sum(len(p['en'].split()) for p in ps) / len(ps), 1))
"
```

Expected: `total 600`，scenes 覆盖 ≥ 5 类，avg words ≤ 10

- [ ] **Step 7: 提交**

```bash
git add -A
git commit -m "content: author 600 phrases for plan 01 stage a"
```

---

### Task 5: 每日选题、复习调度、进度推进（TDD）

**Files:**
- Create: `Core/Sources/SpeedTalkCore/Selection/PlanProgressSnapshot.swift`
- Create: `Core/Sources/SpeedTalkCore/Selection/DailySelector.swift`
- Create: `Core/Sources/SpeedTalkCore/Selection/ProgressEngine.swift`
- Create: `Core/Sources/SpeedTalkCore/Selection/ReviewScheduler.swift`
- Create: `Core/Sources/SpeedTalkCore/Selection/StreakCalculator.swift`
- Test: `Core/Tests/SpeedTalkCoreTests/SelectionTests.swift`
- Test: `Core/Tests/SpeedTalkCoreTests/StreakTests.swift`

**Interfaces:**
- Consumes: `CurriculumService`、`PhraseLibrary`
- Produces:
  - `struct PlanProgressSnapshot: Equatable, Sendable { var planID: String; var stage: String; var day: Int; var completedDays: Int }` + `.initial(planID:)`
  - `struct DailySelector { func selection(for: PlanProgressSnapshot) -> [Phrase] }`（依赖注入 `CurriculumService`）
  - `struct ProgressEngine { func advance(_: PlanProgressSnapshot) -> PlanAdvanceResult }`，`PlanAdvanceResult { snapshot, didFinishPlan }`
  - `struct ReviewScheduler { func next(level: Int, score: Int, from: Date, calendar: Calendar) -> ReviewOutcome }`，`ReviewOutcome { level, nextReviewAt }`
  - `enum StreakCalculator { static func nextStreak(current: Int, lastStudyDate: Date?, now: Date, calendar: Calendar) -> Int }`

- [ ] **Step 1: 写失败测试**

`Core/Tests/SpeedTalkCoreTests/SelectionTests.swift`：

```swift
import Testing
import Foundation
@testable import SpeedTalkCore

private func makeService() throws -> CurriculumService {
    let bundle = try ContentLoader.loadBundled()
    return CurriculumService(curriculum: bundle.curriculum, library: bundle.library)
}

@Test func dailySelectionReturnsFivePhrases() throws {
    let service = try makeService()
    let selector = DailySelector(service: service)
    let snapshot = PlanProgressSnapshot(planID: "01", stage: "a", day: 1, completedDays: 0)
    #expect(selector.selection(for: snapshot).count == 5)
}

@Test func advanceMovesToNextDay() throws {
    let service = try makeService()
    let engine = ProgressEngine(service: service)
    let result = engine.advance(PlanProgressSnapshot(planID: "01", stage: "a", day: 1, completedDays: 0))
    #expect(result.snapshot.day == 2)
    #expect(result.snapshot.completedDays == 1)
    #expect(result.didFinishPlan == false)
}

@Test func advanceRollsOverToNextStageAtDay120() throws {
    let service = try makeService()
    let engine = ProgressEngine(service: service)
    let result = engine.advance(PlanProgressSnapshot(planID: "01", stage: "a", day: 120, completedDays: 119))
    #expect(result.snapshot.stage == "b")
    #expect(result.snapshot.day == 1)
}

@Test func advanceAtLastStageFinishesPlan() throws {
    let service = try makeService()
    let engine = ProgressEngine(service: service)
    let result = engine.advance(PlanProgressSnapshot(planID: "01", stage: "c", day: 120, completedDays: 119))
    #expect(result.didFinishPlan)
}

@Test func reviewIntervalGrowsWhenScoreIsHigh() {
    let scheduler = ReviewScheduler()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let outcome = scheduler.next(level: 0, score: 90, from: now, calendar: .current)
    #expect(outcome.level == 1)
    #expect(outcome.nextReviewAt.timeIntervalSince(now) >= 86_400)
}

@Test func reviewResetsWhenScoreIsLow() {
    let scheduler = ReviewScheduler()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let outcome = scheduler.next(level: 4, score: 40, from: now, calendar: .current)
    #expect(outcome.level == 0)
    #expect(outcome.nextReviewAt.timeIntervalSince(now) < 2 * 86_400)
}
```

`Core/Tests/SpeedTalkCoreTests/StreakTests.swift`：

```swift
import Testing
import Foundation
@testable import SpeedTalkCore

@Test func firstStudyMakesStreakOne() {
    #expect(StreakCalculator.nextStreak(current: 0, lastStudyDate: nil, now: Date(), calendar: .current) == 1)
}

@Test func sameDayKeepsStreak() {
    let now = Date()
    let earlier = now.addingTimeInterval(-3600)
    #expect(StreakCalculator.nextStreak(current: 5, lastStudyDate: earlier, now: now, calendar: .current) == 5)
}

@Test func yesterdayIncrementsStreak() {
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    #expect(StreakCalculator.nextStreak(current: 5, lastStudyDate: yesterday, now: now, calendar: .current) == 6)
}

@Test func gapResetsStreak() {
    let now = Date()
    let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
    #expect(StreakCalculator.nextStreak(current: 9, lastStudyDate: threeDaysAgo, now: now, calendar: .current) == 1)
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Core 2>&1 | tail -20`
Expected: 编译失败，类型未定义

- [ ] **Step 3: 实现四个类型**

`Core/Sources/SpeedTalkCore/Selection/PlanProgressSnapshot.swift`：

```swift
import Foundation

public struct PlanProgressSnapshot: Equatable, Sendable {
    public var planID: String
    public var stage: String
    public var day: Int
    public var completedDays: Int

    public init(planID: String, stage: String, day: Int, completedDays: Int) {
        self.planID = planID
        self.stage = stage
        self.day = day
        self.completedDays = completedDays
    }

    public static func initial(planID: String) -> PlanProgressSnapshot {
        PlanProgressSnapshot(planID: planID, stage: "a", day: 1, completedDays: 0)
    }
}
```

`Core/Sources/SpeedTalkCore/Selection/DailySelector.swift`：

```swift
import Foundation

public struct DailySelector: Sendable {
    private let service: CurriculumService

    public init(service: CurriculumService) {
        self.service = service
    }

    public func selection(for snapshot: PlanProgressSnapshot) -> [Phrase] {
        service.day(plan: snapshot.planID, stage: snapshot.stage, day: snapshot.day)
    }

    public func dayTitle(plan: String, stage: String, day: Int) -> String {
        service.curriculum.plan(id: plan)?
            .stages.first { $0.id == stage }?
            .units.flatMap(\.days).first { $0.day == day }?
            .title ?? "第 \(day) 天"
    }
}
```

`Core/Sources/SpeedTalkCore/Selection/ProgressEngine.swift`：

```swift
import Foundation

public struct PlanAdvanceResult: Equatable, Sendable {
    public let snapshot: PlanProgressSnapshot
    public let didFinishPlan: Bool
}

public struct ProgressEngine: Sendable {
    private let service: CurriculumService

    public init(service: CurriculumService) {
        self.service = service
    }

    public func advance(_ snapshot: PlanProgressSnapshot) -> PlanAdvanceResult {
        guard let plan = service.curriculum.plan(id: snapshot.planID) else {
            return PlanAdvanceResult(snapshot: snapshot, didFinishPlan: false)
        }
        let order = plan.stages.map(\.id)
        let stageIndex = order.firstIndex(of: snapshot.stage) ?? 0
        let dayCount = max(service.dayCount(plan: snapshot.planID, stage: snapshot.stage), 1)

        var next = snapshot
        next.completedDays = min(snapshot.completedDays + 1, dayCount)

        if snapshot.day < dayCount {
            next.day = snapshot.day + 1
            return PlanAdvanceResult(snapshot: next, didFinishPlan: false)
        }

        if stageIndex + 1 < order.count {
            next.stage = order[stageIndex + 1]
            next.day = 1
            next.completedDays = 0
            return PlanAdvanceResult(snapshot: next, didFinishPlan: false)
        }

        return PlanAdvanceResult(snapshot: next, didFinishPlan: true)
    }
}
```

`Core/Sources/SpeedTalkCore/Selection/ReviewScheduler.swift`：

```swift
import Foundation

public struct ReviewOutcome: Equatable, Sendable {
    public let level: Int
    public let nextReviewAt: Date
}

public struct ReviewScheduler: Sendable {
    /// 等级 1...5 对应的间隔天数
    public static let intervals: [Int] = [1, 3, 7, 16, 35]

    public init() {}

    public func next(level: Int, score: Int, from date: Date, calendar: Calendar) -> ReviewOutcome {
        if score < 70 {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            return ReviewOutcome(level: 0, nextReviewAt: nextDate)
        }
        let newLevel = min(max(level + 1, 1), 5)
        let days = Self.intervals[newLevel - 1]
        let nextDate = calendar.date(byAdding: .day, value: days, to: date) ?? date
        return ReviewOutcome(level: newLevel, nextReviewAt: nextDate)
    }
}
```

`Core/Sources/SpeedTalkCore/Selection/StreakCalculator.swift`：

```swift
import Foundation

public enum StreakCalculator {
    public static func nextStreak(
        current: Int,
        lastStudyDate: Date?,
        now: Date,
        calendar: Calendar
    ) -> Int {
        guard let lastStudyDate else { return 1 }
        if calendar.isDate(lastStudyDate, inSameDayAs: now) {
            return max(current, 1)
        }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastStudyDate),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        return days == 1 ? max(current, 1) + 1 : 1
    }
}
```

- [ ] **Step 4: 跑测试直到全绿**

Run: `swift test --package-path Core 2>&1 | tail -20`
Expected: 全部通过

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "feat(core): add daily selector, progress engine, review scheduler and streak calculator"
```

---

### Task 6: App 数据层与依赖容器

**Files:**
- Create: `SpeedTalk/Core/Persistence/UserProfile.swift`
- Create: `SpeedTalk/Core/Persistence/PlanProgress.swift`
- Create: `SpeedTalk/Core/Persistence/PhraseProgress.swift`
- Create: `SpeedTalk/Core/Persistence/DailyLog.swift`
- Create: `SpeedTalk/Core/Persistence/AchievementRecord.swift`
- Create: `SpeedTalk/Core/Persistence/ModelContainerFactory.swift`
- Create: `SpeedTalk/App/AppContainer.swift`
- Create: `SpeedTalk/App/RootView.swift`
- Modify: `SpeedTalk/App/SpeedTalkApp.swift`

**Interfaces:**
- Consumes: `ContentLoader`、`ContentBundle`、`CurriculumService`、`DailySelector`、`ProgressEngine`、`PlanProgressSnapshot`
- Produces:
  - `@Model final class UserProfile`（`activePlan`、`streak`、`longestStreak`、`lastStudyDate`、`dailyGoal`、`speechRate`、`hasOnboarded`、`reminderHour`、`aiBaseURL`、`aiModel`、`aiQuotaPerDay`、`aiQuotaUsed`、`aiQuotaDate`）
  - `@Model final class PlanProgress`（`planID`、`currentStage`、`currentDay`、`completedDays`、`isCompleted`），计算属性 `snapshot: PlanProgressSnapshot`
  - `@Model final class PhraseProgress`（`phraseID`、`masteryLevel`、`bestScore`、`attemptCount`、`isFavorite`、`lastReviewedAt`、`nextReviewAt`、`lastTranscript`）
  - `@Model final class DailyLog`（`dateKey`、`plan`、`stage`、`day`、`completedCount`、`totalScore`、`isCheckedIn`）
  - `@Model final class AchievementRecord`（`achievementID`、`unlockedAt`）
  - `@MainActor @Observable final class AppContainer`（`content: ContentBundle`、`service: CurriculumService`、`selector: DailySelector`、`engine: ProgressEngine`、`modelContainer: ModelContainer`）
  - `AppContainer.live() throws -> AppContainer`

- [ ] **Step 1: 写 SwiftData 模型**

`SpeedTalk/Core/Persistence/UserProfile.swift`：

```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    var activePlan: String = "01"
    var streak: Int = 0
    var longestStreak: Int = 0
    var lastStudyDate: Date?
    var startDate: Date = .now
    var dailyGoal: Int = 5
    var speechRate: Double = 0.48
    var hasOnboarded: Bool = false
    var reminderHour: Int = 20
    var aiBaseURL: String = "https://api.openai.com/v1"
    var aiModel: String = "gpt-4o-mini"
    var aiQuotaPerDay: Int = 30
    var aiQuotaUsed: Int = 0
    var aiQuotaDate: Date?

    init() {}
}
```

`SpeedTalk/Core/Persistence/PlanProgress.swift`：

```swift
import Foundation
import SwiftData
import SpeedTalkCore

@Model
final class PlanProgress {
    @Attribute(.unique) var planID: String
    var currentStage: String = "a"
    var currentDay: Int = 1
    var completedDays: Int = 0
    var isCompleted: Bool = false
    var finishedAt: Date?

    init(planID: String) {
        self.planID = planID
    }

    var snapshot: PlanProgressSnapshot {
        PlanProgressSnapshot(planID: planID, stage: currentStage, day: currentDay, completedDays: completedDays)
    }

    func apply(_ snapshot: PlanProgressSnapshot) {
        planID = snapshot.planID
        currentStage = snapshot.stage
        currentDay = snapshot.day
        completedDays = snapshot.completedDays
    }
}
```

`SpeedTalk/Core/Persistence/PhraseProgress.swift`：

```swift
import Foundation
import SwiftData

@Model
final class PhraseProgress {
    @Attribute(.unique) var phraseID: String
    var masteryLevel: Int = 0
    var bestScore: Int = 0
    var attemptCount: Int = 0
    var isFavorite: Bool = false
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var lastTranscript: String?

    init(phraseID: String) {
        self.phraseID = phraseID
    }
}
```

`SpeedTalk/Core/Persistence/DailyLog.swift`：

```swift
import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var dateKey: String
    var plan: String
    var stage: String
    var day: Int
    var completedCount: Int = 0
    var totalScore: Int = 0
    var isCheckedIn: Bool = false

    init(dateKey: String, plan: String, stage: String, day: Int) {
        self.dateKey = dateKey
        self.plan = plan
        self.stage = stage
        self.day = day
    }
}
```

`SpeedTalk/Core/Persistence/AchievementRecord.swift`：

```swift
import Foundation
import SwiftData

@Model
final class AchievementRecord {
    @Attribute(.unique) var achievementID: String
    var unlockedAt: Date

    init(achievementID: String, unlockedAt: Date = .now) {
        self.achievementID = achievementID
        self.unlockedAt = unlockedAt
    }
}
```

- [ ] **Step 2: 写容器工厂**

`SpeedTalk/Core/Persistence/ModelContainerFactory.swift`：

```swift
import Foundation
import SwiftData

enum ModelContainerFactory {
    static let schema = Schema([
        UserProfile.self,
        PlanProgress.self,
        PhraseProgress.self,
        DailyLog.self,
        AchievementRecord.self
    ])

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
```

- [ ] **Step 3: 写 `AppContainer`**

`SpeedTalk/App/AppContainer.swift`：

```swift
import Foundation
import SwiftData
import SpeedTalkCore

@MainActor
@Observable
final class AppContainer {
    let content: ContentBundle
    let service: CurriculumService
    let selector: DailySelector
    let engine: ProgressEngine
    let modelContainer: ModelContainer

    init(content: ContentBundle, modelContainer: ModelContainer) {
        self.content = content
        self.service = CurriculumService(curriculum: content.curriculum, library: content.library)
        self.selector = DailySelector(service: service)
        self.engine = ProgressEngine(service: service)
        self.modelContainer = modelContainer
    }

    static func live() throws -> AppContainer {
        let content = try ContentLoader.loadBundled()
        let container = try ModelContainerFactory.make()
        return AppContainer(content: content, modelContainer: container)
    }
}
```

- [ ] **Step 4: 写根视图与启动装配**

`SpeedTalk/App/RootView.swift`：

```swift
import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first, profile.hasOnboarded {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}
```

`SpeedTalk/App/SpeedTalkApp.swift`：

```swift
import SwiftUI
import SwiftData

@main
struct SpeedTalkApp: App {
    private let container: AppContainer
    private let modelContainer: ModelContainer

    init() {
        do {
            let container = try AppContainer.live()
            self.container = container
            self.modelContainer = container.modelContainer
        } catch {
            fatalError("内容或数据库加载失败：\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .modelContainer(modelContainer)
        }
    }
}
```

`ContentView` 直接定义在 `RootView.swift` 底部（Task 7 会修改它，避免跨文件重复声明）：

```swift
struct ContentView: View {
    var body: some View {
        Text("今日")
    }
}
```

`OnboardingView` 先建占位文件（Task 10 在原文件替换为完整三步流程）：

`SpeedTalk/Features/Onboarding/OnboardingView.swift`：

```swift
import SwiftUI

struct OnboardingView: View {
    var body: some View {
        Text("选择方案")
    }
}
```

- [ ] **Step 5: 编译并修正装配错误**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: 提交**

```bash
git add -A
git commit -m "feat(app): add SwiftData models, app container and bootstrap"
```

---

### Task 7: 今日卡片流界面

**Files:**
- Create: `SpeedTalk/Core/DesignSystem/Theme.swift`
- Create: `SpeedTalk/Core/DesignSystem/Components.swift`
- Create: `SpeedTalk/Features/Today/TodayViewModel.swift`
- Create: `SpeedTalk/Features/Today/TodayView.swift`
- Create: `SpeedTalk/Features/Today/PhraseCardView.swift`
- Create: `SpeedTalk/Features/Today/PhraseDetailView.swift`
- Modify: `SpeedTalk/App/RootView.swift`（ContentView 改为 TabView）

**Interfaces:**
- Consumes: `AppContainer`、`DailySelector`、`Phrase`
- Produces:
  - `TodayViewModel.phraseCard models`（`cards: [Phrase]`、`index: Int`、`current: Phrase?`、`advance()`、`isFinished: Bool`）
  - `PhraseCardView(phrase:index:total:)`、`PhraseDetailView(phrase:)`
  - `Theme`（颜色与字体）

- [ ] **Step 1: 写主题**

`SpeedTalk/Core/DesignSystem/Theme.swift`：

```swift
import SwiftUI

enum Theme {
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.12)
    static let paper = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let accent = Color(red: 0.10, green: 0.45, blue: 0.94)
    static let positive = Color(red: 0.13, green: 0.66, blue: 0.42)
    static let warning = Color(red: 0.90, green: 0.45, blue: 0.13)
    static let danger = Color(red: 0.83, green: 0.22, blue: 0.24)

    static func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return positive
        case "B": return warning
        default: return danger
        }
    }
}

extension Font {
    static let phrase = Font.system(size: 34, weight: .semibold, design: .rounded)
    static let phraseSmall = Font.system(size: 26, weight: .semibold, design: .rounded)
    static let captionLabel = Font.system(size: 13, weight: .medium, design: .rounded)
}
```

- [ ] **Step 2: 写可复用组件**

`SpeedTalk/Core/DesignSystem/Components.swift`：

```swift
import SwiftUI
import SpeedTalkCore

struct TagChip: View {
    let text: String
    var tint: Color = Theme.accent

    var body: some View {
        Text(text)
            .font(.captionLabel)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
            .foregroundStyle(tint)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String  // 必带下一步动作

    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
```

- [ ] **Step 3: 写 `TodayViewModel`（先只做选题与翻页）**

`SpeedTalk/Features/Today/TodayViewModel.swift`：

```swift
import Foundation
import Observation
import SpeedTalkCore

@MainActor
@Observable
final class TodayViewModel {
    private let selector: DailySelector
    private(set) var cards: [Phrase] = []
    private(set) var index: Int = 0
    private(set) var dayTitle: String = ""

    init(selector: DailySelector) {
        self.selector = selector
    }

    func load(snapshot: PlanProgressSnapshot) {
        cards = selector.selection(for: snapshot)
        dayTitle = selector.dayTitle(plan: snapshot.planID, stage: snapshot.stage, day: snapshot.day)
        index = 0
    }

    var current: Phrase? { cards.indices.contains(index) ? cards[index] : nil }
    var isFinished: Bool { index >= cards.count }
    var total: Int { cards.count }

    func advance() {
        guard index < cards.count else { return }
        index += 1
    }

    func restart() { index = 0 }
}
```

- [ ] **Step 4: 写卡片与详情视图**

`SpeedTalk/Features/Today/PhraseCardView.swift`：

```swift
import SwiftUI
import SpeedTalkCore

struct PhraseCardView: View {
    let phrase: Phrase
    let position: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                TagChip(text: phrase.scene.title)
                TagChip(text: phrase.register.title, tint: .secondary)
                Spacer()
                Text("\(position)/\(total)")
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
            }

            Text(phrase.en)
                .font(.phrase)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(phrase.zh)
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                Label(phrase.focus, systemImage: "sparkle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
                Text(phrase.pronunciation.ipa)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Theme.ink.opacity(0.06), lineWidth: 1)
        )
    }
}
```

`SpeedTalk/Features/Today/PhraseDetailView.swift`：

```swift
import SwiftUI
import SpeedTalkCore

struct PhraseDetailView: View {
    let phrase: Phrase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("怎么用") {
                    Text(phrase.context)
                }
                section("发音要点") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(phrase.pronunciation.ipa)
                            .font(.system(.subheadline, design: .monospaced))
                        ForEach(phrase.pronunciation.notes, id: \.self) { note in
                            Label(note, systemImage: "waveform")
                                .font(.subheadline)
                        }
                    }
                }
                section("换个说法") {
                    ForEach(phrase.variants, id: \.self) { variant in
                        Text(variant).font(.body)
                    }
                }
                if let avoid = phrase.avoid {
                    section("别说成") {
                        Text(avoid)
                            .font(.body)
                            .foregroundStyle(Theme.danger)
                    }
                }
                if let transfer = phrase.transfer {
                    section("换个词也能用") {
                        Text(transfer)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.paper)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.captionLabel).foregroundStyle(.secondary)
            content()
        }
    }
}
```

- [ ] **Step 5: 写 `TodayView` 与 TabView**

`SpeedTalk/Features/Today/TodayView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct TodayView: View {
    @Environment(AppContainer.self) private var container
    @Query private var progressList: [PlanProgress]
    @Query private var profiles: [UserProfile]
    @State private var viewModel: TodayViewModel?

    private var activePlan: String { profiles.first?.activePlan ?? "01" }
    private var progress: PlanProgress? { progressList.first { $0.planID == activePlan } }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel, let phrase = vm.current {
                    VStack(spacing: 16) {
                        header(vm)
                        PhraseCardView(phrase: phrase, position: vm.index + 1, total: vm.total)
                            .id(phrase.id)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        actions(vm)
                    }
                    .padding(20)
                } else if let vm = viewModel, vm.isFinished {
                    EmptyStateView(title: "今天 5 句学完了", message: "点下面的按钮打卡，明天再来 5 句")
                } else {
                    ProgressView().task { load() }
                }
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("今日")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func header(_ vm: TodayViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(container.service.curriculum.plan(id: activePlan)?.title ?? "") · \(progress?.currentStage ?? "a") 阶段")
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
                Text(vm.dayTitle).font(.headline)
            }
            Spacer()
            Text("Day \(progress?.currentDay ?? 1)")
                .font(.captionLabel)
                .foregroundStyle(.secondary)
        }
    }

    private func actions(_ vm: TodayViewModel) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { vm.advance() }
            } label: {
                Label("下一句", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            NavigationLink {
                if let phrase = vm.current { PhraseDetailView(phrase: phrase) }
            } label: {
                Label("详解", systemImage: "text.book.closed")
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    private func load() {
        guard viewModel == nil else { return }
        let vm = TodayViewModel(selector: container.selector)
        let snapshot = progress?.snapshot ?? .initial(planID: activePlan)
        vm.load(snapshot: snapshot)
        viewModel = vm
    }
}
```

`SpeedTalk/App/RootView.swift` 的 `ContentView` 改为：

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今日", systemImage: "sun.max") }
            Text("课表")
                .tabItem { Label("课表", systemImage: "list.bullet.rectangle") }
            Text("场景")
                .tabItem { Label("场景", systemImage: "square.grid.2x2") }
            Text("对练")
                .tabItem { Label("对练", systemImage: "bubble.left.and.bubble.right") }
            Text("我的")
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .tint(Theme.accent)
    }
}
```

- [ ] **Step 6: 编译验证**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: 提交**

```bash
git add -A
git commit -m "feat(app): add today card flow with phrase detail"
```

---

### Task 8: 示范朗读、录音与语音识别

**Files:**
- Create: `SpeedTalk/Core/Speech/AudioSessionManager.swift`
- Create: `SpeedTalk/Core/Speech/SpeechPlayer.swift`
- Create: `SpeedTalk/Core/Speech/SpeechRecognizer.swift`
- Create: `SpeedTalk/Features/Today/PhraseAudioBar.swift`
- Modify: `SpeedTalk/Core/DesignSystem/Theme.swift`（无需改动，仅作引用说明）

**Interfaces:**
- Consumes: 无
- Produces:
  - `final class AudioSessionManager`（`activateRecording()`、`activatePlayback()`、`deactivate()`）
  - `@MainActor @Observable final class SpeechPlayer`（`rate: Double`、`speak(_:)`、`stop()`、`isSpeaking`）
  - `@MainActor @Observable final class SpeechRecognizer`（`state: State`、`transcript: String`、`start()`、`stop() -> String`、`requestAuthorization() async -> Bool`）
  - `PhraseAudioBar(phrase:)`（慢速 / 常速 / 停止）

- [ ] **Step 1: 写音频会话与播放器**

`SpeedTalk/Core/Speech/AudioSessionManager.swift`：

```swift
import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private let session = AVAudioSession.sharedInstance()

    func activateRecording() throws {
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func activatePlayback() throws {
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
    }

    func deactivate() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}
```

`SpeedTalk/Core/Speech/SpeechPlayer.swift`：

```swift
import AVFoundation
import Observation

@MainActor
@Observable
final class SpeechPlayer: NSObject, AVSpeechSynthesizerDelegate {
    enum Speed: Double, CaseIterable {
        case slow = 0.40
        case normal = 0.50

        var title: String {
            switch self {
            case .slow: return "慢速"
            case .normal: return "常速"
            }
        }
    }

    private let synthesizer = AVSpeechSynthesizer()
    private let session = AudioSessionManager.shared
    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, speed: Speed = .normal, language: String = "en-US") {
        stop()
        try? session.activatePlayback()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = speed.rawValue
        utterance.pitchMultiplier = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
```

- [ ] **Step 2: 写识别器**

`SpeedTalk/Core/Speech/SpeechRecognizer.swift`：

```swift
import AVFoundation
import Observation
import Speech

@MainActor
@Observable
final class SpeechRecognizer {
    enum State: Equatable {
        case idle
        case recording
        case processing
        case denied
        case unavailable
    }

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var startedAt: Date?

    private(set) var state: State = .idle
    private(set) var transcript: String = ""
    private(set) var elapsed: TimeInterval = 0

    var isAvailable: Bool { recognizer?.isAvailable ?? false }

    func requestAuthorization() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else {
            state = .denied
            return false
        }
        let micGranted = await AVAudioApplication.requestRecordPermission()
        if !micGranted { state = .denied }
        return micGranted
    }

    func start() throws {
        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable
            throw NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "识别服务不可用"])
        }

        transcript = ""
        elapsed = 0
        startedAt = .now
        try AudioSessionManager.shared.activateRecording()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.finishAudio()
                }
            }
        }
        state = .recording
    }

    @discardableResult
    func stop() -> String {
        guard state == .recording else { return transcript }
        elapsed = startedAt.map { Date.now.timeIntervalSince($0) } ?? 0
        state = .processing
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        AudioSessionManager.shared.deactivate()
        state = .idle
        return transcript
    }

    private func finishAudio() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        elapsed = startedAt.map { Date.now.timeIntervalSince($0) } ?? 0
        state = .idle
    }
}
```

- [ ] **Step 3: 写发音条组件**

`SpeedTalk/Features/Today/PhraseAudioBar.swift`：

```swift
import SwiftUI
import SpeedTalkCore

struct PhraseAudioBar: View {
    let phrase: Phrase
    @State private var player = SpeechPlayer()

    var body: some View {
        HStack(spacing: 10) {
            ForEach(SpeechPlayer.Speed.allCases, id: \.self) { speed in
                Button {
                    player.speak(phrase.en, speed: speed)
                } label: {
                    Label(speed.title, systemImage: "speaker.wave.2")
                        .font(.captionLabel)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.accent.opacity(0.12), in: Capsule())
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
            if player.isSpeaking {
                Button("停") { player.stop() }
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
```

- [ ] **Step 4: 在卡片中接入发音条**

在 `TodayView.actions` 上方的 `VStack` 中，`PhraseCardView` 之后插入：

```swift
PhraseAudioBar(phrase: phrase)
```

- [ ] **Step 5: 编译验证**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -20
```
Expected: `** BUILD SUCCEEDED **`。若报 `AVAudioApplication` 不可用，改用 `AVAudioSession.sharedInstance().requestRecordPermission`

- [ ] **Step 6: 提交**

```bash
git add -A
git commit -m "feat(app): add speech playback, recording and recognition"
```

---

### Task 9: 跟读评分闭环与打卡

**Files:**
- Create: `SpeedTalk/Features/Practice/PracticeViewModel.swift`
- Create: `SpeedTalk/Features/Practice/PracticeView.swift`
- Create: `SpeedTalk/Features/Practice/ScoreResultView.swift`
- Create: `SpeedTalk/Features/Practice/WordHighlightView.swift`
- Create: `SpeedTalk/Core/Persistence/ProgressStore.swift`
- Modify: `SpeedTalk/Features/Today/TodayView.swift`（入口改为进入练习）

**Interfaces:**
- Consumes: `LocalScorer`、`SpeechRecognizer`、`PhraseProgress`、`DailyLog`、`ProgressEngine`、`ReviewScheduler`、`StreakCalculator`
- Produces:
  - `@MainActor @Observable final class PracticeViewModel`（`phase: Phase`、`report: ScoreReport?`、`beginRecording()`、`endRecording()`、`submitManual(_ text: String)`）
  - `ProgressStore`（`recordAttempt(phrase:score:transcript:duration:profile:context:)`、`checkInIfNeeded(...)`、`advanceDayIfNeeded(...)`）
  - `ScoreResultView(report:onRetry:onNext:)`、`WordHighlightView(alignments:)`

- [ ] **Step 1: 写 `ProgressStore`**

`SpeedTalk/Core/Persistence/ProgressStore.swift`：

```swift
import Foundation
import SwiftData
import SpeedTalkCore

@MainActor
final class ProgressStore {
    private let context: ModelContext
    private let reviewScheduler = ReviewScheduler()

    init(context: ModelContext) {
        self.context = context
    }

    func phraseProgress(id: String) -> PhraseProgress {
        let descriptor = FetchDescriptor<PhraseProgress>(predicate: #Predicate { $0.phraseID == id })
        if let existing = try? context.fetch(descriptor).first { return existing }
        let created = PhraseProgress(phraseID: id)
        context.insert(created)
        return created
    }

    func recordAttempt(
        phraseID: String,
        score: Int,
        transcript: String,
        duration: Double,
        profile: UserProfile,
        now: Date = .now
    ) {
        let progress = phraseProgress(id: phraseID)
        progress.attemptCount += 1
        progress.bestScore = max(progress.bestScore, score)
        progress.lastTranscript = transcript
        progress.lastReviewedAt = now
        if score >= 80 {
            progress.masteryLevel = min(progress.masteryLevel + 1, 5)
        } else if score < 60 {
            progress.masteryLevel = max(progress.masteryLevel - 1, 0)
        }
        let outcome = reviewScheduler.next(level: progress.masteryLevel, score: score, from: now, calendar: .current)
        progress.nextReviewAt = outcome.nextReviewAt

        let newStreak = StreakCalculator.nextStreak(
            current: profile.streak,
            lastStudyDate: profile.lastStudyDate,
            now: now,
            calendar: .current
        )
        profile.streak = newStreak
        profile.longestStreak = max(profile.longestStreak, newStreak)
        profile.lastStudyDate = now
        try? context.save()
    }

    func logDayCompletion(plan: String, stage: String, day: Int, completedCount: Int, totalScore: Int, now: Date = .now) {
        let key = Self.dateKey(now)
        let descriptor = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.dateKey == key })
        let log: DailyLog
        if let existing = try? context.fetch(descriptor).first {
            log = existing
        } else {
            log = DailyLog(dateKey: key, plan: plan, stage: stage, day: day)
            context.insert(log)
        }
        log.completedCount = completedCount
        log.totalScore = totalScore
        log.isCheckedIn = completedCount >= 5
        try? context.save()
    }

    static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
```

- [ ] **Step 2: 写练习视图模型**

`SpeedTalk/Features/Practice/PracticeViewModel.swift`：

```swift
import Foundation
import Observation
import SpeedTalkCore

@MainActor
@Observable
final class PracticeViewModel {
    enum Phase: Equatable {
        case idle
        case recording
        case scoring
        case result
        case manual
        case denied
        case unavailable
    }

    let phrase: Phrase
    private let recognizer = SpeechRecognizer()
    private(set) var phase: Phase = .idle
    private(set) var report: ScoreReport?
    private(set) var transcript: String = ""
    private(set) var errorMessage: String?

    init(phrase: Phrase) {
        self.phrase = phrase
    }

    func prepare() async {
        let granted = await recognizer.requestAuthorization()
        if !granted { phase = .denied }
    }

    func beginRecording() async {
        errorMessage = nil
        report = nil
        do {
            try recognizer.start()
            phase = .recording
        } catch {
            phase = recognizer.isAvailable ? .unavailable : .unavailable
            errorMessage = "识别没起来，检查麦克风权限后再试"
        }
    }

    func endRecording() {
        let text = recognizer.stop()
        transcript = text
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "没听清，靠近一点再来一次"
            phase = .idle
            return
        }
        let seconds = max(recognizer.elapsed, 0.6)
        report = LocalScorer.score(expected: phrase.en, actual: text, duration: seconds)
        phase = .result
    }

    func useManualInput(_ text: String) {
        transcript = text
        report = LocalScorer.score(expected: phrase.en, actual: text, duration: max(Double(text.split(separator: " ").count) / 2.8, 0.8))
        phase = .result
    }

    func reset() {
        report = nil
        phase = .idle
    }
}
```

- [ ] **Step 3: 写逐词高亮与结果页**

`SpeedTalk/Features/Practice/WordHighlightView.swift`：

```swift
import SwiftUI
import SpeedTalkCore

struct WordHighlightView: View {
    let alignments: [WordAlignment]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(alignments.enumerated()), id: \.offset) { _, alignment in
                switch alignment {
                case .matched(let word):
                    chip(word, color: Theme.positive, strikethrough: false)
                case .missing(let word):
                    chip(word, color: Theme.danger, strikethrough: true)
                case .extra(let word):
                    chip(word, color: .secondary, strikethrough: false)
                case .replaced(let expected, let actual):
                    chip("\(expected) → \(actual)", color: Theme.warning, strikethrough: false)
                }
            }
        }
    }

    private func chip(_ text: String, color: Color, strikethrough: Bool) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .strikethrough(strikethrough)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(color)
    }
}

/// 简单流式布局，避免引入第三方
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
```

`SpeedTalk/Features/Practice/ScoreResultView.swift`：

```swift
import SwiftUI
import SpeedTalkCore

struct ScoreResultView: View {
    let report: ScoreReport
    let onRetry: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(report.score)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.gradeColor(report.grade.rawValue))
                Text(report.grade.rawValue)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.gradeColor(report.grade.rawValue))
                Text(report.grade.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                metric("完整", report.completeness)
                metric("准确", report.accuracy)
                metric("流利", report.fluency)
            }

            WordHighlightView(alignments: report.alignments)

            HStack(spacing: 12) {
                Button("重说一遍", action: onRetry)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Button("下一句", action: onNext)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Theme.paper)
    }

    private func metric(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.captionLabel).foregroundStyle(.secondary)
            ProgressView(value: value)
                .tint(value > 0.8 ? Theme.positive : Theme.warning)
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 4: 写练习主视图（按住说话）**

`SpeedTalk/Features/Practice/PracticeView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct PracticeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var progressList: [PlanProgress]

    let phrase: Phrase
    let onFinished: (Int) -> Void

    @State private var vm: PracticeViewModel?
    @State private var manualText = ""
    @State private var showManual = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(phrase.en)
                    .font(.phraseSmall)
                    .fixedSize(horizontal: false, vertical: true)
                Text(phrase.zh).font(.subheadline).foregroundStyle(.secondary)
                PhraseAudioBar(phrase: phrase)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            if let report = vm?.report {
                ScrollView {
                    ScoreResultView(
                        report: report,
                        onRetry: { vm?.reset() },
                        onNext: {
                            if let score = vm?.report?.score {
                                save(score: score)
                            }
                            onFinished(report.score)
                        }
                    )
                }
            } else {
                Spacer()
                recordButton
                if let message = vm?.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Theme.danger)
                }
                Button("打不了字？用键盘跟读") { showManual = true }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(20)
        .background(Theme.paper.ignoresSafeArea())
        .navigationTitle("跟读")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showManual) {
            NavigationStack {
                Form {
                    TextField("把你说的写下来", text: $manualText, axis: .vertical)
                        .lineLimit(2...4)
                }
                .navigationTitle("键盘跟读")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("评分") {
                            vm?.useManualInput(manualText)
                            showManual = false
                        }
                    }
                }
            }
            .presentationDetents([.height(240)])
        }
        .task {
            if vm == nil { vm = PracticeViewModel(phrase: phrase) }
            await vm?.prepare()
        }
    }

    private var recordButton: some View {
        let recording = vm?.phase == .recording
        return Text(recording ? "松开结束" : "按住说")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(recording ? Theme.danger : Theme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard vm?.phase != .recording else { return }
                        Task { await vm?.beginRecording() }
                    }
                    .onEnded { _ in
                        vm?.endRecording()
                    }
            )
    }

    private func save(score: Int) {
        let store = ProgressStore(context: modelContext)
        let profile = profiles.first ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()
        store.recordAttempt(
            phraseID: phrase.id,
            score: score,
            transcript: vm?.transcript ?? "",
            duration: 0,
            profile: profile
        )
    }
}
```

- [ ] **Step 5: 今日页接入练习与打卡**

修改 `TodayView`，做四处改动：

1. 顶部加两个依赖与一个状态：

```swift
@Environment(\.modelContext) private var modelContext
@State private var completedScores: [Int] = []
```

2. 把 `actions(_:)` 整体替换为：

```swift
private func actions(_ vm: TodayViewModel) -> some View {
    HStack(spacing: 12) {
        NavigationLink {
            if let phrase = vm.current {
                PracticeView(phrase: phrase) { score in
                    completedScores.append(score)
                    let goal = profiles.first?.dailyGoal ?? 5
                    if completedScores.count >= goal { checkIn() }
                    withAnimation(.snappy) { vm.advance() }
                }
            }
        } label: {
            Label("按住说", systemImage: "mic.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)

        NavigationLink {
            if let phrase = vm.current { PhraseDetailView(phrase: phrase) }
        } label: {
            Label("详解", systemImage: "text.book.closed")
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(Theme.ink)
        }
        .buttonStyle(.plain)
    }
}
```

3. 在 `load()` 下方加入 `checkIn()`（加速档 10 句 = 一次推进 2 天）：

```swift
private func checkIn() {
    guard let profile = profiles.first else { return }
    let store = ProgressStore(context: modelContext)
    let plan = activePlan
    let stage = progress?.currentStage ?? "a"
    let day = progress?.currentDay ?? 1
    let average = completedScores.reduce(0, +) / max(completedScores.count, 1)
    store.logDayCompletion(
        plan: plan,
        stage: stage,
        day: day,
        completedCount: completedScores.count,
        totalScore: average
    )

    let target = progress ?? {
        let created = PlanProgress(planID: plan)
        modelContext.insert(created)
        return created
    }()

    let advanceTimes = max(1, profile.dailyGoal / 5)
    var snapshot = target.snapshot
    var finished = false
    for _ in 0..<advanceTimes where !finished {
        let result = container.engine.advance(snapshot)
        snapshot = result.snapshot
        finished = result.didFinishPlan
    }
    target.apply(snapshot)
    if finished {
        target.isCompleted = true
        target.finishedAt = .now
    }
    try? modelContext.save()
    completedScores = []
}
```

4. 完成态改成「够了就打卡，不够就再来一组」。把 `TodayView` 里 `else if let vm = viewModel, vm.isFinished { ... }` 分支替换为：

```swift
} else if let vm = viewModel, vm.isFinished {
    let goal = profiles.first?.dailyGoal ?? 5
    VStack(spacing: 14) {
        EmptyStateView(
            title: completedScores.count >= goal ? "今天学完了" : "第 1 组完成",
            message: completedScores.count >= goal
                ? "打卡完成，明天再来一组"
                : "还差 \(goal - completedScores.count) 句，再来一组就打卡"
        )
        if completedScores.count < goal {
            PrimaryButton(title: "再学一组") {
                let next = container.engine
                    .advance(progress?.snapshot ?? .initial(planID: activePlan))
                    .snapshot
                withAnimation(.snappy) { vm.load(snapshot: next) }
            }
            .padding(.horizontal, 20)
        }
    }
}
```

> 说明：`checkIn()` 会按 `dailyGoal / 5` 次推进，所以学 2 组后进度一次前进 2 天，与「加速档 60 天/阶段」一致。

- [ ] **Step 6: 编译验证**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: 提交**

```bash
git add -A
git commit -m "feat(app): add practice scoring loop, streak and check-in"
```

---

### Task 10: 课表、方案切换与首次启动

**Files:**
- Create: `SpeedTalk/Features/Course/CourseView.swift`
- Create: `SpeedTalk/Features/Course/PlanDetailView.swift`
- Create: `SpeedTalk/Features/Course/StageListView.swift`
- Create: `SpeedTalk/Features/Onboarding/OnboardingView.swift`
- Modify: `SpeedTalk/App/RootView.swift`

**Interfaces:**
- Consumes: `Curriculum`、`PlanProgress`、`UserProfile`
- Produces:
  - `CourseView`（三方案卡片 + 进度 + 开始/继续）
  - `PlanDetailView(plan:)`（三阶段进度条）
  - `StageListView(plan:stage:)`（单元 → 天列表）
  - `OnboardingView`（3 步：欢迎 → 选方案 → 完成）

- [ ] **Step 1: 写课表主页**

`SpeedTalk/Features/Course/CourseView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct CourseView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [PlanProgress]
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(container.content.curriculum.plans) { plan in
                        planCard(plan)
                    }
                }
                .padding(20)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("课表")
        }
    }

    private func planCard(_ plan: Curriculum.Plan) -> some View {
        let progress = progressList.first { $0.planID == plan.id }
        let isActive = (profiles.first?.activePlan ?? "01") == plan.id
        return NavigationLink {
            PlanDetailView(plan: plan)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(plan.id).font(.captionLabel).foregroundStyle(.secondary)
                    Text(plan.title).font(.headline)
                    if isActive { TagChip(text: "在学") }
                    Spacer()
                    if progress?.isCompleted == true {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.positive)
                    }
                }
                Text(plan.subtitle).font(.subheadline).foregroundStyle(.secondary)
                ProgressView(value: Double(progress?.completedDays ?? 0), total: 120)
                    .tint(isActive ? Theme.accent : .secondary)
                Text(progressText(progress))
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func progressText(_ progress: PlanProgress?) -> String {
        guard let progress else { return "还没开始 · 每天 5 句" }
        if progress.isCompleted { return "已通关 1800 句" }
        return "\(progress.currentStage) 阶段 · Day \(progress.currentDay) · 已完成 \(progress.completedDays) 天"
    }
}
```

- [ ] **Step 2: 写方案详情与阶段列表**

`SpeedTalk/Features/Course/PlanDetailView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct PlanDetailView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [PlanProgress]
    @Query private var profiles: [UserProfile]

    let plan: Curriculum.Plan

    var body: some View {
        List {
            Section("三个阶段") {
                ForEach(plan.stages) { stage in
                    NavigationLink {
                        StageListView(plan: plan, stage: stage)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(stage.id.uppercased()) · \(stage.title)").font(.headline)
                            Text("\(stage.days.count) 天 · \(stage.days.count * 5) 句")
                                .font(.captionLabel)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section {
                Button(action: setActive) {
                    Text(isActive ? "当前在学" : "设为当前方案")
                        .frame(maxWidth: .infinity)
                }
                .disabled(isActive)
            }
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isActive: Bool { (profiles.first?.activePlan ?? "01") == plan.id }

    private func setActive() {
        let profile = profiles.first ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()
        profile.activePlan = plan.id
        if progressList.first(where: { $0.planID == plan.id }) == nil {
            modelContext.insert(PlanProgress(planID: plan.id))
        }
        try? modelContext.save()
    }
}
```

`SpeedTalk/Features/Course/StageListView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct StageListView: View {
    @Environment(AppContainer.self) private var container
    let plan: Curriculum.Plan
    let stage: Curriculum.Plan.Stage

    @Query private var progressList: [PlanProgress]

    private var progress: PlanProgress? { progressList.first { $0.planID == plan.id } }

    var body: some View {
        List {
            ForEach(stage.units, id: \.index) { unit in
                Section("\(unit.index). \(unit.title)") {
                    ForEach(unit.days) { day in
                        NavigationLink {
                            DayDetailView(phraseIDs: day.phraseIDs, title: day.title)
                        } label: {
                            HStack {
                                Text("Day \(day.day)").font(.captionLabel).foregroundStyle(.secondary).frame(width: 58, alignment: .leading)
                                Text(day.title).font(.subheadline)
                                Spacer()
                                if isCompleted(day.day) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.positive)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("\(stage.id.uppercased()) 阶段")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isCompleted(_ day: Int) -> Bool {
        guard let progress, progress.currentStage == stage.id else { return false }
        return day < progress.currentDay
    }
}

struct DayDetailView: View {
    @Environment(AppContainer.self) private var container
    let phraseIDs: [String]
    let title: String

    var body: some View {
        List {
            ForEach(phraseIDs.compactMap { container.content.library.phrase(id: $0) }) { phrase in
                NavigationLink {
                    PhraseDetailScreen(phrase: phrase)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phrase.en).font(.subheadline.weight(.medium))
                        Text(phrase.zh).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

- [ ] **Step 3: 写首次启动**

`SpeedTalk/Features/Onboarding/OnboardingView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct OnboardingView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var selectedPlan: String = "01"
    @State private var step: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if step == 0 {
                Text("每天 5 句").font(.system(size: 34, weight: .bold, design: .rounded))
                Text("3 分钟，把地道美语练成肌肉记忆。").foregroundStyle(.secondary)
                Spacer()
                PrimaryButton(title: "选方案") { step = 1 }
            } else {
                Text("选一个方案开始").font(.system(size: 28, weight: .bold, design: .rounded))
                Text("三个方案各 1800 句，随时可切换，进度各自保留。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(container.content.curriculum.plans) { plan in
                    Button {
                        selectedPlan = plan.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(plan.id) · \(plan.title)").font(.headline)
                                Text(plan.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: selectedPlan == plan.id ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(selectedPlan == plan.id ? Theme.accent : .secondary)
                        }
                        .padding(16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                PrimaryButton(title: "开始第一天", action: start)
            }
        }
        .padding(24)
        .background(Theme.paper.ignoresSafeArea())
    }

    private func start() {
        let profile = profiles.first ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()
        profile.activePlan = selectedPlan
        profile.hasOnboarded = true
        if (try? modelContext.fetch(FetchDescriptor<PlanProgress>()).first { $0.planID == selectedPlan }) == nil {
            modelContext.insert(PlanProgress(planID: selectedPlan))
        }
        try? modelContext.save()
    }
}
```

- [ ] **Step 4: 替换 Tab 占位**

`RootView` 的 `ContentView` 中，课表 Tab 替换为 `CourseView()`：

```swift
CourseView()
    .tabItem { Label("课表", systemImage: "list.bullet.rectangle") }
```

- [ ] **Step 5: 编译验证**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: 提交**

```bash
git add -A
git commit -m "feat(app): add course navigation, plan switching and onboarding"
```

---

### Task 11: 场景库与收藏

**Files:**
- Create: `SpeedTalk/Features/Scenes/SceneGridView.swift`
- Create: `SpeedTalk/Features/Scenes/PhraseListView.swift`
- Create: `SpeedTalk/Features/Scenes/PhraseDetailScreen.swift`
- Modify: `SpeedTalk/App/RootView.swift`（场景 Tab）

**Interfaces:**
- Consumes: `PhraseLibrary.phrases(scene:)`、`search(_:)`、`PhraseProgress.isFavorite`
- Produces:
  - `SceneGridView`（8 分类宫格 + 搜索入口）
  - `PhraseListView(scene:searchText:)`（含收藏筛选）
  - `PhraseDetailScreen(phrase:)`（复用 `PhraseDetailView` + 收藏按钮）

- [ ] **Step 1: 写分类宫格**

`SpeedTalk/Features/Scenes/SceneGridView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct SceneGridView: View {
    @Environment(AppContainer.self) private var container
    @State private var searchText = ""

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Scene.allCases, id: \.self) { scene in
                        NavigationLink {
                            PhraseListView(scene: scene, searchText: "")
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: scene.symbol).font(.title3)
                                Text(scene.title).font(.headline)
                                Text("\(container.content.library.phrases(scene: scene).count) 句")
                                    .font(.captionLabel)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("场景")
            .searchable(text: $searchText, prompt: "搜英文、中文或标签")
            .overlay {
                if !searchText.isEmpty {
                    NavigationStack {
                        PhraseListView(scene: nil, searchText: searchText)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: 写句子列表与详情**

`SpeedTalk/Features/Scenes/PhraseListView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct PhraseListView: View {
    @Environment(AppContainer.self) private var container
    @Query private var progressList: [PhraseProgress]

    let scene: Scene?
    let searchText: String

    @State private var onlyFavorites = false

    private var phrases: [Phrase] {
        var base = !searchText.isEmpty
            ? container.content.library.search(searchText)
            : (scene.map { container.content.library.phrases(scene: $0) } ?? container.content.library.all)
        if onlyFavorites {
            let favoriteIDs = Set(progressList.filter(\.isFavorite).map(\.phraseID))
            base = base.filter { favoriteIDs.contains($0.id) }
        }
        return base
    }

    var body: some View {
        List {
            Toggle("只看收藏", isOn: $onlyFavorites)
            ForEach(phrases) { phrase in
                NavigationLink {
                    PhraseDetailScreen(phrase: phrase)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phrase.en).font(.subheadline.weight(.medium))
                        Text(phrase.zh).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(scene?.title ?? "搜索")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

`SpeedTalk/Features/Scenes/PhraseDetailScreen.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct PhraseDetailScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [PhraseProgress]

    let phrase: Phrase

    private var progress: PhraseProgress? { progressList.first { $0.phraseID == phrase.id } }

    var body: some View {
        VStack(spacing: 0) {
            PhraseDetailView(phrase: phrase)
            HStack(spacing: 12) {
                Button {
                    toggleFavorite()
                } label: {
                    Label(progress?.isFavorite == true ? "已收藏" : "收藏", systemImage: progress?.isFavorite == true ? "star.fill" : "star")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                NavigationLink {
                    PracticeView(phrase: phrase, onFinished: { _ in })
                } label: {
                    Text("练这一句")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleFavorite() {
        if let existing = progress {
            existing.isFavorite.toggle()
        } else {
            let created = PhraseProgress(phraseID: phrase.id)
            created.isFavorite = true
            modelContext.insert(created)
        }
        try? modelContext.save()
    }
}
```

- [ ] **Step 3: 替换场景 Tab**

`RootView` 中：

```swift
SceneGridView()
    .tabItem { Label("场景", systemImage: "square.grid.2x2") }
```

- [ ] **Step 4: 编译验证**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "feat(app): add scene library, search and favorites"
```

---

### Task 12: 我的页：进度、成就、复习队列

**Files:**
- Create: `SpeedTalk/Features/Progress/MeView.swift`
- Create: `SpeedTalk/Features/Progress/AchievementWall.swift`
- Create: `SpeedTalk/Features/Progress/ReviewQueueView.swift`
- Create: `Core/Sources/SpeedTalkCore/Achievements/AchievementCatalog.swift`
- Test: `Core/Tests/SpeedTalkCoreTests/AchievementTests.swift`
- Modify: `SpeedTalk/App/RootView.swift`

**Interfaces:**
- Consumes: `PhraseProgress`、`DailyLog`、`UserProfile`
- Produces:
  - `struct AchievementDefinition { id, title, detail, symbol }`、`AchievementCatalog.all`
  - `AchievementCatalog.unlocked(totalMastered:streak:masteredInPlan:finishedPlans:) -> [String]`
  - `ProgressView`、`AchievementWall`、`ReviewQueueView`

- [ ] **Step 1: 写失败测试**

`Core/Tests/SpeedTalkCoreTests/AchievementTests.swift`：

```swift
import Testing
@testable import SpeedTalkCore

@Test func firstCheckInUnlocksWelcome() {
    let ids = AchievementCatalog.unlocked(totalMastered: 0, streak: 1, finishedPlanCount: 0)
    #expect(ids.contains("first-checkin"))
}

@Test func twoHundredMasteredUnlocksCollector() {
    let ids = AchievementCatalog.unlocked(totalMastered: 200, streak: 3, finishedPlanCount: 0)
    #expect(ids.contains("mastered-200"))
}

@Test func finishingPlanUnlocksPlanBadge() {
    let ids = AchievementCatalog.unlocked(totalMastered: 1800, streak: 30, finishedPlanCount: 1)
    #expect(ids.contains("plan-finished"))
}

@Test func noStreakUnlocksNothing() {
    let ids = AchievementCatalog.unlocked(totalMastered: 0, streak: 0, finishedPlanCount: 0)
    #expect(ids.isEmpty)
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Core 2>&1 | tail -10`
Expected: 编译失败，`AchievementCatalog` 未定义

- [ ] **Step 3: 实现成就目录**

`Core/Sources/SpeedTalkCore/Achievements/AchievementCatalog.swift`：

```swift
import Foundation

public struct AchievementDefinition: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let symbol: String

    public init(id: String, title: String, detail: String, symbol: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
    }
}

public enum AchievementCatalog {
    public static let all: [AchievementDefinition] = [
        .init(id: "first-checkin", title: "第一天", detail: "完成第一次打卡", symbol: "flag"),
        .init(id: "streak-7", title: "一周不断", detail: "连续打卡 7 天", symbol: "flame"),
        .init(id: "streak-30", title: "一个月", detail: "连续打卡 30 天", symbol: "flame.fill"),
        .init(id: "streak-100", title: "百天", detail: "连续打卡 100 天", symbol: "crown"),
        .init(id: "mastered-100", title: "百句成口", detail: "掌握 100 句", symbol: "text.bubble"),
        .init(id: "mastered-200", title: "两百句", detail: "掌握 200 句", symbol: "text.bubble.fill"),
        .init(id: "mastered-500", title: "五百句", detail: "掌握 500 句", symbol: "books.vertical"),
        .init(id: "stage-finished", title: "阶段通关", detail: "完成一个 600 句阶段", symbol: "checkmark.seal"),
        .init(id: "plan-finished", title: "方案通关", detail: "完成一个 1800 句方案", symbol: "trophy")
    ]

    public static func unlocked(totalMastered: Int, streak: Int, finishedPlanCount: Int) -> [String] {
        var ids: [String] = []
        if streak >= 1 { ids.append("first-checkin") }
        if streak >= 7 { ids.append("streak-7") }
        if streak >= 30 { ids.append("streak-30") }
        if streak >= 100 { ids.append("streak-100") }
        if totalMastered >= 100 { ids.append("mastered-100") }
        if totalMastered >= 200 { ids.append("mastered-200") }
        if totalMastered >= 500 { ids.append("mastered-500") }
        if totalMastered >= 600 { ids.append("stage-finished") }
        if finishedPlanCount >= 1 { ids.append("plan-finished") }
        return ids
    }
}
```

- [ ] **Step 4: 跑测试直到全绿**

Run: `swift test --package-path Core 2>&1 | tail -10`
Expected: 全部通过

- [ ] **Step 5: 写我的页**

`SpeedTalk/Features/Progress/MeView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct MeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var planProgress: [PlanProgress]
    @Query private var phraseProgress: [PhraseProgress]
    @Query private var achievements: [AchievementRecord]

    private var mastered: Int { phraseProgress.filter { $0.masteryLevel >= 4 }.count }
    private var finishedPlans: Int { planProgress.filter(\.isCompleted).count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 18) {
                        stat("\(profiles.first?.streak ?? 0)", "连续打卡")
                        stat("\(mastered)", "已掌握")
                        stat("\(planProgress.reduce(0) { $0 + $1.completedDays })", "学习天")
                    }
                    .padding(.vertical, 6)
                }

                Section("方案进度") {
                    ForEach(planProgress.sorted { $0.planID < $1.planID }) { progress in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(progress.planID) · \(container.content.curriculum.plan(id: progress.planID)?.title ?? "")")
                                Spacer()
                                Text(progress.isCompleted ? "已通关" : "\(progress.currentStage) · Day \(progress.currentDay)")
                                    .font(.captionLabel)
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: Double(progress.completedDays), total: 120)
                                .tint(Theme.accent)
                        }
                    }
                }

                Section("复习") {
                    NavigationLink {
                        ReviewQueueView()
                    } label: {
                        Label("到期复习 \(dueCount) 句", systemImage: "arrow.clockwise")
                    }
                }

                Section("成就") {
                    AchievementWall()
                }

                Section {
                    NavigationLink("设置") { SettingsView() }
                    NavigationLink("隐私说明") { PrivacyView() }
                }
            }
            .navigationTitle("我的")
            .task { refreshAchievements() }
        }
    }

    private var dueCount: Int {
        phraseProgress.filter { ($0.nextReviewAt ?? .distantPast) <= .now }.count
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 26, weight: .bold, design: .rounded))
            Text(label).font(.captionLabel).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func refreshAchievements() {
        let unlocked = Set(AchievementCatalog.unlocked(
            totalMastered: mastered,
            streak: profiles.first?.streak ?? 0,
            finishedPlanCount: finishedPlans
        ))
        let existing = Set(achievements.map(\.achievementID))
        for id in unlocked.subtracting(existing) {
            modelContext.insert(AchievementRecord(achievementID: id))
        }
        try? modelContext.save()
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("录音只用在本机评分").font(.headline)
                Text("跟读录音仅存放在临时目录，评分完成后立即删除，不会上传。")
                Text("发给 AI 的只有文字").font(.headline)
                Text("AI 纠音与对练只发送句子文本和你说的文字，不发送音频。")
                Text("API Key 存在钥匙串").font(.headline)
                Text("Key 只保存在系统钥匙串，不写入日志、不随备份上传。")
            }
            .font(.subheadline)
            .padding(20)
        }
        .navigationTitle("隐私说明")
    }
}
```

`SpeedTalk/Features/Progress/AchievementWall.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct AchievementWall: View {
    @Query private var records: [AchievementRecord]

    private var unlockedIDs: Set<String> { Set(records.map(\.achievementID)) }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AchievementCatalog.all) { definition in
                    let unlocked = unlockedIDs.contains(definition.id)
                    VStack(spacing: 6) {
                        Image(systemName: definition.symbol)
                            .font(.title3)
                            .foregroundStyle(unlocked ? Theme.accent : Color.secondary.opacity(0.4))
                        Text(definition.title)
                            .font(.captionLabel)
                            .foregroundStyle(unlocked ? Theme.ink : .secondary)
                        Text(definition.detail)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 86, height: 96)
                    .background(unlocked ? Theme.accent.opacity(0.08) : Theme.ink.opacity(0.03),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.vertical, 4)
        }
    }
}
```

`SpeedTalk/Features/Progress/ReviewQueueView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct ReviewQueueView: View {
    @Environment(AppContainer.self) private var container
    @Query private var progressList: [PhraseProgress]

    private var duePhrases: [Phrase] {
        progressList
            .filter { ($0.nextReviewAt ?? .distantPast) <= .now }
            .sorted { $0.nextReviewAt ?? .distantPast < $1.nextReviewAt ?? .distantPast }
            .prefix(5)
            .compactMap { container.content.library.phrase(id: $0.phraseID) }
    }

    var body: some View {
        List {
            if duePhrases.isEmpty {
                Text("今天没有到期复习，去学新句子。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(duePhrases) { phrase in
                    NavigationLink {
                        PracticeView(phrase: phrase, onFinished: { _ in })
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phrase.en).font(.subheadline.weight(.medium))
                            Text(phrase.zh).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("复习")
    }
}
```

- [ ] **Step 6: 建 `SettingsView` 占位文件（Task 13 原文件替换）**

`ProgressView` 引用了 `SettingsView`，本 Task 先给出可编译的占位，避免跨 Task 编译失败：

`SpeedTalk/Features/Settings/SettingsView.swift`：

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("学习") {
                Text("每天 5 句，3 分钟")
            }
        }
        .navigationTitle("设置")
    }
}
```

- [ ] **Step 7: 替换我的 Tab**

`RootView` 中：

```swift
MeView()
    .tabItem { Label("我的", systemImage: "person.crop.circle") }
```

- [ ] **Step 8: 编译验证**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: 提交**

```bash
git add -A
git commit -m "feat(app): add progress, achievements and review queue"
```

---

### Task 13: 设置与每日提醒

**Files:**
- Create: `SpeedTalk/Features/Settings/SettingsView.swift`
- Create: `SpeedTalk/Features/Settings/NotificationSettingsView.swift`
- Create: `SpeedTalk/Core/Notifications/ReminderScheduler.swift`
- Modify: `SpeedTalk/App/SpeedTalkApp.swift`（启动时请求通知权限）

**Interfaces:**
- Consumes: `UserProfile`
- Produces: `SettingsView`（每日目标、语速、提醒时间、AI 占位入口）、`ReminderScheduler.schedule(hour:)`

- [ ] **Step 1: 写提醒调度**

`SpeedTalk/Core/Notifications/ReminderScheduler.swift`：

```swift
import Foundation
import UserNotifications

struct ReminderScheduler {
    static let identifier = "daily-practice"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func schedule(hour: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "今天 5 句"
        content.body = "3 分钟，把昨天那几句练顺。"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
```

- [ ] **Step 2: 写设置页**

`SpeedTalk/Features/Settings/SettingsView.swift`：

```swift
import SwiftUI
import SwiftData
import SpeedTalkCore

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Form {
            Section("学习") {
                Picker("每天", selection: goalBinding) {
                    Text("5 句 · 3 分钟").tag(5)
                    Text("10 句 · 加速档").tag(10)
                }
                VStack(alignment: .leading) {
                    Text("示范语速")
                    Slider(value: speechRateBinding, in: 0.38...0.55, step: 0.01)
                }
            }

            Section("提醒") {
                NavigationLink("每日提醒") { NotificationSettingsView() }
            }

            Section("AI") {
                Text("AI 纠音与对练在下一步接入，先填好 Key 即可用。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("数据") {
                Text("录音不保存，学习记录只在本机。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
    }

    private var goalBinding: Binding<Int> {
        Binding(
            get: { profile?.dailyGoal ?? 5 },
            set: { profile?.dailyGoal = $0; try? modelContext.save() }
        )
    }

    private var speechRateBinding: Binding<Double> {
        Binding(
            get: { profile?.speechRate ?? 0.48 },
            set: { profile?.speechRate = $0; try? modelContext.save() }
        )
    }
}
```

`SpeedTalk/Features/Settings/NotificationSettingsView.swift`：

```swift
import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Form {
            Picker("提醒时间", selection: hourBinding) {
                ForEach(7...23, id: \.self) { hour in
                    Text("\(hour):00").tag(hour)
                }
            }
            Button("开启提醒") {
                Task {
                    let granted = await ReminderScheduler.requestAuthorization()
                    if granted { await ReminderScheduler.schedule(hour: profiles.first?.reminderHour ?? 20) }
                }
            }
            Button("关闭提醒", role: .destructive) {
                ReminderScheduler.cancel()
            }
        }
        .navigationTitle("每日提醒")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hourBinding: Binding<Int> {
        Binding(
            get: { profiles.first?.reminderHour ?? 20 },
            set: { newValue in
                profiles.first?.reminderHour = newValue
                try? modelContext.save()
                Task { await ReminderScheduler.schedule(hour: newValue) }
            }
        )
    }
}
```

- [ ] **Step 3: 编译验证**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -20
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 提交**

```bash
git add -A
git commit -m "feat(app): add settings and daily reminder"
```

---

### Task 14: 语料补齐至 600 句并全链路自检

**Files:**
- Modify: `Core/Sources/SpeedTalkCore/Resources/phrases.json`
- Modify: `Core/Sources/SpeedTalkCore/Resources/curriculum.json`
- Modify: `Core/Tests/SpeedTalkCoreTests/ContentTests.swift`

**Interfaces:**
- Consumes: Task 3/4 的 Schema
- Produces: 完整可用的 `01-a` 600 句内容

- [ ] **Step 1: 补齐剩余单元（若 Task 4 已一次做完则跳过）**

按 Task 4 的单元主题表，把 Unit 2（Day 31–60）、Unit 3（Day 61–90）、Unit 4（Day 91–120）各 150 句写入 `phrases.json`，并同步 `curriculum.json` 的四个 unit 分组。

- [ ] **Step 2: 恢复严格校验断言**

```swift
@Test func bundledCurriculumIsFullyValid() throws {
    let bundle = try ContentLoader.loadBundled()
    let issues = CurriculumService(curriculum: bundle.curriculum, library: bundle.library).validate()
    #expect(issues.isEmpty, "课纲校验问题：\(issues.joined(separator: "; "))")
}
```

- [ ] **Step 3: 跑全部测试**

Run: `swift test --package-path Core 2>&1 | tail -30`
Expected: 全部通过，无 validation issues

- [ ] **Step 4: 编译 App 并核对包体积**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | head -10
du -h Core/Sources/SpeedTalkCore/Resources/phrases.json
```
Expected: `** BUILD SUCCEEDED **`；phrases.json 体积 < 3MB

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "content: complete 600 phrases and 120-day curriculum for plan 01 stage a"
```

---

### Task 15: 验收

**Files:** 无新增（只做验证与修补）

- [ ] **Step 1: 逻辑层全量测试**

Run: `swift test --package-path Core 2>&1 | tail -15`
Expected: 全部通过

- [ ] **Step 2: App 编译**

Run:
```bash
xcodegen generate && xcodebuild -project SpeedTalk.xcodeproj -scheme SpeedTalk -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "warning:|error:|BUILD" | head -30
```
Expected: `** BUILD SUCCEEDED **`，无 error

- [ ] **Step 3: 冒烟清单（需安装模拟器运行时）**

如需在模拟器验证，先执行：

```bash
xcodebuild -downloadPlatform iOS
xcrun simctl boot "iPhone 17 Pro" || true
```

逐项手动核对：

1. 首次启动 → 选方案 01 → 进入今日，显示 Day 1 与 5 句
2. 点「慢速 / 常速」能听到示范音
3. 进入跟读 → 按住说 → 松开 → 出分与逐词高亮
4. 5 句完成后 → 打卡成功 → 课表 Day 1 打勾、Day 前进
5. 切换到方案 02 → 今日显示 Day 1；切回 01 → 回到原进度
6. 场景 Tab 搜索 `coffee` 与 `咖啡` 均有结果
7. 收藏一句 → 「只看收藏」能筛出
8. 我的页 streak / 已掌握 / 成就正常
9. 设置改 10 句加速档 → 今日显示 10 句

- [ ] **Step 4: 记录遗留问题**

把发现的缺陷写入 `docs/superpowers/plans/known-issues.md`，标注严重级别与复现步骤。

- [ ] **Step 5: 最终提交**

```bash
git add -A
git commit -m "chore: core learning loop acceptance"
```

---

## 后续计划（不在本计划范围）

`docs/superpowers/plans/2026-11-04-speedtalk-ai.md` 覆盖 M4–M5：AI 纠音、AI 场景对练、Keychain、配额、iPad 适配、上架素材。本计划完成后另起一份。
