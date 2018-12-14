//
//  iPadCameraAppDelegate.m
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "iPadCameraAppDelegate.h"
// #import "iPadCameraViewController.h"
#import "MainViewController.h"

#import "camaraViewController.h"

#import "userDbManager.h"
#ifdef HTTP_ON
#import "HttpFileUpDownLoaderManager.h"
#endif
#ifdef SAMPLE_DATA_DOWNLOAD
#import "./model/OKDImageFileManager.h"
#endif
#ifdef APP_STORE_SAMPLE_DATA
#import "./model/OKDImageFileManager.h"
#endif

#ifdef USE_ACCOUNT_MANAGER
#import "defines.h"
#import "AccountManager.h"
#endif

#import "iPadCameraAppDelegate.h"

#import "userDbManager.h"

#import "LockWindowPoupup.h"
#ifdef CLOUD_SYNC
#import "UserInfoListViewController.h"
#import "CloudSyncPictureUploadManager.h"
#endif

#ifdef MDM_DISTRIBUTION_VERSION
#import "VersionInfoManaegr.h"
#endif
#ifdef CHK_APPSTORE_VERSION
#import "AppStoreAPIHelper.h"
#endif

#import "SyncRotator.h"
#import "SelectVideoViewController.h"
#import "VideoCompViewController.h"

#import "dbUploader.h"

#import "SecurityManagerView.h"

#import "HistDetailViewController.h"
#import "SelectPictureViewController.h"
#import "PictureCompViewController.h"
#import "PicturePaintViewController.h"
#import "ThumbnailViewController.h"

//add fabric
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

//2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
#ifdef FOR_SALES
#define ARCHIVE_DB_NAME             @"appstore_sample_cloud.db.zip" // DBファイル
#define ARCHIVE_DATA_FOLDER         @"forSales"
#define ARCHIVE_SAMPLE_PICT_NAME    @"samplePictures.zip"           // サンプル画像(User00000001)
#define ARCHIVE_SAMPLE_MOVIE_NAME   @"sampleMovie.zip"              // サンプル動画(User00000001)
#define ARCHIVE_USER_PICT_NAME      @"userPictures.zip"             // サンプル画像(その他ユーザ)
#define ARCHIVE_USER_MOVIE_NAME     @"userMovie.zip"                // サンプル動画(その他ユーザ)
#import "ZipArchive.h"
#endif

#define SAMPLE_FILE_NUM     25

@implementation iPadCameraAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize navigationController;
@synthesize cameraView;
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
@synthesize bodyCheckView;
#endif
#ifdef HTTP_ON
@synthesize httpServerManager;
#endif
#ifdef USE_ACCOUNT_MANAGER
@synthesize accountCountine;
#endif
#ifdef CLOUD_SYNC
@synthesize cloudPictureUploader;
#endif
@synthesize videoUploader;

#ifdef USE_SPLASH_MOVIE
@synthesize mpmPlayerViewController;
#endif

#pragma mark local_methods
// バージョンアップに伴うデータベース更新の確認
- (void) dbUpdate4VersionUp
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	userDbManager *usrDbMng;
	
	usrDbMng = [[userDbManager alloc] init];
	
	BOOL stat;
    /*
    // GigasJapan sekine 2013/6/18追加
    // メール機能追加 ユーザー情報にemail1,email2追加
    //      TableName:mst_user   column:email1 type:text
    //      TableName:mst_user   column:email2 type:text
    stat = [usrDbMng checkExistColumnWithTableName:@"mst_user" columnName:@"email1"
									  isColumnMake:YES columnType:@"text"];
	if (!stat)
	{
		NSLog (@"databesa update error add email1");
	}
    stat = [usrDbMng checkExistColumnWithTableName:@"mst_user" columnName:@"email2"
									  isColumnMake:YES columnType:@"text"];
	if (!stat)
	{
		NSLog (@"databesa update error add email1");
	}*/
	
	// Ver101での更新：ユーザ登録番号の追加
	//		TableName:mst_user   column:regist_number type:interger
	stat = [usrDbMng checkExistColumnWithTableName:@"mst_user" columnName:@"regist_number"
									  isColumnMake:YES columnType:@"interger"];
	if (!stat)
	{
		NSLog (@"database update error for ver101 !!!");
	}
	//new database table for memo2
//	stat = [usrDbMng createTableMemo2];
//	if(!stat)
//	{
//		NSLog(@"failed to tables of memo2");
//	}
	
	// Ver105での更新：施術内容テーブルにで名前列を追加とidからのコンバート
	if (! [usrDbMng itemEditTableUpgrade4Ver105])
	{
		NSLog (@"database update error for ver105 !!!");
	}
	
	// Ver108:create backup_info table
	/*if ( ! [usrDbMng createBackUpInfoTable] )
	{
		NSLog (@"failed to create backup info table for ver108 !!!");
	}*/
    // Ver114での更新(伊藤)：写真管理テーブルに写真タイトルとコメントのカラムを追加
    //TODO:	2012.07.25	伊藤	サーバー側が対応するまでCLOUD_SYNC版では使用不可
	if (! [usrDbMng userpictureUpgradeVer114])
	{
		NSLog (@"database update error for ver114 !!!");
	}
    
    // GigasJapan sekine 2013/6/18追加
    // メール機能追加 ユーザー情報にemail1,email2追加
    //      TableName:mst_user   column:email1 type:text
    //      TableName:mst_user   column:email2 type:text
	if (! [usrDbMng mstuserUpgradeVer122])
	{
		NSLog (@"database update error for ver122 !!!");
	}
    //fc_user_video
    [usrDbMng createFcUserVideoTableMake];
    stat = [usrDbMng checkExistColumnWithTableName:@"fc_user_video" columnName:@"overlay"
									  isColumnMake:YES columnType:@"interger"];
    
    if (! [usrDbMng mstuserUpgradeVer140]) {
		NSLog (@"database update error for ver140 !!!");
    }
	if (!stat)
    {
        NSLog (@"database update error!!!");
    }
    
    stat = [usrDbMng createMstShopTableMake];
	if (!stat)
        NSLog (@"database update error!![Mst_Shop]");
    stat = [usrDbMng createFcBinaryUploadMngTableMake];
	if (!stat)
        NSLog (@"database update error!![Binary_Upload]");
    stat = [usrDbMng createFcHistInfoUpdateMngTableMake];
	if (!stat)
        NSLog (@"database update error!![Hist_Info_Update]");
    stat = [usrDbMng createFcParentChildShopTableMake];
	if (!stat)
        NSLog (@"database update error!![Parent_Child_Shop]");
    stat = [usrDbMng createFcUpdateMngTimeDeleteTableMake];
	if (!stat)
        NSLog (@"database update error!![Update_Mng_Time_Delete]");
    stat = [usrDbMng createFcUserInfoUpdateMngTableMake];
	if (!stat)
        NSLog (@"database update error!![User_Info_Update_Mng]");
    stat = [usrDbMng createFcUserWorkItemUpdateMngTableMake];
	if (!stat)
        NSLog (@"database update error!![User_Work_Item_Update_Mng]");

    if (! [usrDbMng mstuserUpgradeVer172]) {
        NSLog (@"database update error for ver172 !!!");
    }

    // 2016/6/24 TMS シークレットメモ対応
    if(![usrDbMng secretUserMemoTableMake]){
        NSLog (@"database update error for secretUserMemoTableMake !!!");
    }
    
    // 2016/8/12 TMS 顧客情報に担当者を追加
    if (! [usrDbMng mstuserUpgradeVer215]) {
        NSLog (@"database update error for ver215 !!!");
    }
	// 一斉送信メール向け
	// テンプレート用のデータベースを追加
	if ( [usrDbMng isExistTemplateDB] != YES )
		[usrDbMng createTemplateDB];
