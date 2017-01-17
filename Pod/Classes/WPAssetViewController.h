#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"

@class WPAssetViewController;

@protocol WPAssetViewControllerDelegate <NSObject>

- (void)assetViewController:(WPAssetViewController *)assetPreviewVC selectionChanged:(BOOL)selected;

- (void)assetViewController:(WPAssetViewController *)assetPreviewVC failedWithError:(NSError *)error;

@end

@interface WPAssetViewController : UIViewController

@property (nonatomic, strong) id<WPMediaAsset> asset;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, weak) id<WPAssetViewControllerDelegate> delegate;

@end
