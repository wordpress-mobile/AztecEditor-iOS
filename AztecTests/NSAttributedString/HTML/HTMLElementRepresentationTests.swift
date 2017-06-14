import XCTest
@testable import Aztec

class HTMLElementRepresentationTests: XCTestCase {

    typealias Attribute = Libxml2.Attribute
    typealias ElementNode = Libxml2.ElementNode
    typealias StringAttribute = Libxml2.StringAttribute
    typealias StandardElementType = Libxml2.StandardElementType

    /// Tests creating an element representation for a <strong> node with no attributes.
    ///
    func testInit1() {
        let element = ElementNode(type: .strong)
        let elementRepresentation = HTMLElementRepresentation(for: element)

        XCTAssertEqual(elementRepresentation.name, StandardElementType.strong.rawValue)
        XCTAssertEqual(elementRepresentation.attributes.count, 0)
    }

    /// Tests creating an element representation for the following node:
    ///     <strong attr1 attr2=val2/>
    ///
    func testInit2() {
        let attrName1 = "attr1"
        let attrName2 = "attr2"
        let attrValue2 = "val2"

        let attributes = [Attribute(name: attrName1), StringAttribute(name: attrName2, value: attrValue2)]
        let element = ElementNode(type: .strong, attributes: attributes, children: [])
        let elementRepresentation = HTMLElementRepresentation(for: element)

        XCTAssertEqual(elementRepresentation.name, StandardElementType.strong.rawValue)

        guard elementRepresentation.attributes.count == 2 else {
            XCTFail()
            return
        }

        let attributeRepresentation1 = elementRepresentation.attributes[0]
        XCTAssertEqual(attributeRepresentation1.name, attrName1)
        XCTAssertNil(attributeRepresentation1.value)

        let attributeRepresentation2 = elementRepresentation.attributes[1]
        XCTAssertEqual(attributeRepresentation2.name, attrName2)
        XCTAssertEqual(attributeRepresentation2.value, attrValue2)
    }
}
