import Foundation

class Blockquote: ParagraphProperty {

    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }

    override public init(with representation: HTMLRepresentation? = nil) {
        super.init(with: representation)
    }

    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }

    static func ==(lhs: Blockquote, rhs: Blockquote) -> Bool {
        return lhs.representation == rhs.representation
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let rightBlockquote = object as? Blockquote else {
            return false
        }
        
        return self == rightBlockquote
    }
}

