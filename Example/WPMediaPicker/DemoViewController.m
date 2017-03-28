#import "DemoViewController.h"
#import "CustomPreviewViewController.h"
#import "WPPHAssetDataSource.h"
#import "OptionsViewController.h"
#import "PostProcessingViewController.h"
#import <WPMediaPicker/WPMediaPicker.h>

@interface DemoViewController () <WPMediaPickerViewControllerDelegate, OptionsViewControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSArray * assets;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;
@property (nonatomic, strong) id<WPMediaCollectionDataSource> customDataSource;
@property (nonatomic, copy) NSDictionary *options;
@property (nonatomic, strong) WPNavigationMediaPickerViewController *mediaPicker;
@property (nonatomic, strong) UITextField *quickInputTextField;
@property (nonatomic, strong) WPInputMediaPickerViewController *mediaInputViewController;
@property (nonatomic, strong) UIView* wasFirstResponder;

@end

@implementation DemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"WPMediaPicker";
    //setup nav buttons
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Options" style:UIBarButtonItemStylePlain target:self action:@selector(showOptions:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showPicker:)];
    
    // date formatter
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    [self.tableView registerClass:[WPMediaGroupTableViewCell class] forCellReuseIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class])];
    self.options = @{
                     MediaPickerOptionsShowMostRecentFirst:@(YES),
                     MediaPickerOptionsShowCameraCapture:@(YES),
                     MediaPickerOptionsAllowMultipleSelection:@(YES),
                     MediaPickerOptionsPostProcessingStep:@(NO),
                     MediaPickerOptionsFilterType:@(WPMediaTypeVideoOrImage),
                     MediaPickerOptionsCustomPreview:@(NO)
                     };

}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.quickInputTextField.isFirstResponder) {
        self.wasFirstResponder = self.quickInputTextField;
    } else {
        self.wasFirstResponder = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.wasFirstResponder != nil && self.wasFirstResponder == self.quickInputTextField) {
        [self.quickInputTextField becomeFirstResponder];
    }
    [super viewWillAppear:animated];
}

#pragma - UITableViewControllerDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPMediaGroupTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class]) forIndexPath:indexPath];
    
    id<WPMediaAsset> asset = self.assets[indexPath.row];
    __block WPMediaRequestID requestID = 0;
    requestID = [asset imageWithSize:CGSizeMake(100,100) completionHandler:^(UIImage *result, NSError *error) {
        if (error) {
            return;
        }
        if (cell.tag == requestID) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imagePosterView.image = result;
            });
        }
    }];
    cell.tag = requestID;
    cell.titleLabel.text = [self.dateFormatter stringFromDate:[asset date]];
    if ([asset assetType] == WPMediaTypeImage) {
        cell.countLabel.text = @"Image";
    } else if ([asset assetType] == WPMediaTypeVideo) {
        cell.countLabel.text = @"Video";
    } else {
        cell.countLabel.text = @"Other";
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *viewHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, 44)];
    [viewHeaderView addSubview:self.quickInputTextField];
    self.quickInputTextField.frame = CGRectInset(viewHeaderView.frame, 2, 2);
    self.quickInputTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return viewHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44.0;
}

- (UITextField *)quickInputTextField {
    if (_quickInputTextField) {
        return _quickInputTextField;
    }
    _quickInputTextField = [[UITextField alloc] initWithFrame:CGRectInset(CGRectMake(0, 0, self.view.frame.size.width, 44), 5, 2)];
    _quickInputTextField.placeholder = @"Tap here to quick select assets";
    _quickInputTextField.borderStyle = UITextBorderStyleRoundedRect;
    _quickInputTextField.delegate = self;

    self.mediaInputViewController = [[WPInputMediaPickerViewController alloc] init];

    [self addChildViewController:self.mediaInputViewController];
    _quickInputTextField.inputView = self.mediaInputViewController.view;
    [self.mediaInputViewController didMoveToParentViewController:self];

    self.mediaInputViewController.mediaPickerDelegate = self;
    self.mediaInputViewController.mediaPicker.viewControllerToUseToPresent = self;
    _quickInputTextField.inputAccessoryView = self.mediaInputViewController.mediaToolbar;

    return _quickInputTextField;
}

