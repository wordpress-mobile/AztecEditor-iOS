import XCTest
@testable import Aztec
import libxml2

class InAttributesConverterTests: XCTestCase {

    typealias HTML = Libxml2.HTML

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
        let nameCStr = name.cStringUsingEncoding(NSUTF8StringEncoding)!
        let namePtr = UnsafePointer<xmlChar>(nameCStr)

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
        let nameCStr = name.cStringUsingEncoding(NSUTF8StringEncoding)!
        let namePtr = UnsafePointer<xmlChar>(nameCStr)

        let value = "Value"
        let valueCStr = value.cStringUsingEncoding(NSUTF8StringEncoding)!
        let valuePtr = UnsafeMutablePointer<xmlChar>(valueCStr)

        var node = xmlNode()
        node.content = valuePtr

        var xmlAttribute = xmlAttr()
        xmlAttribute.name = namePtr
        xmlAttribute.children = withUnsafeMutablePointer(&node) {UnsafeMutablePointer<xmlNode>($0)}

        let converter = Libxml2.In.AttributeConverter()

        let attribute = converter.convert(xmlAttribute)

        XCTAssertEqual(String(attribute.dynamicType), String(HTML.StringAttribute.self))
    }
}