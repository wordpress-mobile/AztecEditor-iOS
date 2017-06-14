import UIKit

protocol CharacterAttributeFormatter: AttributeFormatter {
    var attributedStringStorageKey: String { get }
}

extension CharacterAttributeFormatter {

    var placeholderAttributes: [String : Any]? { return nil }

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }

    func worksInEmptyRange() -> Bool {
        return false
    }
}
