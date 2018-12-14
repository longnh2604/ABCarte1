//
//  TestTable.m
//  Setting
//
//  Created by MacBook on 10/10/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UserTable.h"


@implementation UserTable

@synthesize db;
@synthesize dbPath;
@synthesize columnNames;
@synthesize tableName;

-(id)init
{
	self = [super init];
	
	// テーブル名
	tableName = TABLE_NAME;
	// 列名一覧
	columnNames = [[NSArray alloc] initWithObjects:
				   @"usrID",
				   @"name", 
				   @"regist", nil
				   ];
	
	// データベースの物理ファイルのフルパス
	NSArray *paths 
		= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:DB_FILE_NAME];
	
	//dbが存在しているかどうかの確認
	if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) 
	{
		//ファイルが存在しない場合、ファイルを作成する
		BOOL result = [[NSFileManager defaultManager] createFileAtPath:dbPath 
															  contents:nil attributes:nil];
		//ファイル作成が失敗した場合
		if (!result) 
		{
			NSLog(@"data base file create error at %@", dbPath);
			return (self);
		}
		
		//sqliteをオープンする
		if([self openDataBase]){
			//テーブルの作成
			[self createTable];
			
			//テーブルのクローズ
			[self closeDataBase];
		}
		
	}
	
	/*
	if([self openDataBase]){
		//データを登録
		[self insertData];
		//テーブルのクローズ
		[self closeDataBase];
	}
	*/
	 
	return self;
}

//sqliteをオープンする
-(BOOL)openDataBase{
	int ret;
	ret = sqlite3_open([dbPath UTF8String],&db);
	//正常終了
	if(ret == SQLITE_OK){
		return YES;
		//異常終了
	}else {
		//エラーが発生してしまったので、クローズを行う
		sqlite3_close(db);
		return NO;
	}
}

//tableの作成
-(BOOL)createTable{
	
	/*
	 CREATE TABLE mst_user 
		(usrID INTEGER PRIMARY KEY, name VARCHAR(24), regist BOOLEAN)
	 */
	
	//Table作成のsqlの設定
	NSMutableString *createsql = [NSMutableString string];
	[createsql appendString:@"CREATE TABLE "];
	[createsql appendString:tableName];
	[createsql appendString:@" ("];
	for (NSUInteger i=0; i< [columnNames count]; i++) 
	{
		[createsql appendString:[columnNames objectAtIndex:i]];
		switch (i) 
		{
			case 0:
				[createsql appendString:@" INTEGER PRIMARY KEY, "];
				break;
			case 1:
				[createsql appendString:@"  VARCHAR(24), "];
				break;
			case 2:
				[createsql appendString:@" BOOLEAN "];
				break;
			default:
				break;
		}
	}
	[createsql appendString:@")"];
	
	//各関数の戻り値
	int ret;
	//sql文を実行するための変数
	sqlite3_stmt *sqlstmt;
	
	ret = sqlite3_prepare_v2(db,[createsql UTF8String],-1,&sqlstmt,NULL);
	//実行準備おk
	if(ret == SQLITE_OK)
	{
		//sqlの実行を行う
		ret = sqlite3_step(sqlstmt);
		//sql文の解放
		sqlite3_finalize(sqlstmt);
		
		//sqlの実行が正常終了した場合
		if(ret == SQLITE_DONE)
		{
			return YES;
		}
	}
	
	//エラーメセッドをコール
	[self errDataBase];
	//dbクローズ
	[self closeDataBase];
	return NO;
	
}

