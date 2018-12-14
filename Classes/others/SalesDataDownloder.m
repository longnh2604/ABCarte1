
//
//  SalesDataDownloder.m
//  iPadCamera
//
//  Created by  on 11/12/01.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SalesDataDownloder.h"

#import "../userDbManager.h"
#import "../model/OKDImageFileManager.h"

#import "Reachability.h"


#define ACCOUNT_ID_SAVE_KEY		@"accountIDSave"		// アカウントIDの保存用Key

///
/// 販社様用サンプルデータダウンロードクラス
///
@implementation SalesDataDownloder

#pragma mark private_mothods

// データを同期でWebより取得する
- (NSData*) _getImageData_:(NSString*)webUrl
{
	NSData *data = nil;
	
	@try {
		
		NSURL *url = [NSURL URLWithString:webUrl];
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		NSURLResponse *response = nil;
		NSError *error = nil;
		
		data = [NSURLConnection sendSynchronousRequest:request 
									 returningResponse:&response 
												 error:&error];
		if (error)
		{
			NSLog(@"_getImageData error -> %@", [error localizedDescription]);
			data = nil;
		}
	}
	@catch (NSException *exception) {
		NSLog(@"getImageData exception: Caught %@: %@", 
			  [exception name], [exception reason]);
		data = nil;
	}
	
	return (data);
}

// 販社様アカウントの確認
- (BOOL) _isSalesAccount
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if  ([defaults stringForKey:ACCOUNT_ID_SAVE_KEY] == nil)
    {   return (NO); }     // 未ログイン
    
    NSString *accountID = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
    
    // 最後文字が販社様アカウントかを最後の文字で判定
    BOOL stat = ( ([accountID hasSuffix: SALES_ACCOUNT_LAST_WORD]) ||
                  ([accountID hasSuffix: SALES_ACCOUNT_LAST_WORD_SMALL]) );
    
    return  (stat);
}

// ダウンロード済みかの確認
- (BOOL) _isDownloadComlite
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL stat = ( ([defaults objectForKey:APP_STORE_SALES_DEF_KEY] != nil) &&
                 ([defaults boolForKey:APP_STORE_SALES_DEF_KEY]) );
    
    return (stat);
}

// DBファイルのダウンロード
- (BOOL) _appStoreDbFileDownLoad
{
    // デバイス内のDBファイルの実パス
	NSString *docs 
        = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), DB_FILE_NAME];
	
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	// 既にDBファイルが存在する:既にインストール済み？
	if ( ([[NSFileManager defaultManager] fileExistsAtPath:docs]) &&
         ( ([defaluts objectForKey:APP_STORE_SALES_DEF_KEY] != nil) &&
           (! [defaluts boolForKey:APP_STORE_SALES_DEF_KEY]) ) )
	{
		// DBファイルのダウンロードをしない
		return (YES);
	}
	
	// urlを生成
	NSString *webUrl 
    = [NSString stringWithFormat:@"%@/%@/%@", 
       ACCOUNT_HOST_URL, APP_STORE_SALES_URL, APP_STORE_SALES_DB_NAME];
#ifdef DEBUG
	NSLog(@"get web db File->%@ to documents/%@", webUrl, DB_FILE_NAME);
#endif
	// データを同期でWebより取得する
	NSData *data = [self _getImageData_:webUrl];
	// 取得失敗
	if (! data)
	{	
		NSLog (@"db file:[%@] download error  ", APP_STORE_SALES_DB_NAME); 
		return (NO); 
	}
	
	BOOL stat = YES;
	
	// ドキュメントフォルダに保存
	if (! [data writeToFile: docs atomically:YES] )
	{	
		NSLog (@"db file:[%@] copy to document folder error  ", DB_FILE_NAME); 
		stat = NO;
	}
    
    // DBファイルダウンロードのみの完了（写真データ未）を示す
    [[NSUserDefaults standardUserDefaults] setBool:NO 
                                            forKey:APP_STORE_SALES_DEF_KEY];
	
	return (stat);
}

