import Foundation
import XCTest
@testable import Aztec

class NSAttributedStringAttributeRangesTests: XCTestCase {
    
    /// Tests that `map(range:bySubtractingAttributeNamed:)` works.
    ///
    /// Note: I'll use { and } to signal the location of the control characters used for the test.
    ///
    /// Input: 
    ///     - String: "{Hello World!}"
    ///     - Range: full string range
    ///
    /// Expected result:
    ///     - (loc: 0, len: 11)
    ///
    func testMapRange() {
        let factory = ControlCharacterFactory()

        guard let opener = factory.opener(forElement: .blockquote, inheritingAttributes: [:]) else {
            XCTFail("Expected a control character.")
            return
        }

        guard let closer = factory.closer(forElement: .blockquote, inheritingAttributes: [:]) else {
            XCTFail("Expected a control character.")
            return
        }

        let string = NSMutableAttributedString(attributedString: opener)

        string.append(NSAttributedString(string: "Hello Word!"))
        string.append(closer)

        let range = NSRange(location: 0, length: string.length)
        let mappedRange = string.map(range: range, bySubtractingAttributeNamed: ControlCharacterAttributeName)

        XCTAssertEqual(mappedRange, NSRange(location: 0, length: 11))
    }

    /// Tests that `map(range:bySubtractingAttributeNamed:)` works.
    ///
    /// Note: I'll use { and } to signal the location of the control characters used for the test.
    ///
    /// Input:
    ///     - String: "{Hello World!}{Hi all!}"
    ///     - Range: full string range
    ///
    /// Expected result:
    ///     - (loc: 0, len: 18)
    ///
    func testMapRange2() {
        let factory = ControlCharacterFactory()

        guard let opener = factory.opener(forElement: .blockquote, inheritingAttributes: [:]) else {
            XCTFail("Expected a control character.")
            return
        }

        guard let closer = factory.closer(forElement: .blockquote, inheritingAttributes: [:]) else {
            XCTFail("Expected a control character.")
            return
        }

        let string = NSMutableAttributedString(attributedString: opener)

        string.append(NSAttributedString(string: "Hello Word!"))
        string.append(closer)
        string.append(opener)
        string.append(NSAttributedString(string: "Hi all!"))
        string.append(closer)

        let range = NSRange(location: 0, length: string.length)
        let mappedRange = string.map(range: range, bySubtractingAttributeNamed: ControlCharacterAttributeName)

        XCTAssertEqual(mappedRange, NSRange(location: 0, length: 18))
    }

    /// Tests that `map(range:bySubtractingAttributeNamed:)` works.
    ///
    /// Note: I'll use { and } to signal the location of the control characters used for the test.
    ///
    /// Input:
    ///     - String: "{Hello World!}{Hi all!}"
    ///     - Range: (loc: 7, len: 10)
    ///
    /// Expected result:
    ///     - (loc: 0, len: 18)
    ///
    func testMapRange3() {
        let factory = ControlCharacterFactory()

        guard let opener = factory.opener(forElement: .blockquote, inheritingAttributes: [:]) else {
            XCTFail("Expected a control character.")
            return
        }

        guard let closer = factory.closer(forElement: .blockquote, inheritingAttributes: [:]) else {
            XCTFail("Expected a control character.")
            return
        }

        let string = NSMutableAttributedString(attributedString: opener)

        string.append(NSAttributedString(string: "Hello Word!"))
        string.append(closer)
        string.append(opener)
        string.append(NSAttributedString(string: "Hi all!"))
        string.append(closer)

        let range = NSRange(location: 7, length: 10)
        let mappedRange = string.map(range: range, bySubtractingAttributeNamed: ControlCharacterAttributeName)

        XCTAssertEqual(mappedRange, NSRange(location: 6, length: 8))
    }
}
