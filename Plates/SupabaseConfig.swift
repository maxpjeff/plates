import Foundation
import Supabase

enum SupabaseConfig {
    private static let placeholderHost = "placeholder.local"

    static var isConfigured: Bool {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let url = URL(string: urlString),
            url.host != placeholderHost,
            let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            !key.isEmpty,
            key != "placeholder"
        else { return false }
        return true
    }

    static let shared: SupabaseClient? = {
        guard isConfigured,
              let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              let url = URL(string: urlString),
              let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String
        else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }()
}
