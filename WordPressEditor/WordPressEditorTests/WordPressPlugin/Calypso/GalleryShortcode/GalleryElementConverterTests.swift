import Aztec
import XCTest
@testable import WordPressEditor

class GalleryElementConverterTests: XCTestCase {
    
    let converter = GalleryElementConverter()
    
    func testGalleryElementConverterWithOnlyColumns() {
        let attributes = [Attribute(name: "columns", value: .string("4"))]
        let element = ElementNode(type: .gallery, attributes: attributes)
        
        let (gallery, _) = converter.convert(element, inheriting: [:]) { (elementNode, intrinsicRepresentation, attributes, before) -> NSAttributedString in
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
        
        let (gallery, _) = converter.convert(element, inheriting: [:]) { (elementNode, intrinsicRepresentation, attributes, before) -> NSAttributedString in
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
            
            let (gallery, _) = converter.convert(element, inheriting: [:]) { (elementNode, intrinsicRepresentation, attributes, before) -> NSAttributedString in
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
            
            let (gallery, _) = converter.convert(element, inheriting: [:]) { (elementNode, intrinsicRepresentation, attributes, before) -> NSAttributedString in
                return NSAttributedString()
            }
            
            XCTAssertNil(gallery.columns)
            XCTAssertNil(gallery.ids)
            XCTAssertNil(gallery.order)
            XCTAssertEqual(gallery.orderBy, expected)
        }
    }
    
    func testGalleryElementConverterWithSeveralValues() {
        let orderValues = ["asc", "Desc"]
        let orderByValues = ["menu_order", "title", "post_date", "rand"]
        
        for orderValue in orderValues {
            for orderByValue in orderByValues {
                let expectedColumns = 150
                let expectedIDs = [1, 55, 2, 7, 90]
                let expectedOrder = GalleryAttachment.Order(rawValue: orderValue)
                let expectedOrderBy = GalleryAttachment.OrderBy(rawValue: orderByValue)
                
                let columnsAttribute = Attribute(name: "COLUMNS", value: .string("150"))
                let idsAttribute = Attribute(name: "ids", value: .string("1, 55,2 ,7, 90"))
                let orderAttribute = Attribute(name: "ordEr", value: .string(orderValue))
                let orderByAttribute = Attribute(name: "orderby", value: .string(orderByValue))
                let attributes = [columnsAttribute, idsAttribute, orderAttribute, orderByAttribute]
                let element = ElementNode(type: .gallery, attributes: attributes)
                
                let (gallery, _) = converter.convert(element, inheriting: [:]) { (elementNode, intrinsicRepresentation, attributes, intrinsicRepresentationBeforeChildren) -> NSAttributedString in
                    return NSAttributedString()
                }
                
                XCTAssertEqual(gallery.columns, expectedColumns)
                XCTAssertEqual(gallery.ids, expectedIDs)
                XCTAssertEqual(gallery.order, expectedOrder)
                XCTAssertEqual(gallery.orderBy, expectedOrderBy)
            }
        }
    }
}
