import Foundation

class GenericElementToTagConverter: ElementToTagConverter {
    func convert(_ elementNode: ElementNode) -> Tag {
        let openingTag = self.openingTag(for: elementNode)
        let closingTag = self.closingTag(for: elementNode)
        
        return (openingTag, closingTag)
    }
}

// MARK: - Opening and Closing Tag Conversion Logic

private extension GenericElementToTagConverter {
    /// Returns the Opening Tag for a given Element Node
    ///
    private func openingTag(for node: ElementNode) -> String {
        let attributes = serialize(attributes: node.attributes)
        
        return "<" + node.name + attributes + ">"
    }
    
    
    /// Returns the Closing Tag for a given Element Node, if its even required
    ///
    private func closingTag(for elementNode: ElementNode) -> String? {
        guard elementNode.requiresClosingTag() else {
            return nil
        }
        
        return "</" + elementNode.name + ">"
    }
    
    /// Indicates if an ElementNode is a Void Element (expected not to have a closing tag), or not.
    ///
    private static func requiresClosingTag(_ elementNode: ElementNode) -> Bool {
        return !elementNode.isVoid()
    }
}


// MARK: - Attribute Conversion Logic

private extension GenericElementToTagConverter {
    /// Serializes an array of attributes into their HTML representation
    ///
    private func serialize(attributes: [Attribute]) -> String {
        return attributes.reduce("") { (html, attribute) in
            return html + String(.space) + attribute.toString()
        }
    }
}
