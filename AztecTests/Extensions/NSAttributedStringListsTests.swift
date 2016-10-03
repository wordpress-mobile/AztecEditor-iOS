import XCTest
@testable import Aztec

class NSAttributedStringListsTests: XCTestCase {

    func testRangeOfTextListReturnsNilWhenStringDoesntContainTextLists() {
        let string = NSAttributedString(string: "This is a sample Attributed String, with no list")

        for index in 0...string.length {
            XCTAssertNil(string.rangeOfTextList(atIndex: index))
        }
    }

    func testRangeOfTextListReturnsTheExpectedRange() {
        let string = NSMutableAttributedString(string: "Alala lala long long le long long long YEAH!")
        let attributes = [TextList.attributeName: TextList(kind: .Ordered)]
        let expected = (string.string as NSString).rangeOfString("long le long")

        string.addAttributes(attributes, range: expected)

        let minimumIndex = expected.location
        let maximumIndex = expected.location + expected.length

        for index in 0..<string.length {
            let retrieved = string.rangeOfTextList(atIndex: index)

            if index >= minimumIndex && index < maximumIndex {
                XCTAssert(retrieved != nil)
                XCTAssert(expected.location == retrieved!.location)
                XCTAssert(expected.length == retrieved!.length)
            } else {
                XCTAssert(retrieved == nil)
            }
        }
    }

    func testRangeOfEntireStringWorksAsExpectedWithEmptyStrings() {
        let string = NSAttributedString()
        let range = string.rangeOfEntireString

        XCTAssert(range.location == 0)
        XCTAssert(range.length == string.length)
    }

    func testRangeOfEntireStringWorksAsExpectedWithNonEmptyStrings() {
        let string = NSAttributedString(string: "Lord Yosemite should DEFINITELY be a Game of Thrones Character.")
        let range = string.rangeOfEntireString

        XCTAssert(range.location == 0)
        XCTAssert(range.length == string.length)
    }
}
