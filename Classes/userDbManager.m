//
//  userDbManager.m
//  iPadCamera
//
//  Created by MacBook on 10/10/20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "defines.h"

#import "userDbManager.h"
#import "mstUser.h"
#import "Common.h"

#import "userInfo.h"
// 2016/6/24 TMS シークレットメモ対応
#import "SecretMemoInfo.h"
#import "fcUserWorkItem.h"
#import "TemplateInfoListManager.h"

#ifdef CLOUD_SYNC
#import "CloudSyncClientDatabaseUpdate.h"
#endif

#import "MovieResource.h" // TODO: libraryに移動予定 DELC SASAGE

/*
 ** DEFINE
 */
#define ACCOUNT_ID_SAVE_KEY		@"accountIDSave"		// アカウントIDの保存用Key
#define TEMPLATE_VERSION		1


@implementation userDbManager

#pragma mark initialize_open_etc

// 初期化（コンストラクタ）
- (id)init
{
	self = [super init];
	
	[self myInit];
	
	return self;
}

// データベースをOPENして初期化（コンストラクタ）
- (id)initWithDbOpen
{
	self = [super init];
	
	[self myInit];
	
	// データベースのOPEN
	if (! [self openDataBase])
	{
		[NSException raise:@"NSException" format:@"database open error!!"];
	}
	
	return self;
	
}

-(void)myInit
{
	// データベースの物理ファイルのフルパス
	NSArray *paths 
	= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:DB_FILE_NAME];
	
	//dbが存在しているかどうかの確認
	if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) 
	{
		// データベースをDocmentフォルダにコピー
		[self copyDataBase2DocDir];	
	}
	
	// データベースオブジェクトをここで初期化
	db = nil;
	
}

// データベースをDocmentフォルダにコピー
- (void)copyDataBase2DocDir
{
#ifdef APP_STORE_SAMPLE_DATA
	return;		// 但し、ライブラリレベルで空のDBを自動作成する
#endif
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError* error = nil;
	
	// データベースのオリジナルをバンドルから取得する
	NSString *tempPath 
        = [[[NSBundle mainBundle] resourcePath]
#ifndef CLOUD_SYNC
            stringByAppendingPathComponent:DB_FILE_NAME];
#else
            stringByAppendingPathComponent:DB_RESOURCE_FILE_NAME];
#endif
	NSLog(@" bundle file name %@", tempPath);
	
	// バンドルから取得したオリジナルを文書フォルダへコピーする
	if(! [manager copyItemAtPath:tempPath toPath:dbPath error:&error] )
	{
		NSLog(@" copy error %@", [error localizedDescription]);
	}
}


// データベースのクリア
- (void)clearDataBase
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError* error = nil;
	
	// 物理ファイルを削除
	[manager removeItemAtPath:dbPath error:&error];
	
 	if (error != nil)
	{
		NSLog(@" delete error %@", [error localizedDescription]);
		return;
	}
	
	// データベースをDocmentフォルダにコピー
	[self copyDataBase2DocDir];
}

// データベースのOPEN
- (BOOL)openDataBase
{
	// 既にOPEN済み
	if (db)
	{ return YES; }
	
	int ret;
	ret = sqlite3_open([dbPath UTF8String],&db);
	//正常終了
	if(ret == SQLITE_OK){
		return YES;
		//異常終了
	}else {
		NSLog (@"database open error -> code:%d ", ret);
		
		//エラーが発生してしまったので、クローズを行う
		sqlite3_close(db);
		db = nil;
		return NO;
	}
}

// データベースのCLOSE
- (void)closeDataBase
{
	@try 
	{
		if (db)
		{	
			sqlite3_close(db);
			// [db release];
			
		}
	}
	@catch (NSException * e) 
	{
		NSLog(@"close data base error -> %@",
			  e.reason);
	}
	@finally {
		db = nil;
	}
}

#pragma mark local_methods

// データベースエラーのLog表示
- (void)errDataBaseWriteLog
{
	if (! db)
	{	
		NSLog (@"database error no open");
		return;
	}
#ifdef DEBUG
	NSLog (@"database error -> code:%d  message:%@",
		   sqlite3_errcode(db), [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
#endif
}

// データベースエラーのalert表示
- (void)errDataBase
{
	// Log表示
	[self errDataBaseWriteLog];
	
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:[[[NSString alloc] initWithFormat:@"error:%d",sqlite3_errcode(db)]autorelease]
							  message:[[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil
							  ];
	[alertView show];
	[alertView release];	
}

// sqlite3_stmtよりNSStringのオブジェクトを生成
- (NSString*) makeSqliteStmt2String : (sqlite3_stmt*)sqlstmt index:(u_int)idx
{
	const unsigned char *colText = sqlite3_column_text(sqlstmt, idx);

	return ( (colText != NULL)?
 			([[NSString alloc] initWithUTF8String:(const char*)colText]):(@"") );
}

// openとcloseの単純なTemplate
- (id) _simpleOpenCloseTemplateWithArg:(id)argss procHandler:(id (^)(id args))handler 
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (nil); }
	}
	
	id ret = nil;
	
	@try 
	{
		// 実処理
		ret = handler(argss);	
	}
	@catch (NSException * e) 
	{
		NSLog(@"_simpleOpenCloseTemplate data base error -> %@",
			  e.reason);
		ret = nil;
	}
	
	//クローズ
	[self closeDataBase];
	
	return(ret);
}

// SELECT処理のTemplate
- (void) _selectSqlTemplateWithSql:(NSString*)selectsql 
					   bindHandler:(void (^)(sqlite3_stmt* sqlstmt)) hBind
				  iterationHandler:(BOOL (^)(sqlite3_stmt* sqlstmt)) hIterate
{
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド：呼び出し側で設定
		hBind(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// 列データの取得：呼び出し側で処理
			if (! hIterate(sqlstmt) )
			{	break; }
		}			
	}
	else 
	{
		// エラー表示
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
}

// 更新処理系のTemplate
- (BOOL) executeSqlTemplateWithSql:(NSString*)selectsql
                       bindHandler:(void (^)(sqlite3_stmt* sqlstmt)) hBind
{
    BOOL stat = YES;
    
    sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド：呼び出し側で設定
		hBind(sqlstmt);
		
        // SQLの実行
		stat =  (sqlite3_step(sqlstmt) == SQLITE_DONE);
	}
	else
	{
        stat = NO;
	}
    
    if (! stat)
    {
        // エラー表示
		[self errDataBaseWriteLog];
    }
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
    
    return (stat);
    
}

//　テーブルの行数を取得
- (NSUInteger) getTableRowsCount:(NSString*)tableName IDname:(NSString*)name
{
	// SQL statementの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendFormat:@"SELECT COUNT(%@) ", name];
	[selectsql appendFormat:@"  FROM %@ ", tableName];
	
	__block NSUInteger count = 0;
	
	// SELECTの実行
	[self _selectSqlTemplateWithSql:selectsql
						bindHandler: ^(sqlite3_stmt* sqlstmt)
						{
							// バインド変数なし
							return;
						}
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
						{
							count = sqlite3_column_int(sqlstmt, 0);
							
							// 一行しか取得しないのでYESでも同様
							return (NO);
						}
	 ];
	
	return (count);
}

// 施術内容の文字列一覧の設定
- (void) setWorkItemList:(fcUserWorkItem*)workItem
{
	/*
	 SELECT item_name 
		FROM fc_user_work_item 
	   WHERE hist_id=5
	   ORDER BY order_num 
	 */
	
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT item_name "];
	[selectsql appendString:@"    FROM fc_user_work_item "];
	[selectsql appendString:@"  WHERE hist_id=?"];
	[selectsql appendString:@"    ORDER BY order_num"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,
			[[NSString stringWithFormat:@"%d",workItem.histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			[workItem setWorkItemByString:
				[self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0]];
			/*[workItem.workItemListNumber addObject:
				[NSString stringWithFormat:@"%d", sqlite3_column_int(sqlstmt, 1)]];*/
		}			
	}
	else 
	{
		NSLog(@"setWorkItemList error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);	
}

// 施術内容2の文字列一覧の設定
- (void) setWorkItemList2:(fcUserWorkItem*)workItem
{
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT item_name "];
	[selectsql appendString:@"    FROM fc_user_work_item2 "];
	[selectsql appendString:@"  WHERE hist_id=?"];
	[selectsql appendString:@"    ORDER BY order_num"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d",workItem.histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			[workItem setWorkItemByString2:
			 [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0]];
			/*[workItem.workItemListNumber2 addObject:
			 [NSString stringWithFormat:@"%d", sqlite3_column_int(sqlstmt, 1)]];*/
		}			
	}
	else 
	{
		NSLog(@"setWorkItemList2 error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease ]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);	
}

// 写真リストの設定
- (void) setPictureUrls:(fcUserWorkItem*)workItem
{
	// ファイル名（写真の日付）の降順で取得する
	
	/*
	 SELECT picture_url
     FROM fc_user_picture WHERE hist_id = 1
     ORDER BY picture_url DESC
	 */
	
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT picture_url "];
	[selectsql appendString:@"  FROM fc_user_picture WHERE hist_id = ?"];
	[selectsql appendString:@"     ORDER BY picture_url DESC"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d",workItem.histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			[workItem.picturesUrls addObject:
			 [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0]];
		}
	}
	else
	{
		NSLog(@"setPictureUrls error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease ]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
}// 写真リストの設定
- (void) setVideoUrls:(fcUserWorkItem*)workItem
{
	// ファイル名（写真の日付）の降順で取得する
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT video_url "];
	[selectsql appendString:@"  FROM fc_user_video WHERE hist_id = ?"];
	[selectsql appendString:@"     ORDER BY video_url DESC"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d",workItem.histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			[workItem.videosUrls addObject:
			 [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0]];
		}
	}
	else
	{
		NSLog(@"setVideoUrls error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease ]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
}
-(NSArray *)getImageProfile:(NSString*)fileURL{
    
    NSMutableArray *result = [NSMutableArray array];
    // データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return nil; }
	}
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT pictuer_title ,pictuer_comment FROM fc_user_picture WHERE picture_url = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%@",fileURL] UTF8String],-1,SQLITE_TRANSIENT);
		
		if (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			NSString *colText = [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0];
            NSString *temp = [[NSString alloc]initWithString:colText];
            if(temp == nil){
                temp = @"";
            }
			[result addObject:temp];
            [temp release];
			temp = nil;
			colText = [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)1];
            temp = [[NSString alloc]initWithString:colText];
            if(temp == nil){
                temp = @"";
            }
			[result addObject:temp];
            [temp release];
			temp = nil;
			colText = nil;
		}else {
            NSString *temp = [[NSString alloc]initWithString:@""];
			[result addObject:temp];
            [result addObject:temp];
            [temp release];
        }
	}
	else 
	{
		NSLog(@"getImageProfile error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease ]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
    [self closeDataBase];
    return result;
}
-(NSArray *)getVideoProfile:(NSString*)fileURL{
    
    NSMutableArray *result = [NSMutableArray array];
    // データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return nil; }
	}
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT video_title ,video_comment FROM fc_user_video WHERE video_url = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%@",fileURL] UTF8String],-1,SQLITE_TRANSIENT);
		
		if (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
            NSString *temp = [[NSString alloc]initWithString:[self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0]];
            if(temp == nil){
                temp = @"";
            }
			[result addObject:temp];
            [temp release];
            temp = [[NSString alloc]initWithString:[self makeSqliteStmt2String:sqlstmt index:(NSUInteger)1]];
            if(temp == nil){
                temp = @"";
            }
			[result addObject:temp];
            [temp release];
		}else {
            NSString *temp = [[NSString alloc]initWithString:@""];
			[result addObject:temp];
            [result addObject:temp];
            [temp release];
        }
	}
	else
	{
		NSLog(@"getVideoProfile error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease ]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
    [self closeDataBase];
    return result;
}
-(BOOL)setImageProfile:(NSString*)title
                  memo:(NSString*)memo
               fileURL:(NSString*)fileURL
                histID:(HISTID_INT)histID{
    BOOL stat = NO;
    HISTID_INT tableID = histID;
    // データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}

	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//update文の作成
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE  fc_user_picture"]; 
	[updateSql appendString:@" SET pictuer_title = ?, pictuer_comment = ? "];
	[updateSql appendString:@" WHERE picture_url = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
        sqlite3_bind_text(sqlstmt,idx++,[title UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlstmt,idx++,[memo UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlstmt,idx++,[fileURL UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) == SQLITE_DONE)
		{
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
            NSLog(@"%d",tableID);
#ifdef CLOUD_SYNC
			if (![CloudSyncClientDatabaseUpdate editPictureWiithID:tableID
														pictureUrl:fileURL
													  pictureTitle:title
													 sqlite3Object:db] )
            {
                //異常終了(ROLLBACKして処理を終了)
                sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
                stat = NO;
            }
#endif

		}else{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			stat = NO;
        }
	}
    //sql文の解放
    sqlite3_finalize(sqlstmt);
    //dbをクローズ
    [self closeDataBase];
    return stat;
}
-(BOOL)setVideoProfile:(NSString*)title
                  memo:(NSString*)memo
               fileURL:(NSString*)fileURL
                histID:(HISTID_INT)histID{
    BOOL stat = NO;
    HISTID_INT tableID = histID;
    // データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
    
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//update文の作成
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE  fc_user_video"];
	[updateSql appendString:@" SET video_title = ?, video_comment = ? "];
	[updateSql appendString:@" WHERE video_url = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
        sqlite3_bind_text(sqlstmt,idx++,[title UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlstmt,idx++,[memo UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlstmt,idx++,[fileURL UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) == SQLITE_DONE)
		{
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
            NSLog(@"%d",tableID);
#ifdef CLOUD_SYNC
            if (![CloudSyncClientDatabaseUpdate editVideoWithID:tableID
                                                       videoUrl:fileURL
                                                  sqlite3Object:db])
            {
                //異常終了(ROLLBACKして処理を終了)
                sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
                stat = NO;
            }
#endif
            
		}else{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			stat = NO;
        }
	}
    //sql文の解放
    sqlite3_finalize(sqlstmt);
    //dbをクローズ
    [self closeDataBase];
    return stat;
}
// メモリストの設定
- (void)setUserMemos:(fcUserWorkItem*)workItem
{
	/*
	 SELECT memo FROM fc_user_memo WHERE hist_id = 1
	 */
	
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT memo FROM fc_user_memo WHERE hist_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d",workItem.histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			[workItem.userMemos addObject:
			 [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0]];
		}			
	}
	else 
	{
		NSLog(@"setUserMemos error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease ]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);	
}

// 該当ユーザの履歴一覧を取得する
- (NSMutableArray*) getHistIdListWithUserID:(USERID_INT)userID
{
	NSMutableArray *histIDs = nil;
	
	// select文の作成
	/*
	 SELECT hist_ID
	   FROM hist_user_work 
	     WHERE user_id = 1 
	 */
	
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT hist_ID "];
	[selectsql appendString:@"  FROM hist_user_work"];
	[selectsql appendString:@"    WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d", userID] UTF8String],-1,SQLITE_TRANSIENT);
		
		histIDs = [ [NSMutableArray alloc] init];
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			[histIDs addObject:[NSString stringWithFormat:@"%d",
								sqlite3_column_int(sqlstmt, (NSUInteger)0)] ];
		}			
	}
	else 
	{
		NSLog(@"getHistIdListWithUserID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);	
	
	
	return (histIDs);
}

// 該当ユーザの最新施術日を取得
- (NSString*)getMaxNewWorkDateWithUserID:(USERID_INT)userID
{
	NSString *maxDate;
	
	/*
	 SELECT date(MAX(work_date))
	   FROM hist_user_work
	     WHERE user_id = 12
	 */
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT date(MAX(work_date)) "];
	[selectsql appendString:@"  FROM hist_user_work "];
	[selectsql appendString:@"    WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d", userID] UTF8String],-1,SQLITE_TRANSIENT);
		if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			maxDate = [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0];
		}			
		else {
			maxDate = @"";
		}

	}
	else 
	{
		NSLog(@"getMaxNewWorkDateWithUserID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease ]);
		maxDate = @"";
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);	
	
	
	return (maxDate);
}

// 該当ユーザの初回施術日を取得
- (NSString*)getFirstWorkDateWithUserID:(USERID_INT)userID
{
	NSString *firstDate;
	
	/*
	 SELECT date(MAX(work_date))
	 FROM hist_user_work
	 WHERE user_id = 12
	 */
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT date(MIN(work_date)) "];
	[selectsql appendString:@"  FROM hist_user_work "];
	[selectsql appendString:@"    WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d", userID] UTF8String],-1,SQLITE_TRANSIENT);
		if (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			firstDate = [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0];
		}
		else {
			firstDate = @"";
		}
		
	}
	else
	{
		NSLog(@"getFirstWorkDateWithUserID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease ]);
		firstDate = @"";
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	
	return (firstDate);
}

// 列が存在しない場合は追加する
- (BOOL) addColumnWithTable:(NSString*)tableName 
				 columnName:(NSString*)colName columnType:(NSString*)type
{
	BOOL stat = NO;
	
	// テーブル更新のSQLの作成:ALTER TABLEはバインド変数が使用できない
	/* ALTER TABLE test_table ADD new_col_1 interger */
	NSString *alterSql 
		= [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@", 
			tableName, colName, type];
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [alterSql UTF8String], -1, &sqlstmt, NULL)
			== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		//sql文を実行
		int result = sqlite3_step(sqlstmt);
		stat = (result == SQLITE_DONE);
	}
	/*else {
		rollback, エラーログ表示は呼び出し元で行う
	}*/

	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return(stat);
}

// 文字列のバインド：空文字が設定されていればdbNullを設定する
- (void) setBindTextWithString:(NSString*)setValue 
					pStatement:(sqlite3_stmt*)stmt setPositon:(NSUInteger)pos
{
	if ( (setValue) && ([setValue length] > 0) )
	{
		// 文字列が設定されている
		sqlite3_bind_text(stmt, (u_int)pos, [setValue UTF8String], -1, SQLITE_TRANSIENT);
	}
	else 
	{
		// 空文字の場合、dbNullを設定
		sqlite3_bind_null(stmt, (u_int)pos);
	}

}

// 項目編集種別よりテーブル名を取得
- (NSString*) getTableNameWithItemEditKind:(ITEM_EDIT_KIND)editKind
{
	NSString *tableName =nil;
	
	switch (editKind) {
		case ITEM_EDIT_USER_WORK1:
			tableName = ITEM_EDIT_USER_WORK1_TABLE;
			break;
		case ITEM_EDIT_USER_WORK2:
			tableName = ITEM_EDIT_USER_WORK2_TABLE;
			break;
		case ITEM_EDIT_PICTUE_NAME:
			tableName = ITEM_EDIT_PICTUE_NAME_TABLE;
			break;
		case ITEM_EDIT_DATE:;
		case ITEM_EDIT_GENERAL1:;
		case ITEM_EDIT_GENERAL2:;
		case ITEM_EDIT_GENERAL3:;
			tableName = ITEM_EDIT_GEN_FIELD_ITEM_TABLE;
			break;
			
		default:
			break;
	}
	
	return (tableName);
}

// 項目編集種別より状態テーブル名を取得
- (NSString*) getFcTableNameWithItemEditKind:(ITEM_EDIT_KIND)editKind
{
	NSString *tableName =nil;
	
	switch (editKind) {
		case ITEM_EDIT_USER_WORK1:
			tableName = ITEM_EDIT_USER_WORK1_FC_TABLE;
			break;
		case ITEM_EDIT_USER_WORK2:
			tableName = ITEM_EDIT_USER_WORK2_FC_TABLE;
			break;
		case ITEM_EDIT_PICTUE_NAME:
			tableName = ITEM_EDIT_PICTUE_NAME_FC_TABLE;
			break;
		default:
			break;
	}
	
	return (tableName);
}

// 項目マスタテーブルよりitemを取得 : key -> itemID   value -> itemName
- (NSDictionary*) getItems2TableWithEditKind:(ITEM_EDIT_KIND)editKind
{
	NSMutableDictionary *mstItemsDict= nil;
	
	// 項目種別に応じてマスタを取得
	switch (editKind) {
		case ITEM_EDIT_USER_WORK1:
			mstItemsDict = [self getWorkItemTable:ITEM_EDIT_USER_WORK1_TABLE];
			break;
		case ITEM_EDIT_USER_WORK2:
			mstItemsDict = [self getWorkItemTable:ITEM_EDIT_USER_WORK2_TABLE];
			break;
		case ITEM_EDIT_DATE:
        case ITEM_EDIT_GENERAL1:
        case ITEM_EDIT_GENERAL2:
        case ITEM_EDIT_GENERAL3:
            mstItemsDict = nil;
            break;
		default:
			break;
	}
	
	return (mstItemsDict);
}

// ユーザの姓と名の重複チェックを行う
- (BOOL) isExistUserWith1stName:(NSString*)firstName secondName:(NSString*)sndName
{
    /*
     SELECT user_id FROM mst_user 
        WHERE first_name = 'テスト2' AND second_name = 'ユーザ2'
     */
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT user_id FROM mst_user "];
    [sql appendString:@"  WHERE first_name = ? AND second_name = ?"];
    
    __block BOOL isExist = NO;
    
    [self _selectSqlTemplateWithSql:sql 
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
         NSUInteger idx = 1;
         [self setBindTextWithString:firstName pStatement:sqlstmt setPositon:idx++];
         [self setBindTextWithString:sndName pStatement:sqlstmt setPositon:idx++];
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         isExist = YES;
         
         // 存在確認ができたので、継続不要
         return (NO);
     }
     ];

    return (isExist);
}

// ユーザIDの重複チェックを行う
- (BOOL) isExistUserWithID:(USERID_INT)userID
{    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT user_id FROM mst_user "];
    [sql appendString:@"  WHERE user_id = ?"];
    
    __block BOOL isExist = NO;
    
    [self _selectSqlTemplateWithSql:sql 
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
         u_int idx = 1;
         sqlite3_bind_int(sqlstmt, idx++, userID);
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         isExist = YES;
         
         // 存在確認ができたので、継続不要
         return (NO);
     }
     ];
    
    return (isExist);
}

// 履歴代表写真のurl(Documentフォルダ以下)より履歴IDを取得する
- (HISTID_INT) getHistIDByPictURL:(NSString*)headPictUrl
{
    __block HISTID_INT hID = 0;
	// 拡張子を除くurlで確認する
	NSString *noSuffix = [headPictUrl substringToIndex:[headPictUrl length] - 3];
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT hist_id FROM hist_user_work "];
    [sql appendString:@"    WHERE head_picture_url"];
	//LIKEにバインド変数は使用できない
	[sql appendFormat:@" LIKE '%@%%'", noSuffix];
    
    [self _selectSqlTemplateWithSql:sql 
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
//         NSUInteger idx = 1;
//         [self setBindTextWithString:noSuffix pStatement:sqlstmt setPositon:idx++];
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         hID = sqlite3_column_int(sqlstmt, 0);
         
         // 存在確認ができたので、継続不要
         return (NO);
     }
     ];
    
    return  (hID);
}

// 写真のurl(Documentフォルダ以下)より履歴IDを取得する
- (HISTID_INT) getHistIDByPictURL4PictTable:(NSString*)pictUrl
{
    __block HISTID_INT hID = 0;
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT hist_id FROM fc_user_picture "];
    [sql appendString:@"    WHERE picture_url = ?"];
    
    [self _selectSqlTemplateWithSql:sql 
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
         NSUInteger idx = 1;
         [self setBindTextWithString:pictUrl pStatement:sqlstmt setPositon:idx++];
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         hID = sqlite3_column_int(sqlstmt, 0);
         
         // 存在確認ができたので、継続不要
         return (NO);
     }
     ];
    
    return  (hID);
}

// 動画のurl(Documentフォルダ以下)より履歴IDを取得する
- (HISTID_INT) getHistIDByVideoURL4PictTable:(NSString*)pictUrl
{
    __block HISTID_INT hID = 0;
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT hist_id FROM fc_user_video "];
    [sql appendString:@"    WHERE video_url = ?"];
    
    [self _selectSqlTemplateWithSql:sql
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
         NSUInteger idx = 1;
         [self setBindTextWithString:pictUrl pStatement:sqlstmt setPositon:idx++];
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         hID = sqlite3_column_int(sqlstmt, 0);
         
         // 存在確認ができたので、継続不要
         return (NO);
     }
     ];
    
    return  (hID);
}

// お客様代表写真のurl(パスなし)よりユーザIDと姓、名を取得する
- (USERID_INT) getUserIDByPictURL:(NSString*)headPictUrl
                       pFirstName:(NSString**)fName
                      pSecondName:(NSString**)sName
{
    __block USERID_INT uID = 0;
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT user_id, first_name, second_name FROM mst_user "];
    [sql appendString:@"  WHERE picture_url = ?"];
    
    [self _selectSqlTemplateWithSql:sql 
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
         NSUInteger idx = 1;
         [self setBindTextWithString:headPictUrl pStatement:sqlstmt setPositon:idx++];
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         u_int idx = 0;
         uID = sqlite3_column_int(sqlstmt, idx++);
         *fName = [self makeSqliteStmt2String:sqlstmt index:idx++];
         *sName = [self makeSqliteStmt2String:sqlstmt index:idx++];
         
         // 存在確認ができたので、継続不要
         return (NO);
     }
     ];
    
    return  (uID);
}

// ユーザIDより姓と名を取得する
- (BOOL) getFirstSecondNameWithUserID:(USERID_INT)uid getBuffer:(NSMutableDictionary*)buffer
{
    __block BOOL stat = NO;
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT first_name, second_name FROM mst_user"];
    [sql appendString:@"  WHERE user_id = ?"];
    
    [self _selectSqlTemplateWithSql:sql 
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
         sqlite3_bind_int(sqlstmt, 1, uid);
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         u_int idx = 0;
         NSString *firstName = [self makeSqliteStmt2String:sqlstmt index:idx++];
         NSString *secondName = [self makeSqliteStmt2String:sqlstmt index:idx++]; 
         [buffer setObject:firstName forKey:@"first_name"];
         [buffer setObject:secondName forKey:@"second_name"];
         
         stat = YES;
         
         // 存在確認ができたので、継続不要
         return (NO);
     }
     ];
    
    return  (stat);
}

// 履歴IDよりユーザIDと更新日付を取得する
- (BOOL) getUserIDWorkDateWithHistID:(HISTID_INT)hID getBuffer:(NSMutableDictionary*)buffer
{
    __block BOOL stat = NO;
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT user_id, DATE(work_date) FROM hist_user_work"];
    [sql appendString:@"  WHERE hist_id = ?"];
    
    [self _selectSqlTemplateWithSql:sql 
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
         sqlite3_bind_int(sqlstmt, 1, hID);
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         u_int idx = 0;
         NSString *userID = [self makeSqliteStmt2String:sqlstmt index:idx++];
         NSString *workDate = [self makeSqliteStmt2String:sqlstmt index:idx++]; 
         [buffer setObject:userID forKey:@"user_id"];
         [buffer setObject:workDate forKey:@"work_date"];

         
         stat = YES;
         
         // 存在確認ができたので、継続不要
         return (NO);
     }
     ];
    
    if (!stat)
    {   return (stat); }
    
    stat = NO;
    NSMutableArray *delPicts = [NSMutableArray array];
    
    NSMutableString *sql2 = [NSMutableString string];
    [sql2 appendString:@"SELECT picture_url FROM fc_user_picture"];
    [sql2 appendString:@"  WHERE hist_id = ?"];
    
    [self _selectSqlTemplateWithSql:sql2
                        bindHandler: ^(sqlite3_stmt* sqlstmt)
     {
         sqlite3_bind_int(sqlstmt, 1, hID);
     }
				   iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
     {
         u_int idx = 0;
         NSString *docPath = [self makeSqliteStmt2String:sqlstmt index:idx++];
         
         if ([docPath length] <= 0)
         {  return (YES); }
         
         [delPicts addObject:[docPath lastPathComponent]];
         
         return (YES);
     }
     ];
    
    [buffer setObject:delPicts forKey:@"delete_pictrues"];
    stat = YES;
    
    return  (stat);
}

#ifdef CLOUD_SYNC

// 店舗IDより店舗名を取得
- (NSString*) _getShopNameWithID:(NSInteger)shopID
{
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT shop_name FROM mst_shop"];
    [sql appendString:@"  WHERE shop_id = ?"];
    
    __block NSString *shopName = nil;
    
    [self _selectSqlTemplateWithSql:sql 
                         bindHandler:^(sqlite3_stmt* sqlstmt)
     {  
         sqlite3_bind_int(sqlstmt, 1, (int)shopID);
     }
                    iterationHandler:^(sqlite3_stmt* sqlstmt)
     {
         u_int idx = 0;
         shopName = [self makeSqliteStmt2String:sqlstmt index:idx++];
         return (YES);
     }
     ];
    
    return (shopName);
}
#endif

#pragma mark public_methods

// トランザクション付きでデータベースをOPENする
- (BOOL) dataBaseOpen4Transaction
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	return (YES);
}

// トランザクションを完了しデータベースをCLOSEする
- (void) dataBaseClose2TransactionWithState:(BOOL)isTrue
{
	// 正常終了
	if (isTrue)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
#ifdef DEBUG
		NSLog(@"ROLLBACK %s", __func__);
#endif
	}

	//クローズ
	[self closeDataBase];
}

// 新規ユーザの登録 : 戻り値：新しいuserID (負数でエラー）
- (USERID_INT)registNewUser:(mstUser*)newUser
{
	NSInteger stat;
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (-1); }
	}
	sqlite3_busy_timeout(db, 500);
	
    /*
    // ユーザの姓と名の重複チェックを行う
    BOOL isDuplicate 
        = [self isExistUserWith1stName:newUser.firstName secondName:newUser.secondName];
    if (isDuplicate)
    {   return DUPLICATE_USER_NAME_ID; }
    */
    
    //現在DBの最大ID取得
    USERID_INT nowMaxID = 0;
//    nowMaxID = [self getMaxUserID];
    if(nowMaxID < 0){
        NSLog(@"database error");
        return (-1);
    };

    //新規ユーザーのID作成
    USERID_INT userID = -1;
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    NSString* userIDBase = [defaluts objectForKey:@"userIDBase"];
	USERID_INT maxUserID = (USERID_INT)[defaluts integerForKey:@"maxUserID"];
    userID = (nowMaxID + 1)+([userIDBase intValue] * USER_ID_BASE_DIGHT);

    //念のため重複確認
    BOOL IDDuplicate = YES;
    while (IDDuplicate) {
        if ([self isExistUserWithID:userID]){
            userID++;
        }else {
			if (maxUserID < userID){
				IDDuplicate = NO;
			}else{
				userID++;
			}
			
        } 
    }
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//insert文の作成
	/*
	 INSERT INTO mst_user 
	    (first_name, second_name, first_name_kana, second_name_kana, regist_number, sex)
	 VALUES
		('片山', '強',　'かたやま','つよし', 123456, 1);
	 */
	
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"INSERT INTO mst_user "];
	[inssql appendString:@"   (user_id,first_name, second_name, mid_name, "];
	[inssql appendString:@"    first_name_kana, second_name_kana, regist_number, "];
	[inssql appendString:@"    postal, adr1, adr2, adr3, adr4, tel, mobile, "];
	[inssql appendString:@"    sex, bload_type, syumi, email1, email2, memo, responsible"];
	if (newUser.birthDay)
	{	[inssql appendString:@", birthday"]; }
#ifdef CLOUD_SYNC
    [inssql appendString:@", shop_id "];
#endif
	[inssql appendString:@") "];
	
	[inssql appendString:@"VALUES"];
	[inssql appendString:@"   (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?"];		// ? = バインド変数:18個
	if (newUser.birthDay)
	{	[inssql appendString:@",julianday(date(?)) "]; }
#ifdef CLOUD_SYNC
    [inssql appendString:@",? "];
#endif
	[inssql appendString:@") "];

#ifdef DEBUG
	NSLog(@"%@", inssql);
