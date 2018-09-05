import UIKit
@testable import Aztec

class TextViewStub: Aztec.TextView {
    
    let attachmentDelegate = TextViewStubAttachmentDelegate()
    
    // MARK: - Sample HTML Retrieval
    
    static func loadSampleHTML() -> String {
        guard let path = Bundle(for: self).path(forResource: "content", ofType: "html"),
            let sample = try? String(contentsOfFile: path)
            else {
                fatalError()
        }
        
        return sample
    }
    
    init(withHTML html: String? = nil, font: UIFont = .systemFont(ofSize: 14)) {
        super.init(
            defaultFont: font,
            defaultMissingImage: UIImage())
        
        textAttachmentDelegate = attachmentDelegate
        registerAttachmentImageProvider(attachmentDelegate)
        
        if let html = html {
            setHTML(html)
        }
    }
    
    convenience init(withSampleHTML: Bool) {
        let html = withSampleHTML ? TextViewStub.loadSampleHTML() : nil
        
        self.init(withHTML: html)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
