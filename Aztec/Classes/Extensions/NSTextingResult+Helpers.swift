import Foundation

public extension NSTextCheckingResult {

    /// Returns the match for the corresponding capture group position in a text
    ///
    /// - Parameters:
    ///   - position: the capture group position
    ///   - text: the string where the match was detected
    /// - Returns: the string with the captured group text
    ///
    func captureGroup(in position: Int, text: String) -> String? {
        guard position < numberOfRanges else {
            return nil
        }

        let nsrange = rangeAt(position)

        guard nsrange.location != NSNotFound else {
            return nil
        }

        let range = text.range(from: nsrange)
        let captureGroup = text.substring(with: range)
        return captureGroup
    }
}
