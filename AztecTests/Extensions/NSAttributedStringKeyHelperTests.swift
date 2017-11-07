import XCTest
@testable import Aztec

class NSAttributedStringKeyHelperTests: XCTestCase {

    /// Verifies that, given a collection of [NSAttributedStringKey: Any], `NSAttributedStringKey.convertToRaw(:)`  effectively converts
    /// all of the keys into Strings.
    ///
    func testConvertToRawReturnsANewCollectionContainingAllOfTheStringValues() {
        let input: [NSAttributedStringKey: Any] = [
            .strikethroughStyle: NSUnderlineStyle.styleSingle,
            .attachment: 222,
            NSAttributedStringKey("Custom"): 111
        ]

        let output = NSAttributedStringKey.convertToRaw(attributes: input)

        XCTAssertEqual(output[NSAttributedStringKey.strikethroughStyle.rawValue] as! NSUnderlineStyle, .styleSingle)
        XCTAssertEqual(output[NSAttributedStringKey.attachment.rawValue] as! Int, 222)
        XCTAssertEqual(output["Custom"] as! Int, 111)
    }


    /// Verifies that, given a collection of [String: Any], `NSAttributedStringKey.convertFromRaw(:)`  effectively converts
    /// all of the keys into NSAttributedStringKey instances.
    ///
    func testConvertFromRawReturnsANewCollectionContainingAttributedStringKeyInstances() {
        let input: [String: Any] = [
            NSAttributedStringKey.strikethroughStyle.rawValue: NSUnderlineStyle.styleSingle,
            NSAttributedStringKey.attachment.rawValue: 222,
            "Custom": 111
        ]

        let output = NSAttributedStringKey.convertFromRaw(attributes: input)

        XCTAssertEqual(output[.strikethroughStyle] as! NSUnderlineStyle, NSUnderlineStyle.styleSingle)
        XCTAssertEqual(output[.attachment] as! Int, 222)
        XCTAssertEqual(output[NSAttributedStringKey("Custom")] as! Int, 111)
    }
}
