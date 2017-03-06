@import UIKit;

#import <WPMediaPicker/WPMediaPicker.h>

@interface CustomPreviewViewController : UIViewController

@property (nonatomic, strong) id<WPMediaAsset> asset;

- (instancetype)initWithAsset:(id<WPMediaAsset>)asset;

@end
