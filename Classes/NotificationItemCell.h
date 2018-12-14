#import <UIKit/UIKit.h>
#import "Notification.h"

@interface NotificationItemCell : UITableViewCell
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *isNewLabel;

- (void)setNotification:(Notification *)notification;
@end