#ifdef COMMON_BUTTON
    if (![usrDbMng itemEditTableUpgrade4Ver150]) {
        NSLog(@"database update error [itemEditTableUpgrade4Ver150]");
    }
#endif
	[usrDbMng release];
}

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
			NSLog(@"getImageData error -> %@", [error localizedDescription]);
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

#ifdef SAMPLE_DATA_DOWNLOAD
// トライアルバージョンの設定
- (void) trialVersionSet
{
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];

	// 既に設定済みかを確認
	if ([defaluts objectForKey:@"trial_sample_get"])
	{	return; }
	// 設定済みをここで書き込み
	[defaluts setBool:YES forKey:@"trial_sample_get"];
	
	// 画像ファイル一覧
	NSArray *files 
		= [NSArray arrayWithObjects:
		   @"110425_143342", @"110427_092618", @"110427_092746", @"110425_143846", @"110426_130543", nil];
	
	for (NSUInteger idx = 0; idx < [files count]; idx++)
	{
		// Imageファイル管理をidx+1で作成する
		OKDImageFileManager *imgFileMng 
			= [[OKDImageFileManager alloc] initWithUserID:(idx + 1)];
		
		// 実サイズ版のファイル名
		NSString *oriFile 
			= [NSString stringWithFormat:@"%@.jpg", [files objectAtIndex:idx]];
		// ファイル存在確認
		if (! [ imgFileMng getRealSizeImage:oriFile] )
		{
			// ファイルが存在しないのでバンドルからimageを作成する
			UIImage* image = [UIImage imageNamed:oriFile];
			
			// imageにてファイル保存する
			if(! [imgFileMng saveImageWithFileName:image 
									   fnPathExtNo:(NSString*)[files objectAtIndex:idx]] )
			{
				NSLog(@" copy image file error -> %@", oriFile);
			}
		}
		
		[imgFileMng release];
	}
	
	// 残りデータの設定は別スレッドで行う
	[self performSelectorInBackground:@selector(_getImageFileOnWeb_:) 
										  withObject:nil];
}

// Webサイトより画像ファイルの取り込み（workerスレッド）
- (void) _getImageFileOnWeb_:(NSObject*)param
{
	NSAutoreleasePool *pool;
	pool = [[NSAutoreleasePool alloc] init];
	
	// ファイル名：日付部分
	static NSInteger fileDates[] =
		{110425, 110427, 110427, 110425, 110426};
	// ファイル名：時間部分
	static NSInteger fileTimes[] =
		{143343, 92619, 92747, 143847, 130544};
	// 履歴ID
	static NSInteger histID[] = {5, 14, 15, 7, 13};
	
	// URL
	static NSString *url = @"http://www2.okada.co.jp/ota/calulu/trial/samples";
	
	NSInteger arrayLen = sizeof(fileDates) / sizeof(NSInteger);
	for (NSInteger idx = 0; idx < arrayLen; idx++)
	{
		NSInteger usrID = idx + 1;
		
		// Imageファイル管理をidxで作成する
		OKDImageFileManager *imgFileMng 
			= [[OKDImageFileManager alloc] initWithUserID:usrID];

#define TRIAL_SAMPLES_PICTRUE_NUMS 6		// サンプル画像枚数
		for (NSInteger idTm = 0; idTm < TRIAL_SAMPLES_PICTRUE_NUMS; idTm++)
		{
			// ファイル名の基本部分を生成
			NSString *fileBase 
				= [NSString stringWithFormat:@"%d_%06d",fileDates[idx], (fileTimes[idx] + idTm)];
			
			// urlを生成
			NSString *webUrl 
				= [NSString stringWithFormat:@"%@/User%08d/%@.jpg", url, usrID, fileBase];
#ifdef DEBUG
			NSLog(@"get webFile->%@", webUrl);
#endif
			// データを同期でWebより取得する
			NSData *data = [self _getImageData_:webUrl];
			
			// 取得失敗
			if (! data)
			{	continue; }
			
			// Imageオブジェクト生成
			UIImage *image = [UIImage imageWithData:data];
			
			// imageにてファイル保存する
			if(! [imgFileMng saveImageWithFileName:image 
									   fnPathExtNo:fileBase] )
			{
				NSLog(@" copy image file error -> %@", fileBase);
				continue;
			}
		  
			// データベース内の写真urlはDocumentフォルダ以下で設定 -> TODO:変更必要
			NSString *docPictUrl = 
				[NSString stringWithFormat:@"Documents/User%08d/%@.jpg", usrID, fileBase];
		  
			userDbManager *usrDbMng = [[userDbManager alloc] init];
			
			// 保存したファイル名（パスなしの実サイズ版）でデータベースの履歴用のユーザ写真を追加
			[usrDbMng insertHistUserPicture:histID[idx] 
								 pictureURL:docPictUrl];	// docPictUrl -> fileName
		  
		  // データベースは取得都度閉じる
		  [usrDbMng release];
				  
		}
		
		[imgFileMng release];
	}
	
	// [pool drain];
	[pool release];
}

#endif

#define APP_STORE_SAMPLE_DEF_KEY	@"appstore_sample_download"
#define APP_STORE_SAMPLE_DB_DEF_KEY	@"appstore_sample_db_download"

#ifdef APP_STORE_SAMPLE_DATA

#define APP_STORE_SAMPLE_URL		@"sample_data"
#ifndef CLOUD_SYNC
#define APP_STORE_SAMPLE_DB_NAME	@"appstore_sample.db"
#else
#define APP_STORE_SAMPLE_DB_NAME	@"appstore_sample_cloud.db"
#endif

