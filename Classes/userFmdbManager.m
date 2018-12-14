//
//  userFmdbManager.m
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/13.
//
//

#import "userFmdbManager.h"

/*
 ** DEFINE
 */
#define ACCOUNT_ID_SAVE_KEY		@"accountIDSave"		// アカウントIDの保存用Key
#define FMDB_FILE_NAME			@"cameraApp_FMDB.db"

@implementation userFmdbManager

- (id)init
{
	self = [super init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //データベースのパス取得
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:FMDB_FILE_NAME];
	BOOL success = [fileManager fileExistsAtPath:dbPath];
    //無ければコピー
    if(!success){
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:FMDB_FILE_NAME];
        NSError *error = nil;
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        if(!success){
            NSLog(@"%@",[error localizedDescription]);
        }
    }
    
	return self;
}

//データベース初期化
- (BOOL)initDataBase
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //データベース存在チェック
    //メールタイトルテーブルの存在チェック
    //テーブルが無ければ生成する
    NSString *createTableSql = @"CREATE TABLE IF NOT EXISTS mst_mail_title('title_id' INTEGER PRIMARY KEY AUTOINCREMENT, 'title' TEXT);";
    result = [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
    
    //メール本文テーブルの存在チェック
    //テーブルが無ければ生成する
    createTableSql = @"CREATE TABLE IF NOT EXISTS fc_user_mail_item('smtp_id' INTEGER, 'title_id' INTEGER, 'fix_text1' TEXT , 'fix_text2' TEXT , 'fix_text3' TEXT , 'free_text' TEXT);";
    result =  [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
    //smtp設定テーブル
    //テーブルが無ければ生成する
    createTableSql = @"CREATE TABLE IF NOT EXISTS mst_user_mail_item('smtp_id' INTEGER PRIMARY KEY AUTOINCREMENT, 'sender_addr' TEXT, 'smtp_server' TEXT, 'smtp_user' TEXT, 'smtp_pass' TEXT, 'smtp_port' INTEGER, 'smtp_auth' INTEGER);";
    result =  [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
    // ユーザ　テーブル
    createTableSql = @"CREATE TABLE IF NOT EXISTS web_mail_user('id' INTEGER PRIMARY KEY, 'until' INTEGER)";
    result =  [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
    // メール　テーブル
    createTableSql = @"CREATE TABLE IF NOT EXISTS web_mail('id' INTEGER PRIMARY KEY, 'user_id' INTEGER,'title' TEXT, 'body' TEXT,'sender' TEXT, 'from_user' BOOL, 'unread' BOOL, 'checked' BOOL, 'user_unread' BOOL, 'server_created_at' INTEGER, 'created_at' INTEGER, 'error_mail' INTEGER);";
    result =  [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
	// メール　テーブル（旧バージョンでの使用を想定してカラムの確認をしておく）
	if ( [db columnExists:@"error_mail" inTableWithName:@"web_mail"] != YES )
	{
		// なければカラムを作成しておく
		createTableSql = @"ALTER TABLE web_mail ADD COLUMN error_mail INTEGER";
		result =  [db executeUpdate:createTableSql];
		if(!result)
		{
			NSLog(@"DB CREATE TABLE ERROR");
			[db close];
			return FALSE;
		}
	}
    // メール内画像
    createTableSql = @"CREATE TABLE IF NOT EXISTS web_mail_picture('id' INTEGER PRIMARY KEY AUTOINCREMENT, 'picture_url' TEXT,'mail_id' INTEGER, UNIQUE('picture_url','mail_id'));";
    result =  [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
	// 送信エラー履歴テーブル
	createTableSql = @"CREATE TABLE IF NOT EXISTS web_mail_error('error_id' INTEGER PRIMARY KEY AUTOINCREMENT, 'mail_title' TEXT, 'send_count' INTEGER, 'error_count' INTEGER);";
    result =  [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
	// ユーザー別送信エラー数
	createTableSql = @"CREATE TABLE IF NOT EXISTS web_mail_error_user('id' INTEGER PRIMARY KEY AUTOINCREMENT, 'user_id' INTEGER, 'error_count' INTEGER);";
    result =  [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
	// ユーザー別受信拒否状態テーブル
	createTableSql = @"CREATE TABLE IF NOT EXISTS web_mail_block_user('id' INTEGER PRIMARY KEY AUTOINCREMENT, 'user_id' INTEGER UNIQUE, 'block_state' BOOLEAN );";
    result =  [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
    [db close];
    return TRUE;
}
//データベースにコネクションする
+ (FMDatabase*) databaseConect:(NSString*)dbPath
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    
    return db;
}
- (FMDatabase *) databaseConnect{
    return [userFmdbManager databaseConect:dbPath];
}
//メール本文テーブルにメール情報を追加
- (BOOL)insertMail:(WebMail *)mail WithDb:(FMDatabase *)db
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];

    BOOL result = FALSE;
    //追加処理
    NSString *insertSql = @"INSERT OR REPLACE INTO web_mail(id, user_id, title, body, sender,from_user, unread, checked, user_unread, server_created_at, created_at, error_mail) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ? ,? ,?, ?)";
    result =  [db executeUpdate:insertSql,
               [NSNumber numberWithInteger:mail.mailId],
               [NSNumber numberWithInteger:mail.userID],
               mail.title,
               mail.content ,
               mail.from,
               [NSNumber numberWithBool:mail.fromUser],
               [NSNumber numberWithBool:mail.unread],
               [NSNumber numberWithBool:mail.check],
               [NSNumber numberWithBool:mail.userUnread] ,
               [NSNumber numberWithInteger:(NSInteger)[mail.sendDate timeIntervalSince1970]],
               [NSNumber numberWithInteger:(NSInteger)[[NSDate date] timeIntervalSince1970]],
			   [NSNumber numberWithInteger:mail.errorMail]
               ];
    if(!result)
    {
        NSLog(@"DB INSERT ERROR");
        //[db close];
        return FALSE;
    }
    for (NSString *pic in mail.pictures) {
        insertSql = @"INSERT OR REPLACE INTO web_mail_picture(picture_url, mail_id) VALUES(?, ?)";
		NSString* tmpPic = nil;
		if ( pic != nil )
		{
			NSArray* items = [pic componentsSeparatedByString:@"/"];
			NSInteger last = [items count];
			if ( last < 2 )
			{
				// 通常動作
				tmpPic = pic;
			}
			else
			{
				NSString* dir = [items objectAtIndex:1];
				if ( last == 3 && ([dir isEqualToString:@"common"] || [dir isEqualToString:@"Common"]) )
				{
					// 一斉送信の添付画像のみURLが違うのでディレクトリをいじる
					NSString* fileName = [items objectAtIndex:last - 1];
					tmpPic = [NSString stringWithFormat:@"Documents/Common/%@/%@", accID, fileName];
				}
				else
				{
					// 通常動作
					tmpPic = pic;
				}
			}
		}
        result = [db executeUpdate:insertSql,
                  tmpPic,
                  [NSNumber numberWithInteger:mail.mailId]];
        if(!result)
        {
            NSLog(@"DB INSERT ERROR");
            return FALSE;
        }
    }
    return TRUE;
}
// クライアントのあるユーザの情報の更新日時(unix time)をとる
-(NSInteger)selectUntilWithUserId:(USERID_INT)userId{
    NSInteger until = 0;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //取得クエリー文
    NSString *selectTableSql = [NSString stringWithFormat:@"SELECT until FROM web_mail_user WHERE id = ? LIMIT 1"];
    FMResultSet *results = [db executeQuery:selectTableSql, [NSNumber numberWithInteger:userId]];
    if( [results next] )
    {
        until = [[results stringForColumnIndex:0] integerValue];
    }
    [db close];
    return until;
}
- (BOOL)updateUntil:(NSInteger)until userId:(USERID_INT)userId db:(FMDatabase *)db {
    BOOL result = FALSE;

    NSString *insertSql = @"INSERT OR REPLACE INTO web_mail_user(id, until) VALUES(?, ?)";
    result =  [db executeUpdate:insertSql,
               [NSNumber numberWithInteger:userId],
               [NSNumber numberWithInteger:until]
               ];
    if(!result)
    {
        NSLog(@"DB INSERT ERROR");
        return FALSE;
    }
    return TRUE;
}
// あるユーザのある日時（unix time)以前のメールを取得する
- (NSArray *)selectMailsSince:(NSInteger)since userId:(USERID_INT)userId{
    NSMutableArray *mails = [NSMutableArray array];
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //取得クエリー文
    NSString *selectTableSql =
    [NSString stringWithFormat:
     @" SELECT id, user_id, title, body, sender, from_user, unread, "
     @"         checked, user_unread, server_created_at,created_at,error_mail "
     @" FROM   web_mail "
     @" WHERE  user_id = %d AND "
     @"        server_created_at <= %ld "
     @" ORDER BY server_created_at DESC LIMIT 11 ", //同じ秒数のものもとる
     userId, (long)since
     ];
#ifdef DEBUG
    NSLog(@"%@",selectTableSql);
#endif
    FMResultSet *results = [db executeQuery:selectTableSql];
    while ( [results next] )
    {
        WebMail *mail = [[WebMail alloc] init];
        mail.mailId     = [[results objectForColumnName:@"id"] integerValue];
        mail.userID     = (USERID_INT)[[results objectForColumnName:@"user_id"] integerValue];
        mail.title      = [results objectForColumnName:@"title"];
        mail.content    = [results objectForColumnName:@"body"];
        mail.from       = [results objectForColumnName:@"sender"];
        mail.fromUser   = [[results objectForColumnName:@"from_user"] boolValue];
        mail.unread     = [[results objectForColumnName:@"unread"] boolValue];
        mail.check      = [[results objectForColumnName:@"checked"] boolValue];
        mail.userUnread = [[results objectForColumnName:@"user_unread"] boolValue];
        mail.sendDate   = [NSDate dateWithTimeIntervalSince1970:[[results objectForColumnName:@"server_created_at"] integerValue]];
		NSObject* obj   = [results objectForColumnName:@"error_mail"];
		if ( [obj isKindOfClass:[NSNull class]] )
			mail.errorMail = 0;
		else if ( [obj isKindOfClass:[NSNumber class]] )
			mail.errorMail = [(NSNumber*)obj integerValue];

		[mails addObject:mail];
    }
    for (WebMail *mail in mails) {
        selectTableSql =
        [NSString stringWithFormat: @" SELECT picture_url FROM web_mail_picture WHERE  mail_id = %ld ", (long)mail.mailId ];
        results = [db executeQuery:selectTableSql];
        while ([results next]) {
            [mail.pictures addObject:[results objectForColumnIndex:0]];
        }
    }
    [db close];
    //タイトルの配列を返す
    return mails;
}
- (NSDictionary *)getStatuses{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return 0;
    }
    NSString *selectSql = @"SELECT user_id, SUM(unread) as sum_unread, SUM(user_unread) as sum_user_unread, SUM(checked) as sum_checked "
                          @"FROM web_mail GROUP BY user_id";
    FMResultSet *results = [db executeQuery:selectSql];
    while ([results next]) {
        WebMailUserStatus *status = [[WebMailUserStatus alloc] init];
        status.userId = [results intForColumn:@"user_id"];
        status.unread = [results intForColumn:@"sum_unread"];
        status.userUnread = [results intForColumn:@"sum_user_unread"];
        status.check = [results intForColumn:@"sum_checked"];
        [dic setObject:status forKey:[NSNumber numberWithInteger:status.userId]];
    }
    return dic;
}

- (WebMailUserStatus *)getStatus: (USERID_INT)userId{
    WebMailUserStatus *status = [[WebMailUserStatus alloc] init];
    status.userId = userId;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return 0;
    }
    NSString *selectSql = @"SELECT user_id, SUM(unread) as sum_unread, SUM(user_unread) as sum_user_unread, SUM(checked) as sum_checked "
    @"FROM web_mail WHERE user_id = ?";
    FMResultSet *results = [db executeQuery:selectSql, [NSNumber numberWithInteger:userId]];
    if ([results next]) {
        status.userId = [results intForColumn:@"user_id"];
        status.unread = [results intForColumn:@"sum_unread"];
        status.userUnread = [results intForColumn:@"sum_user_unread"];
        status.check = [results intForColumn:@"check"];
    }
    return status;
}
//メールタイトルテーブルにメールタイトルを追加
//戻り値は追加したタイトルのID
- (NSInteger)insertMailTitle:(NSString*)title
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return 0;
    }
    //個数チェック
    int count = 0;
    NSString *checkSql = @"select count(*) as count from mst_mail_title";
    FMResultSet *results =[db executeQuery:checkSql];
    if([results next])
    {
        count = [[results stringForColumn:@"count"] intValue];
    }
    if (count >= 5)
    {
        NSString *deleteSql = @"delete from mst_mail_title where not exists(select * from mst_mail_title as tb where mst_mail_title.title_id > tb.title_id)";
        result =  [db executeUpdate:deleteSql];
        if(!result)
        {
            NSLog(@"DB DELETE ERROR");
            [db close];
            return 0;
        }
    }
    
    //追加処理
    NSString* insertSql = @"INSERT INTO mst_mail_title (title) VALUES (?)";
    result = [db executeUpdate:insertSql, title];
    if(!result)
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return 0;
    }
    
    NSString *selectTableSql = [NSString stringWithFormat:@"SELECT title_id FROM mst_mail_title ORDER BY title_id DESC"];
    results = [db executeQuery:selectTableSql];
    
    NSInteger title_id = 0;
    while( [results next] )
    {
        title_id = [results intForColumnIndex:0];
        break;
        
    }
    
    [db close];
    return title_id;
}


