import SwiftUI
import CloudKit
import XLog

struct ICloudSyncSettingsView: View {
    @EnvironmentObject var config: Config
    @Environment(DataContainer.self) var dataContainer
    @State private var showAudioWarning = false
    @State private var showNotSignedInAlert = false

    var body: some View {
        Form {
            Section {
                Toggle(L(.icloud_sync), isOn: Binding(
                    get: { config.icloudSyncEnabled },
                    set: { newValue in
                        if newValue {
                            checkICloudAvailability { available in
                                if available {
                                    config.icloudSyncEnabled = true
                                    dataContainer.reconfigureForCloudSync(enabled: true)
                                } else {
                                    showNotSignedInAlert = true
                                }
                            }
                        } else {
                            config.icloudSyncEnabled = false
                            config.icloudSyncAudio = false
                            dataContainer.reconfigureForCloudSync(enabled: false)
                        }
                    }
                ))

                if config.icloudSyncEnabled {
                    Toggle(L(.icloud_sync_audio), isOn: Binding(
                        get: { config.icloudSyncAudio },
                        set: { newValue in
                            if newValue {
                                showAudioWarning = true
                            } else {
                                config.icloudSyncAudio = false
                            }
                        }
                    ))
                }
            } header: {
                Text(L(.icloud_sync))
            }

            if config.icloudSyncEnabled {
                Section {
                    syncStatusRow
                }
            }
        }
        .navigationTitle(L(.icloud_sync))
        .alert(L(.icloud_sync_audio), isPresented: $showAudioWarning) {
            Button(L(.cancel), role: .cancel) {}
            Button(L(.confirm)) {
                config.icloudSyncAudio = true
            }
        } message: {
            Text(L(.icloud_sync_audio_warning))
        }
        .alert(L(.icloud_sync), isPresented: $showNotSignedInAlert) {
            Button(L(.ok)) {}
        } message: {
            Text(L(.icloud_sync_not_signed_in))
        }
    }

    @ViewBuilder
    private var syncStatusRow: some View {
        switch dataContainer.syncStatus {
        case .idle:
            EmptyView()
        case .syncing:
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text(L(.icloud_sync_status_syncing))
                    .foregroundColor(.secondary)
            }
        case .succeeded(let date):
            HStack {
                Text(L(.icloud_sync_status_last_synced))
                Spacer()
                Text(date.formatted(.relative(presentation: .named)))
                    .foregroundColor(.secondary)
            }
        case .failed(let message):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(L(.icloud_sync_status_error))
                }
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func checkICloudAvailability(completion: @escaping (Bool) -> Void) {
        CKContainer(identifier: "iCloud.com.tangyue.murmurs").accountStatus { status, _ in
            DispatchQueue.main.async {
                completion(status == .available)
            }
        }
    }
}
