import XCTest
@testable import Aztec

class BoldFormatterTests: XCTestCase {

    private let boldFormatter = BoldWithShadowForHeadingFormatter()
    
    func testApplyAttributesOnHeading() {
        var attributes: [NSAttributedString.Key : Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        attributes[.headingRepresentation] = Header.HeaderType.h1.rawValue
        attributes = boldFormatter.apply(to: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertNotNil(attributes[.shadow])
        XCTAssertNotNil(attributes[.kern])
    }
    
    func testApplyAttributesOnNonHeading() {
        var attributes: [NSAttributedString.Key : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        attributes = boldFormatter.apply(to: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.containsTraits(.traitBold))
        XCTAssertNil(attributes[.shadow])
        XCTAssertNil(attributes[.kern])
    }

    func testRemoveAttributesOnHeading() {
        var attributes: [NSAttributedString.Key : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        attributes[.headingRepresentation] = Header.HeaderType.h1.rawValue

        //test removing a existent attribute
        attributes = boldFormatter.remove(from: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.containsTraits(.traitBold)) //we should keep bold trait for hedings
        XCTAssertNil(attributes[.shadow])
        XCTAssertNil(attributes[.kern])
    }

    func testRemoveAttributesOnNonHeading() {
        var attributes: [NSAttributedString.Key : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        attributes = boldFormatter.remove(from: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.containsTraits(.traitBold))
        XCTAssertNil(attributes[.shadow])
        XCTAssertNil(attributes[.kern])
    }
    
    func testPresentAttributesOnHeading() {
        var attributes: [NSAttributedString.Key : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        attributes[.headingRepresentation] = Header.HeaderType.h1.rawValue
        XCTAssertFalse(boldFormatter.present(in: attributes))
        attributes[.shadow] = NSShadow()
        XCTAssertTrue(boldFormatter.present(in: attributes))
    }
    
    func testPresentAttributesOnNonHeading() {
        var attributes: [NSAttributedString.Key : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        XCTAssertTrue(boldFormatter.present(in: attributes))
        attributes = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        XCTAssertFalse(boldFormatter.present(in: attributes))
    }
}
