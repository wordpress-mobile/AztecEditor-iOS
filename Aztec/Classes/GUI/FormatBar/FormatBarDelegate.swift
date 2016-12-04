import Foundation
import UIKit


public protocol FormatBarDelegate : NSObjectProtocol
{
    func handleActionForIdentifier(_ identifier: String)
}
