@import UIKit;
#import "WPMediaPickerViewController.h"

@protocol WPMediaGroupPickerViewControllerDelegate;

/**
    The WPMediaGroupPickerViewController class creates a controller object that allows the user to view and select a ALAssetGroup ina table view.
 */
@interface WPMediaGroupPickerViewController : UITableViewController

@property (nonatomic, weak) id<WPMediaGroupPickerViewControllerDelegate> delegate;

/**
 The WPMediaCollectionDataSource that is being used to display the assets and groups. If not set the picker will create a new one.
 */
@property (nonatomic, strong) id<WPMediaCollectionDataSource> dataSource;

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
- (void)mediaGroupPickerViewController:(WPMediaGroupPickerViewController *)picker didPickGroup:(id<WPMediaGroup>)group;

@optional

/**
 *  Tells the delegate that the user cancelled the pick operation.
 *
 *  @param picker The controller object managing the assets group picker interface.
 *
 */
- (void)mediaGroupPickerViewControllerDidCancel:(WPMediaGroupPickerViewController *)picker;

@end