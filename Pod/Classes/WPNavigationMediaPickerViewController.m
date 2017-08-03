#import "WPNavigationMediaPickerViewController.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"
#import "WPPHAssetDataSource.h"

@interface WPNavigationMediaPickerViewController () <
UINavigationControllerDelegate,
WPMediaPickerViewControllerDelegate,
WPMediaGroupPickerViewControllerDelegate,
UIPopoverPresentationControllerDelegate
>
@property (nonatomic, strong) UINavigationController *internalNavigationController;
@property (nonatomic, strong) WPMediaPickerViewController *mediaPicker;
@property (nonatomic, strong) UIButton *titleButton;
@end

@implementation WPNavigationMediaPickerViewController

static NSString *const ArrowDown = @"\u25be";

- (instancetype)initWithOptions:(WPMediaPickerOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:options];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:[WPMediaPickerOptions new]];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:[WPMediaPickerOptions new]];
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
    WPMediaPickerViewController *vc = self.mediaPicker;
    
    if (!self.dataSource) {
        self.dataSource = [WPPHAssetDataSource sharedInstance];
    }
    vc.dataSource = self.dataSource;
    vc.mediaPickerDelegate = self;

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
    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];

    if (self.mediaPicker.options.allowMultipleSelection) {
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
        [self.delegate mediaPickerController:self.mediaPicker didFinishPickingAssets:self.mediaPicker.selectedAssets];
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

#pragma mark - WPMediaPickerViewControllerDelegate

- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didFinishPickingAssets:(nonnull NSArray<WPMediaAsset> *)assets {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
        [self.delegate mediaPickerController:picker didFinishPickingAssets:assets];
    }
}

- (void)mediaPickerControllerDidCancel:(nonnull WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.delegate mediaPickerControllerDidCancel:picker];
    }
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldShowAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldShowAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldShowAsset:asset];
    }
    return YES;
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldEnableAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldEnableAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldEnableAsset:asset];
    }
    return YES;
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldSelectAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldSelectAsset:asset];
    }
    return YES;
}

- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didSelectAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.delegate mediaPickerController:picker didSelectAsset:asset];
    }
}

- (BOOL)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldDeselectAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldDeselectAsset:)]) {
        return [self.delegate mediaPickerController:picker shouldDeselectAsset:asset];
    }
    return YES;
}

- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker didDeselectAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.delegate mediaPickerController:picker didDeselectAsset:asset];
    }
}

- (nullable UIViewController *)mediaPickerController:(nonnull WPMediaPickerViewController *)picker previewViewControllerForAsset:(nonnull id<WPMediaAsset>)asset {
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:previewViewControllerForAsset:)]) {
        return [self.delegate mediaPickerController:picker previewViewControllerForAsset:asset];
    }

    return [self.mediaPicker defaultPreviewViewControllerForAsset:asset];
}

// TODO: Decide if this should be here or not
//- (void)mediaPickerController:(nonnull WPMediaPickerViewController *)picker shouldPresentPreviewController:(nonnull UIViewController *)previewViewController {
//    if ([self.delegate respondsToSelector:@selector(mediaPickerController:shouldPresentPreviewController:)]) {
//        [self.delegate mediaPickerController:picker shouldPresentPreviewController:previewViewController];
//    }
//}
//
//- (void)mediaPickerControllerShouldDismissPreviewController:(nonnull WPMediaPickerViewController *)picker {
//    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerShouldDismissPreviewController:)]) {
//        [self.delegate mediaPickerControllerShouldDismissPreviewController:picker];
//    }
//}

- (void)mediaPickerControllerWillBeginLoadingData:(nonnull WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerWillBeginLoadingData:)]) {
        [self.delegate mediaPickerControllerWillBeginLoadingData:picker];
    }
}

- (void)mediaPickerControllerDidEndLoadingData:(nonnull WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidEndLoadingData:)]) {
        [self.delegate mediaPickerControllerDidEndLoadingData:picker];
    }
    [self refreshTitle];
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
