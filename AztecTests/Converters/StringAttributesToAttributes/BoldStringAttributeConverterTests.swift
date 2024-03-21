import XCTest
@testable import Aztec

class BoldStringAttributeConverterTests: XCTestCase {
    
    let converter = BoldStringAttributeConverter()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBoldConversion() {
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.boldSystemFont(ofSize: 14)
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        guard let strongElement = elementNodes.first else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(strongElement.type, .strong)
        XCTAssertEqual(strongElement.attributes.count, 0)
    }
    
    func testBoldConversionWithElementAggregation() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let existingElements = [
            ElementNode(type: .em),
            ElementNode(type: .strong, attributes: [exampleAttribute], children: []),
        ]
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.boldSystemFont(ofSize: 14)
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: existingElements)
        
        XCTAssertEqual(elementNodes.count, 2)
        
        let emElement = elementNodes[0]
        XCTAssertEqual(emElement.type, .em)
        XCTAssertEqual(emElement.attributes.count, 0)
        
        let strongElement = elementNodes[1]
        XCTAssertEqual(strongElement.type, .strong)
        XCTAssertEqual(strongElement.attributes.count, 1)
        XCTAssertEqual(strongElement.attributes[0], exampleAttribute)
    }
    

    func testBoldConversionWithElementRepresentation() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let element = ElementNode(type: .strong, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.boldSystemFont(ofSize: 14)
        attributes[.boldHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let strongElement = elementNodes[0]
        XCTAssertEqual(strongElement.type, .strong)
        XCTAssertEqual(strongElement.attributes.count, 1)
        XCTAssertEqual(strongElement.attributes[0], exampleAttribute)
    }
    
    func testBoldConversionWithEquivalentElementRepresentation() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let element = ElementNode(type: .b, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.boldSystemFont(ofSize: 14)
        attributes[.boldHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let strongElement = elementNodes[0]
        XCTAssertEqual(strongElement.type, .b)
        XCTAssertEqual(strongElement.attributes.count, 1)
        XCTAssertEqual(strongElement.attributes[0], exampleAttribute)
    }

    func testBoldConversionWithElementRepresentation2() {
        let cssAttribute = CSSAttribute.italic
        let exampleAttribute = Attribute(type: .style, value: .inlineCss([cssAttribute]))
        let element = ElementNode(type: .span, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.italicSystemFont(ofSize: 14)
        attributes[.boldHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let spanElement = elementNodes[0]
        XCTAssertEqual(spanElement.type, .span)
        XCTAssertEqual(spanElement.attributes.count, 1)
        XCTAssertEqual(spanElement.attributes[0], exampleAttribute)
    }
}
