#import "OptionsViewController.h"
#import "WPMediaCollectionDataSource.h"

NSString const *MediaPickerOptionsShowMostRecentFirst = @"MediaPickerOptionsShowMostRecentFirst";
NSString const *MediaPickerOptionsUsePhotosLibrary = @"MediaPickerOptionsUsePhotosLibrary";
NSString const *MediaPickerOptionsShowCameraCapture = @"MediaPickerOptionsShowCameraCapture";
NSString const *MediaPickerOptionsPreferFrontCamera = @"MediaPickerOptionsPreferFrontCamera";
NSString const *MediaPickerOptionsAllowMultipleSelection = @"MediaPickerOptionsAllowMultipleSelection";
NSString const *MediaPickerOptionsPostProcessingStep = @"MediaPickerOptionsPostProcessingStep";
NSString const *MediaPickerOptionsFilterType = @"MediaPickerOptionsFilterType";
NSString const *MediaPickerOptionsCustomPreview = @"MediaPickerOptionsCustomPreview";
NSString const *MediaPickerOptionsScrollInputPickerVertically = @"MediaPickerOptionsScrollInputPickerVertically";

typedef NS_ENUM(NSInteger, OptionsViewControllerCell){
    OptionsViewControllerCellShowMostRecentFirst,
    OptionsViewControllerCellShowCameraCapture,
    OptionsViewControllerCellPreferFrontCamera,
    OptionsViewControllerCellAllowMultipleSelection,
    OptionsViewControllerCellPostProcessingStep,
    OptionsViewControllerCellMediaType,
    OptionsViewControllerCellCustomPreview,
    OptionsViewControllerCellInputPickerScroll,
    OptionsViewControllerCellTotal
};

@interface OptionsViewController ()

@property (nonatomic, strong) UITableViewCell *showMostRecentFirstCell;
@property (nonatomic, strong) UITableViewCell *showCameraCaptureCell;
@property (nonatomic, strong) UITableViewCell *preferFrontCameraCell;
@property (nonatomic, strong) UITableViewCell *allowMultipleSelectionCell;
@property (nonatomic, strong) UITableViewCell *postProcessingStepCell;
@property (nonatomic, strong) UITableViewCell *filterMediaCell;
@property (nonatomic, strong) UITableViewCell *customPreviewCell;
@property (nonatomic, strong) UITableViewCell *scrollInputPickerCell;

@end

