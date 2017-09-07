import Foundation

/// Protocol the enum or struct must implement.
///
protocol Coding {
    static func decode(with coder: NSCoder) -> Self?
    func encode(with coder: NSCoder)
}

/// Offers NSCoding support for our enum, without having to change our arquitecture for it.
///
class NSCodingProxy<T: Coding>: NSObject, NSCoding {

    let value: T

    // MARK: - Initializing with value

    init(for value: T) {
        self.value = value
    }

    // MARK: - NSCoding support

    required init?(coder: NSCoder) {

        guard let value = T.decode(with: coder) else {
            return nil
        }

        self.value = value
    }

    func encode(with aCoder: NSCoder) {
        value.encode(with: aCoder)
    }
}
