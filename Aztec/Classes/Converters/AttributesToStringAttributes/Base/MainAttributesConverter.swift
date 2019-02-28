import Foundation

class MainAttributesConverter {
    
    private let converters: [ElementAttributeConverter]
    
    init(_ converters: [ElementAttributeConverter]) {
        self.converters = converters
    }
    
    func convert(
        _ attributes: [Attribute],
        inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        
        return converters.reduce(inheritedAttributes) { (previous, converter) -> [NSAttributedString.Key: Any] in
            return converter.convert(attributes, inheriting: previous)
        }
    }
}
