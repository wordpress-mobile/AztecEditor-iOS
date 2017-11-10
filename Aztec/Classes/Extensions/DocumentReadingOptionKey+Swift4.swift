import UIKit

#if swift(>=4.0)
    public typealias DocumentReadingOptionKey = NSAttributedString.DocumentReadingOptionKey
#else
    public typealias DocumentReadingOptionKey = String
#endif

extension DocumentReadingOptionKey {
    #if swift(>=4.0)
    #else
    public static let documentType = NSDocumentTypeDocumentAttribute
    #endif
    
}
