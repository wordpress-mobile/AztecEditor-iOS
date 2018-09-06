import Foundation

open class RegexProcessor: Processor {

    public typealias ReplaceRegex = (NSTextCheckingResult, String) -> String?

    public let regex: NSRegularExpression
    public let replacer: ReplaceRegex

    public init(regex: NSRegularExpression, replacer: @escaping ReplaceRegex) {
        self.regex = regex
        self.replacer = replacer
    }

    public func process(_ text: String) -> String {
        let matches = regex.matches(in: text, options: [], range: text.utf16NSRange(from: text.startIndex ..< text.endIndex))
        var replacements = [(NSRange, String)]()
        for match in matches {
            if let replacement = replacer(match, text) {
                replacements.append((match.range, replacement))
            }
        }
        let resultText = replace(matches: replacements, in: text)
        return resultText
    }

    func replace(matches: [(NSRange, String)], in text: String) -> String {
        let mutableString = NSMutableString(string: text)
        var offset = 0
        for (range, replacement) in matches {
            let lengthBefore = mutableString.length
            let offsetRange = NSRange(location: range.location + offset, length: range.length)
            mutableString.replaceCharacters(in: offsetRange, with: replacement)
            let lengthAfter = mutableString.length
            offset += (lengthAfter - lengthBefore)
        }
        return mutableString as String
    }
}
