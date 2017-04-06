import Foundation

extension Libxml2 {
    
    /// This class describes an element node for the purpose of either:
    ///
    /// - Searching for a matching element node, or
    /// - Creating it.
    ///
    class ElementNodeDescriptor: NodeDescriptor {
        let attributes: [Attribute]
        let childDescriptor: ElementNodeDescriptor?
        let matchingNames: [String]

        // MARK: - CustomReflectable
        
        public override var customMirror: Mirror {
            get {
                return Mirror(self, children: ["name": name, "attributes": attributes, "matchingNames": matchingNames])
            }
        }
        
        init(name: String, childDescriptor: ElementNodeDescriptor? = nil, attributes: [Attribute] = [], matchingNames: [String] = []) {
            self.attributes = attributes
            self.childDescriptor = childDescriptor
            self.matchingNames = matchingNames
            super.init(name: name)
        }

        convenience init(elementType: StandardElementType, childDescriptor: ElementNodeDescriptor? = nil, attributes: [Attribute] = []) {
            self.init(name: elementType.rawValue, childDescriptor: childDescriptor, attributes: attributes, matchingNames: elementType.equivalentNames)
        }
        
        // MARK: - Introspection
        
        func isBlockLevel() -> Bool {
            return StandardElementType.isBlockLevelNodeName(name)
        }
    }
}
