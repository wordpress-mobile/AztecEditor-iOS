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

        #if swift(>=4.0)
            let nsrange = self.range(at: position)
        #else
            let nsrange = self.rangeAt(position)
        #endif

        guard nsrange.location != NSNotFound else {
            return nil
        }
        
        let range = text.range(fromUTF16NSRange: nsrange)
        
        #if swift(>=4.0)
            let captureGroup = String(text[range])
        #else
            let captureGroup = text.substring(with: range)
        #endif
        
        return captureGroup
    }
}
