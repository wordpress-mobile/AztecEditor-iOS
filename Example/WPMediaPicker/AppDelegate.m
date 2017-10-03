#import "AppDelegate.h"
#import "DemoViewController.h"
#import <WPMediaPicker/WPMediaPicker.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[DemoViewController alloc]  init]];
    [self.window makeKeyAndVisible];
    
    // Customize appearance
    self.window.tintColor = [UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f];
    self.window.backgroundColor = [UIColor whiteColor];
    
    //Configure navigation bar background color
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f]];
    //Configure navigation bar items text color
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    //Configure navigation bar title text color
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} ];

    //Configure navigation bar background color
    UIColor *wordPressBlue = [UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[WPMediaPickerViewController class]]] setBarTintColor: wordPressBlue];
    //Configure navigation bar items text color
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[WPMediaPickerViewController class]]] setTintColor:[UIColor whiteColor]];
    //Configure navigation bar title text color
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[WPMediaPickerViewController class]]] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} ];
    //Configure background color for media scroll view
    [[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[[WPMediaPickerViewController class]]] setBackgroundColor:[UIColor whiteColor]];
    [[UITableView appearanceWhenContainedInInstancesOfClasses:@[[WPNavigationMediaPickerViewController class]]] setBackgroundColor:[UIColor whiteColor]];
    //Configure background color for media cell while loading image.
    UIColor *cellBackgroundColor = [UIColor colorWithRed:243/255.0f green:246/255.0f blue:248/255.0f alpha:1.0f];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[[WPMediaPickerViewController class]]] setLoadingBackgroundColor:cellBackgroundColor];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[[WPInputMediaPickerViewController class]]] setLoadingBackgroundColor:cellBackgroundColor];
    [[WPMediaGroupTableViewCell appearance] setPosterBackgroundColor:cellBackgroundColor];

    //Configure placeholder background color for media cell.
    UIColor *placeholderCellBackgroundColor = [UIColor lightGrayColor];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[[WPMediaPickerViewController class]]] setPlaceholderBackgroundColor:placeholderCellBackgroundColor];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[[WPInputMediaPickerViewController class]]] setPlaceholderBackgroundColor:placeholderCellBackgroundColor];

    //Configure color for activity indicator while loading media collection
    [[UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[[WPMediaPickerViewController class]]] setColor:[UIColor grayColor]];

    //Configure background color for media cell while loading image.

    UIColor * lightGray = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:0.7];

    [[WPMediaCollectionViewCell appearance] setTintColor:wordPressBlue];
    [[WPMediaCollectionViewCell appearance] setPositionLabelUnselectedTintColor:lightGray];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[[WPInputMediaPickerViewController class]]] setPositionLabelUnselectedTintColor:lightGray];

    return YES;
}
							

@end
