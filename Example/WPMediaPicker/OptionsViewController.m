#import "OptionsViewController.h"

NSString const *MediaPickerOptionsShowMostRecentFirst = @"MediaPickerOptionsShowMostRecentFirst";
NSString const *MediaPickerOptionsUsePhotosLibrary = @"MediaPickerOptionsUsePhotosLibrary";
NSString const *MediaPickerOptionsShowCameraCapture = @"MediaPickerOptionsShowCameraCapture";
NSString const *MediaPickerOptionsAllowMultipleSelection = @"MediaPickerOptionsAllowMultipleSelection";
NSString const *MediaPickerOptionsPostProcessingStep = @"MediaPickerOptionsPostProcessingStep";

typedef NS_ENUM(NSInteger, OptionsViewControllerCell){
    OptionsViewControllerCellShowMostRecentFirst,
    OptionsViewControllerCellShowCameraCapture,
    OptionsViewControllerCellAllowMultipleSelection,
    OptionsViewControllerCellPostProcessingStep,
    OptionsViewControllerCellTotal
};

@interface OptionsViewController ()

@property (nonatomic, strong) UITableViewCell *showMostRecentFirstCell;
@property (nonatomic, strong) UITableViewCell *showCameraCaptureCell;
@property (nonatomic, strong) UITableViewCell *allowMultipleSelectionCell;
@property (nonatomic, strong) UITableViewCell *postProcessingStepCell;

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
    
    self.allowMultipleSelectionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.allowMultipleSelectionCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.allowMultipleSelectionCell.accessoryView).on = [self.options[MediaPickerOptionsAllowMultipleSelection] boolValue];
    self.allowMultipleSelectionCell.textLabel.text = @"Allow Multiple Selection";
    
    self.postProcessingStepCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.postProcessingStepCell.accessoryView = [[UISwitch alloc] init];
    ((UISwitch *)self.postProcessingStepCell.accessoryView).on = [self.options[MediaPickerOptionsPostProcessingStep] boolValue];
    self.postProcessingStepCell.textLabel.text = @"Shows Post Processing Step";
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
        case OptionsViewControllerCellAllowMultipleSelection:
            return self.allowMultipleSelectionCell;
            break;
        case OptionsViewControllerCellPostProcessingStep:
            return self.postProcessingStepCell;
            break;
        default:
            break;
    }
    return nil;
}

- (void)done:(id) sender
{
    if ([self.delegate respondsToSelector:@selector(optionsViewController:changed:)]){
        id<OptionsViewControllerDelegate> delegate = self.delegate;
        NSDictionary *newOptions = @{
             MediaPickerOptionsShowMostRecentFirst:@(((UISwitch *)self.showMostRecentFirstCell.accessoryView).on),
             MediaPickerOptionsShowCameraCapture:@(((UISwitch *)self.showCameraCaptureCell.accessoryView).on),
             MediaPickerOptionsAllowMultipleSelection:@(((UISwitch *)self.allowMultipleSelectionCell.accessoryView).on),
             MediaPickerOptionsPostProcessingStep:@(((UISwitch *)self.postProcessingStepCell.accessoryView).on)
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
