import Foundation
import UIKit

class Assets {

    public static var playIcon: UIImage {
        let bundle = Bundle.aztecBundle
        let playImage = UIImage(named: "play", in: bundle, compatibleWith: nil)!
        return playImage
    }

    public static var imageIcon: UIImage {
        let bundle = Bundle.aztecBundle
        let playImage = UIImage(named: "image", in: bundle, compatibleWith: nil)!
        return playImage
    }
}
