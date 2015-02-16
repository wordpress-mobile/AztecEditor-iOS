@import UIKit;
@import AssetsLibrary;

@protocol WPMediaGroupPickerViewControllerDelegate;

@interface WPMediaGroupPickerViewController : UITableViewController

@property (nonatomic, weak) id<WPMediaGroupPickerViewControllerDelegate> delegate;

@property (nonatomic, strong) ALAssetsGroup * selectedGroup;

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