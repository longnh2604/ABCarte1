//
//  OKDImageFileManager.m
//  Pattoru
//
//  Created by MacBook on 11/01/28.
//  Copyright 2011 okada-denshi-Co.Ltd. All rights reserved.
//

#import "../defines.h"

#import "OKDImageFileManager.h"

#import "OKDDirectoryOprater.h"

#ifdef CLOUD_SYNC
// #import "SyncCommon.h"
#import "CloudSyncClientManager.h"
#import "../CloudSyncHelper/CloudSyncUtility.h"
#import "../MainViewController.h"
#import "../CloudSyncHelper/WaitProcManager.h"
#endif

#import "MovieResource.h"

///
/// Imageファイル管理クラス：Imageの入出力を管理する
///
@implementation OKDImageFileManager

@synthesize folderName = _folder;
@synthesize readError;

#pragma mark private_methods

//  Cachesフォルダのディレクトリ操作インスタンス作成
- (void) _makeCachesFolderInstance
{
    if (! _cachesdirOpr)
    {
        // ユーザIDをフォルダ名に変換してメンバに設定
        NSString *folder 
        = [NSString stringWithFormat:FOLDER_NAME_USER_ID, _userID];
        
        // ディレクトリ操作のインスタンスをここで作成
        _cachesdirOpr = [[OKDDirectoryOprater alloc]initWithCachesFolderName:folder];
    }
}

//  Cachesフォルダのディレクトリ操作インスタンス作成
- (void) _makeTemplateCachesFolderInstance
{
    if (! _cachesdirOpr)
    {
        // ユーザIDをフォルダ名に変換してメンバに設定
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* accID = [defaults stringForKey:@"accountIDSave"];
		NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
        
        // ディレクトリ操作のインスタンスをここで作成
        _cachesdirOpr = [[OKDDirectoryOprater alloc]initWithCachesFolderName:folderName];
    }
}

// フォルダの存在確認（ない場合は作成）
-(BOOL) checkMakeFolder
{
	BOOL stat = NO;
	
	// デフォルトフォルダの確認（なければ作成）
	DIR_OPRATE_RESULT result = [_directoryOpr chkFolderMake:YES];
	switch (result) 
	{
		case RESULT_OK:
			stat = YES;
			NSLog(@"created directory at %@", _directoryOpr.folderName);
			break;
		case RESULT_ERROR:
			stat = NO;
			NSLog(@"created directory error at %@", _directoryOpr.folderName);
			break;
		case EXIST_DIRECTORY:
			stat = YES;
			break;
		default:
			stat = NO;
			NSLog(@"default folder check unknown error code:%@",  
						_directoryOpr.folderName);
			break;
	}
			
	return (stat);
}

// 現在日付でのファイル名を生成：パスなし・拡張子なし
- (NSString *) makeFileNameNoExt
{
	// ファイル名のフォーマット:yyMMdd_HHmmss
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:FILE_NAME_FORMAT];
    
	// 現在の日付よりファイル名を生成する
	NSString *fileName = [formatter stringFromDate:[NSDate date]];
	
	// フルパスを付加する
	/*
	NSString* filePath 
		= [NSString stringWithFormat:@"%@/%@", _directoryOpr.folderName, fileName];
	*/
	
	return (fileName);
}

// 縮小版でファイル保存
- (BOOL) saveThumbNail:(NSString*)fnExtNo realImage:(UIImage*)image
{
    // 描画サイズ
    CGRect imgRect
    = CGRectMake(0.0f, 0.0f, THUBNAIL_WITH, THUBNAIL_HEIGHT);

    CGRect rect;
    if (image.size.height*4 > image.size.width*3) {
        // 4:3より縦長の場合
        rect = CGRectMake((THUBNAIL_WITH - (THUBNAIL_HEIGHT*image.size.width/image.size.height))/2,
                          0,
                          (THUBNAIL_HEIGHT*image.size.width/image.size.height),
                          THUBNAIL_HEIGHT);
    } else if (image.size.height*4 < image.size.width*3) {
        // 4:3より横長の場合
        rect = CGRectMake(0,
                          (THUBNAIL_HEIGHT - (THUBNAIL_WITH*image.size.height/image.size.width))/2,
                          THUBNAIL_WITH,
                          THUBNAIL_WITH*image.size.height/image.size.width);
    } else {
        rect = imgRect;
    }
	
	// グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(imgRect.size);
    
	// グラフィックコンテキストに描画
	[image drawInRect:rect];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *drawImg = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
	
	if (! drawImg)
	{	return (NO); }
	
	// 縮小版のImageよりバイナリデータを取得
	NSData *data = UIImagePNGRepresentation(drawImg);
	
	// 実サイズ版でファイル保存
	BOOL stat = [data writeToFile: [NSString stringWithFormat:@"%@%@", 
								fnExtNo, THUMBNAIL_SIZE_EXT] 
					   atomically:YES];
	return (stat);
	
}

// イメージの物理ファイル存在確認
- (BOOL) _isExsistImageFile:(NSString*)fullPath
{
    NSFileManager *fileMng = [NSFileManager defaultManager];
	BOOL isFolder;
	BOOL isExsist = [fileMng fileExistsAtPath:fullPath isDirectory:&isFolder];
    
    return (isExsist && !isFolder);
}

