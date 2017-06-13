import XCTest
@testable import Aztec

class HTMLAttributeRepresentationTests: XCTestCase {

    typealias Attribute = Libxml2.Attribute
    typealias StringAttribute = Libxml2.StringAttribute

    /// Tests creating an element representation for an attribute with no value
    ///
    func testInit1() {
        let name = "attr"

        let attribute = Attribute(name: name)
        let attributeRepresentation = HTMLAttributeRepresentation(for: attribute)

        XCTAssertEqual(attributeRepresentation.name, name)
        XCTAssertNil(attributeRepresentation.value)
    }

    /// Tests creating an element representation for an attribute with a value
    ///
    func testInit2() {
        let name = "attr"
        let value = "val"

        let attribute = StringAttribute(name: name, value: value)
        let attributeRepresentation = HTMLAttributeRepresentation(for: attribute)

        XCTAssertEqual(attributeRepresentation.name, name)
        XCTAssertEqual(attributeRepresentation.value, value)
    }
}
