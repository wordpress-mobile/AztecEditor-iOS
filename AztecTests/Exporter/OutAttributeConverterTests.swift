import XCTest
@testable import Aztec
import libxml2

class OutAttributeConverterTests: XCTestCase {

    typealias Attribute = Libxml2.Attribute
    typealias StringAttribute = Libxml2.StringAttribute

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /// Tests a simple HTML.Attribute to xmlAttribute conversion
    ///
    func testSimpleConversion() {
        
        let name = "Attribute"
        let testAttribute = Attribute(name: name)
        let xmlAttribute = Libxml2.Out.AttributeConverter().convert(testAttribute)
        
        let xmlAttributeNameText = String(cString: xmlAttribute.pointee.name)
        XCTAssertEqual(name, xmlAttributeNameText)
        
        xmlFreeProp(xmlAttribute)
    }
        
    /// Tests a simple HTML.Attribute to xmlAttribute conversion
    ///
    func testStringAttributeConversion() {
        
        let name = "StringAttribute"
        let value = "StringAttributeValue"
        let testAttribute = StringAttribute(name: name, value: value)
        let xmlAttribute = Libxml2.Out.AttributeConverter().convert(testAttribute)
        
        let xmlAttributeNameText = String(cString: xmlAttribute.pointee.name)
        XCTAssertEqual(name, xmlAttributeNameText)

        let xmlAttributeValueNode = xmlAttribute.pointee.children.pointee
        let xmlNodeText = String(cString: xmlAttributeValueNode.content)
        XCTAssertEqual(value, xmlNodeText)
        
        xmlFreeProp(xmlAttribute)
    }
}
