#import <UIKit/UIKit.h>
#import "Notification.h"
#import "NotificationStore.h"

@interface NotificationDetailViewController : UIViewController

@property (retain, nonatomic) Notification* notification;

@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *dateLabel;
@property (retain, nonatomic) IBOutlet UITextView *bodyTextView;

- (void) updateView;
@end
