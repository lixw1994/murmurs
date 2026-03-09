import Foundation


extension Notification.Name {
    static let receivedFileFromWatch = Notification.Name("received_file_from_watch")
    static let recordingSentToIphone = Notification.Name("recording_sent_to_iphone")
    static let connectivityIsActive  = Notification.Name("connectivity_is_active")
    static let memoInserted          = Notification.Name("memo_inserted")
    static let memoAppendRecording   = Notification.Name("memo_append_recording")

    #if os(iOS)
    static let togglePauseRecording  = Notification.Name("toggle_pause_recording")
    static let stopRecording         = Notification.Name("stop_recording")
    #endif
}
