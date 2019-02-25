import XCTest
@testable import Aztec

class NSAttributedStringKeyHelperTests: XCTestCase {

    /// Verifies that, given a collection of [NSAttributedStringKey: Any], `AttributedStringKey.convertToRaw(:)`  effectively converts
    /// all of the keys into Strings.
    ///
    func testConvertToRawReturnsANewCollectionContainingAllOfTheStringValues() {
        let customKey = NSAttributedString.Key("Custom")
        
        let input: [NSAttributedString.Key: Any] = [
            .strikethroughStyle: NSUnderlineStyle.single,
            .attachment: 222,
            customKey: 111
        ]

        let output = NSAttributedString.Key.convertToRaw(input)

        XCTAssertEqual(output[NSAttributedString.Key.strikethroughStyle.rawValue] as! NSUnderlineStyle, NSUnderlineStyle.single)
        XCTAssertEqual(output[NSAttributedString.Key.attachment.rawValue] as! Int, 222)
        XCTAssertEqual(output[customKey.rawValue] as! Int, 111)
    }


    /// Verifies that, given a collection of [String: Any], `AttributedStringKey.convertFromRaw(:)`  effectively converts
    /// all of the keys into NSAttributedStringKey instances.
    ///
    func testConvertFromRawReturnsANewCollectionContainingAttributedStringKeyInstances() {
        let customKey = NSAttributedString.Key("Custom")
        
        let input: [String: Any] = [
            NSAttributedString.Key.strikethroughStyle.rawValue: NSUnderlineStyle.single,
            NSAttributedString.Key.attachment.rawValue: 222,
            customKey.rawValue: 111
        ]

        let output = NSAttributedString.Key.convertFromRaw(input)

        XCTAssertEqual(output[.strikethroughStyle] as! NSUnderlineStyle, NSUnderlineStyle.single)
        XCTAssertEqual(output[.attachment] as! Int, 222)
        XCTAssertEqual(output[customKey] as! Int, 111)
    }
}
