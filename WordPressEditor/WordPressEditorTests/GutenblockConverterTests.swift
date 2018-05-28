@testable import Aztec
@testable import WordPressEditor

import Foundation
import XCTest

/// - IMPORTANT:
///
class GutenblockConverterTests: XCTestCase {

    let elementConverters: [Element: ElementConverter] = [.gutenblock: GutenblockConverter()]
    
    /// Due to complicated dependencies, we need to test using `AttributedStringSerializer` instead of
    /// testing `GutenblockConverter` directly.  The child serialization logic is too complicated
    /// to reimplement separately.
    ///
    lazy var serializer: AttributedStringSerializer = {
        return AttributedStringSerializer(defaultAttributes: [:], elementConverters: elementConverters)
    }()
    
    // MARK: - Tests
    
    func testSimpleGutenblockConversion() {
        let text = "Hello 🌍!"
        let textNode = TextNode(text: text)
        let paragraphElement = ElementNode(type: .p, attributes: [], children: [textNode])
        let gutenblock = ElementNode(type: .gutenblock, attributes: [], children: [paragraphElement])
        
        let output = serializer.serialize(gutenblock)
        
        XCTAssertEqual(output.string, text)
    }
    
    func testSimpleGutenpackConversion() {
        let gutenpack = ElementNode(type: .gutenpack, attributes: [], children: [])
        
        let output = serializer.serialize(gutenpack)
        
        XCTAssert(output.length > 0)
    }
}

