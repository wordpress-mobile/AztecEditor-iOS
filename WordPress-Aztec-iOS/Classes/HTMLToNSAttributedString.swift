import Foundation
import libxml2

public class HTMLTag {

    /// Represents a basic attribute with no value.  This is also the base class for all other
    /// attributes.
    ///
    class Attribute {
        let name: String

        init(name: String) {
            self.name = name
        }
    }

    /// Represents an attribute with an generic string value.  This is useful for storing attributes
    /// that do have a value, which we don't know how to parse.  This is only meant as a mechanism
    /// to maintain the attribute's information.
    ///
    class StringAttribute: Attribute {
        let value: String

        init(name: String, value: String) {
            self.value = value

            super.init(name: name)
        }
    }

    let name: String
    let attributes: [Attribute]?

    init(name: String, attributes: [Attribute]?) {
        self.name = name
        self.attributes = attributes
    }
}

public class HTMLToNSAttributedString {

    public init() {
    }

    public func convert(html: NSData) -> NSAttributedString {

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
            let rootElement = rootElementPtr.memory
            let rootElementName = String(CString: UnsafePointer<Int8>(rootElement.name), encoding: NSUTF8StringEncoding)
            NSLog("Root element name: \(rootElementName)")

            var property = rootElement.properties

            while (property != nil) {
                NSLog("Property: \(String(CString: UnsafePointer<Int8>(property.memory.name), encoding: NSUTF8StringEncoding))")
                property = property.memory.next
            }
        }

        return NSAttributedString(string: "")
/*
        let htmlPtr = UnsafePointer<Int8>(html.bytes)

        xmlResetLastError()

        let options = Int32(XML_PARSE_NONET.rawValue)
        let _ = xmlReadMemory(htmlPtr, Int32(html.length), "", nil, options)

        let errorPtr = xmlGetLastError()

        if errorPtr != nil {
            let messagePtr = errorPtr.memory.message

            if messagePtr != nil {
                let message = String(CString: messagePtr, encoding: NSUTF8StringEncoding)

                DDLogSwift.logDebug(message)
            }
        }

        return NSAttributedString(string: "")
*/

        /*
        let parserDelegate = ParserDelegate()
        let parser = NSXMLParser(data: html)
        parser.delegate = parserDelegate

        if parser.parse() {
            return parserDelegate.output
        } else {

        }

        let attributedString = NSMutableAttributedString(string: "Hello there!")

        let attribute = HTMLTag(name: "HTML", attributes: nil)
        attributedString.addAttribute("HTMLTag", value: attribute, range: NSRange(location: 0, length: attributedString.length))

        return attributedString
 */
    }
}
