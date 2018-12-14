#import <Foundation/Foundation.h>

@interface Notification : NSObject
@property (assign) NSInteger id;
@property (retain, nonatomic) NSString *title;
@property (retain, nonatomic) NSString *body;
@property (retain, nonatomic) NSDate *createdAt;
@property (retain, nonatomic) NSDate *forcePopupDeadline;
@property (assign) BOOL isRead;
@property (retain, nonatomic) NSDate *readAt;
@property (assign) BOOL isReadSynced;
@end
