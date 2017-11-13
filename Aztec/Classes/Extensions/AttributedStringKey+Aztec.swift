import UIKit

public extension AttributedStringKey {

    /// Key used to store Bold Tag Metadata, by our BoldFormatter.
    ///
    public static let boldHtmlRepresentation = AttributedStringKey(key: "Bold.htmlRepresentation")

    /// Key used to store Color Tags Metadata, by our ColorFormatter.
    ///
    public static let colorHtmlRepresentation = AttributedStringKey(key: "Color.htmlRepresentation")

    /// Key used to store HR Tag Metadata, by our HRFormatter.
    ///
    public static let hrHtmlRepresentation = AttributedStringKey(key: "HR.htmlRepresentation")

    /// Key used to store Image Tag Metadata, by our ImageFormatter.
    ///
    public static let imageHtmlRepresentation = AttributedStringKey(key: "Image.htmlRepresentation")

    /// Key used to store Italics Tag Metadata, by our ItalicFormatter.
    ///
    public static let italicHtmlRepresentation = AttributedStringKey(key: "Italic.htmlRepresentation")

    /// Key used to store Link Tag Metadata, by our LinkFormatter.
    ///
    public static let linkHtmlRepresentation = AttributedStringKey(key: "Link.htmlRepresentation")

    /// Key used to store Strike Tag Metadata, by our StrikeFormatter.
    ///
    public static let strikethroughHtmlRepresentation = AttributedStringKey(key: "Strike.htmlRepresentation")

    /// Key used to store UnderlineHTMLRepresentations, by our UnderlineFormatter.
    ///
    public static let underlineHtmlRepresentation = AttributedStringKey(key: "Underline.htmlRepresentation")

    /// Key used to store UnsupportedHTML Snippets, by our HTML Parser.
    ///
    public static let unsupportedHtml = AttributedStringKey(key: "UnsupportedHTMLAttributeName")

    /// Key used to store VideoHTMLRepresentations, by our VideoFormatter.
    ///
    public static let videoHtmlRepresentation = AttributedStringKey(key: "Video.htmlRepresentation")
}
