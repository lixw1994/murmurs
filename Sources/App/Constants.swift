import Foundation

struct Constants {
    
    static let user_agent = "Murmurs \(AppInfo.appVersion)"
    
    struct Contact {
        static let github = "https://github.com/lixw1994"
    }

    struct Legal {
        static let repo_url = "https://github.com/lixw1994/murmurs"
        static let privacy_policy_url = "https://lixw1994.github.io/murmurs/privacy_policy.html"
        static let terms_url = "https://lixw1994.github.io/murmurs/terms.html"
    }
    
    struct OpenAI {
        static let api_key_url = "https://platform.openai.com/account/api-keys"
        static let api_host = "https://api.openai.com/"
    }
    
    struct Summary {
        static let lengthLimit = 10
    }
    
    struct IAP {
        static let premiumProductId = "com.tangyue.murmurs.premium"
    }
    
    struct Limit {
        static let prompts = 3
        static let daily_characters = 20000
        static let daily_characters_premium = daily_characters * 5
    }
    
}
