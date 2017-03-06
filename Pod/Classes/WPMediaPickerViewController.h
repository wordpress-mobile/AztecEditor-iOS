@import UIKit;
#import "WPMediaCollectionDataSource.h"

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

@end


@interface WPMediaPickerViewController : UICollectionViewController

@property (nonatomic, readonly) NSMutableArray *selectedAssets;
/**
 If set the picker will show a cell that allows capture of new media, that can be used immediatelly
 */
@property (nonatomic, assign) BOOL allowCaptureOfMedia;

/**
 If the media picker allows media capturing, it will use the front camera by default when possible
 */
@property (nonatomic, assign) BOOL preferFrontCamera;

/**
 If set the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

/**
 *  Sets what kind of elements the picker show: allAssets, allPhotos, allVideos
 */
@property (nonatomic, assign) WPMediaType filter;

/**
 If set the picker will allow the selection of multiple items. By default this value is YES.
 */
@property (nonatomic, assign) BOOL allowMultipleSelection;

/**
  The object that acts as the data source of the media picker.
 */
@property (nonatomic, weak) id<WPMediaCollectionDataSource> dataSource;

/**
 The object that acts as the data source of the media picker.
 */
@property (nonatomic, weak) id<WPMediaPickerViewControllerDelegate> mediaPickerDelegate;

/**
 Allows to set a group as the current display group on the data source. 
 */
- (void)setGroup:(id<WPMediaGroup>)group;

@end

