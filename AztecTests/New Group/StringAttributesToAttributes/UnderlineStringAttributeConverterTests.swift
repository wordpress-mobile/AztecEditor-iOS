import XCTest
@testable import Aztec

class UnderlineStringAttributeConverterTests: XCTestCase {
    
    let converter = UnderlineStringAttributeConverter()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUnderlineConversion() {
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.underlineStyle] = NSNumber(value: 1)
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let uElement = elementNodes[0]
        XCTAssertEqual(uElement.type, .u)
        XCTAssertEqual(uElement.attributes.count, 0)
    }
    
    func testUnderlineConversionWithElementAggregation() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let existingElements = [
            ElementNode(type: .u, attributes: [exampleAttribute], children: []),
            ElementNode(type: .strong),
            ]
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.underlineStyle] = NSNumber(value: 1)
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: existingElements)
        
        XCTAssertEqual(elementNodes.count, 2)
        
        let uElement = elementNodes[0]
        XCTAssertEqual(uElement.type, .u)
        XCTAssertEqual(uElement.attributes.count, 1)
        XCTAssertEqual(uElement.attributes[0], exampleAttribute)
        
        let strongElement = elementNodes[1]
        XCTAssertEqual(strongElement.type, .strong)
        XCTAssertEqual(strongElement.attributes.count, 0)
    }
    
    
    func testUnderlineConversionWithElementRepresentation() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let element = ElementNode(type: .u, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.underlineStyle] = NSNumber(value: 1)
        attributes[.underlineHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let uElement = elementNodes[0]
        XCTAssertEqual(uElement.type, .u)
        XCTAssertEqual(uElement.attributes.count, 1)
        XCTAssertEqual(uElement.attributes[0], exampleAttribute)
    }
    
    
    func testUnderlineConversionWithElementRepresentation2() {
        let cssAttribute = CSSAttribute.underline
        let exampleAttribute = Attribute(type: .style, value: .inlineCss([cssAttribute]))
        let element = ElementNode(type: .span, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.underlineStyle] = NSNumber(value: 1)
        attributes[.underlineHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let spanElement = elementNodes[0]
        XCTAssertEqual(spanElement.type, .span)
        XCTAssertEqual(spanElement.attributes.count, 1)
        XCTAssertEqual(spanElement.attributes[0], exampleAttribute)
    }
}
