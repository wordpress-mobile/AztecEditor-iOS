import XCTest
@testable import Aztec
import libxml2

class OutAttributeConverterTests: XCTestCase {

    typealias Attribute = Libxml2.HTML.Attribute
    typealias StringAttribute = Libxml2.HTML.StringAttribute

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
        
        let xmlAttributeNameText = String(CString: UnsafePointer<Int8>(xmlAttribute.memory.name), encoding: NSUTF8StringEncoding)
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
        
        let xmlAttributeNameText = String(CString: UnsafePointer<Int8>(xmlAttribute.memory.name), encoding: NSUTF8StringEncoding)
        XCTAssertEqual(name, xmlAttributeNameText)

        let xmlAttributeValueNode = xmlAttribute.memory.children.memory
        let xmlNodeText = String(CString: UnsafeMutablePointer<Int8>(xmlAttributeValueNode.content), encoding: NSUTF8StringEncoding)
        XCTAssertEqual(value, xmlNodeText)
        
        xmlFreeProp(xmlAttribute)
    }
}