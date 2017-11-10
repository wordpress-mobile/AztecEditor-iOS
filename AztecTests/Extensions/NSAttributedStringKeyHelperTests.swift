import XCTest
@testable import Aztec

class NSAttributedStringKeyHelperTests: XCTestCase {

    /// Verifies that, given a collection of [NSAttributedStringKey: Any], `AttributedStringKey.convertToRaw(:)`  effectively converts
    /// all of the keys into Strings.
    ///
    func testConvertToRawReturnsANewCollectionContainingAllOfTheStringValues() {
        let customKey = AttributedStringKey(key: "Custom")
        
        let input: [AttributedStringKey: Any] = [
            .strikethroughStyle: NSUnderlineStyle.styleSingle,
            .attachment: 222,
            customKey: 111
        ]

        let output = AttributedStringKey.convertToRaw(attributes: input)

        XCTAssertEqual(output[AttributedStringKey.strikethroughStyle.rawValue] as! NSUnderlineStyle, .styleSingle)
        XCTAssertEqual(output[AttributedStringKey.attachment.rawValue] as! Int, 222)
        XCTAssertEqual(output[customKey.rawValue] as! Int, 111)
    }


    /// Verifies that, given a collection of [String: Any], `AttributedStringKey.convertFromRaw(:)`  effectively converts
    /// all of the keys into NSAttributedStringKey instances.
    ///
    func testConvertFromRawReturnsANewCollectionContainingAttributedStringKeyInstances() {
        let customKey = AttributedStringKey(key: "Custom")
        
        let input: [String: Any] = [
            AttributedStringKey.strikethroughStyle.rawValue: NSUnderlineStyle.styleSingle,
            AttributedStringKey.attachment.rawValue: 222,
            customKey.rawValue: 111
        ]

        let output = AttributedStringKey.convertFromRaw(attributes: input)

        XCTAssertEqual(output[.strikethroughStyle] as! NSUnderlineStyle, NSUnderlineStyle.styleSingle)
        XCTAssertEqual(output[.attachment] as! Int, 222)
        XCTAssertEqual(output[customKey] as! Int, 111)
    }
}
