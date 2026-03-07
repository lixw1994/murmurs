import Foundation

extension String {
    func formattedHostName() -> String {
        var host = self.replacingOccurrences(of: " ", with: "")
        
        if !host.isEmpty && host.range(of: "^https?://", options: .regularExpression) == nil {
            host = "https://" + host
        }
        
        if !host.isEmpty && host.suffix(1) != "/" {
            host = host + "/"
        }
        
        return host
    }
}