//メール本文テーブルにメール情報を追加
- (BOOL)insertUserMail:(NSInteger)smtpId
               TitleID:(NSInteger)titleId
             MailHead1:(NSString*)mailHead1
             MailHead2:(NSString*)mailHead2
         MailSignature:(NSString*)mailSignature
              MailText:(NSString*)mailText
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //追加処理
    NSString *insertSql = @"INSERT OR REPLACE INTO fc_user_mail_item (smtp_id, title_id, fix_text1, fix_text2, fix_text3, free_text) VALUES (?, ?, ?, ?, ?, ?)";
    result =  [db executeUpdate:insertSql, [NSNumber numberWithInteger:smtpId], [NSNumber numberWithInteger:titleId], mailHead1, mailHead2, mailSignature, mailText];
    if(!result)
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    
    [db close];
    return TRUE;
}

//smtp設定テーブルに設定情報を追加
- (BOOL)insertMailSmtpInfo:(NSString*)sendarAddr
                SmtpServer:(NSString*)smtpServer
                  SmtpUser:(NSString*)smtpUser
                  SmtpPass:(NSString*)smtpPass
                  SmtpPort:(NSInteger)smtpPort
                  SmtpAuth:(NSInteger)smtpAuth
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //追加処理
    NSString *insertSql = @"INSERT INTO mst_user_mail_item(sender_addr, smtp_server, smtp_user, smtp_pass, smtp_port, smtp_auth)VALUES(?,?,?,?,?,?)";
    result =  [db executeUpdate:insertSql, sendarAddr, smtpServer, smtpUser, smtpPass, [NSNumber numberWithInteger:smtpPort], [NSNumber numberWithInteger:smtpAuth]];
