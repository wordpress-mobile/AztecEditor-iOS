import Foundation

// MARK: - NSAttributedString Archive methods
//
extension NSAttributedString
{
    static let pastesboardUTI = "com.wordpress.aztec.attributedString"

    func archivedData() -> Data {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        return data
    }

    static func unarchive(with data: Data) -> NSAttributedString? {
        let attributedString = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSAttributedString
        return attributedString
    }
    
}
