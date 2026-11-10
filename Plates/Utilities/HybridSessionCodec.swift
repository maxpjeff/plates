import Foundation

enum HybridSessionCodec {
    static func encodeSpec(_ spec: HybridItemSpec) -> Data? {
        try? JSONEncoder().encode(spec)
    }

    static func decodeSpec(_ data: Data?) -> HybridItemSpec? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(HybridItemSpec.self, from: data)
    }

    static func encodeResult(_ result: HybridItemResult) -> Data? {
        try? JSONEncoder().encode(result)
    }

    static func decodeResult(_ data: Data?) -> HybridItemResult? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(HybridItemResult.self, from: data)
    }
}
