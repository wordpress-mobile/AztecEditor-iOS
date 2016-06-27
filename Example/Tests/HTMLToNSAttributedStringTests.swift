import XCTest
import Aztec

class HTMLToNSAttributedStringTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        let converter = HTMLToNSAttributedString()

        var range = NSRange(location: 0, length: 5)

        let output = converter.convert("<HTML style='a' nostye peace='123'>Hello World!</HTML>".dataUsingEncoding(NSUTF8StringEncoding)!)
        let attributes = output.attributesAtIndex(0, effectiveRange: &range)
        print(output, attributes)
    }
}
