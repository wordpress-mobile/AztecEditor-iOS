import XCTest
@testable import Aztec


// MARK: - HeaderFormatterTests
//
class HeaderFormatterTests: XCTestCase {

    /// Sample Default Font Size
    ///
    private let defaultFontSize = CGFloat(9)

    /// Sample Attributes
    ///
    private lazy var attributes: [NSAttributedString.Key: Any] = {
        return [.font: UIFont.systemFont(ofSize: self.defaultFontSize)]
    }()


    /// Verifies that the default font size is effectively restored after the Header Formatter is removed.
    ///
    func testDefaultFontIsRestoredWhenFormattingIsRemoved() {
        let formatter = HeaderFormatter(headerLevel: .h1, placeholderAttributes: nil)

        let updatedAttrs = formatter.apply(to: attributes, andStore: nil)
        let updatedFont = updatedAttrs[.font] as! UIFont
        XCTAssert(updatedFont.pointSize == CGFloat(formatter.headerLevel.fontSize))

        let removedAttrs = formatter.remove(from: updatedAttrs)
        let removedFont = removedAttrs[.font] as! UIFont
        XCTAssert(removedFont.pointSize == defaultFontSize)
    }

    /// Verifies that the Default Font is preserved whenever a Header Style is applied on top of an existant Header.
    ///
    func testDefaultFontIsPreservedWheneverTheHeaderLevelIsUpdated() {
        let formatterH1 = HeaderFormatter(headerLevel: .h1, placeholderAttributes: nil)
        let updatedH1Attrs = formatterH1.apply(to: attributes, andStore: nil)
        let updatedH1Font = updatedH1Attrs[.font] as! UIFont
        XCTAssert(updatedH1Font.pointSize == CGFloat(formatterH1.headerLevel.fontSize))

        let formatterH2 = HeaderFormatter(headerLevel: .h2, placeholderAttributes: nil)
        let updatedH2Attrs = formatterH2.apply(to: attributes, andStore: nil)
        let updatedH2Font = updatedH2Attrs[.font] as! UIFont
        XCTAssert(updatedH2Font.pointSize == CGFloat(formatterH2.headerLevel.fontSize))

        let removedAttrs = formatterH2.remove(from: updatedH2Attrs)
        let removedFont = removedAttrs[.font] as! UIFont
        XCTAssert(removedFont.pointSize == defaultFontSize)
    }
}
