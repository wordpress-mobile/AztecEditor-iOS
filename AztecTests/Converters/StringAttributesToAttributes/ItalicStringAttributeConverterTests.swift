import XCTest
@testable import Aztec

class ItalicStringAttributeConverterTests: XCTestCase {
    
    let converter = ItalicStringAttributeConverter()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testItalicConversion() {
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.italicSystemFont(ofSize: 14)
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        guard let emElement = elementNodes.first else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(emElement.type, .em)
        XCTAssertEqual(emElement.attributes.count, 0)
    }
    
    func testItalicConversionWithElementAggregation() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let existingElements = [
            ElementNode(type: .em, attributes: [exampleAttribute], children: []),
            ElementNode(type: .strong),
            ]
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.italicSystemFont(ofSize: 14)
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: existingElements)
        
        XCTAssertEqual(elementNodes.count, 2)
        
        let emElement = elementNodes[0]
        XCTAssertEqual(emElement.type, .em)
        XCTAssertEqual(emElement.attributes.count, 1)
        XCTAssertEqual(emElement.attributes[0], exampleAttribute)
        
        let strongElement = elementNodes[1]
        XCTAssertEqual(strongElement.type, .strong)
        XCTAssertEqual(strongElement.attributes.count, 0)
    }
    
    
    func testItalicConversionWithElementRepresentation() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let element = ElementNode(type: .em, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.italicSystemFont(ofSize: 14)
        attributes[.italicHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let emElement = elementNodes[0]
        XCTAssertEqual(emElement.type, .em)
        XCTAssertEqual(emElement.attributes.count, 1)
        XCTAssertEqual(emElement.attributes[0], exampleAttribute)
    }
    

    func testItalicConversionWithElementRepresentation2() {
        let cssAttribute = CSSAttribute.italic
        let exampleAttribute = Attribute(type: .style, value: .inlineCss([cssAttribute]))
        let element = ElementNode(type: .span, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        attributes[.font] = UIFont.italicSystemFont(ofSize: 14)
        attributes[.italicHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let spanElement = elementNodes[0]
        XCTAssertEqual(spanElement.type, .span)
        XCTAssertEqual(spanElement.attributes.count, 1)
        XCTAssertEqual(spanElement.attributes[0], exampleAttribute)
    }
    
    func testItalicConversionWithEquivalentElementRepresentation() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let element = ElementNode(type: .i, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        var font = UIFont.systemFont(ofSize: 14)
        font = font.modifyTraits([.traitItalic], enable: true)
        
        attributes[.font] = font
        attributes[.italicHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let elementNode = elementNodes[0]
        XCTAssertEqual(elementNode.type, .i)
        XCTAssertEqual(elementNode.attributes.count, 1)
        XCTAssertEqual(elementNode.attributes[0], exampleAttribute)
    }
    
    func testItalicConversionWithEquivalentElementRepresentation2() {
        let exampleAttribute = Attribute(type: .style, value: .string("someStyle"))
        let element = ElementNode(type: .em, attributes: [exampleAttribute], children: [])
        let elementRepresentation = HTMLElementRepresentation(element)
        var attributes = [NSAttributedString.Key: Any]()
        
        var font = UIFont.systemFont(ofSize: 14)
        font = font.modifyTraits([.traitItalic], enable: true)
        
        attributes[.font] = font
        attributes[.italicHtmlRepresentation] = HTMLRepresentation(for: .element(elementRepresentation))
        
        let elementNodes = converter.convert(attributes: attributes, andAggregateWith: [])
        
        XCTAssertEqual(elementNodes.count, 1)
        
        let elementNode = elementNodes[0]
        XCTAssertEqual(elementNode.type, .em)
        XCTAssertEqual(elementNode.attributes.count, 1)
        XCTAssertEqual(elementNode.attributes[0], exampleAttribute)
    }
}