// imageファイルのダウンロードと保存
- (BOOL) imageFileDowlod2SaveWithFileName:(NSString*)fileName 
								UrlFolder:(NSString*)folder imgFileManager:(OKDImageFileManager*)mng
{
	// urlを生成
	NSString *webUrl 
		= [NSString stringWithFormat:@"%@/%@/pictures/%@/%@.jpg", 
					ACCOUNT_HOST_URL, APP_STORE_SAMPLE_URL, folder, fileName];
#ifdef DEBUG
	NSLog(@"get web image File->%@", webUrl);
#endif
	
	// データを同期でWebより取得する
	NSData *data = [self _getImageData_:webUrl];
	// 取得失敗
	if (! data)
	{	return (NO); }
	
	// Imageオブジェクト生成
	UIImage *image = [UIImage imageWithData:data];
	
	// imageにてファイル保存する
	if(! [mng saveImageWithFileName:image 
							   fnPathExtNo:fileName] )
	{	NSLog(@" copy image file error -> %@", fileName); }
	
	return (YES);		// エラーでも継続
}

// movieファイルのダウンロードと保存
- (BOOL) movieFileDowlod2SaveWithFileName:(NSString*)fileName
								UrlFolder:(NSString*)folder imgFileManager:(OKDImageFileManager*)mng
{
	// urlを生成
	NSString *webUrl
    = [NSString stringWithFormat:@"%@/%@/movies/%@/%@.mp4",
       ACCOUNT_HOST_URL, APP_STORE_SAMPLE_URL, folder, fileName];
#ifdef DEBUG
	NSLog(@"get web movie File->%@", webUrl);
#endif
	
	// データを同期でWebより取得する
	NSData *data = [self _getImageData_:webUrl];
	// 取得失敗
	if (! data)
	{	return (NO); }

#ifdef DEBUG
    NSString *movieFullPath = [NSString stringWithFormat:@"%@/Documents/User%08d/%@.mov", NSHomeDirectory(), 1, fileName];
    NSLog(@"full path : [%@]", movieFullPath);
#endif
	
	// movieファイル保存する
	if(! [mng saveMovieWithFileName:data
                        fnPathExtNo:fileName] )
	{	NSLog(@" copy movie file error -> %@", fileName); }
	
	return (YES);		// エラーでも継続
}

// DBファイルのダウンロード
- (BOOL)appStoreDbFileDownLoad
{
	// デバイス内のDBファイルの実パス
	NSString *docs 
		= [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), DB_FILE_NAME];
	
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	// urlを生成
	NSString *webUrl 
		= [NSString stringWithFormat:@"%@/%@/%@", 
				ACCOUNT_HOST_URL, APP_STORE_SAMPLE_URL, APP_STORE_SAMPLE_DB_NAME];
    
#ifdef DEBUG
	NSLog(@"get web db File->%@ to documents/%@", webUrl, DB_FILE_NAME);
#endif
	// データを同期でWebより取得する
	NSData *data = [self _getImageData_:webUrl];
	// 取得失敗
	if (! data)
	{	
		NSLog (@"db file:[%@] download error  ", APP_STORE_SAMPLE_DB_NAME);
        [defaluts setBool:NO forKey:APP_STORE_SAMPLE_DB_DEF_KEY];

		return (NO); 
	}
	
	BOOL stat = YES;
	
	// ドキュメントフォルダに保存
	if (! [data writeToFile: docs atomically:YES] )
	{	
		NSLog (@"db file:[%@] copy to document folder error  ", DB_FILE_NAME); 
		stat = NO;
	}
	
	return (stat);
}

// ユーザ代表写真のダウンロード
- (BOOL)appStoreHeadPictureDownLoad
{
	// Imageファイル管理を固定ユーザ(ID=1)で作成する
	OKDImageFileManager *mng 
		= [[OKDImageFileManager alloc] initWithUserIDInCachesFolder:1];
	
	// imageファイルのダウンロードと保存
	BOOL stat 
		= ([self imageFileDowlod2SaveWithFileName:@"110810_011201" 
										UrlFolder:@"iPad" imgFileManager:mng]);
	
	[mng release];
	
	
	return (stat);
}

// カルテ写真のダウンロード
- (void) karutePictsDownload
{
	// カテゴリのフォルダ
	NSArray *cates = [NSArray arrayWithObjects:@"iPad", @"airmicro50", @"airmicro100", nil];
	// ファイル日付部
	NSArray *fileDates = [NSArray arrayWithObjects:@"110810", @"110805", @"110801", nil]; 
	// ファイル時間部
	NSArray *fileTimes 
		= [NSArray arrayWithObjects:@"011201", @"111201", @"111202", @"111203", 
									@"111204", @"111205", @"111206", nil]; 
	
	// Imageファイル管理を固定ユーザ(ID=1)で作成する
	OKDImageFileManager *mng 
		= [[OKDImageFileManager alloc] initWithUserIDInCachesFolder:1];
	
    CGFloat nowDlFileNum = 0.0f;
	for (NSUInteger idx = 0; idx < [cates count]; idx++)
	{
		for (NSUInteger idy = 0; idy < [fileTimes count]; idy++)
		{
			// 取得するファイル名
			NSString *fn = [NSString stringWithFormat:@"%@_%@",
								[fileDates objectAtIndex:idx], [fileTimes objectAtIndex:idy]];
			
			// imageファイルのダウンロードと保存 : エラーでも続行
			[self imageFileDowlod2SaveWithFileName:fn
										 UrlFolder:[cates objectAtIndex:idx]
									imgFileManager:mng];
            nowDlFileNum += 1.0f;
            [LockWindowPoupup setProgressValueOnLockView:((nowDlFileNum + 2.0f) / SAMPLE_FILE_NUM)];

		}

	}
	
	[mng release];
}

// カルテ動画のダウンロード
- (void) karuteMoviesDownload
{
	// カテゴリのフォルダ
	NSArray *cates = [NSArray arrayWithObjects:@"golf", nil];
	// ファイル日付部
	NSArray *fileDates = [NSArray arrayWithObjects:@"130705", @"130705", nil];
	// ファイル時間部
	NSArray *fileTimes
    = [NSArray arrayWithObjects:@"191501", @"191502", nil];
	
	// Imageファイル管理を固定ユーザ(ID=1)で作成する
	OKDImageFileManager *mng
    = [[OKDImageFileManager alloc] initWithUserIDInCachesFolder:1];
	
    CGFloat nowDlFileNum = SAMPLE_FILE_NUM - [fileTimes count];
	for (NSUInteger idx = 0; idx < [cates count]; idx++)
	{
		for (NSUInteger idy = 0; idy < [fileTimes count]; idy++)
		{
			// 取得するファイル名
			NSString *fn = [NSString stringWithFormat:@"%@_%@",
                            [fileDates objectAtIndex:idx], [fileTimes objectAtIndex:idy]];
			
			// movieファイルのダウンロードと保存 : エラーでも続行
			[self movieFileDowlod2SaveWithFileName:fn
										 UrlFolder:[cates objectAtIndex:idx]
									imgFileManager:mng];
            nowDlFileNum += 1.0f;
            [LockWindowPoupup setProgressValueOnLockView:((nowDlFileNum + 2.0f) / SAMPLE_FILE_NUM)];
            
		}
        
	}
	
	[mng release];
}

