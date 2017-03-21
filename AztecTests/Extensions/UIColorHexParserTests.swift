import XCTest
@testable import Aztec

class UIColorHexParserTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testParseOf24bitsHexColors() {
        var color = UIColor(hexString: "#FF0000")

        XCTAssertEqual(color, UIColor.red)

        color = UIColor(hexString: "#00FF00")

        XCTAssertEqual(color, UIColor.green)

        color = UIColor(hexString: "#0000FF")

        XCTAssertEqual(color, UIColor.blue)

        color = UIColor(hexString: "#FFFFFF")

        XCTAssertEqual(color, UIColor.init(colorLiteralRed: 1, green: 1, blue: 1, alpha: 1))
    }

    func testParseOf32bitsHexColors() {
        var color = UIColor(hexString: "#FFFF0000")

        XCTAssertEqual(color, UIColor.red)

        color = UIColor(hexString: "#FF00FF00")

        XCTAssertEqual(color, UIColor.green)

        color = UIColor(hexString: "#FF0000FF")

        XCTAssertEqual(color, UIColor.blue)

        color = UIColor(hexString: "#FFFFFFFF")

        XCTAssertEqual(color, UIColor.init(colorLiteralRed: 1, green: 1, blue: 1, alpha: 1))
    }

    func testFailingColor() {
        var color = UIColor(hexString: "#")

        XCTAssertEqual(color, nil)

        color = UIColor(hexString: "#ZZZZZZ")

        XCTAssertEqual(color, nil)
    }
}
