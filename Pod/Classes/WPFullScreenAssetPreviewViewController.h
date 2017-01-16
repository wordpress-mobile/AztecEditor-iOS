#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"

@class WPFullScreenAssetPreviewViewController;

@protocol WPFullScreenAssetPreviewViewControllerDelegate <NSObject>

- (void)fullScreenAssetPreviewViewController:(WPFullScreenAssetPreviewViewController *) assetPreviewVC selectionChange:(BOOL)selected;

@end

@interface WPFullScreenAssetPreviewViewController : UIViewController

@property (nonatomic, strong) id<WPMediaAsset> asset;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, weak) id<WPFullScreenAssetPreviewViewControllerDelegate> delegate;

@end