// 黒塗りImageを作成
- (UIImage*) _makeBlackImageWithSize
{
    CGSize size = CGSizeMake(THUBNAIL_WITH*2, THUBNAIL_HEIGHT*2);
    
    UIGraphicsBeginImageContext(size);    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 2倍で描画：文字潰れ防止
    CGContextScaleCTM(context, 2.0f, 2.0f);
    
    // 黒く塗りつぶす
    CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
    CGContextFillRect(context, 
                      CGRectMake(0, 0, size.width, size.height));
    
    // 白文字で描画
    // UIGraphicsPushContext(context);
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    UIFont *tFont = [UIFont systemFontOfSize:6];
    static NSString* noImg = @"画像はありません";
    CGSize szTxt = [noImg sizeWithFont:tFont];
    [noImg drawAtPoint: CGPointMake((THUBNAIL_WITH - szTxt.width) / 2.0f, 5.0f) withFont:tFont];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *)getImage:(NSString *)fileName
{
//#ifdef DEBUG
    NSLog(@"getImage %@", fileName);
//#endif
    readError = nil;

	// ファイル名にフルパスを付与
	NSString* filePath 
		= [NSString stringWithFormat:@"%@/%@", 
					_directoryOpr.folderName, fileName];
    
    NSData *fileDat = nil;
    
    // まずは/Documentフォルダにてファイルの存在を確認
    if ([self _isExsistImageFile:filePath] )
    {   fileDat = [NSData dataWithContentsOfFile:filePath]; }
    else
    {
        //  Cachesフォルダのディレクトリ操作インスタンス作成
        [self _makeCachesFolderInstance];
        
        // /Documentフォルダにファイルがない場合は　/Cachesフォルダで取得を試みる
        NSString *cachesFpath = [NSString stringWithFormat:@"%@/%@", 
                                    _cachesdirOpr.folderName, fileName];
#ifndef CLOUD_SYNC
        if (! [self _isExsistImageFile:cachesFpath] )
        {   return (nil); }
        
        fileDat = [NSData dataWithContentsOfFile:cachesFpath];
#else
        if (! [self _isExsistImageFile:cachesFpath] ) 
        {
            // サムネイルサイズはここではダウンロードしないで黒塗りとする
            if (NO && [fileName hasSuffix:THUMBNAIL_SIZE_EXT] )    // DELC SASAGE
            {   return ([self _makeBlackImageWithSize] ); }
           
            // 処理完了インスタンスの生成
            WaitProcManager *waitProc = [[WaitProcManager alloc] init]; 
            
            // Indicatorの表示
            // [MainViewController showIndicator];
            
            // 写真ファイルのダウンロード
            NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%d",  _userID], SEND_BIN_REQ_PARAM_USER, 
                                   fileName, SEND_BIN_REQ_PARAM_FILE, nil];
#ifdef DEBUG
            NSLog(@"download start");
#endif
            [CloudSyncClientManager download4Cloud:param
                                      hCompRequest:^(SYNC_RESPONSE_STATE result)
             {
                 // 処理完了の待機をリセット
                 [waitProc resetWaitProcComplite];
                 
                 // Busyフラグをリセット
                 // [CloudSyncClientManager resetMainQueBusy];
                 
                 // Indicatorを閉じる
                 [MainViewController closeIndicator];
                 
                 // エラーの場合のみダイアログの表示
                 /*if (result != SYNC_RSP_OK)
                 {  [CloudSyncUtility SyncResultDialogShowWithState:result]; }*/
             }
             ];
            
            // ダウンロードの完了まで待機
            // サムネイルダウンロード時に待機させると、ページ切り替え時に引っかかりが発生するため０秒にした
            // (何らかの状態で画面書き換えを行わせないとダウンロード後でも表示されないという問題が残る)
            NSInteger wait = ([fileName hasSuffix:REAL_SIZE_EXT])? 10 : 0;
            [waitProc wait4ProcCommpliteWithTime:wait];
            [waitProc release];
            waitProc = nil;
#ifdef DEBUG
            NSLog(@"download end");
#endif
            // ダウンロードファイルが保存されているか？
            if (! [self _isExsistImageFile:filePath] )
            {
                readError = YES;
                // ダウンロードできなかった場合は黒塗りの画像を返す
                return ([self _makeBlackImageWithSize]); 
            }
            else
            {
                // ダウンロードファイルが保存されてれば取り出す
                fileDat = [NSData dataWithContentsOfFile:filePath];
            }
        }
        else
        {   fileDat = [NSData dataWithContentsOfFile:cachesFpath]; }
#endif
    }
	
        // NSData *fileDat = [NSData dataWithContentsOfFile:filePath];
        // [fileDat autorelease];
	
	UIImage *img = [UIImage imageWithData:fileDat];
	
	fileDat = nil;
	
	return (img);
}

// イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *)getTemplateImage:(NSString *)fileName
{
//#ifdef DEBUG
    NSLog(@"getTemplateImage %@", fileName);
//#endif
	// ファイル名にフルパスを付与
	NSString* filePath = [NSString stringWithFormat:@"%@/%@", _directoryOpr.folderName, fileName];
    NSData *fileDat = nil;
    
    // まずは/Documentフォルダにてファイルの存在を確認
    if ([self _isExsistImageFile:filePath] )
    {
		fileDat = [NSData dataWithContentsOfFile:filePath];
	}
    else
    {
        //  テンプレート用のCachesフォルダのディレクトリ操作インスタンス作成
        [self _makeTemplateCachesFolderInstance];
        
        // /Documentフォルダにファイルがない場合は　/Cachesフォルダで取得を試みる
        NSString *cachesFpath = [NSString stringWithFormat:@"%@/%@",
								 _cachesdirOpr.folderName, fileName];

        if (! [self _isExsistImageFile:cachesFpath] )
        {
            // サムネイルサイズはここではダウンロードしないで黒塗りとする
            if (NO && [fileName hasSuffix:THUMBNAIL_SIZE_EXT] )    // DELC SASAGE
            {   return ([self _makeBlackImageWithSize] ); }
			
            // 処理完了インスタンスの生成
            WaitProcManager *waitProc = [[WaitProcManager alloc] init];
            
            // 写真ファイルのダウンロード
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSString* accID = [defaults stringForKey:@"accountIDSave"];
            NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:
                                   accID, SEND_BIN_REQ_PARAM_TMPL_ACC_ID,
                                   fileName, SEND_BIN_REQ_PARAM_FILE, nil];
            NSLog(@"download start");
            [CloudSyncClientManager download4Cloud:param
                                      hCompRequest:^(SYNC_RESPONSE_STATE result)
             {
                 // 処理完了の待機をリセット
                 [waitProc resetWaitProcComplite];
                 
                 // Indicatorを閉じる
                 [MainViewController closeIndicator];
             }
             ];
            
            // ダウンロードの完了まで待機
            NSInteger wait = ([fileName hasSuffix:REAL_SIZE_EXT])? 10 : 5;
            [waitProc wait4ProcCommpliteWithTime:wait];
            [waitProc release];
            waitProc = nil;
            NSLog(@"download end");
            // ダウンロードファイルが保存されているか？
            if (! [self _isExsistImageFile:filePath] )
            {
                // ダウンロードできなかった場合は黒塗りの画像を返す
                return ([self _makeBlackImageWithSize]);
            }
            else
            {
                // ダウンロードファイルが保存されてれば取り出す
                fileDat = [NSData dataWithContentsOfFile:filePath];
            }
        }
        else
        {
			fileDat = [NSData dataWithContentsOfFile:cachesFpath];
		}
    }
	
	UIImage *img = [UIImage imageWithData:fileDat];
	fileDat = nil;
	return (img);
}

// 実サイズ版から縮小版へのファイル名変換
-(NSString*) renameReal2Thumbnail:(NSString*)realFileName
{
	return ([realFileName stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
													withString:THUMBNAIL_SIZE_EXT]);
}

// Imageの保存：実サイズ版と縮小版の保存
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) _saveImage:(UIImage *)image fnNo:(NSString*)fnPathExtNo
{
	// フォルダの存在確認（ない場合は作成）
	if (! [ self checkMakeFolder] )
	{	return (nil); }
	
	// フルパスに変換：拡張子なし
	NSString* fnExtNo 
		= [NSString stringWithFormat:@"%@/%@", _directoryOpr.folderName, fnPathExtNo];
	
	// Imageよりバイナリデータを取得
	NSData *data = UIImageJPEGRepresentation(image, 0.95f);
	
	// 実サイズ版でファイル保存
	if (! [data writeToFile: [NSString stringWithFormat:@"%@%@", 
							  fnExtNo, REAL_SIZE_EXT] 
				 atomically:YES] )
	{	
		NSLog(@"save real size error file: %@", fnExtNo);
		
		return (nil); 
	}
	
	// 縮小版でファイル保存
#ifndef DEBUG
    [self saveThumbNail:fnExtNo realImage:image];
#else
    BOOL stat = [self saveThumbNail:fnExtNo realImage:image];
	NSLog(@"save file: => %@ : %@", fnExtNo, (stat)? @"OK" : @"ERROR");
#endif
	// パスなしの実サイズ版のファイル名を返す
	return ([NSString stringWithFormat:@"%@%@", 
					fnPathExtNo, REAL_SIZE_EXT]);
}

// Imageの保存：実サイズ版と縮小版の保存
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) _saveMovie:(NSData *)data fnNo:(NSString*)fnPathExtNo
{
	// フォルダの存在確認（ない場合は作成）
	if (! [ self checkMakeFolder] )
	{	return (nil); }
	
	// フルパスに変換：拡張子なし
	NSString* fnExtNo
    = [NSString stringWithFormat:@"%@/%@", _directoryOpr.folderName, fnPathExtNo];
	
	// 実サイズ版で動画ファイル保存
	if (! [data writeToFile: [NSString stringWithFormat:@"%@%@",
							  fnExtNo, REAL_MOVIE_EXT]
				 atomically:YES] )
	{
		NSLog(@"save real size error file: %@", fnExtNo);
		
		return (nil);
	}

    AVURLAsset* asset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", fnExtNo, REAL_MOVIE_EXT]] options:nil];
    
	// 縮小版でサムネイルファイル保存
    UIImage *thm = [self createThumbnailImage:asset];
#ifndef DEBUG
    [self saveThumbNail:fnExtNo realImage:thm];
#else
    BOOL stat = [self saveThumbNail:fnExtNo realImage:thm];
    NSLog(@"save file: => %@ : %@", fnExtNo, (stat)? @"OK" : @"ERROR");
#endif
    [asset release];
    thm = nil;
	// パスなしの実サイズ版のファイル名を返す
	return ([NSString stringWithFormat:@"%@%@",
             fnPathExtNo, REAL_MOVIE_EXT]);
}

