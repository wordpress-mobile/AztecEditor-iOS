import Foundation
import XCTest
@testable import Aztec


// MARK: - NSAttributedString Analyzer Tests
//
class NSAttributedStringAnalyzerTests: XCTestCase {

    struct LinkedSample {

        /// Testing Link URL
        ///
        static let wordpressURL = NSURL(string: "www.wordpress.com")!

        /// Plain Header String
        ///
        static let headerString = NSAttributedString(string: "Newsflash gentlemen")

        /// Linkified String
        ///
        static let linkifiedString = { _ -> NSAttributedString in
            return NSAttributedString(string: "WordPress iOS + Aztec", attributes: [NSLinkAttributeName: wordpressURL])
        }()

        /// Plain Tail String
        ///
        static let tailString = NSAttributedString(string: " gets things to a different level")

        /// Full String: Header + Link + Tail
        ///
        static let fullString = { _ -> NSAttributedString in
            let fullString = NSMutableAttributedString()
            fullString.append(headerString)
            fullString.append(linkifiedString)
            fullString.append(tailString)
            return fullString
        }()

        /// NSRange indicating the linkified segment
        ///
        static let linkifiedRange = { _ -> NSRange in
            return fullString.foundationString.range(of: linkifiedString.string)
        }()

        /// Initial Link Location
        ///
        static let initialLinkLocation = linkifiedRange.location

        /// Final Link Location
        ///
        static let finalLinkLocation = linkifiedRange.location + linkifiedRange.length
    }



    /// Verifies that isLocationPreceededByLink returns false, whenever the "Character immediately before the
    /// indicated location" does **NOT** contain the NSLinkAttribute.
    ///
    func testLocationPreceededByLinkReturnsFalseWhenNotPreceededByLink() {
        let fullString = LinkedSample.fullString
        let initialLinkLocation = LinkedSample.initialLinkLocation
        let finalLinkLocation = LinkedSample.finalLinkLocation

        for i in 0...fullString.length where i <= initialLinkLocation || i > finalLinkLocation {
            XCTAssertFalse(fullString.isLocationPreceededByLink(i))
        }
    }

    /// Verifies that isLocationPreceededByLink returns true, whenever the "Character immediately before the
    /// indicated location" **DOES** contain the NSLinkAttribute.
    ///
    func testLocationPreceededByLinkReturnsTrueWhenNotPreceededByLink() {
        let fullString = LinkedSample.fullString
        let initialLinkLocation = LinkedSample.initialLinkLocation
        let finalLinkLocation = LinkedSample.finalLinkLocation

        for i in 0...fullString.length where i > initialLinkLocation && i <= finalLinkLocation {
            XCTAssertTrue(fullString.isLocationPreceededByLink(i))
        }
    }


    /// Verifies that isLocationSucceededByLink returns false, whenever the "Character immediately before the
    /// indicated location" does **NOT** contain the NSLinkAttribute.
    ///
    func testLocationSucceededByLinkReturnsFalseWhenNotSucceededByLink() {
        let fullString = LinkedSample.fullString
        let initialLinkLocation = LinkedSample.initialLinkLocation
        let finalLinkLocation = LinkedSample.finalLinkLocation

        for i in 0...fullString.length where i < initialLinkLocation || i >= finalLinkLocation {
            XCTAssertFalse(fullString.isLocationSuccededByLink(i))
        }
    }

    /// Verifies that isLocationSucceededByLink returns true, whenever the "Character immediately before the
    /// indicated location" **DOES** contain the NSLinkAttribute.
    ///
    func testLocationSucceededByLinkReturnsTrueWhenSucceededByLink() {
        let fullString = LinkedSample.fullString
        let initialLinkLocation = LinkedSample.initialLinkLocation
        let finalLinkLocation = LinkedSample.finalLinkLocation

        for i in 0...fullString.length where i > initialLinkLocation && i < finalLinkLocation {
            XCTAssertTrue(fullString.isLocationSuccededByLink(i))
        }
    }

    /// Verifies that *safeSubstring* returns nil, whenever the range parameter is not valid within the receiver.
    ///
    func testSafeSubstringAtRangeReturnsNilWhenQueriedWithOutOfBoundsRanges() {
        let fullString = LinkedSample.fullString
        let empty = NSAttributedString()

        let ranges = [
            NSRange(location: fullString.length, length: 1),
            NSRange(location: -1, length: 1)
        ]

        for range in ranges {
            XCTAssertNil(fullString.safeSubstring(at: range))
            XCTAssertNil(empty.safeSubstring(at: range))
        }
    }
}
