import Foundation


// MARK: - HTMLDiv
//
class HTMLDiv: ParagraphProperty {

    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }

    override public init(with representation: HTMLRepresentation? = nil) {
        super.init(with: representation)
    }

    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }

    static func ==(lhs: HTMLDiv, rhs: HTMLDiv) -> Bool {
        return lhs === rhs
    }
}
