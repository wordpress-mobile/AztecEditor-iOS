import Aztec
import XCTest
@testable import WordPressEditor

class GalleryElementToTagConverterTests: XCTestCase {
    
    let converter = GalleryElementToTagConverter()
    
    func testGalleryElementConverterWithOnlyColumns() {
        let attributes = [
            Attribute(name: "columns", value: .string("4")),
            Attribute(name: "ids", value: .string("4, 5, 6, 7"))
        ]
        let element = ElementNode(type: .gallery, attributes: attributes)
        
        let (tag, _) = converter.convert(element)
        
        XCTAssertEqual(tag, "[gallery columns=\"4\" ids=\"4, 5, 6, 7\"]")
    }
}
