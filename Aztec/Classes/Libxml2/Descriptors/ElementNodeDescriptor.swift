import Foundation

extension Libxml2 {
    
    /// This class describes an element node for the purpose of either:
    ///
    /// - Searching for a matching element node, or
    /// - Creating it.
    ///
    class ElementNodeDescriptor: CustomReflectable {
        
        let name: String
        let attributes: [Attribute]
        let matchingNames: [String]
        
        // MARK: - CustomReflectable
        
        public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name, "attributes": attributes, "matchingNames": matchingNames])
            }
        }
        
        init(name: String, attributes: [Attribute] = [], matchingNames: [String] = []) {
            self.name = name
            self.attributes = attributes
            self.matchingNames = matchingNames
        }

        convenience init(elementType: StandardElementType, attributes: [Attribute] = []) {
            self.init(name: elementType.rawValue, attributes: attributes, matchingNames: elementType.equivalentNames)
        }
        
        // MARK: - Introspection
        
        func isBlockLevel() -> Bool {
            return StandardElementType.isBlockLevelNodeName(name)
        }
    }
}
