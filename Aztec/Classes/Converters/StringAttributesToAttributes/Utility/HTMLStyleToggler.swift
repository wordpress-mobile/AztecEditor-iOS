import Foundation

/// This is a utility class that contains some common logic for toggling styles in
/// an array of element nodes.
///
open class HTMLStyleToggler {
    private let cssAttributeMatcher: CSSAttributeMatcher
    private let defaultElement: Element

    init(
        defaultElement: Element,
        cssAttributeMatcher: CSSAttributeMatcher) {
        
        self.cssAttributeMatcher = cssAttributeMatcher
        self.defaultElement = defaultElement
    }

    // MARK: - Enabling & Disabling
    
    open func disable(in elementNodes: [ElementNode]) -> [ElementNode] {
        
        let elementNodes = elementNodes.compactMap { (elementNode) -> ElementNode? in
            let elementRepresentsStyle = defaultElement.equivalentNames.contains(elementNode.type)
            
            guard elementRepresentsStyle else {
                return elementNode
            }
            
            if elementNode.attributes.count > 0 {
                return ElementNode(type: .span, attributes: elementNode.attributes, children: elementNode.children)
            } else {
                return nil
            }
        }
        
        for elementNode in elementNodes {
            elementNode.removeCSSAttributes(matching: cssAttributeMatcher)
        }
        
        return elementNodes
    }
    
    open func enable(in elementNodes: [ElementNode]) -> [ElementNode] {
        var elementNodes = elementNodes
        
        // We can now check if we have any CSS attribute that triggers the matcher.  If that's the case we can completely skip
        // adding the element.
        //
        for elementNode in elementNodes {
            let elementRepresentsStyle = defaultElement.equivalentNames.contains(elementNode.type)
            
            if elementRepresentsStyle || elementNode.containsCSSAttribute(matching: cssAttributeMatcher) {
                return elementNodes
            }
        }
        
        // Since there's no existing representation of the style, we will add the default one.
        elementNodes.append(ElementNode(type: defaultElement))
        return elementNodes
    }
}
