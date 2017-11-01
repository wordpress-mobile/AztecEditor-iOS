#import "WPMediaGroupPickerViewController.h"
#import "WPMediaGroupTableViewCell.h"

static CGFloat const WPMediaGroupCellHeight = 86.0f;

@interface WPMediaGroupPickerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSObject *changesObserver;

@end

@implementation WPMediaGroupPickerViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = NSLocalizedString(@"Albums", @"Description of albums in the photo libraries");
    }
    return self;
}

- (void)dealloc
{
    [_dataSource unregisterChangeObserver:_changesObserver];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // configure table view
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if ([self respondsToSelector:@selector(popoverPresentationController)]
        && self.popoverPresentationController) {
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    [self.tableView registerClass:[WPMediaGroupTableViewCell class] forCellReuseIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class])];
    self.tableView.rowHeight = WPMediaGroupCellHeight;

    //Setup navigation
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];
    __weak __typeof__(self) weakSelf = self;
    self.changesObserver = [self.dataSource registerChangeObserverBlock:^(BOOL incrementalChanges, NSIndexSet *deleted, NSIndexSet *inserted, NSIndexSet *reload, NSArray *moves) {
            [weakSelf loadData];            
        }];
    [self loadData];
}

- (void)loadData
{
    [self.dataSource loadDataWithOptions:WPMediaLoadOptionsGroups success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showError:error];
        });
    }];
}

- (void)showError:(NSError *)error {
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
    NSString *title = NSLocalizedString(@"Media Library", @"Title for alert when a generic error happened when loading media");
    NSString *message = NSLocalizedString(@"There was a problem when trying to access your media. Please try again later.",  @"Explaining to the user there was an generic error accesing media.");
    NSString *cancelText = NSLocalizedString(@"OK", "");
    NSString *otherButtonTitle = nil;
    if (error.domain == WPMediaPickerErrorDomain &&
        error.code == WPMediaErrorCodePermissionsFailed) {
        otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
        title = NSLocalizedString(@"Media Library", @"Title for alert when access to the media library is not granted by the user");
        message = NSLocalizedString(@"This app needs permission to access your device media library in order to add photos and/or video to your posts. Please change the privacy settings if you wish to allow this.",
                                    @"Explaining to the user why the app needs access to the device media library.");
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:cancelText
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *action) {
                                                         if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewControllerDidCancel:)]) {
                                                             [self.delegate mediaGroupPickerViewControllerDidCancel:self];
                                                         }
                                                     }];
    [alertController addAction:okAction];

    if (otherButtonTitle) {
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        }];
        [alertController addAction:otherAction];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfGroups];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPMediaGroupTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class]) forIndexPath:indexPath];

    id<WPMediaGroup> group = [self.dataSource groupAtIndex:indexPath.row];
    
    cell.imagePosterView.image = nil;
    NSString *groupID = group.identifier;
    cell.groupIdentifier = groupID;
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize requestSize = CGSizeApplyAffineTransform(CGSizeMake(WPMediaGroupCellHeight, WPMediaGroupCellHeight), CGAffineTransformMakeScale(scale, scale));
    [group imageWithSize:requestSize
       completionHandler:^(UIImage *result, NSError *error)
     {
         if (error) {
             return;
         }
         if ([cell.groupIdentifier isEqualToString:groupID]){
             dispatch_async(dispatch_get_main_queue(), ^{
                 cell.imagePosterView.image = result;
             });
         }
     }];
    cell.titleLabel.text = [group name];
    NSInteger numberOfAssets = [group numberOfAssetsOfType:[self.dataSource mediaTypeFilter] completionHandler:^(NSInteger result, NSError *error) {
        if ([cell.groupIdentifier isEqualToString:groupID]){
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)result];
            });
        }
    }];
    if (numberOfAssets != NSNotFound) {
        cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)numberOfAssets];
    } else {
        cell.countLabel.text = NSLocalizedString(@"Counting media items...", @"Message to show while media data source is finding the number of items available.");
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
    if (selectedPath) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:selectedPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self notifySelectionOfGroup];
}

#pragma mark - Callback methods

- (void)cancelPicker:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewControllerDidCancel:)]) {
        [self.delegate mediaGroupPickerViewControllerDidCancel:self];
    }
}

- (void)notifySelectionOfGroup
{
    if (!self.tableView.indexPathForSelectedRow) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewController:didPickGroup:)]) {
        NSInteger selectedRow = self.tableView.indexPathForSelectedRow.row;
        id<WPMediaGroup> group = [self.dataSource groupAtIndex:selectedRow];
        [self.delegate mediaGroupPickerViewController:self didPickGroup:group];
    }
}

@end
