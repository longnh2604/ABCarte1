#import <Foundation/Foundation.h>

#import "NotificationStore.h"
#import "NotificationClient.h"

@interface NotificationSyncer : NSObject
- (id)initWithClient:(NotificationClient *)client store:(NotificationStore *)store;
- (BOOL)sync;
@end
