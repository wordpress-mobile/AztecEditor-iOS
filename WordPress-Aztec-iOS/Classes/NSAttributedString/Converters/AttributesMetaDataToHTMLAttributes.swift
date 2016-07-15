import Foundation

class AttributesMetaDataToHTMLAttributes: SafeArrayConverter<AttributeMetaDataToHTMLAttribute> {

    required init() {
        super.init(elementConverter: AttributeMetaDataToHTMLAttribute())
    }
}