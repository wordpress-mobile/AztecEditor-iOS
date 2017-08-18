@import UIKit;
#import "WPMediaCollectionDataSource.h"
#import "WPAssetViewController.h"
#import "WPMediaPickerOptions.h"

@class WPMediaPickerViewController;
/**
 *  The `WPMediaPickerViewControllerDelegate` protocol defines methods that allow you to to interact with the assets picker interface
 *  and manage the selection and highlighting of assets in the picker.
 *
 *  The methods of this protocol notify your delegate when the user selects, finish picking assets, or cancels the picker operation.
 *
 *  The delegate methods are responsible for dismissing the picker when the operation completes.
 *  To dismiss the picker, call the `dismissViewControllerAnimated:completion:` method of the presenting controller
 *  responsible for displaying `WPMediaPickerController` object.
 *
 */
@protocol WPMediaPickerViewControllerDelegate <NSObject>

/**
 *  @name Closing the Picker
 */

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets An array containing picked `WPMediaAsset` objects.
 *
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didFinishPickingAssets:(nonnull NSArray<WPMediaAsset> *)assets;

@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *
 *  @param picker The controller object managing the assets picker interface.
 *
 */
- (void)mediaPickerControllerDidCancel:(nonnull WPMediaPickerViewController *)picker;

/**
 *  @name Enabling Assets
 */

/**
 *  Ask the delegate if the specified asset shoule be shown.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be shown.
 *
 *  @return `YES` if the asset should be shown or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldShowAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Ask the delegate if the specified asset should be enabled for selection.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be enabled.
 *
 *  @return `YES` if the asset should be enabled or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldEnableAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  @name Managing the Selected Assets
 */

/**
 *  Asks the delegate if the specified asset should be selected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be selected.
 *
 *  @return `YES` if the asset should be selected or `NO` if it should not.
 *
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldSelectAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the asset was selected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset that was selected.
 *
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didSelectAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Asks the delegate if the specified asset should be deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be deselected.
 *
 *  @return `YES` if the asset should be deselected or `NO` if it should not.
 *
 *  @see assetsPickerController:shouldSelectAsset:
 */
- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldDeselectAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the item at the specified path was deselected.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset that was deselected.
 *
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didDeselectAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the selection changed because of external events ( assets being deleted )
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets  The updated selected assets that was deselected.
 *
 */
- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker selectionChanged:(nonnull NSArray<WPMediaAsset> *)assets;

/**
 *  Asks the delegate for a view controller to push when previewing the specified asset.
 *  If this method isn't implemented, the default view controller will be used.
 *  If it returns nil, no preview will be displayed.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param asset  The asset to be previewed.
 */
- (nullable UIViewController *)mediaPickerController:(nonnull WPMediaPickerViewController *)picker previewViewControllerForAsset:(nonnull id<WPMediaAsset>)asset;

/**
 *  Tells the delegate that the picker will begin requesting
 *  new data from its data source.
 */
- (void)mediaPickerControllerWillBeginLoadingData:(nonnull WPMediaPickerViewController *)picker;

/**
 *  Tells the delegate that the picker finished loading
 *  new data from its data source.
 */
- (void)mediaPickerControllerDidEndLoadingData:(nonnull WPMediaPickerViewController *)picker;

@end


@interface WPMediaPickerViewController : UICollectionViewController<WPAssetViewControllerDelegate>

- (instancetype _Nonnull )initWithOptions:(WPMediaPickerOptions *_Nonnull)options;

@property (nonatomic, copy, nonnull) WPMediaPickerOptions *options;

/**
 An array with the the assets that are currently selected.
 */
@property (nonatomic, copy, nonnull) NSArray<WPMediaAsset> *selectedAssets;

/**
  The object that acts as the data source of the media picker.
 */
@property (nonatomic, weak, nullable) id<WPMediaCollectionDataSource> dataSource;

/**
 The delegate for the WPMediaPickerViewController events
 */
@property (nonatomic, weak, nullable) id<WPMediaPickerViewControllerDelegate> mediaPickerDelegate;

/**
 Allows to set a group as the current display group on the data source. 
 */
- (void)setGroup:(nonnull id<WPMediaGroup>)group;

/**
 * Clears the current asset selection in the picker.
 */
- (void)clearSelectedAssets:(BOOL)animated;

/**
 View controller to use when picker needs to present another controller. By default this is set to self.
 @note If the picker is being used within an input view, it's important to set this value to something besides the picker itself.
 */
@property (nonatomic, weak, nullable) UIViewController *viewControllerToUseToPresent;

/**
 Clears all selection and scroll the picker to the starting position
 */
- (void)resetState:(BOOL)animated;

/**
 Return the default preview view controller to use to preview assets

 @param asset the asset to preview
 @return a view controller to preview the asset
 */
- (nonnull UIViewController *)defaultPreviewViewControllerForAsset:(nonnull id <WPMediaAsset>)asset;

/**
 Calculates the appropriate cell height/width given the desired number of cells per line, desired space
 between cells, and total width of the frame containing the cells.

 @param photosPerLine The number of desired photos per line
 @param photoSpacing The amount of space in between photos
 @param frameWidth The width of the frame which contains the photo cells
 @return A CGFloat representing the height/width of the suggested cell size
 */
- (CGFloat)cellSizeForPhotosPerLineCount:(NSUInteger)photosPerLine photoSpacing:(CGFloat)photoSpacing frameWidth:(CGFloat)frameWidth;

@end