// ユーザIDと写真ファイル名(.jpg)にてサーバよりサムネイルをダウンロード
- (BOOL) _dowonloadThumbnail:(USERID_INT) userID fileName:(NSString*)fileName
{
    BOOL stat = YES;
    
    // Imageファイル管理を指定ユーザで作成する
	OKDImageFileManager *mng 
        = [[OKDImageFileManager alloc] initWithUserIDInCachesFolder:userID];
    
    // urlを生成
    NSMutableString *webUrl = [NSMutableString string];
    [webUrl appendFormat:@"%@/%@", ACCOUNT_HOST_URL, APP_STORE_SALES_URL];
    [webUrl appendString:@"/samples/"];
    [webUrl appendFormat:FOLDER_NAME_USER_ID, userID];
    [webUrl appendFormat:@"/%@", 
            [fileName stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
                                                withString:THUMBNAIL_SIZE_EXT]];
#ifdef DEBUG
	NSLog(@"get web thunmbnail image File->%@", webUrl);
#endif
	// データを同期でWebより取得する
	NSData *data = [self _getImageData_:webUrl];
	// 取得失敗
	if (! data)
	{	[mng release];
        return (NO); }
	
	// Imageオブジェクト生成
	UIImage *image = [UIImage imageWithData:data];
	
	// imageにてファイル保存する
	if(! [mng saveImageWithFileName:image 
                        fnPathExtNo:[fileName stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
                                                                        withString:@""]] )
	{	
        NSLog(@" copy image file error -> %@", fileName); 
        stat = NO;
    }
    
    return (stat);
}

// ユーザ代表写真のみダウンロード:サムネイル形式でダウンロード
- (BOOL) _appStoreHeadPictureDownLoad
{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    
    // SQL statementの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT user_id, picture_url "];
	[selectsql appendFormat:@"  FROM %@ ", MST_USER_TABLE];
    [selectsql appendString:@"    ORDER BY user_id"];
	
    NSNumber *isSaved = [usrDbMng _simpleOpenCloseTemplateWithArg:selectsql 
                                                      procHandler:^id (id args)
                         {
                             __block  BOOL iStat = YES;
                             
                             // SELECTの実行
                             [usrDbMng _selectSqlTemplateWithSql:selectsql
                                                     bindHandler: ^(sqlite3_stmt* sqlstmt)
                              {
                                  // バインド変数なし
                                  return;
                              }
                                                iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
                              {
                                  USERID_INT userID = sqlite3_column_int(sqlstmt, 0);
                                  NSString *fileName = [usrDbMng makeSqliteStmt2String:sqlstmt index:1];
                                  
                                  // ユーザIDと写真ファイル名(.jpg)にてサーバよりサムネイルをダウンロード
                                  iStat = [self _dowonloadThumbnail:userID fileName:fileName];
                                  
                                  return (iStat);
                              }
                              ];
                             
                             NSNumber *saved = [NSNumber numberWithBool:iStat];
                             return (saved);
                         }];
    
	
	
    [usrDbMng release];
    
    BOOL stat = (isSaved)? [isSaved boolValue] : NO;
    return (stat);
}

// 写真ファイル名(パス付き　.jpg)にてサーバより写真データをダウンロード
//                  0123456789012345678901234567890123456789
//      filename :  Documents/User00000001/110424_143342.jpg
- (BOOL) _dowonloadPictureWithPath:(NSString*)fileName
{
    // パス付きファイル名の長さチェック
    if ([fileName length] < 40)
    {   return (NO); }
    
    // 既にダウンロード済みか？
    /*NSFileManager *fileMng = [NSFileManager defaultManager];
    if ([fileMng fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",
                                    NSHomeDirectory(), fileName]] )
    {   return (YES); }*/
    
    BOOL stat = YES;
    
    // パスよりユーザIDを取得
    NSString *sUserID = [fileName substringWithRange:NSMakeRange(14, 8)];
    USERID_INT userID = [sUserID intValue];
    if (userID <= 0)
    {   return (NO); }
    
    // Imageファイル管理を指定ユーザで作成する
	OKDImageFileManager *mng 
        = [[OKDImageFileManager alloc] initWithUserIDInCachesFolder:userID];
    
    // パスよりファイル名を取得
    NSString *pictName = [fileName substringFromIndex:23];
    
    // urlを生成
    NSMutableString *webUrl = [NSMutableString string];
    [webUrl appendFormat:@"%@/%@", ACCOUNT_HOST_URL, APP_STORE_SALES_URL];
    [webUrl appendString:@"/samples/"];
    [webUrl appendFormat:FOLDER_NAME_USER_ID, userID];
    [webUrl appendFormat:@"/%@", pictName];
#ifdef DEBUG
	NSLog(@"get web real image File->%@", webUrl);
#endif
	// データを同期でWebより取得する
	NSData *data = [self _getImageData_:webUrl];
	// 取得失敗
	if (! data)
	{	[mng release];
        return (NO); }
	
	// Imageオブジェクト生成
	UIImage *image = [UIImage imageWithData:data];
	
	// imageにてファイル保存する
	if(! [mng saveImageWithFileName:image 
                        fnPathExtNo:[pictName stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
                                                                        withString:@""]] )
	{	
        NSLog(@" copy image file error -> %@", pictName); 
        stat = NO;
    }
    [mng release];
    return (stat);
}

