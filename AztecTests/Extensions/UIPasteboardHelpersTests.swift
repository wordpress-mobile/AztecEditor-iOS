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
        let pasteboardName = UIPasteboard.Name("testPasteboard")
        let pasteboard = UIPasteboard(name: pasteboardName, create: true)!
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
        let pasteboardName = UIPasteboard.Name("testPasteboard")
        let pasteboard = UIPasteboard(name: pasteboardName, create: true)!
        let html = "<p>testing</p>"
        
        pasteboard.setValue(html, forPasteboardType: String(kUTTypeHTML))
        
        XCTAssertEqual(pasteboard.html(), html)
    }
	
	// https://github.com/wordpress-mobile/AztecEditor-iOS/pull/1369
	func testNoCrashWhenPastingBulletList() {
		// Copied one row of a bullet list from the example app's "Empty Demo view" and encoded the clipboard data into base 64.
		let data = Data(base64Encoded: "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGvEC8LDBMXHyssLS48PUNSYGdrb3J2en6ChoqOkZWZnJ+krLGzuL7R0tjg4cri4+fo7FUkbnVsbNMNDg8QERJYTlNTdHJpbmdWJGNsYXNzXE5TQXR0cmlidXRlc4ACgC6ABNIOFBUWWU5TLnN0cmluZ4ADVFRlc3TSGBkaG1okY2xhc3NuYW1lWCRjbGFzc2VzXxAPTlNNdXRhYmxlU3RyaW5noxwdHl8QD05TTXV0YWJsZVN0cmluZ1hOU1N0cmluZ1hOU09iamVjdNMgIQ4iJipXTlMua2V5c1pOUy5vYmplY3RzoyMkJYAFgAaAB6MnKCmACIALgCOAD1dOU0NvbG9yXxAQTlNQYXJhZ3JhcGhTdHlsZVZOU0ZvbnTXLzAxDjIzNDU2Nzg5OjtfEBVVSUNvbG9yQ29tcG9uZW50Q291bnRXVUlXaGl0ZVdVSUFscGhhXxARVUlTeXN0ZW1Db2xvck5hbWVXTlNXaGl0ZVxOU0NvbG9yU3BhY2UQAiIAAAAAIj+AAACACoAJQTAQBFpsYWJlbENvbG9y0xgZPj9AQVskY2xhc3NoaW50c1dVSUNvbG9yoj8eoUJXTlNDb2xvcthERUZHSEkOSktMTU5PTlE7XxARUGFyYWdyYXBoUHJvcGVydHlaTlNUYWJTdG9wc18QFU5TRmlyc3RMaW5lSGVhZEluZGVudFxOU1RleHRCbG9ja3NbaGVhZGVyTGV2ZWxbTlNUZXh0TGlzdHNbTlNBbGlnbm1lbnSAHYAMI0BCAAAAAAAAgBwQAIAcgCLSIQ5TX6tUVVZXWFlaW1xdXoANgBGAEoATgBSAFYAWgBeAGIAZgBqAG9QOYWJjZGU7ZlxOU1RhYk9wdGlvbnNfEA9OU1RleHRBbGlnbm1lbnRaTlNMb2NhdGlvboAQgA4jQBAAAAAAAADTICEOaGkqoKCAD9IYGWxtXE5TRGljdGlvbmFyeaJuHlxOU0RpY3Rpb25hcnnSGBlwcVlOU1RleHRUYWKicB7UDmFiY2RlO3WAEIAOI0AgAAAAAAAA1A5hYmNkZTt5gBCADiNAKAAAAAAAANQOYWJjZGU7fYAQgA4jQDAAAAAAAADUDmFiY2RlO4GAEIAOI0A0AAAAAAAA1A5hYmNkZTuFgBCADiNAOAAAAAAAANQOYWJjZGU7iYAQgA4jQDwAAAAAAADUDmFiY2RlO42AEIAOI0BAAAAAAAAA1A5hYmNkZTtNgBCADtQOYWJjZGU7lIAQgA4jQEQAAAAAAADUDmFiY2RlO5iAEIAOI0BGAAAAAAAA0hgZmptXTlNBcnJheaKaHtIhDp1foIAb0iEOoF+ioaKAHoAggBvUDqWmp6ipqqtYcmV2ZXJzZWRVU3R5bGVVc3RhcnSAHwgQAYAA0hgZra5eQXp0ZWMuVGV4dExpc3Sjr7AeXkF6dGVjLlRleHRMaXN0XxAXQXp0ZWMuUGFyYWdyYXBoUHJvcGVydHnRDrKAIdIYGbS1XEF6dGVjLkhUTUxMaaO2tx5cQXp0ZWMuSFRNTExpXxAXQXp0ZWMuUGFyYWdyYXBoUHJvcGVydHnSGBm5ul8QFEF6dGVjLlBhcmFncmFwaFN0eWxlpLu8vR5fEBRBenRlYy5QYXJhZ3JhcGhTdHlsZV8QF05TTXV0YWJsZVBhcmFncmFwaFN0eWxlXxAQTlNQYXJhZ3JhcGhTdHlsZdu/wMHCww7ExcbHyMnKy8zKzU/KzszQXxAiVUlGb250TWF4aW11bVBvaW50U2l6ZUFmdGVyU2NhbGluZ18QGVVJRm9udFBvaW50U2l6ZUZvclNjYWxpbmdfEBBVSUZvbnREZXNjcmlwdG9yVk5TTmFtZVZOU1NpemVcVUlGb250VHJhaXRzXxAPVUlGb250UG9pbnRTaXplXxAZVUlGb250VGV4dFN0eWxlRm9yU2NhbGluZ1pVSUZvbnROYW1lXFVJU3lzdGVtRm9udCMAAAAAAAAAACNALAAAAAAAAIAlgCSALYAsgCQJXS5TRlVJLVJlZ3VsYXLT0w7U1dbXXxAXVUlGb250RGVzY3JpcHRvck9wdGlvbnNfEBpVSUZvbnREZXNjcmlwdG9yQXR0cmlidXRlcxKAAIQEgCuAJtMgIQ7Z3Cqi2tuAJ4Aoot3egCmAKoAPXxATTlNGb250U2l6ZUF0dHJpYnV0ZV8QGE5TQ1RGb250VUlVc2FnZUF0dHJpYnV0ZV8QEkNURm9udFJlZ3VsYXJVc2FnZdIYGeTlXxAQVUlGb250RGVzY3JpcHRvcqLmHl8QEFVJRm9udERlc2NyaXB0b3JfEBVVSUNURm9udFRleHRTdHlsZUJvZHnTGBk+6errVlVJRm9udKLpHqEt0hgZ7e5fEBlOU011dGFibGVBdHRyaWJ1dGVkU3RyaW5no+/wHl8QGU5TTXV0YWJsZUF0dHJpYnV0ZWRTdHJpbmdfEBJOU0F0dHJpYnV0ZWRTdHJpbmcACAARABoAJAApADIANwBJAEwAUQBTAIUAiwCSAJsAogCvALEAswC1ALoAxADGAMsA0ADbAOQA9gD6AQwBFQEeASUBLQE4ATwBPgFAAUIBRgFIAUoBTAFOAVYBaQFwAX8BlwGfAacBuwHDAdAB0gHXAdwB3gHgAeIB5AHvAfYCAgIKAg0CDwIXAigCPAJHAl8CbAJ4AoQCkAKSApQCnQKfAqECowKlAqoCtgK4AroCvAK+AsACwgLEAsYCyALKAswCzgLXAuQC9gMBAwMDBQMOAxUDFgMXAxkDHgMrAy4DOwNAA0oDTQNWA1gDWgNjA2wDbgNwA3kDggOEA4YDjwOYA5oDnAOlA64DsAOyA7sDxAPGA8gD0QPaA9wD3gPnA/AD8gP0A/0D/wQBBAoEEwQVBBcEIAQlBC0EMAQ1BDYEOAQ9BEAEQgREBEYETwRYBF4EZARmBGcEaQRrBHAEfwSDBJIErASvBLEEtgTDBMcE1ATuBPMFCgUPBSYFQAVTBWoFjwWrBb4FxQXMBdkF6wYHBhIGHwYoBjEGMwY1BjcGOQY7BjwGSgZRBmsGiAaNBo8GkQaYBpsGnQafBqIGpAamBqgGvgbZBu4G8wcGBwkHHAc0BzsHQgdFB0cHTAdoB2wHiAAAAAAAAAIBAAAAAAAAAPEAAAAAAAAAAAAAAAAAAAed")
		
		let pasteboardName = UIPasteboard.Name("testPasteboard")
		let pasteboard = UIPasteboard(name: pasteboardName, create: true)!
		pasteboard.items = [[NSAttributedString.pastesboardUTI: data!]]
		
		// Without the fix an exception is thrown from NSKeyedUnarchiver.unarchiveObject.
		XCTAssertNoThrow(try pasteboard.throwing_attributedString()) // Called by GUI command "Paste without Formatting".
	}
}

extension UIPasteboard {
	func throwing_attributedString() throws -> NSAttributedString? {
		attributedString()
	}
}
