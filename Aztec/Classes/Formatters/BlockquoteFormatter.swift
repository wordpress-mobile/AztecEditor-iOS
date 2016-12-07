import Foundation
import UIKit

class Blockquote: NSObject, NSCoding {
    static let attributeName = "AZBlockquote"

    public func encode(with aCoder: NSCoder) {

    }

    override public init() {

    }

    required public init?(coder aDecoder: NSCoder){

    }
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

