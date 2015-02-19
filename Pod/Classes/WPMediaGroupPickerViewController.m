#import "WPMediaGroupPickerViewController.h"

static NSString * const WPMediaGroupCellIdentifier = @"WPMediaGroupCell";

@interface WPMediaGroupPickerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSMutableArray *assetGroups;

@end

@implementation WPMediaGroupPickerViewController

- (instancetype) init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Albums", @"Description of albums in the photo libraries");
    
    // configure table view
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //Prepare data structures;
    if (!self.assetsLibrary) {
        self.assetsLibrary =  [[ALAssetsLibrary alloc] init];
    }
    self.assetGroups = [NSMutableArray array];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];
    
    if ([self respondsToSelector:@selector(popoverPresentationController)]
        && self.popoverPresentationController) {
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    
    [self loadData];
}

- (void) loadData
{
    [self.assetGroups removeAllObjects];
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if(!group){
            [self.tableView reloadData];
            return;
        }
        [self.assetGroups addObject:group];
    } failureBlock:^(NSError *error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.assetGroups.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:WPMediaGroupCellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:WPMediaGroupCellIdentifier];
    }
    
    ALAssetsGroup * group = (ALAssetsGroup *)self.assetGroups[indexPath.row];
    cell.imageView.image = [UIImage imageWithCGImage:[group posterImage]];
    cell.textLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld",(long)[group numberOfAssets]];
    if ( [[group valueForProperty:ALAssetsGroupPropertyPersistentID] isEqual:[self.selectedGroup valueForProperty:ALAssetsGroupPropertyPersistentID]] ) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * selectedPath = [self.tableView indexPathForSelectedRow];
    if (selectedPath) {
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:selectedPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self notifySelectionOfGroup];
}

#pragma mark - Callback methods

- (void)cancelPicker:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewControllerDidCancel:)]){
        [self.delegate mediaGroupPickerViewControllerDidCancel:self];
    }
}

- (void) notifySelectionOfGroup
{
    if (!self.tableView.indexPathForSelectedRow) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(mediaGroupPickerViewController:didPickGroup:)]){
        NSInteger selectedRow = self.tableView.indexPathForSelectedRow.row;
        ALAssetsGroup * group = self.assetGroups[selectedRow];
        [self.delegate mediaGroupPickerViewController:self didPickGroup:group];
    }
    
}


@end