- (id<WPMediaCollectionDataSource>)defaultDataSource
{
    static id<WPMediaCollectionDataSource> assetSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assetSource = [[WPPHAssetDataSource alloc] init];
    });
    return assetSource;
}

#pragma - <WPMediaPickerViewControllerDelegate>

- (void)mediaPickerControllerDidCancel:(WPMediaPickerViewController *)picker
{
    if (picker == self.mediaInputViewController.mediaPicker) {
        [self.quickInputTextField resignFirstResponder];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    // Update Assets
    self.assets = assets;
    [self.tableView reloadData];
    
    if (picker == self.mediaInputViewController.mediaPicker) {
        [self.quickInputTextField resignFirstResponder];
        return;
    }
    
    // PostProcessing is Optional!
    if ([self.options[MediaPickerOptionsPostProcessingStep] boolValue] == false) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // Sample Post Processing
    PostProcessingViewController *postProcessingViewController = [PostProcessingViewController new];
    postProcessingViewController.onCompletion = ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    [self.mediaPicker showAfterViewController:postProcessingViewController];
}

- (UIViewController *)mediaPickerController:(WPMediaPickerViewController *)picker previewViewControllerForAsset:(id<WPMediaAsset>)asset
{
    if ([self.options[MediaPickerOptionsCustomPreview] boolValue] == false) {
        return nil;
    }

    return [[CustomPreviewViewController alloc] initWithAsset:asset];
}

#pragma - Actions

- (void) clearSelection:(id) sender
{
    self.assets = nil;
    [self.tableView reloadData];
}

- (void) showPicker:(id) sender
{
    self.mediaPicker = [[WPNavigationMediaPickerViewController alloc] init];
    self.mediaPicker.delegate = self;
    self.mediaPicker.showMostRecentFirst = [self.options[MediaPickerOptionsShowMostRecentFirst] boolValue];
    self.mediaPicker.allowCaptureOfMedia = [self.options[MediaPickerOptionsShowCameraCapture] boolValue];
    self.mediaPicker.preferFrontCamera = [self.options[MediaPickerOptionsPreferFrontCamera] boolValue];
    self.mediaPicker.allowMultipleSelection = [self.options[MediaPickerOptionsAllowMultipleSelection] boolValue];
    self.mediaPicker.filter = [self.options[MediaPickerOptionsFilterType] intValue];
    self.mediaPicker.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = self.mediaPicker.popoverPresentationController;
    ppc.barButtonItem = sender;
    
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
}

- (void) showOptions:(id) sender
{
    OptionsViewController *optionsViewController = [[OptionsViewController alloc] init];
    optionsViewController.delegate = self;
    optionsViewController.options = self.options;
    [[self navigationController] pushViewController:optionsViewController animated:YES];
}

#pragma - Options

- (void)optionsViewController:(OptionsViewController *)optionsViewController changed:(NSDictionary *)options
{
    self.options = options;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelOptionsViewController:(OptionsViewController *)optionsViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.quickInputTextField) {
        self.mediaInputViewController.mediaPicker.showMostRecentFirst = [self.options[MediaPickerOptionsShowMostRecentFirst] boolValue];
        self.mediaInputViewController.mediaPicker.allowCaptureOfMedia = [self.options[MediaPickerOptionsShowCameraCapture] boolValue];
        self.mediaInputViewController.mediaPicker.preferFrontCamera = [self.options[MediaPickerOptionsPreferFrontCamera] boolValue];
        self.mediaInputViewController.mediaPicker.allowMultipleSelection = [self.options[MediaPickerOptionsAllowMultipleSelection] boolValue];
        self.mediaInputViewController.mediaPicker.filter = [self.options[MediaPickerOptionsFilterType] intValue];
        [self.mediaInputViewController.mediaPicker resetState:NO];
    }
    return YES;
}

@end
