#import "DemoViewController.h"
#import "WPPHAssetDataSource.h"
#import <WPMediaPicker/WPMediaPicker.h>
#import <WPMediaPicker/WPMediaGroupTableViewCell.h>

@interface DemoViewController () <WPMediaPickerViewControllerDelegate>
@property (nonatomic, strong) NSArray * assets;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;
@property (nonatomic, strong) WPPHAssetDataSource *phAssetDataSource;
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
    [self.tableView registerClass:[WPMediaGroupTableViewCell class] forCellReuseIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class])];

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

#pragma - <WPMediaPickerViewControllerDelegate>

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
    self.phAssetDataSource = [[WPPHAssetDataSource alloc] init];
    mediaPicker.dataSource = self.phAssetDataSource;
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

@end