//    NSString *sql = @"DELETE FROM mst_user_mail_item";
//    result =  [db executeUpdate:sql];
    if(!result)
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    
    [db close];
    return TRUE;
}
//smtp設定テーブルに設定情報を追加
- (BOOL)insertMailSmtpInfo:(NSString*)sendarAddr
                  SmtpUser:(NSString*)smtpUser
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //追加処理
    NSString *insertSql = @"INSERT INTO mst_user_mail_item(sender_addr, smtp_user)VALUES(?,?)";
    result =  [db executeUpdate:insertSql, sendarAddr, smtpUser];
    //    NSString *sql = @"DELETE FROM mst_user_mail_item";
    //    result =  [db executeUpdate:sql];
    if(!result)
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    
    [db close];
    return TRUE;
}

//smtp設定テーブルの設定情報を更新
- (BOOL)updateMailSmtpInfo:(NSString*)sendarAddr
                SmtpServer:(NSString*)smtpServer
                  SmtpUser:(NSString*)smtpUser
                  SmtpPass:(NSString*)smtpPass
                  SmtpPort:(NSInteger)smtpPort
                  SmtpAuth:(NSInteger)smtpAuth
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //追加処理
    NSString *insertSql = @"UPDATE mst_user_mail_item SET sender_addr = ?, smtp_server = ?, smtp_user = ?, smtp_pass = ?, smtp_port = ?, smtp_auth = ?";
    result =  [db executeUpdate:insertSql, sendarAddr, smtpServer, smtpUser, smtpPass, [NSNumber numberWithInteger:smtpPort], [NSNumber numberWithInteger:smtpAuth]];
