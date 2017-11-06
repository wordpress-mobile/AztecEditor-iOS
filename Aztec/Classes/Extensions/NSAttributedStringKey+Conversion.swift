import Foundation
import UIKit


// MARK: - NSAttributedStringKey Helpers
//
extension NSAttributedStringKey {

    ///
    ///
    static func convertToRaw(attributes: [NSAttributedStringKey: Any]) -> [String: Any] {
        var output = [String: Any]()
        for (key, value) in attributes {
            output[key.rawValue] = value
        }

        return output
    }


    ///
    ///
    static func convertFromRaw(attributes: [String: Any]) -> [NSAttributedStringKey: Any] {
        var output = [NSAttributedStringKey: Any]()
        for (key, value) in attributes {
            let wrappedKey = NSAttributedStringKey(key)
            output[wrappedKey] = value
        }

        return output
    }
}
