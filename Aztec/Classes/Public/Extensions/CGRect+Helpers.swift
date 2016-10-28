import CoreGraphics

extension CGRect {
    /// The position to which a rect is anchored when resized vertically.
    ///
    enum VerticalAnchor {
        case top
        case middle
        case bottom
    }

    /// The position to which a rect is anchored when resized horizontally.
    ///
    enum HorizontalAnchor {
        case left
        case center
        case right
    }

    /// Return a rect resized to a specific size, while anchoring it to one of
    /// their edges or centers.
    ///
    /// By default, changing a CGRect size will resize it anchored to its top
    /// left corner, as a CGRect is defined by its `origin`.  This method adds
    /// the option to anchor the resize operation to the center/middle or
    /// bottom/right.
    ///
    func resize(to size: CGSize, horizontalAnchor: HorizontalAnchor = .left, verticalAnchor: VerticalAnchor = .top) -> CGRect {
        let original = self
        var resized = self

        resized.size.width = size.width
        let horizontalGrowth = resized.size.width - original.size.width
        switch horizontalAnchor {
        case .center:
            resized.origin.x -= horizontalGrowth / 2
        case .right:
            resized.origin.x -= horizontalGrowth
        default:
            break
        }

        resized.size.height = size.height
        let verticalGrowth = resized.size.height - original.size.height
        switch verticalAnchor {
        case .middle:
            resized.origin.y -= verticalGrowth / 2
        case .bottom:
            resized.origin.y -= verticalGrowth
        default:
            break
        }

        return resized
    }
}