#endif
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
			== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
        sqlite3_bind_int(sqlstmt, idx++, userID);
		// 姓と名（かな含む）の設定：空文字の場合は、dbNullを設定する
		[self setBindTextWithString:newUser.firstName pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.secondName pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.middleName pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.firstNameCana pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.secondNameCana pStatement:sqlstmt setPositon:idx++];
		if (newUser.registNumber != REGIST_NUMBER_INVALID)
		{	sqlite3_bind_int(sqlstmt, idx++, (int)newUser.registNumber);}
		else 
		{	sqlite3_bind_null(sqlstmt, idx++);}		// お客様番号の無効値はdbNullで設定する
		[self setBindTextWithString:newUser.postal pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.adr1 pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.adr2 pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.adr3 pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.adr4 pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.tel pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:newUser.mobile pStatement:sqlstmt setPositon:idx++];
		sqlite3_bind_text(sqlstmt,idx++,
			[[NSString stringWithString:(newUser.sex != Men)? @"0" : @"1"] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%d", newUser.bloadType] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,[newUser.syumi UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlstmt,idx++,[newUser.email1 UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlstmt,idx++,[newUser.email2 UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,[newUser.memo UTF8String],-1,SQLITE_TRANSIENT);
		// 2016/8/12 TMS 顧客情報に担当者を追加
		sqlite3_bind_text(sqlstmt,idx++,[newUser.responsible UTF8String],-1,SQLITE_TRANSIENT);
		if (newUser.birthDay)
		{
			sqlite3_bind_text(sqlstmt,idx++,
							  [[self makeDateStringByNSDate:newUser.birthDay] UTF8String],-1,SQLITE_TRANSIENT);
		}
#ifdef CLOUD_SYNC
        sqlite3_bind_int(sqlstmt, idx++, (int)newUser.shopID);
#endif
        
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			// userIDは無効とする
			newUser.userID = -1;
			
			return (-1);
		}

		if (userID >= 0){
#ifdef CLOUD_SYNC
            
            // fc_update_mng_time_delete.key_value may not be NULL のため、いずれかの値を設定
            NSString *keyVal = ((newUser.firstName) && ([newUser.firstName length] > 0))?
                newUser.firstName : [NSString stringWithFormat:@"%ld", (long)newUser.registNumber];
            
            if ([CloudSyncClientDatabaseUpdate newUserMakeWithID:userID
                                                       firstName:keyVal
                                                      secondName:newUser.secondName
                                                   sqlite3Object:db] )
            {
                //正常終了(COMMITをして処理を終了)
                stat = sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
				//ユーザーIDの最大値を保存
				[defaluts setInteger:userID forKey:@"maxUserID"];
				[defaluts synchronize];
            }
            else
            {
                //異常終了(ROLLBACKして処理を終了)
                sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
                
                // userIDは無効とする
                newUser.userID = -1;
                userID = -1;
            }
			if(stat==SQLITE_BUSY) {
				for(int i=0 ; i<5 && stat==SQLITE_BUSY ; i++) {
					usleep(200000);
					stat = sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
					NSLog(@"AfterResult1[%d][%s]", i, sqlite3_errmsg(db));
				}
			}
#else
            //正常終了(COMMITをして処理を終了)
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
			
			//ユーザーIDの最大値を保存
			[defaluts setInteger:userID forKey:@"maxUserID"];
			[defaluts synchronize];
#endif
		}
		else 
		{
			//エラーメソッドをコール
			[self errDataBase];
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		}
		
		// ユーザIDを設定する
		newUser.userID = userID;

	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
		userID = -1;
		
		// userIDは無効とする
		newUser.userID = -1;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	NSLog(@"NEW USER ID : %d",userID);
	return (userID);
}

// 最大のuser_idを取得する
- (USERID_INT)getMaxUserID
{
	USERID_INT userID = -1;
	
	// SELECT文の作成
	NSString *selectsql 
        = @"SELECT MAX(user_id_def) FROM (SELECT user_id % ? AS user_id_def FROM mst_user)";
		
	sqlite3_stmt* sqlstmt;
	
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK){   
        sqlite3_clear_bindings(sqlstmt);
        sqlite3_bind_int(sqlstmt, 1,USER_ID_BASE_DIGHT);

		if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			userID = sqlite3_column_int(sqlstmt, 0);
		}
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (userID);
}

//最後に挿入したuser_idを取得する
-(NSInteger)getLastInsertRowId{
    USERID_INT userID = -1;
    NSString *selectsql 
        = @"SELECT user_id FROM mst_user WHERE ROWID = last_insert_rowid()";
    sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
        if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			userID = sqlite3_column_int(sqlstmt, 0);
		}
	}
    NSLog(@"result user_id : %d",userID);
    return userID;
}

// ユーザ一覧の全取得
- (NSMutableArray*)getAllUsers
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
    NSMutableArray *users = [NSMutableArray array];
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (nil); }
	}
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT "];
	[selectsql appendString:@"first_name, second_name, mid_name, "];
	[selectsql appendString:@"first_name_kana, second_name_kana, regist_number, sex, "];
	[selectsql appendString:@"picture_url, syumi, email1, email2, memo, bload_type, "];
	[selectsql appendString:@"date(birthday), date(last_work_date), user_id"];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", mst_shop.shop_name, mst_user.shop_id"];
#endif
	[selectsql appendString:@"  FROM mst_user "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@"    LEFT OUTER JOIN mst_shop"];
    [selectsql appendString:@"       ON mst_user.shop_id = mst_shop.shop_id "];
#endif
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			u_int idx = 0;
			
			// 取得したrowからユーザオブジェクトの基本部分を生成
			mstUser *user = [[mstUser alloc] initWithNewUser:
                    [self makeSqliteStmt2String:sqlstmt index:idx++]
                                         secondName:[self makeSqliteStmt2String:sqlstmt index:idx++]
										 middleName:[self makeSqliteStmt2String:sqlstmt index:idx++]
                                      firstNameCana:[self makeSqliteStmt2String:sqlstmt index:idx++]
                                     secondNameCana:[self makeSqliteStmt2String:sqlstmt index:idx++]
                                       registNumber:[self makeSqliteStmt2String:sqlstmt index:idx++]
                                                sex:(sqlite3_column_int(sqlstmt, idx++) == 0)? Lady : Men
					];
            
			// 残りのメンバを設定する
			user.pictuerURL = [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.syumi = [self makeSqliteStmt2String:sqlstmt index:idx++];
            user.email1 = [self makeSqliteStmt2String:sqlstmt index:idx++];
            user.email2 = [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.memo = [self makeSqliteStmt2String:sqlstmt index:idx++];
			[user setBloadTypeByInt:sqlite3_column_int(sqlstmt, idx++)];
			[user setBirthDayByString:[self makeSqliteStmt2String:sqlstmt index:idx++]];
            user.userID = sqlite3_column_int(sqlstmt, ++idx);
#ifdef CLOUD_SYNC
            user.shopName = [self makeSqliteStmt2String:sqlstmt index:++idx];
            user.shopID = sqlite3_column_int(sqlstmt, ++idx);
#endif
            [users addObject:user];
			user.firstName = nil;
			user.secondName = nil;
			user.firstNameCana = nil;
			user.secondNameCana = nil;
			user.syumi = nil;
			user.email1 = nil;
			user.email2 = nil;
			user.memo = nil;
			[user release];
		}
	}
	else
	{
		NSLog(@"getMstUserByID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (users);
}

// 全ユーザ一のインデックス生成
- (NSMutableArray*)getJapaneseUserListIndex
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
	NSMutableArray *lists = [NSMutableArray array];
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (nil); }
	}
	
	// SQLステートメントの作成
	// SELECT distinct(substr(first_name_kana,1,1))
	//     FROM mst_user where first_name_kana not null order by first_name_kana
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT "];
	[selectsql appendString:@" DISTINCT(SUBSTR(first_name_kana,1,1))"];
	[selectsql appendString:@" FROM mst_user WHERE first_name_kana not NULL"];
	[selectsql appendString:@"  ORDER BY first_name_kana"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			// 取得したrowからユーザオブジェクトの基本部分を生成
			NSString *idx = [self makeSqliteStmt2String:sqlstmt index:0];
			[lists addObject:idx];
		}
	}
	else
	{
		NSLog(@"%s error at %@", __func__,
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (lists);
}

// 検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListBySearch:(NSString*) statement
{
	NSMutableArray* datas = [NSMutableArray array];
	// [datas autorelease];
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT  mst_user.user_id, first_name, second_name, regist_number, 
			 sex, picture_url, date(MAX(work_date))
	 FROM mst_user
	 INNER JOIN  fc_user_work_item
		ON mst_user.user_id = fc_user_work_item.user_id
	 WHERE fc_user_work_item.user_id = 1;
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT "];
	[selectsql appendString:@" mst_user.user_id, first_name, second_name, mid_name, regist_number, "];
	[selectsql appendString:@" sex, picture_url, date(last_work_date), date(birthday) "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", mst_shop.shop_name, mst_user.shop_id"];
#endif
	[selectsql appendString:@"  FROM mst_user "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@"    LEFT OUTER JOIN mst_shop"];
    [selectsql appendString:@"       ON mst_user.shop_id = mst_shop.shop_id "];
#endif
	
	
	// WHERE句の設定
	if ([statement length] > 0)
	{
		[selectsql appendString:@" WHERE "];
		[selectsql appendString:statement];
	}
#ifdef DEBUG
	NSLog(@"search userinfo sql state -> %@", selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			u_int idx = 0;
			
			USERID_INT userID = sqlite3_column_int(sqlstmt, idx++);
			
			// TODO: mst_userのlast_work_dateカラムに最新施術日を更新する必要が有る
			// 現状last_work_dateカラムが未使用のため、getMaxNewWorkDateWithUserIDで
			// 最新施術日を取得している。
			// last_work_dateから取得するようにすれば、表示の高速化ができる
			// 施術作成、削除時に更新するようにロジックを追加
			// また、現状未使用のため、最新施術日で更新するロジックの追加も必要
			// 該当ユーザの最新施術日を取得
			NSString *maxDate = [self getMaxNewWorkDateWithUserID:userID];
			
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc]
                initWithUserInfo: userID
				firstName:		[self makeSqliteStmt2String:sqlstmt index:idx++]
				secondName:		[self makeSqliteStmt2String:sqlstmt index:idx++]
				middleName:		[self makeSqliteStmt2String:sqlstmt index:idx++]
				registNumber:	[self makeSqliteStmt2String:sqlstmt index:idx++]
				sex:			sqlite3_column_int(sqlstmt, idx++)
				pictureURL:		[self makeSqliteStmt2String:sqlstmt index:idx++]
				lastWorkDate:	maxDate
				birthDay:       [self makeSqliteStmt2String:sqlstmt index:++idx]
								 
#ifdef CLOUD_SYNC
                shopName:       [self makeSqliteStmt2String:sqlstmt index:++idx]
#endif
			];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else 
	{
		NSLog(@"getUserInfoListBySearch error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}

	
	 
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

// 検索に該当するユーザ一数の取得
- (NSInteger)getUserInfoListCountBySearch:(NSString*) statement
{
	NSInteger num = 0;
	NSMutableArray* datas = [NSMutableArray array];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT count(*) FROM mst_user "];
	
	// WHERE句の設定
	if ([statement length] > 0)
	{
		[selectsql appendString:@" WHERE "];
		[selectsql appendString:statement];
	}
#ifdef DEBUG
	NSLog(@"search userinfo count sql state -> %@", selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		// SQL実行
		if ( sqlite3_step(sqlstmt) == SQLITE_ROW )
		{
			// カウントを取得
			num = sqlite3_column_int(sqlstmt, 0);
		}
	}
	else
	{
		NSLog(@"getUserInfoListCountBySearch error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (num);
}

// 日付検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListBySearchDate:(NSString*)searchDate optional:(NSString*) statement
{
	NSMutableArray* datas = [NSMutableArray array];
	// [datas autorelease];
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT  mst_user.user_id, first_name, second_name, regist_number, 
	    sex, picture_url, date(hist_user_work.work_date)
	     FROM mst_user
	 LEFT OUTER JOIN  hist_user_work
	   ON mst_user.user_id = hist_user_work.user_id
	 WHERE hist_user_work.work_date = julianday(date('2010-10-20'))
	*/
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  mst_user.user_id, first_name, second_name, mid_name, regist_number,"];
	[selectsql appendString:@"  sex, picture_url, date(hist_user_work.work_date), date(birthday) "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"    FROM mst_user "];
	[selectsql appendString:@"LEFT OUTER JOIN  hist_user_work"];
	[selectsql appendString:@"  ON mst_user.user_id = hist_user_work.user_id "];
	[selectsql appendString:@"WHERE hist_user_work.work_date = julianday(date(?))"];
	
	// WHERE句の設定
	if ([statement length] > 0)
	{
		[selectsql appendString:@" "];
		[selectsql appendString:statement];
	}
#ifdef DEBUG
	NSLog(@"search by birthday userinfo sql state -> %@", selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		// バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt, 1, [searchDate UTF8String], -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			u_int idx = 0;
			
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo:
								 sqlite3_column_int(sqlstmt, idx++)
								 firstName:[self makeSqliteStmt2String:sqlstmt index:idx++]
								secondName:[self makeSqliteStmt2String:sqlstmt index:idx++]
								middleName:[self makeSqliteStmt2String:sqlstmt index:idx++]
							  registNumber:[self makeSqliteStmt2String:sqlstmt index:idx++]
									   sex:sqlite3_column_int(sqlstmt, idx++)
								pictureURL:[self makeSqliteStmt2String:sqlstmt index:idx++]
							  lastWorkDate:[self makeSqliteStmt2String:sqlstmt index:idx++]
								 birthDay:[self makeSqliteStmt2String:sqlstmt index:idx++]
#ifdef CLOUD_SYNC
                                  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, idx++))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else 
	{
		NSLog(@"getUserInfoListBySearchDate error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

// 日付検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListBySearchStart:(NSString*)startDate EndDate:(NSString*)endDate optional:(NSString*) statement
{
	NSMutableArray* datas = [NSMutableArray array];
	// [datas autorelease];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT  mst_user.user_id, first_name, second_name, regist_number, sex, picture_url, date(hist_user_work.work_date), date(birthday), shop_id
	  FROM mst_user LEFT OUTER JOIN  hist_user_work 
	   ON mst_user.user_id = hist_user_work.user_id
	 WHERE  hist_user_work.work_date 
	  BETWEEN julianday(date('2014-03-01')) 
	   AND julianday(date('2014-03-31'))
	 GROUP BY mst_user.user_id
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  mst_user.user_id, first_name, second_name, mid_name, regist_number,"];
	[selectsql appendString:@"  sex, picture_url, date(hist_user_work.work_date), date(birthday) "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"    FROM mst_user "];
	[selectsql appendString:@"LEFT OUTER JOIN  hist_user_work"];
	[selectsql appendString:@"  ON mst_user.user_id = hist_user_work.user_id "];
	[selectsql appendString:@"WHERE hist_user_work.work_date"];
	[selectsql appendString:@" BETWEEN julianday(date(?))"];
	[selectsql appendString:@"  AND julianday(date(?))"];
	
	// WHERE句の設定
	if ([statement length] > 0)
	{
		[selectsql appendString:@" "];
		[selectsql appendString:statement];
	}
	// "group by", "order by" はwhere句の後に配置
	[selectsql appendString:@"   GROUP BY mst_user.user_id"];
	[selectsql appendString:@"    ORDER BY hist_user_work.work_date"];
#ifdef DEBUG
	NSLog(@"search by birthday userinfo sql state -> %@", selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		// バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt, 1, [startDate UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt, 2, [endDate UTF8String], -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo: sqlite3_column_int(sqlstmt, 0)
														 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
														secondName:[self makeSqliteStmt2String:sqlstmt index:2]
														middleName:[self makeSqliteStmt2String:sqlstmt index:3]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:4]
															   sex:sqlite3_column_int(sqlstmt, 5)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:6]
													  lastWorkDate:[self makeSqliteStmt2String:sqlstmt index:7]
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:8]
#ifdef CLOUD_SYNC
														  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, 9))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListBySearchDate error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

// メモ1検索に該当するユーザー一覧の取得
- (NSMutableArray*)getUserInfoListByWorkItemArray:(NSArray*)arrayMemo AndSearch:(BOOL)andSearch optional:(NSString*)addState
{
	NSMutableArray* datas = [NSMutableArray array];

	// 入力なし
	NSInteger memoCount = [arrayMemo count];
	if ( arrayMemo == nil || memoCount == 0 )
		return datas;

	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
			return (datas);
	}

	// 条件文の作成
	NSMutableString* strConditions = [[[NSMutableString alloc] init] autorelease];
	for ( NSInteger i = 0; i < memoCount; i++ )
	{
		// 文字列の追加(LIKEはバインド出来ない)
		[strConditions appendFormat:@"fc_user_work_item.item_name LIKE '%%%@%%' ", [arrayMemo objectAtIndex:i]];

		// 検索方法
		if ( i != (memoCount - 1) )
		{
			if ( andSearch )
				[strConditions appendString:@" AND "];
			else
				[strConditions appendString:@" OR "];
		}
	}
	
	/*
	 SELECT mst_user.user_id, first_name, second_name, regist_number, sex, picture_url, date(hist_user_work.work_date), date(birthday), shop_id FROM mst_user
	 LEFT OUTER JOIN (hist_user_work LEFT OUTER JOIN fc_user_work_item ON hist_user_work.hist_id = fc_user_work_item.hist_id)
	 ON mst_user.user_id = hist_user_work.user_id
	 WHERE fc_user_work_item.item_name = 'カラー'
	 GROUP BY mst_user.user_id 	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  mst_user.user_id, first_name, second_name, mid_name, regist_number,"];
	[selectsql appendString:@"  sex, picture_url, date(hist_user_work.work_date), date(birthday) "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"    FROM mst_user "];
	[selectsql appendString:@"LEFT OUTER JOIN hist_user_work ON mst_user.user_id = hist_user_work.user_id LEFT OUTER JOIN fc_user_work_item ON hist_user_work.hist_id = fc_user_work_item.hist_id"];
	[selectsql appendFormat:@"  WHERE %@", strConditions];
	
	// WHERE句の設定
	if ([addState length] > 0)
	{
		[selectsql appendString:@" "];
		[selectsql appendString:addState];
	}
	// group by は where句の後に配置する
	[selectsql appendString:@"   GROUP BY mst_user.user_id"];
	// 2016/1/18 TMS ストア・デモ版統合対応 ソート対応
	[selectsql appendString:@"   ORDER BY mst_user.first_name,mst_user.second_name"];

#ifdef DEBUG
	NSLog(@"%s sql state -> %@", __func__, selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo: sqlite3_column_int(sqlstmt, 0)
														 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
														secondName:[self makeSqliteStmt2String:sqlstmt index:2]
														middleName:[self makeSqliteStmt2String:sqlstmt index:3]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:4]
															   sex:sqlite3_column_int(sqlstmt, 5)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:6]
													  lastWorkDate:[self makeSqliteStmt2String:sqlstmt index:7]
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:8]
#ifdef CLOUD_SYNC
														  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, 9))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListByWorkItemArray error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];

	return datas;
}

// メモ2検索に該当するユーザー一覧の取得
- (NSMutableArray*)getUserInfoListByWorkItem2Array:(NSArray*)arrayMemo AndSearch:(BOOL)andSearch optional:(NSString*)addState
{
	NSMutableArray* datas = [NSMutableArray array];
	
	// 入力なし
	NSInteger memoCount = [arrayMemo count];
	if ( arrayMemo == nil || memoCount == 0 )
		return datas;
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
			return (datas);
	}
	
	// 条件文の作成
	NSMutableString* strConditions = [[[NSMutableString alloc] init] autorelease];
	for ( NSInteger i = 0; i < memoCount; i++ )
	{
		// 文字列の追加(LIKEはバインド出来ない)
		[strConditions appendFormat:@"fc_user_work_item2.item_name LIKE '%%%@%%' ", [arrayMemo objectAtIndex:i]];
		
		// 検索方法
		if ( i != (memoCount - 1) )
		{
			if ( andSearch )
				[strConditions appendString:@" AND "];
			else
				[strConditions appendString:@" OR "];
		}
	}
	
	/*
	 SELECT mst_user.user_id, first_name, second_name, regist_number, sex, picture_url, date(hist_user_work.work_date), date(birthday), shop_id FROM mst_user
	 LEFT OUTER JOIN (hist_user_work LEFT OUTER JOIN fc_user_work_item ON hist_user_work.hist_id = fc_user_work_item.hist_id)
	 ON mst_user.user_id = hist_user_work.user_id
	 WHERE fc_user_work_item.item_name = 'カラー'
	 GROUP BY mst_user.user_id 	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  mst_user.user_id, first_name, second_name, mid_name, regist_number,"];
	[selectsql appendString:@"  sex, picture_url, date(hist_user_work.work_date), date(birthday) "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"    FROM mst_user "];
	[selectsql appendString:@"LEFT OUTER JOIN hist_user_work ON mst_user.user_id = hist_user_work.user_id LEFT OUTER JOIN fc_user_work_item2 ON hist_user_work.hist_id = fc_user_work_item2.hist_id"];
	[selectsql appendFormat:@"  WHERE %@", strConditions];
	
	// WHERE句の設定
	if ([addState length] > 0)
	{
		[selectsql appendString:@" "];
		[selectsql appendString:addState];
	}
	// group by は where句の後に配置する
	[selectsql appendString:@"   GROUP BY mst_user.user_id"];
	// 2016/1/18 TMS ストア・デモ版統合対応 ソート対応
	[selectsql appendString:@"   ORDER BY mst_user.first_name,mst_user.second_name"];
#ifdef DEBUG
	NSLog(@"search by birthday userinfo sql state -> %@", selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo: sqlite3_column_int(sqlstmt, 0)
														 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
														secondName:[self makeSqliteStmt2String:sqlstmt index:2]
														middleName:[self makeSqliteStmt2String:sqlstmt index:3]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:4]
															   sex:sqlite3_column_int(sqlstmt, 5)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:6]
													  lastWorkDate:[self makeSqliteStmt2String:sqlstmt index:7]
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:8]
#ifdef CLOUD_SYNC
														  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, 9))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListByWorkItem2Array error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return datas;
}

// メモ2検索に該当するユーザー一覧の取得
- (NSMutableArray*)getUserInfoListByMemoArray:(NSArray*)arrayMemo AndSearch:(BOOL)andSearch optional:(NSString*)addState
{
	NSMutableArray* datas = [NSMutableArray array];
	
	// 入力なし
	NSInteger memoCount = [arrayMemo count];
	if ( arrayMemo == nil || memoCount == 0 )
		return datas;
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
			return (datas);
	}
	
	// 条件文の作成
	NSMutableString* strConditions = [[[NSMutableString alloc] init] autorelease];
	for ( NSInteger i = 0; i < memoCount; i++ )
	{
		// 文字列の追加(LIKEはバインド出来ない)
		[strConditions appendFormat:@"fc_user_memo.memo LIKE '%%%@%%' ", [arrayMemo objectAtIndex:i]];
		
		// 検索方法
		if ( i != (memoCount - 1) )
		{
			if ( andSearch )
				[strConditions appendString:@" AND "];
			else
				[strConditions appendString:@" OR "];
		}
	}
	
	/*
	 SELECT mst_user.user_id, first_name, second_name, regist_number, sex, picture_url, date(hist_user_work.work_date), date(birthday), shop_id FROM mst_user
	 LEFT OUTER JOIN (hist_user_work LEFT OUTER JOIN fc_user_work_item ON hist_user_work.hist_id = fc_user_work_item.hist_id)
	 ON mst_user.user_id = hist_user_work.user_id
	 WHERE fc_user_work_item.item_name = 'カラー'
	 GROUP BY mst_user.user_id 	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  mst_user.user_id, first_name, second_name, mid_name, regist_number,"];
	[selectsql appendString:@"  sex, picture_url, date(hist_user_work.work_date), date(birthday) "];
#ifdef CLOUD_SYNC
	[selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"    FROM mst_user "];
	[selectsql appendString:@"LEFT OUTER JOIN hist_user_work ON mst_user.user_id = hist_user_work.user_id LEFT OUTER JOIN fc_user_memo ON hist_user_work.hist_id = fc_user_memo.hist_id"];
	[selectsql appendFormat:@"  WHERE %@", strConditions];
	
	// WHERE句の設定
	if ([addState length] > 0)
	{
		[selectsql appendString:@" "];
		[selectsql appendString:addState];
	}
	// group by は where句の後に配置する
	[selectsql appendString:@"   GROUP BY mst_user.user_id"];
	// 2016/1/18 TMS ストア・デモ版統合対応 ソート対応
	[selectsql appendString:@"   ORDER BY mst_user.first_name,mst_user.second_name"];
#ifdef DEBUG
	NSLog(@"search by birthday userinfo sql state -> %@", selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo: sqlite3_column_int(sqlstmt, 0)
														 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
														secondName:[self makeSqliteStmt2String:sqlstmt index:2]
														middleName:[self makeSqliteStmt2String:sqlstmt index:3]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:4]
															   sex:sqlite3_column_int(sqlstmt, 5)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:6]
													  lastWorkDate:[self makeSqliteStmt2String:sqlstmt index:7]
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:8]
#ifdef CLOUD_SYNC
														  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, 9))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
			[usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListByMemoArray error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return datas;
}

// 誕生日検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByBirthDay:(NSString*)searchDate optional:(NSString*) statement
{
	NSMutableArray* datas = [NSMutableArray array];
	// [datas autorelease];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT  mst_user.user_id, first_name, second_name, regist_number, sex, picture_url, date(birthday)
	 FROM mst_user
	 WHERE birthday = julianday(date('2010-10-20'))
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  mst_user.user_id, first_name, second_name, mid_name, regist_number,"];
	[selectsql appendString:@"  sex, picture_url, date(birthday) "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"    FROM mst_user "];
	[selectsql appendString:@"WHERE birthday = julianday(date(?))"];

	// WHERE句の設定
	if ([statement length] > 0)
	{
		[selectsql appendString:@" "];
		[selectsql appendString:statement];
	}
#ifdef DEBUG
	NSLog(@"search by birthday userinfo sql state -> %@", selectsql);
#endif
	/*
	 ** 二回目の検索は最新施術日で絞り込むため
	 */
	sqlite3_stmt* sqlstmt = nil;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		// バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt, 1, [searchDate UTF8String], -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			USERID_INT userId = sqlite3_column_int(sqlstmt, 0);
			NSString* lastWork = [self getMaxNewWorkDateWithUserID:userId];
			
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo:userId
														 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
														secondName:[self makeSqliteStmt2String:sqlstmt index:2]
														middleName:[self makeSqliteStmt2String:sqlstmt index:3]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:4]
															   sex:sqlite3_column_int(sqlstmt, 5)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:6]
													  lastWorkDate:lastWork
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:7]
#ifdef CLOUD_SYNC
														  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, 8))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListBySearchDate error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

// 誕生年検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByBirthMonth:(NSString*)startDate And:(NSString*)endDate optional:(NSString*) statement
{
	NSMutableArray* datas = [NSMutableArray array];
	// [datas autorelease];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT user_id, first_name, second_name, regist_number, sex, picture_url, date(birthday)
	 FROM mst_user
	 WHERE strftime('%Y', date(birthday))
	 BETWEEN strftime('%Y','1990-01-01' )
	 AND strftime('%Y','1990-12-31' )
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  user_id, first_name, second_name, mid_name, regist_number, sex, picture_url, date(birthday)"];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"    FROM mst_user "];
	[selectsql appendString:@"WHERE strftime('%m', date(birthday)) "];
	[selectsql appendString:@"BETWEEN strftime('%m', ?) "];
	[selectsql appendString:@"AND strftime('%m', ?)"];
	
	// WHERE句の設定
	if ([statement length] > 0)
	{
		[selectsql appendString:@" "];
		[selectsql appendString:statement];
	}
	
	// 並び順を設定
	[selectsql appendString:@" ORDER BY birthday"];
	
#ifdef DEBUG
	NSLog(@"search by birthday userinfo sql state -> %@", selectsql);
#endif
	/*
	 ** 誕生年で絞り込み
	 */
	sqlite3_stmt* sqlstmt = nil;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		// バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt, 1, [startDate UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt, 2, [endDate UTF8String], -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			USERID_INT userId = sqlite3_column_int(sqlstmt, 0);
			NSString* lastWork = [self getMaxNewWorkDateWithUserID:userId];
			
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo:userId
														 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
														secondName:[self makeSqliteStmt2String:sqlstmt index:2]
														middleName:[self makeSqliteStmt2String:sqlstmt index:3]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:4]
															   sex:sqlite3_column_int(sqlstmt, 5)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:6]
													  lastWorkDate:lastWork
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:7]
#ifdef CLOUD_SYNC
														  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, 8))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListBySearchDate error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

// 誕生年検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByBirthYear:(NSString*)startDate And:(NSString*)endDate optional:(NSString*) statement
{
	NSMutableArray* datas = [NSMutableArray array];
	// [datas autorelease];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT user_id, first_name, second_name, regist_number, sex, picture_url, date(birthday)
	 FROM mst_user
	 WHERE strftime('%Y', date(birthday))
	 BETWEEN strftime('%Y','1990-01-01' )
	 AND strftime('%Y','1990-12-31' )
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  user_id, first_name, second_name, mid_name, regist_number, sex, picture_url, date(birthday)"];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"    FROM mst_user "];
	[selectsql appendString:@"WHERE strftime('%Y', date(birthday)) "];
	[selectsql appendString:@"BETWEEN strftime('%Y', ?) "];
	[selectsql appendString:@"AND strftime('%Y', ?)"];
	
	// WHERE句の設定
	if ([statement length] > 0)
	{
		[selectsql appendString:@" "];
		[selectsql appendString:statement];
	}
	
	// 並び順を設定
	[selectsql appendString:@" ORDER BY birthday"];
	
#ifdef DEBUG
	NSLog(@"search by birthday userinfo sql state -> %@", selectsql);
#endif
	/*
	 ** 誕生年で絞り込み
	 */
	sqlite3_stmt* sqlstmt = nil;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		// バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt, 1, [startDate UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt, 2, [endDate UTF8String], -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			USERID_INT userId = sqlite3_column_int(sqlstmt, 0);
			NSString* lastWork = [self getMaxNewWorkDateWithUserID:userId];

			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo:userId
														 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
														secondName:[self makeSqliteStmt2String:sqlstmt index:2]
														middleName:[self makeSqliteStmt2String:sqlstmt index:3]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:4]
															   sex:sqlite3_column_int(sqlstmt, 5)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:6]
													  lastWorkDate:lastWork
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:7]
#ifdef CLOUD_SYNC
														  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, 8))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListBySearchDate error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}


// お客様番号検索に該当するユーザ一覧の取得 registNumber:REGIST_NUMBER_INVALIDで全番号
- (NSMutableArray*)getUserInfoListByUserRegistNumberNew:(NSString*)registNumber isAsc:(BOOL)isAsc
											optional:(NSString*)addState
{
	NSMutableArray* datas = [NSMutableArray array];
	// [datas autorelease];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT  user_id, first_name, second_name, regist_number,
	 sex, picture_url, date(last_work_date)
	 FROM mst_user
	 WHERE regist_number LIKE %123%   -> 部分検索の場合
	 WHERE NOT regist_number IsNull   -> 全番号検索の場合
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  user_id, first_name, second_name, mid_name, regist_number, "];
	[selectsql appendString:@"  sex, picture_url, date(last_work_date), date(birthday) "];
#ifdef CLOUD_SYNC
	[selectsql appendString:@", mst_shop.shop_name, mst_user.shop_id"];
#endif
	[selectsql appendString:@"    FROM mst_user "];
#ifdef CLOUD_SYNC
	[selectsql appendString:@"      LEFT OUTER JOIN mst_shop"];
	[selectsql appendString:@"         ON mst_user.shop_id = mst_shop.shop_id "];
#endif
	[selectsql appendString:@"WHERE "];
	if (![registNumber isEqualToString:@"-1"])
	{
		//LIKEにバインド変数は使用できない
		[selectsql appendString:@" regist_number LIKE '%"];
		[selectsql appendFormat:@"%@", registNumber];
		[selectsql appendString:@"%'"];
	}
	else
	{	[selectsql appendString:@" NOT regist_number IsNull "]; }
	
	// WHERE句の設定
	if ( (addState) && ([addState length] > 0) )
	{   [selectsql appendString:addState]; }
	
	[selectsql appendString:@"ORDER BY regist_number "];
	if (! isAsc)
	{	[selectsql appendString:@" DESC"]; }
#ifdef DEBUG
	NSLog(@"search by regist number userinfo sql state -> %@", selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL)
		== SQLITE_OK)
	{
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			u_int idx = 0;
			
			// 先にuserIDを取得
			USERID_INT userID = sqlite3_column_int(sqlstmt, idx++);
			
			// 該当ユーザの最新施術日を取得
			NSString *maxDate = [self getMaxNewWorkDateWithUserID:userID];
			
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo:userID
														 firstName:[self makeSqliteStmt2String:sqlstmt index:idx++]
														secondName:[self makeSqliteStmt2String:sqlstmt index:idx++]
														middleName:[self makeSqliteStmt2String:sqlstmt index:idx++]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:idx++]
															   sex:sqlite3_column_int(sqlstmt, idx++)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:idx++]
													  lastWorkDate:maxDate
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:++idx]
#ifdef CLOUD_SYNC
														  shopName:[self makeSqliteStmt2String:sqlstmt index:++idx]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
			[usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListByUserRegistNumber error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

- (NSMutableArray*)getUserInfoListByUserRegistNumber:(NSInteger)registNumber isAsc:(BOOL)isAsc
                                            optional:(NSString*)addState
{
	NSMutableArray* datas = [NSMutableArray array];
	// [datas autorelease];
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT  user_id, first_name, second_name, regist_number, 
	         sex, picture_url, date(last_work_date)
	     FROM mst_user
	 WHERE regist_number LIKE %123%   -> 部分検索の場合
	 WHERE NOT regist_number IsNull   -> 全番号検索の場合
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  user_id, first_name, second_name, mid_name, regist_number, "];
	[selectsql appendString:@"  sex, picture_url, date(last_work_date), date(birthday) "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", mst_shop.shop_name, mst_user.shop_id"];
#endif
	[selectsql appendString:@"    FROM mst_user "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@"      LEFT OUTER JOIN mst_shop"];
    [selectsql appendString:@"         ON mst_user.shop_id = mst_shop.shop_id "];
#endif
	[selectsql appendString:@"WHERE "];
	if (registNumber != REGIST_NUMBER_INVALID)
	{	
		//LIKEにバインド変数は使用できない
		[selectsql appendString:@" regist_number LIKE '%"]; 
		[selectsql appendFormat:@"%d", (int)registNumber];
		[selectsql appendString:@"%'"];
	}	
	else 
	{	[selectsql appendString:@" NOT regist_number IsNull "]; }
			
	// WHERE句の設定
    if ( (addState) && ([addState length] > 0) )
    {   [selectsql appendString:addState]; }
    
	[selectsql appendString:@"ORDER BY regist_number "];
	if (! isAsc)
	{	[selectsql appendString:@" DESC"]; }
#ifdef DEBUG
	NSLog(@"search by regist number userinfo sql state -> %@", selectsql);
#endif
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		if (registNumber != REGIST_NUMBER_INVALID)
		{
			//バインド変数をクリアー
			//sqlite3_clear_bindings(sqlstmt);
			//sqlite3_bind_text(sqlstmt,1,[[NSString stringWithFormat:@"%d",registNumber] UTF8String],-1,SQLITE_TRANSIENT);
		}
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			u_int idx = 0;
			
			// 先にuserIDを取得
			USERID_INT userID = sqlite3_column_int(sqlstmt, idx++);
			
			// 該当ユーザの最新施術日を取得
			NSString *maxDate = [self getMaxNewWorkDateWithUserID:userID];
			
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo:userID
														 firstName:[self makeSqliteStmt2String:sqlstmt index:idx++]
														secondName:[self makeSqliteStmt2String:sqlstmt index:idx++]
														middleName:[self makeSqliteStmt2String:sqlstmt index:idx++]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:idx++]
															   sex:sqlite3_column_int(sqlstmt, idx++)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:idx++]
													  lastWorkDate:maxDate
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:++idx]
#ifdef CLOUD_SYNC
                                                          shopName:[self makeSqliteStmt2String:sqlstmt index:++idx]