//    NSString *sql = @"DELETE FROM mst_user_mail_item";
//    result =  [db executeUpdate:sql];
    if(!result)
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    
    [db close];
    return TRUE;
}
//smtp設定テーブルの設定情報を更新
- (BOOL)updateMailSmtpInfo:(NSString*)sendarAddr
                  SmtpUser:(NSString*)smtpUser
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //追加処理
    NSString *insertSql = @"UPDATE mst_user_mail_item SET sender_addr = ?,smtp_user = ?";
    result =  [db executeUpdate:insertSql, sendarAddr, smtpUser];
    if(!result)
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    
    [db close];
    return TRUE;
}

//メール本文テーブルのメール情報を更新
- (BOOL)updateUserMail:(NSInteger)smtpId
               TitleID:(NSInteger)titleId
             MailHead1:(NSString*)mailHead1
             MailHead2:(NSString*)mailHead2
         MailSignature:(NSString*)mailSignature
              MailText:(NSString*)mailText
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //追加処理
    NSString *insertSql = @"UPDATE fc_user_mail_item SET smtp_id = ?, title_id = ?, fix_text1 = ?, fix_text2 = ?, fix_text3 = ?, free_text = ?";
    result =  [db executeUpdate:insertSql, [NSNumber numberWithInteger:smtpId], [NSNumber numberWithInteger:titleId], mailHead1, mailHead2, mailSignature, mailText];
