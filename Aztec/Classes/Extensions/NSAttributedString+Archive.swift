import Foundation
import UIKit

// MARK: - NSAttributedString Archive methods
//
extension NSAttributedString
{
    static let pasteboardUTI = UIPasteboard.UTType(identifier: "com.wordpress.aztec.attributedString")

    func archivedData() throws -> Data {
        return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }

    static func unarchive(with data: Data) throws -> NSAttributedString? {
        return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSAttributedString.self, HTMLRepresentation.self], from: data) as? NSAttributedString
    }
    
}
