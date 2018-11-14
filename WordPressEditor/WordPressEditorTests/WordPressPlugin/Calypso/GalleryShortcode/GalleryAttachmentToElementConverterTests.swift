import Aztec
import XCTest
@testable import WordPressEditor

class GalleryAttachmentToElementConverterTests: XCTestCase {
    
    let converter = GalleryAttachmentToElementConverter()
    
    func testGalleryElementConverterWithOnlyColumns() {
        
        let expectedIds = "4,5"
        let expectedColumns = "2"
        let expectedOrder = GalleryAttachment.Order.asc.rawValue
        let expectedOrderBy = GalleryAttachment.OrderBy.menu.rawValue
        
        let attachment = GalleryAttachment(identifier: "testing")
        let extraAttributeName = "extraAttribute"
        let extraAttributeValue = "extraAttributeValue"
        
        attachment.ids = [4, 5]
        attachment.columns = 2
        attachment.order = .asc
        attachment.orderBy = .menu
        attachment.extraAttributes[extraAttributeName] = .string(extraAttributeValue)
        
        guard let element = converter.convert(attachment, attributes: [:]).first as? ElementNode else {
            XCTFail()
            return
        }
        XCTAssertEqual(element.type, .gallery)
        
        let outputIds = element.attribute(named: GallerySupportedAttribute.ids.rawValue)?.value.toString()
        XCTAssertEqual(outputIds, expectedIds)
        
        let outputColumns = element.attribute(named: GallerySupportedAttribute.columns.rawValue)?.value.toString()
        XCTAssertEqual(outputColumns, expectedColumns)
        
        let outputOrder = element.attribute(named: GallerySupportedAttribute.order.rawValue)?.value.toString()
        XCTAssertEqual(outputOrder, expectedOrder)
        
        let outputOrderBy = element.attribute(named: GallerySupportedAttribute.orderBy.rawValue)?.value.toString()
        XCTAssertEqual(outputOrderBy, expectedOrderBy)
        
        let outputExtraAttribute = element.attribute(named: extraAttributeName)?.value.toString()
        XCTAssertEqual(outputExtraAttribute, extraAttributeValue)
    }
}
