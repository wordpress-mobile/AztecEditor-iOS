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
@property (nonatomic, strong) UIBarButtonItem *selectionButton;
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
    if (!self.dataSource) {
        self.dataSource = [WPPHAssetDataSource sharedInstance];
    }
    self.mediaPicker.dataSource = self.dataSource;
    self.mediaPicker.mediaPickerDelegate = self;

    WPMediaGroupPickerViewController *groupViewController = [[WPMediaGroupPickerViewController alloc] init];
    groupViewController.delegate = self;
    groupViewController.dataSource = self.dataSource;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: groupViewController];
    nav.delegate = self;

    [nav willMoveToParentViewController:self];
    [nav.view setFrame:self.view.bounds];
    [self.view addSubview:nav.view];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
    _internalNavigationController = nav;

    if (self.mediaPicker.options.allowMultipleSelection) {
        [self updateSelectionAction];
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
    [self.mediaPicker setGroup:group];
    self.mediaPicker.title = group.name;
    [self.internalNavigationController pushViewController:self.mediaPicker animated:YES];
}

- (void)mediaGroupPickerViewControllerDidCancel:(WPMediaGroupPickerViewController *)picker
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.delegate mediaPickerControllerDidCancel:self.mediaPicker];
    }
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
    [self updateSelectionAction];
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
    [self updateSelectionAction];
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

- (void)mediaPickerControllerWillBeginLoadingData:(nonnull WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerWillBeginLoadingData:)]) {
        [self.delegate mediaPickerControllerWillBeginLoadingData:picker];
    }
}

- (void)mediaPickerControllerDidEndLoadingData:(nonnull WPMediaPickerViewController *)picker {
    if ([self.delegate respondsToSelector:@selector(mediaPickerControllerDidEndLoadingData:)]) {
        [self.delegate mediaPickerControllerDidEndLoadingData:picker];
    }
}

- (void)updateSelectionAction {
    if (self.mediaPicker.selectedAssets.count == 0 || !self.mediaPicker.options.allowMultipleSelection) {
        self.internalNavigationController.topViewController.navigationItem.rightBarButtonItem = nil;
        return;
    }
    self.selectionButton = [[UIBarButtonItem alloc] initWithTitle:[self selectionActionValue]
                                                            style:UIBarButtonItemStyleDone
                                                           target:self
                                                           action:@selector(finishPicker:)];
    self.internalNavigationController.topViewController.navigationItem.rightBarButtonItem = self.selectionButton;
}

- (NSString *)selectionActionValue {
    NSString *actionString = self.selectionActionTitle;
    if (actionString == nil) {
        actionString = NSLocalizedString(@"Select %@", @"");
    }
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
    NSString * countString = [numberFormatter stringFromNumber:[NSNumber numberWithInteger:self.mediaPicker.selectedAssets.count]];
    NSString * resultString = [NSString stringWithFormat:actionString, countString];

    return resultString;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self updateSelectionAction];
}

#pragma mark - Public Methods

- (void)showAfterViewController:(UIViewController *)viewController
{
    NSParameterAssert(viewController);
    [self.internalNavigationController pushViewController:viewController animated:YES];
}

@end
