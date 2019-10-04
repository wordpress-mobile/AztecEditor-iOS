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
    public static let foregroundColor = CSSAttributeType("color")
    
}

// MARK: - Known values

enum FontStyle: String {
    case italic = "italic"
    case normal = "normal"
    case oblique = "oblique"
}

enum FontWeightNumeric: Int {
    case normal = 400
    case bold = 700
    
    func isBold() -> Bool {
        return self.rawValue >= FontWeightNumeric.bold.rawValue
    }
    
    static func isBold(_ value: Int) -> Bool {
        return value >= FontWeightNumeric.bold.rawValue
    }
}

enum FontWeight: String {
    case normal = "normal"
    case bold = "bold"
    
    func numeric() -> FontWeightNumeric {
        switch self {
        case .normal:
            return .normal
        case .bold:
            return .bold
        }
    }
    
    func isBold() -> Bool {
        return numeric().isBold()
    }
}

enum TextDecoration: String {
    case overline = "overline"
    case lineThrough = "line-through"
    case underline = "underline"
}
