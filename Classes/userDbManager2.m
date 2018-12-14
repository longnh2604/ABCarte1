//
//  userDbManager2.m
//  iPadCamera
//

#import "userDbManager2.h"

#import "userDbManager.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "Common.h"


#import "mstUser.h"
#import "fcUserWorkItem.h"

@implementation userDbManager2

- (id)init
{
    self = [super init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //データベースのパス取得
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:DB_FILE_NAME];
    BOOL success = [fileManager fileExistsAtPath:dbPath];
    //無ければコピー
    if(!success){
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_FILE_NAME];
        NSError *error = nil;
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        if(!success){
            NSLog(@"%@",[error localizedDescription]);
        }
    }
    
    return self;
}

// デモユーザーではないユーザーの数を返す
- (NSInteger)getCountStoreUsers
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    NSInteger count = 0;
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    NSString* userIDBase = [defaluts objectForKey:@"userIDBase"];
    NSInteger minUserID = [userIDBase intValue] * USER_ID_BASE_DIGHT;
    NSInteger maxUserID = minUserID + USER_ID_BASE_DIGHT;
    
    NSLog(@"min:%d max:%d", minUserID, maxUserID);
    // SELECT文の作成
    NSString *selectsql
    = @"SELECT COUNT(user_id) FROM mst_user WHERE user_id >= ? and user_id < ?";
    FMResultSet *results = [db executeQuery:selectsql, [NSNumber numberWithInteger:minUserID], [NSNumber numberWithInteger:maxUserID]];
    if( [results next] )
    {
        count = [[results stringForColumnIndex:0] integerValue];
    }
    [db close];
    
    return (count);
}
// デモユーザーのユーザーIDをすべて返す。
- (NSArray *)getDemoUserIds
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    NSMutableArray *user_ids = [NSMutableArray array];
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    NSString* userIDBase = [defaluts objectForKey:@"userIDBase"];
    NSInteger minUserID = [userIDBase intValue] * USER_ID_BASE_DIGHT;
    NSInteger maxUserID = minUserID + USER_ID_BASE_DIGHT;
    
    NSLog(@"min:%d max:%d", minUserID, maxUserID);
    // SELECT文の作成
    NSString *selectsql
    = @"SELECT user_id FROM mst_user WHERE user_id < ? or user_id >= ?";
    FMResultSet *results = [db executeQuery:selectsql, [NSNumber numberWithInteger:minUserID], [NSNumber numberWithInteger:maxUserID]];
    while ([results next] )
    {
        [user_ids addObject:[NSNumber numberWithInt: [results intForColumn:@"user_id"]]];
    }
    [db close];
    
    return user_ids;
}
- (NSArray *)getDemoPictures
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    NSString* userIDBase = [defaluts objectForKey:@"userIDBase"];
    NSInteger minUserID = [userIDBase intValue] * USER_ID_BASE_DIGHT;
    NSInteger maxUserID = minUserID + USER_ID_BASE_DIGHT;
    // hist_user_work検索
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT picture_url"];
    [sql appendString:@"  FROM hist_user_work  "];
    [sql appendString:@"  INNER JOIN fc_user_picture ON hist_user_work.hist_id = fc_user_picture.hist_id "];
    [sql appendString:@"  WHERE hist_user_work.user_id < ? or hist_user_work.user_id >= ?"];
    FMResultSet *results = [db executeQuery:sql, [NSNumber numberWithInteger:minUserID], [NSNumber numberWithInteger:maxUserID]];
    
    NSMutableArray *pics = [NSMutableArray array];
    while( [results next] ) {
        NSString *picture_path = [results stringForColumn:@"picture_url"];
        [pics addObject:picture_path];
    }
    return pics;
}

