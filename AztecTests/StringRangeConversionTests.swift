import XCTest
@testable import Aztec

class StringRangeConversionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRangeConversion() {
        // test simple word
        var nsString: NSString = "Hello World!"
        var string: String = nsString as String

        var wordToCapture = "World"
        var nsRange = nsString.range(of: wordToCapture)
        var range = string.range(from: nsRange)

        var wordCaptured = string.substring(with: range!)

        XCTAssertEqual(wordToCapture, wordCaptured)

        // test with emoji size 2
        nsString = "Hello 🌍!"
        string = nsString as String

        wordToCapture = "🌍"
        nsRange = nsString.range(of: wordToCapture)
        range = string.range(from: nsRange)

        wordCaptured = string.substring(with: range!)

        XCTAssertEqual(wordToCapture, wordCaptured)

        // test with emoji size 4
        nsString = "Hello 🇮🇳!"
        string = nsString as String

        wordToCapture = "🇮🇳"
        nsRange = nsString.range(of: wordToCapture)
        range = string.range(from: nsRange)

        wordCaptured = string.substring(with: range!)

        XCTAssertEqual(wordToCapture, wordCaptured)

        // test with two emojis
        nsString = "Hello 🇮🇳 🌍!"
        string = nsString as String

        wordToCapture = "🌍"
        nsRange = nsString.range(of: wordToCapture)
        range = string.range(from: nsRange)

        wordCaptured = string.substring(with: range!)

        XCTAssertEqual(wordToCapture, wordCaptured)
    }

    func testLocationConversion() {
        // test simple word
        var nsString: NSString = "Hello World!"
        var string: String = nsString as String

        var wordToCapture = "World"
        var nsRange = nsString.range(of: wordToCapture)
        var index = string.indexFromLocation(nsRange.location)!

        var wordCaptured = string.substring(to: index)

        XCTAssertEqual("Hello ", wordCaptured)

        // test with emoji size 2
        nsString = "Hello 🌍!"
        string = nsString as String

        wordToCapture = "🌍"
        nsRange = nsString.range(of: wordToCapture)
        index = string.indexFromLocation(nsRange.location)!

        wordCaptured = string.substring(to: index)

        XCTAssertEqual("Hello ", wordCaptured)

        // test with emoji size 4
        nsString = "Hello 🇮🇳!"
        string = nsString as String

        wordToCapture = "🇮🇳"
        nsRange = nsString.range(of: wordToCapture)
        index = string.indexFromLocation(nsRange.location)!

        wordCaptured = string.substring(to: index)

        XCTAssertEqual("Hello ", wordCaptured)

        // test with two emojis
        nsString = "Hello 🇮🇳 🌍!"
        string = nsString as String

        wordToCapture = "🌍"
        nsRange = nsString.range(of: wordToCapture)
        index = string.indexFromLocation(nsRange.location)!

        wordCaptured = string.substring(to: index)
        
        XCTAssertEqual("Hello 🇮🇳 ", wordCaptured)
    }

    func testLocationBefore() {
        var nsString: NSString = "Hello World!"
        var string: String = nsString as String

        var wordToCapture = "World"
        var nsRange = nsString.range(of: wordToCapture)
        var location = string.location(before: nsRange.location)!
        var index = string.indexFromLocation(location)!
        var wordCaptured = string.substring(to: index)

        XCTAssertEqual("Hello", wordCaptured)

        // test with emoji size 2
        nsString = "Hello 🌍!"
        string = nsString as String

        wordToCapture = "🌍"
        nsRange = nsString.range(of: wordToCapture)
        location = string.location(before: nsRange.endLocation)!
        index = string.indexFromLocation(location)!

        wordCaptured = string.substring(to: index)
        
        XCTAssertEqual("Hello ", wordCaptured)
    }

    func testLocationBeforeAtLimits() {
        // test at start of string
        let string = ""
        let nonExistentLocation = string.location(before: 0)
        XCTAssertNil(nonExistentLocation)
    }

    func testLocationAfterAtLimits() {
        // test at start of string
        let string = ""
        let nonExistentLocation = string.location(after: 0)
        XCTAssertNil(nonExistentLocation)
    }

    /// Tests that converting a range back and forth works.
    ///
    /// Input:
    ///     - String is: "Hello world!"
    ///     - NSRange is: (loc: 2, len: 3)
    ///
    /// Expected Output:
    ///     - The range will be converted to a range and back, the final NSRange should stay the
    ///         same.
    ///
    func testNSRangeFromRange1() {
        let nsRange = NSRange(location: 2, length: 3)
        let string = "Hello world!"

        guard let range = string.range(from: nsRange) else {
            XCTFail("Range conversion failed!")
            return
        }

        let finalNSRange = string.nsRange(from: range)

        XCTAssertEqual(nsRange, finalNSRange)
    }

    /// Tests that converting a range back and forth works.
    ///
    /// Input:
    ///     - String is: "Hello 😬 world!"
    ///     - NSRange is: (loc: 5, len: 3)
    ///
    /// Expected Output:
    ///     - The range will be converted to a range and back, the final NSRange should stay the
    ///         same.
    ///
    func testNSRangeFromRange2() {
        let nsRange = NSRange(location: 5, length: 3)
        let string = "Hello world!"

        guard let range = string.range(from: nsRange) else {
            XCTFail("Range conversion failed!")
            return
        }

        let finalNSRange = string.nsRange(from: range)

        XCTAssertEqual(nsRange, finalNSRange)
    }

    /// Tests that converting a range back and forth works.
    ///
    /// Input:
    ///     - String is: "Hello 😬 world!"
    ///     - NSRange is: (loc: 5, len: 3)
    ///
    /// Expected Output:
    ///     - The range will be converted to a range and back, the final NSRange should stay the
    ///         same.
    ///
    func testNSRangeFromRange3() {
        let nsRange = NSRange(location: 6, length: 1)
        let string = "Hello 🌎!"

        guard let range = string.range(from: nsRange) else {
            XCTFail("Range conversion failed!")
            return
        }

        let finalNSRange = string.nsRange(from: range)

        XCTAssertEqual(nsRange, finalNSRange)
    }
    
}