// 動画ファイルよりサムネイル画像を取得する
- (UIImage*)createThumbnailImage:(AVURLAsset*)asset {
    if ([asset tracksWithMediaCharacteristic:AVMediaTypeVideo]) {
        AVAssetImageGenerator *imageGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        [imageGen setAppliesPreferredTrackTransform:YES];
        
        CMTime midpoint =   CMTimeMakeWithSeconds(0, 600);
        NSError* error = nil;
        CMTime actualTime;
        
        CGImageRef halfWayImageRef = [imageGen copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
        [imageGen release];
        
        if (halfWayImageRef != NULL) {
            UIImage* myImage = [[UIImage alloc]initWithCGImage:halfWayImageRef];
            CGImageRelease(halfWayImageRef);
            return myImage;
        }
    }
    return nil;
}

// 指定フォルダ（ユーザ）の全てのイメージ（実サイズ版と縮小版の両方）の削除
- (BOOL) _deleteAllImageWithFolderName:(NSString*)folder IsDelFolder:(BOOL)isDelFolder
{
    BOOL stat = YES;
    
    // 指定フォルダ以下のフォルダ（またはファイル）一覧の取得
    NSArray *files 
        = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:NULL];
    
    for (NSString *file in files)
    {
        // ファイル名にフルパスを付与
        NSString* filePath 
            = [NSString stringWithFormat:@"%@/%@",folder, file];
        
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        
        // エラーでも続行する
        if (error)
        {
            NSLog (@"_deleteAllImageWithFolderName Error　delete file:%@ error->%@", 
                   filePath, error);
            stat = NO;
        }
    }
    
    // 最後にフォルダも削除
    if (isDelFolder)
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:folder error:&error];
        if (error)
        {
            NSLog (@"_deleteAllImageWithFolderName Error　delete folder:%@ error->%@", 
                   _directoryOpr.folderName, error);
            stat = NO;
        }
    }
    
    return (stat);
    
}

// イメージ（実サイズ版と縮小版の両方）の削除
//		fileName:削除するファイル名（拡張子は実サイズ版：パスなし）
- (BOOL) _deleteImageBothByRealSizeWithFolderName:(NSString*)folder aFileName:(NSString*)fileName
{
    NSError *error1 = nil, *error2 = nil;
	
	// 実サイズ版のフルパス
	NSString *realFile 
    = [NSString stringWithFormat:@"%@/%@", folder, fileName];
	// 実サイズ版の削除
	[[NSFileManager defaultManager] removeItemAtPath:realFile error:&error1];
	if (error1)
	{	NSLog (@"delete real image file:%@ error->%@", fileName, error1);}
	else 
	{	NSLog (@"delete real image file:%@ done.", fileName);}
	
	// 縮小版のフルパス
	NSString *thumbnailFile
    = [NSString stringWithFormat:@"%@/%@",
            folder,
           [fileName stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
                                               withString:THUMBNAIL_SIZE_EXT]];
	// 縮小版の削除
	[[NSFileManager defaultManager] removeItemAtPath:thumbnailFile error:&error2];
	if (error2)
	{	NSLog (@"delete thumbnail file:%@ error->%@", thumbnailFile, error2);}
	else 
	{	NSLog (@"delete thumbnail file:%@ done.", thumbnailFile);}
	
	return ( !error1 && !error2);

}

// サイズを指定してイメージの取得
- (UIImage *) _getImageWithOriginalImage:(UIImage *)img fitSize:(CGSize)size
{
    if (! img)
    {   return  (nil); }
    
    // 描画サイズ
	CGRect imgRect = [self adjustAspect:CGRectMake(0, 0, size.width, size.height)
                            adjustImage:img];
	
	// グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(size);
	// グラフィックコンテキストに描画
	[img drawInRect:imgRect];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *drawImg = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
    return (drawImg);
}

/**
 * 画像のアスペクト比が正しくなるように調整
 * @param (CGRect)baseFrame     透過画像を表示するフレーム
 * @param (UIImage *)adjustImg  調整対象のイメージ
 */
- (CGRect)adjustAspect:(CGRect)baseFrame adjustImage:(UIImage *)adjustImg
{
    CGRect rect;
    CGSize tmpSize = CGSizeMake(adjustImg.size.width, adjustImg.size.height);
    CGFloat width  = baseFrame.size.width;
    CGFloat height = baseFrame.size.height;
    CGFloat tmpY   = baseFrame.origin.y;
    
    if (width < height) {   // ポートレートに対して調整する場合
        
        if (adjustImg.size.width > adjustImg.size.height)
        {   // 横長画像の場合(縦をフィットさせて、左右をクリップ)
            CGFloat tmpWidth = tmpSize.width * height / tmpSize.height;
            CGFloat tmpX     = (tmpWidth - width) / 2 * -1;
            rect = CGRectMake(tmpX, 0.0f, tmpWidth, height);
            // 内蔵カメラ・iPodカメラ： -298.5 = (1365-768) /2
            //                rect = CGRectMake(-298.5f, 0.0f, 1365.0f, 1024.0f);
        }
        else
        {   // 縦長画像の場合
            rect = CGRectMake(0.0f, 0.0f, width, height);
        }
    } else {                // ランドスケープに対して調整する場合
        
        if (adjustImg.size.width < adjustImg.size.height)
        {   // 縦長画像の場合(縦をフィットさせて、左右はスペース)
            CGFloat tmpWidth = tmpSize.width * height / tmpSize.height;
            CGFloat tmpX     = (width - tmpWidth) / 2;
            rect = CGRectMake(tmpX, tmpY, tmpWidth, height);
        } else {
            rect = CGRectMake(0.0f, tmpY, width, height);
        }
    }
    
    return rect;
}

#pragma mark life-cycle

