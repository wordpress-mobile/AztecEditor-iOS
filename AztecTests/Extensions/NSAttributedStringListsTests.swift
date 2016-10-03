import XCTest
@testable import Aztec


// MARK: - NSAttributedStringLists Tests
//
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
        for index in (0 ... samplePlainString.length) {
            XCTAssertNil(samplePlainString.rangeOfTextList(atIndex: index))
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
        let string = sampleListString
        let expected = sampleListRange

        for index in (0 ..< string.length) {
            let retrieved = string.rangeOfTextList(atIndex: index)

            if isIndexWithinListRange(index) {
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
        let string = samplePlainString
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
        let string = samplePlainString

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
        let string = sampleListString
        let expectedContents = sampleListContents
        let expectedRange = sampleListRange

        for index in (0 ..< string.length) {
            let retrievedContents = string.textListContents(followingIndex: index)

            if isIndexWithinListRange(index) {
                XCTAssertNotNil(retrievedContents)
                let delta = index - expectedRange.location
                let expectedSubstring = expectedContents.substringFromIndex(expectedContents.startIndex.advancedBy(delta))
                XCTAssertEqual(retrievedContents!.string, expectedSubstring)
            } else {
                XCTAssertNil(retrievedContents)
            }
        }
    }

    /// Tests that `textListAttribute` returns the expected TestList, when applicable.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with no TextList.
    ///
    /// Expected result:
    /// - Nil. Always
    ///
    func testTextListAttributeReturnsNilWhenThereIsNoList() {
        let string = samplePlainString

        for index in (0 ..< string.length) {
            XCTAssertNil(string.textListAttribute(atIndex: index))
        }
    }

    /// Tests that `textListAttribute` returns the expected TestList, when applicable.
    ///
    /// Set up:
    /// - Sample (NON empty) NSAttributedString, with a TextList.
    ///
    /// Expected result:
    /// - The TextList, whenever we're within the expected range.
    ///
    func testTextListAttributeReturnsTheTextListAttributeWhenApplicable() {
        let string = sampleListString

        for index in (0 ..< string.length) {
            let attribute = string.textListAttribute(atIndex: index)
            if isIndexWithinListRange(index) {
                XCTAssertNotNil(attribute)
            } else {
                XCTAssertNil(attribute)
            }
        }
    }
}



// MARK: - Helpers
//
extension NSAttributedStringListsTests
{
    var samplePlainString: NSAttributedString {
        return NSAttributedString(string: "Lord Yosemite should DEFINITELY be a Game of Thrones Character.")
    }

    var sampleListString: NSAttributedString {
        let sample = NSMutableAttributedString(string: "World Domination Plans:\n" +
            "- Build Warp Drive\n" +
            "- Rebuild Atlantis\n" +
            "- Free Internet for Everyone\n" +
            "Yay!")

        let range = (sample.string as NSString).rangeOfString(sampleListContents)
        let attributes = [TextList.attributeName: TextList(kind: .Ordered)]
        sample.addAttributes(attributes, range: range)

        return sample
    }

    var sampleListContents: String {
        return "- Build Warp Drive\n" +
            "- Rebuild Atlantis\n" +
            "- Free Internet for Everyone"
    }

    var sampleListRange: NSRange {
        return (sampleListString.string as NSString).rangeOfString(sampleListContents)
    }

    func isIndexWithinListRange(index: Int) -> Bool {
        let expectedRange = sampleListRange
        let minimumIndex = expectedRange.location
        let maximumIndex = expectedRange.location + expectedRange.length

        return index >= minimumIndex && index < maximumIndex
    }
}
