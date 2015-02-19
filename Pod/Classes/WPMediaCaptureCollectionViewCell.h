@import UIKit;

@interface WPMediaCaptureCollectionViewCell : UICollectionViewCell

- (void)stopCaptureOnCompletion:(void (^)(void))block;
- (void)startCapture;

@end
