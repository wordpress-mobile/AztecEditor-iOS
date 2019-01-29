import Foundation
import UIKit


// MARK: - Header property for paragraphs
//
open class Header: ParagraphProperty {

    // MARK: - Nested Types

    /// Available Heading Types
    ///
    public enum HeaderType: Int {
        case none = 0
        case h1 = 1
        case h2 = 2
        case h3 = 3
        case h4 = 4
        case h5 = 5
        case h6 = 6

        public static var defaultFontSizeMap: [HeaderType: Float] = {
            return [
                .h1: 36,
                .h2: 24,
                .h3: 21,
                .h4: 16,
                .h5: 14,
                .h6: 11,
                .none: Constants.defaultFontSize
                ]
        }()
        
        public var fontSize: Float {
            return fontSize(for: nil)
        }
        
        public func fontSize(for fontSizeMap: [HeaderType: Float]?) -> Float {
            var effectiveFontSizeMap: [HeaderType: Float] = HeaderType.defaultFontSizeMap
            if let fontSizeMap = fontSizeMap {
                effectiveFontSizeMap = fontSizeMap
            }
            let fontSize = effectiveFontSizeMap[self] ?? Constants.defaultFontSize

            if #available(iOS 11.0, *) {
                return Float(UIFontMetrics.default.scaledValue(for: CGFloat(fontSize)))
            } else {
                return fontSize
            }
        }
    }

    // MARK: - Properties

    /// Kind of Header: Header 1, Header 2, etc..
    ///
    let level: HeaderType

    /// Default Font Size (corresponding to HeaderType.none)
    ///
    let defaultFontSize: Float

    /// HeaderType and font size map
    //
    let fontSizeMap: [Header.HeaderType: Float]?

    // MARK: - Initializers

    init(level: HeaderType,
         with representation: HTMLRepresentation? = nil,
         defaultFontSize: Float? = nil,
         fontSizeMap: [Header.HeaderType: Float]? = nil)
    {
        self.defaultFontSize = defaultFontSize ?? Constants.defaultFontSize
        self.level = level
        self.fontSizeMap = fontSizeMap
        super.init(with: representation)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValue(forKey: Keys.level),
            let decodedLevel = HeaderType(rawValue: aDecoder.decodeInteger(forKey: Keys.level))
        {
            level = decodedLevel
        } else {
            level = .none
        }

        if aDecoder.containsValue(forKey: Keys.level) {
            defaultFontSize = aDecoder.decodeFloat(forKey: Keys.defaultFontSize)
        } else {
            defaultFontSize = Constants.defaultFontSize
        }
        fontSizeMap = nil
        super.init(coder: aDecoder)
    }

    func fontSize() -> Float {
        guard level == .none else {
            return level.fontSize(for: fontSizeMap)
        }
        
        return defaultFontSize
    }
    
    // MARK: - NSCoder

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(defaultFontSize, forKey: Keys.defaultFontSize)
        aCoder.encode(level.rawValue, forKey: Keys.level)
    }

    static func ==(lhs: Header, rhs: Header) -> Bool {
        return lhs.level == rhs.level
    }
}


// MARK: - Private Helpers
//
private extension Header {
    struct Constants {
        static let defaultFontSize = Float(14)
    }

    struct Keys {
        static let defaultFontSize = "defaultFontSize"
        static let level = String(describing: HeaderType.self)
    }
}
