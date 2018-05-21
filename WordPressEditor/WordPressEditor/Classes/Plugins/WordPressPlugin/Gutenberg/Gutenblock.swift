import Aztec
import Foundation
import UIKit

class Gutenblock: ParagraphProperty {
    public init(storing representation: HTMLRepresentation? = nil) {
        super.init(with: representation)
    }
    
    required public init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
}
