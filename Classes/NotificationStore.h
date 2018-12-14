#import <Foundation/Foundation.h>
#import "Notification.h"

@interface NotificationStore : NSObject

- (BOOL) testFunc;

- (BOOL) initializeDatabase;
- (BOOL) insertNotifications:(NSArray *)notifications;
- (BOOL) deleteAllNotifications;
- (NSArray *) getAllNotifications;
- (NSArray *) getNotificationsToDisplay:(NSDate *)date;
- (NSArray *) getReadNotifications;
- (Notification *) getNotificationById:(NSInteger)notificationId;
- (BOOL) setRead:(NSInteger)notificationId readAt:(NSDate *)readAt;
- (BOOL) setSynced:(NSArray *)notificationIds;
@end
