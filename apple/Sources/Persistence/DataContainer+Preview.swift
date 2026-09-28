import Foundation

extension DataContainer {
    #if DEBUG
    func addPreviewData() {
        let items = [
            "Woke up, kind of a bummer",
            "Morning jog for 2 miles. My lungs, they're screaming! Rushed shower. Thought I saw a spider. It was just shampoo."
        ]
        for item in items {
            let m = MemoEntity()
            m.content = item
            m.day = Int32(DateHelper.todayIdentifier())
            m.timezone = "Asia/Tokyo"
            m.createdAt = Date()
            context.insert(m)
        }
        try! context.save()
    }
    #endif
}
