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

        func markerText(forItemNumber number: Int, level: Int) -> String {
            switch self {
            case .ordered:      return "\t\(number)."
            case .unordered:    return unorderedMarker(for: level)
            }
        }

        func unorderedMarker(for level: Int) -> String {
            switch level {
            case 0:
                return "\t\u{2022}"
            default:
                // Using the same black bullet for now until Android side is able to edit bullets by level too.
                // Then this should be updated to "{25E6}"
                return "\t\u{2022}"
            }
        }
    }

    // MARK: - Properties

    /// Kind of List: Ordered / Unordered
    ///
    let style: Style
    let level: Int

    init(style: Style, with representation: HTMLRepresentation? = nil, level: Int = 0) {
        self.style = style
        self.level = level
        super.init(with: representation)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValue(forKey: String(describing: Style.self)),
            let decodedStyle = Style(rawValue:aDecoder.decodeInteger(forKey: String(describing: Style.self))) {
            style = decodedStyle
        } else {
            style = .ordered
        }
        if aDecoder.containsValue(forKey: String(describing: \TextList.level)) {
            level = aDecoder.decodeInteger(forKey: String(describing: \TextList.level))
        } else {
            level = 0
        }

        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(style.rawValue, forKey: String(describing: Style.self))
        aCoder.encode(level, forKey: String(describing: \TextList.level))
    }

    public static func ==(lhs: TextList, rhs: TextList) -> Bool {
        return lhs.style == rhs.style 
    }
}
