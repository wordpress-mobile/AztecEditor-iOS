import Foundation


public struct CSSAttributeType: RawRepresentable, Hashable {
    
    public typealias RawValue = String
    
    public let rawValue: String
    
    // MARK: - Initializers
    
    public init?(rawValue: RawValue) {
        self.init(rawValue)
    }
    
    public init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
}


extension CSSAttributeType {
    public static let fontStyle = CSSAttributeType("font-style")
    public static let fontWeight = CSSAttributeType("font-weight")
    public static let textDecoration = CSSAttributeType("text-decoration")
    
}

// MARK: - Known values

enum FontStyle: String {
    case italic = "italic"
    case normal = "normal"
    case oblique = "oblique"
}

enum FontWeight: Int {
    case normal = 400
    case bold = 700
    
    init(for name: String) {
        switch name {
        case "bold":
            self = FontWeight.bold
        default:
            self = FontWeight.normal
        }
    }
}

enum TextDecoration: String {
    case overline = "overline"
    case lineThrough = "line-through"
    case underline = "underline"
}
