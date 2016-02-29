@import UIKit;

@interface WPMediaCapturePreviewCollectionView : UICollectionReusableView

- (void)stopCaptureOnCompletion:(void (^)(void))block;
- (void)startCapture;

@end
