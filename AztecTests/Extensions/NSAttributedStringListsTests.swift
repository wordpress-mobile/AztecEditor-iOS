import XCTest
@testable import Aztec

class NSAttributedStringListsTests: XCTestCase {

    /// Tests that `rangeOfTextList` works.
    ///
    /// Set up:
    /// - Sample NSAttributedString, with no TextList
    ///
    /// Expected result:
    /// - nil for the whole String Length
    ///
    func testRangeOfTextListReturnsNilWhenStringDoesntContainTextLists() {
        let string = NSAttributedString(string: "This is a sample Attributed String, with no list")

        for index in (0 ... string.length) {
            XCTAssertNil(string.rangeOfTextList(atIndex: index))
        }
    }

    /// Tests that `rangeOfTextList` works.
    ///
    /// Set up:
    /// - Sample NSAttributedString, with a TextList associated to a substring
    ///
    /// Expected result:
    /// - The "Text List Substring" range, when applicable.
    ///
    func testRangeOfTextListReturnsTheExpectedRange() {
        let string = NSMutableAttributedString(string: "Alala lala long long le long long long YEAH!")
        let attributes = [TextList.attributeName: TextList(kind: .Ordered)]
        let expected = (string.string as NSString).rangeOfString("long le long")

        string.addAttributes(attributes, range: expected)

        let minimumIndex = expected.location
        let maximumIndex = expected.location + expected.length

        for index in (0 ..< string.length) {
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

    /// Tests that `rangeOfEntireString` works.
    ///
    /// Set up:
    /// - Sample (empty) NSAttributedString
    ///
    /// Expected result:
    /// - Range: (loc: 0 , length: 0)
    ///
    func testRangeOfEntireStringWorksAsExpectedWithEmptyStrings() {
        let string = NSAttributedString()
        let range = string.rangeOfEntireString

        XCTAssert(range.location == 0)
        XCTAssert(range.length == string.length)
    }

    /// Tests that `rangeOfEntireString` works.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString
    ///
    /// Expected result:
    /// - Range: (loc: 0 , length: Sample String Length)
    ///
    func testRangeOfEntireStringWorksAsExpectedWithNonEmptyStrings() {
        let string = NSAttributedString(string: "Lord Yosemite should DEFINITELY be a Game of Thrones Character.")
        let range = string.rangeOfEntireString

        XCTAssert(range.location == 0)
        XCTAssert(range.length == string.length)
    }

    /// Tests that `textListContents` returns nil, whenever there is no Text List.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, but with no TextList
    ///
    /// Expected result:
    /// - nil for the whole String Length.
    ///
    func testTextListContentsReturnsNilWheneverTheReceiverHasNoTextList() {
        let string = NSAttributedString(string: "This is a sample string, with no Lists")

        for index in (0 ..< string.length) {
            let contents = string.textListContents(followingIndex: index)
            XCTAssertNil(contents)
        }
    }

    /// Tests that `textListContents` returns the expected TestList Contents.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with a TextList range.
    ///
    /// Expected result:
    /// - Text List Contents. YAY!.
    ///
    func testTextListContentsReturnsTheAssociatedTextListContents() {
        let string = NSMutableAttributedString(string: "World Domination Plans:\n - Build Warp Drive\n - Rebuild Atlantis\n End!")
        let expectedContents = "- Build Warp Drive\n - Rebuild Atlantis"

        // Set Attribute
        let range = (string.string as NSString).rangeOfString(expectedContents)
        let attributes = [TextList.attributeName: TextList(kind: .Ordered)]

        string.addAttributes(attributes, range: range)

        // Verify!
        let minimumIndex = range.location
        let maximumIndex = range.location + range.length

        for index in (0 ..< string.length) {
            let retrievedContents = string.textListContents(followingIndex: index)

            if index >= minimumIndex && index < maximumIndex {
                XCTAssertNotNil(retrievedContents)
                let delta = index - minimumIndex
                let expectedSubstring = expectedContents.substringFromIndex(expectedContents.startIndex.advancedBy(delta))
                XCTAssertEqual(retrievedContents!.string, expectedSubstring)
            } else {
                XCTAssertNil(retrievedContents)
            }
        }
    }
}
