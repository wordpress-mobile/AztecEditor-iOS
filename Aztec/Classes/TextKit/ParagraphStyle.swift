import Foundation
import UIKit

enum ParagraphHint: Int {
    case paragraph
    case blockquote
    case orderedList
    case unorderedList
    case header1
    case header2
    case header3
    case header4
    case header5
    case header6
}

open class ParagraphStyle: NSMutableParagraphStyle, CustomReflectable {

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["blockquote": blockquote as Any, "headerLevel": headerLevel, "htmlParagraph": htmlParagraph as Any])//, "textList": textLists as Any])
        }
    }

    private enum EncodingKeys: String {
        case headerLevel
    }

    var blockquote: Blockquote?
    var htmlParagraph: HTMLParagraph?
    //var textLists: [TextList] = []
    
    var headerLevel: Int = 0

    var paragraphHints: [ParagraphHint] = []

    override init() {
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
//        if let encodedLists = aDecoder.decodeObject(forKey:String(describing: TextList.self)) as? [TextList] {
//            textLists = encodedLists
//        }
        if aDecoder.containsValue(forKey: String(describing: Blockquote.self)) {
            blockquote = aDecoder.decodeObject(forKey: String(describing: Blockquote.self)) as? Blockquote
        }

        headerLevel = aDecoder.decodeInteger(forKey: EncodingKeys.headerLevel.rawValue)

        if let encodedHints = aDecoder.decodeObject(forKey:String(describing: ParagraphHint.self)) as? [ParagraphHint] {
            paragraphHints = encodedHints
        }
        
        super.init(coder: aDecoder)
    }

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)

//        aCoder.encode(textLists, forKey: String(describing: TextList.self))

        if let blockquote = self.blockquote {
            aCoder.encode(blockquote, forKey: String(describing: Blockquote.self))
        }

        aCoder.encode(headerLevel, forKey: EncodingKeys.headerLevel.rawValue)

        aCoder.encode(paragraphHints, forKey: String(describing: ParagraphHint.self))
    }

    override open func setParagraphStyle(_ obj: NSParagraphStyle) {
        super.setParagraphStyle(obj)
        if let paragrahStyle = obj as? ParagraphStyle {
            headIndent = 0
            firstLineHeadIndent = 0
            tailIndent = 0
            paragraphSpacing = 0
            paragraphSpacingBefore = 0

            baseHeadIndent = paragrahStyle.baseHeadIndent
            baseFistLineHeadIndent = paragrahStyle.baseFistLineHeadIndent
            baseTailIndent = paragrahStyle.baseTailIndent
            baseParagraphSpacing = paragrahStyle.baseParagraphSpacing
            baseParagraphSpacingBefore = paragrahStyle.baseParagraphSpacingBefore

            blockquote = paragrahStyle.blockquote
            headerLevel = paragrahStyle.headerLevel
            htmlParagraph = paragrahStyle.htmlParagraph
//            textLists = paragrahStyle.textLists
            paragraphHints = paragrahStyle.paragraphHints
        }
    }

    func calculateExtraHeadIndent() -> CGFloat {
        return (CGFloat(depth(paragraphHint: .orderedList) + depth(paragraphHint: .unorderedList)) * Metrics.listTextIndentation)
    }

    open override var headIndent: CGFloat {
        get {
            let extra: CGFloat = calculateExtraHeadIndent()

            return baseHeadIndent + extra
        }

        set {
            baseHeadIndent = newValue
        }
    }

    open override var firstLineHeadIndent: CGFloat {
        get {
            let extra: CGFloat = calculateExtraHeadIndent()

            return baseFistLineHeadIndent + extra
        }

        set {
            baseFistLineHeadIndent = newValue
        }
    }

    open override var tailIndent: CGFloat {
        get {
            let extra: CGFloat = (self.blockquote == nil ? 0 : 1) * Metrics.defaultIndentation

            return baseTailIndent - extra
        }

        set {
            baseTailIndent = newValue
        }
    }

    open override var paragraphSpacing: CGFloat {
        get {
            let extra: CGFloat = (self.blockquote == nil ? 0 : 1) * Metrics.defaultIndentation

            return baseParagraphSpacing + extra
        }

        set {
            baseParagraphSpacing = newValue
        }
    }

    open override var paragraphSpacingBefore: CGFloat {
        get {
            let extra: CGFloat = (self.blockquote == nil ? 0 : 1) * Metrics.defaultIndentation

            return baseParagraphSpacingBefore + extra
        }

        set {
            baseParagraphSpacingBefore = newValue
        }
    }

    var baseHeadIndent: CGFloat = 0
    var baseFistLineHeadIndent: CGFloat = 0
    var baseTailIndent: CGFloat = 0
    var baseParagraphSpacing: CGFloat = 0
    var baseParagraphSpacingBefore: CGFloat = 0

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
//            || textLists != otherParagraph.textLists
            || paragraphHints != otherParagraph.paragraphHints
        {
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
//        copy.textLists = textLists
        copy.paragraphHints = paragraphHints

        return copy
    }

    open override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let originalCopy = super.mutableCopy(with: zone) as! NSParagraphStyle
        let copy = ParagraphStyle()
        copy.setParagraphStyle(originalCopy)
        copy.blockquote = blockquote
        copy.headerLevel = headerLevel
        copy.htmlParagraph = htmlParagraph