@implementation OptionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelection = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
    self.showMostRecentFirstCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.showMostRecentFirstCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.showMostRecentFirstCell.accessoryView).on = [self.options[MediaPickerOptionsShowMostRecentFirst] boolValue];
    self.showMostRecentFirstCell.textLabel.text = @"Show Most Recent First";

    self.showCameraCaptureCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.showCameraCaptureCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.showCameraCaptureCell.accessoryView).on = [self.options[MediaPickerOptionsShowCameraCapture] boolValue];
    self.showCameraCaptureCell.textLabel.text = @"Show Capture Cell";

    self.preferFrontCameraCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.preferFrontCameraCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.preferFrontCameraCell.accessoryView).on = [self.options[MediaPickerOptionsPreferFrontCamera] boolValue];
    self.preferFrontCameraCell.textLabel.text = @"Prefer Front Camera";
    
    self.allowMultipleSelectionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.allowMultipleSelectionCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.allowMultipleSelectionCell.accessoryView).on = [self.options[MediaPickerOptionsAllowMultipleSelection] boolValue];
    self.allowMultipleSelectionCell.textLabel.text = @"Allow Multiple Selection";
    
    self.postProcessingStepCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.postProcessingStepCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.postProcessingStepCell.accessoryView).on = [self.options[MediaPickerOptionsPostProcessingStep] boolValue];
    self.postProcessingStepCell.textLabel.text = @"Shows Post Processing Step";

    self.filterMediaCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[@"Photos", @"Videos", @"Photos & Videos"]];
    self.filterMediaCell.accessoryView = segment;
    NSInteger filterOption = [self.options[MediaPickerOptionsFilterType] intValue];
    if ((filterOption & WPMediaTypeImage) && (filterOption & WPMediaTypeVideo)) {
        segment.selectedSegmentIndex = 2;
    } else if (filterOption & WPMediaTypeImage) {
        segment.selectedSegmentIndex = 0;
    } else {
        segment.selectedSegmentIndex = 1;
    }
    self.filterMediaCell.textLabel.text = @"Media Type";

    self.customPreviewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.customPreviewCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.customPreviewCell.accessoryView).on = [self.options[MediaPickerOptionsCustomPreview] boolValue];
    self.customPreviewCell.textLabel.text = @"Use Custom Preview Controller";

    self.scrollInputPickerCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.scrollInputPickerCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.scrollInputPickerCell.accessoryView).on = [self.options[MediaPickerOptionsScrollInputPickerVertically] boolValue];
    self.scrollInputPickerCell.textLabel.text = @"Scroll Input Picker Vertically";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return OptionsViewControllerCellTotal;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case OptionsViewControllerCellShowMostRecentFirst:
            return self.showMostRecentFirstCell;
            break;
        case OptionsViewControllerCellShowCameraCapture:
            return self.showCameraCaptureCell;
            break;
        case OptionsViewControllerCellPreferFrontCamera:
            return self.preferFrontCameraCell;
            break;
        case OptionsViewControllerCellAllowMultipleSelection:
            return self.allowMultipleSelectionCell;
            break;
        case OptionsViewControllerCellPostProcessingStep:
            return self.postProcessingStepCell;
            break;
        case OptionsViewControllerCellMediaType:
            return self.filterMediaCell;
            break;
        case OptionsViewControllerCellCustomPreview:
            return self.customPreviewCell;
            break;
        case OptionsViewControllerCellInputPickerScroll:
            return self.scrollInputPickerCell;
            break;
        default:
            break;
    }
    return [UITableViewCell new];
}

- (void)done:(id) sender
{
    NSInteger selectedFilterOption = ((UISegmentedControl *)self.filterMediaCell.accessoryView).selectedSegmentIndex;
    NSInteger filterType = WPMediaTypeImage;
    if (selectedFilterOption == 1) {
        filterType = WPMediaTypeVideo;
    } else if (selectedFilterOption == 2) {
        filterType = WPMediaTypeImage | WPMediaTypeVideo;
    }

    if ([self.delegate respondsToSelector:@selector(optionsViewController:changed:)]){
        id<OptionsViewControllerDelegate> delegate = self.delegate;
        NSDictionary *newOptions = @{
             MediaPickerOptionsShowMostRecentFirst:@(((UISwitch *)self.showMostRecentFirstCell.accessoryView).on),
             MediaPickerOptionsShowCameraCapture:@(((UISwitch *)self.showCameraCaptureCell.accessoryView).on),
             MediaPickerOptionsPreferFrontCamera:@(((UISwitch *)self.preferFrontCameraCell.accessoryView).on),
             MediaPickerOptionsAllowMultipleSelection:@(((UISwitch *)self.allowMultipleSelectionCell.accessoryView).on),
             MediaPickerOptionsPostProcessingStep:@(((UISwitch *)self.postProcessingStepCell.accessoryView).on),
             MediaPickerOptionsFilterType:@(filterType),
             MediaPickerOptionsCustomPreview:@(((UISwitch *)self.customPreviewCell.accessoryView).on),
             MediaPickerOptionsScrollInputPickerVertically:@(((UISwitch *)self.scrollInputPickerCell.accessoryView).on),
             };
        
        [delegate optionsViewController:self changed:newOptions];
    }
}

- (void)cancel:(id) sender
{
    if ([self.delegate respondsToSelector:@selector(cancelOptionsViewController:)]){
        id<OptionsViewControllerDelegate> delegate = self.delegate;
        [delegate cancelOptionsViewController:self];
    }
}

@end
