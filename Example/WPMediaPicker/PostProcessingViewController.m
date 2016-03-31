#import "PostProcessingViewController.h"

@interface PostProcessingViewController ()

@end

@implementation PostProcessingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Post Processing", nil);
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(dismissWasPressed)];
}

- (void)dismissWasPressed {
    if (self.onCompletion) {
        self.onCompletion();
    }
}

@end
