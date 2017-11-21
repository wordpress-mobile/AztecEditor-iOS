import XCTest
@testable import Aztec


// MARK: - FontFormatter Tests
//
class FontFormatterTests: XCTestCase
{
    let boldFormatter = BoldFormatter()
    let italicFormatter = ItalicFormatter()

    func testApplyAttribute() {
        var attributes: [AttributedStringKey : Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        //test adding a non-existent testApplyAttribute
        attributes = boldFormatter.apply(to: attributes)
        //this should add a new attribute to it
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.containsTraits(.traitBold))

        //test addding a existent attribute
        attributes = boldFormatter.apply(to: attributes)
        // this shouldn't change anything in the attributes
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.containsTraits(.traitBold))

    }

    func testRemoveAttributes() {
        var attributes: [AttributedStringKey : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?

        //test removing a existent attribute
        attributes = boldFormatter.remove(from: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.containsTraits(.traitBold))

        attributes = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        //test removing a non-existent testApplyAttribute
        attributes = italicFormatter.remove(from: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.containsTraits(.traitBold))
    }

    func testPresentAttributes() {
        var attributes: [AttributedStringKey : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]

        //test when attribute is present
        XCTAssertTrue(boldFormatter.present(in: attributes))
        //test when attributes is not present
        XCTAssertFalse(italicFormatter.present(in: attributes))
        // apply attribute and check again
        attributes = italicFormatter.apply(to: attributes)
        XCTAssertTrue(italicFormatter.present(in: attributes))
    }
}
