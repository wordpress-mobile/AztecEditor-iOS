import Foundation

class NSAttributedStringToHMTLNode: SafeConverter {
    typealias HTML = Libxml2.HTML
    typealias ElementNode = HTML.ElementNode
    typealias Node = HTML.Node
    typealias TextNode = HTML.TextNode

    let attributesConverter = HTMLAttributesToAttributesMetaData()

    func convert(string: NSAttributedString) -> Node {

        let fullRange = NSRange(location: 0, length: string.length)

        if let tag = string.firstTag(matchingRange: fullRange) {
            return TextNode(name: "placeholder", text: "placeholder", attributes: [])
        } else if let tag = string.firstTag(insideRange: fullRange) {
            return TextNode(name: "placeholder", text: "placeholder", attributes: [])
        } else {
            return TextNode(name: "text", text: string.string, attributes: [])
        }
    }
}
