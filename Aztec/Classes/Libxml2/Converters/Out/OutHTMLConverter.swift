import Foundation
import libxml2

extension Libxml2.Out {
    class HTMLConverter: Converter {
        
        typealias Node = Libxml2.Node
        typealias ElementNode = Libxml2.ElementNode
        typealias RootNode = Libxml2.RootNode
        typealias UndoRegistrationClosure = Node.UndoRegistrationClosure
        
        let registerUndo: UndoRegistrationClosure
        
        required init(registerUndo: @escaping UndoRegistrationClosure) {
            self.registerUndo = registerUndo
        }

        /// Converts the a Libxml2 Node into HTML representing the same data.
        ///
        /// - Parameters:
        ///     - rawNode: the Libxml2 Node to convert.
        ///
        /// - Returns: a String object representing the specified HTML data.
        ///
        func convert(_ rawNode: Node) -> String {
            
            guard let buffer = xmlBufferCreate() else {
                fatalError("This should not ever happen. Prevent the code from going further to avoid possible data loss.")
            }
            
            let xmlDocPtr = xmlNewDoc(nil)
            
            defer {
                xmlFreeDoc(xmlDocPtr)
                xmlBufferFree(buffer)
            }

            let xmlNodePtr = Libxml2.Out.NodeConverter().convert(rawNode)
            
            xmlDocSetRootElement(xmlDocPtr, xmlNodePtr)
            htmlNodeDump(buffer, xmlDocPtr, xmlNodePtr)
            
            let htmlDumpString = String(cString: buffer.pointee.content)

            let finalString = htmlDumpString.replacingOccurrences(of: "<\(RootNode.name)>", with: "").replacingOccurrences(of: "</\(RootNode.name)>", with: "")
            
            return finalString
        }
    }
}
