import Foundation
import XCTest
@testable import Aztec

class NSMutableAttributedStringParagraphPropertyTests: XCTestCase {
    
    let sampleAttributes: [NSAttributedStringKey : Any] = [
        .font: UIFont.systemFont(ofSize: UIFont.systemFontSize),
        .paragraphStyle: NSParagraphStyle()
    ]
    /// Verifies that Images with *Styled* caption fields get properly converted into their corresponding HTML
    ///
    /// - Input: Image Attachment, with a caption in Bold + Italics.
    ///
    /// - Output: <figure><img src="."><figcaption><strong><em>Bold and Italics</em></strong></figcaption></figure>
    ///
    func testAppendProperty() {
        let string = NSMutableAttributedString(string: "Hello world!", attributes: sampleAttributes)
        
        string.append(paragraphProperty: Figure())
        
        guard let paragraphStyle = string.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? ParagraphStyle else {
            XCTFail() // Expected a ParagraphStyle object.
            return
        }
        
        XCTAssert(paragraphStyle.hasProperty(where: { $0 is Figure }))
    }
}