// AppStoreサンプルデータのダウンロード
- (void) appStoreSampleDownload
{
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	if([defaluts objectForKey:APP_STORE_SAMPLE_DEF_KEY] == nil){
        [defaluts setBool:NO forKey:APP_STORE_SAMPLE_DEF_KEY];
    }
    if([defaluts objectForKey:APP_STORE_SAMPLE_DB_DEF_KEY] == nil){
        [defaluts setBool:NO forKey:APP_STORE_SAMPLE_DB_DEF_KEY];
    }

	// 既にダウンロード済みかを確認
    // デバイス内のDBファイルの実パス
	NSString *docs 
    = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), DB_FILE_NAME];
	
	if ([defaluts boolForKey:APP_STORE_SAMPLE_DEF_KEY] && [[NSFileManager defaultManager] fileExistsAtPath:docs])
	{	return; }
    [self copyDefaultDb];
    [MainViewController setDbdownloadEnd:NO];

    // Global Queueの取得
	dispatch_queue_t queue = 
	dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(queue, ^{
        BOOL dbdlSuccess = NO;
        // DBファイルとユーザ代表写真のみ事前にダウンロード
        NSLog(@"DLStart");
        if(![defaluts boolForKey:APP_STORE_SAMPLE_DB_DEF_KEY]){

            if ([self appStoreHeadPictureDownLoad])
            {
                [LockWindowPoupup setProgressValueOnLockView:1 / SAMPLE_FILE_NUM];
                if ([self appStoreDbFileDownLoad] ){
                    [self dbUpdate4VersionUp];
                    [defaluts setBool:YES forKey:APP_STORE_SAMPLE_DB_DEF_KEY];
                    [LockWindowPoupup setProgressValueOnLockView:2 / SAMPLE_FILE_NUM];
                    dbdlSuccess = YES;
                    // バージョンアップに伴うデータベース更新の確認
                    [self dbUpdate4VersionUp];
                }
            }
        }else{
            [LockWindowPoupup setProgressValueOnLockView:2 / SAMPLE_FILE_NUM];
            dbdlSuccess = YES;
        }
        if (dbdlSuccess) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            // カルテ写真のダウンロード
            [self karutePictsDownload];
#ifdef DEF_ABCARTE
            // カルテ動画のダウンロード
            [self karuteMoviesDownload];
#endif
            // ダウンロード済みをここで書き込み
            [defaluts setBool:YES forKey:APP_STORE_SAMPLE_DEF_KEY];
            [defaluts synchronize];

            [pool release];
        }
        [MainViewController setDbdownloadEnd:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"sampleDlEnded"
                                                                object:nil];
        });
	});
}
#endif

//2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
#ifdef FOR_SALES
- (void) demoSampleDownload
{
    // 設定ファイル管理インスタンスを取得
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    if([defaluts objectForKey:APP_STORE_SAMPLE_DEF_KEY] == nil){
        [defaluts setBool:NO forKey:APP_STORE_SAMPLE_DEF_KEY];
    }
    if([defaluts objectForKey:APP_STORE_SAMPLE_DB_DEF_KEY] == nil){
        [defaluts setBool:NO forKey:APP_STORE_SAMPLE_DB_DEF_KEY];
    }
    
    // iPadCamera-info.plistよりバージョン番号を取得:Bundle Versionキーで設定
    NSString *ver
    = [ [[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    // 設定ファイルよりバージョン番号を取得
    NSString *setVer = [ defaluts stringForKey:@"appInfo_version"];
    // 双方が異なれば、設定ファイル側を更新
    BOOL isUpdateVersion = ! [setVer isEqualToString:ver];
    
    // 既にダウンロード済みかを確認
    // デバイス内のDBファイルの実パス
    NSString *docs
    = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), DB_FILE_NAME];
    
    BOOL isFirstDL = !([defaluts boolForKey:APP_STORE_SAMPLE_DEF_KEY] && [[NSFileManager defaultManager] fileExistsAtPath:docs]);
    if (!isFirstDL && !isUpdateVersion)
    {	return; }
    [self copyDefaultDb];
    [MainViewController setDbdownloadEnd:NO];
    
    // Global Queueの取得
    dispatch_queue_t queue =
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        BOOL dbdlSuccess = NO;
        // DBファイルとユーザ代表写真のみ事前にダウンロード
        NSLog(@"デモ版サンプルデータダウンロード開始");
        if(![defaluts boolForKey:APP_STORE_SAMPLE_DB_DEF_KEY] || isUpdateVersion){
            progressPos = 0;
            [LockWindowPoupup setProgressValueOnLockView:(progressPos / SAMPLE_FILE_NUM)];
            NSString *tmpFolder = NSTemporaryDirectory();
            NSString *path = [tmpFolder stringByAppendingPathComponent:ARCHIVE_DB_NAME];
            NSData *data = [self getArchiveFile:ARCHIVE_DB_NAME
                                      UrlFolder:ARCHIVE_DATA_FOLDER];
            [LockWindowPoupup setProgressValueOnLockView:(++progressPos / SAMPLE_FILE_NUM)];
            [data writeToFile:path atomically:YES];
            if (![defaluts boolForKey:APP_STORE_SAMPLE_DB_DEF_KEY]){
                if ([self doFileUnArchive:path destFolder:@"Documents"]) {
                    [self dbUpdate4VersionUp];
                    [defaluts setBool:YES forKey:APP_STORE_SAMPLE_DB_DEF_KEY];
                    // 解凍が成功したら、アーカイブファイルを削除
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                    dbdlSuccess = YES;
                    [LockWindowPoupup setProgressValueOnLockView:(++progressPos / SAMPLE_FILE_NUM)];
                    [defaluts setObject:ver forKey:@"appInfo_version"];
                }
            } else {
                // アップデート時
                if ([self doFileUnArchive:path destFolder:@"Documents/Update"]) {
                    [self dbUpdate4VersionUp];
                    
                    userDbManager2 *dbManager = [[userDbManager2 alloc] init];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSArray *demoUserIds = [dbManager getDemoUserIds];
                    for (NSNumber *userID in demoUserIds) {
                        NSString *folder = [NSString stringWithFormat:FOLDER_NAME_USER_ID, [userID intValue]];
                        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), folder] error:NULL];
                    }
                    NSString *dir
                    = [NSString stringWithFormat:@"%@/Documents/Update", NSHomeDirectory()];
                    
                    /* 全てのファイル名 */
                    NSArray *allImagePaths = [iPadCameraAppDelegate imageAndMovieFileNamesAtDirectoryPath:dir];
                    for (NSString *imagePath in allImagePaths) {
                        NSString *fromPath = [NSString stringWithFormat:@"%@/Documents/Update/%@", NSHomeDirectory(), imagePath];
                        NSString *toPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), imagePath];
                        [iPadCameraAppDelegate moveFile:fromPath to:toPath];
                    }
                    
                    if([dbManager mergeDB:[NSString stringWithFormat:@"%@/%@", dir, @"cameraApp.db"]]){
                        dbdlSuccess = YES;
                    }
                    // 解凍が成功したら、アーカイブファイルを削除
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                    [LockWindowPoupup setProgressValueOnLockView:(++progressPos / SAMPLE_FILE_NUM)];
                }
            }
        }else{
            [LockWindowPoupup setProgressValueOnLockView:2 / SAMPLE_FILE_NUM];
            dbdlSuccess = YES;
        }
        if (dbdlSuccess) {
            [defaluts setObject:ver forKey:@"appInfo_version"];
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            NSString *tmpFolder = NSTemporaryDirectory();
            NSString *path = [tmpFolder stringByAppendingPathComponent:ARCHIVE_SAMPLE_PICT_NAME];
            
            // サーバより、サンプル画像をダウンロード
            NSData *data = [self getArchiveFile:ARCHIVE_SAMPLE_PICT_NAME
                                      UrlFolder:ARCHIVE_DATA_FOLDER];
            [LockWindowPoupup setProgressValueOnLockView:(++progressPos / SAMPLE_FILE_NUM)];
            [data writeToFile:path atomically:YES];
            if ([self doFileUnArchive:path destFolder:DOWNLOAD_PICTURE_CACHES_FOLDER]) {
                // 解凍が成功したら、アーカイブファイルを削除
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                
                [LockWindowPoupup setProgressValueOnLockView:(++progressPos / SAMPLE_FILE_NUM)];
            }
            
            // サーバより、サンプル動画をダウンロード
            path = [tmpFolder stringByAppendingPathComponent:ARCHIVE_SAMPLE_MOVIE_NAME];
            data = [self getArchiveFile:ARCHIVE_SAMPLE_MOVIE_NAME
                              UrlFolder:ARCHIVE_DATA_FOLDER];
            [LockWindowPoupup setProgressValueOnLockView:(++progressPos / SAMPLE_FILE_NUM)];
            [data writeToFile:path atomically:YES];
            if ([self doFileUnArchive:path destFolder:DOWNLOAD_PICTURE_CACHES_FOLDER]) {
                
                // 解凍が成功したら、アーカイブファイルを削除
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                
                [LockWindowPoupup setProgressValueOnLockView:(++progressPos / SAMPLE_FILE_NUM)];
            }
            // Imageファイル管理マネージャ生成
            OKDImageFileManager *mng = [[OKDImageFileManager alloc] initWithAppHome];
            
            [mng makeThumnails:0];  // サムネイル生成(キャッシュディレクトリ以下)
            [LockWindowPoupup setProgressValueOnLockView:(++progressPos / SAMPLE_FILE_NUM)];
            [mng makeThumnails:1];  // サムネイル生成(Documentsディレクトリ以下)
            [LockWindowPoupup setProgressValueOnLockView:SAMPLE_FILE_NUM / SAMPLE_FILE_NUM];
            [mng release];

            // ダウンロード済みをここで書き込み
            [defaluts setBool:YES forKey:APP_STORE_SAMPLE_DEF_KEY];
            
            [pool release];
        }
        [MainViewController setDbdownloadEnd:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"sampleDlEnded"
                                                                object:nil];
        });
    });
}