//    NSString *sql = @"DELETE FROM fc_user_mail_item";
//    result =  [db executeUpdate:sql];
    if(!result)
    {
        NSLog(@"DB UPDATE ERROR");
        [db close];
        return FALSE;
    }
    
    [db close];
    return TRUE;
}

//  メール受信拒否状態更新
- (BOOL)updateWebMailBlockUser:(USERID_INT) userId
                    BlockState:(bool) blockState
{
    BOOL result = FALSE;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return result;
    }
    //追加処理
    NSString *insertSql = @"REPLACE INTO web_mail_block_user(user_id,block_state) VALUES(?,?)";
    result =  [db executeUpdate:insertSql, [NSNumber numberWithInteger:userId], [NSNumber numberWithInteger:blockState] ];
    
    [db close];
    return result;
}

//登録されている全てのメールタイトルを取得
- (NSMutableArray*)selectAllMailTitle
{
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    //取得クエリー文
    NSString *selectTableSql = [NSString stringWithFormat:@"SELECT DISTINCT title FROM mst_mail_title ORDER BY title_id DESC"];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return NULL;
    }
    //タイトル格納行列
    NSMutableArray *titleArray = [NSMutableArray array];
    FMResultSet *results = [db executeQuery:selectTableSql];
    //データが存在するだけ繰り返す
    while( [results next] )
    {
        NSString *title = [results stringForColumnIndex:0];
        [titleArray addObject:title];
    }
    [db close];
    //タイトルの配列を返す
    return titleArray;
}

//特定のIDのメールタイトル取得
- (NSString*)selectMailTitle:(NSInteger)titleId
{
    NSString *title = @"";
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    NSString *selectTableSql
        = [NSString stringWithFormat:@"SELECT title FROM mst_mail_title WHERE title_id = %ld", (long)titleId];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return title;
    }
    FMResultSet *results = [db executeQuery:selectTableSql];
    while( [results next] )
    {
        title = [results stringForColumnIndex:0];
    }
    [db close];
    return title;
}

//該当するIDのsmtp設定情報を取得
- (NSMutableArray*)selectMailSmtpInfo:(NSInteger)smtpId
{
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    //取得クエリー文
    NSString *selectTableSql= [NSString stringWithFormat:@"SELECT sender_addr, smtp_server, smtp_user, smtp_pass, smtp_port, smtp_auth FROM mst_user_mail_item"];
    NSMutableArray *infoArray = [NSMutableArray array];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return infoArray;
    }
    FMResultSet *results = [db executeQuery:selectTableSql];
    //データが存在するだけ繰り返す
    while( [results next] )
    {
        mstUserMailItemBean *bean= [[mstUserMailItemBean alloc]init];
        //Beanにデータをセット
        bean.sender_addr = [results stringForColumnIndex:0];
        bean.smtp_server = [results stringForColumnIndex:1];
        bean.smtp_user = [results stringForColumnIndex:2];
        bean.smtp_pass = [results stringForColumnIndex:3];
        bean.smtp_port = [results intForColumnIndex:4];
        bean.smtp_auth = [results intForColumnIndex:5];
        //データを格納
        [infoArray addObject:bean];
    }
    
//    NSString *sql = @"DELETE FROM mst_user_mail_item";
//     BOOL result =  [db executeUpdate:sql];
    
    [db close];
    //配列を返す
    return infoArray;
}

