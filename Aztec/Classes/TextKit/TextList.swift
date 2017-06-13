import Foundation
import UIKit


// MARK: - Text List
//
class TextList: ParagraphProperty
{
    // MARK: - Nested Types

    /// List Styles
    ///
    enum Style: Int {
        case ordered
        case unordered

        func markerText(forItemNumber number: Int) -> String {
            switch self {
            case .ordered:      return "\t\(number).\t"
            case .unordered:    return "\t\u{2022}\t\t"
            }
        }
    }

    // MARK: - Properties

    /// Kind of List: Ordered / Unordered
    ///
    let style: Style

    init(style: Style) {
        self.style = style
        super.init()
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

    static func ==(lhs: TextList, rhs: TextList) -> Bool {
        return lhs.style == rhs.style 
    }
}
