import Foundation
#if canImport(LinkPresentation)
import LinkPresentation

@MainActor
final class LinkPreviewGenerator {
    private static let cache = NSCache<NSString, LPLinkMetadata>()

    static func fetchMetadata(for url: URL) async -> LPLinkMetadata? {
        let key = url.absoluteString as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        let provider = LPMetadataProvider()
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            cache.setObject(metadata, forKey: key)
            return metadata
        } catch {
            return nil
        }
    }

    static func detectURLs(in text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }

        let nsRange = NSRange(text.startIndex..., in: text)
        let results = detector.matches(in: text, options: [], range: nsRange)

        return results.compactMap(\.url)
    }
}
#endif
