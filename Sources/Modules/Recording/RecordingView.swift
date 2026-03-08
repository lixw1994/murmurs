import SwiftUI
import DSWaveformImage
import DSWaveformImageViews

struct RecordingView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) var dismiss
    @StateObject var recorder = AudioRecorder()
    @State var vm = RecordingViewModel()
    var appendTo: MemoEntity?

    @State var configuration: Waveform.Configuration = .init(
        style: .striped(.init(color: .label.withAlphaComponent(0.5), width: 3, spacing: 3))
    )

    @State private var detents: Set<PresentationDetent> = [.medium]
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var liveTranscriptionResult: String?

    var body: some View {
        ZStack {
            if recorder.isRecording {
                VStack(spacing: 0) {
                    closeButton

                    Spacer()

                    RecordingStatusView(isPaused: recorder.isPaused)

                    recordedTimeLabel
                        .padding(.top, 20)

                    if vm.isLiveTranscribing && !vm.liveTranscriptionText.isEmpty {
                        liveTranscriptionView
                    }

                    Spacer()

                    WaveformLiveCanvas(samples: recorder.samples, configuration: configuration)
                        .frame(height: 50)
                        .padding(.horizontal)
                        .padding(.bottom, 30)

                    HStack(spacing: 30) {
                        if recorder.canPause {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                if recorder.isPaused {
                                    recorder.resumeRecording()
                                } else {
                                    recorder.pauseRecording()
                                }
                            } label: {
                                Image(systemName: recorder.isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color(uiColor: .tertiaryLabel).opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }

                        StopRecordingButton {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            Task {
                                liveTranscriptionResult = await vm.stopLiveTranscription()
                                recorder.stopRecording()
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            } else if recorder.isCompleted {
                RecordingCompletedView(
                    voiceURL: recorder.voiceFile!,
                    preTranscribedText: liveTranscriptionResult,
                    appendTo: appendTo
                )
                .opacity(Config.shared.autoSave && liveTranscriptionResult == nil && appendTo == nil ? 0 : 1)
            } else {
                ProgressView()
            }
        }
        .presentationDetents(detents, selection: $selectedDetent)
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
        .task {
            vm.configureRecorder(recorder)
            await AudioRecorder.awaitPrewarm()
            recorder.startRecording()
        }
        .onChange(of: appState.micPermission) { oldValue, newValue in
            if newValue == .denied {
                dismiss()
            }
        }
        .onChange(of: recorder.isRecording) { oldValue, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
            if newValue && vm.shouldUseLiveTranscription {
                vm.startLiveTranscription()
            }
        }
        .onChange(of: recorder.isCompleted) { oldValue, newValue in
            if newValue {
                detents = [.large]
                selectedDetent = .large
            }
        }
    }

    @ViewBuilder
    var liveTranscriptionView: some View {
        ScrollView {
            Text(vm.liveTranscriptionText)
                .font(.body)
                .foregroundColor(.primary.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
        .frame(maxHeight: 120)
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.2), value: vm.liveTranscriptionText)
    }

    @ViewBuilder
    var recordedTimeLabel: some View {
        Text(recorder.formattedTime)
            .font(.system(size: 50, weight: .bold, design: .monospaced))
    }

    @ViewBuilder
    var closeButton: some View {
        HStack {
            Spacer()
            FeedbackButton {
                Task {
                    _ = await vm.stopLiveTranscription()
                }
                recorder.terminate()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
            }
            .foregroundColor(Color(uiColor: .tertiaryLabel))
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}


struct StopRecordingButton: View {
    @State private var recording = false
    var action: () -> Void
    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button (action: action) {
            Image(systemName: "stop.fill")
                .font(.system(size: 30))
                .foregroundColor(.red)
                .padding()
                .background(.white)
                .clipShape(Circle())
        }
        .padding(8)
        .background(
            Color(uiColor: .tertiaryLabel)
                .opacity(recording ? 1 : 0.6)
        )
        .clipShape(Circle())
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recording)
        .onAppear {
            self.recording = true
        }
    }
}

#Preview {
    RecordingView()
        .preferredColorScheme(.dark)
        .environment(AppState.shared)
}
