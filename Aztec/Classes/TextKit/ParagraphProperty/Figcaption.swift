import Foundation
import UIKit

class Figcaption: ParagraphProperty {
    
    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
    
    override public init(with representation: HTMLRepresentation? = nil) {
        super.init(with: representation)
    }
    
    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    
    // MARK: - Dynamic Styling

    override func addDynamicAttributes(to attributes: [NSAttributedStringKey:Any]) -> [NSAttributedStringKey:Any] {
        var finalAttributes = attributes
        let font = UIFont.systemFont(ofSize: 10)
        
        finalAttributes[.font] = font
        finalAttributes[.foregroundColor] = UIColor.darkGray
        
        return finalAttributes
    }
}
