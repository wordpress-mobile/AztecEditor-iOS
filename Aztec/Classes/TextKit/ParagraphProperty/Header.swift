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

        public var fontSize: CGFloat {
            switch self {
            case .none: return Constants.defaultFontSize
            case .h1: return 36
            case .h2: return 24
            case .h3: return 21
            case .h4: return 16
            case .h5: return 14
            case .h6: return 11
            }
        }
    }

    // MARK: - Properties

    /// Kind of Header: Header 1, Header 2, etc..
    ///
    let level: HeaderType

    /// Default Font Size (corresponding to HeaderType.none)
    ///
    let defaultFontSize: CGFloat


    // MARK: - Initializers

    init(level: HeaderType, with representation: HTMLRepresentation? = nil, defaultFontSize: CGFloat? = nil) {
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
            defaultFontSize = CGFloat(aDecoder.decodeFloat(forKey: Keys.defaultFontSize))
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
        static let defaultFontSize = CGFloat(14)
    }

    struct Keys {
        static let defaultFontSize = "defaultFontSize"
        static let level = String(describing: HeaderType.self)
    }
}
