import Aztec
import XCTest
@testable import WordPressEditor

class GutenblockTests: XCTestCase {
    
    func testInitWithRepresentation() {
        let gutenblockElement = ElementNode(type: .gutenblock)
        let elementRepresentation = HTMLElementRepresentation(gutenblockElement)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        let gutenblock = Gutenblock(storing: representation)
        
        XCTAssertEqual(gutenblock.representation, representation)
    }
    
    func testInitWithCoder() {
        let gutenblock = Gutenblock()
        
        XCTAssertEqual(gutenblock.representation, nil)
    }
}