#endif                                 
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else 
	{
		NSLog(@"getUserInfoListByUserRegistNumber error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

// メール送信エラーに該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByMailSendError:(NSString*)addState
{
	NSMutableArray* datas = [NSMutableArray array];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	/*
	 SELECT user_id, first_name, second_name, regist_number, sex, picture_url, date(birthday)
	 FROM mst_user
	 WHERE strftime('%Y', date(birthday))
	 BETWEEN strftime('%Y','1990-01-01' )
	 AND strftime('%Y','1990-12-31' )
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  user_id, first_name, second_name, mid_name, regist_number, sex, picture_url, date(birthday)"];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", shop_id "];
#endif
	[selectsql appendString:@"FROM mst_user "];
	if (addState.length>0) {
		[selectsql appendFormat:@"where %@ ", addState];	// 店舗階層対応
	}
	[selectsql appendString:@"ORDER BY first_name_kana, second_name_kana"];
#ifdef DEBUG
	NSLog(@"search by Mail send error userinfo sql state -> %@", selectsql);
#endif
	/*
	 **
	 */
	sqlite3_stmt* sqlstmt = nil;
	if ( sqlite3_prepare_v2(db, [selectsql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		// バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			USERID_INT userId = sqlite3_column_int(sqlstmt, 0);
			NSString* lastWork = [self getMaxNewWorkDateWithUserID:userId];
			
			// 取得したrowからユーザ情報オブジェクトを生成
			userInfo* usrInfo = [[userInfo alloc] initWithUserInfo:userId
														 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
														secondName:[self makeSqliteStmt2String:sqlstmt index:2]
														middleName:[self makeSqliteStmt2String:sqlstmt index:3]
													  registNumber:[self makeSqliteStmt2String:sqlstmt index:4]
															   sex:sqlite3_column_int(sqlstmt, 5)
														pictureURL:[self makeSqliteStmt2String:sqlstmt index:6]
													  lastWorkDate:lastWork
														  birthDay:[self makeSqliteStmt2String:sqlstmt index:7]
#ifdef CLOUD_SYNC
														  shopName:[self _getShopNameWithID:(sqlite3_column_int(sqlstmt, 8))]
#endif
								 ];
			// リストに加える
			[datas addObject:usrInfo];
            [usrInfo release];
		}
	}
	else
	{
		NSLog(@"getUserInfoListByMailSendError error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

// IDによるユーザ（マスタ）の取得
- (mstUser*)getMstUserByID:(USERID_INT)userID
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (nil); }
	}
	
	mstUser *user = nil;
	
	/*
	 SELECT  user_id, first_name, second_name, regist_number, sex, 
	 first_name_kana, second_name_kana, 
	 picture_url, syumi, memo,
	 date(birthday), date(last_work_date)
	 FROM mst_user
	 WHERE user_id = 1;
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT "];
	[selectsql appendString:@"first_name, second_name, mid_name, "];
	[selectsql appendString:@"first_name_kana, second_name_kana, regist_number, sex, "];
	[selectsql appendString:@"postal, adr1, adr2, adr3, adr4, tel, mobile, "];
	[selectsql appendString:@"picture_url, syumi, email1, email2, memo, responsible, bload_type, "];
	[selectsql appendString:@"date(birthday), date(last_work_date)"];
#ifdef CLOUD_SYNC
    [selectsql appendString:@", mst_shop.shop_name, mst_user.shop_id"];
#endif
	[selectsql appendString:@"  FROM mst_user "];
#ifdef CLOUD_SYNC
    [selectsql appendString:@"    LEFT OUTER JOIN mst_shop"];
    [selectsql appendString:@"       ON mst_user.shop_id = mst_shop.shop_id "];
#endif
	[selectsql appendString:@"WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,[[NSString stringWithFormat:@"%d",userID] UTF8String],-1,SQLITE_TRANSIENT);
		
		if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			u_int idx = 0;
			
			// 取得したrowからユーザオブジェクトの基本部分を生成
			user = [[mstUser alloc] initWithNewUser:
						[self makeSqliteStmt2String:sqlstmt index:idx++]
						secondName:[self makeSqliteStmt2String:sqlstmt index:idx++]
						middleName:[self makeSqliteStmt2String:sqlstmt index:idx++]
						firstNameCana:[self makeSqliteStmt2String:sqlstmt index:idx++]
						secondNameCana:[self makeSqliteStmt2String:sqlstmt index:idx++]
						registNumber:[self makeSqliteStmt2String:sqlstmt index:idx++]
						sex:(sqlite3_column_int(sqlstmt, idx++) == 0)? Lady : Men
					];

			// 残りのメンバを設定する
			user.postal		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.adr1		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.adr2		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.adr3		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.adr4		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.tel		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.mobile		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.pictuerURL = [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.syumi		= [self makeSqliteStmt2String:sqlstmt index:idx++];
            user.email1		= [self makeSqliteStmt2String:sqlstmt index:idx++];
            user.email2		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.memo		= [self makeSqliteStmt2String:sqlstmt index:idx++];
			user.responsible = [self makeSqliteStmt2String:sqlstmt index:idx++];
			[user setBloadTypeByInt:sqlite3_column_int(sqlstmt, idx++)];
			[user setBirthDayByString:[self makeSqliteStmt2String:sqlstmt index:idx++]];
#ifdef CLOUD_SYNC
            user.shopName = [self makeSqliteStmt2String:sqlstmt index:++idx];
            user.shopID = sqlite3_column_int(sqlstmt, ++idx);
#endif
			// userIDも設定
			user.userID = userID;
		}
	}
	else 
	{
		NSLog(@"getMstUserByID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (user);
}

// IDによるユーザの写真urlの取得
- (NSString*)getMstUserPictureUrlByID:(USERID_INT)userID
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (nil); }
	}
	
	NSString *pictureUrl = nil;
	
	/*
	 SELECT  picture_url FROM mst_user
	   WHERE user_id = 1;
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT "];
	[selectsql appendString:@"picture_url"];
	[selectsql appendString:@"  FROM mst_user "];
	[selectsql appendString:@"WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,[[NSString stringWithFormat:@"%d",userID] UTF8String],-1,SQLITE_TRANSIENT);
		
		if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			u_int idx = 0;
			
			pictureUrl = [self makeSqliteStmt2String:sqlstmt index:idx++];
		}
	}
	else 
	{
		NSLog(@"getMstUserPictureUrlByID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (pictureUrl);
}

// ユーザ情報(マスタ)の更新
- (BOOL)updateMstUser:(mstUser*)user4Update
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//update文の作成
	/*
	 UPDATE  mst_user 
	 SET first_name = ?, second_name = ?, 
	   first_name_kana = ?, second_name_kana = ?, regist_number = ?, 
	   sex = ?, bload_type = ?, syumi  = ?, memo = ?,
	   birthday = julianday(date(?))
	 WHERE user_id = ?;
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE  mst_user"]; 
	[updateSql appendString:@" SET first_name = ?, second_name = ?, mid_name = ?, "];
	[updateSql appendString:@" first_name_kana = ?, second_name_kana = ?, regist_number = ?,"];
	[updateSql appendString:@" postal = ?, adr1 = ?, adr2 = ?, adr3 = ?, adr4 = ?, tel = ?, mobile = ?,"];
	[updateSql appendString:@" sex = ?, bload_type = ?, syumi  = ?, email1 = ?, email2 = ?, memo = ?, responsible = ?"];
	if (user4Update.birthDay)
	{	[updateSql appendString:@", birthday = julianday(date(?)) "]; }
#ifdef CLOUD_SYNC
    [updateSql appendString:@", shop_id = ? "];
#endif
	[updateSql appendString:@" WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
		// 姓と名（かな含む）の設定：空文字の場合は、dbNullを設定する
		[self setBindTextWithString:user4Update.firstName pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.secondName pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.middleName pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.firstNameCana pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.secondNameCana pStatement:sqlstmt setPositon:idx++];
		if (user4Update.registNumber != REGIST_NUMBER_INVALID)
		{	sqlite3_bind_int(sqlstmt, idx++, (int)user4Update.registNumber);}
		else 
		{	sqlite3_bind_null(sqlstmt, idx++);}		// お客様番号の無効値はdbNullで設定する
		[self setBindTextWithString:user4Update.postal pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.adr1 pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.adr2 pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.adr3 pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.adr4 pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.tel pStatement:sqlstmt setPositon:idx++];
		[self setBindTextWithString:user4Update.mobile pStatement:sqlstmt setPositon:idx++];
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithString:(user4Update.sex != Men)? @"0" : @"1"] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%d", user4Update.bloadType] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,[user4Update.syumi UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlstmt,idx++,[user4Update.email1 UTF8String],-1,SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlstmt,idx++,[user4Update.email2 UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,[user4Update.memo UTF8String],-1,SQLITE_TRANSIENT);
		// 2016/8/12 TMS 顧客情報に担当者を追加
		sqlite3_bind_text(sqlstmt,idx++,[user4Update.responsible UTF8String],-1,SQLITE_TRANSIENT);
		if (user4Update.birthDay)
		{
			sqlite3_bind_text(sqlstmt,idx++,
				[[self makeDateStringByNSDate:user4Update.birthDay] UTF8String],-1,SQLITE_TRANSIENT);
		}
#ifdef CLOUD_SYNC
        sqlite3_bind_int(sqlstmt, idx++, (SHOPID_INT)user4Update.shopID);
#endif
		sqlite3_bind_text(sqlstmt,idx++,
				[[NSString stringWithFormat:@"%d",user4Update.userID] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
						
			return (NO);
		}
#ifdef CLOUD_SYNC
		// 2016/7/25 TMS お客様番号のみ登録時に対応
		// fc_update_mng_time_delete.key_value may not be NULL のため、いずれかの値を設定
		user4Update.firstName = ((user4Update.firstName) && ([user4Update.firstName length] > 0))?
		user4Update.firstName : [NSString stringWithFormat:@"%ld", (long)user4Update.registNumber];
		
        if ([CloudSyncClientDatabaseUpdate editUserWithID:user4Update.userID
                                                  firstName:user4Update.firstName
                                                 secondName:user4Update.secondName
                                              sqlite3Object:db] )
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        }
#else	        
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
}

- (BOOL)deleteUserPicture:(USERID_INT)userID pictureURL:(NSString*)url
{
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//update文の作成
	/*
	 UPDATE  mst_user
	 SET picture_url = ?
	 WHERE user_id = ?;
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"DELETE FROM  hist_user_work"];
	[updateSql appendString:@" WHERE head_picture_url = ? "];
	[updateSql appendString:@" AND user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,[url UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%d", userID] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
#ifdef CLOUD_SYNC
	
		if ([CloudSyncClientDatabaseUpdate deleteHeadPictureWithID :userID
														sqlite3Object:db] )
		{
			//正常終了(COMMITをして処理を終了)
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
			stat = YES;
		}
		else
		{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		}
#else
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
	
}

// ユーザの写真更新
- (BOOL)updateUserPictureNew:(USERID_INT)userID pictureURL:(NSString *)url complete:(CompletionBlock)completed
{
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//update文の作成
	/*
	 UPDATE  mst_user
	 SET picture_url = ?
	 WHERE user_id = ?;
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE  mst_user"];
	[updateSql appendString:@" SET picture_url = ? "];
	[updateSql appendString:@" WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,[url UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%d", userID] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			completed(NO);
			return (NO);
		}
#ifdef CLOUD_SYNC
		if ([CloudSyncClientDatabaseUpdate editUserHeadPictureWithID :userID
														sqlite3Object:db] )
		{
			//正常終了(COMMITをして処理を終了)
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
			stat = YES;
		}
		else
		{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		}
#else
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	completed(YES);
	
	return(stat);
	
}

// ユーザの写真更新
- (BOOL)updateUserPicture:(USERID_INT)userID pictureURL:(NSString*)url
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//update文の作成
	/*
	 UPDATE  mst_user 
	  SET picture_url = ?
	 WHERE user_id = ?;
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE  mst_user"];
	[updateSql appendString:@" SET picture_url = ? "];
	[updateSql appendString:@" WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,[url UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
			[[NSString stringWithFormat:@"%d", userID] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
#ifdef CLOUD_SYNC
        if ([CloudSyncClientDatabaseUpdate editUserHeadPictureWithID :userID
                                                        sqlite3Object:db] )
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        }
#else	
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
	
}

// ユーザの元urlによる写真更新
- (BOOL)updateUserPictureByNewUrl:(NSString*)oridinalUrl newUrl:(NSString*)url
{
	// 元urlがnilの場合は、何もしない（レコードが特定できないため）
	if (! oridinalUrl)
	{ return (YES); }
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
#ifdef CLOUD_SYNC
    // 事前に代表写真urlよりユーザIDと姓、名を取得しておく
    NSString *firstName = nil;
    NSString *secondName = nil;
    USERID_INT userID
        = [self getUserIDByPictURL:oridinalUrl pFirstName:&firstName pSecondName:&secondName];
    
#endif
	// 拡張子を除くurlで確認する
	NSString *noSuffix = [oridinalUrl substringToIndex:[oridinalUrl length] - 3];
	
	//update文の作成
	/*
	 UPDATE mst_user 
	   SET picture_url=Null 
	 WHERE user_id =
	   (SELECT user_id FROM mst_user 
         WHERE picture_url = '101110_100209.jpg')
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE mst_user "]; 
	[updateSql appendString:@"  SET picture_url=? "];
	[updateSql appendString:@"WHERE user_id = "];
	[updateSql appendString:@"  (SELECT user_id FROM mst_user "];
	//LIKEにバインド変数は使用できない
	[updateSql appendFormat:@"     WHERE picture_url LIKE '%@%%')", noSuffix];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に履歴IDとurl値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
						  ((url)? [url UTF8String] : NULL), -1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
#ifdef CLOUD_SYNC
        if (userID > 0) 
        {
            if ([CloudSyncClientDatabaseUpdate editUserWithID:userID
                                                    firstName:firstName
                                                   secondName:secondName
                                                sqlite3Object:db] )
            {
                //正常終了(COMMITをして処理を終了)
                sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
                stat = YES;
            }
            else
            {
                //異常終了(ROLLBACKして処理を終了)
                sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
            }
        }
        else
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
#else	
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
}

// NSDateから文字列を取得
- (NSString*) makeDateStringByNSDate:(NSDate*)date
{
	NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
	fmt.dateFormat = @"yyyy-MM-dd";
	return ( [fmt stringFromDate:date] );
}

// IDによる施術内容の取得
- (fcUserWorkItem*) getUserWorkItemByID:(USERID_INT)usrID userName:(NSString*)usrName :(fcUserWorkItem*)workItem
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (nil); }
	}
	// 2016/6/1 TMS メモリ使用率抑制対応
	//fcUserWorkItem *workItem = [[fcUserWorkItem alloc]
	//							initWithWorkItem:usrID userName:usrName];
	
	/*
	 SELECT  date(hist_user_work.work_date), fc_user_work_item.item_name
		FROM hist_user_work LEFT OUTER JOIN fc_user_work_item 
			ON hist_user_work.hist_id = fc_user_work_item.hist_id
		WHERE (hist_user_work.work_date 
			= (SELECT MAX(hist_user_work.work_date) FROM hist_user_work
				WHERE hist_user_work.user_id = 1) 
			AND hist_user_work.user_id = 1)
		ORDER BY fc_user_work_item.order_num	 
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT  date(hist_user_work.work_date), fc_user_work_item.item_name "];
	[selectsql appendString:@"  FROM hist_user_work LEFT OUTER JOIN fc_user_work_item "];
	[selectsql appendString:@"     ON hist_user_work.hist_id = fc_user_work_item.hist_id "];
	[selectsql appendString:@"  WHERE (hist_user_work.work_date "];
	[selectsql appendString:@"     = (SELECT MAX(hist_user_work.work_date) FROM hist_user_work"];
	[selectsql appendString:@"           WHERE hist_user_work.user_id = ?) AND hist_user_work.user_id = ?)"];
	[selectsql appendString:@"  ORDER BY fc_user_work_item.order_num"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,[[NSString stringWithFormat:@"%d",usrID] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,2,[[NSString stringWithFormat:@"%d",usrID] UTF8String],-1,SQLITE_TRANSIENT);
		
		BOOL isSetDate = NO;
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			u_int idx = 0;
			
			// 取得したrowから施術内容のItemオブジェクトに値を設定
			if (! isSetDate)
			{ 
				// 最新施術日は初回のみ設定
				// 2016/6/1 TMS メモリ使用率抑制対応
				NSString *str = [self makeSqliteStmt2String:sqlstmt index:idx++];
				[ workItem setNewWorkDateByString:
					str];
				isSetDate = YES;
				[str release];
			}
			else {
				idx++;
			}
			
			/*[workItem.workItemListNumber 
				addObject:[NSString stringWithFormat:@"%d", 
						   sqlite3_column_int(sqlstmt, idx++)]];*/
			// 2016/6/1 TMS メモリ使用率抑制対応
			NSString *str2 = [self makeSqliteStmt2String:sqlstmt index:idx++];
			[workItem setWorkItemByString
				:str2];
			[str2 release];
		}
	}
	else 
	{
		NSLog(@"getUserWorkItemByID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
		workItem = nil;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	// 施術内容の文字列一覧の取得
	if ( (workItem.workItemStrings = [self getWorkItemStrings:ITEM_EDIT_USER_WORK1_TABLE]) )
	{	[[workItem.workItemStrings retain]autorelease ]; }
	else 
	{	workItem = nil; }

	//クローズ
	[self closeDataBase];
	
	return (workItem);
}

// IDによる施術内容一覧の取得
- (NSMutableArray*) getUserWorkItemsByID:(USERID_INT)usrID
{
	NSMutableArray *histUserItems;
	histUserItems = [NSMutableArray array];
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (histUserItems); }
	}	

	// 履歴テーブルより該当ユーザの一覧を取得
	/*
	 SELECT hist_ID, date(work_date), head_picture_url 
	   FROM hist_user_work WHERE user_id = 1 ORDER BY work_date DESC
	 */
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT hist_ID, date(work_date), head_picture_url "];
	[selectsql appendString:@"  FROM hist_user_work WHERE user_id = ? "];
	[selectsql appendString:@"    ORDER BY work_date DESC"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,[[NSString stringWithFormat:@"%d",usrID] UTF8String],-1,SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// 施術内容のItemのインスタンス生成
			fcUserWorkItem *workItem 
				= [[fcUserWorkItem alloc] initWithUserID:usrID];
			
			u_int idx = 0;
			// 取得したrowから施術内容のItemオブジェクトに値を設定
			workItem.histID = sqlite3_column_int(sqlstmt, idx++);
			[workItem setNewWorkDateByString:
				[self makeSqliteStmt2String:sqlstmt index:idx++]];
			workItem.headPictureUrl =
				[self makeSqliteStmt2String:sqlstmt index:idx++];
			
			// 施術内容の文字列一覧の設定
			[self setWorkItemList:workItem];
			
			// 写真リストの設定
			[self setPictureUrls:workItem];
			// 動画リストの設定
			[self setVideoUrls:workItem];
			
			// メモリストの設定
			[self setUserMemos:workItem];
			
			//START, 2011.06.19, chen, ADD
			//fcUserWorkItem *workItem2 = [[fcUserWorkItem alloc] initWithUserID:usrID];
			//workItem2.histID = workItem.histID;
			// 施術内容2の文字列一覧の設定
			[self setWorkItemList2:workItem];
			//END
			// リストにworkItemを加える
			[histUserItems addObject:workItem];
			[workItem release];
			//START, 2011.06.19, chen, ADD
			//[histUserItems addObject:workItem2];
			//END
		}
	}
	else 
	{
		NSLog(@"getUserWorkItemsByID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	
	return (histUserItems);

}

// 施術内容の文字列一覧の取得
- (NSMutableArray*) getWorkItemStrings:(NSString *)tableName
{
	NSMutableArray *workItemStrings = [NSMutableArray array];
	
	// データベースが閉じている場合はOPENする
	// 2016/6/1 TMS メモリ使用率抑制対応
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return nil; }
	}
	/*
	 SELECT work_item_name
	   FROM mst_user_work_item
	*/
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT work_item_name "];
	[selectsql appendFormat:@"  FROM %@", tableName];
	[selectsql appendString:@"    ORDER BY work_item_id"];
	
	sqlite3_stmt* sqlstmt;
	
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// 2016/6/1 TMS メモリ使用率抑制対応
			NSString *str = [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0];
			[workItemStrings addObject:
			str];
			[str release];
		}
	}
	else 
	{
		workItemStrings = nil;
	}
	
	//sql文の解放
	// 2016/6/1 TMS メモリ使用率抑制対応
	sqlite3_finalize(sqlstmt);
	//クローズ
	[self closeDataBase];
	
	return(workItemStrings);
}

// 施術マスタの文字列テーブルの取得：key=ID object=施術内容（文字列）
- (NSMutableDictionary*) getWorkItemTable:(NSString *)tableName
{
	NSMutableDictionary *table = [NSMutableDictionary dictionary];
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (table); }
	}
	
	// 施術マスタより一覧を取得
	/*
	 SELECT work_item_id, work_item_name 
	   FROM mst_user_work_item
	     ORDER BY work_item_id
	 */
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT work_item_id, work_item_name "];
	[selectsql appendFormat:@"  FROM %@ ", tableName];
	[selectsql appendString:@"    ORDER BY work_item_id"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// テーブルにkey=ID object=施術内容（文字列）として加える
			[table setObject:[self makeSqliteStmt2String:sqlstmt index:(NSUInteger)1]
					  forKey:[NSString stringWithFormat:@"%d", 
							  sqlite3_column_int(sqlstmt, (NSUInteger)0)]];
		}
	}
	else 
	{
		NSLog(@"getWorkItemTable error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];	
	
	return (table);
}


// 施術内容の更新
- (BOOL) updateUserWorkItem:(fcUserWorkItem*) workItem
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
		
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	// 最初に最新施術内容をすべて削除する
	if (! [self deleteNewWorkItem:workItem])
	{	
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		//dbをクローズ
		[self closeDataBase];
		
		return (NO); 
	}
	
	// 施術内容の設定がない場合はここで正常終了
	if ([workItem.workItemListNumber count] <= 0)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		//dbをクローズ
		[self closeDataBase];
		
		return (YES);
	}
	
	BOOL stat = YES;
		
	//insert文の作成
	/*
	 INSERT INTO fc_user_work_item 
	   (user_id, work_date, work_item_id)
	 VALUES
	   (?,julianday(date(?)),?);
	 */
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"INSERT INTO fc_user_work_item "];
	[inssql appendString:@" (user_id, work_date, work_item_id) "];
	[inssql appendString:@"VALUES "];
	[inssql appendString:@" (?,julianday(date(?)),?)"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		
		NSString *usrID = [NSString stringWithFormat:@"%d", workItem.userID];
		NSString *workDate = [self makeDateStringByNSDate:workItem.workItemDate];
		
		for (id itemNo in workItem.workItemListNumber)
		{
			//sqlをリセット
			sqlite3_reset(sqlstmt);
			//バインド変数をクリアー
			sqlite3_clear_bindings(sqlstmt);
			
			// バインド変数に施術内容を設定
			u_int idx = 1;
			sqlite3_bind_text(sqlstmt,idx++, [usrID UTF8String],-1,SQLITE_TRANSIENT);
			sqlite3_bind_text(sqlstmt,idx++, [workDate UTF8String],-1,SQLITE_TRANSIENT);
			sqlite3_bind_text(sqlstmt,idx++, [(NSString*)itemNo UTF8String],-1,SQLITE_TRANSIENT);
		
			//sql文を実行してエラーが発生した場合はクローズさせて終了
			if(sqlite3_step(sqlstmt) != SQLITE_DONE)
			{
				stat = NO;
				break;
			}
			
		}
		
		// mstUserの最終施術日も更新
		if(stat)
		{
			stat = [self updateMstUserLastWorkDate:usrID lastWorkDate:workDate];
		}
	}
	else 
	{
	// 構文解析の結果問題あり 
		stat = NO;
	}
	
	if (stat)
	{
		//すべて正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];	
	
	return (stat);
}

// 施術内容リストの更新
- (BOOL) updateUserWorkItemList:(HISTID_INT)histID workItemListNumber:(NSMutableArray*) numbers
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	NSString *hID = [NSString stringWithFormat:@"%d", histID];
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	// 先に該当履歴IDの施術内容を全て削除する
	if (! [self deleteAllWorkItems:hID tableName:@"fc_user_work_item"])
	{	
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		//dbをクローズ
		[self closeDataBase];
		
		return (NO); 
	}
	
	// 施術内容の設定がない場合はここで正常終了
	if ([numbers count] <= 0)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		//dbをクローズ
		[self closeDataBase];
		
		return (YES);
	}
	
	BOOL stat = YES;
	
	//insert文の作成
	/*
	 INSERT INTO fc_user_work_item 
	   (hist_id, work_item_id)
	     VALUES (?,?);
	 */
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"INSERT INTO fc_user_work_item "];
	[inssql appendString:@"  (hist_id, work_item_id)"];
	[inssql appendString:@"    VALUES (?,?)"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		
		
		for (id itemID in numbers)
		{
			//sqlをリセット
			sqlite3_reset(sqlstmt);
			//バインド変数をクリアー
			sqlite3_clear_bindings(sqlstmt);
			
			// バインド変数に施術内容を設定
			u_int idx = 1;
			sqlite3_bind_text(sqlstmt,idx++, [hID UTF8String],-1,SQLITE_TRANSIENT);
			sqlite3_bind_text(sqlstmt,idx++, [(NSString*)itemID UTF8String],-1,SQLITE_TRANSIENT);
			
			//sql文を実行してエラーが発生した場合はクローズさせて終了
			if(sqlite3_step(sqlstmt) != SQLITE_DONE)
			{
				stat = NO;
				break;
			}
			
		}
	}
	else 
	{
		// 構文解析の結果問題あり 
		stat = NO;
	}
	
	if (stat)
	{
		//すべて正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];	
	
	return (stat);
}

// 施術内容リストの更新
- (BOOL) updateUserWorkItemList2:(HISTID_INT)histID workItemListNumber:(NSMutableArray*) numbers
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	NSString *hID = [NSString stringWithFormat:@"%d", histID];
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	// 先に該当履歴IDの施術内容を全て削除する
	if (! [self deleteAllWorkItems:hID tableName:@"fc_user_work_item2"])
	{	
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		//dbをクローズ
		[self closeDataBase];
		
		return (NO); 
	}
	
	// 施術内容の設定がない場合はここで正常終了
	if ([numbers count] <= 0)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		//dbをクローズ
		[self closeDataBase];
		
		return (YES);
	}
	
	BOOL stat = YES;
	
	//insert文の作成
	/*
	 INSERT INTO fc_user_work_item 
	 (hist_id, work_item_id)
	 VALUES (?,?);
	 */
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"INSERT INTO fc_user_work_item2 "];
	[inssql appendString:@"  (hist_id, work_item_id)"];
	[inssql appendString:@"    VALUES (?,?)"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		
		for (id itemID in numbers)
		{
			//sqlをリセット
			sqlite3_reset(sqlstmt);
			//バインド変数をクリアー
			sqlite3_clear_bindings(sqlstmt);
			
			// バインド変数に施術内容を設定
			u_int idx = 1;
			sqlite3_bind_text(sqlstmt,idx++, [hID UTF8String],-1,SQLITE_TRANSIENT);
			sqlite3_bind_text(sqlstmt,idx++, [(NSString*)itemID UTF8String],-1,SQLITE_TRANSIENT);
			
			//sql文を実行してエラーが発生した場合はクローズさせて終了
			if(sqlite3_step(sqlstmt) != SQLITE_DONE)
			{
				stat = NO;
				break;
			}
			
		}
	}
	else 
	{
		// 構文解析の結果問題あり 
		stat = NO;
	}
	
	if (stat)
	{
		//すべて正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];	
	
	return (stat);
}

// 施術内容文字の更新
- (BOOL) updateUserItemEditWithString:(HISTID_INT)histID
							itemKinds:(ITEM_EDIT_KIND*)kinds
                            itemEdits:(NSArray*)items
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = YES;
	
	NSString *hID = [NSString stringWithFormat:@"%d", histID];
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	for (NSUInteger i = 0; i < [items count]; i++)
	{
		NSString *fcTblName = [self getFcTableNameWithItemEditKind:kinds[i]];
		
		// 先に該当履歴IDの施術内容を全て削除する
		if (! [self deleteAllWorkItems:hID tableName:fcTblName])
		{	
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//dbをクローズ
			[self closeDataBase];
		
			return (NO); 
		}
	
		//insert文の作成
		/*
		 INSERT INTO fc_user_work_item 
			(hist_id, work_item_id)
		 VALUES (?,?);
		 */
		NSMutableString *inssql = [NSMutableString string];
		[inssql appendFormat:@"INSERT INTO %@ ", fcTblName];
		[inssql appendFormat:@"  (hist_id,%@,%@)", ITEM_EDIT_NAME_FIELD, ITEM_EDIT_ORDER_FIELD];
		[inssql appendString:@"    VALUES (?,?,?)"];
	
		sqlite3_stmt* sqlstmt;
	
		if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
				== SQLITE_OK)
		{
			// 構文解析の結果問題なし
			
			u_int order = 0;
			for (id name in [items objectAtIndex:i])
			{
				//sqlをリセット
				sqlite3_reset(sqlstmt);
				//バインド変数をクリアー
				sqlite3_clear_bindings(sqlstmt);
			
				// バインド変数に施術内容を設定
				u_int idx = 1;
				NSString *orderS = [NSString stringWithFormat:@"%d", order++];
				sqlite3_bind_text(sqlstmt,idx++, [hID UTF8String],-1,SQLITE_TRANSIENT);
				sqlite3_bind_text(sqlstmt,idx++, [name UTF8String],-1,SQLITE_TRANSIENT);
				sqlite3_bind_text(sqlstmt,idx++, [orderS UTF8String],-1,SQLITE_TRANSIENT);
			
				//sql文を実行してエラーが発生した場合はクローズさせて終了
				if(sqlite3_step(sqlstmt) != SQLITE_DONE)
				{
					stat = NO;
					break;
				}
			
			}
		}
		else 
		{
			// 構文解析の結果問題あり 
			stat = NO;
		}
		
		//sql文の解放
		sqlite3_finalize(sqlstmt);
		
		if (!stat)
		{
			//エラーメソッドをコール
			[self errDataBase];
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			break;
		}
	}
	
	if (stat)
	{
#ifdef CLOUD_SYNC
        for (NSUInteger i = 0; i < [items count]; i++) 
        {
            USER_WORK_ITEM_KIND kind = (i == 0)? USER_WORK_ITEM_1 : USER_WORK_ITEM_2;
            
            if (! [CloudSyncClientDatabaseUpdate userWorkItemEditWiithID:histID
                                                              memoKind:kind
                                                            memoTables:[items objectAtIndex:i]
                                                sqlite3Object:db] )
            {
                //異常終了(ROLLBACKして処理を終了)
                sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
                stat = NO;
                break;
            }
        }
        if (stat)
        {
            //すべて正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
        }
#else
		//すべて正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
#endif
	}
	
	//クローズ
	[self closeDataBase];	
	
	return (stat);
}

// 施術メモリストの更新
- (BOOL) updateUserWorkMemoList:(HISTID_INT) histID userMemos:(NSMutableArray*) userMemos
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	NSString *hID = [NSString stringWithFormat:@"%d", histID];
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	// 先に該当履歴IDのユーザメモを全て削除する
	if (! [self deleteAllWorkItems:hID tableName:@"fc_user_memo"])
	{	
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		//dbをクローズ
		[self closeDataBase];
		
		return (NO); 
	}
	
	// メモの設定がない場合はここで正常終了
	if ([userMemos count] <= 0)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		//dbをクローズ
		[self closeDataBase];
		
		return (YES);
	}
	
	BOOL stat = YES;
	
	//insert文の作成
	/*
	 INSERT INTO fc_user_memo 
	   (hist_id, memo)
	     VALUES (?,?);
	 */
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"INSERT INTO fc_user_memo "];
	[inssql appendString:@"  (hist_id, memo)"];
	[inssql appendString:@"    VALUES (?,?)"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		for (id userMemo in userMemos)
		{
			//sqlをリセット
			sqlite3_reset(sqlstmt);
			//バインド変数をクリアー
			sqlite3_clear_bindings(sqlstmt);
			
			// バインド変数に施術内容を設定
			u_int idx = 1;
			sqlite3_bind_text(sqlstmt,idx++, [hID UTF8String],-1,SQLITE_TRANSIENT);
			sqlite3_bind_text(sqlstmt,idx++, [(NSString*)userMemo UTF8String],-1,SQLITE_TRANSIENT);
			
			//sql文を実行してエラーが発生した場合はクローズさせて終了
			if(sqlite3_step(sqlstmt) != SQLITE_DONE)
			{
				stat = NO;
				break;
			}
			
		}
	}
	else 
	{
		// 構文解析の結果問題あり 
		stat = NO;
	}
	
	if (stat)
	{
#ifdef CLOUD_SYNC
        if ([CloudSyncClientDatabaseUpdate userMemoEditWiithID:histID
                                                    memoTables:userMemos
                                                 sqlite3Object:db] )
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
            stat = NO;
        }
