@import UIKit;

@interface WPMediaCapturePreviewCollectionView : UICollectionReusableView

@property (nonatomic, assign) BOOL preferFrontCamera;

- (void)stopCaptureOnCompletion:(void (^)(void))block;
- (void)startCapture;

@end
