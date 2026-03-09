#if os(iOS)
import ActivityKit
import SwiftUI
import WidgetKit

struct RecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            // Lock Screen banner (minimal)
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.center) {
                    expandedView(context: context)
                }
            } compactLeading: {
                Image(systemName: context.state.isFinished ? "checkmark.circle.fill" : "mic.fill")
                    .foregroundStyle(context.state.isFinished ? .green : .red)
            } compactTrailing: {
                if context.state.isFinished {
                    Text("Saved")
                        .font(.system(.caption))
                        .foregroundStyle(.green)
                } else {
                    Text(formatTime(context.state.recordedTime))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(context.state.isPaused ? .secondary : .primary)
                }
            } minimal: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "mic.fill")
                    .foregroundStyle(.red)
            }
            .widgetURL(URL(string: "murmurs://record"))
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        HStack {
            if context.state.isFinished {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else {
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "mic.circle.fill")
                    .font(.title2)
                    .foregroundStyle(context.state.isPaused ? .orange : .red)
            }

            VStack(alignment: .leading) {
                Text("Murmurs")
                    .font(.headline)
                if context.state.isFinished {
                    Text("Recording saved")
                        .font(.body)
                        .foregroundStyle(.green)
                } else {
                    Text(formatTime(context.state.recordedTime))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !context.state.isFinished {
                if context.attributes.canPause {
                    Button(intent: TogglePauseRecordingIntent()) {
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                    }
                    .tint(context.state.isPaused ? .green : .orange)
                }

                Button(intent: StopRecordingIntent()) {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                }
                .tint(.red)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func expandedView(context: ActivityViewContext<RecordingActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            if context.state.isFinished {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)

                Text("Recording saved")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else {
                HStack(spacing: 8) {
                    Circle()
                        .fill(context.state.isPaused ? .orange : .red)
                        .frame(width: 10, height: 10)

                    Text(context.state.isPaused ? "Paused" : "Recording")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(formatTime(context.state.recordedTime))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))

                HStack(spacing: 20) {
                    if context.attributes.canPause {
                        Button(intent: TogglePauseRecordingIntent()) {
                            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                        .tint(context.state.isPaused ? .green : .orange)
                    }

                    Button(intent: StopRecordingIntent()) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .tint(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
#endif
