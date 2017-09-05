import XCTest
@testable import Aztec

class StringEndOfParagraphTests: XCTestCase {
    
    func testEndsWithCarriageReturnEffectivelyReturnsTrueWheneverTestStringEndsWithCarriageReturn() {
        let test = "something\u{000D}"

        XCTAssert(test.isEndOfParagraph(before: test.endIndex))
    }

    func testEndsWithCarriageReturnReturnsFalseWheneverTestStringDoesNotEndWithCarriageReturn() {
        let test = "something"

        XCTAssertFalse(test.isEndOfParagraph(before: test.endIndex))
    }

    func testEndsWithDoesNotCrashOnEmptyString() {
        let test = ""

        XCTAssertNoThrow(test.isEndOfParagraph(before: test.endIndex), "")
    }    
}
