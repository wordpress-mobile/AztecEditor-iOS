#import <UIKit/UIKit.h>
#import "WPMediaPickerViewController.h"


/**
 A class to be used as an input view for an UITextView or UITextField.
 
 The mediaToolbar property provides a toolbar that can be used as the inputAccessoryView for this inputView.
 */
@interface WPInputMediaPickerView : UIView

/**
The delegate for the WPMediaPickerViewController events
*/
@property (nonatomic, weak) _Nullable id<WPMediaPickerViewControllerDelegate> mediaPickerDelegate;

/**
 The object that acts as the data source of the media picker.

 @Discussion
 If no object is defined before the picker is show then the picker will use a shared data source that access the user media library.
 */
@property (nonatomic, weak) _Nullable id<WPMediaCollectionDataSource> dataSource;

/**
 The internal WPMediaPickerViewController that is used to display the media.
 */
@property (nonatomic, readonly) WPMediaPickerViewController *mediaPicker;

/**
 A toolbar that can be used as the inputAccessoryView for this inputView.
 */
@property (nonatomic, readonly) UIToolbar *mediaToolbar;

/**
 If set the picker will show a cell that allows capture of new media, that can be used immediatelly
 */
@property (nonatomic, assign) BOOL allowCaptureOfMedia;

/**
 If the media picker allows media capturing, it will use the front camera by default when possible
 */
@property (nonatomic, assign) BOOL preferFrontCamera;

/**
 If set the picker will allow the selection of multiple items. By default this value is YES.
 */
@property (nonatomic, assign) BOOL allowMultipleSelection;

/**
 If set the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

/**
 *  Sets what kind of elements the picker show: allAssets, allPhotos, allVideos
 */
@property (nonatomic, assign) WPMediaType filter;

@end
