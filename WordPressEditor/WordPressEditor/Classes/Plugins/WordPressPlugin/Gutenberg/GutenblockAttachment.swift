import Foundation
import UIKit

class GutenblockAttachment: NSTextAttachment {
    static let tagDataEncodingKey = "tagData"
    
    let tagData: String
    
    required init?(coder aDecoder: NSCoder) {
        guard let tagData = aDecoder.decodeObject(forKey: GutenblockAttachment.tagDataEncodingKey) as? String else {
            return nil
        }
        
        self.tagData = tagData
        
        super.init(coder: aDecoder)
    }
    
    init(_ tagData: String) {
        self.tagData = tagData
        
        super.init(data: nil, ofType: nil)
    }
}
