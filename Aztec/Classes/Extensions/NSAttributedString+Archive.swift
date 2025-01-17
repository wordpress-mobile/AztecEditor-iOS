import Foundation

// MARK: - NSAttributedString Archive methods
//
extension NSAttributedString
{
    static let pastesboardUTI = "com.wordpress.aztec.attributedString"

    func archivedData() throws -> Data {
        return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }

    static func unarchive(with data: Data) throws -> NSAttributedString? {
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)
    }
    
}
