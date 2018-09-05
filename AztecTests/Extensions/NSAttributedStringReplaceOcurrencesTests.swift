import Foundation
import XCTest
@testable import Aztec

class NSAttributedStringReplaceOcurrencesTests: XCTestCase {

    // MARK: - Test replacing a string that doesn't exist in the original attrString

    /// Tests that replacing ocurrences of a string that doesn't exist in the original attrString
    /// doesn't cause the final attrString to change.
    ///
    func testReplaceOcurrencesWithoutMatches1() {
        let attrString = NSAttributedString(string: "Hello 🌎 World!")
        let newAttrString = NSAttributedString(with: attrString, replacingOcurrencesOf: "🍎", with: "Ahoi!")

        XCTAssertEqual(newAttrString, attrString)
    }

    /// Tests that replacing ocurrences of a string that doesn't exist in the original attrString
    /// doesn't cause the final attrString to change.
    ///
    func testReplaceOcurrencesWithoutMatches2() {
        let attrString = NSAttributedString(string: "Hello 🌎 World!")
        let newAttrString = NSAttributedString(with: attrString, replacingOcurrencesOf: "", with: "Ahoi!")

        XCTAssertEqual(newAttrString, attrString)
    }

    // MARK: - Test replacing a string that exists once in the original attrString

    /// Tests that replacing ocurrences of a string that shows up once in the original string
    /// works.
    ///
    func testReplaceOcurrencesThatAppearOnce1() {
        let attrString = NSAttributedString(string: "Hello 🌎 World!")
        let newAttrString = NSAttributedString(with: attrString, replacingOcurrencesOf: "🌎 ", with: "")

        XCTAssertEqual(newAttrString, NSAttributedString(string: "Hello World!"))
    }


    /// Tests that replacing ocurrences of a string that shows up once in the original string
    /// works.
    ///
    func testReplaceOcurrencesThatAppearOnce2() {
        let attrString = NSAttributedString(string: "Hello 🌎 World!")
        let newAttrString = NSAttributedString(with: attrString, replacingOcurrencesOf: "Hello ", with: "")

        XCTAssertEqual(newAttrString, NSAttributedString(string: "🌎 World!"))
    }

    /// Tests that replacing ocurrences of a string that shows up once in the original string
    /// works.
    ///
    func testReplaceOcurrencesThatAppearOnce3() {
        let attrString = NSAttributedString(string: "Hello 🌎 World!")
        let newAttrString = NSAttributedString(with: attrString, replacingOcurrencesOf: " World!", with: "")

        XCTAssertEqual(newAttrString, NSAttributedString(string: "Hello 🌎"))
    }

    // MARK: - Test replacing a string that exists once in the original attrString

    /// Tests that replacing ocurrences of a string that shows up more than once in the original
    /// string works.
    ///
    func testReplaceOcurrencesThatAppearMoreThanOnce1() {
        let attrString = NSAttributedString(string: "Hello 🌎, Hello World! Hello There!")
        let newAttrString = NSAttributedString(with: attrString, replacingOcurrencesOf: "Hello ", with: "")

        XCTAssertEqual(newAttrString, NSAttributedString(string: "🌎, World! There!"))
    }

    /// Tests that replacing ocurrences of a string that shows up more than once in the original
    /// string works.
    ///
    func testReplaceOcurrencesThatAppearMoreThanOnce2() {
        let attrString = NSAttributedString(string: "🌎🍎🍎😬🍎🌎")
        let newAttrString = NSAttributedString(with: attrString, replacingOcurrencesOf: "🍎", with: "💚")

        XCTAssertEqual(newAttrString, NSAttributedString(string: "🌎💚💚😬💚🌎"))
    }
}
