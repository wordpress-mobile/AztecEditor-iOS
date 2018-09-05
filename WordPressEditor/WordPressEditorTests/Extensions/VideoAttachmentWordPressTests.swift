import Aztec
import XCTest
@testable import WordPressEditor

class VideoAttachmentWordPressTests: XCTestCase {
    
    func testVideoPressIDSetter() {
        let videoAttachment = VideoAttachment(identifier: "testing")
        let videoPressID = "some-id"
        
        XCTAssertEqual(videoAttachment.extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute], nil)
        
        videoAttachment.videoPressID = videoPressID
        XCTAssertEqual(videoAttachment.extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute], videoPressID)
        
        videoAttachment.videoPressID = nil
        XCTAssertEqual(videoAttachment.extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute], nil)
    }
    
    func testVideoPressIDGetter() {
        let videoAttachment = VideoAttachment(identifier: "testing")
        let videoPressID = "some-id"
        
        XCTAssertEqual(videoAttachment.videoPressID, nil)
        
        videoAttachment.extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute] = videoPressID
        XCTAssertEqual(videoAttachment.videoPressID, videoPressID)
        
        videoAttachment.extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute] = nil
        XCTAssertEqual(videoAttachment.videoPressID, nil)
    }
}
