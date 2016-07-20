import Foundation

class HTMLToAttributedString: Converter {

    func convert(html: NSData) throws -> NSAttributedString {
        let htmlToNode = Libxml2.In.HTMLConverter()
        let nodeToAttributedString = HMTLNodeToNSAttributedString()

        let node = try htmlToNode.convert(html)
        let rootNode = Libxml2.HTML.ElementNode(name: Aztec.AttributeName.rootNode, attributes: [], children: [node])

        node.parent = rootNode

        return nodeToAttributedString.convert(rootNode)
    }
}