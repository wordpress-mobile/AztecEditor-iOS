import MobileCoreServices
import UIKit
import XCTest
@testable import Aztec

class UIPasteboardHelpersTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPasteboardAttributedString() {
        let pasteboard = UIPasteboard.forTesting
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.red
        ]
        let attrString = NSAttributedString(string: "Hello 🌎!", attributes: attributes)
        
        guard let data = try? attrString.data(
            from: NSRange(location: 0, length: attrString.length),
            documentAttributes: [.documentType: DocumentType.rtfd]) else {
                XCTFail()
                return
        }
        
        pasteboard.setData(data, forPasteboardType: String(kUTTypeFlatRTFD))

        guard let pastedString = pasteboard.attributedString() else {
            XCTFail()
            return
        }
        
        // Comparing the attributes has proved next to impossible due to changes applied by the pasteboard.
        // We'll just compare the string is right for now.
        XCTAssertEqual(attrString.string, pastedString.string)
    }
    
    func testPasteboardHTML() {
        let pasteboard = UIPasteboard.forTesting
        let html = "<p>testing</p>"
        
        pasteboard.setValue(html, forPasteboardType: String(kUTTypeHTML))
        
        XCTAssertEqual(pasteboard.html(), html)
    }
}
