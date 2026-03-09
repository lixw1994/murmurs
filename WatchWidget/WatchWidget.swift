import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date.distantFuture)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct WatchWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            #if os(watchOS)
            watch()
            #else
            ios()
            #endif
        }
        .widgetAccentable()
        .widgetURL(URL(string: "murmurs://record")!)
    }
    
    @ViewBuilder
    private func watch() -> some View {
        if family == .accessoryCircular {
            Image("logo-circular")
        } else {
            Image("logo-corner")
        }
    }
    
    @ViewBuilder
    private func ios() -> some View {
        Image("logo-circular-ios")
    }
}

struct MurmursStaticWidget: Widget {
    let kind: String = "main"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WatchWidgetEntryView(entry: entry)
        }
        #if os(watchOS)
        .configurationDisplayName("Murmurs")
        .description("")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
        #else
        .configurationDisplayName("Start Recording")
        .description("")
        .supportedFamilies([.accessoryCircular])
        #endif
    }
}

@main
struct MurmursWidgets: WidgetBundle {
    var body: some Widget {
        MurmursStaticWidget()
        #if os(iOS)
        RecordingLiveActivity()
        #endif
    }
}

#if os(watchOS)
#Preview(as: .accessoryCorner) {
    MurmursStaticWidget()
} timeline: {
    SimpleEntry(date: .now)
}
#else
#Preview(as: .accessoryCircular) {
    MurmursStaticWidget()
} timeline: {
    SimpleEntry(date: .now)
}
#endif
