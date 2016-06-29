import Foundation
import libxml2

public class HTMLToNSAttributedString: Converter {

    typealias TypeIn = NSData
    typealias TypeOut = NSAttributedString

    static let nodeNSStringAttributeName = "HMTLNode"

    public init() {
    }

    public func convert(html: NSData) -> NSAttributedString {

        let result = NSMutableAttributedString()
        let bufferSize = 1024
        let buffer = Array<Int8>(count: bufferSize, repeatedValue: 0)
        let htmlPtr = UnsafePointer<Int8>(html.bytes)

        let parserContext = htmlCreateMemoryParserCtxt(buffer, 1024)

        let document = htmlCtxtReadMemory(parserContext, htmlPtr, Int32(html.length), "", nil, 0)

        let errorPtr = xmlGetLastError()

        if errorPtr != nil {
            let messagePtr = errorPtr.memory.message

            if messagePtr != nil {
                let message = String(CString: messagePtr, encoding: NSUTF8StringEncoding)

                NSLog("Message: \(message)")
            }

            return NSAttributedString(string: "")
        }

        let rootElementPtr = xmlDocGetRootElement(document)

        if rootElementPtr != nil {
            let rootNode = rootElementPtr.memory

            let converter = RawNodeToNode()
            let node = converter.convert(rootNode)

            result.addAttribute(self.dynamicType.nodeNSStringAttributeName, value: node, range: NSRange(location: 0, length: 0))
        }

        return result
    }
}
