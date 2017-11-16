import UIKit

#if swift(>=4.0)
    public typealias DocumentType = NSAttributedString.DocumentType
#else
    public typealias DocumentType = String
#endif

extension DocumentType {
    #if swift(>=4.0)
    #else
    
    public static let plain = NSPlainTextDocumentType
    public static let rtf = NSRTFTextDocumentType
    public static let rtfd = NSRTFDTextDocumentType
    #endif
    
}

