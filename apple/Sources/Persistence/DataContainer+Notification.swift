import Foundation
import WatchConnectivity
import XLog

extension DataContainer {
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFileFromWatch), name: .receivedFileFromWatch, object: nil)
    }

    @objc func didReceiveFileFromWatch(_ notification: Notification) {
        guard let file = notification.object as? WCSessionFile else { return }
        let voiceURL = file.fileURL

        do {
            _ = try FileHelper.moveAudioFile(voiceURL)
        } catch {
            XLog.error(error, source: "DC")
            return
        }

        DispatchQueue.main.async {
            let memo = MemoEntity()
            memo.file = voiceURL.lastPathComponent
            memo.content = ""
            memo.transcribed = false
            memo.isFromWatch = true

            if let metadata = file.metadata {
                XLog.info(metadata, source: "DC")
                memo.timezone = (metadata["timezone"] as? String) ?? TimeZone.current.identifier
                memo.createdAt = (metadata["createdAt"] as? Date) ?? Date()
                memo.duration = (metadata["duration"] as? Double) ?? 0
            }

            self.context.insert(memo)
            do {
                try self.context.save()
                NotificationCenter.default.post(name: .memoInserted, object: memo)
            } catch {
                XLog.error(error, source: "DC")
            }
        }
    }
}
