import Foundation
import libxml2

extension Libxml2.Out {
    public class HTMLConverter: Converter {
        
        typealias Node = HTML.Node
        typealias ElementNode = HTML.ElementNode

        /// Converts the a Libxml2 Node into HTML representing the same data.
        ///
        /// - Parameters:
        ///     - rawNode: the Libxml2 Node to convert.
        ///
        /// - Returns: a String object representing the specified HTML data.
        ///
        func convert(rawNode: Node) -> String {
            
            let buf = xmlBufferCreate()
            let xmlDocPtr = xmlNewDoc(nil)
            
            let rootNode = rawNode as! ElementNode
            let htmlNode = rootNode.children[0] as! ElementNode
            
            let xmlNodePtr = Libxml2.Out.NodeConverter().convert(htmlNode)
            
            xmlDocSetRootElement(xmlDocPtr, xmlNodePtr)
            htmlNodeDump(buf, xmlDocPtr, xmlNodePtr)
            
            let htmlDumpString = String(CString: UnsafePointer<Int8>(buf.memory.content), encoding: NSUTF8StringEncoding)!
            
            xmlFreeDoc(xmlDocPtr)
            xmlBufferFree(buf)
            
            return htmlDumpString
        }
    }
}
