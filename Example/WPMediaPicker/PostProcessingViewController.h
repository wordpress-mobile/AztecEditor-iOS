#import <UIKit/UIKit.h>

@interface PostProcessingViewController : UIViewController

@property (nonatomic, copy) void (^onCompletion)(void);

@end
