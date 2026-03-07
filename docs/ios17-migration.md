# iOS 17+ 迁移计划

## 背景

项目部署目标已升级到 iOS 17.0 / watchOS 10.0。以下记录各阶段迁移计划和完成状态。

以下按**风险从低到高**、**收益从快到慢**分为四个阶段。

---

## Phase 0: 提升部署目标 ✅ 已完成

`project.yml` 中所有 6 个 target 的部署目标已更新：iOS 16.0 → 17.0，watchOS 9.0 → 10.0。

前置评估：
- 检查 App Store Connect 中 iOS 16 用户占比，确认可接受
- watchOS 10 对应 Apple Watch Series 4+，覆盖面足够

---

## Phase 1: 低风险语法升级 ✅ 已完成

41 个 `PreviewProvider` 已迁移为 `#Preview` 宏，13 个 `onChange` 处理器已升级为 iOS 17 新语法。

### 1.1 `#Preview` 宏替代 `PreviewProvider`

影响 30+ 文件。

```swift
// Before (iOS 16)
#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
#endif

// After (iOS 17+)
#Preview {
    MainView()
}
```

### 1.2 `onChange` 新语法

影响约 10 文件。

```swift
// Before (iOS 16)
.onChange(of: vm.saved) { newValue in
    if newValue { dismiss() }
}

// After (iOS 17+)
.onChange(of: vm.saved) { oldValue, newValue in
    if newValue { dismiss() }
}
```

涉及文件：
- `Sources/Modules/Recording/RecordingView.swift`
- `Sources/Modules/Recording/RecordingCompletedView.swift`
- `Sources/Modules/Settings/SettingsView.swift`
- `Sources/Modules/Premium/PremiumView.swift`
- `Sources/Modules/Summary/AddSummaryPromptView.swift`
- 以及 Watch 端若干文件

---

## Phase 2: @Observable 替代 ObservableObject ✅ 已完成

已迁移 12 个类，更新 20+ 个视图文件。

### 已迁移的类

**ViewModel（7 个）：**
- `QuickMemoViewModel` — 1 @Published
- `ExportViewModel` — 6 @Published, 2 didSet
- `RecordingCompletedViewModel` — 8 @Published, 1 didSet
- `TimelineViewModel` — 9 @Published, 1 didSet, @objc methods, @AppStorage（用 `@ObservationIgnored` 排除）
- `EditPromptViewModel` — Combine pipeline → computed property
- `AddSummaryViewModel` — 2 Combine pipelines → computed property + didSet
- `ServerSettingsViewModel` — 2 Combine pipelines → computed property + didSet

**全局状态（5 个）：**
- `AppState` — 6 @Published, 2 didSet (language, isPremium)
- `WatchAppState` — 3 @Published
- `WatchViewModel` — 0 @Published, @objc methods
- `DataContainer` (iOS) — 0 @Published
- `DataContainer` (Watch) — 0 @Published

### 未迁移（技术限制）

- `Config` — `@AppStorage` 与 `@Observable` 不兼容
- `AudioPlayer` / `AudioRecorder` / `IAPManager` / `Connectivity` / `AppDelegate` — NSObject 子类，编译器不允许
- `MemoEntity` / `SummaryEntity` / `PromptEntity` — NSManagedObject 子类

### 关键模式

```swift
// ViewModel 层
@Observable final class MyViewModel {
    var property = ""           // 不再需要 @Published
    var computed: Bool { ... }  // 替代 Combine pipeline
    var tracked = "" {
        didSet { sideEffect() } // didSet 正常工作
    }
    @ObservationIgnored @AppStorage("key") var stored = ""  // @AppStorage 需要排除
}

// View 层
@State private var vm = MyViewModel()              // 替代 @StateObject
@Environment(AppState.self) var appState           // 替代 @EnvironmentObject
@Bindable var appState = appState                  // 需要 $ 绑定时使用

// 注入
.environment(migratedInstance)                     // 替代 .environmentObject()
.environmentObject(nonMigratedInstance)             // NSObject 子类保持不变
```

---

## Phase 3: SwiftData 替代 Core Data ✅ 已完成

已完成全部 5 个实体的 SwiftData 迁移，更新 30+ 文件，112 个测试全部通过。

### 迁移内容

**@Model 定义（5 个实体）：**
- `MemoEntity` — `@Attribute(originalName: "id") var entityId` 避免与 @Model 自动 Identifiable 冲突
- `SummaryEntity` — 非 optional 属性 + 默认值兼容已有数据库 nil 值
- `PromptEntity` / `UsageEntity` / `RecordingEntity`（Watch）

**DataContainer 重写：**
- `ModelContainer` + `ModelContext` 替代 `NSPersistentContainer` + `NSManagedObjectContext`
- `nonisolated(unsafe) let context` 解决 `@MainActor` 隔离与默认参数表达式的冲突
- Store URL 指向已有 Core Data SQLite 文件（SwiftData 原地读取）

**View 层：**
- `@Query` 替代 `@FetchRequest` / `@SectionedFetchRequest`
- Timeline 分组：`@Query` + `Dictionary(grouping:by:)` computed property
- `@ObservedObject var entity` → 直接 `var entity`（@Model 自带 @Observable）
- `.modelContainer()` 替代 `.environment(\.managedObjectContext, ...)`

**ViewModel 层：**
- `ModelContext` 替代 `NSManagedObjectContext`
- `FetchDescriptor` + `#Predicate` 替代 `NSFetchRequest` + `NSPredicate(format:)`
- 自定义 `.memoInserted` 通知替代 `NSManagedObjectContextDidSave`

**清理：**
- 删除 5 个 `+Extension.swift` 文件和 2 个 `.xcdatamodeld` 目录
- 不再依赖 Core Data framework

---

## Phase 4: 其他 iOS 17+ 增强（可选）

优先级较低，按需采纳。

### 4.1 触觉反馈

```swift
// Before: UIKit 方式
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()

// After: SwiftUI 原生
Button("Delete") { ... }
    .sensoryFeedback(.impact(weight: .medium), trigger: deleteTrigger)
```

### 4.2 内容过渡动画

```swift
Text(count, format: .number)
    .contentTransition(.numericText())
```

### 4.3 ScrollView 增强

```swift
ScrollView {
    LazyVStack { ... }
        .scrollTargetLayout()
}
.scrollTargetBehavior(.viewAligned)
```

### 4.4 StoreKit 2 替代 StoreKit 1

当前使用 `SKPaymentQueue`（StoreKit 1），可迁移到 StoreKit 2 的 `Product` / `Transaction` API，代码量大幅减少。

---

## 总结

| 阶段 | 内容 | 工作量 | 风险 | 收益 |
|------|------|--------|------|------|
| **Phase 0** | 提升部署目标 | ✅ 已完成 | — | 前提条件 |
| **Phase 1** | #Preview + onChange 语法 | ✅ 已完成 | — | 代码整洁 |
| **Phase 2** | @Observable | ✅ 已完成 | — | 大幅减少样板、性能提升 |
| **Phase 3** | SwiftData | ✅ 已完成 | — | 架构简化、去除 XML schema |
| **Phase 4** | 触觉反馈等增强 | 按需 | 极低 | 体验优化 |

建议 Phase 1 → Phase 2 连续执行，Phase 3 作为独立迭代规划。
