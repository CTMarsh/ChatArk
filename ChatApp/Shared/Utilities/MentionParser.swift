import Foundation

enum MentionParser {
    struct Mention: Sendable {
        let username: String
        let range: Range<String.Index>
    }

    static func parse(_ text: String) -> [Mention] {
        var mentions: [Mention] = []

        if let regex = try? NSRegularExpression(pattern: "@(\\w+)", options: []) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let results = regex.matches(in: text, options: [], range: nsRange)

            for result in results {
                if let range = Range(result.range(at: 1), in: text),
                   let fullRange = Range(result.range, in: text) {
                    mentions.append(Mention(
                        username: String(text[range]),
                        range: fullRange
                    ))
                }
            }
        }

        return mentions
    }

    static func extractMentionedUsernames(from text: String) -> [String] {
        parse(text).map(\.username)
    }
}