// データの挿入
-(BOOL)insertData:(NSString*) name regist:(BOOL)isRegist
{
	/*
	 INSERT INTO mst_user(name, regist) VALUES('usr22', 0)
	 */
	
	NSArray *tmpArray 
		= [[NSArray alloc] initWithObjects:
		   // [NSString stringWithFormat : @"'%@'", name],
		   name,
		   (isRegist)? @"1" : @"0" ,
		   nil];
	
	BOOL q_Ret = NO;
	
	//各関数の戻り値
	int ret;
	
	//トランザクションの開始
	sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
	
	//insert文の作成
	sqlite3_stmt* sqlstmt;
	NSMutableString *inssql = [NSMutableString string];
	[inssql appendString:@"INSERT INTO "];
	[inssql appendString:tableName];
	[inssql appendString:@"("];
	for (NSUInteger i=0; i<[columnNames count]; i++) {
		if (i == 0) continue;		// 主キー:autoident
		
		[inssql appendString:((i>1)? @", " : @"")];
		[inssql appendString:[columnNames objectAtIndex:i]];
	}
	[inssql appendString:@") VALUES("];
	for (NSUInteger i=0; i<[tmpArray count]; i++) {
		[inssql appendString:((i>0)? @", " : @"")];
		[inssql appendString:@"?"];		// バインド変数
	}
	[inssql appendString:@")"];
	
	ret = sqlite3_prepare_v2(db, [inssql UTF8String], -1, &sqlstmt, NULL);
	//構文解析の結果問題なし(バインド前)
	if (ret == SQLITE_OK) 
	{
		//sqlをリセット
		sqlite3_reset(sqlstmt);
		//バインド変数をクリアー
		sqlite3_clear_bindings(sqlstmt);
		sqlite3_bind_text(sqlstmt,1,[[tmpArray objectAtIndex:0] UTF8String],-1,SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlstmt,2,[[tmpArray objectAtIndex:1] UTF8String],-1,SQLITE_TRANSIENT);
		
		//sql文を実行
		ret = sqlite3_step(sqlstmt);
			
		//一回でもエラーが発生した場合はクローズさせて終了
		if(ret != SQLITE_DONE)
		{
			//sql文の解放
			sqlite3_finalize(sqlstmt);
			//異常終了(ROLLBACKして処理を終了)
			sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
			//エラーメソッドをコール
			[self errDataBase];
			//dbをクローズ
			[self closeDataBase];
			return q_Ret;
		}
		
		//正常終了(COMMITをして処理を終了)
		sqlite3_exec(db, "COMMIT TRANSACTION", NULL, NULL, NULL);
		q_Ret = YES;
	}
	//構文解析の結果問題あり(バインド前)
	else 
	{
		//エラーメソッドをコール
		[self errDataBase];
		//異常終了(ROLLBACKして処理を終了)
		sqlite3_exec(db, "ROLLBACK TRANSACTION", NULL, NULL, NULL);
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	//クローズ -> 必要？
	// [self closeDataBase];
	return q_Ret;
}

// データの取得
- (NSMutableArray*)selectName:(NSString*) statement
{
	NSMutableArray* datas = [NSMutableArray array];
	[datas autorelease];
	
	/* SELECT name FROM mst_user WHERE usrID >= 16*/
	
	
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT "];
	[selectsql appendString:[columnNames objectAtIndex:1]];
	
	[selectsql appendString:@" FROM "];
	[selectsql appendString:TABLE_NAME];
	
	if ([statement length] > 0)
	{
		[selectsql appendString:@" WHERE "];
		[selectsql appendString:statement];
	}
		 
	sqlite3_stmt* sqlstmt;
	
	if (sqlite3_prepare_v2(db,[selectsql UTF8String],-1,&sqlstmt,NULL) 
			== SQLITE_OK)
	{
		while (sqlite3_step(sqlstmt) == SQLITE_ROW) 
		{
			// const unsigned char*をNSStringに変換
			NSString* name = [[NSString alloc] 
								initWithUTF8String:(const char*)sqlite3_column_text(sqlstmt, 0)];
			
			NSLog(@" name is %s %@", 
				  sqlite3_column_text(sqlstmt, 0),
				  name);
			
			[datas addObject:name];
		}
	}
	
	//sql文の解放
	sqlite3_finalize(sqlstmt);
	
	return (datas);
}

//sqliteをクローズする
-(void)closeDataBase{
	sqlite3_close(db);
}

//sqliteのエラー処理
-(void)errDataBase{
	
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:[[NSString alloc] initWithFormat:@"error:%d",sqlite3_errcode(db)]
							  message:[[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil
							  ];
	[alertView show];
	[alertView release];
	
}

@end
