import Foundation

enum GallerySupportedAttribute: String {
    case columns = "columns"
    case ids = "ids"
    case order = "order"
    case orderBy = "orderBy"
    
    static func isSupported(_ attributeName: String) -> Bool {
        return GallerySupportedAttribute(rawValue: attributeName) != nil
    }
}
