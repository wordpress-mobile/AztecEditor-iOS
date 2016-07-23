import Foundation

extension NSAttributedString {

    func rootNode() -> Libxml2.HTML.ElementNode {

        guard let rootNode = attribute(Aztec.AttributeName.rootNode, atIndex: 0, effectiveRange: nil) as? Libxml2.HTML.ElementNode else {

            fatalError("We lost the root node during editing.")
        }

        return rootNode
    }
}