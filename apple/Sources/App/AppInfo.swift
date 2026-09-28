import Foundation

struct AppInfo {
    static let appStoreURL: URL = {
        if let urlString = Bundle.main.infoDictionary?["AppStoreURL"] as? String,
           let url = URL(string: urlString) {
            return url
        }
        return URL(string: Constants.Legal.repo_url)!
    }()

    static let reviewURL: URL = {
        return appStoreURL.appending(queryItems: [.init(name: "action", value: "write-review")])
    }()
    
    static let appVersion: String = {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }()
    
    static let buildVersion: String = {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }()
    
    public static let gitHash: String = {
        guard let hash = Bundle.main.infoDictionary?["GIT_HASH"] as? String, hash != "" else {
            return ""
        }
        return hash
    }()
    
    static let sourceURL: URL = {
        let baseURL = URL(string: Constants.Legal.repo_url)!
        guard !gitHash.isEmpty else { return baseURL }
        
        return baseURL.appendingPathComponent("tree").appendingPathComponent(gitHash)
    }()
    
}
