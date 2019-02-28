import Foundation

open class ParagraphProperty: NSObject, NSCoding {

    open var representation: HTMLRepresentation?
    
    public override init() {
        self.representation = nil
    }

    public init(with representation: HTMLRepresentation? = nil) {
        self.representation = representation
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
    }

    static func ==(lhs: ParagraphProperty, rhs: ParagraphProperty) -> Bool {
        return lhs === rhs
    }
    
    // MARK: - Dynamic Styling
    
    /// This method will be called by the `TextStorage` to add any necessary dynamic attributes to the range covered
    /// by a paragraph property.  This allows the paragraph property to define styling that shares its lifecycle.
    /// Once the paragraph property is removed, the dynamic properties will go away automatically.
    ///
    /// The default implementation does not add any dynamic styling.
    ///
    func addDynamicAttributes(to attributes: [NSAttributedString.Key:Any]) -> [NSAttributedString.Key:Any] {
        return attributes
    }
}
