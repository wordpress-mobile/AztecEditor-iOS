import XCTest
@testable import Aztec

class ShadowBoldFormatterTests: XCTestCase {

    private let shadowBoldFormatter = ShadowBoldFormatter()
    
    func testApplyAttributesOnHeading() {
        var attributes: [NSAttributedStringKey : Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        attributes[.headingRepresentation] = Header.HeaderType.h1.rawValue
        attributes = shadowBoldFormatter.apply(to: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertNotNil(attributes[.shadow])
        XCTAssertNotNil(attributes[.kern])
    }
    
    func testApplyAttributesOnNonHeading() {
        var attributes: [NSAttributedStringKey : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        attributes = shadowBoldFormatter.apply(to: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.containsTraits(.traitBold))
        XCTAssertNil(attributes[.shadow])
        XCTAssertNil(attributes[.kern])
    }

    func testRemoveAttributesOnHeading() {
        var attributes: [NSAttributedStringKey : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        attributes[.headingRepresentation] = Header.HeaderType.h1.rawValue

        //test removing a existent attribute
        attributes = shadowBoldFormatter.remove(from: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertTrue(font!.containsTraits(.traitBold)) //we should keep bold trait for hedings
        XCTAssertNil(attributes[.shadow])
        XCTAssertNil(attributes[.kern])
    }

    func testRemoveAttributesOnNonHeading() {
        var attributes: [NSAttributedStringKey : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        var font: UIFont?
        attributes = shadowBoldFormatter.remove(from: attributes)
        font = attributes[.font] as? UIFont
        XCTAssertNotNil(font)
        XCTAssertFalse(font!.containsTraits(.traitBold))
        XCTAssertNil(attributes[.shadow])
        XCTAssertNil(attributes[.kern])
    }
    
    func testPresentAttributesOnHeading() {
        var attributes: [NSAttributedStringKey : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        attributes[.headingRepresentation] = Header.HeaderType.h1.rawValue
        XCTAssertFalse(shadowBoldFormatter.present(in: attributes))
        attributes[.shadow] = NSShadow()
        XCTAssertTrue(shadowBoldFormatter.present(in: attributes))
    }
    
    func testPresentAttributesOnNonHeading() {
        var attributes: [NSAttributedStringKey : Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
        XCTAssertTrue(shadowBoldFormatter.present(in: attributes))
        attributes = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        XCTAssertFalse(shadowBoldFormatter.present(in: attributes))
    }
}