// 初期化（コンストラクタ）
//   folder = フォルダ名：HomeDirectoryは除く
- (id) initWithFolder:(NSString *)folder
{
	if ( self = [super init])
	{
		// フォルダ名をそのままメンバに設定
		_folder = folder;
		
		// ディレクトリ操作のインスタンスをここで作成
		_directoryOpr = [[OKDDirectoryOprater alloc] initWithFolderName:folder];
        _cachesdirOpr = nil;
        
        // ユーザIDは使用不可
        _userID = NSIntegerMin;
	}
	
	return self;
}

// 初期化（コンストラクタ）
//   userID = ユーザID
- (id) initWithUserID:(USERID_INT)userID
{
	
	if ( self = [super init])
	{
		// ユーザIDをフォルダ名に変換してメンバに設定
		_folder = [NSString stringWithFormat:FOLDER_NAME_USER_ID, userID];
		
		// ディレクトリ操作のインスタンスをここで作成
		_directoryOpr = [[OKDDirectoryOprater alloc] initWithFolderName:_folder];
        _cachesdirOpr = nil;
        
        // ユーザIDを保存
        _userID = userID;
	}
	
	return self;
	
}

// 初期化（コンストラクタ）: Cachesフォルダを対象とする
//   userID = ユーザID
- (id) initWithUserIDInCachesFolder:(USERID_INT)userID
{
    if ( self = [super init])
	{
		// ユーザIDをフォルダ名に変換してメンバに設定
		_folder = [NSString stringWithFormat:FOLDER_NAME_USER_ID, userID];
		
		// ディレクトリ操作のインスタンスをここで作成
		_directoryOpr = [[OKDDirectoryOprater alloc]initWithCachesFolderName:_folder];
        _cachesdirOpr = nil;
        
        // ユーザIDを保存
        _userID = userID;
	}
	
	return self;

}

//2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
// 初期化（コンストラクタ）
// NSHomeDirectory()までの初期化
- (id) initWithAppHome
{
    if ( self = [super init])
    {
        // フォルダ名をそのままメンバに設定
        _folder = nil;
        
        // ディレクトリ操作のインスタンスをここで作成
        _directoryOpr = [[OKDDirectoryOprater alloc] init];
        _cachesdirOpr = [[OKDDirectoryOprater alloc] init];
        if (_directoryOpr) {
            _directoryOpr.folderName = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        }
        if (_cachesdirOpr) {
            _cachesdirOpr.folderName = [NSHomeDirectory() stringByAppendingPathComponent:DOWNLOAD_PICTURE_CACHES_FOLDER];
        }
        
        // ユーザIDは使用不可
        _userID = NSIntegerMin;
    }
    
    return self;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif

    [_directoryOpr release];
    
    [_cachesdirOpr release];
	
	[super dealloc];
	
}

#pragma mark public_methods

// Imageの保存：実サイズ版と縮小版の保存
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) saveImage:(UIImage *)image
{
	// 現在日付でのファイル名を生成：パスなし・拡張子なし
	NSString *fnPathExtNo = [self makeFileNameNoExt];
	
	return ([self _saveImage:image fnNo:fnPathExtNo]);
	
}

// Imageの保存：実サイズ版と縮小版の保存＋連射などで同じファイル名にならないようにチェックを行う
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) saveImageWithCheckSameFileName:(UIImage *)image lastFileName:(NSString *)lastFname
{
	// 現在日付でのファイル名を生成：パスなし・拡張子なし
	NSString *fnPathExtNo = [self makeFileNameNoExt];
    
    if (lastFname) {
        NSString *last = [lastFname substringToIndex:[lastFname length] - 4];
#ifdef DEBUG
        NSLog(@"pict [%@ : %@]", last, fnPathExtNo);
#endif
        if([last isEqualToString:fnPathExtNo]) {
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setLocale:[NSLocale systemLocale]];
            [formatter setTimeZone:[NSTimeZone systemTimeZone]];
            formatter.dateFormat = FILE_NAME_FORMAT;
            NSDateComponents *components = [NSDateComponents new];
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            components.second = 1;
            NSDate *date = [formatter dateFromString:last];
            NSDate *result = [calendar dateByAddingComponents:components toDate:date options:nil];
            
            // 補正したファイル名を生成する
//            [fnPathExtNo release];
            fnPathExtNo = [NSString stringWithString:[formatter stringFromDate:result]];
#ifdef DEBUG
            NSLog(@"SaveFileName : %@ -> %@", last, fnPathExtNo);
#endif
            [calendar release];
            [components release];
            [formatter release];
        }
    }
	
	return ([self _saveImage:image fnNo:fnPathExtNo]);
	
}

// Imageの保存：実サイズ版と縮小版の保存(パスなし・拡張子なしファイル名指定)
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) saveImageWithFileName:(UIImage *)image fnPathExtNo:(NSString*)fn
{
	return ([self _saveImage:image fnNo:fn]);
}

// Movieの保存：実サイズ版と縮小版の保存(パスなし・拡張子なしファイル名指定)
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) saveMovieWithFileName:(NSData *)data fnPathExtNo:(NSString*)fn
{
	return ([self _saveMovie:data fnNo:fn]);
}

// 実サイズ版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getRealSizeImage:(NSString *)fileName
{
	// 拡張子の確認:”.JPG”で終わるファイル名であるか？
	if (! [fileName hasSuffix:REAL_SIZE_EXT] )
	{	return (nil); }
	
	return ([self getImage:fileName]);
}

