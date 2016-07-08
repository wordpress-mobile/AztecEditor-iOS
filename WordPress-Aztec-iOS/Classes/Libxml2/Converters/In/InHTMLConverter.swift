import Foundation
import libxml2

extension Libxml2.In {
    public class HTMLConverter: Converter {

        enum Error: String, ErrorType {
            case NoRootNode = "No root node"
        }

        /// Not sure why, but the compiler is requiring this initializer.
        ///
        public init() {
        }

        /// Converts HTML data into an attributed string representing the same data.
        ///
        /// - Parameters:
        ///     - html: the HTML data to convert.
        ///
        /// - Returns: an attributed string representing the specified HTML data.
        ///
        public func convert(html: NSData) throws -> Libxml2.HTML.Node {

            // We don't want <p> tags added automattically.
            //
            htmlHandleOmittedElem(0)

            let result = NSMutableAttributedString()
            let bufferSize = 1024
            let buffer = Array<Int8>(count: bufferSize, repeatedValue: 0)
            let htmlPtr = UnsafePointer<Int8>(html.bytes)

            let parserContext = htmlCreateMemoryParserCtxt(buffer, 1024)

            let document = htmlCtxtReadMemory(parserContext, htmlPtr, Int32(html.length), "", nil, Int32(HTML_PARSE_RECOVER.rawValue | HTML_PARSE_NODEFDTD.rawValue | HTML_PARSE_NOERROR.rawValue | HTML_PARSE_NOWARNING.rawValue | HTML_PARSE_NOIMPLIED.rawValue))

            let errorPtr = xmlGetLastError()

            if errorPtr != nil {
                let messagePtr = errorPtr.memory.message

                if messagePtr != nil {
                    let message = String(CString: messagePtr, encoding: NSUTF8StringEncoding)

                    NSLog("Message: \(message)")
                }

                // Some errors are really not a problem for us (like "misplaced HTML tag"), so let's
                // keep going.  In the future we should analyze the different errors here and decide
                // if there's a need to handle any of them in a different way.
                //
            }

            let rootNodePtr = xmlDocGetRootElement(document)

            if rootNodePtr != nil {
                let rootNode = rootNodePtr.memory

                // TODO: If the root node has siblings, they're loaded as children instead (by
                // libxml2).  We need to test this a bit more, because saving the HTML back will
                // produce a different result unless there's some way to identify this scenario.
                //
                // Example HTML: <a></a><b></b>
                //
                // It may be a good idea to wrap the HTML in a single fake root node before parsing
                // it to bypass this behaviour.
                //
                let nodeConverter = NodeConverter()
                let node = try nodeConverter.convert(rootNode)

                return node
            } else {
                throw Error.NoRootNode
            }
        }
    }
}