- (id) getArchiveFile:(NSString*)fileName
            UrlFolder:(NSString*)folder
{
    NSString *webUrl
    = [NSString stringWithFormat:@"%@/%@/%@/%@",
       ACCOUNT_HOST_URL, APP_STORE_SAMPLE_URL, folder, fileName];
    
    NSData *data = [self _getImageData_:webUrl];
    
    return data;
}

/**
 * アーカイブされたファイルを解凍する
 * @param   NSString:アーカイブファイルへのパス
 * @param   NSString:展開フォルダ名 (NSHomeDirectory() 以下の部分)
 * @return  BOOL    :成功 or 失敗
 */
- (BOOL)doFileUnArchive:(NSString *)zipFilePath destFolder:(NSString *)folder
{
    BOOL stat = NO;
    ZipArchive *zip = [[ZipArchive alloc]init];
    
    [zip UnzipOpenFile:zipFilePath];
    
    NSString *targetFolder = [NSHomeDirectory() stringByAppendingPathComponent:folder];

    NSLog (@"unzip start!");
    if (![zip UnzipFileTo:targetFolder overWrite:YES]) {
        NSLog (@"unzip one file error");
    }else{
        stat = YES;
    }
/*
    stat = [zip UnzipFileTo:targetFolder overWrite:YES progressHandler:^(NSUInteger progressPersent) {
        [LockWindowPoupup setProgressValueOnLockView:(progressPos + (progressPersent / 100.0f)) / SAMPLE_FILE_NUM];
#ifdef DEBUG
        NSLog(@"Unarchive %d[%f]", progressPersent, (progressPos + ((CGFloat)progressPersent / 100.0f)) / SAMPLE_FILE_NUM);
#endif
    }];
 */
    NSLog (@"unzip end!");
    [zip UnzipCloseFile];
    [zip release];
    
    return stat;
}

+ (NSArray*)imageAndMovieFileNamesAtDirectoryPath:(NSString*)directoryPath
{
    NSError *error = nil;
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    /* 全てのファイル名 */
    NSArray *allFileName = [fileManager subpathsOfDirectoryAtPath:directoryPath error:&error];
    if (error) return nil;
    NSMutableArray *hitFileNames = [[NSMutableArray alloc] init];
    for (NSString *fileName in allFileName) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", directoryPath, fileName];
        if (![[fileName pathExtension] isEqualToString:@"db"]) {
            if ( [fileManager fileExistsAtPath:fullPath isDirectory: &isDir] && !isDir ) {
                [hitFileNames addObject:fileName];
            }
        }
    }
    return hitFileNames;
}

+ (BOOL)moveFile:(NSString*)fromPath to:(NSString*)toPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSString *toDirectory = [toPath stringByDeletingLastPathComponent];
    // ディレクトリが存在しなければ作成
    if (![fileManager fileExistsAtPath:toDirectory]){
        [fileManager createDirectoryAtPath:toDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error){
            NSLog(@"%@", error);
            return NO;
        }
    }
    [fileManager moveItemAtPath:fromPath toPath:toPath error:&error];
    if (error) {
        //NSLog(@"%@", error);
        return NO;
    }
    return YES;
}

