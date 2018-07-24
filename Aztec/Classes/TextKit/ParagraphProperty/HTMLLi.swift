import Foundation

class HTMLLi: ParagraphProperty {

    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }

    override public init(with representation: HTMLRepresentation? = nil) {
        super.init(with: representation)
    }

    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }

    static func ==(lhs: HTMLLi, rhs: HTMLLi) -> Bool {
        return false
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let rightElement = object as? HTMLLi else {
            return false
        }
        
        return self == rightElement
    }
}
