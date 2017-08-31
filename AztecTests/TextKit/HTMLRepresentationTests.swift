import XCTest
@testable import Aztec


// MARK: - HTMLRepresentationTests
//
class HTMLRepresentationTests: XCTestCase {

    /// Verifies that HTMLRepresentation of Attribute kind is properly serialized Back and Forth
    ///
    func testAttibuteRepresentationGetsProperlySerializedAndRestored() {
        let representation = HTMLRepresentation(for: .attribute(sampleAttribute))
        let regenerated = regenerate(representation: representation)

        guard case let .attribute(attribute) = regenerated.kind else {
            XCTFail()
            return
        }

        XCTAssert(attribute == sampleAttribute)
    }

    /// Verifies that HTMLRepresentation of Element kind is properly serialized Back and Forth
    ///
    func testElementRepresentationGetsProperlySerializedAndRestored() {
        let representation = HTMLRepresentation(for: .element(sampleElement))
        let regenerated = regenerate(representation: representation)

        guard case let .element(element) = regenerated.kind else {
            XCTFail()
            return
        }

        XCTAssert(element == sampleElement)
    }

    /// Verifies that HTMLRepresentation of inlineCSS kind is properly serialized Back and Forth
    ///
    func testCssRepresentationGetsProperlySerializedAndRestored() {
        let representation = HTMLRepresentation(for: .inlineCss(sampleCSS))
        let regenerated = regenerate(representation: representation)

        guard case let .inlineCss(css) = regenerated.kind else {
            XCTFail()
            return
        }

        XCTAssert(css == sampleCSS)
    }

}


// MARK: - Private Helpers
//
private extension HTMLRepresentationTests {

    var sampleCSS: CSSAttribute {
        return CSSAttribute(name: "some", value: "thing")
    }

    var sampleAttribute: Attribute {
        return Attribute(name: "css", value: .inlineCss([sampleCSS]))
    }

    var sampleElement: HTMLElementRepresentation {
        return HTMLElementRepresentation(name: "table", attributes: [sampleAttribute])
    }

    func regenerate(representation: HTMLRepresentation) -> HTMLRepresentation {
        let data = NSKeyedArchiver.archivedData(withRootObject: representation)
        guard let restored = NSKeyedUnarchiver.unarchiveObject(with: data) as? HTMLRepresentation else {
            fatalError()
        }

        return restored
    }
}
