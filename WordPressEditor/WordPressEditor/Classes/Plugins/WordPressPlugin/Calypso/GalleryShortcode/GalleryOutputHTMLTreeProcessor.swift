import Aztec
import Foundation

public class GalleryOutputHTMLTreeProcessor: HTMLTreeProcessor {
    
    let converter = GalleryOutputElementConverter()
    
    public init() {}
    
    public func process(_ rootNode: RootNode) {
        rootNode.children = process(rootNode.children)
    }
    
    func process(_ nodes: [Node]) -> [Node] {
        return nodes.map ({ (node) -> Node in
            guard let element = node as? ElementNode else {
                return node
            }
            
            element.children = process(element.children)
            
            guard element.type == .gallery else {
                return element
            }
            
            return converter.convert(element)
        })
    }
}
