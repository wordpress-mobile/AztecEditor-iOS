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
@property (nonatomic, strong) id<WPMediaCollectionDataSource> pickerDataSource;

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
                     MediaPickerOptionsFilterType:@(WPMediaTypeImage | WPMediaTypeVideo),
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
    } else if ([asset assetType] == WPMediaTypeAudio) {
        cell.countLabel.text = @"Audio";
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

    return _quickInputTextField;
}

- (void)setupMediaKeyboardForInputField {
    self.mediaInputViewController = [[WPInputMediaPickerViewController alloc] init];

    [self addChildViewController:self.mediaInputViewController];
    _quickInputTextField.inputView = self.mediaInputViewController.view;
    [self.mediaInputViewController didMoveToParentViewController:self];

    self.mediaInputViewController.mediaPickerDelegate = self;
    self.mediaInputViewController.mediaPicker.viewControllerToUseToPresent = self;
    _quickInputTextField.inputAccessoryView = self.mediaInputViewController.mediaToolbar;
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
        self.quickInputTextField.inputView = nil;
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
        self.quickInputTextField.inputView = nil;
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

- (UIViewController *)mediaPickerController:(WPMediaPickerViewController *)picker previewViewControllerForAsset:(id<WPMediaAsset>)asset {
    if (picker == self.mediaInputViewController.mediaPicker) {
        return nil;
    }

    if (asset.assetType == WPMediaTypeAudio) {
        return nil;
    }

    if ([self.options[MediaPickerOptionsCustomPreview] boolValue]) {
        return [[CustomPreviewViewController alloc] initWithAsset:asset];
    }

    WPAssetViewController *assetViewController = [[WPAssetViewController alloc] initWithAsset: asset];
    assetViewController.delegate = picker;
    assetViewController.selected = [picker.selectedAssets containsObject:asset];
    return assetViewController;

}

#pragma - Actions

- (void) clearSelection:(id) sender
{
    self.assets = nil;
    [self.tableView reloadData];
}

- (WPMediaPickerOptions *)selectedOptions {
    WPMediaPickerOptions *options = [WPMediaPickerOptions new];
    options.showMostRecentFirst = [self.options[MediaPickerOptionsShowMostRecentFirst] boolValue];
    options.allowCaptureOfMedia = [self.options[MediaPickerOptionsShowCameraCapture] boolValue];
    options.preferFrontCamera = [self.options[MediaPickerOptionsPreferFrontCamera] boolValue];
    options.allowMultipleSelection = [self.options[MediaPickerOptionsAllowMultipleSelection] boolValue];
    options.filter = [self.options[MediaPickerOptionsFilterType] intValue];
    return options;
}

- (void)showPicker:(id) sender
{
    self.mediaPicker = [[WPNavigationMediaPickerViewController alloc] initWithOptions:[self selectedOptions]];
    self.mediaPicker.delegate = self;
    self.pickerDataSource = [[WPPHAssetDataSource alloc] init];
    self.mediaPicker.dataSource = self.pickerDataSource;
    if (self.mediaInputViewController) {
        self.mediaPicker.mediaPicker.selectedAssets = self.mediaInputViewController.mediaPicker.selectedAssets;
        self.mediaInputViewController.mediaPicker.selectedAssets = (NSArray<WPMediaAsset> *)@[];
    }
    self.mediaPicker.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = self.mediaPicker.popoverPresentationController;
    ppc.barButtonItem = sender;
    
    [self presentViewController:self.mediaPicker animated:YES completion:nil];
    [self.quickInputTextField resignFirstResponder];
    self.wasFirstResponder = nil;
}

- (void)showOptions:(id) sender
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
        [self setupMediaKeyboardForInputField];
        self.mediaInputViewController.mediaPicker.options = [self selectedOptions];        
        [self.mediaInputViewController.mediaPicker resetState:NO];
    }
    return YES;
}

@end
