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
            case .ordered:      return "\t\(number)."
            case .unordered:    return "\t\u{2022}"
            }
        }
    }

    // MARK: - Properties

    /// Kind of List: Ordered / Unordered
    ///
    let style: Style

    init(style: Style, with representation: HTMLRepresentation? = nil) {
        self.style = style
        super.init(with: representation)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValue(forKey: String(describing: Style.self)),
            let decodedStyle = Style(rawValue:aDecoder.decodeInteger(forKey: String(describing: Style.self))) {
            style = decodedStyle
        } else {
            style = .ordered
        }
        super.init(coder: aDecoder)
    }

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(style.rawValue, forKey: String(describing: Style.self))
    }

    public static func ==(lhs: TextList, rhs: TextList) -> Bool {
        return lhs.style == rhs.style 
    }
}
