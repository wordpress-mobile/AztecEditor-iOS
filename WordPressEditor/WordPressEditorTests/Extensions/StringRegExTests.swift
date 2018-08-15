import Aztec
import XCTest
@testable import WordPressEditor

class StringRegExTests: XCTestCase {
    
    /// This test checks if `replacingMatches(of:options:using:)` crashes when the match finishes with
    /// a character modified by "Mark, nonspacing"-class unicode characters.
    ///
    /// More info here: https://github.com/wordpress-mobile/WordPress-iOS/issues/9941
    ///
    func testReplacingMatchesWithMnClassUnicodeCharacters() {
        let string = "a\u{0309}"
        
        XCTAssertNoThrow(string.replacingMatches(of: "a", options: [], using: { _, _ in return "ignored!" }));
    }
}
