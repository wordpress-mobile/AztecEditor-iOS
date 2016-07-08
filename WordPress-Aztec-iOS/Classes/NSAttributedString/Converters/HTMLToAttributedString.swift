import Foundation

class HTMLToAttributedString: Converter {
    func convert(html: NSData) throws -> NSAttributedString {
        let htmlToNode = Libxml2.In.HTMLConverter()
        let nodeToAttributedString = HMTLNodeToAttributedString()

        let node = try htmlToNode.convert(html)
        return nodeToAttributedString.convert(node)
    }
}