#else	
		//すべて正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];	
	
	return (stat);
}


// 最新施術内容をすべて削除する
- (BOOL) deleteNewWorkItem:(fcUserWorkItem*)workItem
{
	BOOL stat = NO;
	
	/*
	 DELETE FROM fc_user_work_item 
	 WHERE user_id = ? 
	  AND work_date = julianday(date(?))
	 */
	NSMutableString *delsql = [NSMutableString string];
	[delsql appendString:@"DELETE FROM fc_user_work_item "];
	[delsql appendString:@"  WHERE user_id = ? "];
	[delsql appendString:@"   AND work_date = julianday(date(?))"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [delsql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
				[[NSString stringWithFormat:@"%d", workItem.userID] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
				[[self makeDateStringByNSDate:workItem.workItemDate] UTF8String],-1,SQLITE_TRANSIENT);
		
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//エラーメソッドをコール
			[self errDataBase];
		}
		else 
		{
			stat = YES;
		}
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);

	return (stat);
}

// mstUserの最終施術日の更新
- (BOOL) updateMstUserLastWorkDate:(NSString*)userID lastWorkDate:(NSString*)workDate
{
	BOOL stat;
	
	//update文の作成
	/*
	 UPDATE  mst_user 
	 SET last_work_date = julianday(date(?))
	 WHERE user_id = ?;
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE  mst_user "]; 
	[updateSql appendString:@"  SET last_work_date = julianday(date(?)) "];
	[updateSql appendString:@"WHERE user_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,[workDate UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,[userID UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}			
		
		stat = YES;
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		stat = NO;
	}
	
	return (stat);

}

// ユーザ情報（マスタ）と施術内容の削除
- (BOOL) deleteUserInfoWorkItems:(USERID_INT)userID
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	// 最初に履歴テーブルより該当ユーザの履歴一覧を取得する
	NSMutableArray* histIDs = [self getHistIdListWithUserID:userID];
	if (! histIDs)
	{	return(NO); }

	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);

#ifdef CLOUD_SYNC
    NSMutableDictionary *buffer = [NSMutableDictionary dictionary];
    // // ユーザIDより姓と名を取得する
    if (! [self getFirstSecondNameWithUserID:userID getBuffer:buffer] )
    {
        //異常終了(ROLLBACKして処理を終了)
        sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        
        //クローズ
        [self closeDataBase];
        
        [histIDs release];
        
        return (NO);
    }
#endif
    
	
	for (id histID in histIDs)
	{
	
		// 先に施術内容を全て削除
		if (! ([self deleteAllWorkItems:histID tableName:@"fc_user_work_item"] &&
			   [self deleteAllWorkItems:histID tableName:@"fc_user_work_item2"] &&
			   [self deleteAllWorkItems:histID tableName:@"fc_user_picture"] &&
			   [self deleteAllWorkItems:histID tableName:@"fc_user_video"] &&
			   [self deleteAllWorkItems:histID tableName:@"fc_user_memo"] &&
			   [self deleteAllWorkItems:histID tableName:@"hist_user_work"]))
		{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//dbをクローズ
			[self closeDataBase];
			
			[histIDs release];
			
			return (NO); 
		}
	}
	
	BOOL stat = YES;
	
	/*
	 DELETE FROM mst_user 
	 WHERE user_id = ? 
	 */
	NSMutableString *delsql = [NSMutableString string];
	[delsql appendString:@"DELETE FROM mst_user"];
	[delsql appendString:@"  WHERE user_id = ? "];	
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [delsql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に施術内容を設定
		sqlite3_bind_text(sqlstmt,1, 
			[[NSString stringWithFormat:@"%d", userID] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			stat = NO;
		}
	}
	else 
	{
	// 構文解析の結果問題あり 
		stat = NO;
	}
	
	if (stat)
	{
#ifdef CLOUD_SYNC
		// 2016/8/16 TMS お客様番号のみ登録時に対応
		// fc_update_mng_time_delete.key_value may not be NULL のため、いずれかの値を設定
		NSString *first_name = [buffer objectForKey:@"first_name"];
		first_name = ((first_name) && ([first_name length] > 0))?
		first_name : [NSString stringWithFormat:@"%ld", (long)userID];
        if ([CloudSyncClientDatabaseUpdate deleteUserWithID:userID
                                                  firstName:first_name
                                                 secondName:[buffer objectForKey:@"second_name"]
                                              sqlite3Object:db] )
        {
            //すべて正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
            stat = NO;
        }
#else	
        
		//すべて正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	[histIDs release];
	
	return (stat);
}

// 履歴IDにて施術関連Itemを全て削除する
- (BOOL) deleteAllWorkItems:(NSString*)histID tableName:(NSString*)tableName
{
	BOOL stat = NO;
	
	/*
	 DELETE FROM fc_user_work_item 
	 WHERE user_id = ? 
	 */
	NSMutableString *delsql = [NSMutableString string];
	[delsql appendFormat:@"DELETE FROM %@ ", tableName];
	[delsql appendString:@"  WHERE hist_id = ?"];

	sqlite3_stmt* sqlstmt;

	if ( sqlite3_prepare_v2(db, [delsql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に新規ユーザの値を設定
		sqlite3_bind_text(sqlstmt,1, [histID UTF8String],-1,SQLITE_TRANSIENT);
		
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//エラーメソッドをコール
			[self errDataBase];
		}
		else 
		{
			stat = YES;
		}
 	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);
}

// 日付とユーザIDよりhist_ID(履歴ID)を作成する
// 引数：userID＝ユーザID date＝日付 isMakeNoRecord＝hist_user_workに該当レコードがない場合に作成するか？
// 戻り値：hist_ID(履歴ID) isMakeNoRecord=NOで -1：存在しない -2:確認失敗   / =YESで <0：作成失敗
- (HISTID_INT) getHistIDWithDateUserID:(USERID_INT)userID workDate:(NSDate*)wDate isMakeNoRecord:(BOOL)isMake
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (-2); }
	}
	
	// 指定日付のレコードが存在するかを確認
	HISTID_INT histID
		= [self getHistIDByDateUserID:userID workDate:wDate]; 
	   
	// 指定日付のレコードが存在しない場合
	if (histID < 0) 
	{
		// 作成しない場合は以降の処理を行わない
		if (isMake) 
		{
			// 新規に指定日付のレコードをfc_user_workに作成
			if (! [self makeNewHistUserworkWithDateUserID:userID workDate:wDate])
			{
				//クローズ
				[self closeDataBase];

				return (-2); 
			}
			
			// 新規作成後に改めて指定日付のhistIDを取得
			histID = [self getHistIDByDateUserID:userID workDate:wDate];
		}
	}
	
	//クローズ
	[self closeDataBase];
	
	return(histID);
}

// ユーザIDと日付よりhistIDを取得
- (HISTID_INT) getHistIDByDateUserID:(USERID_INT)userID workDate:(NSDate*)wDate
{
	HISTID_INT histID = -1;
	
	/*
	 SELECT hist_id FROM hist_user_work 
	   WHERE (user_id = 1) 
	     AND (work_date = julianday(date('2010-12-13')))
	 */
	
	// SQLステートメントの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT hist_id FROM hist_user_work "];
	[selectsql appendString:@"  WHERE (user_id = ?) "];
	[selectsql appendString:@"    AND (work_date = julianday(date(?)))"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		//バインド変数にユーザIDと日付を設定 
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
				[[NSString stringWithFormat:@"%d",userID] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
				[[self makeDateStringByNSDate:wDate] UTF8String],-1,SQLITE_TRANSIENT);
		
		/* NSLog (@"getHistIDByDateUserID sql=> %s",
			   sqlite3_sql(sqlstmt) ); */
		
		if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			histID = sqlite3_column_int(sqlstmt, 0);		
		}
	}
	else 
	{
		NSLog(@"getHistIDByDateUserID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return(histID);
}

// 新規に指定日付のレコードをfc_user_workに作成
- (BOOL) makeNewHistUserworkWithDateUserID:(USERID_INT)userID workDate:(NSDate*)wDate
{
	BOOL isDbOpen = NO;
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
		
		isDbOpen = YES;
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//insert文の作成
	/*
	  INSERT INTO hist_user_work (user_id, work_date)
	    VALUES(1, julianday(date('2010-12-13')))
	 */
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"INSERT INTO hist_user_work (user_id, work_date) "];
	[inssql appendString:@"  VALUES(?, julianday(date(?)))"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数にユーザIDと日付を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
			[[NSString stringWithFormat:@"%d",userID] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
			[[self makeDateStringByNSDate:wDate] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			if (isDbOpen)
			{[self closeDataBase]; }
						
			return (NO);
		}
#ifdef CLOUD_SYNC
        // 事前にhistIDを取得
        HISTID_INT histID = [self getHistIDByDateUserID:userID workDate:wDate];

        if ( ( histID > 0) &&
			([CloudSyncClientDatabaseUpdate newHistMakeWithID:histID
													   userID:userID
													 workDate:wDate
												sqlite3Object:db] ) )
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        }
#else	
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);

	// このメソッド内でDBをOPENした場合はクローズする
	if (isDbOpen)
	{
		//クローズ
		[self closeDataBase];
	}
	
	return(stat);
}

// 履歴用のユーザ写真を追加:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) insertHistUserPicture:(HISTID_INT)histID pictureURL:(NSString*)url
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//inserte文の作成
	/*
	 INSERT INTO fc_user_picture (hist_id, picture_url)
	   VALUES(1, 'Documents/User00000001/101101_100333.jpg');
	 */
	NSMutableString *insertSql = [NSMutableString string];
	[insertSql appendString:@"INSERT INTO fc_user_picture (hist_id, picture_url)"]; 
	[insertSql appendString:@"  VALUES(?, ?)"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [insertSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に履歴IDとurlの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%d", histID] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,[url UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
#ifdef CLOUD_SYNC
        if ([CloudSyncClientDatabaseUpdate savePictureWiithID:histID
                                                      pitureUrl:url
                                                  sqlite3Object:db] )
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        }
#else
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
	
}

// 代表画像が設定されているかを確認する [戻り値　<0:失敗 =0:設定なし >0:設定あり]
- (NSInteger) isHeadPicureExist:(HISTID_INT)histID
{
	NSInteger isExsist = -1;
	
	// select文の作成
	/*
	 SELECT head_picture_url
	   FROM hist_user_work 
	    WHERE hist_id = 1
	 */
	
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT head_picture_url "];
	[selectsql appendString:@"  FROM hist_user_work"];
	[selectsql appendString:@"   WHERE hist_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		sqlite3_bind_text(sqlstmt,1,
			[[NSString stringWithFormat:@"%d", histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		isExsist = 0;
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			NSString *url = [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0];
			
			isExsist = ([url length] > 0)? 1 : 0;
		}			
	}
	else 
	{
		NSLog(@"isHeadPicureExist error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);	
	
	
	return (isExsist);
}

// 代表画像を取得する
- (NSString*) getHeadPicureExist:(HISTID_INT)histID
{
	NSString *headPicture = nil;
	
	// select文の作成
	/*
	 SELECT head_picture_url
	 FROM hist_user_work 
	 WHERE hist_id = 1
	 */
	
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT head_picture_url "];
	[selectsql appendString:@"  FROM hist_user_work"];
	[selectsql appendString:@"   WHERE hist_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);

		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d", histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			headPicture= [self makeSqliteStmt2String:sqlstmt index:(NSUInteger)0];
			NSLog(@"HEAD PICTURE %@",headPicture);
		}			
	}
	else 
	{
		NSLog(@"getHeadPicureExist error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
		// return (histUserItems);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);	
	
	
	return (headPicture);
}

// 履歴テーブル(hist_user_work)の代表画像の更新:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) updateHistHeadPicture:(HISTID_INT)histID
					pictureURL:(NSString*)url
			   isEnforceUpdate:(BOOL)isEnforce
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	// 先に代表画像が設定されているかを確認する [戻り値　<0:失敗 =0:設定なし >0:設定あり]
	NSInteger exist = [self isHeadPicureExist:histID];
	if ( exist < 0)
	{
	// 確認失敗
		//クローズ
		[self closeDataBase];		
		return (NO);
	}
	if (( exist > 0) && (!isEnforce) )
	{
	// 設定していて、かつ強制更新の指定のない場合は、何もしない
		//クローズ
		[self closeDataBase];		
		return (YES);
	}
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//update文の作成
	/*
	 UPDATE hist_user_work 
	   SET head_picture_url = 'Documents/User00000001/101101_100333.jpg'
	     WHERE hist_id = 1
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE  hist_user_work"]; 
	[updateSql appendString:@" SET head_picture_url = ? "];
	[updateSql appendString:@"   WHERE hist_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に履歴IDとurl値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,(url)? [url UTF8String] : NULL,-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
				[[NSString stringWithFormat:@"%d", histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
#ifdef CLOUD_SYNC
        if ([CloudSyncClientDatabaseUpdate setHistPictureWithID:histID
                                                  sqlite3Object:db] )
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        }
#else		
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
	
}

- (BOOL) deleteHistHeadPicture:(NSString*)oridinalUrl pictureURL:(NSString*)url
{
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	HISTID_INT histID = [self getHistIDByPictURL:oridinalUrl];
	
	//delete文の作成
	/*
	 DELETE FROM fc_user_picture
	 WHERE picture_url='test.jpg' AND hist_id=1
	 */
	NSMutableString *deleteSql = [NSMutableString string];
	[deleteSql appendString:@"DELETE FROM hist_user_work"];
	[deleteSql appendString:@"  WHERE head_picture_url=?"];
	if (histID != HISTID_INTMIN)
	{
		[deleteSql appendString:@" AND hist_id=?"];
	}
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [deleteSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に履歴IDとurlの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,[url UTF8String],-1,SQLITE_TRANSIENT);
		if (histID != HISTID_INTMIN)
		{
			sqlite3_bind_text(sqlstmt,idx++,
							  [[NSString stringWithFormat:@"%d", histID] UTF8String],-1,SQLITE_TRANSIENT);
		}
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
		
#ifdef CLOUD_SYNC
		if ([CloudSyncClientDatabaseUpdate deletePictureWiithID:histID
													  pitureUrl:url
												  sqlite3Object:db] )
		{
			//正常終了(COMMITをして処理を終了)
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
			stat = YES;
		}
		else
		{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		}
#else
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
}

// 履歴テーブル(hist_user_work)の代表画像の元urlによる更新:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) updateHistHeadPictureByNewUrl:(NSString*)oridinalUrl newUrl:(NSString*)url
{
	// 元urlがnilの場合は、何もしない（レコードが特定できないため）
	if (! oridinalUrl)
	{ return (YES); }
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
#ifdef CLOUD_SYNC
    // 事前に履歴IDを取得しておく
    HISTID_INT histID = [self getHistIDByPictURL:oridinalUrl];
#endif
	// 拡張子を除くurlで確認する
	NSString *noSuffix = [oridinalUrl substringToIndex:[oridinalUrl length] - 3];
    
	//update文の作成
	/*
	 UPDATE hist_user_work 
	   SET head_picture_url=Null 
	 WHERE hist_id =
	   (SELECT hist_id FROM hist_user_work 
	      WHERE head_picture_url = '001115.jpg')
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendString:@"UPDATE  hist_user_work"]; 
	[updateSql appendString:@" SET head_picture_url = ? "];
	[updateSql appendString:@"WHERE hist_id = "];
	[updateSql appendString:@"  (SELECT hist_id FROM hist_user_work "];
	//LIKEにバインド変数は使用できない
	[updateSql appendFormat:@"     WHERE head_picture_url LIKE '%@%%')", noSuffix];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に履歴IDとurl値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
						  ((url)? [url UTF8String] : NULL), -1,SQLITE_TRANSIENT);
//		sqlite3_bind_text(sqlstmt,idx++, [oridinalUrl UTF8String], -1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
#ifdef CLOUD_SYNC
        // 変更があったかを確認する
        if (histID > 0)
        {
            if ([CloudSyncClientDatabaseUpdate setHistPictureWithID:histID
                                                      sqlite3Object:db] )
            {
                //正常終了(COMMITをして処理を終了)
                sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
                stat = YES;
            }
            else
            {
                //異常終了(ROLLBACKして処理を終了)
                sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
            }
        }
        else
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
#else
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
}

// 履歴用のユーザ写真を削除:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) deleteHistUserPicture:(HISTID_INT)histID pictureURL:(NSString*)url
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
#ifdef CLOUD_SYNC
    if (histID == HISTID_INTMIN)
    {
        // サムネイル一覧などからのコールで履歴IDが不明な場合は、ここで取得する
        histID = [self getHistIDByPictURL4PictTable:url];
    }
#endif
    
	//delete文の作成
	/*
	 DELETE FROM fc_user_picture 
	   WHERE picture_url='test.jpg' AND hist_id=1
	 */
	NSMutableString *deleteSql = [NSMutableString string];
	[deleteSql appendString:@"DELETE FROM fc_user_picture"]; 
	[deleteSql appendString:@"  WHERE picture_url=?"];
	if (histID != HISTID_INTMIN)
	{
		[deleteSql appendString:@" AND hist_id=?"];
	}
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [deleteSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に履歴IDとurlの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,[url UTF8String],-1,SQLITE_TRANSIENT);
		if (histID != HISTID_INTMIN)
		{
			sqlite3_bind_text(sqlstmt,idx++,
							  [[NSString stringWithFormat:@"%d", histID] UTF8String],-1,SQLITE_TRANSIENT);
		}
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
        
#ifdef CLOUD_SYNC
        if ([CloudSyncClientDatabaseUpdate deletePictureWiithID:histID
                                                      pitureUrl:url
                                                  sqlite3Object:db] )
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        }
#else	
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
}
// 履歴用のユーザ動画を削除:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) deleteHistUserVideo:(HISTID_INT)histID videoURL:(NSString*)url
{
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
#ifdef CLOUD_SYNC
    if (histID == HISTID_INTMIN)
    {
        // サムネイル一覧などからのコールで履歴IDが不明な場合は、ここで取得する
        histID = [self getHistIDByVideoURL4PictTable:url];
    }
#endif
    
	//delete文の作成
	/*
	 DELETE FROM fc_user_picture
     WHERE picture_url='test.jpg' AND hist_id=1
	 */
	NSMutableString *deleteSql = [NSMutableString string];
	[deleteSql appendString:@"DELETE FROM fc_user_video"];
	[deleteSql appendString:@"  WHERE video_url=?"];
	if (histID != HISTID_INTMIN)
	{
		[deleteSql appendString:@" AND hist_id=?"];
	}
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [deleteSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に履歴IDとurlの値を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,[url UTF8String],-1,SQLITE_TRANSIENT);
		if (histID != HISTID_INTMIN)
		{
			sqlite3_bind_text(sqlstmt,idx++,
							  [[NSString stringWithFormat:@"%d", histID] UTF8String],-1,SQLITE_TRANSIENT);
		}
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			
			return (NO);
		}
        
#ifdef CLOUD_SYNC
        if ([CloudSyncClientDatabaseUpdate deleteVideoWithID:histID
                                                    videoUrl:url
                                               sqlite3Object:db] )
        {
            //正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        }
#else
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
}
// 履歴用のユーザ写真リストの取得
- (BOOL) getHistPictureUrls:(fcUserWorkItem*)workItem
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	// 既に入っている写真リストをクリアする
	if ( workItem.picturesUrls)
	{	[workItem.picturesUrls removeAllObjects]; }
	else 
	{
		workItem.picturesUrls = [ [NSMutableArray alloc] init];
		[workItem.picturesUrls retain];
	}

	// 写真リストの設定
	[self setPictureUrls:workItem];
    /*
    // 既に入っている動画リストをクリアする
	if ( workItem.videosUrls)
	{
        [workItem.videosUrls removeAllObjects];
    }
	else
	{
		workItem.videosUrls = [ [NSMutableArray alloc] init];
		[workItem.videosUrls retain];
	}
	// 写真リストの設定
	[self setVideoUrls:workItem];
    //<<<<
     */
	// 代表画像を取得する
	workItem.headPictureUrl = [self getHeadPicureExist:workItem.histID];
		
	//クローズ
	[self closeDataBase];
	
	return (stat);
}
// 履歴用のユーザ写真リストの取得
- (BOOL) getHistVideoUrls:(fcUserWorkItem*)workItem
{
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	BOOL stat = NO;
	
	// 既に入っている写真リストをクリアする
	if ( workItem.videosUrls)
	{	[workItem.videosUrls removeAllObjects]; }
	else
	{
		workItem.videosUrls = [ [NSMutableArray alloc] init];
		[workItem.videosUrls retain];
	}
    
	// 写真リストの設定
	[self setVideoUrls:workItem];
	
	// 代表画像を取得する
	// workItem.headPictureUrl = [self getHeadPicureExist:workItem.histID];
    
	//クローズ
	[self closeDataBase];
	
	return (stat);
}
// データベースより履歴（とその関連情報）の削除
- (BOOL) deleteHistWithHistID:(HISTID_INT)histID
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	// histIDの文字列
	NSString *hID = [NSString stringWithFormat:@"%d", histID];
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
#ifdef CLOUD_SYNC
    NSMutableDictionary *buffer = [NSMutableDictionary dictionary];
    // 履歴IDよりユーザIDと更新日付を取得する
    if (! [self getUserIDWorkDateWithHistID:histID getBuffer:buffer] )
    {
        //異常終了(ROLLBACKして処理を終了)
        sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);

        //クローズ
        [self closeDataBase];
        
        return (NO);
    }
#endif
	
	// 施術内容、履歴写真、メモと最後に履歴テーブル本体を該当履歴IDで削除する
	if (! ([self deleteAllWorkItems:hID tableName:@"fc_user_work_item"] &&
		   [self deleteAllWorkItems:hID tableName:@"fc_user_work_item2"] &&
		   [self deleteAllWorkItems:hID tableName:@"fc_user_picture"] &&
		   [self deleteAllWorkItems:hID tableName:@"fc_user_video"] && // DELC SASAGE
		   [self deleteAllWorkItems:hID tableName:@"fc_user_memo"] &&
		   [self deleteAllWorkItems:hID tableName:@"hist_user_work"]))
	{
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	else 
	{
#ifdef CLOUD_SYNC
        if ([CloudSyncClientDatabaseUpdate deleteHistWithID:histID
                                                     userID:[[buffer objectForKey:@"user_id"] intValue]  
                                                   workDate:[buffer objectForKey:@"work_date"]
                                                deletePicts:[buffer objectForKey:@"delete_pictrues"]
                                                sqlite3Object:db] )
        {
            //すべて正常終了(COMMITをして処理を終了)
            sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
            stat = YES;
        }
        else
        {
            //異常終了(ROLLBACKして処理を終了)
            sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
        }
#else
		//すべて正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	
	//クローズ
	[self closeDataBase];
	
	return (stat);
}

// 施術マスタの更新：editedTableは更新分のみで、key=ID object=施術内容（文字列）となる
- (BOOL) updateWorkItemMstWithEditedTable:(NSMutableDictionary*)editedTable
								tableName:(NSString *)tableName
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//update文の作成
	/*
	 UPDATE mst_user_work_item
	   SET work_item_name = ?
	 WHERE work_item_id = ?
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendFormat:@"UPDATE %@", tableName];
	[updateSql appendString:@"  SET work_item_name = ? "];
	[updateSql appendString:@" WHERE work_item_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
	// 構文解析の結果問題なし
		
		// tableをイテレートする
		for (NSString* key in [editedTable allKeys])
		{
			//sqlをリセット
			sqlite3_reset(sqlstmt);
			//バインド変数をクリアー
			sqlite3_clear_bindings(sqlstmt);
			
			// バインド変数に新規ユーザの値を設定
			u_int idx = 1;
			sqlite3_bind_text(sqlstmt,idx++,
							  [((NSString*)[editedTable objectForKey:key]) UTF8String],-1,SQLITE_TRANSIENT);
			sqlite3_bind_text(sqlstmt,idx++,[key UTF8String],-1,SQLITE_TRANSIENT);
						
			//sql文を実行してエラーが発生した場合はクローズさせて終了
			if(sqlite3_step(sqlstmt) != SQLITE_DONE)
			{
				//sql文の解放
				sqlite3_finalize(sqlstmt);
				//異常終了(ROLLBACKして処理を終了)
				sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
				//エラーメソッドをコール
				[self errDataBase];
				//dbをクローズ
				[self closeDataBase];
				
				return (NO);
			}
		}
		
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
	}
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return(stat);
	
}

// 施術内容の文字列一覧の取得
- (void) getWorkItemListWithWorkItem:(fcUserWorkItem*)workItem
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return ; }
	}
	
	// 施術内容（文字と数値)のリセット
	// [workItem resetWorkItemList];
	workItem.workItemListString = [NSMutableString string];
	[workItem.workItemListNumber removeAllObjects];
	
	// 施術内容の文字列一覧の設定
	[self setWorkItemList:workItem];
	
	// 施術内容の文字列一覧の取得
	workItem.workItemStrings = [self getWorkItemStrings:ITEM_EDIT_USER_WORK1_TABLE];
	
	//クローズ
	[self closeDataBase];

}

// 施術内容2の文字列一覧の取得
- (void) getWorkItemListWithWorkItem2:(fcUserWorkItem*)workItem
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return ; }
	}
	
	// 施術内容（文字と数値)のリセット
	// [workItem resetWorkItemList];
	workItem.workItemListString2 = [NSMutableString string];
	[workItem.workItemListNumber2 removeAllObjects];
	
	// 施術内容の文字列一覧の設定
	[self setWorkItemList2:workItem];
	
	// 施術内容の文字列一覧の取得
	workItem.workItemStrings2 = [self getWorkItemStrings:ITEM_EDIT_USER_WORK2_TABLE];
	
	//クローズ
	[self closeDataBase];
	
}

#pragma mark item_edit_tables

// 履歴IDに該当する項目名一覧の取得: key -> orderNum   value -> itemName
- (NSDictionary*) getItemNamesByHistID:(HISTID_INT)histID itemEditKind:(ITEM_EDIT_KIND)editKind
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (nil); }
	}
	
	NSMutableDictionary *itemNames = nil;

	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendFormat:@"SELECT item_name,	%@", ITEM_EDIT_ORDER_FIELD];
	[selectsql appendFormat:@"  FROM %@", [self getFcTableNameWithItemEditKind:editKind] ];
	[selectsql appendString:@"    WHERE hist_id = ? "];
	[selectsql appendFormat:@"      ORDER BY %@", ITEM_EDIT_ORDER_FIELD];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		sqlite3_bind_text(sqlstmt,1,
						  [[NSString stringWithFormat:@"%d", histID] UTF8String],-1,SQLITE_TRANSIENT);
		
		itemNames = [NSMutableDictionary dictionary];
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			[itemNames setObject:[ self makeSqliteStmt2String:sqlstmt index:0] 
						  forKey:[NSString stringWithFormat:@"%d", 
									sqlite3_column_int(sqlstmt, (NSUInteger)1)]];
		}			
	}
	else 
	{
		NSLog(@"getItemNamesByHistID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);		
	
	//クローズ
	[self closeDataBase];
	
	return (itemNames);
}

// 挿入したitemのIDを取得
- (WORKITEM_INT) _getWorkItemMaxWithEdidKind:(ITEM_EDIT_KIND)editKind
{
    WORKITEM_INT maxID = WORKID_INTMIN;
    
    NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT MAX(work_item_id) "];
	[selectsql appendFormat:@"  FROM %@", [self getTableNameWithItemEditKind:editKind]];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
        
        if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			maxID = sqlite3_column_int(sqlstmt, (NSUInteger)0);
		}			
	}
	else 
	{
		NSLog(@"_getWorkItemMaxWithEdidKind error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);	
    
    return (maxID);
}

// 定型メモ内容を取得
- (NSString*) _getWorkItemNameWithID:(WORKITEM_INT)itemID editItemKind:(ITEM_EDIT_KIND)editKind
{
    NSString* itemName = nil;
    
    NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT work_item_name "];
	[selectsql appendFormat:@"  FROM %@", [self getTableNameWithItemEditKind:editKind] ];
	[selectsql appendString:@"    WHERE work_item_id = ? "];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		sqlite3_bind_int(sqlstmt,1,itemID);
        
		if (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			itemName = [ self makeSqliteStmt2String:sqlstmt index:0];
            [itemName autorelease];
		}			
	}
	else 
	{
		NSLog(@"_getWorkItemNameWithID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);		
    
    return (itemName);
}

// 項目マスタテーブルよりitemを削除
- (BOOL) itemEditTableDeleteWithItemIDList:(NSArray*)itemIDList itemEditKind:(ITEM_EDIT_KIND)editKind
{
	// データベースが閉じている場合はErrorとする
	if (db == nil) 
	{
		return (NO);
	}
    
	BOOL stat = NO;
	
	NSMutableString *delsql = [NSMutableString string];
	[delsql appendFormat:@"DELETE FROM %@ ",[self getTableNameWithItemEditKind:editKind]  ];
	[delsql appendString:@"  WHERE work_item_id = ? "];	
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [delsql UTF8String], -1, &sqlstmt, NULL)
			== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		for (NSString *IDs in itemIDList)
		{
#ifdef CLOUD_SYNC
            //　削除前にメモ内容を取得
            NSString *itemName 
                = [self _getWorkItemNameWithID:[IDs intValue] editItemKind:editKind];
            if (! itemName)
            {   
                NSLog(@"itemEditTableDeleteWithItemIDList : work item name is empty: %@", IDs);
                continue; 
            }
#endif
            
            //sqlをリセット
			sqlite3_reset(sqlstmt);
			//バインド変数をクリアー
			sqlite3_clear_bindings(sqlstmt);
			
			// バインド変数にIDを設定
			u_int idx = 1;
			sqlite3_bind_text(sqlstmt,idx++, [IDs UTF8String],-1,SQLITE_TRANSIENT);
			
			if(sqlite3_step(sqlstmt) != SQLITE_DONE)
			{
				//エラーメソッドをコール
				// [self errDataBase];
				
				stat = NO;
				break;
			}
#ifdef CLOUD_SYNC
            // 定型メモマスタを更新時削除テーブルに追加
            [CloudSyncClientDatabaseUpdate deleteWorkItemMakeWithID:[IDs intValue]
                                                         memoKind:(editKind == ITEM_EDIT_USER_WORK1)? USER_WORK_ITEM_1 : USER_WORK_ITEM_2 
                                                     workItemName:itemName
                                                    sqlite3Object:db];
#endif
		}
	}
	else 
	{
		//エラーメソッドをコール
		// [self errDataBase];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);	
	
}
// 項目マスタテーブルよりitemを更新 key => itemID value => name
- (BOOL) itemEditTableUpdateWithItemList:(NSDictionary*)itemList itemEditKind:(ITEM_EDIT_KIND)editKind
{
	// データベースが閉じている場合はErrorとする
	if (db == nil) 
	{
		return (NO);
	}
	
	BOOL stat = NO;
	
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendFormat:@"UPDATE %@ ", [self getTableNameWithItemEditKind:editKind]]; 
	[updateSql appendString:@" SET work_item_name = ? "];
	[updateSql appendString:@"   WHERE work_item_id = ?"];	
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		NSArray *ids = [itemList allKeys];
		for (NSString *itemID in ids)
		{
			//sqlをリセット
			sqlite3_reset(sqlstmt);
			//バインド変数をクリアー
			sqlite3_clear_bindings(sqlstmt);
			
			// バインド変数にIDを設定
			u_int idx = 1;
			sqlite3_bind_text(sqlstmt,idx++, [[itemList objectForKey:itemID] UTF8String],-1,SQLITE_TRANSIENT);
			sqlite3_bind_text(sqlstmt,idx++, [itemID UTF8String],-1,SQLITE_TRANSIENT);
			
			if(sqlite3_step(sqlstmt) != SQLITE_DONE)
			{
				//エラーメソッドをコール
				// [self errDataBase];
				
				stat = NO;
				break;
			}
			
#ifdef CLOUD_SYNC
            // 定型メモマスタを更新時削除テーブルに追加
            [CloudSyncClientDatabaseUpdate editWorkItemMakeWithID:[itemID intValue]
                                                         memoKind:(editKind == ITEM_EDIT_USER_WORK1)? USER_WORK_ITEM_1 : USER_WORK_ITEM_2 
                                                     workItemName:[itemList objectForKey:itemID]
                                                    sqlite3Object:db];
#endif
		}
	}
	else 
	{
		//エラーメソッドをコール
		// [self errDataBase];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);	
}

// 項目マスタテーブルよりitemを挿入
- (BOOL) itemEditTableInsertWithNameList:(NSArray*)nameList itemEditKind:(ITEM_EDIT_KIND)editKind
{
	// データベースが閉じている場合はErrorとする
	if (db == nil) 
	{
		return (NO);
	}
	
	BOOL stat = NO;
	
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendFormat:@"INSERT INTO %@ (work_item_name) ", [self getTableNameWithItemEditKind:editKind]];
	[inssql appendString:@"  VALUES(?)"];	
	
	sqlite3_stmt* sqlstmt;
	
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		stat = YES;
		
		for (NSString *name in nameList)
		{
			//sqlをリセット
			sqlite3_reset(sqlstmt);
			//バインド変数をクリアー
			sqlite3_clear_bindings(sqlstmt);
			
			// バインド変数にIDを設定
			u_int idx = 1;
			sqlite3_bind_text(sqlstmt,idx++, [name UTF8String],-1,SQLITE_TRANSIENT);
			
			if(sqlite3_step(sqlstmt) != SQLITE_DONE)
			{
				//エラーメソッドをコール
				// [self errDataBase];
				
				stat = NO;
				break;
			}
#ifdef CLOUD_SYNC
            // 挿入したitemのIDを取得
            WORKITEM_INT maxID = [self _getWorkItemMaxWithEdidKind:editKind];
            if (maxID == WORKID_INTMIN)
            {   continue; }     // 取得エラーでも継続
            
            // 定型メモの種別
            USER_WORK_ITEM_KIND itemKind =
                (editKind == ITEM_EDIT_USER_WORK1)? USER_WORK_ITEM_1 : USER_WORK_ITEM_2;
            // 定型メモマスタを更新時削除テーブルに追加
            [CloudSyncClientDatabaseUpdate newWorkItemMakeWithID:maxID 
                                                        memoKind:itemKind workItemName:name
                                                   sqlite3Object:db];
#endif
		}
	}
	else 
	{
		//エラーメソッドをコール
		// [self errDataBase];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);	
}

// お客様総数など現在の状況を取得する
- (NSDictionary*) getAllUsersNumNowState
{
	NSDictionary* stateTable 
		= [self _simpleOpenCloseTemplateWithArg:nil
							 procHandler: ^id (id args)
		   {
			   //　ユーザテーブルの行数を取得
			   NSUInteger userNums = [self getTableRowsCount:@"mst_user" IDname:@"user_id"];
			   //　ユーザ写真テーブルの行数を取得
			   NSUInteger pictureNums = [self getTableRowsCount:@"fc_user_picture" IDname:@"hist_id"];
			   //　履歴テーブルの行数を取得
			   NSUInteger histNums = [self getTableRowsCount:@"hist_user_work" IDname:@"hist_id"];
			   
			   
			   NSDictionary* table = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithLong:userNums], @"user_nums",
										[NSNumber numberWithLong:pictureNums], @"picture_nums",
										[NSNumber numberWithLong:histNums], @"hist_nums", nil];
			   return (table);
		   }];
	
	return (stateTable);
			
}

#pragma mark database_maintenace

-(void) insertRecord: (NSString *) tableName
		   withField: (NSString *) field1
		 field1Value: (NSString *) field1Value
		  withField2: (NSString *) field2
		 field2Value: (NSString *) field2Value
		  withField3: (NSString *) field3
		 field3Value: (NSString *) field3Value
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return; }
	}
	NSString *sql = [NSString stringWithFormat:
					 @"INSERT OR REPLACE INTO '%@' ('%@','%@','%@') VALUES('%@','%@','%@')"
					 , tableName, field1, field2, field3, field1Value, field2Value, field3Value];
	char *err;
	if(sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err)!= SQLITE_OK)
	{
		[self closeDataBase];
		NSLog(@"Error updateing table");
	}
}

- (BOOL) createTableMemo2
{
	sqlite3  *dbx;
	NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [paths objectAtIndex:0];
	NSString *filePath = [documentsDir stringByAppendingPathComponent:DB_FILE_NAME];
	
	if(sqlite3_open([filePath UTF8String], &dbx) != SQLITE_OK)
	{
		sqlite3_close(dbx);
		NSLog(0, @"database failed to open");
		return NO;
	}
	char *err;
	NSString *sql = [NSString alloc];
	sql = @"CREATE TABLE IF NOT EXISTS mst_user_work_item2 ('work_item_id' INT PRIMARY KEY, 'work_item_name' TEXT, 'item_edit' TEXT);";
	if(sqlite3_exec(dbx, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK)
	{
		sqlite3_close(dbx);
		NSLog(0, @"Tabled failed to create. mst_user_work_item2");
		//NSLog(@"table failed to create");
		return NO;
	}
	else 
	{
		NSInteger rowCount = 0;
		sql = @"SELECT * FROM mst_user_work_item2";
		sqlite3_stmt *statement;
		if(sqlite3_prepare_v2(dbx, [sql UTF8String], -1, &statement, nil) == SQLITE_OK)
		{
			while (sqlite3_step(statement) == SQLITE_ROW) 
			{
				rowCount = rowCount +1;
			}
		}
		if(rowCount <=0)
		{
			//insert record
			for (int i=1; i<=9; i++) 
			{
				NSString *data1 = [[NSString alloc] initWithFormat:@"%d",i];
				NSString *data2 = [NSString alloc];
				switch (i) {
					case 1:
						data2 = @"カット";
						break;
					case 2:
						data2 = @"パーマ";
						break;
					case 3:
						data2 = @"縮毛矯正";
						break;
					case 4:
						data2 = @"シャンプー";
						break;
					case 5:
						data2 = @"リンス";
						break;
					case 6:
						data2 = @"トリートメント";
						break;
					case 7:
						data2 = @"スタイリング";
						break;
					case 8:
						data2 = @"カラー";
						break;
					case 9:
						data2 = @"ヘッドスパ";
						break;
					default:
						data2 = @"";
						break;
				}
				NSString *data3 = @"-";
				sql = [NSString stringWithFormat:
					   @"INSERT OR REPLACE INTO '%@' ('%@','%@','%@') VALUES('%@','%@','%@')"
					   , @"mst_user_work_item2", @"work_item_id", @"work_item_name", @"item_edit", 
					   data1, data2, data3];
                [data1 release];
				[data2 release];
				char *err;
				if(sqlite3_exec(dbx, [sql UTF8String], NULL, NULL, &err)!= SQLITE_OK)
				{
					NSLog(@"Error updateing table. mst_user_work_item2 %@",[NSString stringWithUTF8String:err]);
					sqlite3_close(dbx);
                    [sql release];
					return NO;
				}
			}
		}
	}
	sql = @"CREATE TABLE IF NOT EXISTS 'fc_user_work_item2' ('hist_id' INT, 'work_item_id' INT,'create_date' TEXT)";
	if(sqlite3_exec(dbx, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK)
	{
		sqlite3_close(dbx); 
		NSLog(0, @"Tabled failed to create. fc_user_work_item2");
		//NSLog(@"table failed to create");
        [sql release];

		return NO;
	}
	sqlite3_close(dbx);
	dbx = nil;
    [sql release];

	return YES;
}
- (BOOL)createFcUserVideoTableMake
{
	BOOL stat = NO;
	if (db == nil)
	{
		if (! [self dataBaseOpen4Transaction])
		{  return (NO); }
	}

	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'fc_user_video' "];
	[ pragmaSql appendString:@"  ('hist_id' INTEGER, "];
	[ pragmaSql appendString:@"   'video_url' STRING,"];
	[ pragmaSql appendString:@"   'video_title' TEXT, "];
	[ pragmaSql appendString:@"   'video_comment' TEXT, "];
	[ pragmaSql appendString:@"   'status' INTEGER, "];
	[ pragmaSql appendString:@"   'overlay' INTEGER)"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	[self dataBaseClose2TransactionWithState:stat];
	
	return (stat);
}

//check
- (BOOL) checkExistTableMemo2
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	//トランザクションの開始
	
	
	NSString *sql = [[NSString alloc] init];
	sqlite3_stmt* sqlstmt;
	int rowCount = 0;
	char *err;
	//sql = @"SELECT name FROM sqlite_master WHERE name='mst_user_work_item2'";
	
	sql = @"CREATE TABLE IF NOT EXISTS 'mst_user_work_item2' ('work_item_id' INT PRIMARY KEY, 'work_item_name' TEXT,'item_edit' TEXT)";	
	if ( sqlite3_prepare_v2(db, [sql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		stat = YES;
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
		for (int i=0; i<=8; i++) 
		{
			NSString *data1 = [[NSString alloc] initWithFormat:@"%d",i];
			NSString *data2 = @"-";
			NSString *data3 = @"-";
			//[self insertRecord: @"mst_user_work_item2" withField:@"work_item_id" field1Value: data1 withField2:@"work_item_name" field2Value:data2 withField3:@"item_edit" field3Value:data3];
			sql = [NSString stringWithFormat:
				   @"INSERT OR REPLACE INTO 'mst_user_work_item2' ('work_item_id','work_item_name','item_edit') VALUES('%@','%@','%@')"
				   , data1, data2, data3];
			if(sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err)!= SQLITE_OK)
			{
				stat = NO;
				i = 8;
			}
			[data1 release];
			/*[data2 release];
			[data3 release];*/
		}
		if(stat)
		{
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		}
		else
		{
			// データベースエラーのLog表示
			[self errDataBaseWriteLog];
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			stat = NO;
		}
		/*
		stat = YES;
		sql = @"SELECT * FROM mst_user_work_item2";
		if ( sqlite3_prepare_v2(db, [sql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
		{
			while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
			{
				rowCount = rowCount + 1;
			}
		}
		 */
		if(![self checkExistColumnWithTableName:@"mst_user_work_item2" columnName:@"work_item_id" isColumnMake:YES columnType:@"INTEGER"])
		{
			NSLog(@"Failed check table with column");
		}
		if(rowCount <= 0) 
		{
			//sqlをリセット
		}
	}
	
	//fc_user_work_item2
	sqlite3_reset(sqlstmt);
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	sql = @"CREATE TABLE IF NOT EXISTS 'fc_user_work_item2' ('hist_id' INT, 'work_item_id' INT,'create_date' TEXT)";
	if ( sqlite3_prepare_v2(db, [sql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		stat = YES;
	}
	else 
	{
		stat = NO;
	}

	
	if (stat)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
    [sql release];
	return (stat);

}
// 指定テーブル名で列名の存在を確認 : isColumnMake = 存在しない場合は、列を追加する
- (BOOL) checkExistColumnWithTableName:(NSString*)tableName columnName:(NSString*)colName
						  isColumnMake:(BOOL)isMake columnType:(NSString*)type
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	
	//SQL(table_info)文の作成:PRAGMAはバインド変数は使用できない
	NSString *pragmaSql 
		= [NSString stringWithFormat: @"PRAGMA table_info(%@)", tableName];
		
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
						
		BOOL isFind = NO;
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// 取得したrowからテーブル情報を取得:2列目が列名情報
			NSString *rowName = [self makeSqliteStmt2String:sqlstmt index:1];
			
			// 列名を確認
			if ((rowName) && ([rowName isEqualToString:colName]) )
			{
				// 指定列名は存在している
				stat = isFind = YES;
				break;
			}
		}
		
		if( ! isFind)
		{
			// 指定列名は存在しない
			if (isMake)
			{
				// 列が存在しない場合は追加する
				stat = [self addColumnWithTable:tableName columnName:colName columnType:type];
			}
			else 
			{
				//列名の存在確認のみなので正常終了とする
				stat = YES;
			}
		}
			
		if (stat)
		{
			//正常終了(COMMITをして処理を終了)
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		}
		else 
		{
			// データベースエラーのLog表示
			[self errDataBaseWriteLog];
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		}
		// stat = YES;
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (stat);
}

