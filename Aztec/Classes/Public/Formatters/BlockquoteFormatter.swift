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
        style.paragraphSpacing = Metrics.defaultIndentation
        style.paragraphSpacingBefore = Metrics.defaultIndentation

        return [
            NSParagraphStyleAttributeName: style,
            Blockquote.attributeName: Blockquote()
        ]
    }()

    func present(inAttributes attributes: [String : AnyObject]) -> Bool {
        return attributes[Blockquote.attributeName] is Blockquote
    }
}

