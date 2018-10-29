import Foundation

public extension String {
    
    /// Initializes this instance with the specified character.
    ///
    /// - Parameters:
    ///     - characterName: the name of the character to initialize this String with.
    ///
    init(_ characterName: Character.Name) {
        self.init(Character(characterName))
    }
}
