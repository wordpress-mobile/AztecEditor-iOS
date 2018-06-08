import Aztec
import XCTest
@testable import WordPressEditor

class GalleryElementConverterTests: XCTestCase {
    
    let converter = GalleryElementConverter()
    
    func testGalleryElementConverterWithOnlyColumns() {
        let attributes = [Attribute(name: "columns", value: .string("4"))]
        let element = ElementNode(type: .gallery, attributes: attributes)
        
        let (gallery, _) = converter.convert(element, inheriting: [:]) { (node, attributes) -> NSAttributedString in
            return NSAttributedString()
        }
        
        XCTAssertEqual(gallery.columns, 4)
        XCTAssertNil(gallery.ids)
        XCTAssertNil(gallery.order)
        XCTAssertNil(gallery.orderBy)
    }
    
    func testGalleryElementConverterWithOnlyIDs() {
        let attributes = [Attribute(name: "iDs", value: .string("4, 2, 6,8"))]
        let element = ElementNode(type: .gallery, attributes: attributes)
        
        let (gallery, _) = converter.convert(element, inheriting: [:]) { (node, attributes) -> NSAttributedString in
            return NSAttributedString()
        }
        
        XCTAssertNil(gallery.columns)
        XCTAssertEqual(gallery.ids, [4,2,6,8])
        XCTAssertNil(gallery.order)
        XCTAssertNil(gallery.orderBy)
    }
}
