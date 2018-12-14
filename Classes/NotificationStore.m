#import "NotificationStore.h"
#import "FMDatabase.h"

static NSString * const NotificationStoreDBFileName = @"notification.db";

@interface NotificationStore ()
@end

@implementation NotificationStore
{
    NSString *_dbPath;
}

- (void)dealloc {
    NSLog(@"NotificationStore dealloc");
    [_dbPath release];
    [super dealloc];
}

- (id) init {
    self = [super init];

    //データベースのパス取得
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _dbPath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:NotificationStoreDBFileName] retain];

    return self;
}

- (BOOL) initializeDatabase {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            return NO;
        }
        NSString *createTableSql =
        @"CREATE TABLE IF NOT EXISTS notifications ("
        " id INTEGER PRIMARY KEY AUTOINCREMENT, "
        " title TEXT, "
        " body TEXT, "
        " created_at TEXT, "
        " force_popup_deadline TEXT, "
        " is_read INTEGER, "
        " read_at TEXT, "
        " is_read_synced INTEGER ); ";
        BOOL result = [db executeUpdate:createTableSql];
        if(!result)
        {
            NSLog(@"DB CREATE TABLE ERROR : %@", [db lastErrorMessage]);
            [db close];
            return NO;
        }
        
        [db close];
        return YES;
    }
}

- (BOOL) insertNotifications:(NSArray *)notifications {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            NSLog(@"[insertNotifications] could not open database");
            return NO;
        }
        
        BOOL result;
        result = [db beginTransaction];
        if (!result) {
            NSLog(@"[insertNotifications] beginTransaction failed : %@", [db lastErrorMessage]);
            [db close];
            return NO;
        }
        
        for (Notification* notif in notifications) {
            result = [self insertNotification:db notification:notif];
            if (!result) {
                result = [db rollback];
                if (!result) {
                    NSLog(@"[insertNotifications] rollback failed : %@", [db lastErrorMessage]);
                }
                [db close];
                return NO;
            }
        }
        
        result = [db commit];
        if (!result) {
            NSLog(@"[insertNotifications] commit failed : %@", [db lastErrorMessage]);
            [db close];
            return NO;
        }
        
        [db close];
        return YES;
    }
}

- (BOOL) deleteAllNotifications {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            NSLog(@"[deleteAllNotifications] could not open database");
            return NO;
        }
        
        if (![db executeUpdate:@"delete from notifications;"]) {
            NSLog(@"[deleteAllNotifications] delete query failed : %@", [db lastErrorMessage]);
            [db close];
            return NO;
        }
        
        [db close];
        return YES;
    }
}

- (NSArray *) getAllNotifications {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            NSLog(@"getAllNotifications failed : could not open database");
            return nil;
        }
        
        NSMutableArray *notifications = [NSMutableArray array];
        
        // 新しいお知らせが前になるように取得する
        FMResultSet *result = [db executeQuery:@"select * from notifications order by created_at desc;"];
        if (result == nil) {
            NSLog(@"select all notifications failed : %@", [db lastErrorMessage]);
            return nil;
        }
        while ([result next]) {
            Notification *notif = [[[Notification alloc] init] autorelease];
            notif.id = [result intForColumn:@"id"];
            notif.title = [result stringForColumn:@"title"];
            notif.body = [result stringForColumn:@"body"];
            notif.createdAt = [result dateForColumn:@"created_at"];
            notif.forcePopupDeadline = [result dateForColumn:@"force_popup_deadline"];
            notif.isRead = [result boolForColumn:@"is_read"];
            notif.readAt = [result dateForColumn:@"read_at"];
            notif.isReadSynced = [result boolForColumn:@"is_read_synced"];
            [notifications addObject:notif];
        }
        
        [db close];
        return notifications;
    }
}

- (NSArray *) getNotificationsToDisplay:(NSDate *)date {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            NSLog(@"getAllNotifications failed : could not open database");
            return nil;
        }
        
        NSMutableArray *notifications = [NSMutableArray array];
        
        // 強制的に表示すべきものを古い順から最大5件取得する
        FMResultSet *result = [db executeQuery:@"select * from notifications where force_popup_deadline > ? AND is_read = 0 order by created_at limit 5;", date];
        if (result == nil) {
            NSLog(@"select all notifications failed : %@", [db lastErrorMessage]);
            return nil;
        }
        while ([result next]) {
            Notification *notif = [[[Notification alloc] init] autorelease];
            notif.id = [result intForColumn:@"id"];
            notif.title = [result stringForColumn:@"title"];
            notif.body = [result stringForColumn:@"body"];
            notif.createdAt = [result dateForColumn:@"created_at"];
            notif.forcePopupDeadline = [result dateForColumn:@"force_popup_deadline"];
            notif.isRead = [result boolForColumn:@"is_read"];
            notif.readAt = [result dateForColumn:@"read_at"];
            notif.isReadSynced = [result boolForColumn:@"is_read_synced"];
            [notifications addObject:notif];
        }
        
        [db close];
        return notifications;
    }
}

