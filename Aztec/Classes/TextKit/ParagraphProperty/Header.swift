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

        public static var fontSizeMap: [HeaderType: Float] = {
            return [
                .h1: 24,
                .h2: 22,
                .h3: 20,
                .h4: 18,
                .h5: 16,
                .h6: 14,
                .none: Constants.defaultFontSize
                ]
        }()

        public var fontSize: Float {
            let fontSize = HeaderType.fontSizeMap[self] ?? Constants.defaultFontSize
            return Float(UIFontMetrics.default.scaledValue(for: CGFloat(fontSize)))
        }
    }

    // MARK: - Properties

    /// Kind of Header: Header 1, Header 2, etc..
    ///
    let level: HeaderType

    /// Default Font Size (corresponding to HeaderType.none)
    ///
    let defaultFontSize: Float


    // MARK: - Initializers

    init(level: HeaderType, with representation: HTMLRepresentation? = nil, defaultFontSize: Float? = nil) {
        self.defaultFontSize = defaultFontSize ?? Constants.defaultFontSize
        self.level = level
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

        super.init(coder: aDecoder)
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
        static let defaultFontSize = Float(16)
    }

    struct Keys {
        static let defaultFontSize = "defaultFontSize"
        static let level = String(describing: HeaderType.self)
    }
}
