import Foundation
import UIKit

open class ParagraphStyle: NSMutableParagraphStyle {

    var textList: TextList?

    override init() {
        textList = nil
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        textList = nil
        super.init()
    }

    override open func setParagraphStyle(_ obj: NSParagraphStyle) {
        if let paragrahStyle = obj as? ParagraphStyle {
            textList = paragrahStyle.textList
        }
        super.setParagraphStyle(obj)
    }

    private static let tabStepInterval = 8
    private static let tabStepCount    = 12
    
    open override class var `default`: NSParagraphStyle {
        let style = ParagraphStyle()

        var tabStops = [NSTextTab]()

        for intervalNumber in (1 ..< tabStepCount) {
            let location = intervalNumber * tabStepInterval
            let textTab = NSTextTab(textAlignment: .natural, location: CGFloat(location), options: [:])

            tabStops.append(textTab)
        }

        style.tabStops = tabStops

        return style
    }

    class var defaultList : ParagraphStyle {
        let style = ParagraphStyle()
        style.setParagraphStyle(self.default)

        style.headIndent = 12
        style.firstLineHeadIndent = style.headIndent        
        return style
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let otherParagraph = object as? ParagraphStyle else {
            return false
        }

        if textList == nil || otherParagraph.textList == nil {
            return super.isEqual(object)
        }

        if textList == nil && otherParagraph.textList != nil {
            return false
        }

        if textList != nil && otherParagraph.textList == nil {
            return false
        }

        if textList! != otherParagraph.textList! {
            return false
        }

        return super.isEqual(object)
    }

    static func ==(lhs: ParagraphStyle, rhs: ParagraphStyle) -> Bool {
        return lhs.isEqual(rhs)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let result = super.copy(with: zone)
        let thisResult = ParagraphStyle()
        thisResult.setParagraphStyle(result as! NSParagraphStyle)
        thisResult.textList = textList

        return thisResult
    }

    open override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let result = super.mutableCopy(with: zone)
        let thisResult = ParagraphStyle()
        thisResult.setParagraphStyle(result as! NSParagraphStyle)
        thisResult.textList = textList

        return thisResult
    }

    var debugString: String {
        return description
    }

    open override var description:String {
        return super.description + "\nTextList:\(textList?.style)"
    }
}
