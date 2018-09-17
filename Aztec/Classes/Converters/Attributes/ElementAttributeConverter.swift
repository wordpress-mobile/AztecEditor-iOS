import UIKit


public protocol ElementAttributeConverter {
    func convert(
        _ attributes: [Attribute],
        inheriting inheritedAttributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any]
}
