import Aztec
import Foundation

enum GutenbergAttribute: String {
    case selfCloser = "selfcloser"
    case blockOpener = "opener"
    case blockCloser = "closer"
}

extension Attribute {
    convenience init(name: GutenbergAttribute, value: Attribute.Value) {
        self.init(name: name.rawValue, value: value)
    }
}
