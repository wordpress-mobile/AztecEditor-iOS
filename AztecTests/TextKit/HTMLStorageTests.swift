import XCTest
@testable import Aztec


class HTMLStorageTests: XCTestCase {
    func testInitWithFont() {
        let font = UIFont.boldSystemFont(ofSize: 12)
        let storage = HTMLStorage(defaultFont: font)
        
        XCTAssertEqual(storage.font, font)
    }
    
    func testInsert() {
        let font = UIFont.boldSystemFont(ofSize: 12)
        let storage = HTMLStorage(defaultFont: font)
        let initialString = "ahoi"
        
        storage.insert(NSAttributedString(string: initialString), at: 0)
        
        XCTAssertEqual(storage.string, initialString)
    }
    
    func testReplaceCharactersWithString() {
        let font = UIFont.boldSystemFont(ofSize: 12)
        let storage = HTMLStorage(defaultFont: font)
        let initialString = "ahoi"
        
        storage.insert(NSAttributedString(string: initialString), at: 0)
        storage.replaceCharacters(in: NSRange(location: 3, length: 1), with: "y!")
        
        XCTAssertEqual(storage.string, "ahoy!")
    }
    
    func testReplaceCharactersWithStringWithEmojis() {
        let font = UIFont.boldSystemFont(ofSize: 12)
        let storage = HTMLStorage(defaultFont: font)
        let initialString = "The 🌎 goes round and round!"
        let expected = "The 🌎 goes 🔄 and 🔄!"
        
        storage.insert(NSAttributedString(string: initialString), at: 0)
        storage.replaceCharacters(in: NSRange(location: 22, length: 5), with: "🔄")
        storage.replaceCharacters(in: NSRange(location: 12, length: 5), with: "🔄")
        
        XCTAssertEqual(storage.string, expected)
    }
    
    func testReplaceCharactersWithAttributedString() {
        let font = UIFont.boldSystemFont(ofSize: 12)
        let storage = HTMLStorage(defaultFont: font)
        let initialString = "<p>Hello there!</p>"
        let expected = "<p>Hello <em>world</em>!</p>"
        
        let attrString = NSAttributedString(string: "<em>world</em>", attributes: [.foregroundColor: UIColor.red])
        
        storage.insert(NSAttributedString(string: initialString), at: 0)
        storage.replaceCharacters(in: NSRange(location: 9, length: 5), with: attrString)
        
        XCTAssertEqual(storage.string, expected)
        
        let openingTagColor = storage.attribute(.foregroundColor, at: 9, effectiveRange: nil) as! UIColor
        let closingTagColor = storage.attribute(.foregroundColor, at: 18, effectiveRange: nil) as! UIColor
        
        XCTAssertEqual(openingTagColor, HTMLStorage.Styles.defaultTagColor)
        XCTAssertEqual(closingTagColor, HTMLStorage.Styles.defaultTagColor)
    }
    
    func testSetTextColor() {
        let font = UIFont.boldSystemFont(ofSize: 12)
        let storage = HTMLStorage(defaultFont: font)
        let initialString = "Hello there"
        
        storage.insert(NSAttributedString(string: initialString), at: 0)
        
        XCTAssertEqual(storage.string, initialString)
        XCTAssertEqual(storage.textColor, HTMLStorage.Styles.defaultTextColor)

        storage.textColor = .red
        storage.replaceCharacters(in: NSRange(location: 0, length: 4), with: NSAttributedString(string: "Hello world"))
        
        let textColor = storage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as! UIColor

        XCTAssertEqual(textColor, UIColor.red)
    }
}