// 該当するitemIDで名前を設定する
- (BOOL) setItemNameWithItemID:(WORKITEM_INT)itemID
                        histID:(HISTID_INT)histID
                      orderNum:(NSUInteger)order
                  mstTableName: (NSString*)mstTblName
                   fcTableName:(NSString*)fcTblName
{
	BOOL stat = YES;
	
	// update文
	/*
	 UPDATE fc_user_work_item 
	  SET item_name = 
	    (SELECT mst_user_work_item.work_item_name 
	       FROM mst_user_work_item 
	         WHERE mst_user_work_item.work_item_id = 9),
	      order_num = 1
	 WHERE (hist_id = 8 AND work_item_id = 9);
	 */
	NSMutableString *updateSql = [NSMutableString string];
	[updateSql appendFormat:@"UPDATE %@ ", fcTblName]; 
	[updateSql appendFormat:@" SET %@ =", ITEM_EDIT_NAME_FIELD];
	[updateSql appendFormat:@"   (SELECT %@.work_item_name ", mstTblName];
	[updateSql appendFormat:@"      FROM %@ ", mstTblName];
	[updateSql appendFormat:@"        WHERE %@.work_item_id = ?), ", mstTblName];
	[updateSql appendFormat:@"     %@ = ? ", ITEM_EDIT_ORDER_FIELD];
	[updateSql appendFormat:@" WHERE (hist_id = ? AND work_item_id = ? ) "];
	
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[updateSql UTF8String],-1,&sqlstmt,NULL) 
			== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数に値を設定
		u_int idx = 1;
		sqlite3_bind_int(sqlstmt, idx++, itemID);
		sqlite3_bind_int(sqlstmt, idx++, (int)order);
		sqlite3_bind_int(sqlstmt, idx++, histID);
		sqlite3_bind_int(sqlstmt, idx++, itemID);
		
		if  (sqlite3_step(sqlstmt) != SQLITE_DONE) 
		{
			NSLog(@"setItemNameWithItemID error at %@",
				  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
			stat = NO;
		}			
	}
	else 
	{
		NSLog(@"setItemNameWithItemID error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);
}

// itemIDからitemNameへと変換する
- (BOOL) convertID2Name:(NSString*)mstTblName  fcTableName:(NSString*)fcTblName
{
	BOOL stat = YES;
	
	// 状態テーブルから全てのitem_idを取得する
	NSString *selectsql 
		= [NSString stringWithFormat:@"SELECT hist_id, work_item_id FROM %@ ORDER BY hist_id", fcTblName];
	sqlite3_stmt* sqlstmt;
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		// histIDごとの順番テーブル
		NSMutableDictionary *histIDs = [NSMutableDictionary dictionary];
		NSUInteger orderNum = 0;
				
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			HISTID_INT histID = sqlite3_column_int(sqlstmt, 0);
			NSString *hID = [NSString stringWithFormat:@"%d", histID];
			
			// histIDが順番テーブルにあるか？
			if (! [histIDs objectForKey:hID] )	// ない場合は、順番を初期化
			{	orderNum = 0; }
			[histIDs setObject:[NSString stringWithFormat:@"%d", (int)orderNum]
						forKey:hID];
						
			// 該当するIDで名前を設定する
			if (! [self setItemNameWithItemID:sqlite3_column_int(sqlstmt, 1)
									   histID:histID
									 orderNum:orderNum++
								 mstTableName: mstTblName 
								  fcTableName:fcTblName])
			{	
				stat = NO;
				break;
			}
		}
		
		[histIDs removeAllObjects];
		histIDs = nil;
	}
	else 
	{
		NSLog(@"convertID2Name error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);
}

// 項目（施術）マスタテーブル２でKeyが自動増加でない場合のテーブル削除
- (BOOL) badmstUserWorkItem2Drop
{
	BOOL stat = NO;
	
	/*
	 DROP TABLE IF EXISTS mst_user_work_item2であると、
	 database error -> code:6  message:database table is lockedとなる
	 */
	
	/*
	 ALTER TABLE mst_user_work_item2 RENAME TO mst_user_work_item2_old
	 */
	NSMutableString *pragmaSql = [NSMutableString string];
	[pragmaSql appendFormat:@"ALTER TABLE %@", ITEM_EDIT_USER_WORK2_TABLE];
	[pragmaSql appendString:@" RENAME TO "];
	[pragmaSql appendFormat:@" %@_ver105_later", ITEM_EDIT_USER_WORK2_TABLE];
		
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL,&err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);
}

// mstUserWorkItem2テーブルの作成
- (BOOL) mstUserWorkItem2TableMake:(NSString *)tableName
{
	BOOL stat = NO;
	
	/*
	 CREATE TABLE IF NOT EXISTS mst_user_work_item2 
	   ('work_item_id' INTEGER PRIMARY KEY AUTOINCREMENT, 
		'work_item_name' TEXT)
	 */
	
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ ", tableName];
	[ pragmaSql appendString:@"  ('work_item_id' INTEGER PRIMARY KEY AUTOINCREMENT, "];
	[ pragmaSql appendString:@"   'work_item_name' TEXT)"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);
}

// 項目（施術）マスタテーブル２のアップグレード
- (BOOL) mstUserWorkItem2Upgade
{
	// フィールド名にitem_editがあるかを確認
	BOOL stat = NO;
	
	//SQL(table_info)文の作成:PRAGMAはバインド変数は使用できない
	NSString *pragmaSql 
		= [NSString stringWithFormat: @"PRAGMA table_info(%@)", ITEM_EDIT_USER_WORK2_TABLE];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		BOOL isFind = NO;
		BOOL isExist = NO;
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// とりあえずテーブルは存在する
			isExist = YES;
			
			// 取得したrowからテーブル情報を取得:2列目が列名情報
			NSString *rowName = [self makeSqliteStmt2String:sqlstmt index:1];
			
			// 列名を確認
			if ((rowName) && ([rowName isEqualToString:@"item_edit"]) )
			{
				// 指定列名は存在している
				isFind = YES;
				break;
			}
		}
		
		if ( (isExist) && (! isFind) )
		{
			// テーブルがあって列名が存在しない場合は、アップグレード完了とする
			return (YES);
		}
		
		if( (isExist) && (isFind) )
		{
			// テーブルがあって列名が存在する場合は、一旦テーブルを削除する
			stat = [self badmstUserWorkItem2Drop];
		}
		
		if (stat)
		{
			// mstUserWorkItem2テーブルの作成
			stat = [self mstUserWorkItem2TableMake:ITEM_EDIT_USER_WORK2_TABLE];
		}
			
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);
}

// 項目編集テーブル	のアップグレード
- (BOOL) itemEditTableUpgradeWithKind:(ITEM_EDIT_KIND)kind
{
	BOOL stat = NO;
	
	// 項目編集種別より状態テーブル名を取得
	NSString *fcTableName = [self getFcTableNameWithItemEditKind:kind];
	
	//SQL(table_info)文の作成:PRAGMAはバインド変数は使用できない
	NSString *pragmaSql 
	= [NSString stringWithFormat: @"PRAGMA table_info(%@)", fcTableName];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		BOOL isFind = NO;
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// 取得したrowからテーブル情報を取得:2列目が列名情報
			NSString *rowName = [self makeSqliteStmt2String:sqlstmt index:1];
			
			// 列名を確認
			if ((rowName) && ([rowName isEqualToString:ITEM_EDIT_NAME_FIELD]) )
			{
				// 指定列名は存在している
				stat = isFind = YES;
				break;
			}
		}
		
		if( ! isFind)
		{
			// 名前field列名が存在しない場合は、追加する
			if ( ([self addColumnWithTable:fcTableName 
							  columnName:ITEM_EDIT_NAME_FIELD columnType:@"text"]) &&
				 ([self addColumnWithTable:fcTableName 
							   columnName:ITEM_EDIT_ORDER_FIELD columnType:@"INTEGER"]) )
			{
				// itemIDからitemNameへと変換する
				stat = [self convertID2Name:[self getTableNameWithItemEditKind:kind] 
									fcTableName:fcTableName];
			}
			else{
				stat = NO;
			}
		}
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);
}

// 項目編集テーブル	のアップグレード：Ver105
- (BOOL) itemEditTableUpgrade4Ver105
{
	ITEM_EDIT_KIND kinds[] = {ITEM_EDIT_USER_WORK1, ITEM_EDIT_USER_WORK2};
	
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	BOOL stat = YES;
	
	for (NSInteger idx = 0; idx < 2; idx++)
	{
		if (! [self itemEditTableUpgradeWithKind:kinds[idx]])
		{
			stat = NO;
			break;
		}
	}
	
	// 項目（施術）マスタテーブル２のアップグレード:DROPの際のLOCK解除のため、COMMITは完了していること
	if (stat)
	{
		stat =[self mstUserWorkItem2Upgade];
	}
	
	if (stat)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
	}
	else 
	{
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//クローズ
	[self closeDataBase];
	
	return (stat);	
}

// Webメールのテンプレートで使用する汎用ボタンテーブル追加
- (BOOL) itemEditTableUpgrade4Ver150
{
	NSArray *tables = [NSArray arrayWithObjects:
					   ITEM_EDIT_USER_WORK3_TABLE,
					   ITEM_EDIT_USER_WORK4_TABLE,
					   ITEM_EDIT_USER_WORK5_TABLE, nil];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	BOOL stat = YES;
	
	// mstUserWorkItemテーブルの作成
	for (NSString *table in tables) {
		if (![self mstUserWorkItem2TableMake:table]) {
			stat = NO;
			break;
		}
	}
	
	if (stat)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
	} else {
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//クローズ
	[self closeDataBase];
	
	return (stat);
}

- (BOOL) _createBackUpInfoTable
{
	BOOL stat = NO;
	
	/*
	 CREATE TABLE  IF NOT EXISTS hist_backup_info (
		 "create_date" text NOT NULL  PRIMARY KEY,
		 "memo" text,
		 "total_user_nums" integer NOT NULL,
		 "total_picture_nums" integer NOT NULL,
		 "total_hist_nums" integer NOT NULL
	 );	 */
	
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendString:@"CREATE TABLE IF NOT EXISTS hist_backup_info ("];
	[ pragmaSql appendString:@"  'create_date' text NOT NULL  PRIMARY KEY, "];
	[ pragmaSql appendString:@"  'memo' text, "];
	[ pragmaSql appendString:@"  'total_user_nums' integer NOT NULL,"];
	[ pragmaSql appendString:@"  'total_picture_nums' integer NOT NULL, "];
	[ pragmaSql appendString:@"  'total_hist_nums' integer NOT NULL "];
	[ pragmaSql appendString:@" );"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (stat);
}

// PCバックアップ情報テーブルの作成：Ver108
- (BOOL) createBackUpInfoTable
{
	// データベースが閉じている場合はOPENする
	if (db == nil) 
	{
		if (! [self openDataBase])
		{  return (NO); }
	}
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	BOOL stat = [self _createBackUpInfoTable];
	
	if (stat)
	{
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
	}
	else 
	{
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//クローズ
	[self closeDataBase];
	
	return (stat);	
}

- (BOOL) _doSqlForCreateTable:(NSMutableString *)pragmaSql
{
	BOOL stat = NO;
	if (db == nil)
	{
		if (! [self dataBaseOpen4Transaction])
		{  return (NO); }
	}
	
//	NSMutableString *pragmaSql = [NSMutableString string];
//	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'fc_binary_upload_mng' "];
//	[ pragmaSql appendString:@"  ('user_id' INTEGER, "];
//	[ pragmaSql appendString:@"   'picture_url' TEXT,"];
//	[ pragmaSql appendString:@"   'update_king' INTEGER )"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	[self dataBaseClose2TransactionWithState:stat];
	
	return (stat);
}

/**
 * mst_shopテーブル生成(Calulu1のDB用)
 */
- (BOOL)createMstShopTableMake
{
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'mst_shop' "];
	[ pragmaSql appendString:@"  ('shop_id' INTEGER, "];
	[ pragmaSql appendString:@"   'shop_name' TEXT,"];
	[ pragmaSql appendString:@"   'shop_level' INTEGER DEFAULT '0' )"];
	
	return [self _doSqlForCreateTable:pragmaSql];
}

/**
 * fc_binary_upload_mngテーブル生成(Calulu1のDB用)
 */
- (BOOL)createFcBinaryUploadMngTableMake
{
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'fc_binary_upload_mng' "];
	[ pragmaSql appendString:@"  ('user_id' INTEGER, "];
	[ pragmaSql appendString:@"   'picture_url' TEXT,"];
	[ pragmaSql appendString:@"   'update_king' INTEGER )"];
	
	return [self _doSqlForCreateTable:pragmaSql];
}

/**
 * fc_hist_info_update_mngテーブル生成(Calulu1のDB用)
 */
- (BOOL)createFcHistInfoUpdateMngTableMake
{
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'fc_hist_info_update_mng' "];
	[ pragmaSql appendString:@"  ('hist_id' INTEGER, "];
	[ pragmaSql appendString:@"   'table_name' TEXT,"];
	[ pragmaSql appendString:@"   'update_kind' INTEGER,"];
	[ pragmaSql appendString:@"   'update_date' REAL,"];
	[ pragmaSql appendString:@"   'sub_key' TEXT,"];
	[ pragmaSql appendString:@"   'user_id' INTEGER,"];
	[ pragmaSql appendString:@"   'work_date' REAL )"];
	
	return [self _doSqlForCreateTable:pragmaSql];
}

/**
 * fc_hist_info_update_mngテーブル生成(Calulu1のDB用)
 */
- (BOOL)createFcParentChildShopTableMake
{
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'fc_parent_child_shop' "];
	[ pragmaSql appendString:@"  ('parent_shop_id' INTEGER, "];
	[ pragmaSql appendString:@"   'child_shop_id' INTEGER )"];
	
	return [self _doSqlForCreateTable:pragmaSql];
}

/**
 * fc_update_mng_time_deleteテーブル生成(Calulu1のDB用)
 */
- (BOOL)createFcUpdateMngTimeDeleteTableMake
{
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'fc_update_mng_time_delete' "];
	[ pragmaSql appendString:@"  ('update_table_id' INTEGER, "];
	[ pragmaSql appendString:@"   'table_name' TEXT NOT NULL, "];
	[ pragmaSql appendString:@"   'update_kind' INTEGER, "];
	[ pragmaSql appendString:@"   'update_date' REAL NOT NULL, "];
	[ pragmaSql appendString:@"   'key_value' TEXT NOT NULL, "];
	[ pragmaSql appendString:@"   'sub_key1_value' TEXT, "];
	[ pragmaSql appendString:@"   'sub_key2_value' TEXT )"];
	
	return [self _doSqlForCreateTable:pragmaSql];
}

/**
 * fc_update_mng_time_deleteテーブル生成(Calulu1のDB用)
 */
- (BOOL)createFcUserInfoUpdateMngTableMake
{
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'fc_user_info_update_mng' "];
	[ pragmaSql appendString:@"  ('user_id' INTEGER, "];
	[ pragmaSql appendString:@"   'update_kind' INTEGER, "];
	[ pragmaSql appendString:@"   'update_date' REAL NOT NULL, "];
	[ pragmaSql appendString:@"   'first_name' TEXT, "];
	[ pragmaSql appendString:@"   'second_name' TEXT, "];
	[ pragmaSql appendString:@"   'mid_name' TEXT )"];
	
	return [self _doSqlForCreateTable:pragmaSql];
}

/**
 * fc_update_mng_time_deleteテーブル生成(Calulu1のDB用)
 */
- (BOOL)createFcUserWorkItemUpdateMngTableMake
{
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS 'fc_user_work_item_update_mng' "];
	[ pragmaSql appendString:@"  ('work_item_id' INTEGER, "];
	[ pragmaSql appendString:@"   'mst_kind' INTEGER, "];
	[ pragmaSql appendString:@"   'update_kind' INTEGER, "];
	[ pragmaSql appendString:@"   'update_date' REAL, "];
	[ pragmaSql appendString:@"   'work_item_name' TEXT )"];
	
	return [self _doSqlForCreateTable:pragmaSql];
}

#pragma mark -
#pragma mark DBアップデート
// ピクチャーテーブル	のアップグレード：Ver114
- (BOOL) userpictureUpgradeVer114
{	
	BOOL stat = NO;
    if (db == nil) 
	{
		if (! [self dataBaseOpen4Transaction])
		{  return (NO); }
	}
	// 項目編集種別より状態テーブル名を取得
	NSString *fcTableName = [[NSString alloc]initWithString:@"fc_user_picture"];
	
	//SQL(table_info)文の作成:PRAGMAはバインド変数は使用できない
	NSString *pragmaSql 
	= [NSString stringWithFormat: @"PRAGMA table_info(%@)", fcTableName];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		//sqlite3_reset(sqlstmt);
		
		BOOL isFind = NO;
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// 取得したrowからテーブル情報を取得:1列目が列名情報
			NSString *rowName = [self makeSqliteStmt2String:sqlstmt index:1];
			
			// 列名を確認
			if ((rowName) && ([rowName isEqualToString:@"pictuer_title"]) )
			{
				// 指定列名は存在している
				stat = isFind = YES;
				break;
			}
		}
		
		if( ! isFind)
		{
			// 名前field列名が存在しない場合は、追加する
			if ( ([self addColumnWithTable:fcTableName
                                columnName:@"pictuer_title" columnType:@"text"]) &&
                ([self addColumnWithTable:fcTableName 
							   columnName:@"pictuer_comment" columnType:@"text"]) )
			{
                stat = YES;
			}
			else{
				stat = NO;
			}
            NSLog(@"Ver114 updated");
		}else{
#ifdef DEBUG
            NSLog(@"Ver114 already updated");
#endif
        }
	}
	else 
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
    
    [fcTableName release];
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
    [self dataBaseClose2TransactionWithState:stat];

	return (stat);
}

// mst_user のアップグレード：Ver122
// GigasJapan sekine 2013/6/18追加
// メール機能追加 ユーザー情報にemail1,email2追加
//      TableName:mst_user   column:email1 type:text
//      TableName:mst_user   column:email2 type:text
- (BOOL) mstuserUpgradeVer122
{
	BOOL stat = NO;
//    if (db == nil)
//	{
//		if (! [self dataBaseOpen4Transaction])
//		{  return (NO); }
//	}
    
    stat = [self checkExistColumnWithTableName:@"mst_user" columnName:@"shop_id"
								  isColumnMake:YES columnType:@"integer default '0'"];
	if (!stat)
	{
		NSLog (@"databesa update error add shop_id");
	}
    stat = [self checkExistColumnWithTableName:@"mst_user" columnName:@"email1"
									  isColumnMake:YES columnType:@"text"];
	if (!stat)
	{
		NSLog (@"databesa update error add email1");
	}
    stat = [self checkExistColumnWithTableName:@"mst_user" columnName:@"email2"
									  isColumnMake:YES columnType:@"text"];
	if (!stat)
	{
		NSLog (@"databesa update error add email2");
	}
        
	return (stat);
}

/**
 * mst_user のアップグレード：ver140
 * 郵便番号・住所・電話番号の追加
 */
- (BOOL) mstuserUpgradeVer140
{
	BOOL stat = NO;
	
	NSArray *col = [NSArray arrayWithObjects:
					@"postal",	// 郵便番号
					@"adr1",	// 住所１：都道府県
					@"adr2",	// 住所２：郡/市区町村
					@"adr3",	// 住所３：その他地番など
					@"adr4",	// 住所３：その他地番など
					@"tel",
					@"mobile",// 電話番号
					nil];
	
	for (NSString *colName in col) {
		stat = [self checkExistColumnWithTableName:@"mst_user" columnName:colName
									  isColumnMake:YES columnType:@"text"];
		if (stat==NO) break;
	}

	return stat;
}

/**
 * mst_user のアップグレード：ver172
 * ミドルネームの追加
 */
- (BOOL) mstuserUpgradeVer172
{
	BOOL stat = NO;

	stat = [self checkExistColumnWithTableName:@"mst_user" columnName:@"mid_name"
								  isColumnMake:YES columnType:@"text"];
#ifdef DEBUG
	NSLog(@"%s [%d]",__func__, stat);
#endif
	return stat;
}

/**
 * mst_user のアップグレード：ver215
 * 担当者の追加
 */
- (BOOL) mstuserUpgradeVer215
{
	BOOL stat = NO;
	
	stat = [self checkExistColumnWithTableName:@"mst_user" columnName:@"responsible"
								  isColumnMake:YES columnType:@"text"];
#ifdef DEBUG
	NSLog(@"%s [%d]",__func__, stat);
#endif
	return stat;
}

#pragma mark -
// TODO:video libraryに移動。DELC SASAGE

- (oneway void) release
{
	// ここでデータベースをCLOSEして、オブジェクトをクリアする
	[self closeDataBase];
	
	[super release];
}


#pragma mark template_database
/**
 createTemplateDB
 */
-(BOOL) createTemplateDB
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
	BOOL ret = YES;
	
	// DBオープン
	ret = [self openDataBase];
	if ( ret != YES ) return  NO;

	// 各テーブルの作成
	if ( ret == YES )
		ret = [self createTemplateTable];
	if ( ret == YES)
		ret = [self createCategoryTable];
	if ( ret == YES )
		ret = [self createGeneralFieldTable];
	if ( ret == YES )
		ret = [self createGeneralFieldItemTable];
	if ( ret == YES )
		ret = [self createPictureInfoTable];
	if ( ret == YES )
		ret = [self createCaptruePictInfoTable];
	if ( ret != YES )
	{
		NSLog( @"DB Error" );
		return NO;
	}
	
	// DBクローズ
	[self closeDataBase];
	return YES;
}

/**
 createTemplateTable
 */
