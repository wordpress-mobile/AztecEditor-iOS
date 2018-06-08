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
    
    func testGalleryElementConverterWithOnlyOrder() {
        let orderValues = ["asc", "Desc"]
        
        for orderValue in orderValues {
            let expected = GalleryAttachment.Order(rawValue: orderValue)
            
            let attributes = [Attribute(name: "orderby", value: .string(orderValue))]
            let element = ElementNode(type: .gallery, attributes: attributes)
            
            let (gallery, _) = converter.convert(element, inheriting: [:]) { (node, attributes) -> NSAttributedString in
                return NSAttributedString()
            }
            
            XCTAssertNil(gallery.columns)
            XCTAssertNil(gallery.ids)
            XCTAssertEqual(gallery.order, expected)
            XCTAssertNil(gallery.orderBy)
        }
    }
    
    func testGalleryElementConverterWithOnlyOrderBy() {
        let orderByValues = ["menu_order", "title", "post_date", "rand"]
        
        for orderByValue in orderByValues {
            let expected = GalleryAttachment.OrderBy(rawValue: orderByValue)
            
            let attributes = [Attribute(name: "orderby", value: .string(orderByValue))]
            let element = ElementNode(type: .gallery, attributes: attributes)
            
            let (gallery, _) = converter.convert(element, inheriting: [:]) { (node, attributes) -> NSAttributedString in
                return NSAttributedString()
            }
            
            XCTAssertNil(gallery.columns)
            XCTAssertNil(gallery.ids)
            XCTAssertNil(gallery.order)
            XCTAssertEqual(gallery.orderBy, expected)
        }
    }
}
