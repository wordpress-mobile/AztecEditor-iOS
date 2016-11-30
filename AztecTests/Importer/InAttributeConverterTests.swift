import XCTest
@testable import Aztec
import libxml2

class InAttributesConverterTests: XCTestCase {

    typealias HTML = Libxml2

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /// Tests that the name in xmlAttr is maintained in a conversion to HTML.Attribute.
    ///
    func testNameConversion() {

        let name = "Attribute"
        let nameCStr = name.cString(using: String.Encoding.utf8)!
        let namePtr = UnsafePointer<xmlChar>(OpaquePointer(nameCStr))

        var xmlAttribute = xmlAttr()
        xmlAttribute.name = namePtr

        let converter = Libxml2.In.AttributeConverter()

        let attribute = converter.convert(xmlAttribute)

        XCTAssertEqual(name, attribute.name)
    }

    /// Tests that a string xmlAttr is properly converted into an HTML.StringAttribute object.
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

        let converter = Libxml2.In.AttributeConverter()

        let attribute = converter.convert(xmlAttribute)

        XCTAssertTrue(attribute is HTML.StringAttribute)
    }
}
