import Foundation

/// This extension exists for the solt purpose of supporting both Swift 3.2 and Swift 4.
/// This extension should be removed when dropping support for Swift 3.2.
///
extension NSAttributedString {
    #if swift(>=4.0)
    #else
    let NSDocumentTypeDocumentAttribute = NSDocumentTypeDocumentAttribute
    #endif
}
