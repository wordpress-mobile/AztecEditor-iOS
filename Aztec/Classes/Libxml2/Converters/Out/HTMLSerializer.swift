import Foundation
import libxml2


// MARK: - Node to HTML-String Serialization Protocol
//
public protocol HTMLSerializer {
    func serialize(_ node: Node) -> String
}
