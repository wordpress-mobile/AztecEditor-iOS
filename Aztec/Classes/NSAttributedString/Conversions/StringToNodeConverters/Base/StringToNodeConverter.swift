import Foundation

public protocol StringToNodeConverter {
    func convert(_ attrString: NSAttributedString) -> Node?
}
