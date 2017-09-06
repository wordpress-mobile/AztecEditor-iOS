#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"

@class WPAssetViewController;

@protocol WPAssetViewControllerDelegate <NSObject>

- (void)assetViewController:(nonnull WPAssetViewController *)assetPreviewVC selectionChanged:(BOOL)selected;

- (void)assetViewController:(nonnull WPAssetViewController *)assetPreviewVC failedWithError:(nonnull NSError *)error;

@end

@interface WPAssetViewController : UIViewController

- (nonnull instancetype)initWithAsset:(nonnull id<WPMediaAsset>)asset;

@property (nonatomic, strong, nonnull) id<WPMediaAsset> asset;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, weak, nullable) id<WPAssetViewControllerDelegate> delegate;

@end