//        copy.textLists = textLists
        copy.paragraphHints = paragraphHints

        return copy
    }

    open override var hash: Int {
        var hash: Int = super.hash
        if blockquote != nil {
            hash = hash ^ String(describing: Blockquote.self).hashValue
        }
//        for list in textLists {
//            hash = hash ^ list.style.hashValue
//        }

        hash = hash ^ headerLevel.hashValue

        for hint in paragraphHints {
            hash = hash ^ hint.hashValue
        }
        return hash
    }

    var debugString: String {
        return description
    }

    open override var description: String {
        return super.description + " Blockquote: \(String(describing:blockquote)),\n HeaderLevel: \(headerLevel),\n HTMLParagraph: \(String(describing: htmlParagraph))"//,\n TextLists: \(textLists)"
    }

    func has(paragraphHint: ParagraphHint) -> Bool {
        return paragraphHints.contains(paragraphHint)
    }

    func remove(paragraphHint: ParagraphHint) {
        let pos = positionOfFirst(paragraphHint: paragraphHint)
        if (pos != NSNotFound) {
            paragraphHints.remove(at: pos)
        }
    }

    func positionOfFirst(paragraphHint: ParagraphHint) -> Int {
        var pos = NSNotFound
        for i in (0..<paragraphHints.count).reversed() {
            if paragraphHints[i] == paragraphHint {
                pos = i
                break
            }
        }
        return pos
    }

    func add(paragraphHint: ParagraphHint) {
        paragraphHints.append(paragraphHint)
    }

    func replace(paragraphHint: ParagraphHint) {
        let pos = positionOfFirst(paragraphHint: paragraphHint)
        if (pos != NSNotFound) {
            paragraphHints[pos] = paragraphHint
        }
    }

    func depth(paragraphHint: ParagraphHint) -> Int {
        var depth = 0
        for loopParagraphHint in paragraphHints {
            if paragraphHint == loopParagraphHint {
                depth += 1
            }
        }
        return depth
    }

    func depth(paragraphHintsToSearch: Set<ParagraphHint>) -> Int {
        var depth = 0
        for loopParagraphHint in paragraphHints {
            if paragraphHintsToSearch.contains(loopParagraphHint) {
                depth += 1
            }
        }
        return depth
    }

    func deepest(paragraphHint: ParagraphHint) -> ParagraphHint? {        
        for loopParagrahHint in paragraphHints.reversed() {
            if loopParagrahHint == paragraphHint {
                return loopParagrahHint
            }
        }
        return nil
    }

    func deepest(paragraphHintsToSearch: Set<ParagraphHint>) -> ParagraphHint? {
        for loopParagrahHint in paragraphHints.reversed() {
            if paragraphHintsToSearch.contains(loopParagrahHint) {
                return loopParagrahHint
            }
        }
        return nil
    }

}
