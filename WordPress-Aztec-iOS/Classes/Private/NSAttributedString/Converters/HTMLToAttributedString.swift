import Foundation

class HTMLToAttributedString: Converter {

    func convert(html: String) throws -> NSAttributedString {
        let htmlToNode = Libxml2.In.HTMLConverter()
        let nodeToAttributedString = HMTLNodeToNSAttributedString()

        let node = try htmlToNode.convert(html)

        return nodeToAttributedString.convert(node)
    }
}