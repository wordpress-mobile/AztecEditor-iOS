import Foundation
import UIKit

open class ParagraphStyle: NSMutableParagraphStyle, CustomReflectable {

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["blockquote": blockquote as Any, "headerLevel": headerLevel, "htmlParagraph": htmlParagraph as Any, "textList": textLists as Any])
        }
    }

    private enum EncodingKeys: String {
        case headerLevel
    }

    var blockquote: Blockquote?
    var htmlParagraph: HTMLParagraph?
    var textLists: [TextList] = []
    
    var headerLevel: Int = 0

    override init() {
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        if let encodedLists = aDecoder.decodeObject(forKey:String(describing: TextList.self)) as? [TextList] {
            textLists = encodedLists
        }
        if aDecoder.containsValue(forKey: String(describing: Blockquote.self)) {
            blockquote = aDecoder.decodeObject(forKey: String(describing: Blockquote.self)) as? Blockquote
        }

        aDecoder.decodeInteger(forKey: EncodingKeys.headerLevel.rawValue)
        
        super.init(coder: aDecoder)
    }

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)

        aCoder.encode(textLists, forKey: String(describing: TextList.self))

        if let blockquote = self.blockquote {
            aCoder.encode(blockquote, forKey: String(describing: Blockquote.self))
        }

        aCoder.encode(headerLevel, forKey: EncodingKeys.headerLevel.rawValue)
    }

    override open func setParagraphStyle(_ obj: NSParagraphStyle) {
        super.setParagraphStyle(obj)
        if let paragrahStyle = obj as? ParagraphStyle {
            blockquote = paragrahStyle.blockquote
            headerLevel = paragrahStyle.headerLevel
            htmlParagraph = paragrahStyle.htmlParagraph
            textLists = paragrahStyle.textLists
        }
    }

    open override class var `default`: NSParagraphStyle {
        let style = ParagraphStyle()

        var tabStops = [NSTextTab]()

        for intervalNumber in (1 ..< Metrics.tabStepCount) {
            let location = intervalNumber * Metrics.tabStepInterval
            let textTab = NSTextTab(textAlignment: .natural, location: CGFloat(location), options: [:])

            tabStops.append(textTab)
        }

        style.tabStops = tabStops

        return style
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let otherParagraph = object as? ParagraphStyle else {
            return false
        }

        if blockquote != otherParagraph.blockquote
            || headerLevel != otherParagraph.headerLevel
            || htmlParagraph != otherParagraph.htmlParagraph
            || textLists != otherParagraph.textLists {
            return false
        }
        
        return super.isEqual(object)
    }

    static func ==(lhs: ParagraphStyle, rhs: ParagraphStyle) -> Bool {
        return lhs.isEqual(rhs)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let originalCopy = super.copy(with: zone) as! NSParagraphStyle
        let copy = ParagraphStyle()
        copy.setParagraphStyle(originalCopy)
        copy.blockquote = blockquote
        copy.headerLevel = headerLevel
        copy.htmlParagraph = htmlParagraph
        copy.textLists = textLists

        return copy
    }

    open override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let originalCopy = super.mutableCopy(with: zone) as! NSParagraphStyle
        let copy = ParagraphStyle()
        copy.setParagraphStyle(originalCopy)
        copy.blockquote = blockquote
        copy.headerLevel = headerLevel
        copy.htmlParagraph = htmlParagraph
        copy.textLists = textLists

        return copy
    }

    open override var hash: Int {
        var hash: Int = super.hash
        if blockquote != nil {
            hash = hash ^ String(describing: Blockquote.self).hashValue
        }
        for list in textLists {
            hash = hash ^ list.style.hashValue
        }

        hash = hash ^ headerLevel.hashValue
        return hash
    }

    var debugString: String {
        return description
    }

    open override var description: String {
        return super.description + " Blockquote: \(String(describing:blockquote)),\n HeaderLevel: \(headerLevel),\n HTMLParagraph: \(String(describing: htmlParagraph)),\n TextLists: \(textLists)"
    }
}
