import Foundation
import XCTest
@testable import Aztec


// MARK: - NSAttributedStringAttachmentTests
//
class NSAttributedStringAttachmentTests: XCTestCase {
    
    let wpLogoAttachment = ImageAttachment(identifier: "wplogo", url: URL(string: "https://s.w.org/about/images/logos/wordpress-logo-32-blue.png"))
    let wpLogoAttachmentGrey = ImageAttachment(identifier: "wplogo", url: URL(string: "https://s.w.org/about/images/logos/wordpress-logo-32.png"))
    
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
    
    /// Verifies looking for caption ranges from an attachment that doesn't have any, returns no ranges.
    ///
    func testCoorectCaptionRangesForTwoAttachmentsWithCaption() {
        let attributedString = NSMutableAttributedString()
        
        let caption = NSAttributedString(string: "This is a caption!!")
        let attachmentString = NSAttributedString(attachment: wpLogoAttachment, caption: caption, attributes: [:])
        
        let caption2 = NSAttributedString(string: "This is a caption!!")
        let secondAttachmentString = NSAttributedString(attachment: wpLogoAttachmentGrey, caption: caption, attributes: [:])
        
        attributedString.append(attachmentString)
        attributedString.append(secondAttachmentString)
        
        let range = attributedString.captionRange(for: wpLogoAttachment)
        let secondAttachmentRange = attributedString.captionRange(for: wpLogoAttachmentGrey)
        
        // Starts at 2 because the attachment ends with a newline.
        // Length is +1 for the same reason.
        let expectedRange = NSRange(location: 2, length: caption.length + 1)
        
        XCTAssertEqual(range, expectedRange)
        
        let firstAttachmentStringLength = 3 + caption.length
        
        // Starts at +2 because the attachment ends with a newline.
        // Length is +1 for the same reason.
        let secondExpectedRange = NSRange(location: firstAttachmentStringLength + 2, length: caption2.length + 1)
        
        XCTAssertEqual(secondAttachmentRange, secondExpectedRange)
    }
}

