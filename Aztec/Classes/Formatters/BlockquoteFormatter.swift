import Foundation
import UIKit

struct BlockquoteFormatter: ParagraphAttributeFormatter {
    let attributes: [String: AnyObject] = {
        let style = NSMutableParagraphStyle()
        style.headIndent = Metrics.blockquoteIndentation
        style.firstLineHeadIndent = style.headIndent
        style.tailIndent = -Metrics.blockquoteIndentation

        return [
            NSParagraphStyleAttributeName: style
        ]
    }()

    func present(inAttributes attributes: [String : AnyObject]) -> Bool {
        guard let style = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle else {
            return false
        }
        return style.tailIndent == -Metrics.blockquoteIndentation
    }
}

