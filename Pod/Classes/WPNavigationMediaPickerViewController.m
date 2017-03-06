#import "WPNavigationMediaPickerViewController.h"
#import "WPMediaPickerViewController.h"
#import "WPPHAssetDataSource.h"

@interface WPNavigationMediaPickerViewController () <UINavigationControllerDelegate>
@property (nonatomic, strong) UINavigationController *internalNavigationController;
@end

@implementation WPNavigationMediaPickerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _allowCaptureOfMedia = YES;
        _preferFrontCamera = NO;
        _showMostRecentFirst = NO;
        _allowMultipleSelection = YES;
        _filter = WPMediaTypeVideoOrImage;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self setupNavigationController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationController
{
    WPMediaPickerViewController *vc = [[WPMediaPickerViewController alloc] init];
    vc.allowCaptureOfMedia = self.allowCaptureOfMedia;
    vc.preferFrontCamera = self.preferFrontCamera;
    vc.showMostRecentFirst = self.showMostRecentFirst;
    vc.filter = self.filter;
    vc.allowMultipleSelection = self.allowMultipleSelection;
    if (!self.dataSource) {
        self.dataSource = [WPPHAssetDataSource sharedInstance];
    }
    vc.dataSource = self.dataSource;
    vc.mediaPickerDelegate = self.delegate;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.delegate = self;

    [nav willMoveToParentViewController:self];
    [nav.view setFrame:self.view.bounds];
    [self.view addSubview:nav.view];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
    _internalNavigationController = nav;
}

#pragma mark - Public Methods

- (void)showAfterViewController:(UIViewController *)viewController
{
    NSParameterAssert(viewController);
    [self.internalNavigationController pushViewController:viewController animated:YES];
}

@end
