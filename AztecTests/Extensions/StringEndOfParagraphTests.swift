import XCTest
@testable import Aztec

class StringEndOfParagraphTests: XCTestCase {
    
    func testIsEndOfParagraphReturnsTrueWheneverTestStringEndsWithCarriageReturn() {
        let test = "something" + String(.carriageReturn)

        XCTAssertTrue(test.isEndOfParagraph(before: test.endIndex))
    }

    func testIsEndOfParagraphReturnsFalseWheneverTestStringEndsWithLineSeparator() {
        let test = "something" + String(.lineSeparator)

        XCTAssertFalse(test.isEndOfParagraph(before: test.endIndex))
    }
}