// サイズを指定して実サイズ版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getRealSizeImageWithSize:(NSString *)fileName fitSize:(CGSize)size
{
	// 実サイズ版イメージの取得
    UIImage *img = [self getRealSizeImage:fileName];
    
	if (! img)
	{	return (nil); }
	
	// 描画サイズ
	CGRect imgRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	
	// グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(size);
	// グラフィックコンテキストに描画
	[img drawInRect:imgRect];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *drawImg = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
	
	// オリジナルのImageを解放
	img = nil;
	
	// [drawImg autorelease];
	
	return (drawImg);
}

// サイズを指定してイメージの取得 : 実サイズ→サムネイルサイズの順で取得する
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getSizeImageWithSize:(NSString *)fileName fitSize:(CGSize)size
{
    NSString *aFile = nil;
    
    // ファイル名にフルパスを付与
	NSString* filePath 
        = [NSString stringWithFormat:@"%@/%@", 
           _directoryOpr.folderName, fileName];
    
    // まずは/Documentフォルダにて実サイズファイルの存在を確認
    if (! [self _isExsistImageFile:filePath] )
    {
        //  Cachesフォルダのディレクトリ操作インスタンス作成
        [self _makeCachesFolderInstance];
        
        // /Documentフォルダにファイルがない場合は　/Cachesフォルダで実サイズファイルの存在を確認
        NSString *cachesFpath = [NSString stringWithFormat:@"%@/%@", 
                                 _cachesdirOpr.folderName, fileName];

        if (! [self _isExsistImageFile:cachesFpath] )
        {
            // どちらのフォルダにも実サイズがないので、サムネイルで取得する
            aFile = [self renameReal2Thumbnail:fileName]; 
        }
    }
    
    // いずれかのフォルダに実サイズファイルがあったので、実ファイルで取得する
    if (! aFile)
    {   aFile = fileName; }

    UIImage *img = [self getImage:aFile];
	
    // 取得したImageで指定サイズのイメージの取得
    UIImage *drawImg 
        = [self _getImageWithOriginalImage:img fitSize:size];
	
	// オリジナルのImageを解放
	img = nil;
	
	// [drawImg autorelease];
	
	return (drawImg);
}

// テンプレート用実サイズ版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getTemplateRealSizeImage:(NSString *)fileName
{
	// 拡張子の確認:”.JPG”で終わるファイル名であるか？
	if (! [fileName hasSuffix:REAL_SIZE_EXT] )
	{	return (nil); }
	
	return ([self getTemplateImage:fileName]);
}

// 縮小版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getThumbnailSizeImage:(NSString *)fileName
{
    // TODO:DELETE SASAGE
#ifdef DEBUG
    NSLog(@"%@",fileName);
#endif
	NSString *fnNoPath;
	if ( [fileName length] > FILE_NAME_LEN_EXT)
	{
		// パスを含んでいる（と思われる）場合はファイル名のみとする
		// fnNoPath = [fileName substringFromIndex:FILE_NAME_LEN_EXT];
		fnNoPath = [fileName lastPathComponent];
	}
	else 
	{
		fnNoPath = [NSString stringWithString:fileName];
	}
	
	NSString *thumbnailFileName;
	// 拡張子の確認:”.tmb”で終わるファイル名であるか？
	if (! [fileName hasSuffix:THUMBNAIL_SIZE_EXT] )
	{	
		// .tmbでない場合サムネイルの拡張子に変更する
		thumbnailFileName
			= [fnNoPath stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
												  withString:THUMBNAIL_SIZE_EXT];
	}
	else {
		thumbnailFileName = [NSString stringWithString:fnNoPath];;
	}

	// イメージの取得
	UIImage *image = [self getImage:thumbnailFileName];
	
	// 縮小版のファイルがない場合は、実サイズ版で取得する
	if (! image)
	{
#ifndef CLOUD_SYNC
        // 実サイズ版の拡張子に置換する
		NSString *realFileName 
			= [thumbnailFileName stringByReplacingOccurrencesOfString:THUMBNAIL_SIZE_EXT
														   withString:REAL_SIZE_EXT];
		
		image = [self getImage:realFileName];
		
		// ここで縮小版をファイル保存しておく
		if (image)
		{
			// 拡張子を取り除く
			NSString *realFnExtNo 
				= [realFileName stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
												  withString:@""];
			// ファイル名にフルパスを付与
			NSString* filePath 
				= [NSString stringWithFormat:@"%@/%@", 
						_directoryOpr.folderName, realFnExtNo];
			
			// 縮小版でファイル保存
			[self saveThumbNail:filePath realImage:image];
		}
#else
        // /Documentフォルダにファイルがない場合は　/Cachesフォルダで取得を試みる
        NSString *cachesFpath = [NSString stringWithFormat:@"%@/%@", 
                                 _cachesdirOpr.folderName, fileName];
        if ([self _isExsistImageFile:cachesFpath] )
        {
            NSData *fileDat = [NSData dataWithContentsOfFile:cachesFpath];
            image = [UIImage imageWithData:fileDat];
            fileDat = nil;
        }
#endif
	}
	
	return (image);
} 

