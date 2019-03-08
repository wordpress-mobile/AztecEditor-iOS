import UIKit


public protocol ElementAttributeConverter {
    func convert(
        _ attributes: [Attribute],
        inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any]

    func convert(
        _ attribute: Attribute,
        inheriting attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any]
}

extension ElementAttributeConverter {
    
    func convert(
        _ attributes: [Attribute],
        inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        
        return attributes.reduce(inheritedAttributes, { (previous, attribute) -> [NSAttributedString.Key: Any] in
            return convert(attribute, inheriting: previous)
        })
    }
}
