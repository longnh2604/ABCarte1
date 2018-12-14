#import "NotificationSyncer.h"

@implementation NotificationSyncer
{
    NotificationClient* _client;
    NotificationStore* _store;
}

- (id)initWithClient:(NotificationClient *)client store:(NotificationStore *)store {
    if (self = [super init]) {
        _client = client;
        _store = store;
    }
    return self;
}

- (BOOL)sync {
    NSArray* readNotifications = [_store getReadNotifications];
    NSMutableArray* notificationIds = [NSMutableArray array];
    NSMutableArray *readTimes = [NSMutableArray array];
    for (Notification* notification in readNotifications) {
        if (notification.isReadSynced) {
            continue;
        }
        
        [notificationIds addObject:@(notification.id)];
        [readTimes addObject:notification.readAt];
    }
    if (notificationIds.count == 0) {
        return YES;
    }
    if (![_client setNotificationsRead:notificationIds readTimes:readTimes]) {
        NSLog(@"[NotificationSyncer#sync] setNotificationsRead failed");
        return NO;
    }
    if (![_store setSynced:notificationIds]) {
        NSLog(@"[NotificationSyncer#sync] setSynced failed");
        return NO;
    }
    return YES;
}

@end