//登録されているメール情報を取得
- (NSMutableArray*)selectUserMail
{
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    //取得クエリー文
    NSString *selectTableSql = [NSString stringWithFormat:@"SELECT * FROM fc_user_mail_item"];
    NSMutableArray *userMailArray = [NSMutableArray array];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return userMailArray;
    }
    FMResultSet *results = [db executeQuery:selectTableSql];
    //データが存在するだけ繰り返す
    while( [results next] )
    {
        fcUserMailItemBean *bean = [[fcUserMailItemBean alloc]init];;
        //Beanにデータをセット
        bean.smtp_id = [results intForColumnIndex:0];
        bean.title_id = [results intForColumnIndex:1];
        bean.fix_text1 = [results stringForColumnIndex:2];
        bean.fix_text2 = [results stringForColumnIndex:3];
        bean.fix_text3 = [results stringForColumnIndex:4];
        bean.free_text = [results stringForColumnIndex:5];
        
        //データを格納
        [userMailArray addObject:bean];
    }
    [db close];
    //配列を返す
    return userMailArray;
}

#pragma mark GetterWebMailFunction

// メールIDからメールタイトル取得
- (NSString*) selectMailTitleWhereMailId:(NSInteger)mailId;
{
    NSString *title = @"";
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    NSString *selectTableSql
        = [NSString stringWithFormat:@"SELECT title FROM web_mail WHERE id = %ld", (long)mailId];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return title;
    }
    FMResultSet *results = [db executeQuery:selectTableSql];
	if ( [results next] )
    {
        title = [results stringForColumnIndex:0];
    }
    [db close];
    return title;
}

- (NSInteger) selectMailDateWhereMailId:(NSInteger)mailId
{
	NSInteger nDate = 0;
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    NSString *selectTableSql
        = [NSString stringWithFormat:@"SELECT server_created_at FROM web_mail WHERE id = %ld", (long)mailId];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return nDate;
    }
    FMResultSet *results = [db executeQuery:selectTableSql];
	if ( [results next] )
    {
        nDate = [[results stringForColumnIndex:0] integerValue];
    }
    [db close];
	return nDate;
}

#pragma mark RemoveWebMailFunction

// 登録されているメール情報を削除
- (BOOL) removeUserMailInfo:(USERID_INT) userId
{
	// DBオープン
	FMDatabase* db = [userFmdbManager databaseConect:dbPath];
	if ( !db ) return NO;
	if ( ![db open] )
	{
		NSLog( @"DB OPEN ERROR" );
		return NO;
	}

	// DBからの削除
	BOOL bSuccess = YES;
	if ( bSuccess == YES )
		bSuccess = [self removeUserMailInfoInWebMailPicture:db UserID:userId];
	if ( bSuccess == YES )
		bSuccess = [self removeUserMailInfoInWebMail:db UserID:userId];
	if ( bSuccess == YES )
		bSuccess = [self removeUserMailInfoInWebMailUser:db UserID:userId];
	if ( bSuccess == NO )
	{
		NSLog( @"DB DELETE ERROR" );
		[db close];
		return NO;
	}

	// DBクローズ
	[db close];
	return YES;
}

/**
 web_mail_picturテーブルからユーザー情報を削除する
 @param fmDB	FMDB
 @param userId	ユーザーID
 @return YES:DBの削除に成功 NO:DBの削除に失敗
 */
- (BOOL) removeUserMailInfoInWebMailPicture:(FMDatabase*) fmDb
									 UserID:(USERID_INT) userId
{
	if ( fmDb == nil )
		return NO;
	
	// web_mailからmail_idを取得する
	NSMutableArray* mailIdArray = [NSMutableArray array];
	if ( mailIdArray == nil ) return NO;

	NSString* searchSql
        = [NSString stringWithFormat:@"SELECT id FROM web_mail WHERE user_id = %ld", (long)userId];
    FMResultSet *results = [fmDb executeQuery:searchSql];
	while ( [results next])
	{
		[mailIdArray addObject:[NSNumber numberWithInteger:[results intForColumnIndex:0]]];
	}
	
	// web_mail_pictureから指定したmail_idを削除する
	for (NSNumber* num in mailIdArray)
	{
		USERID_INT mail_id = [num intValue];
		[self removeUserMailInfoInTable:fmDb TableName:@"web_mail_picture" ColumnName:@"mail_id" UserID:mail_id];
	}

	return YES;
}

/**
 web_mailテーブルからユーザー情報を削除する
 @param fmDB	FMDB
 @param userId	ユーザーID
 @return YES:DBの削除に成功 NO:DBの削除に失敗
 */
- (BOOL) removeUserMailInfoInWebMail:(FMDatabase*) fmDb
							  UserID:(USERID_INT) userId
{
	return [self removeUserMailInfoInTable:fmDb TableName:@"web_mail" ColumnName:@"user_id" UserID:userId];
}