#endif

- (void)copyDefaultDb{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //新規テンプレートDBをコピー
    NSString *templateDBPath = [[NSString alloc]initWithString:[[[NSBundle mainBundle] resourcePath]
#ifndef CLOUD_SYNC
                                stringByAppendingPathComponent:DB_FILE_NAME ]];
#else
                                stringByAppendingPathComponent:DB_RESOURCE_FILE_NAME ]];
#endif
    // デバイス内のDBファイルの実パス
	NSString *docs 
    = [[NSString alloc] initWithFormat:@"%@/Documents/%@", NSHomeDirectory(), DB_FILE_NAME];
    if([[NSFileManager defaultManager] fileExistsAtPath:docs]){
        [templateDBPath release];
        [docs release];
        return;
    }
#ifdef DEBUG
    NSLog(@"default db copy %@ -> %@",templateDBPath,docs);
#endif
    NSError *error = nil;
    BOOL success = [fileManager copyItemAtPath:templateDBPath toPath:docs error:&error];
    if (!success) {
        // エラーの場合
       NSLog(@"failed to create DB : %@.", [error localizedDescription]);
    }
    [templateDBPath release];
    [docs release];
}

#ifdef HTTP_ON
// httpサーバーの管理
- (void) setupHttpServer
{
    @try
    {
#ifdef USE_ACCOUNT_MANAGER
      
        //  未ログインではhttpサーバーを起動しない
        if (! [AccountManager isLogined])
        {   return; }
        
#endif
        // 設定ファイルよりwebサーバポート番号を取得
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults stringForKey:@"webSeverPortNum"]) 
        {
            [defaults setObject:@"23456" forKey:@"webSeverPortNum"];
        }
        [defaults synchronize];
        
        NSString *sPort = [defaults stringForKey:@"webSeverPortNum"];
        NSUInteger port = [sPort intValue];
        
        if ( (port > 0) && (port != 80) )
        {
            httpServerManager = [[HttpFileUpDownLoaderManager alloc] init];
            if (! [httpServerManager startHttpServer:port] )
            {	
                [httpServerManager release]; 
                httpServerManager = nil;
            }
        }
        else {
            httpServerManager = nil;
        }
    }
    @catch (NSException* exception) {
        NSLog(@"doArchive: Caught %@: %@", [exception name], [exception reason]);
        httpServerManager = nil;
    }

}
- (void) shutdownHttpServer
{
    if (! httpServerManager)
    {   return; }
    // 2012 7/5 伊藤 ここでサーバーを停止すると再開時にハングする事がある。
    //[httpServerManager stopHttpServer];
    //[httpServerManager release];
    //httpServerManager = nil;
}
#endif

#ifdef USE_ACCOUNT_MANAGER

// アカウント継続スレッド起動
- (void) accoutContinueThreadRun
{
    if (self.accountCountine) {
        return;
    }
	self.accountCountine 
		= [[AccountManager alloc]initWithServerHostName:ACCOUNT_HOST_URL];
    accountCountine.isThreadFinish = NO;    // スレッド終了フラグを継続にする
#ifdef DEBUG
	[self.accountCountine doAccoutContinueThreadWithErrHandler:^void (ACCOUNT_RESPONSE response)
	 {
		 NSLog (@"doAccoutContinueThreadWithErrHandler fire at %ld", (long)response);
         [self.viewController onAccountContinueError];
	 } idelTimeSec:30.0f];
#else
	[self.accountCountine doAccoutContinueThreadWithErrHandler:^void (ACCOUNT_RESPONSE response)
	 {
		 NSLog (@"doAccoutContinueThreadWithErrHandler fire at %ld", (long)response);
			[self.viewController onAccountContinueError];
	 } idelTimeSec:360.0f];
#endif
}

#endif

#ifdef CLOUD_SYNC

// 写真ファイルの自動アップロードworkerスレッド開始
-(void) cloudSyncPictUploaderRun
{
    // 中断状態で開始する
    /*self.cloudPictureUploader
        = [[CloudSyncPictureUploadManager alloc] init2RunByThreadBreak];*/
}

// バックグラウンド処理の登録
-(void) backgroundProcRegist
{
    UIApplication*    app = [UIApplication sharedApplication];
    
    backgroundTaskIdentifer = [app beginBackgroundTaskWithExpirationHandler:^{
#ifdef DEBUG
        NSLog(@"expired upload pictures background ");
#endif
        // 写真及び動画のアップロードスレッドを終了する
        [self uploadProcEnd];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Do the work associated with the task.
            [app endBackgroundTask:backgroundTaskIdentifer];
            backgroundTaskIdentifer = UIBackgroundTaskInvalid;
        });
    }];
}

// バックグラウンド処理の解除
-(void) backgroundProcRemove
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (backgroundTaskIdentifer != UIBackgroundTaskInvalid)
        { 
            UIApplication*    app = [UIApplication sharedApplication];
            
            [app endBackgroundTask:backgroundTaskIdentifer];
            backgroundTaskIdentifer = UIBackgroundTaskInvalid;
        }
    });
}

#endif

/**
 * 前回終了時のセキュリティーロックフェースの確認
 * YES:ノーマル     NO:セキュリティーロックあり
 */
- (BOOL) getLastPhase
{
    BOOL ret = YES;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // セキュリティのPhase
    id defObj = [defaults objectForKey:SECURITY_FAZE_KEY];
    if (!defObj)
    {
        ret = YES;
        //        securityFaze = SECURITY_NONE;
        //        [defaults setObject:[NSNumber numberWithUnsignedInteger: securityFaze]
        //                     forKey:SECURITY_FAZE_KEY];
    }
    else
    {
        SECURITY_FAZE securFaze = [((NSNumber*)defObj) unsignedIntegerValue];
        
        switch (securFaze)
        {
            case (SECURITY_WINDOW_LOCK): // 画面ロックで終了していた場合はViewLockに変更する
            case (SECURITY_VIEW_LOCK):
                ret = NO;
                break;
            case (SECURITY_NONE):
            case (SECURITY_PC_BACKUP):   // PCバックアップで終了していた場合はセキュリテリなし：通常状態にする
                ret = YES;
                break;
            default:
                ret = YES;
                break;
        }
    }
    
    return ret;
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //initialize Fabric
    [Fabric with:@[[Crashlytics class]]];
    
    // Override point for customization after app launch. 
    
    BOOL do_splash = NO;
    BOOL is_movie = NO;
	
	// 2015/10/27 TMS iOS9対応
    self.window.rootViewController = [UIViewController new];
    
    // 32bit or 64bit
    if (sizeof(void*) == 4) {
        NSLog(@"You're running in 32 bit");
    } else if (sizeof(void*) == 8) {
        NSLog(@"You're running in 64 bit");
    }
//
#ifdef USE_SPLASH_MOVIE
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(splashMoviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    NSURL *urlPath;
    NSString *splash_file = [AccountManager isSplash];
    if ( splash_file != nil) {
        // ファイルのパスを作成
        NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"/Documents/splash_data/%@", splash_file]];
        // ファイルマネージャを作成
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // ファイルが存在すれば再生
        if ([fileManager fileExistsAtPath:filePath]) {
            if ([filePath hasSuffix:@".mp4"]) {
                urlPath = [NSURL fileURLWithPath:filePath];
                mpmPlayerViewController = [[MPMoviePlayerViewController alloc]
                                           initWithContentURL:urlPath];
                is_movie = YES;
            } else {
                uiSplashimg = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithContentsOfFile:filePath]];
            }
            do_splash = YES;
        }
    }
