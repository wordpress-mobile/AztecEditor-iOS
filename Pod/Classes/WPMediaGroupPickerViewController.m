#import "WPMediaGroupPickerViewController.h"
#import "WPMediaGroupTableViewCell.h"

static CGFloat const WPMediaGroupCellHeight = 50.0f;

@interface WPMediaGroupPickerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSObject *changesObserver;

@end

@implementation WPMediaGroupPickerViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
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

    self.title = NSLocalizedString(@"Albums", @"Description of albums in the photo libraries");

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
    self.changesObserver = [self.dataSource registerChangeObserverBlock:^{
        [weakSelf loadData];
    }];
    [self loadData];
}

- (void)loadData
{
    [self.tableView reloadData];
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
    __block WPMediaRequestID requestKey = 0;
    requestKey = [group imageWithSize:CGSizeMake(WPMediaGroupCellHeight, WPMediaGroupCellHeight)
                              completionHandler:^(UIImage *result, NSError *error)
    {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cell.tag == requestKey){
                cell.imagePosterView.image = result;
            }
        });
    }];
    cell.tag = requestKey;
    cell.titleLabel.text = [group name];
    NSInteger numberOfAssets = [group numberOfAssets];
    if (numberOfAssets != NSNotFound) {
        cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)numberOfAssets];
    } else {
        cell.countLabel.text = NSLocalizedString(@"Counting media items...", @"Message to show while media data source is finding the number of items available.");
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if ([[group identifier] isEqual:[[self.dataSource selectedGroup] identifier]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
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
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
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
