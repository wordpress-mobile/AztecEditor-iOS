import Aztec
import Foundation

class ParagraphRemovingProcessor: HTMLTreeProcessor {
    func process(_ rootNode: RootNode) -> RootNode {
        // All nodes at the root level that are not block nodes will be wrapped by paragraphs.
        var nodesToWrapInParagraph = [Node]()

        // First clean BRs:
        // - Converts single \n at root level to <br/>
        // - Converts double \n at root level to </p>
        // - Converts any \n non at root level to <br/>
        //
        // cleanNewlines()
        
        for (index, node) in rootNode.children.enumerated() {
            
            guard let textNode = node as? TextNode else {
                rootNode.children.remove(at: index)
                nodesToWrapInParagraph.append(node)
                continue
            }
            
            guard let elementNode = node as? ElementNode else {
            }
            
            guard !elementNode.isNodeType(.br) else {
                // Process
            }
            
            guard elementNode.isBlockLevelElement() else {
                rootNode.children.remove(at: index)
                nodesToWrapInParagraph.append(node)
                continue
            }
            
            
            if nodesToWrapInParagraph.count > 0 {
                let paragraph = wrapInParagraph(nodesToWrapInParagraph)
                
                rootNode.children.insert(paragraph, at: index)
                nodesToWrapInParagraph.removeAll()
            }
            
            continue
            
            guard elementNode.standardName != .br else {
                continue
            }
            // If <br>, with a <br> coming up next, wrap all pending nodes
            // Otherwise add the node to the list of nodes to wrap in a paragraph
        }

        return rootNode
    }
    
    private func wrapInParagraph(_ nodes: [Node]) -> ElementNode {
        return ElementNode(type: .p, attributes: [], children: nodes)
    }
    
    private func replaceLineBreaks(in element: ElementNode) {
            elementNode.isNodeType(.br) else {
                
        }
    }
}
