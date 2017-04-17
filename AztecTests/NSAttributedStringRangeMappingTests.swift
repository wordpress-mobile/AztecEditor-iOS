import Foundation
import XCTest
@testable import Aztec

class NSAttributedStringRangeMappingTests: XCTestCase {
    
    /// Tests that `map(range:bySubtractingAttributeNamed:)` works.
    ///
    /// Note: I'll use | to signal the location of visual-only characters.
    ///
    /// Input: 
    ///     - String: "|Hello World!|"
    ///     - Range: full string range
    ///
    /// Expected result:
    ///     - (loc: 0, len: 11)
    ///
    func testMapRangeBySubtractingAttributeNamed() {
        let factory = VisualOnlyElementFactory()

        let string = NSMutableAttributedString(attributedString: factory.newline())

        string.append(NSAttributedString(string: "Hello Word!"))
        string.append(factory.newline())

        let range = NSRange(location: 0, length: string.length)
        let mappedRange = string.map(range: range, bySubtractingAttributeNamed: VisualOnlyAttributeName)

        XCTAssertEqual(mappedRange, NSRange(location: 0, length: 11))
    }

    /// Tests that `map(range:bySubtractingAttributeNamed:)` works.
    ///
    /// Note: I'll use | to signal the location of visual-only characters.
    ///
    /// Input:
    ///     - String: "|Hello World!||Hi all!|"
    ///     - Range: full string range
    ///
    /// Expected result:
    ///     - (loc: 0, len: 18)
    ///
    func testMapRangeBySubtractingAttributeNamed2() {
        let factory = VisualOnlyElementFactory()

        let string = NSMutableAttributedString(attributedString: factory.newline())

        string.append(NSAttributedString(string: "Hello Word!"))
        string.append(factory.newline())
        string.append(factory.newline())
        string.append(NSAttributedString(string: "Hi all!"))
        string.append(factory.newline())

        let range = NSRange(location: 0, length: string.length)
        let mappedRange = string.map(range: range, bySubtractingAttributeNamed: VisualOnlyAttributeName)

        XCTAssertEqual(mappedRange, NSRange(location: 0, length: 18))
    }

    /// Tests that `map(range:bySubtractingAttributeNamed:)` works.
    ///
    /// Note: I'll use | to signal the location of visual-only characters.
    ///
    /// Input:
    ///     - String: "|Hello World!||Hi all!|"
    ///     - Range: (loc: 7, len: 10)
    ///
    /// Expected result:
    ///     - (loc: 0, len: 18)
    ///
    func testMapRangeBySubtractingAttributeNamed3() {
        let factory = VisualOnlyElementFactory()

        let string = NSMutableAttributedString(attributedString: factory.newline())

        string.append(NSAttributedString(string: "Hello Word!"))
        string.append(factory.newline())
        string.append(factory.newline())
        string.append(NSAttributedString(string: "Hi all!"))
        string.append(factory.newline())

        let range = NSRange(location: 7, length: 10)
        let mappedRange = string.map(range: range, bySubtractingAttributeNamed: VisualOnlyAttributeName)

        XCTAssertEqual(mappedRange, NSRange(location: 6, length: 8))
    }
}