- (BOOL) createTemplateTable
{
	BOOL stat = NO;
	
	/*
	 CREATE TABLE IF NOT EXISTS mst_user_template
	 ('template_id' TEXT PRIMARY KEY,
	  'account_id' TEXT,
	  'template_title' TEXT,
	  'template_body' TEXT,
	  'version' INTEGER,
	  'category_id' TEXT,
	  'gen1_field_id' TEXT,
	  'gen2_field_id' TEXT,
	  'gen3_field_id' TEXT,
	  'update_date' REAL,
	  'delete_flag' INTEGER)
	 */
	
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ ", ITEM_EDIT_USER_TEMPLATE_TABLE];
	[ pragmaSql appendString:@"  ('template_id' TEXT PRIMARY KEY, "];
	[ pragmaSql appendString:@"   'account_id' TEXT, "];
	[ pragmaSql appendString:@"   'template_title' TEXT, "];
	[ pragmaSql appendString:@"   'template_body' TEXT, "];
	[ pragmaSql appendString:@"   'version' INTEGER, "];
	[ pragmaSql appendString:@"   'category_id' TEXT, "];
	[ pragmaSql appendString:@"   'gen1_field_id' TEXT, "];
	[ pragmaSql appendString:@"   'gen2_field_id' TEXT, "];
	[ pragmaSql appendString:@"   'gen3_field_id' TEXT, "];
	[ pragmaSql appendString:@"   'update_date' REAL, "];
	[ pragmaSql appendString:@"   'delete_flag' INTEGER)"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	return (stat);
}

/**
 createCategoryTable
 */
- (BOOL) createCategoryTable
{
	BOOL stat = NO;
	
	/*
	 CREATE TABLE IF NOT EXISTS category_info
	 ('category_id' TEXT PRIMARY KEY,
	  'account_id' TEXT,
	  'category_name' TEXT,
	  'update_date' REAL,
	  'delete_flag' INTEGER)
	 */
	
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ ", ITEM_EDIT_CATEGORY_INFO_TABLE];
	[ pragmaSql appendString:@"  ('category_id' TEXT PRIMARY KEY, "];
	[ pragmaSql appendString:@"   'account_id' TEXT, "];
	[ pragmaSql appendString:@"   'category_name' TEXT, "];
	[ pragmaSql appendString:@"   'update_date' REAL, "];
	[ pragmaSql appendString:@"   'delete_flag' INTEGER)"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	return (stat);
}

/**
 カテゴリーが初期化されているか
 */
- (BOOL) isCategoryInitialized
{
	/*
	 SELECT count(*) FROM category_info WHERE category_id = '30ADDBD2-A503-495E-8994-F3B691B809F7'
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT COUNT(*) "];
	[sqlCmd appendString:@"FROM category_info "];
	[sqlCmd appendFormat:@"WHERE category_id = '%@'", TEMPLATE_CATEGORY_NOTHING];


	// 初期値が設定されているか？
	__block NSNumber* num = nil;
	BOOL status = [self execSqlOnTemplateDatabase:sqlCmd
									   ReturnData:nil
										 Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
											 num = [NSNumber numberWithInt:sqlite3_column_int(sqlstmt, 0)];
										 }];
	if ( status == NO ) return NO;
	return ([num intValue] > 0) ? YES : NO;
}

/**
 初期値を設定する
 */
- (BOOL) insertCategoryInitData
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
	NSString* timeString = [Common convertPOSIX2String:[[NSDate date] timeIntervalSince1970]];
	NSString* timeReal = [NSString stringWithFormat:@"julianday('%@')", timeString]; // ユリウス日に変換しておく
	
	/*
	 INSERT INTO category_info VALUES('30ADDBD2-A503-495E-8994-F3B691B809F7', acount_id, 'なし', julianday('2014-04-09 12:12:12'), 0)
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"INSERT INTO category_info "];
	[sqlCmd appendString:@"VALUES("];
	[sqlCmd appendFormat:@"'%@', ", TEMPLATE_CATEGORY_NOTHING];
	[sqlCmd appendFormat:@"'%@', ", accID];
	[sqlCmd appendString:@"'なし', "];
	[sqlCmd appendFormat:@"%@, ", timeReal];
	[sqlCmd appendString:@"0)"];

	// INSERT文の実行
	return [self execSqlCommand:sqlCmd
						   Bind:nil
					   Function:^(BOOL *status) {
						   //  fc_update_mng_time_deleteに更新履歴を追加
						   *status = [CloudSyncClientDatabaseUpdate newCategoryMakeWithID:TEMPLATE_CATEGORY_NOTHING
																			splite3Object:db
																			   UpdateDate:timeString];
					   }];
}

/**
 createGeneralFieldTable
 */
- (BOOL) createGeneralFieldTable
{
	BOOL stat = NO;
	
	/*
	 CREATE TABLE IF NOT EXISTS gen_field_info
	 ('gen_field_id' TEXT PRIMARY KEY,
	  'account_id' TEXT,
	  'gen_field_name' TEXT,
	  'update_date' REAL,
	  'delete_flag' INTEGER)
	 */
	
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ ", ITEM_EDIT_GEN_FIELD_INFO_TABLE];
	[ pragmaSql appendString:@"  ('gen_field_id' TEXT PRIMARY KEY, "];
	[ pragmaSql appendString:@"   'account_id' TEXT, "];
	[ pragmaSql appendString:@"   'gen_field_name' TEXT, "];
	[ pragmaSql appendString:@"   'update_date' REAL, "];
	[ pragmaSql appendString:@"   'delete_flag' INTEGER)"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	return (stat);
}

/**
 createGeneralFieldItemTable
 */
- (BOOL) createGeneralFieldItemTable
{
	BOOL stat = NO;
	
	/*
	 CREATE TABLE IF NOT EXISTS gen_field_itme
	 ( 'gen_field_id' TEXT PRIMARY KEY AUTOINCREMENT,
	 'account_id' TEXT,
	 'gen_field_type' TEXT,
	 'gen_field_name' TEXT,
	 'update_date' REAL,
	 'delete_flag' INTEGER)
	 */
	
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ ", ITEM_EDIT_GEN_FIELD_ITEM_TABLE];
	[ pragmaSql appendString:@"  ('gen_field_id' TEXT PRIMARY KEY, "];
	[ pragmaSql appendString:@"   'account_id' TEXT, "];
	[ pragmaSql appendString:@"   'gen_field_type' INTEGER, "];
	[ pragmaSql appendString:@"   'gen_field_name' TEXT, "];
	[ pragmaSql appendString:@"   'update_date' REAL, "];
	[ pragmaSql appendString:@"   'delete_flag' INTEGER)"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	return (stat);
}

/**
 createPictureInfoTable
 */
- (BOOL) createPictureInfoTable
{
	BOOL stat = NO;
	
	/*
	 CREATE TABLE IF NOT EXISTS template_pict_info
	 ('template_pict_id' TEXT PRIMARY KEY,
	  'template_id' TEXT,
	  'picture_url' TEXT,
	  'update_date' REAL,
	  'delete_flag' INTEGER)
	 */
	
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ ", ITEM_EDIT_PICT_INFO_TABLE];
	[ pragmaSql appendString:@"  ('template_pict_id' TEXT PRIMARY KEY, "];
	[ pragmaSql appendString:@"   'template_id' TEXT, "];
	[ pragmaSql appendString:@"   'picture_url' TEXT, "];
	[ pragmaSql appendString:@"   'update_date' REAL, "];
	[ pragmaSql appendString:@"   'delete_flag' INTEGER)"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	return (stat);
}

/**
 createPictureInfoTable
 */
- (BOOL) createCaptruePictInfoTable
{
	BOOL stat = NO;
	
	/*
	 CREATE TABLE IF NOT EXISTS capture_pict_info
	 ('template_pict_id' INTEGER PRIMARY KEY,
	  'account_id' TEXT,
	  'picture_url' TEXT,
	  'update_date' REAL)
	 */
	
	NSMutableString *pragmaSql = [NSMutableString string];
	[ pragmaSql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ ", ITEM_EDIT_CAPTURE_PICT_INFO_TABLE];
	[ pragmaSql appendString:@"  ('capture_pict_id' TEXT PRIMARY KEY, "];
	[ pragmaSql appendString:@"   'account_id' TEXT, "];
	[ pragmaSql appendString:@"   'picture_url' TEXT, "];
	[ pragmaSql appendString:@"   'update_date' REAL)"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	return (stat);
}

/**
 isExistTemplateDB
 */
- (BOOL) isExistTemplateDB
{
	int i = 0;
	// DBオープン
	BOOL ret = [self openDataBase];
	if ( ret != YES ) return  NO;

	// 存在確認
	if ( ret == YES )
	{
		// mst_user_template
		ret = [self isExistMstUserTemplate];
		if ( ret != YES )
		{
			// テンプレートテーブルの作成
			ret = [self createTemplateTable];
		}
		i++;
	}
	if ( ret == YES )
	{
		// category_info
		ret = [self isExistCategoryInfo];
		if ( ret != YES )
		{
			// カテゴリーテーブルの作成
			ret = [self createCategoryTable];
		}
		// カテゴリーが初期化されているか
		ret = [self isCategoryInitialized];
		if ( ret != YES )
		{
			// 初期化されていなければ作成しておく(この中でDBが閉じられてしまう)
			ret = [self insertCategoryInitData];
		}
		i++;
	}
	if ( ret == YES )
	{
		ret = [self openDataBase];
		// gen_field_info
		ret = [self isExistGenFieldInfo];
		if ( ret != YES )
		{
			// 汎用フィールドの作成
			ret = [self createGeneralFieldTable];
		}
		i++;
	}
	if( ret == YES )
	{
		ret = [self isExistGenFieldItem];
		if( ret != YES )
		{
			// 汎用フィールドの作成
			ret = [self createGeneralFieldItemTable];
		}
		i++;
	}
	if ( ret == YES )
	{
		// template_pict_info
		ret = [self isExistTemplatePictInfo];
		if ( ret != YES )
		{
			// テンプレート画像用テーブルの作成
			ret = [self createPictureInfoTable];
		}
		i++;
	}
	if ( ret == YES )
	{
		// capture_pict_info
		ret = [self isExistCapturePictInfo];
		if ( ret != YES )
		{
			// テンプレート用の画像取り込みテーブルの作成
			ret = [self createCaptruePictInfoTable];
		}
		i++;
	}
	if ( ret != YES )
	{
		NSLog(@"DB Error [%d]%s", i, __func__);
	}
	
	// DBクローズ
	[self closeDataBase];
	return YES;
}

/**
 isExistMstUserTemplate
 テンプレートテーブルの確認
 */
- (BOOL) isExistMstUserTemplate
{
	return [self IsExistTable:@"mst_user_template"];
}

/**
 isExistCategoryInfo
 テンプレートテーブルの確認
 */
- (BOOL) isExistCategoryInfo
{
	return [self IsExistTable:@"category_info"];
}

/**
 isExistGenFieldInfo
 テンプレートテーブルの確認
 */
- (BOOL) isExistGenFieldInfo
{
	return [self IsExistTable:@"gen_field_info"];
}

/**
 isExistGenFieldItem
 テンプレートテーブルの確認
 */
- (BOOL) isExistGenFieldItem
{
	return [self IsExistTable:ITEM_EDIT_GEN_FIELD_ITEM_TABLE];
}

/**
 テンプレート画像用テーブルの確認
 */
- (BOOL) isExistTemplatePictInfo
{
	return  [self IsExistTable:@"template_pict_info"];
}

/**
 テンプレート画像の取り込み画像テーブルの確認
 */
- (BOOL) isExistCapturePictInfo
{
	return  [self IsExistTable:@"capture_pict_info"];
}

/**
 IsExistTable
 テーブルの存在確認
 @param tableName 存在確認するテーブル名
 */
- (BOOL) IsExistTable:(NSString*) tableName
{
	BOOL stat = YES;
	NSString* strSqlCmd = [NSString stringWithFormat:@"SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='%@'", tableName];
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [strSqlCmd UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// 構文解析の結果問題なし
		stat = YES;
		// リセット
		sqlite3_reset( sqlstmt );
		// SQL実行
		if ( sqlite3_step(sqlstmt) != SQLITE_DONE )
		{
			int count = sqlite3_column_int(sqlstmt, 0);
			if ( count == 0 )
			{
				[self errDataBaseWriteLog];
				stat = NO;
			}
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	return stat;
}


/**
 
 */
- (NSString*) getStringWithObject:(id) obj
{
	if ( [obj isKindOfClass:[NSNull class]] == YES )
		return @"NULL";
	return [NSString stringWithFormat:@"'%@'", (NSString*)obj];
}

/**
 insertTemplateWithID
 */
- (BOOL) insertTemplateWithID:(NSString*) tmplUUID
						Title:(NSString*) textTitle
						 Body:(NSString*) textBody
						 Data:(NSMutableArray*) data;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* tmplId = [NSString stringWithFormat:@"'%@'", tmplUUID];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	NSNumber* ver = [NSNumber numberWithInt:TEMPLATE_VERSION];

	NSString* categoryId = [self getStringWithObject: [data objectAtIndex:0]];
	NSString* gen1FieldId = [self getStringWithObject: [data objectAtIndex:1]];
	NSString* gen2FieldId = [self getStringWithObject: [data objectAtIndex:2]];
	NSString* gen3FieldId = [self getStringWithObject: [data objectAtIndex:3]];
	NSString* timeString = [Common convertPOSIX2String:[(NSNumber*)[data objectAtIndex:4] doubleValue]];
	NSString* timeReal = [NSString stringWithFormat:@"julianday('%@')", timeString]; // ユリウス日に変換しておく
	NSNumber* deleteFlag = [NSNumber numberWithInteger:0];

	/*
	 SQL文の作成
	 INSERT OR REPLACE INTO mst_user_template VALUES(tmplId, accID, title, body, 1, xxxx, ....)
	 */
	NSString* insertSql = [self createInsertCommand:@"mst_user_template"
											   Data:tmplId,			// テンプレートID
													accID,			// アカウントID
													@"?",			// テンプレートのタイトル
													@"?",			// テンプレート本文
													ver,			// バージョン
													categoryId,		// カテゴリーID
													gen1FieldId,	// 汎用フィールド１
													gen2FieldId,	// 汎用フィールド２
													gen3FieldId,	// 汎用フィールド３
													timeReal,		// 更新日時
													deleteFlag,		// 削除フラグ
													nil];

	// DBのオープン＆トランザクション開始
	BOOL ret = [self dataBaseOpen4Transaction];
	if ( ret != YES ) return NO;
	
	//
	// データベースに追加する
	//
	
	// sqlstmtの生成
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [insertSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		//バインド変数をクリアー
		sqlite3_clear_bindings( sqlstmt );
		// バインド
		sqlite3_bind_text( sqlstmt, 1, [textTitle UTF8String], -1, SQLITE_TRANSIENT );	// title
		sqlite3_bind_text( sqlstmt, 2, [textBody UTF8String], -1, SQLITE_TRANSIENT );	// body

		// SQL実行
		if ( sqlite3_step(sqlstmt) != SQLITE_DONE )
		{
			// エラー
			ret = NO;
			//エラーメソッドをコール
			[self errDataBase];
		}
		if ( ret == YES )
		{
			// サーバーにアップロード
			//  fc_update_mng_time_deleteに更新履歴を追加
			ret = [CloudSyncClientDatabaseUpdate newTemplateMakeWithID:tmplUUID
														 splite3Object:db
															UpdateDate:timeString];
		}
	}
	else
	{
		// エラー表示
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	// DBクローズ＆トランザクションの終了
	[self dataBaseClose2TransactionWithState: ret];
	
	return YES;
}

/**
 deleteTemplateWithID
 */
- (BOOL) deleteTemplateWithID:(NSString*) tmplUUID
{
	NSString* strTemplateID = [NSString stringWithFormat:@"'%@'", tmplUUID];
	
	/*
	 UPDATE mst_user_template SET delete_flag = 1 WHERE template_id = id
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE mst_user_template "];
	[sqlCmd appendFormat:@"SET delete_flag = 1 "];
	[sqlCmd appendFormat:@"WHERE template_id = %@ ", strTemplateID];
	BOOL ret = [self execSqlCommand:sqlCmd
							   Bind:nil
						   Function:^(BOOL *status) {
							   if ( *status == YES )
							   {
								   //  fc_update_mng_time_deleteに更新履歴を追加
								   *status = [CloudSyncClientDatabaseUpdate deleteTemplateMakeWithID:tmplUUID
																					   splite3Object:db];
							   }
						   }];
	return ret;
}

/**
 updateTemplateWithTitle
 */
- (BOOL) updateTemplateWithID:(NSString*) templateId
						Title:(NSString*) textTitle
						 Body:(NSString*) textBody
						 Data:(NSMutableArray*) data
{
	NSString* tmplId = [NSString stringWithFormat:@"'%@'", templateId];
	NSString* categoryId = [self getStringWithObject: [data objectAtIndex:0]];
	NSString* gen1FieldId = [self getStringWithObject: [data objectAtIndex:1]];
	NSString* gen2FieldId = [self getStringWithObject: [data objectAtIndex:2]];
	NSString* gen3FieldId = [self getStringWithObject: [data objectAtIndex:3]];
	NSString* timeString = [Common convertPOSIX2String:[(NSNumber*)[data objectAtIndex:4] doubleValue]];
	NSString* timeReal = [NSString stringWithFormat:@"julianday('%@')", timeString]; // ユリウス日に変換しておく

	/*
	 SQL文の作成
	 UPDATE mst_user_template 
	  SET template_title = title, template_body = body, version = ver, category_id = categoryId,
	      gen1_field_id = gen1field, gen2_field_id = gen2field, gen3_field_id = gen3field, update_date = timeInt
	   WHERE template_id = templateId AND delete_flag = 0
	 */
	NSMutableString* updateSql = [NSMutableString stringWithFormat:@"UPDATE mst_user_template SET "];
	[updateSql appendString:@"template_title = ?, "];
	[updateSql appendString:@"template_body = ?, "];
	[updateSql appendFormat:@"version = %d, ", TEMPLATE_VERSION];
	[updateSql appendFormat:@"category_id = %@, ", categoryId];
	[updateSql appendFormat:@"gen1_field_id = %@, ", gen1FieldId];
	[updateSql appendFormat:@"gen2_field_id = %@, ", gen2FieldId];
	[updateSql appendFormat:@"gen3_field_id = %@, ", gen3FieldId];
	[updateSql appendFormat:@"update_date = %@ ", timeReal];
	[updateSql appendFormat:@"WHERE template_id = %@ ", tmplId];
	[updateSql appendFormat:@"AND delete_flag = 0"];
	
	//
	// データベースに追加する
	//

	// DBのオープン＆トランザクション開始
	BOOL ret = [self dataBaseOpen4Transaction];
	if ( ret != YES ) return NO;
	
	// sqlstmtの生成
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		//バインド変数をクリアー
		sqlite3_clear_bindings( sqlstmt );
		// バインド
		sqlite3_bind_text( sqlstmt, 1, [textTitle UTF8String], -1, SQLITE_TRANSIENT );	// title
		sqlite3_bind_text( sqlstmt, 2, [textBody UTF8String], -1, SQLITE_TRANSIENT );	// body
		// SQL実行
		if ( sqlite3_step(sqlstmt) != SQLITE_DONE )
		{
			// エラー
			ret = NO;
			//エラーメソッドをコール
			[self errDataBase];
		}
		if ( ret == YES )
		{
			// サーバーにアップロード
			//  fc_update_mng_time_deleteに更新履歴を追加
			ret = [CloudSyncClientDatabaseUpdate editTemplateMakeWithID:templateId
														  splite3Object:db
															 UpdateDate:timeString];
		}
	}
	else
	{
		// エラー表示
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	// DBクローズ＆トランザクションの終了
	[self dataBaseClose2TransactionWithState: ret];
	
	return YES;
}

/**
 指定したテンプレートのタイトルを取得する
 */
- (NSString*) getTemplateTitleWithID:(NSString *)templateId
{
	/*
	 SELECT template_title FROM mst_user_template WHERE template_id = templateId
	 */
	__block NSString* retString = nil;
	NSString* sqlCmd = [NSString stringWithFormat:@"SELECT template_title FROM mst_user_template WHERE template_id = '%@' AND delete_flag = 0", templateId];
	[self execSqlOnTemplateDatabase:sqlCmd
						 ReturnData:nil
						   Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
							   char* title = (char*)sqlite3_column_text(sqlstmt, 0);
							   if ( title )
							   {
								   // タイトルの取得
								   retString = [NSString stringWithUTF8String:title];
							   }
						   }];
	return retString;
}

/**
 テンプレートに設定されているカテゴリーIDを取得する
 */
- (NSString*) getCategoryIdWithTmplID:(NSString*) tmplId
{
	/*
	 SELECT category_id FROM mst_user_template WHERE template_id = tmplId AND delete_flag = 0
	 */
	__block NSString* retString = nil;
	NSString* sqlCmd = [NSString stringWithFormat:@"SELECT category_id FROM mst_user_template WHERE template_id = '%@' AND delete_flag = 0", tmplId];
	[self execSqlOnTemplateDatabase:sqlCmd
						 ReturnData:nil
						   Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
							   char* categoryId = (char*)sqlite3_column_text(sqlstmt, 0);
							   if ( categoryId )
							   {
								   // カテゴリーIDの取得
								   retString = [NSString stringWithUTF8String:categoryId];
							   }
						   }];
	return retString;
}

/**
 テンプレートに設定されている汎用フィールドIDを
 */
- (NSDictionary*) getGenFieldIdWithTmplID:(NSString*) tmplId
{
	/*
	 SELECT category_id FROM mst_user_template WHERE template_id = tmplId AND delete_flag = 0
	 */
	__block NSMutableDictionary* retDictionary = [NSMutableDictionary dictionary];
	NSString* sqlCmd = [NSString stringWithFormat:@"SELECT gen1_field_id, gen2_field_id, gen3_field_id FROM mst_user_template WHERE template_id = '%@' AND delete_flag = 0", tmplId];
	[self execSqlOnTemplateDatabase:sqlCmd
						 ReturnData:nil
						   Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
							   char* gen1Field = (char*)sqlite3_column_text(sqlstmt, 0);
							   if ( gen1Field )
							   {
								   // 汎用フィールド１
								   [retDictionary setObject:[NSString stringWithUTF8String:gen1Field] forKey:@"1"];
							   }
							   char* gen2Field = (char*)sqlite3_column_text(sqlstmt, 1);
							   if ( gen2Field )
							   {
								   // 汎用フィールド２
								   [retDictionary setObject:[NSString stringWithUTF8String:gen2Field] forKey:@"2"];
							   }
							   char* gen3Field = (char*)sqlite3_column_text(sqlstmt, 2);
							   if ( gen3Field )
							   {
								   // 汎用フィールド３
								   [retDictionary setObject:[NSString stringWithUTF8String:gen3Field] forKey:@"3"];
							   }
						   }];
	return retDictionary;
}

/**
 loadTemplateDatabase
 */
- (NSMutableArray*) loadTemplateDatabase;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	
	/*
	 SELECT * FROM mst_user_template WHERE account_id = xxxxxx AND delete_flag = 0
	 */
	
	// SQL文の作成
	NSString* strSql = [self createSelectSqlCommand:@"template_id, template_title, template_body, category_id, datetime(update_date)"
											  Table:@"mst_user_template"
										 WhereColum:@"account_id"
										  WhereData:accID
										  AndColumn:@"delete_flag"
											AndData:[NSString stringWithFormat:@"%d", 0]];
	
	// 取得する
	NSMutableArray* _array = [NSMutableArray array];
	BOOL ret = [self execSqlOnTemplateDatabase:strSql
								ReturnData:&_array
								  Function:^(sqlite3_stmt* sqlstmt, NSObject** data){
									  NSMutableArray** _temp = (NSMutableArray**)data;
									  if ( _temp == nil ) return;
									  // DBからの取得
									  TemplateInfo* info = [[[TemplateInfo alloc] init] autorelease];
									  char* tmpId = (char*)sqlite3_column_text(sqlstmt, 0 );
									  char* title = (char*)sqlite3_column_text( sqlstmt,1);
									  char* body = (char*)sqlite3_column_text( sqlstmt, 2);
									  char* categoryId = (char*)sqlite3_column_text( sqlstmt, 3 );
									  char* date = (char*)sqlite3_column_text( sqlstmt, 4 );

									  // テンプレート情報に設定
									  if ( tmpId ) [info setTmplId:[NSString stringWithUTF8String:tmpId]];
									  if ( title ) [info setStrTemplateTitle: [NSString stringWithUTF8String:title]];
									  if ( body ) [info setStrTemplateBody: [NSString stringWithUTF8String:body]];
									  if ( categoryId ) [info setCategoryId:[NSString stringWithUTF8String:categoryId]];
									  if ( date )
									  {
										  // まずは日付の文字列からNSDateに変換
										  NSString* strDateSource = [NSString stringWithUTF8String:date];
										  NSDateFormatter* df = [[NSDateFormatter alloc] init];
										  [df setLocale:[NSLocale systemLocale]];
										  [df setTimeZone:[NSTimeZone systemTimeZone]];
										  [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
										  // NSDateからUNIX時刻へ
										  NSTimeInterval timeInt = [[df dateFromString:strDateSource] timeIntervalSince1970];
										  // UNIX時刻からNSDateへ
										  [info setDateTemplateUpdate: [NSDate dateWithTimeIntervalSince1970:timeInt]];
										  [df release];
									  }
									  [*_temp addObject:info];
								  }];

	return ((ret == YES) ? _array : nil);
}

// 2016/5/10 TMS テンプレートの並び順をタイトル順にする
/**
 loadTemplateDatabaseOrderBy
 */
- (NSMutableArray*) loadTemplateDatabaseOrderBy;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	// SQL文の作成
	NSString* strSql = [self createSelectSqlCommand:@"template_id, template_title, template_body, category_id, datetime(update_date)"
											  Table:@"mst_user_template"
										 WhereColum:@"account_id"
										  WhereData:accID
										  AndColumn:@"delete_flag"
											AndData:[NSString stringWithFormat:@"%d", 0]
											Orderby:@"template_title"];
	
	// 取得する
	NSMutableArray* _array = [NSMutableArray array];
	BOOL ret = [self execSqlOnTemplateDatabase:strSql
									ReturnData:&_array
									  Function:^(sqlite3_stmt* sqlstmt, NSObject** data){
										  NSMutableArray** _temp = (NSMutableArray**)data;
										  if ( _temp == nil ) return;
										  // DBからの取得
										  TemplateInfo* info = [[[TemplateInfo alloc] init] autorelease];
										  char* tmpId = (char*)sqlite3_column_text(sqlstmt, 0 );
										  char* title = (char*)sqlite3_column_text( sqlstmt,1);
										  char* body = (char*)sqlite3_column_text( sqlstmt, 2);
										  char* categoryId = (char*)sqlite3_column_text( sqlstmt, 3 );
										  char* date = (char*)sqlite3_column_text( sqlstmt, 4 );
										  
										  // テンプレート情報に設定
										  if ( tmpId ) [info setTmplId:[NSString stringWithUTF8String:tmpId]];
										  if ( title ) [info setStrTemplateTitle: [NSString stringWithUTF8String:title]];
										  if ( body ) [info setStrTemplateBody: [NSString stringWithUTF8String:body]];
										  if ( categoryId ) [info setCategoryId:[NSString stringWithUTF8String:categoryId]];
										  if ( date )
										  {
											  // まずは日付の文字列からNSDateに変換
											  NSString* strDateSource = [NSString stringWithUTF8String:date];
											  NSDateFormatter* df = [[NSDateFormatter alloc] init];
											  [df setLocale:[NSLocale systemLocale]];
											  [df setTimeZone:[NSTimeZone systemTimeZone]];
											  [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
											  // NSDateからUNIX時刻へ
											  NSTimeInterval timeInt = [[df dateFromString:strDateSource] timeIntervalSince1970];
											  // UNIX時刻からNSDateへ
											  [info setDateTemplateUpdate: [NSDate dateWithTimeIntervalSince1970:timeInt]];
											  [df release];
										  }
										  [*_temp addObject:info];
									  }];
	
	return ((ret == YES) ? _array : nil);
}

/**
 カテゴリーで絞り込み検索を行う
 */
- (NSMutableArray*) refiningTemplateDatabaseWithCategory:(NSString*) strCategory
{
	// カテゴリーIDの検索
	NSString* category_id = [self getCategoryID:strCategory];
	if ( category_id == nil ) return NO;

	/*
	 SELECT mst_user_template.template_id, mst_user_template.template_title, mst_user_template.template_body,
	   mst_user_template.category_id, mst_user_template.update_date
	  FROM mst_user_template
	   INNER JOIN category_info ON mst_user_template.category_id = category_info.category_id
	    WHERE mst_user_template.category_id = '419E0947-C496-4234-89ED-41F1D7F55DED'
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT mst_user_template.template_id, mst_user_template.template_title, mst_user_template.template_body,"];
	[sqlCmd appendString:@"mst_user_template.category_id, datetime(mst_user_template.update_date) "];
	[sqlCmd appendString:@"FROM mst_user_template "];
	[sqlCmd appendString:@"INNER JOIN category_info ON mst_user_template.category_id = category_info.category_id "];
	[sqlCmd appendFormat:@"WHERE mst_user_template.category_id = '%@' ", category_id];
	[sqlCmd appendFormat:@"AND mst_user_template.delete_flag = 0"];

	// 取得する
	NSMutableArray* _array = [NSMutableArray array];
	BOOL ret = [self execSqlOnTemplateDatabase:sqlCmd
									ReturnData:&_array
									  Function:^(sqlite3_stmt* sqlstmt, NSObject** data){
										  NSMutableArray** _temp = (NSMutableArray**)data;
										  if ( _temp == nil ) return;
										  // DBからの取得
										  char* tmpId = (char*)sqlite3_column_text(sqlstmt, 0 );
										  char* title = (char*)sqlite3_column_text( sqlstmt,1);
										  char* body = (char*)sqlite3_column_text( sqlstmt, 2);
										  char* categoryId = (char*)sqlite3_column_text( sqlstmt, 3 );
										  char* date = (char*)sqlite3_column_text( sqlstmt, 4 );

										  // テンプレート情報に設定
										  TemplateInfo* info = [[[TemplateInfo alloc] init] autorelease];
										  if ( tmpId ) [info setTmplId:[NSString stringWithUTF8String:tmpId]];
										  if ( title ) [info setStrTemplateTitle: [NSString stringWithUTF8String:title]];
										  if ( body ) [info setStrTemplateBody: [NSString stringWithUTF8String:body]];
										  if ( categoryId )[info setCategoryId:[NSString stringWithUTF8String:categoryId]];
										  if ( date )
										  {
											  // まずは日付の文字列からNSDateに変換
											  NSString* strDateSource = [NSString stringWithUTF8String:date];
											  NSDateFormatter* df = [[NSDateFormatter alloc] init];
											  [df setLocale:[NSLocale systemLocale]];
											  [df setTimeZone:[NSTimeZone systemTimeZone]];
											  [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
											  // NSDateからUNIX時刻へ
											  NSTimeInterval timeInt = [[df dateFromString:strDateSource] timeIntervalSince1970];
											  // UNIX時刻からNSDateへ
											  [info setDateTemplateUpdate: [NSDate dateWithTimeIntervalSince1970:timeInt]];
											  [df release];
										  }
										  [*_temp addObject:info];
									  }];
	
	return ((ret == YES) ? _array : nil);
}
// 2016/5/10 TMS テンプレートの並び順をタイトル順にする
/**
 並び順を指定してカテゴリーで絞り込み検索を行う
 */
- (NSMutableArray*) refiningTemplateDatabaseWithCategoryOrderBy:(NSString*) strCategory
{
	// カテゴリーIDの検索
	NSString* category_id = [self getCategoryID:strCategory];
	if ( category_id == nil ) return NO;
	
	/*
	 SELECT mst_user_template.template_id, mst_user_template.template_title, mst_user_template.template_body,
	 mst_user_template.category_id, mst_user_template.update_date
	 FROM mst_user_template
	 INNER JOIN category_info ON mst_user_template.category_id = category_info.category_id
	 WHERE mst_user_template.category_id = '419E0947-C496-4234-89ED-41F1D7F55DED'
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT mst_user_template.template_id, mst_user_template.template_title, mst_user_template.template_body,"];
	[sqlCmd appendString:@"mst_user_template.category_id, datetime(mst_user_template.update_date) "];
	[sqlCmd appendString:@"FROM mst_user_template "];
	[sqlCmd appendString:@"INNER JOIN category_info ON mst_user_template.category_id = category_info.category_id "];
	[sqlCmd appendFormat:@"WHERE mst_user_template.category_id = '%@' ", category_id];
	[sqlCmd appendFormat:@"AND mst_user_template.delete_flag = 0 "];
	[sqlCmd appendFormat:@"ORDER BY mst_user_template.template_title"];
	
	// 取得する
	NSMutableArray* _array = [NSMutableArray array];
	BOOL ret = [self execSqlOnTemplateDatabase:sqlCmd
									ReturnData:&_array
									  Function:^(sqlite3_stmt* sqlstmt, NSObject** data){
										  NSMutableArray** _temp = (NSMutableArray**)data;
										  if ( _temp == nil ) return;
										  // DBからの取得
										  char* tmpId = (char*)sqlite3_column_text(sqlstmt, 0 );
										  char* title = (char*)sqlite3_column_text( sqlstmt,1);
										  char* body = (char*)sqlite3_column_text( sqlstmt, 2);
										  char* categoryId = (char*)sqlite3_column_text( sqlstmt, 3 );
										  char* date = (char*)sqlite3_column_text( sqlstmt, 4 );
										  
										  // テンプレート情報に設定
										  TemplateInfo* info = [[[TemplateInfo alloc] init] autorelease];
										  if ( tmpId ) [info setTmplId:[NSString stringWithUTF8String:tmpId]];
										  if ( title ) [info setStrTemplateTitle: [NSString stringWithUTF8String:title]];
										  if ( body ) [info setStrTemplateBody: [NSString stringWithUTF8String:body]];
										  if ( categoryId )[info setCategoryId:[NSString stringWithUTF8String:categoryId]];
										  if ( date )
										  {
											  // まずは日付の文字列からNSDateに変換
											  NSString* strDateSource = [NSString stringWithUTF8String:date];
											  NSDateFormatter* df = [[NSDateFormatter alloc] init];
											  [df setLocale:[NSLocale systemLocale]];
											  [df setTimeZone:[NSTimeZone systemTimeZone]];
											  [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
											  // NSDateからUNIX時刻へ
											  NSTimeInterval timeInt = [[df dateFromString:strDateSource] timeIntervalSince1970];
											  // UNIX時刻からNSDateへ
											  [info setDateTemplateUpdate: [NSDate dateWithTimeIntervalSince1970:timeInt]];
											  [df release];
										  }
										  [*_temp addObject:info];
									  }];
	
	return ((ret == YES) ? _array : nil);
}

#pragma mark category_database
/**
 insertCategory
 */
- (BOOL) insertCategory:(NSString*) strCategory Date:(NSTimeInterval) date
{
	NSString* uuid = [Common getUUID];
	NSString* tableId = [NSString stringWithFormat:@"'%@'", uuid];
	NSString* binString = @"?";
	BOOL ret = [self insertDataBaseInTable:tableId
									 Table:@"category_info"
									  Data:binString
									  Date:date
									  Bind:^( sqlite3_stmt* sqlstmt ){
										  // カテゴリー名のバインド
										  sqlite3_bind_text( sqlstmt, 1, [strCategory UTF8String], -1, SQLITE_TRANSIENT );
									  }
								  Function:^(BOOL* status){
										  if ( *status == YES )
										  {
											  //  fc_update_mng_time_deleteに更新履歴を追加
											  NSString* timeString = [Common convertPOSIX2String:date];
											  *status = [CloudSyncClientDatabaseUpdate newCategoryMakeWithID:uuid
																							   splite3Object:db
																								  UpdateDate:timeString];
										  }
									  }];
	return ret;
}

/**
 deleteCategory
 */
- (BOOL) deleteCategory:(NSString*) strCategoryId
{
	NSString* strCategoryTemp = [NSString stringWithFormat:@"'%@'", strCategoryId];

	/*
	 UPDATE category_info SET delete_flag = 1 WHERE category_id = id
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE category_info "];
	[sqlCmd appendFormat:@"SET delete_flag = 1 "];
	[sqlCmd appendFormat:@"WHERE category_id = %@ ", strCategoryTemp];
	BOOL ret = [self execSqlCommand:sqlCmd
							   Bind:nil
						   Function:^(BOOL *status) {
							   if ( *status == YES )
							   {
								   //  fc_update_mng_time_deleteに更新履歴を追加
								   *status = [CloudSyncClientDatabaseUpdate deleteCategoryMakeWithID:strCategoryId
																					   splite3Object:db];
							   }
						   }];

	if ( ret == YES )
	{
		// テンプレート上からカテゴリーを消す
		ret = [self deleteCategoryInTemplate:strCategoryId];
	}
	return ret;
}

/**
 deleteAllCategories
 */
- (BOOL) deleteAllCategories
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	
	/*
	 SELECT category_id FROM category_info WHERE account_id = accID AND delete_flag = 0 AND category_id != '30ADDBD2-A503-495E-8994-F3B691B809F7'
	 */
	NSMutableString* sqlCmd =  [self createSelectSqlCommand:@"category_id"
													  Table:@"category_info"
												 WhereColum:@"account_id"
												  WhereData:accID
												  AndColumn:@"delete_flag"
													AndData:@"0"];

	// 初期値「なし」以外を検索する
	[sqlCmd appendFormat:@" AND category_id != '30ADDBD2-A503-495E-8994-F3B691B809F7'"];
	
	// 絞り込み
	NSMutableArray* _arrayCategories = [[NSMutableArray alloc] init];
	[self execSqlOnTemplateDatabase:sqlCmd
						 ReturnData:nil
						   Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
							   char* category = (char*)sqlite3_column_text(sqlstmt, 0);
							   if ( category)
							   {
								   NSString* uuid = [NSString stringWithUTF8String:category];
								   [_arrayCategories addObject:uuid];
							   }
						   }];

	// 絞り込まれたカテゴリーに対して実行
	if ( [_arrayCategories count] > 0 )
	{
		for ( NSString* uuid in _arrayCategories )
		{
			// カテゴリーを削除する
			[self deleteCategory:uuid];
		}
	}
	[_arrayCategories release];
	return YES;
}

/*
 deleteCategoryInTemplate
 */
- (BOOL) deleteCategoryInTemplate:(NSString*) categoryId
{
	// 更新日時
	NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
	NSString* timeString = [Common convertPOSIX2String:date];

	/*
	 該当するテンプレートを検索する
	 */
	
	/*
	 SQL文の作成
	 SELECT template_id 
	  FROM mst_user_template
	   WHERE category_id = ? AND delete_flag = 0
	 */
	__block NSMutableArray* arrayTemplate = [NSMutableArray array];
	NSMutableString* selectCmd = [NSMutableString stringWithString:@"SELECT template_id"];
	[selectCmd appendString:@" FROM mst_user_template"];
	[selectCmd appendFormat:@" WHERE category_id = '%@' AND delete_flag = 0", categoryId];
	BOOL ret = [self execSqlOnTemplateDatabase:selectCmd
									ReturnData:nil
									  Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
										  char* tmplId = (char*)sqlite3_column_text(sqlstmt, 0);
										  if ( tmplId )
										  {
											  // テンプレートIDを格納しておく
											  [arrayTemplate addObject:[NSString stringWithUTF8String:tmplId]];
										  }
									  }];
									  
	if ( ret != YES )
		return ret;

	/*
	 該当するテンプレートからカテゴリーを削除する
	 fc_update_mng_time_deleteに操作履歴を残す為、
	 回りくどい事をしている
	 */
	for ( NSString* tmplId in arrayTemplate )
	{
		/*
		 SQL文の作成
		 UPDATE mst_user_template
		 SET category_id = NULL, update_date = julianday('%@')
		 WHERE template_id = tmplId AND delete_flag = 0
		 */
		NSMutableString* updateCmd = [NSMutableString stringWithString:@"UPDATE mst_user_template"];
		[updateCmd appendFormat:@" SET category_id = NULL, update_date = julianday('%@')", timeString];
		[updateCmd appendString:@" WHERE template_id = ? AND delete_flag = 0"];
		ret = [self execSqlCommand:updateCmd
							  Bind:^( sqlite3_stmt* sqlstmt ){
								  // カテゴリー名のバインド
								  sqlite3_bind_text( sqlstmt, 1, [tmplId UTF8String], -1, SQLITE_TRANSIENT );
							  }
						  Function:^(BOOL *status) {
							  //  fc_update_mng_time_deleteに更新履歴を追加
							  *status = [CloudSyncClientDatabaseUpdate editTemplateMakeWithID:tmplId
																				splite3Object:db
																				   UpdateDate:timeString];
						  }];
	}
	return ret;
}

/**
 updateCategory
 */
- (BOOL) updateCategory:(NSString*) strCategoryId
				   Date:(NSTimeInterval) date
			   NewValue:(NSString*) newValue
{
	NSString* categoryId = [NSString stringWithFormat:@"'%@'", strCategoryId];
	NSString* timeString = [Common convertPOSIX2String:date];

	/*
	 UPDATE category_info SET category_name = ?, update_date = xxxxxx WHERE category_id = xxxxx
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE category_info "];
	[sqlCmd appendString:@"SET category_name = ?,"];
	[sqlCmd appendFormat:@" update_date = julianday('%@') ", timeString];
	[sqlCmd appendFormat:@"WHERE category_id = %@", categoryId];
	BOOL ret = [self execSqlCommand:sqlCmd
							   Bind:^( sqlite3_stmt* sqlstmt ){
								   // カテゴリー名のバインド
								   sqlite3_bind_text( sqlstmt, 1, [newValue UTF8String], -1, SQLITE_TRANSIENT );
							   }
						   Function:^(BOOL *status) {
							   //  fc_update_mng_time_deleteに更新履歴を追加
							   *status = [CloudSyncClientDatabaseUpdate editCategoryMakeWithID:strCategoryId
																				 splite3Object:db
																					UpdateDate:timeString];
						   }];
	return ret;
}

/**
 loadCategoryName
 ID,Data,Dateを取得する
 */
- (BOOL) loadCategoryName:(NSMutableArray**) _arrayCategory
{
	if ( _arrayCategory == nil ) return NO;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	return [self getTableDataFrom:@"category_info"
						   Select:@"category_id, category_name, datetime(update_date)"
							Where:@"account_id"
							 Data:accID
							  Pos:1
						   Output:_arrayCategory
						 Category:YES];
}

/**
 chkCategoryName
 カテゴリの存在をチェックする
 */
- (BOOL) chkCategoryName : (NSString*) categoryName
{
	BOOL rt = true;
	NSMutableArray* _categoryNameList = [[NSMutableArray alloc] init];
	categoryName = [NSString stringWithFormat:@"'%@'", categoryName];
	[self getTableDataFrom:@"category_info"
						   Select:@"category_name"
							Where:@"category_name"
							 Data:categoryName
							  Pos:1
						   Output:&_categoryNameList
						 Category:YES];
	if ( [_categoryNameList count] > 1){
		rt = false;
	}else{
		rt = true;
	}
	
	return rt;
}

/**
 getCategoryID
 */
- (NSString*) getCategoryID:(NSString*) strCategory
{
	if ( strCategory == nil || [strCategory length] == 0 )
		return @"";

	/*
	 SELECT category_id FROM category_info WHERE account_id = xxxxx AND category_name = xxxxxx AND delete_flag = 0
	 */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	NSString* strCategoryTemp = [NSString stringWithFormat:@"'%@'", strCategory];

	// SQL文の作成
	NSMutableString* strSql = [self createSelectSqlCommand:@"category_id"
													 Table:@"category_info"
												WhereColum:@"account_id"
												 WhereData:accID
												 AndColumn:@"category_name"
												   AndData:strCategoryTemp];
	// delete_flagを参照する
	[strSql appendString:@"AND delete_flag = 0"];

	// SQLの実行
	NSString* idCategory = nil;
	[self execSqlOnTemplateDatabase:strSql
						 ReturnData:&idCategory
						   Function: ^(sqlite3_stmt* sqlstmt, NSObject** data){
							   // 取得
							   (*data) = [NSString stringWithUTF8String:(char*)sqlite3_column_text(sqlstmt, 0)];
						   }
	];
	return idCategory;
}

/**
 getCategoryTitleAtID
 */
- (NSString*) getCategoryTitleAtID:(NSString*) categoryId
{
	if ( categoryId == nil || [categoryId length] == 0 )
		return nil;

	/*
	 SELECT category_name FROM category_info WHERE category_id = categoryId AND delete_flag = 0
	 */

	// SQL文の作成
	NSMutableString* strSql = [self createSelectSqlCommand:@"category_name"
													 Table:@"category_info"
												WhereColum:@"category_id"
												 WhereData:[NSString stringWithFormat:@"'%@'", categoryId]
												 AndColumn:nil
												   AndData:nil];

	// delete_flagを参照する
	[strSql appendString:@"AND delete_flag = 0"];

	// SQLの実行
	NSString* strCategory = nil;
	[self execSqlOnTemplateDatabase:strSql
						 ReturnData:&strCategory
						   Function:^(sqlite3_stmt* sqlstmt, NSObject** data){
							   // 取得
							   NSString** str = (NSString**)data;
							   *str = [NSString stringWithUTF8String:(char*)sqlite3_column_text(sqlstmt, 0)];
						   }];
	return strCategory;
}


/**
 カテゴリーIDがデフォルト値（”なし”）かどうかの判定
 */
- (BOOL) isCategoryDefaultWithID:(NSString*) categoryId
{
	NSString* cmpString = @"30ADDBD2-A503-495E-8994-F3B691B809F7";
	return [cmpString isEqualToString:categoryId] ;
}


#pragma mark generalfield_database
/**
 insertGeneralField
 */
- (BOOL) insertGeneralField:(NSString*) strFieldData Date:(NSTimeInterval) date
{
	NSString* uuid = [Common getUUID];
	NSString* tableId = [NSString stringWithFormat:@"'%@'", uuid];
	NSString* bindString = @"?";
	BOOL ret = [self insertDataBaseInTable:tableId
									 Table:@"gen_field_info"
									  Data:bindString
									  Date:date
									  Bind:^( sqlite3_stmt* sqlstmt ){
										  // 汎用フィールド名のバインド
										  sqlite3_bind_text( sqlstmt, 1, [strFieldData UTF8String], -1, SQLITE_TRANSIENT );
									  }
								  Function:^(BOOL* status){
										  if ( *status == YES )
										  {
											  //  fc_update_mng_time_deleteに更新履歴を追加
											  NSString* timeString = [Common convertPOSIX2String:date];
											  *status = [CloudSyncClientDatabaseUpdate newGenFieldMakeWithID:uuid
																							   splite3Object:db
																								  UpdateDate:timeString];
										  }
									  }];
	return ret;
}

/**
 deleteGeneralField
 */
- (BOOL) deleteGeneralField:(NSString*) strGenFieldId
{
	NSString* strFieldTemp = [NSString stringWithFormat:@"'%@'", strGenFieldId];
	
	/*
	 UPDATE gen_field_info SET delete_flag = 1 WHERE gen_field_id = id
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE gen_field_info "];
	[sqlCmd appendFormat:@"SET delete_flag = 1 "];
	[sqlCmd appendFormat:@"WHERE gen_field_id = %@ ", strFieldTemp];
	BOOL ret = [self execSqlCommand:sqlCmd
							   Bind:nil
						   Function:^(BOOL *status) {
							   if ( *status == YES )
							   {
								   //  fc_update_mng_time_deleteに更新履歴を追加
								   *status = [CloudSyncClientDatabaseUpdate deleteGenFieldMakeWithID:strGenFieldId
																					   splite3Object:db];
							   }
						   }];
	return ret;
}

/**
 deleteAllGeneralFields
 */
- (BOOL) deleteAllGeneralFields
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	
	/*
	 SELECT gen_field_id FROM gen_field_info WHERE account_id = accID AND delete_flag = 0
	 */
	NSMutableString* sqlCmd =  [self createSelectSqlCommand:@"gen_field_id"
													  Table:@"gen_field_info"
												 WhereColum:@"account_id"
												  WhereData:accID
												  AndColumn:@"delete_flag"
													AndData:@"0"];
	
	// 絞り込み
	NSMutableArray* _arrayGenField = [[NSMutableArray alloc] init];
	[self execSqlOnTemplateDatabase:sqlCmd
						 ReturnData:nil
						   Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
							   NSString* uuid = [NSString stringWithUTF8String:(char*)sqlite3_column_text(sqlstmt, 0)];
							   [_arrayGenField addObject:uuid];
						   }];
	
	// 絞り込まれたカテゴリーに対して実行
	if ( [_arrayGenField count] > 0 )
	{
		for ( NSString* uuid in _arrayGenField )
		{
			// カテゴリーを削除する
			[self deleteGeneralField:uuid];
		}
	}
	[_arrayGenField release];
	return YES;
}

/**
 updateGeneralField
 */
- (BOOL) updateGeneralField:(NSString*) strGenFieldId
					   Date:(NSTimeInterval) date
				   NewValue:(NSString*) newValue
{
	NSString* genfieldId = [NSString stringWithFormat:@"'%@'", strGenFieldId];
	NSString* timeString = [Common convertPOSIX2String:date];
	
	/*
	 UPDATE gen_field_info SET gen_field_name = newData, update_date = date WHERE gen_field_id = genfieldId
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE gen_field_info "];
	[sqlCmd appendString:@"SET gen_field_name = ?,"];
	[sqlCmd appendFormat:@" update_date = julianday('%@') ", timeString];
	[sqlCmd appendFormat:@"WHERE gen_field_id = %@", genfieldId];
	BOOL ret = [self execSqlCommand:sqlCmd
							   Bind:^( sqlite3_stmt* sqlstmt ){
								   // 汎用フィールド名のバインド
								   sqlite3_bind_text( sqlstmt, 1, [newValue UTF8String], -1, SQLITE_TRANSIENT );
							   }
						   Function:^(BOOL *status) {
							   //  fc_update_mng_time_deleteに更新履歴を追加
							   *status = [CloudSyncClientDatabaseUpdate editGenFieldMakeWithID:strGenFieldId
																				 splite3Object:db
																					UpdateDate:timeString];
						   }];
	return ret;
}

/**
 loadGeneralFieldName
 */
- (BOOL) loadGeneralFieldName:(NSMutableArray **)arrayFieldName
{
	if ( arrayFieldName == nil ) return NO;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	return [self getTableDataFrom:@"gen_field_info"
						   Select:@"gen_field_id, gen_field_name, datetime(update_date)"
							Where:@"account_id"
							 Data:accID
							  Pos:1
						   Output:arrayFieldName
						 Category:NO];
}

/**
 getGenFieldID
 */
- (NSString*) getGenFieldID:(NSString*) strGenField
{
	if ( strGenField == nil || [strGenField length] == 0  )
		return @"";
	
	/*
	 SELECT gen_field_id FROM gen_field_info WHERE account_id = accID AND gen_field_name = strGenFieldTemp AND delete_flag = 0
	 */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	NSString* strGenFieldTemp = [NSString stringWithFormat:@"'%@'", strGenField];
	
	// SQL文の作成
	NSMutableString* strSql = [self createSelectSqlCommand:@"gen_field_id"
													 Table:@"gen_field_info"
												WhereColum:@"account_id"
												 WhereData:accID
												 AndColumn:@"gen_field_name"
												   AndData:strGenFieldTemp];
	// デリートフラグを参照する
	[strSql appendString:@"AND delete_flag = 0"];
	
	// SQLの実行
	NSString* idGenField = nil;
	[self execSqlOnTemplateDatabase:strSql
						 ReturnData:&idGenField
						   Function: ^(sqlite3_stmt* sqlstmt, NSObject** data){
							   // 取得
							   (*data) = [NSString stringWithUTF8String:(char*)sqlite3_column_text(sqlstmt, 0)];
						   }
	 ];
	return idGenField;
}


/**
 テンプレートのデータを取得する
 */
- (BOOL) getGenFieldIdByTemplateId:(NSString*)templateId
					   Gen1FieldId:(NSString**)gen1FieldId
					   Gen2FieldId:(NSString**)gen2FieldId
					   Gen3FieldId:(NSString**)gen3FieldId
{
	if ( templateId == nil
	||   gen1FieldId == nil
	||   gen2FieldId == nil
	||   gen3FieldId == nil )
		return NO;

	/*
	 SELECT gen1_field_id, gen2_field_id, gen3_field_id FROM mst_user_template WHERE template_id = templateId AND delete_flag = 0
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT gen1_field_id, gen2_field_id, gen3_field_id "];
	[sqlCmd appendFormat:@"FROM mst_user_template "];
	[sqlCmd appendFormat:@"WHERE template_id = '%@' AND delete_flag = 0", templateId];
	[self execSqlOnTemplateDatabase:sqlCmd
						 ReturnData:nil
						   Function: ^(sqlite3_stmt* sqlstmt, NSObject** data){
							   char* id1 = (char*)sqlite3_column_text(sqlstmt, 0);
							   char* id2 = (char*)sqlite3_column_text(sqlstmt, 1);
							   char* id3 = (char*)sqlite3_column_text(sqlstmt, 2);
							   // 取得
							   if ( id1 ) *gen1FieldId = [NSString stringWithUTF8String:id1];
							   if ( id2 ) *gen2FieldId = [NSString stringWithUTF8String:id2];
							   if ( id3 ) *gen3FieldId = [NSString stringWithUTF8String:id3];
						   }];
	return YES;
}

/**
 汎用フィールドIDから汎用フィールドデータを取得する
 */
- (NSString*) getGenFieldDataByID:(NSString*) genFieldId
{
	if ( genFieldId == nil )
		return nil;

	/*
	 SELECT gen_field_name FROM gen_field_info WHERE gen_field_id = genFieldId AND delete_flag = 0
	 */
	__block NSString* retString = nil;
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT gen_field_name "];
	[sqlCmd appendFormat:@"FROM gen_field_info "];
	[sqlCmd appendFormat:@"WHERE gen_field_id = '%@' AND delete_flag = 0", genFieldId];
	[self execSqlOnTemplateDatabase:sqlCmd
						 ReturnData:nil
						   Function: ^(sqlite3_stmt* sqlstmt, NSObject** data){
							   // 取得
							   retString = [NSString stringWithUTF8String:(char*)sqlite3_column_text(sqlstmt, 0)];
						   }];
	return retString;
}

/**
 指定フィールドが指定テンプレート以外で使用されているかの判定
 */
- (BOOL) isGenFieldUsed:(NSString*) genFieldId TmplId:(NSString*) tmplId Error:(BOOL*) error
{
	/*
	 SELECT COUNT(*) 
	  FROM mst_user_template
	   WHERE template_id != ?
	    AND (gen1_field_id = ? OR gen2_field_id = ? OR gen3_field_id = ?)
	    AND delete_flag = 0
	 */
	NSMutableString* sqlCmd = [NSMutableString string];
	[sqlCmd appendString:@"SELECT COUNT(*)"];
	[sqlCmd appendString:@" FROM mst_user_template"];
	[sqlCmd appendString:@"  WHERE template_id != ?"];
	[sqlCmd appendString:@"   AND (gen1_field_id = ? OR gen2_field_id = ? OR gen3_field_id = ?)"];
	[sqlCmd appendString:@"   AND delete_flag = 0"];

	// DBを開く
	*error = [self openDataBase];
	if ( *error != YES )
	{
		[self errDataBaseWriteLog];
		return NO;
	}

	BOOL ret = NO;
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [sqlCmd UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		// バインド変数をクリアー
		sqlite3_clear_bindings( sqlstmt );

		// テンプレートIDのバインド
		sqlite3_bind_text( sqlstmt, 1, [tmplId UTF8String], -1, SQLITE_TRANSIENT );
		// 汎用フィールドIDのバインド
		sqlite3_bind_text( sqlstmt, 2, [genFieldId UTF8String], -1, SQLITE_TRANSIENT );
		sqlite3_bind_text( sqlstmt, 3, [genFieldId UTF8String], -1, SQLITE_TRANSIENT );
		sqlite3_bind_text( sqlstmt, 4, [genFieldId UTF8String], -1, SQLITE_TRANSIENT );
		
		// SQL実行
		if ( sqlite3_step(sqlstmt) == SQLITE_ROW )
		{
			// カウントを取得
			ret = (sqlite3_column_int(sqlstmt, 0) > 0) ? YES : NO;
		}

	}
	else
	{
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize( sqlstmt );
	
	// DBを閉じる
	[self closeDataBase];
	return ret;
}

#pragma mark generalfielditem_database
/**
 insertGeneralFieldItem
 */
- (BOOL) insertGeneralFieldItemList:(NSArray*) fieldDataList
							   Type:(NSInteger) type
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	
	NSNumber* typeData = [NSNumber numberWithInteger:type];
		
	NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
	NSString* timeString = [Common convertPOSIX2String:date];
	NSString* timeReal = [NSString stringWithFormat:@"julianday('%@')", timeString]; // ユリウス日に変換しておく
	
	NSNumber* deleteFlag = [NSNumber numberWithInteger:0];
	
	for( NSString* genFieldName in fieldDataList )
	{
		NSString* uuid = [Common getUUID];
		NSString* tableId = [NSString stringWithFormat:@"'%@'", uuid];
		NSString* genFiledNameData = [NSString stringWithFormat:@"'%@'", genFieldName];
		
		NSMutableString* insertSql = [self createInsertCommand:ITEM_EDIT_GEN_FIELD_ITEM_TABLE
														  Data:tableId, accID, typeData, genFiledNameData, timeReal, deleteFlag, nil];
		
		// 挿入の実行
		BOOL ret = [self execSqlCommand:insertSql
							  Bind:nil
						  Function:^(BOOL* status){
							  if ( *status == YES )
							  {
								  //  fc_update_mng_time_deleteに更新履歴を追加
								  NSString* timeString = [Common convertPOSIX2String:date];
								  *status = [CloudSyncClientDatabaseUpdate newGenFieldItemMakeWithID:uuid
																					   splite3Object:db
																						  UpdateDate:timeString
																						subKey1Value:genFieldName];
							  }
						  }];
		
		if( !ret )	return ret;
	}
	return YES;
}

/**
 updateGeneralFieldItemList
 */
- (BOOL) updateGeneralFieldItemList:(NSArray*)updateDataList
{
	NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
	NSString* timeString = [Common convertPOSIX2String:date];
	
	for( NSArray *data in updateDataList )
	{
		NSString *genFieldId = [data objectAtIndex:0];
		NSString *genFieldName = [data objectAtIndex:1];
		
		/*
		 UPDATE gen_field_item SET gen_field_name = newData, update_date = date WHERE gen_field_id = genfieldId
		 */
		NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE %@ ", ITEM_EDIT_GEN_FIELD_ITEM_TABLE];
		[sqlCmd appendString:@"SET gen_field_name = ?,"];
		[sqlCmd appendFormat:@" update_date = julianday('%@') ", timeString];
		[sqlCmd appendFormat:@"WHERE gen_field_id = '%@'", genFieldId];
		BOOL ret = [self execSqlCommand:sqlCmd
								   Bind:^( sqlite3_stmt* sqlstmt ){
									   // 汎用フィールド名のバインド
									   sqlite3_bind_text( sqlstmt, 1, [genFieldName UTF8String], -1, SQLITE_TRANSIENT );
								   }
							   Function:^(BOOL *status) {
								   //  fc_update_mng_time_deleteに更新履歴を追加
								   *status = [CloudSyncClientDatabaseUpdate editGenFieldItemMakeWithID:genFieldId
																						 splite3Object:db
																							UpdateDate:timeString
																						  subKey1Value:genFieldName];
							   }];
		if( !ret )	return ret;
	}
	return YES;
}

/**
 loadGeneralFieldItemType NameData
 */
- (BOOL) loadGeneralFieldItemType:(NSInteger)type
						 NameData:(NSMutableArray **)arrayFieldName;
{
	//	TODO データベースのWhereにtypeでの判別を追加する必要がある！
	
	if ( arrayFieldName == nil ) return NO;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
	
	/*
	 SELECT gen_field_id, gen_field_name, datetime(update_date) FROM gen_field_itme
	 WHERE account_id = '' AND gen_field_type = 0 AND delete_flag = 0
	 */
	NSMutableString* selectSql = [NSMutableString stringWithFormat:@"SELECT gen_field_id, gen_field_name, datetime(update_date) "];
	[selectSql appendFormat:@"FROM %@ ", ITEM_EDIT_GEN_FIELD_ITEM_TABLE];
	[selectSql appendFormat:@"WHERE account_id = '%@' ", accID];
	[selectSql appendFormat:@"  AND gen_field_type = %ld ", (long)type];
	[selectSql appendFormat:@"  AND delete_flag = 0"];
	
	// DBを開く
	BOOL ret = [self openDataBase];
	if ( ret != YES )
	{
		[self errDataBaseWriteLog];
		return NO;
	}
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [selectSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		// 実行
		while ( sqlite3_step(sqlstmt) == SQLITE_ROW )
		{
			// DBから取得
			char* uuid = (char*)sqlite3_column_text( sqlstmt, 0 );
			char* data = (char*)sqlite3_column_text( sqlstmt, 1 );
			char* date = (char*)sqlite3_column_text( sqlstmt, 2 );
			
			// 検索結果を追加する
			NSMutableArray* _obj = [[[NSMutableArray alloc] init] autorelease];
			if ( uuid ) [_obj addObject:[NSString stringWithUTF8String:uuid]];	// ID
			if ( data )
			{
				[_obj addObject:[NSString stringWithUTF8String:data]];	// DATA
			}
			else
			{
				[_obj addObject:@""];	// DATA
			}
			if ( date )															// DATE
			{
				// まずは日付の文字列からNSDateに変換
				NSString* strDateSource = [NSString stringWithUTF8String:date];
				NSDateFormatter* df = [[NSDateFormatter alloc] init];
				[df setLocale:[NSLocale systemLocale]];
				[df setTimeZone:[NSTimeZone systemTimeZone]];
				[df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
				// NSDateからUNIX時刻へ
				NSTimeInterval timeInt = [[df dateFromString:strDateSource] timeIntervalSince1970];
				[_obj addObject:[NSNumber numberWithDouble:timeInt]];
				[df release];
			}
			
			// NSMutableArrayを追加
			[*arrayFieldName addObject:_obj];
		}
	}
	else
	{
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize( sqlstmt );
	
	// DBを閉じる
	[self closeDataBase];
	return YES;
}

/**
 deleteGeneralFieldItemList
 */
- (BOOL) deleteGeneralFieldItemList:(NSArray*) genFieldIdList
{
	for( NSString* genFieldId in genFieldIdList )
	{
		NSString* strFieldTemp = [NSString stringWithFormat:@"'%@'", genFieldId];
		
		/*
		 UPDATE gen_field_itme SET delete_flag = 1 WHERE gen_field_id = id
		 */
		NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE %@ ", ITEM_EDIT_GEN_FIELD_ITEM_TABLE];
		[sqlCmd appendFormat:@"SET delete_flag = 1 "];
		[sqlCmd appendFormat:@"WHERE gen_field_id = %@ ", strFieldTemp];
		BOOL ret = [self execSqlCommand:sqlCmd
								   Bind:nil
							   Function:^(BOOL *status) {
								   if ( *status == YES )
								   {
									   //  fc_update_mng_time_deleteに更新履歴を追加
									   *status = [CloudSyncClientDatabaseUpdate deleteGenFieldItemMakeWithID:genFieldId
																						   splite3Object:db];
								   }
							   }];
		if( !ret )	return ret;
	}
	return YES;
}

#pragma mark pict_url_database
/**
 insertPictureUrl
 */
- (BOOL) insertPictureUrl:(NSMutableArray*) pictUrl TemplateId:(NSString*) templId
{
	if ( templId == nil ) return NO;

	// 入力文字列の作成
	NSString* uuid = [Common getUUID];
	NSString* pictId = [NSString stringWithFormat:@"'%@'", uuid];
	NSString* strTemplId = [NSString stringWithFormat:@"'%@'", templId];
	NSString* strPictUrl = [NSString stringWithFormat:@"'%@'", (NSString*)[pictUrl objectAtIndex:0]];
	NSString* timeString = [Common convertPOSIX2String:[(NSNumber*)[pictUrl objectAtIndex:1] doubleValue]];
	NSString* timeReal = [NSString stringWithFormat:@"julianday('%@')", timeString]; // ユリウス日に変換しておく
	NSNumber* deleteFlag = [NSNumber numberWithInteger:0];
	
	// カテゴリーテーブルにデータを追加
	NSMutableString* insertSql = [self createInsertCommand:@"template_pict_info"
													  Data:pictId, strTemplId, strPictUrl, timeReal, deleteFlag, nil];
	
	// 挿入の実行
	return [self execSqlCommand:insertSql
						   Bind:nil
					   Function:^(BOOL *status) {
						   //  fc_update_mng_time_deleteに更新履歴を追加
						   *status = [CloudSyncClientDatabaseUpdate newTmplPictMakeWithID:uuid
																			splite3Object:db
																			   UpdateDate:timeString];
					   }];
}

/**
 insertPictureUrls
 */
- (BOOL) insertPictureUrls:(NSMutableArray*) pictUrls TemplateId:(NSString*) templId
{
	if ( pictUrls == nil ) return NO;
	for ( NSMutableArray* pictUrl in pictUrls )
	{
		// 画像の場所を追加する
		[self insertPictureUrl:pictUrl TemplateId:templId];
	}
	return YES;
}

/**
 deletePictureUrl
 */
- (BOOL) deletePictureUrl:(NSString*) pictId
{
	// 文字列の作成
	NSString* strPictId = [NSString stringWithFormat:@"'%@'", pictId];

	/*
	 UPDATE template_pict_info SET delete_flag = 1 WHERE template_pict_id = strPictId
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE template_pict_info "];
	[sqlCmd appendFormat:@"SET delete_flag = 1 "];
	[sqlCmd appendFormat:@"WHERE template_pict_id = %@ ", strPictId];
	return [self execSqlCommand:sqlCmd Bind:nil Function:^(BOOL *status) {
		//  fc_update_mng_time_deleteに更新履歴を追加
		*status = [CloudSyncClientDatabaseUpdate deleteTmplPictMakeWithID:pictId
															splite3Object:db];
	}];
}

/**
 deleteAllPictureUrls
 */
- (BOOL) deleteAllPictureUrls:(NSString*) templId
{
	// 文字列の作成
	NSString* strTemplId = [NSString stringWithFormat:@"'%@'", templId];
	
	/*
	 SELECT template_pict_id FROM template_pict_info WHERE template_id = strTemplId AND delete_flag = 0
	 */
	NSMutableString* sqlCmd =  [self createSelectSqlCommand:@"template_pict_id"
													  Table:@"template_pict_info"
												 WhereColum:@"template_id"
												  WhereData:strTemplId
												  AndColumn:@"delete_flag"
													AndData:@"0"];
	
	// 絞り込み
	NSMutableArray* _arrayPictUrls = [[NSMutableArray alloc] init];
	[self execSqlOnTemplateDatabase:sqlCmd
						 ReturnData:nil
						   Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
							   NSString* uuid = [NSString stringWithUTF8String:(char*)sqlite3_column_text(sqlstmt, 0)];
							   [_arrayPictUrls addObject:uuid];
						   }];
	
	// 絞り込まれたカテゴリーに対して実行
	if ( [_arrayPictUrls count] > 0 )
	{
		for ( NSString* uuid in _arrayPictUrls )
		{
			// カテゴリーを削除する
			[self deletePictureUrl:uuid];
		}
	}
	[_arrayPictUrls release];
	return YES;
}

/**
 getTemplatePictureUrls
 */
- (BOOL) getTemplatePictureUrls:(NSString*) templID PictUrls:(NSMutableArray*) arrayPictUrls
{
	// 文字列の作成
	NSString* strTemplId = [NSString stringWithFormat:@"'%@'", templID];

	/*
	 SELECT picture_url, picture_url FROM template_pict_info WHERE template_id = xxxxx AND delete_flag = 0
	 */
	NSMutableString* selectSql = [NSMutableString stringWithString:@"SELECT template_pict_id, picture_url "];
	[selectSql appendString:@"FROM template_pict_info "];
	[selectSql appendFormat:@"WHERE template_id = %@ ", strTemplId];
	[selectSql appendString:@"AND delete_flag = 0"];
	
	// SQL文の実行
	BOOL ret = [self execSqlOnTemplateDatabase:selectSql
									ReturnData:&arrayPictUrls
									  Function:^(sqlite3_stmt* sqlstmt, NSObject** data){
										  NSMutableArray** _temp = (NSMutableArray**)data;
										  // 入れ子作成
										  NSMutableArray* _obj = [[[NSMutableArray alloc] init] autorelease];
										  // データ取得
										  NSString* strPictId = [NSString stringWithUTF8String:(char*)sqlite3_column_text( sqlstmt, 0)];
										  NSString* strPictUrl = [NSString stringWithUTF8String:(char*)sqlite3_column_text( sqlstmt, 1)];
										  // 入れ子に追加
										  [_obj addObject:strPictId];
										  [_obj addObject:strPictUrl];
										  // データに追加
										  [*_temp addObject:_obj];
									  }];
	return ret;
}


/**
 テンプレート用画像が他のテンプレートで使用されているか判定する
 */
- (BOOL) isTemplatePictureUsed:(NSString*) tmplPictUrl TmplId:(NSString*)tmplId Error:(BOOL*) error
{
	/*
	 SELECT COUNT(*) FROM template_pict_info WHERE template_id != tmplId AND delete_flag = 0 AND template_pict_id = ?
	 */
	NSMutableString* sqlCmd = [NSMutableString string];
	[sqlCmd appendString:@"SELECT COUNT(*) FROM template_pict_info WHERE template_id != ? AND delete_flag = 0 AND picture_url = ?"];
	
	// DBを開く
	*error = [self openDataBase];
	if ( *error != YES )
	{
		[self errDataBaseWriteLog];
		return NO;
	}
	
	BOOL ret = NO;
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [sqlCmd UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		// バインド変数をクリアー
		sqlite3_clear_bindings( sqlstmt );
		
		// テンプレートIDのバインド
		sqlite3_bind_text( sqlstmt, 1, [tmplId UTF8String], -1, SQLITE_TRANSIENT );
		sqlite3_bind_text( sqlstmt, 2, [tmplPictUrl UTF8String], -1, SQLITE_TRANSIENT );
		
		// SQL実行
		if ( sqlite3_step(sqlstmt) == SQLITE_ROW )
		{
			// カウントを取得
			ret = (sqlite3_column_int(sqlstmt, 0) > 0) ? YES : NO;
		}
		
	}
	else
	{
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize( sqlstmt );
	
	// DBを閉じる
	[self closeDataBase];
	return ret;
}


/**
 */
- (BOOL) isTemplatePictureUsedByUrl:(NSString*) tmplUrl TmplId:(NSString*)tmplId Error:(BOOL*)error
{
	/*
	 SELECT COUNT(*) FROM template_pict_info WHERE template_id != tmplId AND delete_flag = 0 AND picture_url = ?
	 */
	NSMutableString* sqlCmd = [NSMutableString string];
	[sqlCmd appendString:@"SELECT COUNT(*) FROM template_pict_info WHERE template_id = ? AND delete_flag = 0 AND picture_url = ?"];
	
	// DBを開く
	*error = [self openDataBase];
	if ( *error != YES )
	{
		[self errDataBaseWriteLog];
		return NO;
	}
	
	BOOL ret = NO;
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [sqlCmd UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		// バインド変数をクリアー
		sqlite3_clear_bindings( sqlstmt );
		
		// テンプレートIDのバインド
		sqlite3_bind_text( sqlstmt, 1, [tmplId UTF8String], -1, SQLITE_TRANSIENT );
		sqlite3_bind_text( sqlstmt, 2, [tmplUrl UTF8String], -1, SQLITE_TRANSIENT );
		
		// SQL実行
		if ( sqlite3_step(sqlstmt) == SQLITE_ROW )
		{
			// カウントを取得
			ret = (sqlite3_column_int(sqlstmt, 0) > 0) ? YES : NO;
		}
		
	}
	else
	{
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize( sqlstmt );

	// DBを閉じる
	[self closeDataBase];
	return ret;
}


#pragma mark capture_info_database
/**
 取り込み画像情報をDBに追加する
 */
- (BOOL) insertCapturePictInfo:(NSString*)accountId PictUrl:(NSString*)pictUrl Date:(NSTimeInterval)date
{
	NSString* uuid = [Common getUUID];
	NSString* pictId = [NSString stringWithFormat:@"'%@'", uuid];
	NSString* tmpAccId = [NSString stringWithFormat:@"'%@'", accountId];
	NSString* tmpPictUrl = [NSString stringWithFormat:@"'%@'", pictUrl];
	NSString* timeString = [Common convertPOSIX2String:date];
	NSString* timeReal = [NSString stringWithFormat:@"julianday('%@')", timeString]; // ユリウス日に変換しておく

	/*
	 INSERT OR REPLACE INTO capture_pict_info VALUES( pictId, accountId, pictUrl, date )
	 */

	// SQL文の作成
	NSMutableString* sqlCmd = [self createInsertCommand:@"capture_pict_info" Data:pictId, tmpAccId, tmpPictUrl, timeReal, nil];

	// 挿入の実行
	return [self execSqlCommand:sqlCmd
						   Bind:nil
					   Function:nil];
}

/**
 アカウント指定で取り込んだ画像を取得する
 */
- (BOOL) getCapturePictInfo:(NSString*)accountId Data:(NSMutableArray**)captureData
{
	if ( accountId == nil || captureData == nil )
		return NO;

	/*
	 SELECT picture_url 
	  FROM capture_pict_info 
	   WHERE account_id = 'accountId'
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT capture_pict_id, picture_url, datetime(update_date) "];
	[sqlCmd appendString:@"FROM capture_pict_info "];
	[sqlCmd appendFormat:@"WHERE account_id = '%@'", accountId];

	[self execSqlOnTemplateDatabase:sqlCmd ReturnData:nil Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
		// DBから取得
		char* uuid = (char*)sqlite3_column_text(sqlstmt, 0);
		char* url = (char*)sqlite3_column_text(sqlstmt, 1);
		char* date = (char*)sqlite3_column_text(sqlstmt, 2);

		// 画像情報を取得
		NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
		if ( uuid ) [array addObject:[NSString stringWithUTF8String:uuid]];
		if ( url ) [array addObject:[NSString stringWithUTF8String:url]];
		if ( date )
		{
			// まずは日付の文字列からNSDateに変換
			NSString* strDateSource = [NSString stringWithUTF8String:date];
			NSDateFormatter* df = [[NSDateFormatter alloc] init];
			[df setLocale:[NSLocale systemLocale]];
			[df setTimeZone:[NSTimeZone systemTimeZone]];
			[df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			// NSDateからUNIX時刻へ
			NSTimeInterval timeInt = [[df dateFromString:strDateSource] timeIntervalSince1970];
			[array addObject:[NSNumber numberWithDouble:timeInt]];
			[df release];
		}
		// 画像情報を追加
		[*captureData addObject:array];
	}];
	return YES;
}

/**
 */
- (BOOL) getCapturePictInfoByPictId:(NSString*)capturePictId Data:(NSMutableArray**)captureData
{
	if ( capturePictId == nil || captureData == nil )
		return NO;
	
	/*
	 SELECT picture_url, update_date
	  FROM capture_pict_info
	   WHERE capture_pict_id = 'capturePictId'
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT picture_url, datetime(update_date) "];
	[sqlCmd appendString:@"FROM capture_pict_info "];
	[sqlCmd appendFormat:@"WHERE capture_pict_id = '%@'", capturePictId];
	
	[self execSqlOnTemplateDatabase:sqlCmd ReturnData:nil Function:^(sqlite3_stmt *sqlstmt, NSObject **data) {
		// DBから取得
		char* url = (char*)sqlite3_column_text(sqlstmt, 0);
		char* date = (char*)sqlite3_column_text(sqlstmt, 1);
		// 画像情報を取得
		if ( url ) [*captureData addObject:[NSString stringWithUTF8String:url]];
		if ( date )
		{
			// まずは日付の文字列からNSDateに変換
			NSString* strDateSource = [NSString stringWithUTF8String:date];
			NSDateFormatter* df = [[NSDateFormatter alloc] init];
			[df setLocale:[NSLocale systemLocale]];
			[df setTimeZone:[NSTimeZone systemTimeZone]];
			[df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			// NSDateからUNIX時刻へ
			NSTimeInterval timeInt = [[df dateFromString:strDateSource] timeIntervalSince1970];
			[*captureData addObject:[NSNumber numberWithDouble:timeInt]];
			[df release];
			}
	}];
	return YES;
}

/**
 取り込み画像情報をDBから削除する
 */
- (BOOL) deleteCapturePictInfo:(NSString*)capturePictId
{
	/*
	 DELETE FROM capture_pict_info WHERE capture_pict_id = 'capturePictId'
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"DELETE FROM capture_pict_info "];
	[sqlCmd appendFormat:@"WHERE capture_pict_id = '%@'", capturePictId];
	return [self execSqlCommand:sqlCmd Bind:nil Function:nil];
}


#pragma mark database_operator
/**
 insertDataBaseInTable
 指定テーブルにデータを挿入する
 @param tableName テーブル名
 @param strData 挿入するデータ
 */
- (BOOL) insertDataBaseInTable:(NSString*) tableId
						 Table:(NSString*) tableName
						  Data:(NSString*) strData
						  Date:(NSTimeInterval) date
						  Bind:(void (^)( sqlite3_stmt* sqlstmt )) bindFunc
					  Function:(void (^)( BOOL* status )) func
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	NSString* timeString = [Common convertPOSIX2String:date];
	NSString* timeReal = [NSString stringWithFormat:@"julianday('%@')", timeString]; // ユリウス日に変換しておく
	NSNumber* deleteFlag = [NSNumber numberWithInteger:0];

	// カテゴリーテーブルにデータを追加
	NSMutableString* insertSql = [self createInsertCommand:tableName
													  Data:tableId, accID, strData, timeReal, deleteFlag, nil];
	
	// 挿入の実行
	return [self execSqlCommand:insertSql Bind:bindFunc Function:func];
}

/**
 テーブルにデータを追加する
 */
- (NSMutableString*) createInsertCommand:(NSString*) table Data:(NSObject*) strData, ...
{
	NSMutableArray* arrayArgs = [NSMutableArray array];
	
	// 可変引数の取得
	va_list args;
	va_start(args, strData);
	for ( NSObject* arg = strData; arg != nil; arg = va_arg(args, NSObject*) )
	{
		// ひとまずNSMutableArrayに追加する
		[arrayArgs addObject:arg];
	}
	va_end(args);
	
	//
	// SQLのコマンドを作成
	//
	
	/*
	 データベースへの挿入コマンド
	 INSERT OR REPLACE INTO xxxxx VALUES(NULL, xxxx, xxxx, ....)
	 */
	
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@ VALUES(", table];
	for ( NSInteger i = 0; i < [arrayArgs count]; i++ )
	{
		// NSString
		NSObject* obj = [arrayArgs objectAtIndex:i];
		if ( [obj isKindOfClass:[NSString class]] )
		{
			NSString* str = (NSString*)obj;
			if ( i == ([arrayArgs count] - 1) )
			{
				// 文字列ラストは’）’で終了させる
				[sqlCmd appendFormat:@"%@)", str];
			}
			else
			{
				// 通常
				[sqlCmd appendFormat:@"%@, ", str];
			}
		}
		else
		if ( [obj isKindOfClass:[NSNumber class]] )
		{
			// NSNumber
			NSNumber* num = (NSNumber*)obj;
			// arm64の場合に、numがlongとなるため@encode(long)で比較する必要が有る
			if ((strcmp( [num objCType], @encode(int)) == 0) ||
				(strcmp( [num objCType], @encode(long)) == 0))
			{
				// INT型
				if ( i == ([arrayArgs count] - 1) )
				{
					// 文字列ラストは’）’で終了させる
					[sqlCmd appendFormat:@"%ld)", (long)[num integerValue]];
				}
				else
				{
					// 通常
					[sqlCmd appendFormat:@"%ld, ", (long)[num integerValue]];
				}
			}
			else
			if ( strcmp( [num objCType], @encode(double) ) == 0 )
			{
				// DOUBLE型
				if ( i == ([arrayArgs count] - 1) )
				{
					// 文字列ラストは’）’で終了させる
					[sqlCmd appendFormat:@"%f)", [num doubleValue]];
				}
				else
				{
					// 通常
					[sqlCmd appendFormat:@"%f, ", [num doubleValue]];
				}
			}
		}
	}
	
	return sqlCmd;
}

/**
 createDeleteCommandFrom
 @param tableName テーブル名
 @param account アカウントのカラム名
 @param accountName アカウント
 @param column カラム名（省略可）
 @param columnData カラムのデータ（省略可）
 */
- (NSMutableString*) createDeleteCommandFrom:(NSString*) tableName
									   Where:(NSString*) account
								   WhereData:(NSString*) accountName
									  Column:(NSString*) column
								  ColumnData:(NSString*) columnData
{
	/*
	 削除用SQL文
	 DELETE FROM tableName WHERE account = accountName AND column = columnData
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"DELETE FROM %@ ", tableName];
	[sqlCmd appendFormat:@"WHERE %@ ", account];
	[sqlCmd appendFormat:@"= %@ ", accountName];
	if ( column != nil )
	{
		[sqlCmd appendFormat:@"AND %@ ", column];
		[sqlCmd appendFormat:@"= %@", columnData];
	}
	return sqlCmd;
}

/**
 */
- (BOOL) updateDatabaseInTable:(NSString*) tableName
					ColumnName:(NSString*) columnName
				 ColumnNewData:(NSString*) newData
				 ColumnOldData:(NSString*) oldData
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [NSString stringWithFormat:@"'%@'", [defaults stringForKey:ACCOUNT_ID_SAVE_KEY]];
	
	//
	// SQLのコマンドを作成
	//
	NSMutableString* updateSql = [self createUpdateCommandFrom:tableName
													ColumnName:columnName
												   ColumnValue:newData
														 Where:@"account_id"
													WhereValue:accID
													  OldValue:oldData];
	[updateSql appendString:@"AND delete_flag = 0"];
	
	// DBのオープン＆トランザクション開始
	BOOL ret = [self dataBaseOpen4Transaction];
	if ( ret != YES ) return NO;
	
	// sqlstmtの生成
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [updateSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		// SQL実行
		if ( sqlite3_step(sqlstmt) != SQLITE_DONE )
		{
			// エラー
			ret = NO;
			//エラーメソッドをコール
			[self errDataBase];
		}
	}
	else
	{
		// エラー表示
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	// DBクローズ＆トランザクションの終了
	[self dataBaseClose2TransactionWithState: ret];
	
	return YES;
}

/**
 アップデートのクエリー文作成
 @param tableName
 @param columnName
 @param columnValue
 @param whereName
 @param whereValue
 @param oldValue
 */
- (NSMutableString*) createUpdateCommandFrom:(NSString*) tableName
								  ColumnName:(NSString*) columnName
								 ColumnValue:(NSString*) columnValue
									   Where:(NSString*) whereName
								  WhereValue:(NSString*) whereValue
									OldValue:(NSString*) oldValue
{
	/*
	 UPDATE tableName SET columnName = columnValue (WHERE whereName = whereValue AND columnName = oldValue)
	 */
	NSMutableString* sqlCmd = [NSMutableString stringWithFormat:@"UPDATE %@ ", tableName];
	[sqlCmd appendFormat:@"SET %@ ", columnName];
	[sqlCmd appendFormat:@"= %@ ", columnValue];
	if ( whereName != nil )
	{
		[sqlCmd appendFormat:@"WHERE %@ ", whereName];
		[sqlCmd appendFormat:@"= %@ ", whereValue];
		[sqlCmd appendFormat:@"AND %@ ", columnName];
		[sqlCmd appendFormat:@"= %@", oldValue];
	}
	return sqlCmd;
}

/**
 getTableDataFrom
 @param tableName テーブル名
 @param column カラム名
 @param columnData カラムデータ
 @return 文字列
 */
- (BOOL) getTableDataFrom:(NSString*) tableName
				   Select:(NSString*) selectCmd
					Where:(NSString*) column
					 Data:(NSString*) columnData
					  Pos:(NSInteger) pos
				   Output:(NSMutableArray**) _array
				 Category:(BOOL)isCategory
{
	/*
	 SELECT * FROM tablename WHERE column = columnData OR category_id = '30ADDBD2-A503-495E-8994-F3B691B809F7' AND delete_flag = 0
	  category_id = '30ADDBD2-A503-495E-8994-F3B691B809F7' => default
	 */
	NSMutableString* selectSql = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@ ", selectCmd, tableName];
	if ( isCategory )
	{
		[selectSql appendFormat:@"WHERE (%@ = %@ ", column, columnData];
		[selectSql appendString:@" OR category_id = '30ADDBD2-A503-495E-8994-F3B691B809F7')"];
	}
	else
	{
		[selectSql appendFormat:@"WHERE %@ = %@ ", column, columnData];
	}
	[selectSql appendFormat:@"  AND delete_flag = 0"];
	
	// DBを開く
	BOOL ret = [self openDataBase];
	if ( ret != YES )
	{
		[self errDataBaseWriteLog];
		return NO;
	}
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [selectSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		// 実行
		while ( sqlite3_step(sqlstmt) == SQLITE_ROW )
		{
			// DBから取得
			char* uuid = (char*)sqlite3_column_text( sqlstmt, 0 );
			char* data = (char*)sqlite3_column_text( sqlstmt, (int)pos );
			char* date = (char*)sqlite3_column_text( sqlstmt, 2 );
			
			// 検索結果を追加する
			NSMutableArray* _obj = [[[NSMutableArray alloc] init] autorelease];
			if ( uuid ) [_obj addObject:[NSString stringWithUTF8String:uuid]];	// ID
			if ( data )
			{
				[_obj addObject:[NSString stringWithUTF8String:data]];	// DATA
			}
			else
			{
				[_obj addObject:@""];	// DATA
			}
			if ( date )															// DATE
			{
				// まずは日付の文字列からNSDateに変換
				NSString* strDateSource = [NSString stringWithUTF8String:date];
				NSDateFormatter* df = [[NSDateFormatter alloc] init];
				[df setLocale:[NSLocale systemLocale]];
				[df setTimeZone:[NSTimeZone systemTimeZone]];
				[df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
				// NSDateからUNIX時刻へ
				NSTimeInterval timeInt = [[df dateFromString:strDateSource] timeIntervalSince1970];
				[_obj addObject:[NSNumber numberWithDouble:timeInt]];
				[df release];
			}

			// NSMutableArrayを追加
			[*_array addObject:_obj];
		}
	}
	else
	{
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize( sqlstmt );
	
	// DBを閉じる
	[self closeDataBase];
	return YES;
}

/**
 SELECT文の作成
 @param columnName
 @param tableName
 @param whereName
 @param whereData
 @param andColumn
 @param andData
 */
- (NSMutableString*) createSelectSqlCommand:(NSString*) columnName
									  Table:(NSString*) tableName
								 WhereColum:(NSString*) whereName
								  WhereData:(NSString*) whereData
								  AndColumn:(NSString*) andColumn
									AndData:(NSString*) andData
{
	/*
	 SELECT xxxxx FROM tableName WHERE xxxxx = xxxxxx AND xxxxx = xxxxxx
	 */
	NSMutableString* strSql = [NSMutableString stringWithFormat:@"SELECT %@ ", columnName];
	[strSql appendFormat:@"FROM %@ ", tableName];
	if ( whereName != nil )
	{
		[strSql appendFormat:@"WHERE %@ = %@", whereName, whereData];
	}
	if ( andColumn != nil )
	{
		[strSql appendFormat:@"AND %@ = %@", andColumn, andData];
	}
	return strSql;
}

// 2016/5/10 TMS テンプレートの並び順をタイトル順にする
/**
 SELECT文の作成（並び順指定）
 @param columnName
 @param tableName
 @param whereName
 @param whereData
 @param andColumn
 @param andData
 @param orderbyName
 */
- (NSMutableString*) createSelectSqlCommand:(NSString*) columnName
									  Table:(NSString*) tableName
								 WhereColum:(NSString*) whereName
								  WhereData:(NSString*) whereData
								  AndColumn:(NSString*) andColumn
									AndData:(NSString*) andData
								    Orderby:(NSString*) orderbyName
{
	/*
	 SELECT xxxxx FROM tableName WHERE xxxxx = xxxxxx AND xxxxx = xxxxxx
	 */
	NSMutableString* strSql = [NSMutableString stringWithFormat:@"SELECT %@ ", columnName];
	[strSql appendFormat:@"FROM %@ ", tableName];
	if ( whereName != nil )
	{
		[strSql appendFormat:@"WHERE %@ = %@", whereName, whereData];
	}
	if ( andColumn != nil )
	{
		[strSql appendFormat:@"AND %@ = %@", andColumn, andData];
	}
	if ( orderbyName != nil )
	{
		[strSql appendFormat:@" ORDER BY %@", orderbyName];
	}
	return strSql;
}

/**
 execSqlOnTemplateDatabase
 */
- (BOOL) execSqlOnTemplateDatabase:(NSString*) sqlStrings
						ReturnData:(NSObject**) retData
						  Function:(void (^)(sqlite3_stmt* sqlstmt, NSObject** data)) callback
{
	// DBを開く
	BOOL ret = [self openDataBase];
	if ( ret != YES )
	{
		[self errDataBaseWriteLog];
		return NO;
	}
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [sqlStrings UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		// コールバック実行
		while ( sqlite3_step(sqlstmt) == SQLITE_ROW )
		{
			// 検索結果を追加する
			callback( sqlstmt, retData );
		}
	}
	else
	{
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize( sqlstmt );
	
	// DBを閉じる
//	[self closeDataBase];
	return YES;
}

/**
 execSqlCommand
 */
- (BOOL) execSqlCommand:(NSString*) sqlStrings
				   Bind:(void (^)( sqlite3_stmt* sqlstmt )) bindFunc
			   Function:(void (^)( BOOL* status )) func
{
	// DBのオープン＆トランザクション開始
	BOOL ret = [self dataBaseOpen4Transaction];
	if ( ret != YES ) return NO;
	
	// sqlstmtの生成
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [sqlStrings UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// リセット
		sqlite3_reset( sqlstmt );
		// バインド変数をクリアー
		sqlite3_clear_bindings( sqlstmt );
		// バインド
		if ( bindFunc != nil )
			bindFunc( sqlstmt );

		// SQL実行
		if ( sqlite3_step(sqlstmt) != SQLITE_DONE )
		{
			// エラー
			ret = NO;
			//エラーメソッドをコール
			[self errDataBase];
		}
		if ( ret != NO && func != nil )
			func( &ret );
	}
	else
	{
		// エラー表示
		[self errDataBaseWriteLog];
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	// DBクローズ＆トランザクションの終了
	[self dataBaseClose2TransactionWithState: ret];
	
	return YES;

}

- (NSString*)getMaxSecretID {
	BOOL isDbOpen = NO;
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
		
		isDbOpen = YES;
	}
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	NSString *ret = [self selectSecretMemoByMax];
	NSLog(@"lay secretID max ban dau = %@",ret);
	
	[ud setObject:ret forKey:@"secret_memo_id_max"];
	[ud synchronize];
	
	if (isDbOpen)
	{
		//クローズ
		[self closeDataBase];
	}
	return (ret);
}

// 2016/6/24 TMS シークレットメモ対応
// シークレットメモを追加
- (BOOL) insertSecretMemoWithDateUserID:(USERID_INT)userID :(NSInteger*)secret_memo_id :(NSString*)memo :(NSDate*)wDate
{
	BOOL isDbOpen = NO;
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
		
		isDbOpen = YES;
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//insert文の作成
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"INSERT INTO secret_user_memo (user_id, memo, sakuseibi) "];
	[inssql appendString:@"  VALUES(?, ?, datetime('now', 'localtime'))"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数にユーザIDと日付を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%d",userID] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
						  [memo UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			if (isDbOpen)
			{[self closeDataBase]; }
			
			return (NO);
		}
#ifdef CLOUD_SYNC
		//sql文の解放
		sqlite3_finalize(sqlstmt);
		
		//secret id analyse
		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		NSString *status = [ud objectForKey:@"first_add"];
		NSString *ret = @"";
		ret = [self selectSecretMemoByMax];
		NSInteger lastID = [ret integerValue] - 1;
		
		NSLog(@"status = \%@",status);
		if (status == NULL) {
			NSLog(@"lay secretID max ban dau = %ld",(long)lastID);
			[ud setObject:@"false" forKey:@"first_add"];
			[ud setObject:[NSString stringWithFormat:@"%ld",(long)lastID] forKey:@"secret_memo_id_max"];
			[ud synchronize];
		}
	
		if ( ( [ret intValue] > 0) && ([CloudSyncClientDatabaseUpdate newSecretMemoMakeWithID:0
													   userID:userID
													 SecretMemo:memo
												sqlite3Object:db] ) )
		{
			//正常終了(COMMITをして処理を終了)
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
			stat = YES;
		}
		else
		{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		}
#else
		//正常終了(COMMITをして処理を終了)
		//sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	// このメソッド内でDBをOPENした場合はクローズする
	if (isDbOpen)
	{
		//クローズ
		[self closeDataBase];
	}
	
	return(stat);
}

// シークレットメモを更新
- (BOOL) updateSecretMemoWithDateUserID:(USERID_INT)userID :(NSInteger*)secret_memo_id :(NSString*)memo :(NSDate*)wDate
{
	BOOL isDbOpen = NO;
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
		
		isDbOpen = YES;
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//insert文の作成
	/*
	 INSERT INTO hist_user_work (user_id, work_date)
	 VALUES(1, julianday(date('2010-12-13')))
	 */
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"UPDATE secret_user_memo SET memo = ?"];
	[inssql appendString:@" WHERE user_id = ? AND secret_memo_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数にユーザIDと日付を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
						  [memo UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%d",userID] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%ld",(long)secret_memo_id] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			if (isDbOpen)
			{[self closeDataBase]; }
			
			return (NO);
		}
#ifdef CLOUD_SYNC
		if ( ( secret_memo_id > 0) &&
//			([CloudSyncClientDatabaseUpdate editSecretMemoMakeWithID:secret_memo_id
//													   userID:userID
//														   SecretMemo:memo
//													  sqlite3Object:db] ) )
			
			([CloudSyncClientDatabaseUpdate editSecretMemoMakeWithID:secret_memo_id userID:userID SecretMemo:memo Sakuseibi:wDate sqlite3Object:db]))

		{
			//正常終了(COMMITをして処理を終了)
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
			stat = YES;
		}
		else
		{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		}
#else
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	// このメソッド内でDBをOPENした場合はクローズする
	if (isDbOpen)
	{
		//クローズ
		[self closeDataBase];
	}
	
	return(stat);
}

// シークレットメモを削除
- (BOOL) deleteSecretMemoWithDateUserID:(USERID_INT)userID :(NSInteger*)secret_memo_id :(NSDate*)wDate
{
	BOOL isDbOpen = NO;
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (NO); }
		
		isDbOpen = YES;
	}
	
	BOOL stat = NO;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"DELETE FROM secret_user_memo "];
	[inssql appendString:@" WHERE user_id = ? AND secret_memo_id = ?"];
	
	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL)
		== SQLITE_OK)
	{
		// 構文解析の結果問題なし
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		
		// バインド変数にユーザIDと日付を設定
		u_int idx = 1;
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%d",userID] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,idx++,
						  [[NSString stringWithFormat:@"%ld",(long)secret_memo_id] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行してエラーが発生した場合はクローズさせて終了
		if(sqlite3_step(sqlstmt) != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			if (isDbOpen)
			{[self closeDataBase]; }
			
			return (NO);
		}
#ifdef CLOUD_SYNC
//		NSString *ret = [self selectSecretMemoByMax];
		
		if ( ( secret_memo_id > 0) &&
//			([CloudSyncClientDatabaseUpdate deleteSecretMemoMakeWithID:secret_memo_id
//															  userID:userID
//													   sqlite3Object:db] ) )
			
			([CloudSyncClientDatabaseUpdate deleteSecretMemoMakeWithID:secret_memo_id userID:userID withDate:wDate sqlite3Object:db]))
		{
			//正常終了(COMMITをして処理を終了)
			sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
			stat = YES;
		}
		else
		{
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
		}
#else
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		stat = YES;
#endif
	}
	else
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	// このメソッド内でDBをOPENした場合はクローズする
	if (isDbOpen)
	{
		//クローズ
		[self closeDataBase];
	}
	
	return(stat);
}

// secret_user_memoテーブルの作成
- (BOOL) secretUserMemoTableMake
{
	BOOL stat = NO;
	
	NSMutableString *pragmaSql = [NSMutableString string];
	
	// DBオープン
	stat = [self openDataBase];
	if ( stat != YES ) return  NO;
	
	[ pragmaSql appendString:@"CREATE TABLE IF NOT EXISTS secret_user_memo "];
	[ pragmaSql appendString:@"  ('secret_memo_id' INTEGER PRIMARY KEY AUTOINCREMENT, "];
	[ pragmaSql appendString:@"   'user_id' TEXT,"];
	[ pragmaSql appendString:@"   'memo' TEXT,"];
	[ pragmaSql appendString:@"   'sakuseibi' TEXT)"];

	sqlite3_stmt* sqlstmt;
	if ( sqlite3_prepare_v2(db, [pragmaSql UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK)
	{
		// 構文解析の結果問題なし
		stat = YES;
		
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		
		char *err;
		if(sqlite3_exec(db, [pragmaSql UTF8String], NULL, NULL, &err) != SQLITE_OK)
		{
			[self errDataBaseWriteLog];
			stat = NO;
		}
	}
	else
	{
		// データベースエラーのLog表示
		[self errDataBaseWriteLog];
		stat = NO;
	}
	
	NSLog(@"CREATE TABLE IF NOT EXISTS secret_user_memo !!!");
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	return (stat);
}

/**
 並び順を指定してシークレットメモを取得
 */
- (NSMutableArray*) selectSecretMemoOrderBy:(USERID_INT)userID : (int)OrderMode
{
	
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT secret_memo_id, user_id,memo, datetime(sakuseibi) "];
	[sqlCmd appendString:@"FROM secret_user_memo "];
	[sqlCmd appendFormat:@"WHERE user_id = '%d' ", userID];
	if(OrderMode == 1){
		[sqlCmd appendFormat:@"ORDER BY sakuseibi"];
	}else if(OrderMode == 2){
		[sqlCmd appendFormat:@"ORDER BY sakuseibi desc"];
	}else if(OrderMode == 3){
		[sqlCmd appendFormat:@"ORDER BY memo"];
	}else if(OrderMode == 4){
		[sqlCmd appendFormat:@"ORDER BY memo desc"];
	}else{
		[sqlCmd appendFormat:@"ORDER BY sakuseibi desc"];
	}

	
	// 取得する
	NSMutableArray* datas = [[NSMutableArray alloc] init];
	
	// データベースが閉じている場合はOPENする
	if (db == nil)
	{
		if (! [self openDataBase])
		{  return (datas); }
	}
	
	sqlite3_stmt* sqlstmt = nil;
	if ( sqlite3_prepare_v2(db, [sqlCmd UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		// バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt, 1, [[NSString stringWithFormat:@"%d",userID] UTF8String], -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			
			// 取得したrowからユーザ情報オブジェクトを生成
	//		userInfo* usrInfo = [[userInfo alloc] initWithUserInfo:userId
	//													 firstName:[self makeSqliteStmt2String:sqlstmt index:1]
			
			SecretMemoInfo* info = [[SecretMemoInfo alloc] init];
			info.secretMemoId = [self makeSqliteStmt2String:sqlstmt index:0];
			info.userId = [self makeSqliteStmt2String:sqlstmt index:1];
			info.memo = [self makeSqliteStmt2String:sqlstmt index:2];
			//NSString* strDateSource = [self makeSqliteStmt2String:sqlstmt index:3];

			NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			[formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
			//タイムゾーンの指定
			[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:60 * 60 * 9]];
			
			//NSDate *date = [formatter dateFromString:[self makeSqliteStmt2String:sqlstmt index:3]];
			
			info.sakuseibi = [formatter dateFromString:[self makeSqliteStmt2String:sqlstmt index:3]];

			// リストに加える
			[datas addObject:info];
			[info release];
		}
	}
	else
	{
		NSLog(@"selectSecretMemoOrderBy error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ
	[self closeDataBase];
	
	return (datas);
}

/**
 シークレットメモの最大値を取得
 */
- (NSString*) selectSecretMemoByMax
{
	NSString *ret;
	NSMutableString* sqlCmd = [NSMutableString stringWithString:@"SELECT max(secret_memo_id) as smax"];
	[sqlCmd appendString:@" FROM secret_user_memo "];

	sqlite3_stmt* sqlstmt = nil;
	if ( sqlite3_prepare_v2(db, [sqlCmd UTF8String], -1, &sqlstmt, NULL) == SQLITE_OK )
	{
		// sqlをリセット
		sqlite3_reset(sqlstmt);
		
		while (sqlite3_step(sqlstmt) == SQLITE_ROW)
		{
			ret = [self makeSqliteStmt2String:sqlstmt index:0];
		}

	}
	else
	{
		NSLog(@"selectSecretMemoByMax error at %@",
			  [[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]autorelease]);
	}
	
	// sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (ret);
}

@end
