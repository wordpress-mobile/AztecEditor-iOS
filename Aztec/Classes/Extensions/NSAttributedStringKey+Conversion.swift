import Foundation
import UIKit


// MARK: - AttributedStringKey converters for Swift 3.2 and 4.0 support
//
extension NSAttributedStringKey {

    /// Converts a collection of NSAttributedString Attributes, with 'NSAttributedStringKey' instances as 'Keys', into an
    /// equivalent collection that uses regular 'String' instances as keys.
    ///
    @inline(__always)
    static func convertToRaw(_ attributes: [NSAttributedStringKey: Any]) -> [String: Any] {
        var output = [String: Any]()
        
        for (key, value) in attributes {
            output[key.rawValue] = value
        }
        
        return output
    }


    /// Converts a collection of NSAttributedString Attributes, with 'String' instances as 'Keys', into an equivalent
    /// collection that uses the new 'NSAttributedStringKey' enum as keys.
    ///
    @inline(__always)
    static func convertFromRaw(_ attributes: [String: Any]) -> [NSAttributedStringKey: Any] {
        var output = [NSAttributedStringKey: Any]()
        
        for (key, value) in attributes {
            let wrappedKey = NSAttributedStringKey(key)
            output[wrappedKey] = value
        }
        
        return output
    }
}
