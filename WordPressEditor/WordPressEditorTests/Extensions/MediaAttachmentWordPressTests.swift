import Aztec
import XCTest
@testable import WordPressEditor

class MediaAttachmentWordPressTests: XCTestCase {
    
    func testUploadIDSetter() {
        let imageAttachment = MediaAttachment(identifier: "testing")
        let uploadID = "some-id"
        
        XCTAssertEqual(imageAttachment.extraAttributes[MediaAttachment.uploadKey], nil)
        
        imageAttachment.uploadID = uploadID
        XCTAssertEqual(imageAttachment.extraAttributes[MediaAttachment.uploadKey], .string(uploadID))
        
        imageAttachment.uploadID = nil
        XCTAssertEqual(imageAttachment.extraAttributes[MediaAttachment.uploadKey], nil)
    }
    
    func testUploadIDGetter() {
        let imageAttachment = MediaAttachment(identifier: "testing")
        let uploadID = "some-id"
        
        XCTAssertEqual(imageAttachment.uploadID, nil)
        
        imageAttachment.extraAttributes[MediaAttachment.uploadKey] = .string(uploadID)
        XCTAssertEqual(imageAttachment.uploadID, uploadID)
        
        imageAttachment.extraAttributes[MediaAttachment.uploadKey] = nil
        XCTAssertEqual(imageAttachment.uploadID, nil)
    }

    func testIsLoadedInitiallyReturnsFalse() {
        let imageAttachment = MediaAttachment(identifier: "testing")

        XCTAssertFalse(imageAttachment.isLoaded)
    }
}
