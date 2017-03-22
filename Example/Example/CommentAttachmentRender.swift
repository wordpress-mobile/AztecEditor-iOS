//
//  CommentAttachmentRender.swift
//  AztecExample
//
//  Created by Jorge Leandro Perez on 3/22/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import Foundation
import UIKit
import Aztec


class CommentAttachmentRender {

    /// Attachment to be rendered
    ///
    let attachment: CommentAttachment

    /// Text Color
    ///
    var textColor = UIColor.gray


    /// Default Initializer
    ///
    init?(attachment: CommentAttachment) {
        self.attachment = attachment
    }
}


// MARK: - TextViewCommentsDelegate Methods
//
extension CommentAttachmentRender: TextViewCommentsDelegate {

    func textView(_ textView: TextView, imageForComment attachment: CommentAttachment, with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        let message = messageAttributedString()
        let targetRect = boundingRect(for: message, size: size)

        message.draw(in: targetRect)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    func textView(_ textView: TextView, boundsForComment attachment: CommentAttachment, with lineFragment: CGRect) -> CGRect {
        let message = messageAttributedString()
        let size = CGSize(width: lineFragment.size.width, height: lineFragment.size.height)
        let targetRect = boundingRect(for: message, size: size)

        return targetRect
    }



    func boundingRect(for message: NSAttributedString, size: CGSize) -> CGRect {
        let targetBounds = message.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let targetPosition = CGPoint(x: ((size.width - targetBounds.width) * 0.5), y: ((size.height - targetBounds.height) * 0.5))

        return CGRect(origin: targetPosition, size: targetBounds.size)

    }

    func messageAttributedString() -> NSAttributedString {
        let attributes: [String: Any] = [
            NSForegroundColorAttributeName: textColor,
            NSFontAttributeName: UIFont.systemFont(ofSize: 14)
        ]

        return NSAttributedString(string: attachment.text.uppercased(), attributes: attributes)
    }
}
