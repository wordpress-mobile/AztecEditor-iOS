import XCTest
@testable import Aztec

class StringRegexTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testRegex() {
        let nsString: NSString = "Hello World!"
        let string: String = nsString as String
        
        let wordToCapture = "World"
        let nsRange = nsString.range(of: wordToCapture)
        let range = string.range(from: nsRange)
        
        let wordCaptured = String(string[range])
        
        XCTAssertEqual(wordToCapture, wordCaptured)
    }
}
