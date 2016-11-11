import Foundation

extension Libxml2 {
    
    /// This class describes an element node for the purpose of either:
    ///
    /// - Searching for a matching element node, or
    /// - Creating it.
    ///
    class ElementNodeDescriptor {
        
        let name: String
        let attributes: [Attribute]
        let matchingNames: [String]
        
        init(name: String, attributes: [Attribute] = [], matchingNames: [String] = []) {
            self.name = name
            self.attributes = attributes
            self.matchingNames = matchingNames
        }
        
        func isBlockLevel() -> Bool {
            return StandardElementType.isBlockLevelNodeName(name)
        }
    }
}
