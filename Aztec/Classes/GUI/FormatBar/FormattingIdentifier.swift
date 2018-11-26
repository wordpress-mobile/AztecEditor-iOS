import Foundation

public struct FormattingIdentifier: RawRepresentable, Hashable {
    
    public typealias RawValue = String
    
    public var rawValue: String
    
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension FormattingIdentifier {
    public static let blockquote = FormattingIdentifier("blockquote")
    public static let bold = FormattingIdentifier("bold")
    public static let code = FormattingIdentifier("code")
    public static let italic = FormattingIdentifier("italic")
    public static let media = FormattingIdentifier("media")
    public static let more = FormattingIdentifier("more")
    public static let header1 = FormattingIdentifier("header1")
    public static let header2 = FormattingIdentifier("header2")
    public static let header3 = FormattingIdentifier("header3")
    public static let header4 = FormattingIdentifier("header4")
    public static let header5 = FormattingIdentifier("header5")
    public static let header6 = FormattingIdentifier("header6")
    public static let horizontalruler = FormattingIdentifier("horizontalruler")
    public static let link = FormattingIdentifier("link")
    public static let orderedlist = FormattingIdentifier("orderedlist")
    public static let p = FormattingIdentifier("p")
    public static let sourcecode = FormattingIdentifier("sourcecode")
    public static let strikethrough = FormattingIdentifier("strikethrough")
    public static let underline = FormattingIdentifier("underline")
    public static let unorderedlist = FormattingIdentifier("unorderedlist")
}
