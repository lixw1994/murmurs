## Context

Timeline 当前以 `ScrollView > LazyVStack` 按 `MemoEntity.day`（`Int32`，格式 `yyyyMMdd`）分 section 展示。数据通过 `@Query` 全量获取，计算属性 `sections` 按 day 分组。`ScrollViewReader` 已存在但未使用。

`day` 字段受 `Config.dayStartTime` 影响（凌晨 2 点前的记录归属前一天），日历组件必须基于 `day` 字段而非 `createdAt` 来标记有数据的日期。

## Goals / Non-Goals

**Goals:**
- 在 Timeline 顶部提供可折叠的月历，标记有 memo 的日期
- 点击日期自动滚动列表到对应 section
- 保持纯原生 SwiftUI，无第三方依赖

**Non-Goals:**
- 不过滤列表内容（只导航，不隐藏）
- 不同步滚动位置到日历月份
- 不支持日期范围选择或周视图

## Decisions

### 1. 日历放在 ScrollView 外部，而非内部

日历作为固定区域放在 `VStack` 中 ScrollView 上方，而非 ScrollView 内的第一个元素。

**理由**：避免与纵向 ScrollView 的嵌套滚动冲突。日历展开时始终可见，方便反复点击不同日期导航。通过 toolbar 按钮控制显隐，不需要时完全不占空间。

**替代方案**：放在 ScrollView 内部作为第一个 section。问题：滚动后日历消失，需要滚回顶部才能再次使用，削弱了导航价值。

### 2. 从已有 `allMemos` 派生日历数据，而非独立查询

日历标记有 memo 的日期通过 `Set(allMemos.map { Int($0.day) })` 计算，复用 View 层已有的 `@Query` 数据。

**理由**：避免引入额外的 SwiftData 查询。`allMemos` 已经是全量数据，提取唯一 `day` 值的开销可忽略（1000 条 memo 也是微秒级）。数据源单一，保证日历标记与列表 section 天然一致。

### 3. 使用 `ScrollViewReader.scrollTo` 定位，给 section header 添加 `.id()`

`TimelineHeaderView` 添加 `.id(Int(section.day))` 修饰符，使 `ScrollViewReader` 能按 dayId 定位。

**理由**：`ScrollViewReader` 已存在于 `timelineList` 中但未使用，只需传出 proxy 引用。`.id()` 修饰符不影响现有渲染行为。

### 4. Toolbar 日历按钮与 quick memo 按钮合并在同一 ToolbarItem

用 `HStack` 将日历切换按钮和现有 quick memo 按钮组合在一个 `.navigationBarTrailing` 的 `ToolbarItem` 中。

**理由**：保持 trailing 区域紧凑。日历按钮使用 SF Symbol `calendar` / `calendar.circle.fill` 切换态，视觉清晰。

## Risks / Trade-offs

**[`scrollTo` 在极远距离可能抖动]** → 可接受。SwiftUI 的 `ScrollViewReader` 在 iOS 17 上对 `LazyVStack` 的支持基本可靠。极端情况（数千 memo、跨数百个 section）下可能有视觉抖动，但不影响功能。

**[日历展开占用约 280pt 垂直空间]** → 通过 toolbar 按钮折叠。默认折叠，不影响纯列表浏览习惯。

**[`@State scrollProxy` 生命周期]** → `onAppear` 时捕获 proxy。`timelineList` 重建时 `onAppear` 重新触发，proxy 自动更新。

**[多选模式下日历可见性]** → 保留日历可见但 toolbar 切换按钮在多选 toolbar 中不显示。日历状态不变，多选取消后恢复正常。

## Affected Files

| File | Change |
|------|--------|
| `Sources/Modules/Timeline/CalendarView.swift` | 新建：月历组件 |
| `Sources/Modules/Timeline/TimelineView.swift` | 修改：集成日历、toolbar 按钮、scrollTo 逻辑 |
