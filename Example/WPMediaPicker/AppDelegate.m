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
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} ];
    [[UICollectionView appearanceWhenContainedIn:[WPMediaCollectionViewController class],nil] setBackgroundColor:[UIColor colorWithRed:233/255.0f green:239/255.0f blue:243/255.0f alpha:1.0f]];
    return YES;
}
							

@end
