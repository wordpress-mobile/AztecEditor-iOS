import UIKit


public protocol ElementAttributeConverter {
    func convert(
        _ attributes: [Attribute],
        inheriting inheritedAttributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any]

    func convert(
        _ attribute: Attribute,
        inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any]
}

extension ElementAttributeConverter {
    
    func convert(
        _ attributes: [Attribute],
        inheriting inheritedAttributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        return attributes.reduce(inheritedAttributes, { (previous, attribute) -> [NSAttributedStringKey: Any] in
            return convert(attribute, inheriting: previous)
        })
    }
}
