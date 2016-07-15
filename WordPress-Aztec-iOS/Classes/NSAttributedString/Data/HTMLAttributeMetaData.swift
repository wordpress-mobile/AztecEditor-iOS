class HTMLAttributeMetaData {
    let name: String

    init(name: String) {
        self.name = name
    }
}

class HTMLStringAttributeMetaData: HTMLAttributeMetaData {
    let value: String

    init (name: String, value: String) {
        self.value = value
        super.init(name: name)
    }
}