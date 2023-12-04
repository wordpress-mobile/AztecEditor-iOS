import XCTest
@testable import Aztec

class UnderlineElementToAttributeConverterTests: XCTestCase {
    
    let converter = UnderlineElementAttributesConverter()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - EditorView Properties
    
    func testSimpleUnderlineConversion() {
        
        let cssAttribute = CSSAttribute.underline
        let attribute = Attribute(type: .style, value: .inlineCss([cssAttribute]))
        let stringAttributes: [NSAttributedString.Key: Any] = [:]
        
        let finalAttributes = converter.convert(attribute, inheriting: stringAttributes)
        
        guard let underline = finalAttributes[.underlineStyle] as? NSNumber else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(underline, 1)
    }
    
    func testSimpleNonUnderlineConversion() {
        
        let cssAttribute = CSSAttribute.bold
        let attribute = Attribute(type: .style, value: .inlineCss([cssAttribute]))
        let stringAttributes: [NSAttributedString.Key: Any] = [:]
        
        let finalAttributes = converter.convert(attribute, inheriting: stringAttributes)
        let underline = finalAttributes[.underlineStyle] as? NSNumber
        
        XCTAssertNil(underline)
    }
}