/**
 web_mail_userテーブルからユーザー情報を削除する
 @param fmDB	FMDB
 @param userId	ユーザーID
 @return YES:DBの削除に成功 NO:DBの削除に失敗
 */
- (BOOL) removeUserMailInfoInWebMailUser:(FMDatabase*) fmDb
								  UserID:(USERID_INT) userId
{
	return [self removeUserMailInfoInTable:fmDb TableName:@"web_mail_user" ColumnName:@"id" UserID:userId];
}

/**
 指定したテーブルからユーザーIDの情報を削除する
 @param fmDb			FMDB
 @param tableString		テーブル名
 @param columnString	コラム名
 @param userId			ユーザーID
 @return YES:DBの削除に成功 NO:DBの削除に失敗
 */
- (BOOL) removeUserMailInfoInTable:(FMDatabase*) fmDb
						 TableName:(NSString*) tableString
						ColumnName:(NSString*) columnString
							UserID:(USERID_INT) userId
{
	if ( fmDb == nil )
		return NO;

	// SQL文作成
	NSString* delSql
        = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %d", tableString, columnString, userId];
	
	// 指定テーブルの指定カラムからデータを削除する
	BOOL bResult = [fmDb executeUpdate:delSql];
	if ( bResult == NO )
	{
		NSLog(@"DELETE Error");
		return NO;
	}
	return YES;
}

// 指定メールを削除する
- (BOOL) removeWebMailWhereMailId:(NSInteger) mailId
{
	// DBオープン
	FMDatabase* db = [userFmdbManager databaseConect:dbPath];
	if ( !db ) return NO;
	if ( ![db open] )
	{
		NSLog( @"DB OPEN ERROR" );
		return NO;
	}

	// DBからメールを削除
	BOOL bRet = [self removeUserMailInfoInTable:db TableName:@"web_mail" ColumnName:@"id" UserID:(USERID_INT)mailId];
	if ( bRet == NO )
	{
		NSLog( @"DB DELETE ERROR" );
	}
	
	// DBクローズ
	[db close];
	return bRet;
}

/**
 送信エラーの履歴をDBに追加する
 */
- (BOOL) insertWebMailErrorWithTitle:(NSString *)title SendCount:(NSInteger)sendCount ErrorCount:(NSInteger)errorCount
{
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }

	/*
	 INSERT OR REPLACE INTO web_mail_error VALUES ( NULL, ?, ?, ? )
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"INSERT OR REPLACE INTO web_mail_error "];
	[sqlCmd appendString:@"VALUES ( NULL, ?, ?, ? );"];
    BOOL result =  [db executeUpdate:sqlCmd, title, [NSNumber numberWithInteger:sendCount], [NSNumber numberWithInteger:errorCount]];
    if( !result )
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    [db close];

	return YES;
}

/**
 送信エラーの履歴をDBから全て削除する
 */
- (BOOL) removeAllWebMailError
{
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }

	/*
	 DELETE FROM web_mail_error
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"DELETE FROM web_mail_error"];
    BOOL result =  [db executeUpdate:sqlCmd];
    if( !result )
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    [db close];
	return YES;
}

/**
 送信メールのエラー情報を取得する
 */
- (NSArray*) getWebMailError
{
	// DB OPEN
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }

	NSMutableArray* arrayError = [[[NSMutableArray alloc] init] autorelease];

	/*
	 SELECT mail_title, send_count, error_count FROM web_mail_error
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT mail_title, send_count, error_count FROM web_mail_error"];
	FMResultSet *results = [db executeQuery:sqlCmd];
	while ( [results next] )
	{
		NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
        [array addObject:[results stringForColumnIndex:0]];
		[array addObject:[NSNumber numberWithInt:[[results stringForColumnIndex:1] intValue]]];
		[array addObject:[NSNumber numberWithInt:[[results stringForColumnIndex:2] intValue]]];
		[arrayError addObject:array];
	}

    [db close];
	return arrayError;
}

/**
 指定ユーザーの送信メールのエラー数を増加させる
 */
