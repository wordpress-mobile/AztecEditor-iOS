import XCTest
@testable import Aztec

class NSAttributedStringKeyHelperTests: XCTestCase {

    /// Verifies that, given a collection of [NSAttributedStringKey: Any], `AttributedStringKey.convertToRaw(:)`  effectively converts
    /// all of the keys into Strings.
    ///
    func testConvertToRawReturnsANewCollectionContainingAllOfTheStringValues() {
        let customKey = NSAttributedStringKey("Custom")
        
        let input: [NSAttributedStringKey: Any] = [
            .strikethroughStyle: NSUnderlineStyle.styleSingle,
            .attachment: 222,
            customKey: 111
        ]

        let output = NSAttributedStringKey.convertToRaw(input)

        XCTAssertEqual(output[NSAttributedStringKey.strikethroughStyle.rawValue] as! NSUnderlineStyle, .styleSingle)
        XCTAssertEqual(output[NSAttributedStringKey.attachment.rawValue] as! Int, 222)
        XCTAssertEqual(output[customKey.rawValue] as! Int, 111)
    }


    /// Verifies that, given a collection of [String: Any], `AttributedStringKey.convertFromRaw(:)`  effectively converts
    /// all of the keys into NSAttributedStringKey instances.
    ///
    func testConvertFromRawReturnsANewCollectionContainingAttributedStringKeyInstances() {
        let customKey = NSAttributedStringKey("Custom")
        
        let input: [String: Any] = [
            NSAttributedStringKey.strikethroughStyle.rawValue: NSUnderlineStyle.styleSingle,
            NSAttributedStringKey.attachment.rawValue: 222,
            customKey.rawValue: 111
        ]

        let output = NSAttributedStringKey.convertFromRaw(input)

        XCTAssertEqual(output[.strikethroughStyle] as! NSUnderlineStyle, NSUnderlineStyle.styleSingle)
        XCTAssertEqual(output[.attachment] as! Int, 222)
        XCTAssertEqual(output[customKey] as! Int, 111)
    }
}