// テンプレート用の縮小版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getTemplateThumbnailSizeImage:(NSString *)fileName
{
    // TODO:DELETE SASAGE
#ifdef DEBUG
    NSLog(@"%@",fileName);
#endif
	NSString *fnNoPath;
	if ( [fileName length] > FILE_NAME_LEN_EXT)
	{
		// パスを含んでいる（と思われる）場合はファイル名のみとする
		// fnNoPath = [fileName substringFromIndex:FILE_NAME_LEN_EXT];
		fnNoPath = [fileName lastPathComponent];
	}
	else
	{
		fnNoPath = [NSString stringWithString:fileName];
	}
	
	NSString *thumbnailFileName;
	// 拡張子の確認:”.tmb”で終わるファイル名であるか？
	if (! [fileName hasSuffix:THUMBNAIL_SIZE_EXT] )
	{
		// .tmbでない場合サムネイルの拡張子に変更する
		thumbnailFileName
		= [fnNoPath stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
											  withString:THUMBNAIL_SIZE_EXT];
	}
	else {
		thumbnailFileName = [NSString stringWithString:fnNoPath];;
	}
	
	// イメージの取得
	UIImage *image = [self getTemplateImage:thumbnailFileName];
	
	// 縮小版のファイルがない場合は、実サイズ版で取得する
	if (! image)
	{
        // /Documentフォルダにファイルがない場合は　/Cachesフォルダで取得を試みる
        NSString *cachesFpath = [NSString stringWithFormat:@"%@/%@",
                                 _cachesdirOpr.folderName, fileName];
        if ([self _isExsistImageFile:cachesFpath] )
        {
            NSData *fileDat = [NSData dataWithContentsOfFile:cachesFpath];
            image = [UIImage imageWithData:fileDat];
            fileDat = nil;
        }
	}
	
	return (image);
}

// イメージ（実サイズ版と縮小版の両方）の削除
//		fileName:削除するファイル名（拡張子は実サイズ版：パスなし）
- (BOOL) deleteImageBothByRealSize:(NSString*)fileName
{
	// 拡張子の確認:”.JPG”で終わるファイル名であるか？ 
    //      -> サムネイルのみの場合に削除できないので以下の処理をコメントアウト
	/*if (! [fileName hasSuffix:REAL_SIZE_EXT] )
	{ return(NO); }*/
    
    // _deleteImageBothByRealSizeWithFolderNameメソッドで拡張子を変えているので以下の処理は不要
    /*fileName = [fileName stringByReplacingOccurrencesOfString:THUMBNAIL_SIZE_EXT 
                                                       withString:REAL_SIZE_EXT];*/
    BOOL stat;
    
    @try
    {
        // Documentsのユーザフォルダのファイルを削除
        stat = [self _deleteImageBothByRealSizeWithFolderName:_directoryOpr.folderName
                                                  aFileName:fileName];
        
        //  Cachesフォルダのディレクトリ操作インスタンス作成
		if ( _userID != USERID_INTMIN )
			[self _makeCachesFolderInstance];
		else
			[self _makeTemplateCachesFolderInstance];
        
        // Documentsのユーザフォルダ以下全てを削除
        [self _deleteImageBothByRealSizeWithFolderName:_cachesdirOpr.folderName 
                                             aFileName:fileName];
        
		
    }
	@catch (NSException* exception) {
		NSLog(@"deleteImageBothByRealSize: Caught %@: %@", 
			  [exception name], [exception reason]);
		
		stat = NO;
	}
	
	return (stat);

    
	
	NSError *error1 = nil, *error2 = nil;
	
	// 実サイズ版のフルパス
	NSString *realFile 
		= [NSString stringWithFormat:@"%@/%@", 
			_directoryOpr.folderName, fileName];
	// 実サイズ版の削除
	[[NSFileManager defaultManager] removeItemAtPath:realFile error:&error1];
	if (error1)
	{	NSLog (@"delete real image file:%@ error->%@", fileName, error1);}
	else 
	{	NSLog (@"delete real image file:%@ done.", fileName);}
	
	// 縮小版のフルパス
	NSString *thumbnailFile
		= [NSString stringWithFormat:@"%@/%@",
			_directoryOpr.folderName,
		   [fileName stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
											   withString:THUMBNAIL_SIZE_EXT]];
	// 縮小版の削除
	[[NSFileManager defaultManager] removeItemAtPath:thumbnailFile error:&error2];
	if (error2)
	{	NSLog (@"delete thumbnail file:%@ error->%@", fileName, error2);}
	else 
	{	NSLog (@"delete thumbnail file:%@ done.", fileName);}
	
	
	return ( !error1 && !error2);
}

// イメージ（実サイズ版と縮小版の両方）の移動またはコピー
//		fileName:移動するファイル名（拡張子は実サイズ版：パスなし）
//		dstFolderName:移動先のフォルダ名（HomeDirectoryは除く）
//		isMove  YES:移動  NO:コピー
- (DIR_OPRATE_RESULT) moveCopyImageBoth:(NSString*)fileName 
			 dstFolderName:(NSString*)dstFolder isMoce:(BOOL)isMove
{
	// 移動先のディレクトリ（フォルダ）操作クラスのインスタンス作成
	OKDDirectoryOprater *dstFolderOpr 
		=[[OKDDirectoryOprater alloc]initWithFolderName:dstFolder]; 
	
	// 拡張子の確認:”.JPG”で終わるファイル名であるか？
	if (! [fileName hasSuffix:REAL_SIZE_EXT] )
	{ 
        [dstFolderOpr release];
        return(NO); }
	
	NSError *error = nil;
	
	// 移動元の実サイズ版のフルパス
	NSString *srcRealFile 
		= [NSString stringWithFormat:@"%@/%@", 
		   _directoryOpr.folderName, fileName];
	// 移動先の実サイズ版のフルパス
	NSString *dstRealFile 
		= [NSString stringWithFormat:@"%@/%@", 
			dstFolderOpr.folderName, fileName];
	
	// 移動元の縮小版のフルパス
	NSString *srcThumbnailFile = [self renameReal2Thumbnail:srcRealFile];
	// 移動先の縮小版のフルパス
	NSString *dstThumbnailFile = [self renameReal2Thumbnail:dstRealFile];
	
	// 移動またはコピー先に実サイズ版の同一ファイル名がある場合は何もしない(上書きしない)
	if ( [[NSFileManager defaultManager] fileExistsAtPath:dstRealFile])
	{	[dstFolderOpr release];
        return (EXIST_FILE); }
	
	if (isMove)
	{
		// 実サイズ版の移動
		[[NSFileManager defaultManager] moveItemAtPath:srcRealFile 
												toPath:dstRealFile error:&error];
		if (! error)
		{
			// 縮小版の移動
			[[NSFileManager defaultManager] moveItemAtPath:srcThumbnailFile 
													toPath:dstThumbnailFile error:&error];
		}
	}
	else 
	{
		// 実サイズ版のコピー
		[[NSFileManager defaultManager] copyItemAtPath:srcRealFile 
												toPath:dstRealFile error:&error];
		if (! error)
		{
			// 縮小版のコピー
			[[NSFileManager defaultManager] copyItemAtPath:srcThumbnailFile 
													toPath:dstThumbnailFile error:&error];
		}
	}
	
	
	[dstFolderOpr release];
	
	return ( (!error)? RESULT_OK : RESULT_ERROR);
	
	
}