- (NSArray *)getDemoVideos
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    NSString* userIDBase = [defaluts objectForKey:@"userIDBase"];
    NSInteger minUserID = [userIDBase intValue] * USER_ID_BASE_DIGHT;
    NSInteger maxUserID = minUserID + USER_ID_BASE_DIGHT;
    // hist_user_work検索
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT video_url"];
    [sql appendString:@"  FROM hist_user_work  "];
    [sql appendString:@"  INNER JOIN fc_user_video ON hist_user_work.hist_id = fc_user_video.hist_id "];
    [sql appendString:@"  WHERE hist_user_work.user_id < ? or hist_user_work.user_id >= ?"];
    FMResultSet *results = [db executeQuery:sql, [NSNumber numberWithInteger:minUserID], [NSNumber numberWithInteger:maxUserID]];
    
    NSMutableArray *videos = [NSMutableArray array];
    while( [results next] ) {
        NSString *video_path = [results stringForColumn:@"video_url"];
        [videos addObject:video_path];
    }
    return videos;
}
- (BOOL)mergeDB:(NSString *)otherDbPath
{
    FMDatabase *db1 = [FMDatabase databaseWithPath:otherDbPath];
    if(![db1 open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    
    FMDatabase *db2 = [FMDatabase databaseWithPath:dbPath];
    if(![db2 open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    [db2 beginTransaction];
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    NSString* userIDBase = [defaluts objectForKey:@"userIDBase"];
    NSInteger minUserID = [userIDBase intValue] * USER_ID_BASE_DIGHT;
    NSInteger maxUserID = minUserID + USER_ID_BASE_DIGHT;
    
    NSLog(@"min:%d max:%d", minUserID, maxUserID);
    // 既存DBのデモユーザに関する情報全削除
    //// mst_user削除
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"DELETE FROM mst_user where  user_id < ? or user_id >= ?"];
    BOOL result = [db2 executeUpdate:sql, [NSNumber numberWithInteger:minUserID], [NSNumber numberWithInteger:maxUserID]];
    if(!result)
    {
        NSLog(@"delete mst_user error");
        [db2 rollback];
        return NO;
    }
    // hist_user_work検索
    sql = [NSMutableString string];
    [sql appendString:@"SELECT hist_id"];
    [sql appendString:@"  FROM hist_user_work  "];
    [sql appendString:@"  WHERE user_id < ? or user_id >= ?"];
    FMResultSet *results = [db2 executeQuery:sql, [NSNumber numberWithInteger:minUserID], [NSNumber numberWithInteger:maxUserID]];
    
    NSMutableArray *hist_ids = [NSMutableArray array];
    while( [results next] ) {
        [hist_ids addObject:[NSNumber numberWithInt:[results intForColumn:@"hist_id"]]];
    }
    // hist_user_work配下削除
    for (NSNumber *hist_id in hist_ids) {
        sql = [NSMutableString string];
        [sql appendFormat:@"DELETE FROM hist_user_work WHERE hist_id = ?"];
        result = [db2 executeUpdate:sql, hist_id];
        if(!result)
        {
            NSLog(@"delete hist_user_work error");
            [db2 rollback];
            return NO;
        }
        
        sql = [NSMutableString string];
        [sql appendFormat:@"DELETE FROM fc_user_work_item WHERE hist_id = ?"];
        result = [db2 executeUpdate:sql, hist_id];
        if(!result)
        {
            NSLog(@"delete fc_user_work_item error");
            [db2 rollback];
            return NO;
        }
        sql = [NSMutableString string];
        [sql appendFormat:@"DELETE FROM fc_user_work_item2 WHERE hist_id = ?"];
        result = [db2 executeUpdate:sql, hist_id];
        if(!result)
        {
            NSLog(@"delete fc_user_work_item2 error");
            [db2 rollback];
            return NO;
        }
        sql = [NSMutableString string];
        [sql appendFormat:@"DELETE FROM fc_user_memo WHERE hist_id = ?"];
        result = [db2 executeUpdate:sql, hist_id];
        if(!result)
        {
            NSLog(@"delete fc_user_memo error");
            [db2 rollback];
            return NO;
        }
        sql = [NSMutableString string];
        [sql appendFormat:@"DELETE FROM fc_user_picture WHERE hist_id = ?"];
        result = [db2 executeUpdate:sql, hist_id];
        if(!result)
        {
            NSLog(@"delete fc_user_picture error");
            [db2 rollback];
            return NO;
        }
        sql = [NSMutableString string];
        [sql appendFormat:@"DELETE FROM fc_user_video WHERE hist_id = ?"];
        result = [db2 executeUpdate:sql, hist_id];
        if(!result)
        {
            NSLog(@"delete fc_user_video error");
            [db2 rollback];
            return NO;
        }
    }
    // 新DBにより既存DB更新
    // SELECT文の作成
    sql = [NSMutableString string];
    [sql appendString:@"SELECT "];
    [sql appendString:@"  first_name, second_name, "];
    [sql appendString:@"  first_name_kana, second_name_kana, regist_number, sex, "];
    [sql appendString:@"  picture_url, syumi, email1, email2, memo, bload_type, "];
    [sql appendString:@"  date(birthday) as birth, user_id, "];
    [sql appendString:@"  shop_id "];
    [sql appendString:@"FROM mst_user "];
    [sql appendString:@"WHERE user_id < ? or user_id >= ?"];
    
    results = [db1 executeQuery:sql, [NSNumber numberWithInteger:minUserID], [NSNumber numberWithInteger:maxUserID]];
    
    NSMutableArray *users = [NSMutableArray array];
    while( [results next] )
    {
        mstUser *user = [[mstUser alloc] init];
        user.userID = [results intForColumn:@"user_id"];
        user.firstName = [results stringForColumn:@"first_name"];
        user.secondName = [results stringForColumn:@"second_name"];
        user.firstNameCana = [results stringForColumn:@"first_name_kana"];
        user.secondNameCana = [results stringForColumn:@"second_name_kana"];
        user.registNumber = [results intForColumn:@"regist_number"];
        user.sex = [results intForColumn:@"sex"];
        user.pictuerURL = [results stringForColumn:@"picture_url"];
        user.syumi = [results stringForColumn:@"syumi"];
        user.email1 = [results stringForColumn:@"email1"];
        user.email2 = [results stringForColumn:@"email2"];
        user.memo = [results stringForColumn:@"memo"];
        user.bloadType = [results intForColumn:@"bload_type"];
        user.birthDay = [Common convertDate2Sqlite:[results stringForColumn:@"birth"]];
        user.shopID = [results intForColumn:@"shop_id"];
        [users addObject:user];
    }
    // ユーザー情報の挿入・更新
    // INSERT OR UPDATE
    for (mstUser *user in users) {
        sql = [NSMutableString string];
        [sql appendString:@"INSERT OR REPLACE INTO mst_user( "];
        [sql appendString:@"  user_id, first_name, second_name, first_name_kana, second_name_kana, "];
        [sql appendString:@"  regist_number, sex, picture_url, syumi, "];
        [sql appendString:@"  email1, email2, memo, bload_type, "];
        [sql appendString:@"  birthday, "];
        [sql appendString:@"  shop_id "];
        [sql appendString:@") "];
        [sql appendString:@"VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, julianday(date(?)), ?)"];
        
        BOOL result = [db2 executeUpdate:sql,
                       [NSNumber numberWithInteger:user.userID],
                       user.firstName, user.secondName, user.firstNameCana, user.secondNameCana,
                       [NSNumber numberWithInt:user.registNumber],
                       [NSNumber numberWithInt:user.sex],
                       user.pictuerURL, user.syumi,
                       user.email1, user.email2, user.memo,
                       [NSNumber numberWithInt:user.bloadType],
                       [self makeDateStringByNSDate:user.birthDay],
                       [NSNumber numberWithInt:user.shopID]
                       ];
        if(!result)
        {
            NSLog(@"insert or update user error");
            [db2 rollback];
            return NO;
        }
    }
    // 施術内容の更新
    sql = [NSMutableString string];
    [sql appendString:@"SELECT hist_Id, user_id, work_date, head_picture_url "];
    [sql appendString:@"  FROM hist_user_work  "];
    [sql appendString:@"  WHERE user_id < ? or user_id >= ?"];
    
    results = [db1 executeQuery:sql, [NSNumber numberWithInteger:minUserID], [NSNumber numberWithInteger:maxUserID]];
    
    NSMutableArray *hists = [NSMutableArray array];
    while( [results next] ) {
        [hists addObject:@{
                           @"hist_id": [NSNumber numberWithInt:[results intForColumn:@"hist_id"]],
                           @"user_id": [NSNumber numberWithInt:[results intForColumn:@"user_id"]],
                           @"work_date": [NSNumber numberWithDouble:[results doubleForColumn:@"work_date"]],
                           @"head_picture_url": [results stringForColumn:@"head_picture_url"]
                           }];
    }
    for (NSDictionary *hist in hists) {
        // 施術履歴を作成・更新
        NSMutableString *sql = [NSMutableString string];
        [sql appendString:@"INSERT OR REPLACE INTO hist_user_work (hist_id, user_id, work_date, head_picture_url) "];
        [sql appendString:@"  VALUES(?, ?, ?, ?)"];
        
        BOOL result = [db2 executeUpdate:sql, hist[@"hist_id"], hist[@"user_id"], hist[@"work_date"], hist[@"head_picture_url"]];
        if(!result)
        {
            NSLog(@"insert or update hist error");
            [db2 rollback];
            return NO;
        }
        // 施術履歴の詳細を更新
        // fc_user_work_itemの移行
        sql = [NSMutableString string];
        [sql appendString:@"SELECT hist_id, work_item_id, user_id, item_name, order_num, work_date "];
        [sql appendString:@"  FROM fc_user_work_item  "];
        [sql appendString:@"  WHERE hist_id = ?"];
        
        results = [db1 executeQuery:sql, hist[@"hist_id"]];
        
        NSMutableArray *items = [NSMutableArray array];
        while( [results next] ) {
            sql = [NSMutableString string];
            [sql appendString:@"INSERT INTO fc_user_work_item (hist_id, user_id, work_item_id, item_name, order_num, work_date) "];
            [sql appendString:@"  VALUES(?, ?, ?, ?, ?, ?)"];
            result = [db2 executeUpdate:sql,
                      [results objectForColumnName:@"hist_id"],
                      [results objectForColumnName:@"user_id"],
                      [results objectForColumnName:@"work_item_id"],
                      [results objectForColumnName:@"item_name"],
                      [results objectForColumnName:@"order_num"],
                      [results objectForColumnName:@"work_date"]
                      ];
            if(!result)
            {
                NSLog(@"insert fc_user_work_item error");
                [db2 rollback];
                return NO;
            }
        }
        // fc_user_work_item2の移行
        sql = [NSMutableString string];
        [sql appendString:@"SELECT hist_id, work_item_id, create_date, item_name, order_num"];
        [sql appendString:@"  FROM fc_user_work_item2  "];
        [sql appendString:@"  WHERE hist_id = ?"];
        
        results = [db1 executeQuery:sql, hist[@"hist_id"]];
        
        items = [NSMutableArray array];
        while( [results next] ) {
            
            sql = [NSMutableString string];
            [sql appendString:@"INSERT INTO fc_user_work_item2 (hist_id, work_item_id, create_date, item_name, order_num) "];
            [sql appendString:@"  VALUES(?, ?, ?, ?, ?)"];
            result = [db2 executeUpdate:sql,
                      [results objectForColumnName:@"hist_id"],
                      [results objectForColumnName:@"work_item_id"],
                      [results objectForColumnName:@"create_date"],
                      [results objectForColumnName:@"item_name"],
                      [results objectForColumnName:@"order_num"]
                      ];
            if(!result)
            {
                NSLog(@"insert fc_user_work_item2 error");
                [db2 rollback];
                return NO;
            }
        }
        
        // fc_user_memoの移行
        sql = [NSMutableString string];
        [sql appendString:@"SELECT hist_id, memo"];
        [sql appendString:@"  FROM fc_user_memo "];
        [sql appendString:@"  WHERE hist_id = ?"];
        
        results = [db1 executeQuery:sql, hist[@"hist_id"]];
        
        while( [results next] ) {
            sql = [NSMutableString string];
            [sql appendString:@"INSERT INTO fc_user_memo (hist_id, memo) "];
            [sql appendString:@"  VALUES(?, ?)"];
            result = [db2 executeUpdate:sql,
                      [results objectForColumnName:@"hist_id"],
                      [results objectForColumnName:@"memo"]];
            if(!result)
            {
                NSLog(@"insert fc_user_memo error");
                [db2 rollback];
                return NO;
            }
        }
        
        // fc_user_pictureの移行
        sql = [NSMutableString string];
        [sql appendString:@"SELECT hist_id, picture_url, pictuer_title, pictuer_comment"];
        [sql appendString:@"  FROM fc_user_picture "];
        [sql appendString:@"  WHERE hist_id = ?"];
        
        results = [db1 executeQuery:sql, hist[@"hist_id"]];
        
        while( [results next] ) {
            sql = [NSMutableString string];
            [sql appendString:@"INSERT INTO fc_user_picture (hist_id, picture_url, pictuer_title, pictuer_comment) "];
            [sql appendString:@"  VALUES(?, ?, ?, ?)"];
            
            result = [db2 executeUpdate:sql,
                      [results objectForColumnName:@"hist_id"],
                      [results objectForColumnName:@"picture_url"],
                      [results objectForColumnName:@"pictuer_title"],
                      [results objectForColumnName:@"pictuer_comment"]];
            if(!result)
            {
                NSLog(@"insert fc_user_picture error");
                [db2 rollback];
                return NO;
            }
        }
        // fc_user_videoの移行
        sql = [NSMutableString string];
        [sql appendString:@"SELECT hist_id, video_url, video_title, video_comment, status, overlay"];
        [sql appendString:@"  FROM fc_user_video "];
        [sql appendString:@"  WHERE hist_id = ?"];
        
        results = [db1 executeQuery:sql, hist[@"hist_id"]];
        
        while( [results next] ) {
            sql = [NSMutableString string];
            [sql appendString:@"INSERT INTO fc_user_video (hist_id, video_url, video_title, video_comment, status, overlay) "];
            [sql appendString:@"  VALUES(?, ?, ?, ?, ?, ?)"]; // error
            result = [db2 executeUpdate:sql,
                      [results objectForColumnName:@"hist_id"],
                      [results objectForColumnName:@"video_url"],
                      [results objectForColumnName:@"video_title"],
                      [results objectForColumnName:@"video_comment"],
                      [results objectForColumnName:@"status"],
                      [results objectForColumnName:@"overlay"]
                      ];
            if(!result)
            {
                NSLog(@"insert fc_user_video error");
                [db2 rollback];
                return NO;
            }
        }
    }
    [db2 commit];
    [db1 close];
    [db2 close];
    return YES;
}
- (NSString*) makeDateStringByNSDate:(NSDate*)date
{
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    return ( [fmt stringFromDate:date] );
}
@end
