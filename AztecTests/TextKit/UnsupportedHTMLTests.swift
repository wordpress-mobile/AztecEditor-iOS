import XCTest
@testable import Aztec


// MARK: - UnsupportedHTMLTests
//
class UnsupportedHTMLTests: XCTestCase {

    /// Verifies that a UnsupportedHTML Instance can get properly serialized back and forth
    ///
    func testSnippetsGetProperlyEncodedAndDecoded() {
        let unsupported = UnsupportedHTML()
        unsupported.append(element: sampleElement)
        unsupported.append(element: sampleElement)

        let data = NSKeyedArchiver.archivedData(withRootObject: unsupported)
        guard let restored = NSKeyedUnarchiver.unarchiveObject(with: data) as? UnsupportedHTML else {
            XCTFail()
            return
        }

        let elements = restored.elements
        XCTAssert(elements.count == 2)

        for element in elements {
            XCTAssert(element.children == sampleChildren)
            XCTAssert(element.attributes == sampleAttributes)
        }
    }
}


// MARK: - Helpers
//
private extension UnsupportedHTMLTests {
    var sampleCSS: CSSProperty {
        return CSSProperty(name: "text", value: "bold")
    }

    var sampleAttributes: [Attribute] {
        return [
            Attribute(name: "none", value: .none),
            Attribute(name: "string", value: .string("value")),
            Attribute(name: "style", value: .inlineCss([self.sampleCSS]))
        ]
    }

    var sampleChildren: [Node] {
        return [
            TextNode(text: "Some Text"),
            CommentNode(text: "Some Comment"),
        ]
    }

    var sampleElement: ElementNode {
        return ElementNode(name: "Test", attributes: self.sampleAttributes, children: self.sampleChildren)
    }
}