//    else {
//        urlPath = [NSURL fileURLWithPath:
//                   [[NSBundle mainBundle] pathForResource:@"abcarte" ofType:@"mp4"]];
//    }
//    mpmPlayerViewController = [[MPMoviePlayerViewController alloc]
//                               initWithContentURL:urlPath];

#ifndef SPLASH_PARA_TEST
    if (do_splash) {
        if (is_movie) {
            // 動画スプラッシュ
            mpmPlayerViewController.moviePlayer.controlStyle = MPMovieControlStyleNone;
            [self.window addSubview:mpmPlayerViewController.view];
        } else {
            // 静止画スプラッシュ
            uiSplashimg.alpha = 0.25f;
            CGRect new_frame = self.window.bounds;
            uiSplashimg.frame = new_frame;
            [self.window addSubview:uiSplashimg];
            //アニメーション
            [UIView animateWithDuration:2.0f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 uiSplashimg.alpha = 1.0f;
                             }
                             completion:^(BOOL finished) {
                                 [uiSplashimg removeFromSuperview];
                                 self.window.rootViewController = navigationController;
                             }];
        }
    }
#else
	// Global Queueの取得
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	// スレッド処理
	dispatch_async(queue, ^{
        mpmPlayerViewController.moviePlayer.controlStyle = MPMovieControlStyleNone;
        [self.window addSubview:mpmPlayerViewController.view];
    });
