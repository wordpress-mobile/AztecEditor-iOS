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
        try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSAttributedString
    }
    
}
