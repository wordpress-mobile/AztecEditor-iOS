#import "WPNavigationMediaPickerViewController.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"
#import "WPPHAssetDataSource.h"

@interface WPNavigationMediaPickerViewController () <
UINavigationControllerDelegate,
WPMediaGroupPickerViewControllerDelegate,
UIPopoverPresentationControllerDelegate
>
@property (nonatomic, strong) UINavigationController *internalNavigationController;
@property (nonatomic, strong) WPMediaPickerViewController *mediaPicker;
@property (nonatomic, strong) UIButton *titleButton;
@end

@implementation WPNavigationMediaPickerViewController

static NSString *const ArrowDown = @"\u25be";

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

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.internalNavigationController.topViewController;
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
    self.mediaPicker = vc;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.delegate = self;

    [nav willMoveToParentViewController:self];
    [nav.view setFrame:self.view.bounds];
    [self.view addSubview:nav.view];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
    _internalNavigationController = nav;

    //setup navigation items
    self.titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.titleButton addTarget:self action:@selector(changeGroup:) forControlEvents:UIControlEventTouchUpInside];
    vc.navigationItem.titleView = self.titleButton;
    [self.dataSource loadDataWithSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshTitle];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshTitle];
        });
    }];

    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];

    if (self.allowMultipleSelection) {
        vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishPicker:)];
    }
}

- (void)cancelPicker:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.delegate mediaPickerControllerDidCancel:self.mediaPicker];
    }
}

- (void)finishPicker:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
        [self.delegate mediaPickerController:self.mediaPicker didFinishPickingAssets:[self.mediaPicker.selectedAssets copy]];
    }
}

- (void)refreshTitle {
    id<WPMediaGroup> mediaGroup = [self.dataSource selectedGroup];
    if (!mediaGroup) {
        // mediaGroup can be nil in some cases. For instance if the
        // user denied access to the device's Photos.
        self.titleButton.hidden = YES;
        return;
    } else {
        self.titleButton.hidden = NO;
    }
    NSString *title = [NSString stringWithFormat:@"%@ %@", [mediaGroup name], ArrowDown];
    [self.titleButton setTitle:title forState:UIControlStateNormal];
    [self.titleButton sizeToFit];
}

- (void)changeGroup:(UIButton *)sender
{
    WPMediaGroupPickerViewController *groupViewController = [[WPMediaGroupPickerViewController alloc] init];
    groupViewController.delegate = self;
    groupViewController.dataSource = self.dataSource;

    groupViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = groupViewController.popoverPresentationController;
    ppc.delegate = self;
    ppc.sourceView = sender;
    ppc.sourceRect = [sender bounds];
    [self presentViewController:groupViewController animated:YES completion:nil];
}


#pragma mark - WPMediaGroupViewControllerDelegate

- (void)mediaGroupPickerViewController:(WPMediaGroupPickerViewController *)picker didPickGroup:(id<WPMediaGroup>)group
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.mediaPicker setGroup:group];
        [self refreshTitle];
    }];
}

- (void)mediaGroupPickerViewControllerDidCancel:(WPMediaGroupPickerViewController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Public Methods

- (void)showAfterViewController:(UIViewController *)viewController
{
    NSParameterAssert(viewController);
    [self.internalNavigationController pushViewController:viewController animated:YES];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}


@end
