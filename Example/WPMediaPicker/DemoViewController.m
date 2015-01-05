#import "DemoViewController.h"
#import <WPMediaPicker/WPMediaPickerViewController.h>

@interface DemoViewController () <WPMediaPickerViewControllerDelegate>
@property (nonatomic, strong) NSArray * assets;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;
@end

@implementation DemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"WPMediaPicker";
    //setup nav buttons
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearSelection:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showPicker:)];
    
    // date formatter
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    ALAsset * asset = self.assets[indexPath.row];
    cell.imageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
    
    cell.textLabel.text = [self.dateFormatter stringFromDate:[asset valueForProperty:ALAssetPropertyDate]];
    cell.detailTextLabel.text = [asset valueForProperty:ALAssetPropertyType];
    cell.detailTextLabel.hidden = NO;
    
    return cell;
}

#pragma - <SVEMediaPickerViewControllerDelegate>

- (void)mediaPickerControllerDidCancel:(WPMediaPickerViewController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.assets = assets;
    
    [self.tableView reloadData];
}

#pragma - Actions

- (void) clearSelection:(id) sender
{
    self.assets = nil;
    [self.tableView reloadData];
}

- (void) showPicker:(id) sender
{
    WPMediaPickerViewController * mediaPicker = [[WPMediaPickerViewController alloc] init];
    mediaPicker.delegate = self;
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

@end
