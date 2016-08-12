import UIKit

extension Libxml2.HTML {
    class RootNode: ElementNode {

        static let name = "aztec.htmltag.rootnode"

        override var parent: Libxml2.HTML.ElementNode? {
            get {
                return nil
            }

            set {
            }
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["name": name, "children": children])
        }

        init(children: [Node]) {
            super.init(name: self.dynamicType.name, attributes: [], children: children)
        }
    }
}