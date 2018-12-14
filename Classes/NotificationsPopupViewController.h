#import <UIKit/UIKit.h>

@interface NotificationsPopupViewController : UIViewController
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

+ (UINavigationController *) createNavigationController;

@end
