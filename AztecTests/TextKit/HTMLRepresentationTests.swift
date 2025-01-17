import XCTest
@testable import Aztec


// MARK: - HTMLRepresentationTests
//
class HTMLRepresentationTests: XCTestCase {

    /// Verifies that HTMLRepresentation of Attribute kind is properly serialized Back and Forth
    ///
    func testAttibuteRepresentationGetsProperlySerializedAndRestored() throws {
        let representation = HTMLRepresentation(for: .attribute(sampleAttribute))
        let regenerated = try regenerate(representation: representation)

        guard case let .attribute(attribute) = regenerated.kind else {
            XCTFail()
            return
        }

        XCTAssert(attribute == sampleAttribute)
    }

    /// Verifies that HTMLRepresentation of Element kind is properly serialized Back and Forth
    ///
    func testElementRepresentationGetsProperlySerializedAndRestored() throws {
        let representation = HTMLRepresentation(for: .element(sampleElement))
        let regenerated = try regenerate(representation: representation)

        guard case let .element(element) = regenerated.kind else {
            XCTFail()
            return
        }

        XCTAssert(element == sampleElement)
    }

    /// Verifies that HTMLRepresentation of inlineCSS kind is properly serialized Back and Forth
    ///
    func testCssRepresentationGetsProperlySerializedAndRestored() throws {
        let representation = HTMLRepresentation(for: .inlineCss(sampleCSS))
        let regenerated = try regenerate(representation: representation)

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
        return Attribute(type: .style, value: .inlineCss([sampleCSS]))
    }

    var sampleElement: HTMLElementRepresentation {
        return HTMLElementRepresentation(name: "table", attributes: [sampleAttribute])
    }

    func regenerate(representation: HTMLRepresentation) throws -> HTMLRepresentation {
        let data = try NSKeyedArchiver.archivedData(withRootObject: representation, requiringSecureCoding: false)
        let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: HTMLRepresentation.self, from: data)

        return restored!
    }
}
