import UIKit

public extension NSAttributedStringKey {

    /// Key used to store Bold Tag Metadata, by our BoldFormatter.
    ///
    public static let boldHtmlRepresentation = NSAttributedStringKey("Bold.htmlRepresentation")

    /// Key used to store Color Tags Metadata, by our ColorFormatter.
    ///
    public static let colorHtmlRepresentation = NSAttributedStringKey("Color.htmlRepresentation")

    /// Key used to store HR Tag Metadata, by our HRFormatter.
    ///
    public static let hrHtmlRepresentation = NSAttributedStringKey("HR.htmlRepresentation")

    /// Key used to store Image Tag Metadata, by our ImageFormatter.
    ///
    public static let imageHtmlRepresentation = NSAttributedStringKey("Image.htmlRepresentation")

    /// Key used to store Italics Tag Metadata, by our ItalicFormatter.
    ///
    public static let italicHtmlRepresentation = NSAttributedStringKey("Italic.htmlRepresentation")

    /// Key used to store Link Tag Metadata, by our LinkFormatter.
    ///
    public static let linkHtmlRepresentation = NSAttributedStringKey("Link.htmlRepresentation")

    /// Key used to store Strike Tag Metadata, by our StrikeFormatter.
    ///
    public static let strikethroughHtmlRepresentation = NSAttributedStringKey("Strike.htmlRepresentation")

    /// Key used to store UnderlineHTMLRepresentations, by our UnderlineFormatter.
    ///
    public static let underlineHtmlRepresentation = NSAttributedStringKey("Underline.htmlRepresentation")

    /// Key used to store UnsupportedHTML Snippets, by our HTML Parser.
    ///
    public static let unsupportedHtml = NSAttributedStringKey("UnsupportedHTMLAttributeName")

    /// Key used to store VideoHTMLRepresentations, by our VideoFormatter.
    ///
    public static let videoHtmlRepresentation = NSAttributedStringKey("Video.htmlRepresentation")
}