- (BOOL) insertWebMailErrorCountWithUserID:(USERID_INT)userID Error:(NSInteger)error
{
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
	
	/*
	 INSERT OR REPLACE INTO web_mail_error_user VALUES ( NULL, ?, ? )
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"INSERT OR REPLACE INTO web_mail_error_user "];
	[sqlCmd appendString:@"VALUES ( NULL, ?, ? );"];
    BOOL result =  [db executeUpdate:sqlCmd, [NSNumber numberWithInteger:userID], [NSNumber numberWithInteger:error]];
    if( !result )
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    [db close];
	
	return YES;
}

/**
 指定ユーザーの送信メールのエラー数を削除する
 */
- (BOOL) removeWebMailErrorCountWithUserID:(USERID_INT)userID
{
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
	
	/*
	 DELETE FROM web_mail_error_user WHERE user_id = userID
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"DELETE FROM web_mail_error_user WHERE user_id = ?"];
    BOOL result =  [db executeUpdate:sqlCmd, [NSNumber numberWithInteger:userID]];
    if( !result )
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    [db close];
	return YES;
	
}

/**
 送信メールのエラー数を全て削除する
 */
- (BOOL) removeAllWebMailErrorUsers
{
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
	
	/*
	 DELETE FROM web_mail_error_user
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"DELETE FROM web_mail_error_user"];
    BOOL result =  [db executeUpdate:sqlCmd];
    if( !result )
    {
        NSLog(@"DB INSERT ERROR");
        [db close];
        return FALSE;
    }
    [db close];
	return YES;
}

/**
 指定ユーザーの送信メールのエラー数を取得する
 */
- (NSInteger) getWebMailErrorCountByUserID:(USERID_INT)userId
{
	// DB OPEN
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }

	NSInteger count = 0;

	/*
	 SELECT error_count FROM web_mail_error WHERE user_id = userId
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT error_count FROM web_mail_error_user WHERE user_id = ?"];
	FMResultSet *results = [db executeQuery:sqlCmd, [NSNumber numberWithInteger:userId]];
	while ( [results next] )
	{
		// エラー数をカウントする
		count += [[results stringForColumnIndex:0] integerValue];
	}

	// DB CLOSE
	[db close];
	return count;
}

/**
 指定ユーザーの送信メール数を取得する
 */
- (NSInteger) getSendWebMailCounts:(USERID_INT)userId
{
	// DB OPEN
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }
	
	NSInteger count = 0;

	/*
	 SELECT COUNT(*) FROM web_mail WHERE user_id = ?
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT COUNT(*) FROM web_mail WHERE user_id = ?"];
	FMResultSet *results = [db executeQuery:sqlCmd, [NSNumber numberWithInteger:userId]];
	while ( [results next] )
	{
		// エラー数をカウントする
		count += [[results stringForColumnIndex:0] integerValue];
	}
	
	// DB CLOSE
	[db close];
	return count;
}

/**
 指定ユーザーがあるかどうか
 */
- (BOOL) isWebMailUser:(USERID_INT)userId
{
	// DB OPEN
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }
	
	NSInteger count = 0;
	
	/*
	 SELECT COUNT(*) FROM web_mail_user WHERE id = ?
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT COUNT(*) FROM web_mail_user WHERE id = ?"];
	FMResultSet *results = [db executeQuery:sqlCmd, [NSNumber numberWithInteger:userId]];
	while ( [results next] )
	{
		// 数をカウントする
		count += [[results stringForColumnIndex:0] integerValue];
	}
	
	// DB CLOSE
	[db close];
	return (count > 0) ? YES : NO;
}

/**
 端末のデータベースを参照して
 受信拒否ユーザーIDのリストを返す
 */
- (NSDictionary*) getWebMailBlockUserList
{
    NSMutableDictionary*    userList = [[NSMutableDictionary alloc] init];
 
    // DB OPEN
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }

    NSString*   sqlCmd = @"SELECT user_id FROM web_mail_block_user WHERE block_state = 1";
	FMResultSet *results = [db executeQuery:sqlCmd];
    
	while ( [results next] )
	{
        NSNumber* userId = [NSNumber numberWithInt:[[results stringForColumnIndex:0] intValue]];
        [userList setObject:userId forKey:[userId stringValue]];
	}
    
    // DB CLOSE
	[db close];
    
    if( [userList count] <= 0 )
    {
        return nil;
    }
    return userList;
}

/**
 端末のデータベースを参照して
 ユーザー受信拒否かどうかを返す。
 */
-(bool) isWebMailBlockUser:(USERID_INT) userId
{
    // DB OPEN
    FMDatabase *db = [userFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }
    
    NSString*   sqlCmd = @"SELECT block_state FROM web_mail_block_user WHERE user_id = ?";
	FMResultSet *results = [db executeQuery:sqlCmd, [NSNumber numberWithInteger:userId]];
    
	// DB CLOSE
	[db close];
    
    if( results == nil )
    {
        return false;
    }
    return ([results stringForColumnIndex:0] != 0);
}

@end
