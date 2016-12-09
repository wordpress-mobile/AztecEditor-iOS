import Foundation
import UIKit

struct TextListFormatter: ParagraphAttributeFormatter {

    let listStyle: TextList.Style

    init(style: TextList.Style) {
        self.listStyle = style
    }

    var attributes: [String: AnyObject] {
        get {
            let style = ParagraphStyle()
            style.headIndent = Metrics.defaultIndentation
            style.firstLineHeadIndent = style.headIndent
            style.textList = TextList(style: self.listStyle)

            return [
                NSParagraphStyleAttributeName: style
            ]
        }
    }

    func present(inAttributes attributes: [String : AnyObject]) -> Bool {
        guard let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle,
              let textList = paragraphStyle.textList else {
            return false
        }
        return textList.style == listStyle
    }
}