- (NSArray *) getReadNotifications {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            NSLog(@"getAllNotifications failed : could not open database");
            return nil;
        }
        
        NSMutableArray *notifications = [NSMutableArray array];
        
        FMResultSet *result = [db executeQuery:@"select * from notifications where is_read = 1 order by created_at desc;"];
        if (result == nil) {
            NSLog(@"select all notifications failed : %@", [db lastErrorMessage]);
            return nil;
        }
        while ([result next]) {
            Notification *notif = [[[Notification alloc] init] autorelease];
            notif.id = [result intForColumn:@"id"];
            notif.title = [result stringForColumn:@"title"];
            notif.body = [result stringForColumn:@"body"];
            notif.createdAt = [result dateForColumn:@"created_at"];
            notif.forcePopupDeadline = [result dateForColumn:@"force_popup_deadline"];
            notif.isRead = [result boolForColumn:@"is_read"];
            notif.readAt = [result dateForColumn:@"read_at"];
            notif.isReadSynced = [result boolForColumn:@"is_read_synced"];
            [notifications addObject:notif];
        }
        
        [db close];
        return notifications;
    }
}

- (Notification *) getNotificationById:(NSInteger)notificationId {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            NSLog(@"[getNotificationById] could not open database");
            return nil;
        }
        
        FMResultSet *result = [db executeQuery:@"select * from notifications where id = ?;", @(notificationId)];
        if (![result next]) {
            [db close];
            return nil;
        }
        Notification *notif = [[[Notification alloc] init] autorelease];
        notif.id = [result intForColumn:@"id"];
        notif.title = [result stringForColumn:@"title"];
        notif.body = [result stringForColumn:@"body"];
        notif.createdAt = [result dateForColumn:@"created_at"];
        notif.forcePopupDeadline = [result dateForColumn:@"force_popup_deadline"];
        notif.isRead = [result boolForColumn:@"is_read"];
        notif.readAt = [result dateForColumn:@"read_at"];
        notif.isReadSynced = [result boolForColumn:@"is_read_synced"];
        [db close];
        return notif;
    }
}

- (BOOL) setRead:(NSInteger)notificationId readAt:(NSDate *)readAt {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            NSLog(@"[setRead] could not open database");
            return NO;
        }
        
        BOOL result = [db executeUpdate:@"update notifications set is_read = 1, read_at = ? where id = ?", readAt, @(notificationId)];
        [db close];
        return result;
    }
}

- (BOOL) setSynced:(NSArray *)notificationIds {
    @synchronized (self) {
        FMDatabase *db = [self openDatabase];
        if (db == nil) {
            NSLog(@"[setSynced] could not open database");
            return NO;
        }
        
        BOOL result;
        result = [db beginTransaction];
        if (!result) {
            NSLog(@"[setSynced] beginTransaction failed : %@", [db lastErrorMessage]);
            [db close];
            return NO;
        }
        
        for (NSNumber* notificationId in notificationIds) {
            result = [db executeUpdate:@"update notifications set is_read_synced = 1 where id = ?", notificationId];
            if (!result) {
                result = [db rollback];
                if (!result) {
                    NSLog(@"[setSynced] rollback failed : %@", [db lastErrorMessage]);
                }
                [db close];
                return NO;
            }
        }
        
        result = [db commit];
        if (!result) {
            NSLog(@"[setSynced] commit failed : %@", [db lastErrorMessage]);
            [db close];
            return NO;
        }
        
        [db close];
        return YES;
    }
}


- (FMDatabase*) openDatabase {
    FMDatabase *db = [FMDatabase databaseWithPath:_dbPath];
    if (db == nil) {
        NSLog(@"Could init FMDatabase");
        return nil;
    }
    BOOL result = [db open];
    if (!result) {
        NSLog(@"DB open error : %@", [db lastErrorMessage]);
        [db close];
        return nil;
    }
    return db;
}

- (BOOL) insertNotification:(FMDatabase *)db notification:(Notification *)notif {
    NSString *sql =
    @" INSERT INTO notifications "
    " ( id, title, body, created_at, force_popup_deadline, is_read, read_at, is_read_synced ) "
    " values ( ?, ?, ?, ?, ?, ?, ?, ? ); ";
    BOOL result = [db executeUpdate:sql, @(notif.id), notif.title, notif.body, notif.createdAt, notif.forcePopupDeadline, @(notif.isRead), notif.readAt, @(notif.isReadSynced)];
    return result;
}

- (NSDate *) parseDateString:(NSString *)dateStr {
    if (dateStr == nil) {
        return nil;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"JST"]];
    NSDate *date = [dateFormatter dateFromString:dateStr];
    [dateFormatter release];
    return date;
}

@end
