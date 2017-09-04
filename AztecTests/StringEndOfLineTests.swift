import XCTest
@testable import Aztec

class StringEndOfLineTests: XCTestCase {

    private let endOfLineSeparators = [String(.lineFeed), String(.lineSeparator), String(.paragraphSeparator)]

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - isEmptyParagraph(at index:)

    func testIsEmptyParagraphAtIndex1() {
        let string = "Hello there"
        let index = string.endIndex

        XCTAssertFalse(string.isEmptyParagraph(at: index))
    }

    func testIsEmptyParagraphAtIndex2() {
        let string = "Hello there"
        let index = string.startIndex

        XCTAssertFalse(string.isEmptyParagraph(at: index))
    }

    func testIsEmptyParagraphAtIndex3() {
        let string = ""
        let index = string.startIndex

        XCTAssertTrue(string.isEmptyParagraph(at: index))
    }

    func testIsEmptyParagraphAtIndex4() {
        for separator in endOfLineSeparators {
            let string = separator
            let index = string.startIndex

            XCTAssertTrue(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEmptyParagraphAtIndex5() {
        for separator in endOfLineSeparators {
            let string = separator
            let index = string.endIndex

            XCTAssertTrue(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEmptyParagraphAtIndex6() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.startIndex

            XCTAssertFalse(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEmptyParagraphAtIndex7() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.endIndex

            XCTAssertTrue(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEmptyParagraphAtIndex8() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.startIndex

            XCTAssertTrue(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEmptyParagraphAtIndex9() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.endIndex

            XCTAssertFalse(string.isEmptyParagraph(at: index))
        }
    }

    // MARK: - isEndOfLine()

    func testIsEndOfLine1() {
        for separator in endOfLineSeparators {
            let string = separator
            let index = string.startIndex

            XCTAssertTrue(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEndOfLine2() {
        for separator in endOfLineSeparators {
            let string = separator
            let index = string.endIndex

            XCTAssertTrue(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEndOfLine3() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.startIndex

            XCTAssertFalse(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEndOfLine4() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.endIndex

            XCTAssertTrue(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEndOfLine5() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.startIndex

            XCTAssertTrue(string.isEmptyParagraph(at: index))
        }
    }

    func testIsEndOfLine6() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.endIndex

            XCTAssertFalse(string.isEmptyParagraph(at: index))
        }
    }

    // MARK: - isStartOfNewline()

    func testIsStartOfNewline1() {
        for separator in endOfLineSeparators {
            let string = "\(separator)"
            let index = string.startIndex

            XCTAssertTrue(string.isStartOfNewLine(at: index))
        }
    }

    func testIsStartOfNewline2() {
        for separator in endOfLineSeparators {
            let string = "\(separator)"
            let index = string.endIndex

            XCTAssertTrue(string.isStartOfNewLine(at: index))
        }
    }

    func testIsStartOfNewline3() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.range(of: "🌎")!.lowerBound

            XCTAssertTrue(string.isStartOfNewLine(at: index))
        }
    }

    func testIsStartOfNewline4() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.range(of: "🌎")!.upperBound

            XCTAssertFalse(string.isStartOfNewLine(at: index))
        }
    }

    func testIsStartOfNewline5() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.range(of: "🌎")!.lowerBound

            XCTAssertTrue(string.isStartOfNewLine(at: index))
        }
    }

    func testIsStartOfNewline6() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.range(of: "🌎")!.upperBound

            XCTAssertFalse(string.isStartOfNewLine(at: index))
        }
    }

    func testEndsWithCarriageReturnEffectivelyReturnsTrueWheneverTestStringEndsWithCarriageReturn() {
        let test = "something\u{000D}"

        XCTAssert(test.isEndOfParagraph(at: test.endIndex))
    }

    func testEndsWithCarriageReturnReturnsFalseWheneverTestStringDoesNotEndWithCarriageReturn() {
        let test = "something"

        XCTAssertFalse(test.isEndOfParagraph(at: test.endIndex))
    }

    func testEndsWithDoesNotCrashOnEmptyString() {
        let test = ""

        XCTAssertNoThrow(test.isEndOfParagraph(at: test.endIndex), "")
    }
}
