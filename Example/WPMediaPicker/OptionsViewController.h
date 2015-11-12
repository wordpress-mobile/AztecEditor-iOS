@import UIKit;

extern NSString const *MediaPickerOptionsShowMostRecentFirst;
extern NSString const *MediaPickerOptionsUsePhotosLibrary;
extern NSString const *MediaPickerOptionsShowCameraCapture;
extern NSString const *MediaPickerOptionsAllowMultipleSelection;

@class OptionsViewController;

@protocol OptionsViewControllerDelegate <NSObject>

- (void)optionsViewController:(OptionsViewController *)optionsViewController changed:(NSDictionary *)options;

- (void)cancelOptionsViewController:(OptionsViewController *)optionsViewController;

@end
@interface OptionsViewController : UITableViewController

@property (nonatomic, weak) id<OptionsViewControllerDelegate> delegate;
@property (nonatomic, copy) NSDictionary *options;

@end
