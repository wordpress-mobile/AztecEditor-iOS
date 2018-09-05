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

    // MARK: - isEmptyLine(at index:)

    func testIsEmptyLineAtIndex1() {
        let string = "Hello there"
        let index = string.endIndex

        XCTAssertFalse(string.isEmptyLine(at: index))
    }

    func testIsEmptyLineAtIndex2() {
        let string = "Hello there"
        let index = string.startIndex

        XCTAssertFalse(string.isEmptyLine(at: index))
    }

    func testIsEmptyLineAtIndex3() {
        let string = ""
        let index = string.startIndex

        XCTAssertTrue(string.isEmptyLine(at: index))
    }

    func testIsEmptyLineAtIndex4() {
        for separator in endOfLineSeparators {
            let string = separator
            let index = string.startIndex

            XCTAssertTrue(string.isEmptyLine(at: index))
        }
    }

    func testIsEmptyLineAtIndex5() {
        for separator in endOfLineSeparators {
            let string = separator
            let index = string.endIndex

            XCTAssertTrue(string.isEmptyLine(at: index))
        }
    }

    func testIsEmptyLineAtIndex6() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.startIndex

            XCTAssertFalse(string.isEmptyLine(at: index))
        }
    }

    func testIsEmptyLineAtIndex7() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.endIndex

            XCTAssertTrue(string.isEmptyLine(at: index))
        }
    }

    func testIsEmptyLineAtIndex8() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.startIndex

            XCTAssertTrue(string.isEmptyLine(at: index))
        }
    }

    func testIsEmptyLineAtIndex9() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.endIndex

            XCTAssertFalse(string.isEmptyLine(at: index))
        }
    }

    // MARK: - isEndOfLine()

    func testIsEndOfLine1() {
        for separator in endOfLineSeparators {
            let string = separator
            let index = string.startIndex

            XCTAssertTrue(string.isEmptyLine(at: index))
        }
    }

    func testIsEndOfLine2() {
        for separator in endOfLineSeparators {
            let string = separator
            let index = string.endIndex

            XCTAssertTrue(string.isEmptyLine(at: index))
        }
    }

    func testIsEndOfLine3() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.startIndex

            XCTAssertFalse(string.isEmptyLine(at: index))
        }
    }

    func testIsEndOfLine4() {
        for separator in endOfLineSeparators {
            let string = "🌎\(separator)"
            let index = string.endIndex

            XCTAssertTrue(string.isEmptyLine(at: index))
        }
    }

    func testIsEndOfLine5() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.startIndex

            XCTAssertTrue(string.isEmptyLine(at: index))
        }
    }

    func testIsEndOfLine6() {
        for separator in endOfLineSeparators {
            let string = "\(separator)🌎"
            let index = string.endIndex

            XCTAssertFalse(string.isEmptyLine(at: index))
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
}
