import Foundation

class HTMLAttributeToAttributeMetaData: SafeConverter {
    typealias Attribute = Libxml2.HTML.Attribute
    typealias StringAttribute = Libxml2.HTML.StringAttribute

    func convert(attribute: Attribute) -> HTMLAttributeMetaData {

        if let stringAttribute = attribute as? StringAttribute {
            return HTMLStringAttributeMetaData(name: stringAttribute.name, value: stringAttribute.value)
        } else {
            return HTMLAttributeMetaData(name: attribute.name)
        }
    }
}