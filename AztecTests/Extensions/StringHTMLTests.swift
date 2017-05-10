import XCTest
@testable import Aztec


// MARK: - StringHTMLTests
//
class StringHTMLTests: XCTestCase {

    /// Verifies that Emoji Characters get properly encoded as Hexadecimal Entities.
    ///
    func testEncodeHtmlEntitiesEffectivelyEncodeEmojiCharacters() {
        let original = "😘☺️🍱🥈🍣😄 Some Text Here 😆😂😍😭😊👌🏻🙀☠️👾"

        let expected = "&#x1F618;&#x263A;&#xFE0F;&#x1F371;&#x1F948;&#x1F363;&#x1F604; " +
                        "Some Text Here &#x1F606;&#x1F602;&#x1F60D;&#x1F62D;&#x1F60A;" +
                        "&#x1F44C;&#x1F3FB;&#x1F640;&#x2620;&#xFE0F;&#x1F47E;"

        XCTAssertEqual(original.encodeHtmlEntities(), expected)
    }

    /// Verifies that HTML Entities get properly escaped.
    ///
    func testEscapeHtmlEntitiesEffectivelyEscapesAllOfTheHtmlEntities() {
        let original = "&<>\"' Some Text Here"
        let expected = "&amp;&lt;&gt;&quot;&apos; Some Text Here"

        XCTAssertEqual(original.escapeHtmlEntities(), expected)
    }

    /// Verifies that strings that do not contain HTML Entities remain pristine.
    ///
    func testEscapeHtmlEntitiesDoesNotAlterAnythingIfThereWereNoHtmlEntities() {
        let original = "This should be a super long text, that is expected to remain unmodified"

        XCTAssertEqual(original.escapeHtmlEntities(), original)
    }
}
