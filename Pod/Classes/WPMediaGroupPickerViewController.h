@import UIKit;
@import AssetsLibrary;

@protocol WPMediaGroupPickerViewControllerDelegate;

/**
    The WPMediaGroupPickerViewController class creates a controller object that allows the user to view and select a ALAssetGroup ina table view.
 */
@interface WPMediaGroupPickerViewController : UITableViewController

@property (nonatomic, weak) id<WPMediaGroupPickerViewControllerDelegate> delegate;

/**
 The group that is being displaying on the picker. If not set the picker will try to select the default Camera Roll group.
 */
@property (nonatomic, strong) ALAssetsGroup *selectedGroup;

/**
 The AssettLibrary that is being used to display the assets and groups. If not set the picker will create a new one.
 */
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

@end

@protocol WPMediaGroupPickerViewControllerDelegate <NSObject>

/**
 *  @name Closing the Picker
 */

/**
 *  Tells the delegate that the user finish picking photos or videos.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets An array containing picked `ALAsset` objects.
 *
 */
- (void)mediaGroupPickerViewController:(WPMediaGroupPickerViewController *)picker didPickGroup:(ALAssetsGroup *)group;

@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *
 *  @param picker The controller object managing the assets group picker interface.
 *
 */
- (void)mediaGroupPickerViewControllerDidCancel:(WPMediaGroupPickerViewController *)picker;

@end