#endif
//    [self.window makeKeyAndVisible];
#endif

	// [window addSubview:viewController.view];
    navigationController = [[ABCUINavigationController alloc]
							initWithRootViewController:self.viewController];
	[navigationController setNavigationBarHidden:YES];
	[navigationController setToolbarHidden:YES];
    
	[self.window addSubview:navigationController.view];
    
    if (!do_splash)
        self.window.rootViewController = navigationController;
	
	[self.window makeKeyAndVisible];
	
	// iPadCamera-info.plistよりバージョン番号を取得:Bundle Versionキーで設定
	NSString *ver 
		= [ [[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	// 設定ファイルよりバージョン番号を取得
	NSString *setVer = [ defaluts stringForKey:@"appInfo_version"];
	// 双方が異なれば、設定ファイル側を更新
//2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
#ifndef FOR_SALES
	if(! [setVer isEqualToString:ver] )
	{ [defaluts setObject:ver forKey:@"appInfo_version"];  }
#endif
	
	self.cameraView = nil;
	
#ifdef APP_STORE_SAMPLE_DATA
	// AppStoreサンプルデータのダウンロード
#ifndef FOR_SALES
	[self appStoreSampleDownload];
#endif
#endif
#ifdef FOR_SALES
    // AppStoreサンプルデータのダウンロード
    [self demoSampleDownload];
#endif
	
    if ([defaluts boolForKey:APP_STORE_SAMPLE_DB_DEF_KEY]) {
	// バージョンアップに伴うデータベース更新の確認
    [self dbUpdate4VersionUp];
    }

#ifdef SAMPLE_DATA_DOWNLOAD
	// トライアルバージョンの設定
	[self trialVersionSet];
#endif
	
	// httpサーバーの管理
	// [self setupHttpServer];
	
#ifdef USE_ACCOUNT_MANAGER
	// アカウント継続スレッド起動
	[self accoutContinueThreadRun];
    // バックグラウンド処理初期化
    backgroundTaskIdentifer = UIBackgroundTaskInvalid;
    
#endif
    
#ifdef CLOUD_SYNC
    // 写真ファイルの自動アップロードworkerスレッド開始
    if([AccountManager isCloud])
        [self cloudSyncPictUploaderRun];
#endif
	// DELC SASAGE
    // http://stackoverflow.com/questions/1725881/unknown-class-myclass-in-interface-builder-file-error-at-runtime
    // ライブラリ定義したIBで使うUIViewを継承したクラスはあらかじめロードしておかないと落ちる
    [SyncRotator class];
    
    // バッジ表示の登録
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if (iOSVersion<8.0) {        
         [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge];
    }else{
        UIUserNotificationType types = UIRemoteNotificationTypeBadge;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
#ifdef DEBUG
	NSLog (@"applicationWillResignActive");
#endif
	// カメラ画面へForegroundInActiveに遷移を通知
	UIViewController *vc = [viewController getVC4NaviCtrlWithClass:[camaraViewController class]];
	if ( vc && (self.cameraView))
	{  [cameraView willResignActive]; }
    
    UIViewController *vcvc;
    NSArray *objArray = [[NSArray alloc] initWithObjects:
                         [HistDetailViewController class],
                         [SelectPictureViewController class],
                         [PictureCompViewController class],
                         [PicturePaintViewController class],
                         nil];
    for (UIViewController *tvc in objArray) {
        vcvc = [viewController getVC4NaviCtrlWithClass:(Class)tvc];
        if ( !vcvc )
        {
            // スクロールビューのうちの一つとしてSelectVideoViewControllerがあるか
            vcvc = [viewController getVC4ViewControllersWithClass:(Class)tvc];
        }
        if (vcvc) {
            if ([vcvc respondsToSelector:@selector(willResignActive)]) {
                [vcvc willResignActive];
            }
        }
    }
    [objArray release];
    
    // ナビゲーションとしてSelectVideoViewControllerがあるか
	vcvc = [viewController getVC4NaviCtrlWithClass:[VideoCompViewController class]];
	if ( !vcvc )
	{
        // スクロールビューのうちの一つとしてSelectVideoViewControllerがあるか
        vcvc = [viewController getVC4ViewControllersWithClass:[VideoCompViewController class]];
    }
    if (vcvc) {
        [(VideoCompViewController *)vcvc willResignActive];
    }
    
    // getVC4ViewControllersWithClass
#ifdef CLOUD_SYNC
    // 写真アップロードの残がある場合はバックグラウンド処理を行う
    if (self.cloudPictureUploader.remaingUploadPictureNum > 0 ||
        self.videoUploader.remaingUploadPictureNum > 0)
    {   [self backgroundProcRegist]; }
    else {
        // アップロード残が無い場合、スレッドを終了する
        [self uploadProcEnd];
    }
#endif

    // アカウント継続確認スレッドを終了させる
    if (accountCountine) {
        accountCountine.isThreadFinish = YES;
        [accountCountine release];
        accountCountine = nil;
    }
}

/**
 * 写真及び動画のアップロードスレッドを終了する
 */
- (void)uploadProcEnd
{
    [cloudPictureUploader threadFinish];
    [cloudPictureUploader release];
    cloudPictureUploader = nil;
    [videoUploader threadFinish];
    [videoUploader release];
    videoUploader = nil;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
#ifdef DEBUG
	NSLog (@"applicationDidBecomeActive");
#endif
    // ロック画面が表示中（同期プロセスが実行中）であれば、以降の処理を行わない
    if(MainViewController.isDisplayBottomModalDialog) return;
	
	// カメラ画面へForegroundActiveに遷移を通知
	UIViewController *vc = [viewController getVC4NaviCtrlWithClass:[camaraViewController class]];
	if ( vc && (self.cameraView))
	{  [cameraView didBecomeActive]; }

#ifndef CLOUD_SYNC
#ifdef HTTP_ON
    // httpサーバの起動と管理
    [self shutdownHttpServer];
    [self setupHttpServer];
#endif  // HTTP_ON
#endif
    
#ifdef CLOUD_SYNC
    //  現在の表示がユーザ一覧の場合は、同期中断時の再開の確認と端末固有ユーザIDの取得を行う
    UIViewController *cVc = [viewController getNowCurrentViewController];
    if ( (cVc) && ([cVc isKindOfClass:[UserInfoListViewController class]]) )
    {
        [((UserInfoListViewController*)cVc) doSyncAtRunnigTime];
        
        // 端末固有ユーザIDの取得（取得できていない場合）
        [((UserInfoListViewController*)cVc) getUserIdBase4NoGet];
        
#ifdef MDM_DISTRIBUTION_VERSION
        // バージョン更新の確認を行う
        [VersionInfoManaegr getVersionInfo];
#endif
#ifdef CHK_APPSTORE_VERSION
        // AppStoreから最新版のチェックを行う
        [AppStoreAPIHelper checkAppVersionWithId];
#endif

        // 一定時間経過ごとにDBをアップロードする
        if ([AccountManager isCloud] && [self getLastPhase]) {
            dbUploader *dbup = [[dbUploader alloc] init];
            [dbup doDBuploadDaily];
//            [dbup release];
        }
    }
    // アカウント継続確認スレッドの再起動
    if (!accountCountine) {
        [self accoutContinueThreadRun];
    }
    
    // バックグラウンド処理が登録されていれば解除する
    [self backgroundProcRemove];
    //
    
#endif
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	
	NSLog (@"applicationWillTerminate");

    // カメラ画面へアプリケーション停止を通知
    UIViewController *vc = [viewController getVC4NaviCtrlWithClass:[camaraViewController class]];
    if ( vc && (self.cameraView))
    {  [cameraView viewDidDisappear:NO]; }
}

#ifdef USE_SPLASH_MOVIE
- (void)splashMoviePlayBackDidFinish:(NSNotification *)notification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.window.rootViewController = navigationController;
//    [self.window addSubview:rootViewController.view];
    [mpmPlayerViewController.view removeFromSuperview];
    [mpmPlayerViewController release];
}
#endif

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    BOOL isPortrait;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    switch (orientation) {
		case UIInterfaceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			isPortrait = YES;
			break;
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			isPortrait = NO;
			break;
		default:
			isPortrait = NO;
			break;
	}
#ifdef DEBUG
    NSString *itemName = [notification.userInfo objectForKey:@"EventKey"];
    NSLog(@"%s : %@[%d]", __func__, itemName, isPortrait);
#endif
    // iOS7以降の場合のUI調整
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = (iOSVersion<7.0f)? 0.0f : 20.0f;

    CGFloat scrWidth  = (isPortrait)? 768.0f : 1024.0f;
	CGFloat scrHeigth = (isPortrait)? 1004.0f : 748.0f;
    [self.viewController.view setFrame:CGRectMake(0, 0, scrWidth, scrHeigth + uiOffset)];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
	
	if (self.cameraView)
	{ 
		[self.cameraView release]; 
		self.cameraView = nil;
	}
}

- (void)dealloc {
    
	if (self.cameraView)
	{ [self.cameraView release]; }
	
	[navigationController release];
#ifdef HTTP_ON
	if (httpServerManager)
	{	[httpServerManager release]; }
#endif
#ifdef USE_ACCOUNT_MANAGER
    if (accountCountine)
    {[accountCountine release];}
    if (self.accountCountine)
    {[self.accountCountine release];}
#endif
	
	[viewController release];
    [window release];
    [super dealloc];
}

#pragma mark public_methods

#ifdef HTTP_ON
// HttpServerのコントロール
- (void) httpServerControlWithFlag: (BOOL)isStart
{
    // とりあえず、一旦停止する
    [self shutdownHttpServer];
    if (isStart)
    {
        // 起動する
        [self setupHttpServer];
    }
}
#endif

#ifdef CLOUD_SYNC
// 写真ファイルの自動アップロードの起動と停止
- (void) setSyncPictUploaderRun:(BOOL)isRun
{
#ifdef DEBUG
    NSLog(@"%s [%d]", __func__, isRun);
#endif
    if (! self.cloudPictureUploader)
    {
        // 中断状態で開始する
        self.cloudPictureUploader
            = [[CloudSyncPictureUploadManager alloc] init2RunByThreadBreak];
    }
    
    if (isRun)
    {   [self.cloudPictureUploader uploadRestart]; }
    else 
    {   [self.cloudPictureUploader uploadInnterrupt]; }
}
#endif
// 動画ファイルの自動アップロードの起動と停止
- (void) setSyncVideoUploaderRun:(BOOL)isRun
{
    if (! self.videoUploader)
    {
        // 中断状態で開始する
        self.videoUploader = [[VideoUploader alloc] init2RunByThreadBreak];
    }
    
    if (isRun)
    {   [self.videoUploader uploadRestart]; }
    else
    {   [self.videoUploader uploadInnterrupt]; }
}
#pragma mark CFBundleDocumentType

// Will be deprecated at some point, please replace with application:openURL:sourceApplication:annotation:
- (BOOL) application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
	if ([url.scheme isEqualToString:@"file"])
	{
		NSString *fileName = [url absoluteString];
		NSLog (@"handleOpenURL recvied at file :%@", fileName);
		
		return (YES);
	}
	
	return (NO);
}
@end
