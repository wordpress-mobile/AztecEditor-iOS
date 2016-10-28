import Foundation
import UIKit

class Blockquote {
    static let attributeName = "AZBlockquote"
}

struct BlockquoteFormatter: ParagraphAttributeFormatter {
    let attributes: [String: AnyObject] = {
        let style = NSMutableParagraphStyle()
        style.headIndent = Metrics.defaultIndentation
        style.firstLineHeadIndent = style.headIndent
        style.tailIndent = -Metrics.defaultIndentation

        // We're going to need custom drawing to get the background that we want,
        // but for now let's use a light grey background to aid debugging.
        let backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        return [
            NSBackgroundColorAttributeName: backgroundColor,
            NSParagraphStyleAttributeName: style,
            Blockquote.attributeName: Blockquote()
        ]
    }()

    func present(inAttributes attributes: [String : AnyObject]) -> Bool {
        return attributes[Blockquote.attributeName] is Blockquote
    }
}

