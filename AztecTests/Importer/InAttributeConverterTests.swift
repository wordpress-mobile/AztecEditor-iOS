import XCTest
@testable import Aztec
import libxml2

class InAttributesConverterTests: XCTestCase {

    /// Tests that the name in xmlAttr is maintained in a conversion to HTML.Attribute.
    ///
    func testNameConversion() {

        let name = "Attribute"
        let nameCStr = name.cString(using: String.Encoding.utf8)!
        let namePtr = UnsafePointer<xmlChar>(OpaquePointer(nameCStr))

        var xmlAttribute = xmlAttr()
        xmlAttribute.name = namePtr

        let converter = InAttributeConverter()

        let attribute = converter.convert(xmlAttribute)

        XCTAssertEqual(name, attribute.name)
    }

    /// Tests that a string xmlAttr is properly stored
    ///
    func testStringAttributeConversion() {

        let name = "StringAttribute"
        let nameCStr = name.cString(using: String.Encoding.utf8)!
        let namePtr = UnsafePointer<xmlChar>(OpaquePointer(nameCStr))

        let value = "Value"
        let valueCStr = value.cString(using: String.Encoding.utf8)!
        let valuePtr = UnsafeMutablePointer<xmlChar>(OpaquePointer(valueCStr))

        var node = xmlNode()
        node.content = valuePtr

        var xmlAttribute = xmlAttr()
        xmlAttribute.name = namePtr
        xmlAttribute.children = withUnsafeMutablePointer(to: &node) {UnsafeMutablePointer<xmlNode>($0)}

        let converter = InAttributeConverter()

        let attribute = converter.convert(xmlAttribute)

        XCTAssertEqual(attribute.value.toString(), value)
    }
}
