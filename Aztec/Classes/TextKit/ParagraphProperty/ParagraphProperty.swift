import Foundation

open class ParagraphProperty: NSObject, NSCoding {

    var representation: HTMLRepresentation?
    
    public override init() {
        self.representation = nil
    }

    init(with representation: HTMLRepresentation? = nil) {
        self.representation = representation
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
    }

    static func ==(lhs: ParagraphProperty, rhs: ParagraphProperty) -> Bool {
        return lhs == rhs
    }
}
