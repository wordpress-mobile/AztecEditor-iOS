@import UIKit;
#import "WPMediaCollectionDataSource.h"
#import "WPMediaPickerOptions.h"

@protocol WPMediaPickerViewControllerDelegate;

@interface WPNavigationMediaPickerViewController : UIViewController

/**
 Init a WPNavigationMediaPickerViewController with the selection options

 @param options an options object
 @return am initiated WPNavigationMediaPickerViewController
 */
- (instancetype _Nonnull )initWithOptions:(WPMediaPickerOptions *_Nonnull)options;

@property (nonatomic, weak) _Nullable id<WPMediaPickerViewControllerDelegate> delegate;

/**
 The object that acts as the data source of the media picker.
 
 @Discussion
 If no object is defined before the picker is show then the picker will use a shared data source that access the user media library.
*/
@property (nonatomic, weak) _Nullable id<WPMediaCollectionDataSource> dataSource;

/**
 Options to use on the internal WPMediaPickerViewController.
 */
@property (nonatomic, copy) WPMediaPickerOptions * _Nonnull options;


/**
 Pushes a given ViewController into the internal UINavigationController. Useful for post-processing steps.
 */
- (void)showAfterViewController:(nonnull UIViewController *)viewController;

@property (nonatomic, strong, readonly) UICollectionViewFlowLayout * _Nonnull layout;

@end
