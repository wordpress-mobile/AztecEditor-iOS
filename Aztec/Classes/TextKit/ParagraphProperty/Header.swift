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
            case .none: return 14
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

    init(level: HeaderType, with representation: HTMLElementRepresentation? = nil) {
        self.level = level
        super.init(with: representation)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValue(forKey: String(describing: HeaderType.self)),
            let decodedStyle = HeaderType(rawValue:aDecoder.decodeInteger(forKey: String(describing: HeaderType.self))) {
            level = decodedStyle
        } else {
            level = .none
        }
        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(level.rawValue, forKey: String(describing: HeaderType.self))
    }

    static func ==(lhs: Header, rhs: Header) -> Bool {
        return lhs.level == rhs.level
    }
}
