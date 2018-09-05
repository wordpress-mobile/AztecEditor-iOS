import XCTest
@testable import Aztec

class UIStackViewHelpersTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testArrangedSubviews() {
        let subviews = [
            UIView(),
            UIView(),
            UIView()
        ]
        let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        stackView.addArrangedSubviews(subviews)
        XCTAssertEqual(stackView.arrangedSubviews, subviews)
        
        stackView.removeArrangedSubviews(subviews)
        XCTAssertEqual(stackView.arrangedSubviews, [])
    }
}
