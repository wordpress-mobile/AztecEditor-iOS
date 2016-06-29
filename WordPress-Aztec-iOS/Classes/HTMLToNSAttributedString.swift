import Foundation
import libxml2

public class HTMLTag: CustomDebugStringConvertible {
    let name: String
    private(set) var attributes = [Attribute]()

    init(name: String) {
        self.name = name
    }

    public var debugDescription: String {
        get {
            return "<\(String(self.dynamicType)): {name: \(name); attributes: \(String(attributes))}>"
        }
    }
}

extension HTMLTag {

    /// Represents a basic attribute with no value.  This is also the base class for all other
    /// attributes.
    ///
    class Attribute: CustomDebugStringConvertible {
        let name: String

        init(name: String) {
            self.name = name
        }

        public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType)): {name: \(name)}>"
            }
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

        override public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType)): {name: \(name); value: \(value)}>"
            }
        }
    }
}

public class HTMLToNSAttributedString {

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
            let rootElement = rootElementPtr.memory

            guard let rootElementName = String(CString: UnsafePointer<Int8>(rootElement.name), encoding: NSUTF8StringEncoding) else {
                // We should evaluate how to improve this condition check... is a nil value
                // possible at all here?  If so... do we want to interrupt the parsing or try to
                // recover from it?
                //
                // For the sake of moving forward I'm just interrupting here, but this could change
                // if we find a unit test causing a nil value here.
                //
                fatalError("The root element name should not be nil.")
            }

            let tag = HTMLTag(name: rootElementName)

            var property = rootElement.properties

            while (property != nil) {
                guard let propertyName = String(CString: UnsafePointer<Int8>(property.memory.name), encoding: NSUTF8StringEncoding) else {
                    // We should evaluate how to improve this condition check... is a nil value
                    // possible at all here?  If so... do we want to interrupt the parsing or try to
                    // recover from it?
                    //
                    // For the sake of moving forward I'm just interrupting here, but this could change
                    // if we find a unit test causing a nil value here.
                    //
                    fatalError("The root element name should not be nil.")
                }

                let attribute = HTMLTag.Attribute(name: propertyName)
                tag.attributes.append(attribute)

                property = property.memory.next
            }

            result.addAttribute("HTMLTag", value: tag, range: NSRange(location: 0, length: 0))
        }

        return result
    }
}
