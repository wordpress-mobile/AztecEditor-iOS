import Foundation
import UIKit


// MARK: - Text List
//
open class TextList: ParagraphProperty {

    // MARK: - Nested Types

    /// List Styles
    ///
    public enum Style: Int {
        case ordered
        case unordered

        func markerText(forItemNumber number: Int) -> String {
            switch self {
            case .ordered:      return "\(number)."
            case .unordered:    return "\u{2022}"
            }
        }
    }

    public let reversed: Bool

    public let start: Int?

    // MARK: - Properties

    /// Kind of List: Ordered / Unordered
    ///
    let style: Style

    init(style: Style, start: Int? = nil, reversed: Bool = false, with representation: HTMLRepresentation? = nil) {
        self.style = style

        if let representation = representation, case let .element( html ) = representation.kind {
            self.reversed = html.attribute(ofType: .reversed) != nil
            
            if let startAttribute = html.attribute(ofType: .start),
                case let .string( value ) = startAttribute.value,
                let start = Int(value)
            {
                self.start = start
            } else {
                self.start = nil
            }
        } else {
            self.start = start
            self.reversed = reversed
        }
        super.init(with: representation)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValue(forKey: String(describing: Style.self)),
            let decodedStyle = Style(rawValue:aDecoder.decodeInteger(forKey: String(describing: Style.self))) {
            style = decodedStyle
        } else {
            style = .ordered
        }
        if aDecoder.containsValue(forKey: AttributeType.start.rawValue) {
            let decodedStart = aDecoder.decodeInteger(forKey: AttributeType.start.rawValue)
            start = decodedStart
        } else {
            start = nil
        }

        if aDecoder.containsValue(forKey: AttributeType.reversed.rawValue) {
            let decodedReversed = aDecoder.decodeBool(forKey: AttributeType.reversed.rawValue)
            reversed = decodedReversed
        } else {
            reversed = false
        }

        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(style.rawValue, forKey: String(describing: Style.self))
        aCoder.encode(start, forKey: AttributeType.start.rawValue)
        aCoder.encode(reversed, forKey: AttributeType.reversed.rawValue)
    }

    public static func ==(lhs: TextList, rhs: TextList) -> Bool {
        return lhs.style == rhs.style && lhs.start == rhs.start && lhs.reversed == rhs.reversed
    }
}
