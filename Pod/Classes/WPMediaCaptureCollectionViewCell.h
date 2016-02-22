@import UIKit;

@interface WPMediaCaptureCollectionViewCell : UICollectionReusableView

- (void)stopCaptureOnCompletion:(void (^)(void))block;
- (void)startCapture;

@end
