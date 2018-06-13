import Aztec
import Foundation

public class GalleryOutputHTMLTreeProcessor: HTMLTreeProcessor {
    
    let converter = GalleryOutputElementConverter()
    
    public init() {}
    
    public func process(_ rootNode: RootNode) {
        rootNode.children = rootNode.children.map ({ (node) -> Node in
            guard let element = node as? ElementNode,
                element.type == .gallery else {
                    return node
            }
            
            return converter.convert(element)
        })
    }
}
