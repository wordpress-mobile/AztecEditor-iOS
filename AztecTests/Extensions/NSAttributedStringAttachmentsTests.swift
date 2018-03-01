import Foundation
import XCTest
@testable import Aztec


// MARK: - NSAttributedStringAttachmentTests
//
class NSAttributedStringAttachmentTests: XCTestCase {
    
    let wpLogoAttachment = ImageAttachment(identifier: "wplogo", url: URL(string: "https://s.w.org/about/images/logos/wordpress-logo-32-blue.png"))
    
    /// Verifies looking for caption ranges from an attachment that doesn't have any, returns no ranges.
    ///
    func testNoCaptionRangesForPlainAttachment() {
        let attributedString = NSAttributedString(attachment: wpLogoAttachment)
        
        let range = attributedString.captionRange(for: wpLogoAttachment)
        
        XCTAssertNil(range)
    }
    
    /// Verifies looking for caption ranges from an attachment that doesn't have any, returns no ranges.
    ///
    func testCoorectCaptionRangesForAttachmentWithCaption() {
        let caption = NSAttributedString(string: "This is a caption!!")
        let attributedString = NSAttributedString(attachment: wpLogoAttachment, caption: caption, attributes: [:])
        
        let range = attributedString.captionRange(for: wpLogoAttachment)
        
        // Starts at 2 because the attachment ends with a newline.
        // Length is +1 for the same reason.
        let expectedRange = NSRange(location: 2, length: caption.length + 1)
        
        XCTAssertEqual(range, expectedRange)
    }
}

