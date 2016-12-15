import Foundation
import libxml2

extension Libxml2.In {

    /// Converts a C linked list of xmlNode to [HTML.Node].
    ///
    class NodesConverter: SafeCLinkedListToArrayConverter<NodeConverter> {

        typealias UndoRegistrationClosure = Libxml2.Node.UndoRegistrationClosure
        
        required init(registerUndo: @escaping UndoRegistrationClosure) {
            super.init(elementConverter: NodeConverter(registerUndo: registerUndo), next: { return $0.next })
        }
    }
}
