import Foundation

class PipelineAttributesConverter: ElementAttributeConverter {
    
    private let converters: [ElementAttributeConverter]
    
    init(_ converters: [ElementAttributeConverter]) {
        self.converters = converters
    }
    
    func convert(
        _ attributes: [Attribute],
        inheriting inheritedAttributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        return converters.reduce(inheritedAttributes) { (previous, converter) -> [NSAttributedStringKey: Any] in
            return converter.convert(attributes, inheriting: previous)
        }
    }
}
