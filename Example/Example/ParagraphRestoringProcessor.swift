import Aztec
import Foundation

class ParagraphRestoringProcessor: HTMLTreeProcessor {
    func process(_ rootNode: RootNode) -> RootNode {
        
        var index = 0
        
        removeNewlinesFromChildren(of: rootNode)
        
        var wrapStartIndex = 0
        var wrapEndIndex = 0

        // First clean BRs:
        // - Converts single \n at root level to <br/>
        // - Converts double \n at root level to </p>
        // - Converts any \n non at root level to <br/>
        //
        // cleanNewlines()
        
        while index < rootNode.children.count {
            let node = rootNode.children[index]
            
            guard var textNode = node as? TextNode else {
                index += 1
                continue
            }
            /*
            if let range = textNode.text().rangeOfCharacter(from: .newlines) {
                if let nextRange = textNode.text().rangeOfCharacter(from: .newlines),
                    nextRange.lowerBound == range.upperBound {
                    
                    // Paragraph ending
                    
                    split(textNode)
                    
                    let nodesToWrap = rootNode.children.dropFirst(startIndex).dropLast(endIndex)
                } else {
                    // Single line break
                    
                    let leftText = textNode.text().substring(to: range.lowerBound)
                    let rightText = textNode.text().substring(from: range.upperBound)
                    
                    let leftTextNode = TextNode(text: leftText)
                    let brNode = ElementNode(type: .br)
                    let rightTextNode = TextNode(text: rightText)
                    
                    rootNode.children.remove(at: index)
                    rootNode.children.insert(rightTextNode, at: index)
                    rootNode.children.insert(brNode, at: index)
                    rootNode.children.insert(leftTextNode, at: index)
                }
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
            } */
            // If <br>, with a <br> coming up next, wrap all pending nodes
            // Otherwise add the node to the list of nodes to wrap in a paragraph
        }

        return rootNode
    }
    
    private func wrapInParagraph(_ nodes: [Node]) -> ElementNode {
        return ElementNode(type: .p, attributes: [], children: nodes)
    }
}

extension ParagraphRemovingProcessor {
    
    func removeNewlinesFromChildren(of rootNode: RootNode) {
        removeNewlinesFromChildren(of: rootNode, restoreParagraphs: true)
    }
    
    // Recursive
    private func removeNewlinesFromChildren(of element: ElementNode, restoreParagraphs: Bool) {
        
        var processedNodes = [Node]()
        var textToProcess = ""
        
        for child in element.children {
            guard let textNode = child as? TextNode else {
                if textToProcess.characters.count > 0 {
                    let nodes = self.nodes(for: textToProcess, restoreParagraphs: restoreParagraphs)
                    
                    processedNodes.append(contentsOf: nodes)
                    textToProcess = ""
                }
                
                if let element = child as? ElementNode {
                    removeNewlinesFromChildren(of: element, restoreParagraphs: false)
                }
                
                processedNodes.append(child)
                continue
            }
            
            textToProcess = textToProcess + textNode.text()
        }
        
        element.children = processedNodes
    }
    
    private func nodes(for text: String, restoreParagraphs: Bool) -> [Node] {
        if restoreParagraphs {
            return nodesRestoringBreaksAndParagraphs(for: text)
        } else {
            return nodesRestoringBreaks(for: text)
        }
    }
    
    private func nodesRestoringBreaksAndParagraphs(for text: String) -> [Node] {
        var nodes = [Node]()
        let paragraphs = text.components(separatedBy: "\n\n")
        
        for paragraph in paragraphs {
            let children = nodesRestoringBreaks(for: paragraph)
            let paragraph = ElementNode(type: .p, attributes: [], children: children)
            
            nodes.append(paragraph)
        }
        
        return nodes
    }
    
    private func nodesRestoringBreaks(for text: String) -> [Node] {
        var nodes = [Node]()
        let lines = text.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            if index > 0 {
                nodes.append(ElementNode(type: .br))
            }
            
            let textNode = TextNode(text: line)
            
            nodes.append(textNode)
        }
        
        return nodes
    }
 }