// カルテ写真のダウンロード
- (BOOL) _karutePictsDownload
{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    
    // SQL statementの作成
	NSMutableString *selectsql = [NSMutableString string];
	[selectsql appendString:@"SELECT picture_url "];
	[selectsql appendString:@"  FROM fc_user_picture "];
    [selectsql appendString:@"    ORDER BY hist_id"];
	
    NSNumber *isSaved = [usrDbMng _simpleOpenCloseTemplateWithArg:selectsql 
                                                      procHandler:^id (id args)
                         {
                             __block  BOOL iStat = YES;
                             
                             // SELECTの実行
                             [usrDbMng _selectSqlTemplateWithSql:selectsql
                                                     bindHandler: ^(sqlite3_stmt* sqlstmt)
                              {
                                  // バインド変数なし
                                  return;
                              }
                                                iterationHandler: ^BOOL (sqlite3_stmt* sqlstmt)
                              {
                                  // filename : Documents/User00000001/110424_143342.jpg
                                  NSString *fileName = [usrDbMng makeSqliteStmt2String:sqlstmt index:0];
                                  
                                  // 写真ファイル名(パス付き　.jpg)にてサーバより写真データをダウンロード
                                  iStat = [self _dowonloadPictureWithPath:fileName];
                                  
                                  return (iStat);
                              }
                              ];
                             
                             NSNumber *saved = [NSNumber numberWithBool:iStat];
                             return (saved);
                         }];
    
	
	
    [usrDbMng release];
    
    BOOL stat = (isSaved)? [isSaved boolValue] : NO;
    return (stat);
}

#pragma mark life_cycle

#pragma mark public_methods

// 販社様用サンプルデータのダウンロード
-(BOOL) doDownloadWithStartHandler:(void(^)(void))hStart 
                    comleteHandler:(void(^)(BOOL downloadStat)) hComplite
                     isInitRehresh:(BOOL*)pIsRefresh
{
    *pIsRefresh = NO;
    
    // 販社様アカウントの確認
    if (! [self _isSalesAccount])
    {   return  (YES); }
    
    // ダウンロード済みかの確認
    if ([self _isDownloadComlite])
    {   return  (YES); }
    
    // ダウンロード開始ハンドラ
    if (hStart)
    {   hStart(); }
    
    __block BOOL stat = NO;
    
    // ネットワーク接続の確認
    dispatch_queue_t nwQueue = 
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(nwQueue, ^{
        
        REACHABLE_STATUS nwStat 
            = [ReachabilityManager reachabilityStatusWithHostName: ACCOUNT_HOST_URL];
        
        stat = (nwStat == REACHABLE_HOST);
        
    });
    if(! stat)
    {   return (NO); }      // ネットワーク接続エラー
    
    // DBファイルとユーザ代表写真のみ事前にダウンロード
    if ( ([self _appStoreDbFileDownLoad]) &&
         ([self _appStoreHeadPictureDownLoad] ) )
    {   
        *pIsRefresh = YES;
        userDbManager *usrDbMng = [[userDbManager alloc]init];
        [usrDbMng userpictureUpgradeVer114];
        [usrDbMng mstuserUpgradeVer122];
        [usrDbMng mstuserUpgradeVer140];
        [usrDbMng mstuserUpgradeVer172];
        // 2016/6/24 TMS シークレットメモ対応
        [usrDbMng secretUserMemoTableMake];
        // 2016/8/12 TMS 顧客情報に担当者を追加
        [usrDbMng mstuserUpgradeVer215];
        [usrDbMng release];
        // Global Queueの取得
        dispatch_queue_t queue = 
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        // 別スレッドにて残りの写真をダウンロード
        dispatch_async(queue, ^{
            
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            // カルテ写真のダウンロード
            if ([self _karutePictsDownload])
            {
                // ダウンロード済みを書き込み
                [[NSUserDefaults standardUserDefaults] setBool:YES 
                                                        forKey:APP_STORE_SALES_DEF_KEY];
                // 2012 07/26 伊藤
                // 起動時のダウンロードを再び行わないように
                [[NSUserDefaults standardUserDefaults] setBool:YES 
                                                        forKey:@"appstore_sample_download"];
                [[NSUserDefaults standardUserDefaults] setBool:YES 
                                                        forKey:@"appstore_sample_db_download"];
                stat = YES;
            }
            else
            {   stat = NO; }
            
            // mainスレッドへ完了を通知
            dispatch_async(dispatch_get_main_queue(), ^{
                if (hComplite)
                {   hComplite(stat); }
            });
            
            [pool release];
        });
    }
    else
	{	return (NO);  }
    
    return (stat);
}
@end
