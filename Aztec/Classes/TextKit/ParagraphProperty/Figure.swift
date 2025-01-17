import Foundation

class Figure: ParagraphProperty {
    
    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }

    override open class var supportsSecureCoding: Bool { true }

    override public init(with representation: HTMLRepresentation? = nil) {
        super.init(with: representation)
    }
    
    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
}
