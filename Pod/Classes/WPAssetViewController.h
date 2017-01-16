#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"

@class WPAssetViewController;

@protocol WPAssetViewControllerDelegate <NSObject>

- (void)assetViewController:(WPAssetViewController *) assetPreviewVC selectionChange:(BOOL)selected;

@end

@interface WPAssetViewController : UIViewController

@property (nonatomic, strong) id<WPMediaAsset> asset;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, weak) id<WPAssetViewControllerDelegate> delegate;

@end
