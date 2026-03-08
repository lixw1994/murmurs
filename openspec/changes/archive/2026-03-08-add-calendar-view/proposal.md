## Why

随着录音条目增多，用户在纯时间线列表中难以快速定位到特定日期的笔记。需要一个日历视图让用户能直观地看到哪些天有记录，并一键跳转到对应日期。这是语音日记类产品的核心导航需求（GitHub Issue #33）。

## What Changes

- Timeline 顶部新增可折叠的月历组件，通过 toolbar 按钮切换显隐
- 月历中标记有 memo 的日期（小圆点），高亮今天
- 点击有 memo 的日期，自动滚动 timeline 到对应 section
- 月历支持左右箭头切换月份，星期标签和月份名称自动本地化

### Non-goals

- 不按日期过滤列表（只滚动，不隐藏其他日期内容）
- 不跟踪滚动位置同步日历月份
- 不引入第三方日历库
- 不支持日期范围选择

## Capabilities

### New Capabilities

- `calendar-navigation`: 月历组件及其与 Timeline 的交互（展示、日期标记、点击跳转）

### Modified Capabilities

（无已有 spec 的行为变更）

## Impact

- `Sources/Modules/Timeline/TimelineView.swift` — 布局变更，新增日历区域和 toolbar 按钮
- `Sources/Modules/Timeline/CalendarView.swift` — 新建月历组件
- 不涉及数据模型、持久化、网络层或外部依赖的变更
