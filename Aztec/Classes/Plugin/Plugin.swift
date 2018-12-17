import Foundation
import UIKit

/// Plugin base class.  You can implement a subclass to customize some of the behavior in Aztec.
///
open class Plugin {
    
    // MARK: - Customizers
    
    public let inputCustomizer: PluginInputCustomizer?
    public let outputCustomizer: PluginOutputCustomizer?
    
    // MARK: - Initializers
    
    public init(inputCustomizer: PluginInputCustomizer? = nil, outputCustomizer: PluginOutputCustomizer? = nil) {
        self.inputCustomizer = inputCustomizer
        self.outputCustomizer = outputCustomizer
    }
    
    /// Method plugins can use to execute extra code when loaded.
    ///
    open func loaded(textView: TextView) {}

    // MARK: - Equatable
    
    public static func ==(lhs: Plugin, rhs: Plugin) -> Bool {
        return type(of: lhs) == type(of: rhs)
    }
}
