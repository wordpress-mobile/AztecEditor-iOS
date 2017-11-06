import Foundation
import UIKit

extension UIImage {

    /// Resizes an image so it fits within rectSize and will not exceed the height or width
    /// of the maxImageSize. The aspect ratio is maintained.
    ///
    /// - Parameters:
    ///     - rectSize: The CGSize that the image will be fit into. *Note*, this is NOT the returned image size.
    ///     - maxImageSize: The maximum height and width of the new image. The returned image will always be smaller in *both* dimensions.
    ///     - color: Optional UIColor. If provided, the color will be set when drawing the new image.
    ///
    /// - Returns: A new UIImage that is contained within rectSize, but no larger than maxImageSize in either dimension.
    ///
    func resizedImageWithinRect(rectSize: CGSize, maxImageSize: CGSize, color: UIColor? = nil) -> UIImage {
        let smallerWidthThanMax = rectSize.width < maxImageSize.width
        let smallerHeightThanMax = rectSize.height < maxImageSize.height

        if smallerWidthThanMax && smallerHeightThanMax {
            return resizedImageWithinRect(rectSize: rectSize, color: color)
        } else if smallerWidthThanMax && !smallerHeightThanMax {
            return resizedImageWithinRect(rectSize: CGSize(width: rectSize.width, height: maxImageSize.height), color: color)
        } else if !smallerWidthThanMax && smallerHeightThanMax {
            return resizedImageWithinRect(rectSize: CGSize(width: maxImageSize.width, height: rectSize.height), color: color)
        } else {
            return resizedImageWithinRect(rectSize: CGSize(width: maxImageSize.width, height: maxImageSize.height), color: color)
        }
    }

    /// Resizes an image so it fits within rectSize. The aspect ratio is maintained.
    ///
    /// - Parameters:
    ///     - rectSize: The CGSize that the image will be fit into. *Note*, this is NOT the returned image size.
    ///     - color: Optional UIColor. If provided, the color will be set when drawing the new image.
    ///
    /// - Returns: A new UIImage that is contained within rectSize.
    ///
    func resizedImageWithinRect(rectSize: CGSize, color: UIColor? = nil) -> UIImage {
        let widthRatio = size.width / rectSize.width
        let heightRatio = size.height / rectSize.height
        var resizeRatio = widthRatio
        if size.height > size.width {
            resizeRatio = heightRatio
        }

        let newSize = CGSize(width: size.width / resizeRatio, height: size.height / resizeRatio)
        return resizedImage(newSize: newSize, color: color)
    }

    /// Resizes the image so it fills newSize.
    ///
    /// - Parameters:
    ///     - newSize: The CGSize that the image will be fit into. *Note*, this is NOT the returned image size.
    ///     - color: Optional UIColor. If provided, the color will be set when drawing the new image.
    ///
    /// - Returns: A new UIImage that fills newSize.
    ///
    func resizedImage(newSize: CGSize, color: UIColor?) -> UIImage {
        guard size != newSize else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        if let color = color {
            color.set()
        }
        draw(in: rect)
        let resizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
