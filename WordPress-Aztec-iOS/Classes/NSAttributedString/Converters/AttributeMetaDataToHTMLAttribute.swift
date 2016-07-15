import Foundation

class AttributeMetaDataToHTMLAttribute: SafeConverter {
    typealias Attribute = Libxml2.HTML.Attribute
    typealias StringAttribute = Libxml2.HTML.StringAttribute

    func convert(attribute: HTMLAttributeMetaData) -> Attribute {

        if let attributeMetaData = attribute as? HTMLStringAttributeMetaData {
            return StringAttribute(name: attributeMetaData.name, value: attributeMetaData.value)
        } else {
            return Attribute(name: attribute.name)
        }
    }
}