// Document以下のフォルダを付与してファイル名を取得する
-(NSString*) getDocumentFolderFilename:(NSString*)fileName
{
	return ([_directoryOpr getDocumentFolderFilenameWithUID: _folder
										  fileNameNoFolder: fileName]);
}

// 指定フォルダ（ユーザ）の全てのイメージ（実サイズ版と縮小版の両方）の削除
- (BOOL) deleteAllImageWithIsDelFolder:(BOOL)isDelFolder
{
	BOOL stat = YES;
	
	@try {
        
        // Documentsのユーザフォルダ以下全てを削除
        stat = [self _deleteAllImageWithFolderName:_directoryOpr.folderName IsDelFolder:isDelFolder];
        
        //  Cachesフォルダのディレクトリ操作インスタンス作成
		if ( _userID != USERID_INTMIN )
			[self _makeCachesFolderInstance];
		else
			[self _makeTemplateCachesFolderInstance];
        
        // Documentsのユーザフォルダ以下全てを削除
        [self _deleteAllImageWithFolderName:_cachesdirOpr.folderName IsDelFolder:isDelFolder];
	}
	@catch (NSException* exception) {
		NSLog(@"deleteAllImageWithIsDelFolder: Caught %@: %@", 
			  [exception name], [exception reason]);
		
		stat = NO;
	}
	
	return (stat);
}

// ファイル名のみでの存在確認:Document以下のファイルのみを確認する
- (BOOL) isExsitFileWithOutPath:(NSString*)aFile isThumbnail:(BOOL)thumbnail
{
    NSString *checkFile;
	// 拡張子の確認:”.tmb”で終わるファイル名であるか？
	if ((thumbnail) && (! [aFile hasSuffix:THUMBNAIL_SIZE_EXT] ) )
	{
		// .tmbでない場合サムネイルの拡張子に変更する
		checkFile
            = [aFile stringByReplacingOccurrencesOfString:REAL_SIZE_EXT
                                               withString:THUMBNAIL_SIZE_EXT];
	}
	else {
		checkFile = [NSString stringWithString:aFile];
	}
    
    // ファイル名にフルパスを付与
	NSString* filePath
        = [NSString stringWithFormat:@"%@/%@", _directoryOpr.folderName, checkFile];
    
    return ([self _isExsistImageFile:filePath]);
}

//2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
/**
 * サムネイルの生成(ユーザデータディレクトリを走査して廻る)
 */
- (void)makeThumnails:(NSInteger)folder
{
    NSArray *files;
    OKDDirectoryOprater *_dirOpr;
    if (folder==0) {
        _dirOpr = _cachesdirOpr;
    } else {
        _dirOpr = _directoryOpr;
    }
    files = [_dirOpr getFilesWithFolderName];
    
    BOOL isDir;
    NSMutableArray *dirs = [[NSMutableArray alloc] init];
    for (NSString *file in files) {
        if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",_dirOpr.folderName, file]
                                                isDirectory:&isDir] && isDir) {
            [dirs addObject:file];
        }
    }
    
    for (NSArray *dir in dirs) {
        OKDDirectoryOprater *_fileOpr = [[OKDDirectoryOprater alloc] init];
        _fileOpr.folderName = [NSString stringWithFormat:@"%@/%@",_dirOpr.folderName, dir];
        NSArray *picts = [_fileOpr getFilesWithFolderName];
        for (NSString *pict in picts) {
            NSString *fullPath = [NSString stringWithFormat:@"%@/%@", _fileOpr.folderName, pict];
            if ([pict hasSuffix:REAL_SIZE_EXT]) {
                UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
                [self saveThumbNail:[fullPath substringToIndex:[fullPath length] - 4] realImage:image];
#ifdef DEBUG
                NSLog(@"[JPG]--- %@", pict);
#endif
            } else if ([pict hasSuffix:REAL_MOVIE_EXT]){
                AVURLAsset* asset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:fullPath] options:nil];
                
                // 縮小版でサムネイルファイル保存
                UIImage *thm = [self createThumbnailImage:asset];
                [self saveThumbNail:[fullPath substringToIndex:[fullPath length] - 4] realImage:thm];
#ifdef DEBUG
                NSLog(@"[MP4] %@", pict);
#endif
            }
        }
    }
}

@end
