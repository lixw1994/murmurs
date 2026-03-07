import SwiftUI
import XLang

struct SettingsView: View {
    @EnvironmentObject var config: Config
    @Environment(AppState.self) var appState
    @EnvironmentObject var appDelegate: AppDelegate
    
    @State private var showPremium = false
    @State private var showExport = false
    
    @State private var showTransWarning = false {
        didSet {
            if showTransWarning {
                transWarningDisplayed = true
            }
        }
    }
    
    @AppStorage("trans_privacy_warning_displayed") var transWarningDisplayed = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    sectionGeneral
                    sectionServer
                    
                    sectionTranscription
                    sectionSummarization
                    
                    if !appState.isPremium {
                        sectionPremium
                    }
                    
                    sectionData
                    
                    sectionExperiments
                    
                    sectionInfo
                }
            }
            .navigationTitle(L(.settings_title))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: config.transEnabled) { oldValue, newValue in
                if newValue && transWarningDisplayed == false {
                    showTransWarning = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var sectionGeneral: some View {
        @Bindable var appState = appState
        Section {
            Picker(selection: $config.dayStartTime) {
                ForEach(0..<9) { n in
                    Text("0\(n):00")
                        .tag(n)
                }
            } label: {
                Text(L(.settings_day_starts_at))
            }
            
            Picker(selection: $appState.language) {
                ForEach(Language.supported, id: \.self) { lang in
                    Text(lang.displayName)
                        .tag(lang)
                }
            } label: {
                Text(L(.settings_app_language))
            }
            
            Picker(selection: $config.darkMode) {
                ForEach(DarkMode.allCases, id: \.self) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            } label: {
                Text(L(.settings_app_appearance))
            }

            MyToggle(isOn: $config.autoSave) {
                Text(L(.settings_auto_save))
            }
            
            MyToggle(isOn: $config.holdToRecordEnabled) {
                Text(L(.hold_to_record))
            }
            
        } header: {
            Text(L(.settings_general))
        }
    }
    
    @ViewBuilder
    private var sectionServer: some View {
        Section {
            NavigationLink(destination: ServerSettingsView()) {
                HStack {
                    Text(L(.settings_server_settings))
                    Spacer()

                    if config.isServerSet {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
        } header: {
            Text(L(.settings_server))
        }
    }
    
    @ViewBuilder
    private var sectionTranscription: some View {
        Section {
            MyToggle(isOn: $config.transEnabled) {
                Text(L(.enable))
            }
            
            if config.transEnabled {
                Picker(selection: $config.transLang) {
                    ForEach(TranscriptionLang.allCases, id: \.self) { item in
                        Text(item.displayName)
                    }
                } label: {
                    Text(L(.settings_trans_lang))
                }
                
                Picker(selection: $config.transProvider) {
                    ForEach(TranscriptionProvider.allCases, id: \.self) { item in
                        Text(item.displayName)
                    }
                } label: {
                    Text(L(.settings_trans_provider))
                }
                
                if config.transProvider == .openai {
                    Picker(selection: $config.transModel) {
                        ForEach(TranscriptionModel.allCases, id: \.self) { item in
                            Text(item.displayName)
                                .tag(item)
                        }
                    } label: {
                        Text(L(.settings_trans_model))
                    }
                }
            }
        } header: {
            Text(L(.settings_trans))
        } footer: {
            if config.transEnabled && config.transProvider == .apple {
                Text(L(.trans_provider_apple_notice))
            } else {
                Text(" ")
            }
        }
        .alert(isPresented: $showTransWarning) {
            Alert(title: Text(L(.settings_trans_privacy_warning)), dismissButton: nil)
        }
    }
    
    @ViewBuilder
    private var sectionSummarization: some View {
        Section {
            MyToggle(isOn: $config.sumEnabled) {
                Text(L(.enable))
            }
            
            if config.sumEnabled {
                Picker(selection: $config.aiModel) {
                    ForEach(OpenAIChatModel.allCases, id: \.self) {
                        Text($0.displayName)
                    }
                } label: {
                    Text(L(.settings_sum_model))
                }

                NavigationLink {
                    PromptsView()
                } label: {
                    Text(L(.settings_sum_prompts))
                }
            }
        } header: {
            Text(L(.settings_sum))
        } footer: {
        }
    }
    
    @ViewBuilder
    private var sectionPremium: some View {
        Section {
            Button {
                showPremium = true
            } label:{
                Label(L(.premium), systemImage: "crown.fill")
                    .foregroundColor(.orange)
            }
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
    }
    
    @ViewBuilder
    private var sectionData: some View {
        Section {
            NavigationLink(destination: ReadwiseSettingsView()) {
                HStack {
                    Text("Readwise")
                    Spacer()
                    if config.isReadwiseSet {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }

            Button {
                if appState.isPremium {
                    showExport = true
                } else {
                    showPremium = true
                }
            } label:{
                HStack {
                    Text(L(.export_data))
                    premiumLockIcon
                }
            }
        }
        .sheet(isPresented: $showExport) {
            ExportView()
        }
    }
    
    @ViewBuilder
    private var sectionExperiments: some View {
        Section {
            NavigationLink(destination: ExperimentsView()) {
                Text(L(.settings_experimental_features))
            }
        }
    }
    
    @ViewBuilder
    private var sectionInfo: some View {
        Section {
            NavigationLink(destination: AboutView()) {
                Text(L(.about_app))
            }
            
            ShareLink(item: AppInfo.appStoreURL) {
                Text(L(.share_with_friends))
            }
            
            Link(destination: AppInfo.reviewURL) {
                HStack {
                    Text(L(.rate_on_the_app_store))
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                HStack {
                    Text(L(.version))
                }
                Spacer()
                HStack {
                    Group {
                        Text("v\(AppInfo.appVersion)")
                            .foregroundColor(.secondary)
                        Text("(\(AppInfo.gitHash.isEmpty ? AppInfo.buildVersion : AppInfo.gitHash))")
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    .font(.system(.footnote, design: .monospaced))
                }
            }
        } footer: {
            VStack(spacing: 10) {
                Link(L(.source_code), destination: AppInfo.sourceURL)
                HStack(spacing: 5) {
                    Link(L(.privacy_policy), destination: URL(string: Constants.Legal.privacy_policy_url)!)
                    Text("・")
                    Link(L(.terms_of_use), destination: URL(string: Constants.Legal.terms_url)!)
                }
            }
            .foregroundColor(.secondary)
            .font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
    
    @ViewBuilder
    private var premiumLockIcon: some View {
        if !appState.isPremium {
            Image(systemName: "lock.fill")
                .font(.subheadline)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
    }
}

#Preview {
    SettingsView()
}
