import Foundation

class HTMLAttributesToAttributesMetaData: SafeArrayConverter<HTMLAttributeToAttributeMetaData> {

    required init() {
        super.init(elementConverter: HTMLAttributeToAttributeMetaData())
    }
}