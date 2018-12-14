    //
//  ThumbnailViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"

#import "ThumbnailViewController.h"
#import "camaraViewController.h"
#import "SelectPictureViewController.h"
#import "SelectVideoViewController.h"
#import "PictureCompViewController.h"

#import "userDbManager.h"

#import "./model/OKDImageFileManager.h"
#import "OKDThumbnailItemViewForWebMail.h"
#import "VideoThumbnailItemView.h"
#import "MovieResource.h"
#import "DevStatusCheck.h"

#define DRAW_VIEW_TAG       10000
#define WEB_CAM_MID_SIZE    2592

camaraViewController *cameraView;
SelectPictureViewController *selectPictVC;

@implementation ThumbnailViewController

// @synthesize _selectedUserID;
@synthesize userNameColor = _userNameColor;
@synthesize delegate;
@synthesize _userName;
@synthesize isFinishDidLoad;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		// メンバの初期化
		tumbnailItems = nil;
		_scrollView = nil;
		_drawView = nil;
		
		_selectedUserID = -1;
		_isThumbnailRedraw = YES;
        memWarning = NO;
        isFinishDidLoad = NO;
	}
	
	return (self);				
}

// このユーザのDocumentsとCachesフォルダの写真ファイル一覧の取得
- (NSArray*) _getPictureFiles
{
    NSMutableArray *pictFiles = [NSMutableArray array];
    
    // 最初にCachesフォルダから取得
    NSMutableString *cFolder = [NSMutableString string];
    [cFolder appendFormat:@"%@/%@/", NSHomeDirectory(), DOWNLOAD_PICTURE_CACHES_FOLDER];
    [cFolder appendFormat:FOLDER_NAME_USER_ID, _selectedUserID];
    NSArray *cFiles
        = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cFolder error:NULL];
    for (NSString* aFile in cFiles)
    {   [ pictFiles addObject:aFile];}
       
    // 次にDocumentsフォルダから取得
    NSArray *dFiles
        = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: 
            [NSString stringWithFormat:PICTURE_FOLDER, NSHomeDirectory(), _selectedUserID] 
                                                          error:NULL];
    
    for (NSString* aFile in dFiles)
    {   [ pictFiles addObject:aFile];}
    
    return (pictFiles);
}

// 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
- (void) setSelectedUserID:(USERID_INT)userID
{
	if (_selectedUserID != userID)
	{
		// ユーザIDが異なるので、再描画する
		_isThumbnailRedraw = YES;
		
		// ここで、選択ユーザIDを保存する
		_selectedUserID = userID;
		
		return;
	}
	
	// Documentsフォルダのファイル一覧の取得
	/*NSArray *fileNames 
	= [[NSFileManager defaultManager] contentsOfDirectoryAtPath: 
	   [NSString stringWithFormat:PICTURE_FOLDER, NSHomeDirectory(), _selectedUserID] 
	   error:NULL];	*/
    
    // このユーザのDocumentsとCachesフォルダの写真ファイル一覧の取得
    NSArray *fileNames = [self _getPictureFiles];
	
	// 前回と同じユーザの場合は、写真が追加されたか否かをサムネイルItemのリスト数で判定
	_isThumbnailRedraw 
		= ( (tumbnailItems) && ([tumbnailItems count] != [fileNames count]) );
}

// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName nameColor:(UIColor*)color
{
	// ユーザ名の設定
	self._userName = [NSString stringWithString: userName];
	btnUserName.title = [NSString stringWithFormat:@"%@ 様", userName];
	self.userNameColor = color;
}

// サムネイルItemリストの作成
- (BOOL) tumbnailItemsMake
{
	// Documentsフォルダのファイル一覧の取得
	/*NSString *pictFolder 
		= [NSString stringWithFormat:PICTURE_FOLDER, NSHomeDirectory(), _selectedUserID];
	NSArray *fileNames 
		= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pictFolder error:NULL];*/
    
	// このユーザのDocumentsとCachesフォルダの写真ファイル一覧の取得
    NSArray *fileNames = [self _getPictureFiles];
    
	// 更新の必要性を確認:サムネイルItemリストとファイル一覧が同数であれば更新不要とする
	if ((tumbnailItems) &&
		([tumbnailItems count] == [fileNames count] ) )
	{	return (NO); }
		
	// actIndView.backgroundColor = [UIColor blackColor];
	[self.view bringSubviewToFront:actIndView];
	[actIndView startAnimating];
	[self.view bringSubviewToFront:actIndView];
	
	if (tumbnailItems != nil)
	{ 
		// リストをクリアする
		[tumbnailItems removeAllObjects];
	}
	else 
	{
		// リストを空で作成
		tumbnailItems = [ [NSMutableArray alloc] init];
	}

    //データベースからタイトルを読み出す
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    // Imageファイル管理のインスタンスを生成
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
		
	// ファイル一覧よりthumbnailのitemを作成
	// for (int idx = 0; idx < [fileNames count]; idx++) -> 昇順
    int tagnum = 1;
	for (NSInteger idx = ([fileNames count] -1); idx >= 0; idx--) // -> 降順
	{
		// ファイルのフルパス
		/*NSString * fileName 
			= [NSString stringWithFormat:@"%@/%@",
				pictFolder, (NSString*)[fileNames objectAtIndex:idx]];*/
		NSString *fileName 
			= [NSString stringWithString:[fileNames objectAtIndex:idx]];
		
		// 縮小版は除外する
		/*
		if ([fileName hasSuffix:@".tmb"])
		{	continue; }
		*/
		
		/*　 -> tmbのみしかない場合に対応のため、以下をコメントアウト
        // 実サイズ版のみ対応する
		if (! [fileName hasSuffix:@".jpg"])
		{	continue; }
		*/
        
        // fukui　tmbのみしかない場合に対応
        if (! [fileName hasSuffix:THUMBNAIL_SIZE_EXT])
		{	continue; }
        MovieResource *movieResource = [[MovieResource alloc] initWithUserId:_selectedUserID fileName:fileName];
#ifdef DEBUG
        NSLog(@"Movie Resource : %@",movieResource.path);
#endif
		// サムネイルViewの作成
		OKDThumbnailItemView *thumbnailView;
        if (!movieResource.isMovie) {
            thumbnailView = [[OKDThumbnailItemViewForWebMail alloc] initWithFrame:
                             CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)];	// autorelease
            [thumbnailView setFileName:fileName];
        } else {
            thumbnailView = [[VideoThumbnailItemView alloc] initWithFrame:
                             CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)];	// autorelease
            [thumbnailView setFileName:movieResource.thumbnailPath];
        }
        [movieResource release];
		// [thumbnailView setImageWithFile:fileName];
        
        //2012 7/3 伊藤 
        //データベースからタイトルを読み出す
#ifdef CLOUD_SYNC
        // Document以下のファイル名に変換
        NSString *documentFileName = [[NSString alloc]initWithString:fileName];

        documentFileName = [documentFileName substringToIndex:[documentFileName length] - 3];
        documentFileName = [NSString stringWithFormat:@"%@jpg",documentFileName];
        documentFileName = [imgFileMng getDocumentFolderFilename:documentFileName];
        NSArray* imageProfile = [usrDbMng getImageProfile:documentFileName];
        NSString* imageTitle = [[NSString alloc]initWithString:[imageProfile objectAtIndex:0]];
        if ([imageTitle isEqualToString:@""]) {
            // タイトルの形式をyyyy年mm月dd日　HH時MM分ss秒　形式にする
            // [thumbnailView setTitle:(NSString*)[fileNames objectAtIndex:idx]];
            [thumbnailView setTitle:[self makeThumbNailTitle:fileName]];
            
        }else {
            [thumbnailView setTitle:imageTitle];
        }
        [imageTitle release];
#else
        [thumbnailView setTitle:[self makeThumbNailTitle:fileName]];
#endif

        [thumbnailView setDate:[self setDateTime:fileName]];
        
		thumbnailView.delegate = self;
        // ファイル総数よりサムネイル画像のtag番号を割り振っているため、jpg/mp4を
        // クラウドよりダウンロードするとファイル総数が変わりtag番号も変わってしまっていた
        // tag番号が固定になるように修正
		thumbnailView.tag = tagnum++;
		
        // userから送られたファイルの場合ファイル名は..._u.jpgになっている
        if ([thumbnailView isKindOfClass:[OKDThumbnailItemViewForWebMail class]]) {
            if ([fileName hasSuffix:@"u.tmb"] || [fileName hasSuffix:@"u.jpg"]) {
                [(OKDThumbnailItemViewForWebMail *)thumbnailView setUser:YES];
            } else {
                [(OKDThumbnailItemViewForWebMail *)thumbnailView setUser:NO];
            }
        }
		// itemをリストに加える
		[tumbnailItems addObject:thumbnailView];
		[thumbnailView release];
	}
    tumbnailItems = [self rearrangeThumbnailItemsByDate:tumbnailItems];
    [usrDbMng release];
    [imgFileMng release];
	// Timerにより別スレッドでImageを描画する
	[NSTimer scheduledTimerWithTimeInterval:0.1f 
									 target:self 
								   selector:@selector(OnImageWrite:) 
								   userInfo:nil 
									repeats:NO];
#ifdef DEBUG
	NSLog(@"fire imageWrite timer");
#endif
	return (YES);
}

// Imageの描画：Timerスレッド
-(void) OnImageWrite:(NSTimer*)timer
{
#ifdef DEBUG
	NSLog(@"reise imageWrite timer");
#endif
	
	// Imageファイル管理のインスタンスを生成
	OKDImageFileManager *imgFileMng
		= [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
	
	for (id item in tumbnailItems)
	{
		// [ ((OKDThumbnailItemView*)item) writeToImage];
		[ ((OKDThumbnailItemView*)item) writeToThumbnail:imgFileMng];
		OKDThumbnailItemView *view = (OKDThumbnailItemView*)item;
		[view drawRect:view.bounds];
		// NSLog(@"imageWrite done on %d", ((OKDThumbnailItemView*)item).tag);
	}
	
	[actIndView stopAnimating];
	
	[imgFileMng release];
#ifdef DEBUG
	NSLog(@"complite imageWrite timer");
#endif
}


// フルパスのファイル名からサムネイルのタイトル［yy年mm月dd日 HH時MM分］を取得する
- (NSString*) makeThumbNailTitle:(NSString*)fullPath
{
	// フルパスからファイル名だけを取り出す->yyMMdd_HHmmss.jpg
	NSString *fileName = [fullPath lastPathComponent];
	
	// 文字列から日付を取り出すmakeThumbNailTitle
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter setDateFormat:@"yyMMdd_HHmmss"];
	NSDate *date
		= [formatter dateFromString:[fileName substringToIndex:13]]; // 先頭から13文字を取得
	
	// サムネイルタイトルの書式にする
	NSDateFormatter *formatter2 = [[[NSDateFormatter alloc] init] autorelease];
    [formatter2 setLocale:[NSLocale systemLocale]];
    [formatter2 setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter2 setDateFormat:@"20yy年MM月dd日HH時mm分ss秒"];
    
	return ([formatter2 stringFromDate:date]);
}

- (NSDate*) setDateTime:(NSString*)fullPath
{
    // フルパスからファイル名だけを取り出す->yyMMdd_HHmmss.jpg
    NSString *fileName = [fullPath lastPathComponent];
    
    // 文字列から日付を取り出すmakeThumbNailTitle
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"yyMMdd_HHmmss"];
    NSDate *date
    = [formatter dateFromString:[fileName substringToIndex:13]]; // 先頭から13文字を取得
  
    return date;
}

- (void)SelectThumbnail:(NSUInteger)tagID image:(UIImage*)image select:(BOOL)isSelect
{
	// NSLog (@"selected tag ID = %d", tagID);
	
	NSUInteger idx = 0xffffffff;
	NSUInteger count = 0;
	for (id aItem in selectItemOrder)
	{
		NSUInteger tag = (NSUInteger)[((NSString*)aItem) intValue];
		if ( tag == tagID)
		{
			// 選択時、選択したIDが既に選択サムネイルItemの順序Tableに含まれている場合は何もしない
			if (isSelect)
			{ return; }
			// 選択解除時、選択サムネイルItemの順序Tableより削除
			else
			{
				idx = count;
				break;
			}
		}
		
		count++;
		
		// NSLog(@"selectItemOrder item %u", (NSUInteger)((NSNumber*)aItem) )
	}
	
	if (idx != 0xffffffff)
	{
		// サムネイルItemを取り出す
		OKDThumbnailItemView *item = [self searchThnmbnailItemByTagID:tagID];
		// サムネイルItemの選択番号を非表示にする
		[item setSelectNumber:0];
		// 選択サムネイルItemの順序Tableより削除
		[selectItemOrder removeObjectAtIndex:idx];
		
		// 他のサムネイルItemの選択番号を更新
		for (u_int i = 0; i < (u_int)[selectItemOrder count]; i++)
		{
			NSUInteger oIdx
			= (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:i]) intValue];
			OKDThumbnailItemView *oItem = [self searchThnmbnailItemByTagID:oIdx];
			[oItem setSelectNumber:(i+1)];
		}
		
		return;
	}
	
	if (isSelect)
	{
		// サムネイルItemを取り出す
		OKDThumbnailItemView *item = [self searchThnmbnailItemByTagID:tagID];
        if (selectItemOrder.count > 0){
            NSUInteger oIdx
            = (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:0]) intValue];
            OKDThumbnailItemView *oItem = [self searchThnmbnailItemByTagID:oIdx];
            if ([oItem isKindOfClass:[VideoThumbnailItemView class]] !=
                [item isKindOfClass:[VideoThumbnailItemView class]]){
                // 動画と画像のサムネイルを両方選択することはできない。
                [item setSelect:NO];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"選択出来ません"
                                                                message:@"動画と静止画を同時に選択できません"
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                [alert show];
                [alert release];
                return;
            }
        }
        
		// 選択時、選択サムネイルItemの順序Tableの末尾に追加
		[selectItemOrder addObject:[NSString stringWithFormat:@"%ld", (long)tagID]];
		
		// サムネイルItemに選択番号を設定にする
		[item setSelectNumber:(u_int)[selectItemOrder count]];
	}
    
}
- (BOOL)videoIsSelected {
	if ([self selectThubnailItemNums] <= 0) {
        return NO;
    }
    NSUInteger oIdx = (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:0]) intValue];
    OKDThumbnailItemView *oItem = [self searchThnmbnailItemByTagID:oIdx];
    return [oItem isKindOfClass:[VideoThumbnailItemView class]];
}
// サムネイルの選択個数を取得
- (NSInteger) selectThubnailItemNums
{
	// 選択個数を確認
	NSInteger sel = 0;
	for ( id item in tumbnailItems)
	{
		if (((OKDThumbnailItemView*)item).IsSelected)
		{
			sel++;
		}
	}
	
	return (sel);
}
// tagIDによりサムネイルItemを取り出す
- (OKDThumbnailItemView*) searchThnmbnailItemByTagID:(NSUInteger)tagID
{
	// サムネイルItemを取り出す
	OKDThumbnailItemView *item = nil;
	for (id iv in tumbnailItems)
	{	
		item = (OKDThumbnailItemView*)iv;
		if ( item.tag == tagID)
		{
			break;
		}
	}
	
	return(item);
}

// ScrollViewと描画Viewの作成
- (void) makeScrDrawView
{
	// 画面サイズの取得
	UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
	CGFloat scrWidth 
		= (screen.applicationFrame.size.width == 320.0f)? 320.0f : 480.0f;
	CGFloat scrHeigth 
		= (screen.applicationFrame.size.height == 460.0f)? 460.0f : 300.0f;
#else
    CGFloat scrWidth 
        = (screen.applicationFrame.size.width == 768.0f)? 768.0f : 1024.0f;
	CGFloat scrHeigth 
        = (screen.applicationFrame.size.height == 1004.0f)? 1004.0f : 748.0f;
#endif
	// scroll viewの作成
	if (! _scrollView) {
		_scrollView = [[UIScrollView alloc] 
				   initWithFrame:CGRectMake(0.0f, 44.0f, scrWidth, (scrHeigth -88.0f))];
		
		// 本（base）viewにスクロールビューを追加
		[self.view addSubview:_scrollView];

	}
	else {
		_scrollView .frame 
			= CGRectMake(0.0f, 44.0f, scrWidth, (scrHeigth -88.0f));
		[_scrollView setZoomScale:1.0f];
	}

	
	// 描画Viewの作成 : 高さは横向きでの値（自動伸縮しないので仮設定）
	if (! _drawView) {
		_drawView = [[UIView alloc] 
					 initWithFrame:CGRectMake(0.0f, 0.0f, scrWidth, 660.0f)];
        [_drawView setTag:DRAW_VIEW_TAG];
		
		// スクロールビューに対象viewを追加
		[_scrollView addSubview:_drawView];
        [_drawView release];
	}
	else {
		_drawView.frame = CGRectMake(0.0f, 0.0f, scrWidth, 660.0f);
		
		// 一旦、subViewとなるサムネイルItemを全て削除する
		for ( id vw in _drawView.subviews)
		{
			[((UIView*)vw) removeFromSuperview];
		}
	}
	
	// スクロール範囲の設定（これがないとスクロールしない）		   
	[_scrollView setContentSize:_drawView.frame.size];

	// ピンチ（ズーム）機能の追加:delegate指定
	[_scrollView setDelegate:self];
	
	// スクロールビューの拡大と縮小の範囲設定（これがないとズームしない）
//    [_scrollView setMinimumZoomScale:1.0];
//    [_scrollView setMaximumZoomScale:10.0];
	
	// サムネイルItemを描画Viewに加える
	for ( id item in tumbnailItems)
	{
	// レイアウトはthumbnailItemsLayoutで行う
		[_drawView addSubview:(OKDThumbnailItemView*)item];
	}
}

// ピンチ（ズーム）機能のdelegate:hファイルにUIScrollViewDelegateが必要
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	// このviewがscroll対象のviewとなる
	UIView *view = nil;
	if (_scrollView == scrollView)
	{
		view = _drawView;
	}
	
	return (view);
}

// サムネイルItemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
- (void) thumbnailItemsLayout:(BOOL)isPortrait
{
	// サムネイルItemのリストの個数
	NSUInteger count = [tumbnailItems count];
	
	// 横に何個並ぶか？
	// UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
	NSUInteger wn = (isPortrait)? 4 : 7;		// 横画面＝ 7 縦画面＝4
#else
    NSUInteger wn = (isPortrait)? 5 : 7;		// 横画面＝ 7 縦画面＝5
#endif
	
	// 縦に何個並ぶか？
	NSUInteger hn = ((count % wn) == 0)? (count / wn) : ((count /wn) + 1);
	
	// 横マージン
#ifdef CALULU_IPHONE
	CGFloat wm = (isPortrait)?  14.0f : 4.0f;
#else
    CGFloat wm = (isPortrait)?  34.0f : 19.0f;
#endif
    
	// 縦横間隔マージン（縦マージン）
#ifdef CALULU_IPHONE
	CGFloat im = (isPortrait)? 12.0f : 4.0f;
#else
   	CGFloat im = 15.0f;
#endif
	
	CGFloat sW;
	CGFloat sH;
	// 描画ViewとScrollViewもリサイズする
#ifdef CALULU_IPHONE
	CGFloat scrWidth  = (isPortrait)?  320.0f : 480.0f;
	CGFloat scrHeight = (isPortrait)?  460.0f : 300.0f;
#else
    CGFloat scrWidth  = (isPortrait)?  768.0f : 1024.0f;
	CGFloat scrHeight = (isPortrait)? 1004.0f : 748.0f;
#endif
    [self setupSwipSupport];
    
	if (isPortrait)
	{
#ifdef CALULU_IPHONE
		sW = 320.0f;
#else
   		sW = 768.0f;
#endif
		// 縦の場合は高さを調節
		sH = ( (ITEM_HEIGHT * hn) + (im * (hn + 1) ));
	}
	else 
	{
#ifdef CALULU_IPHONE
		sW = 460.0f;
#else
   		sW = 1004.0f;
#endif
        
		// 横の場合も高さを調節
		sH = ( (ITEM_HEIGHT * hn) + (im * (hn + 1) ));
		
		/* 幅を調整する場合
		sW = ( (ITEM_WITH * wn) + (wm * (wn + 1) ) );
		sH = 748.0f - 88.0f;
		*/
	}
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = (iOSVersion >= 7.0f)? 20.0f : 0.0f;
#ifdef DEBUG
        NSLog(@"[%.1f:%.1f] [%.1f:%.1f]", scrWidth, scrHeight, sW, sH);
#endif
	
    //2012 6/26 sHの比較対象をscrHeightから(scrHeight - 88.0f)に変更
//    if ( (sW > scrWidth) || (sH > scrHeight - 88.0f) )
//    {
//        [_scrollView setContentSize:_drawView.frame.size];
//    }
    
    NSDate *currentDate = nil;
    CGFloat totalCount = 0;
    CGFloat addLine = 15;
    CGFloat totalInLine = 1;
    
    if (_scrollView.subviews) {
        for(UIView* lb in _scrollView.subviews){
            if ([lb isKindOfClass:[UILabel class]]){
                [lb removeFromSuperview];
            }
        }
    }

    for (NSInteger i = 0; i < tumbnailItems.count; i++) {
        
        OKDThumbnailItemView *item
        = (OKDThumbnailItemView*)[tumbnailItems objectAtIndex:i];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"20yy年MM月dd日HH時mm分ss秒"];
        
        NSDate *date = [[NSDate alloc]init];
        NSString *subString = [[NSString alloc]init];
        
        date = [dateFormatter dateFromString:item.finalDateTime.text];
        //cut string
        if (item.finalDateTime.text.length >=11) {
            subString = [item.finalDateTime.text substringWithRange:NSMakeRange(0, 11)];
        }
        
        if ([[NSCalendar currentCalendar]isDate:date inSameDayAsDate:currentDate]) {
            NSLog(@"same day");
            if (totalInLine == wn) {
                addLine += 150;
                totalCount = 0;
                totalInLine = 1;
            } else {
                totalInLine += 1;
                totalCount += 1;
            }
        } else {
            NSLog(@"other day");
            
            if (currentDate != nil) {
                addLine += 150;
                totalCount = 0;
                totalInLine = 1;
            }
            UILabel *myLabel = [[UILabel alloc]init];
            [myLabel setTextColor:[UIColor blackColor]];
            [myLabel setFont:[UIFont fontWithName:@"Arial-BoldMT" size:20]];
            [myLabel setText:subString];
            [myLabel setFrame:CGRectMake(30, 5 + addLine - 15, 300, 15)];
            [_scrollView addSubview:myLabel];
        }
        currentDate = date;
        
        CGFloat xp = wm + (im + ITEM_WITH) * totalCount;
        CGFloat yp = addLine;
        
        NSLog(@"in xp = %f",xp);
        NSLog(@"in yp = %f",yp);
        NSLog(@"addLine = %f",addLine);
        
        [item setFrame:CGRectMake(xp, yp, ITEM_WITH, ITEM_HEIGHT)];
    }

    //set final scrollview size
    [_drawView setFrame:CGRectMake(0.0f,0.0f + uiOffset,scrWidth, addLine + 150)];
    [_scrollView setFrame:CGRectMake(0.0f, 44.0f + uiOffset, scrWidth, (scrHeight -88.0f))];
    [_scrollView setContentSize:_drawView.frame.size];
}

- (NSMutableArray*)rearrangeThumbnailItemsByDate: (NSMutableArray*)thumbItems {
    
    NSMutableArray *sortedEventArray = [[NSMutableArray alloc]init];
    NSArray *sortedArray = [[NSArray alloc]init];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"20yy年MM月dd日HH時mm分ss秒"];
    
    for (int i = 0; i < thumbItems.count; i++) {
         sortedArray = [thumbItems sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [dateFormatter dateFromString:[(OKDThumbnailItemView*)a finalDateTime].text];
            NSDate *second = [dateFormatter dateFromString:[(OKDThumbnailItemView*)b finalDateTime].text];
            return [second compare:first];
        }];
    }
    sortedEventArray = [sortedArray mutableCopy];
    
    return sortedEventArray;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement loadView to create a view hierarchy programmatically, without using a nib.
/*
- (void)loadView 
{
	[super loadView];
	
	// 画面際サイズの取得
	UIScreen *screen = [UIScreen mainScreen];
	NSLog(@"width = %f height = %f", 
		  screen.applicationFrame.size.width, screen.applicationFrame.size.height);
	
	// サムネイルItemリストの作成
	[self tumbnailItemsMake];
	
	// ScrollViewと描画Viewの作成
	[ self makeScrDrawView];
	
	// 選択サムネイルItemの順序Tableの初期化
	if (selectItemOrder == nil)
	{ selectItemOrder = [[NSMutableArray alloc] init];}

}
*/

// スワイプのセットアップ
- (void) setupSwipSupport
{
	// 右方向スワイプ
	UISwipeGestureRecognizer *swipeGestue = [[UISwipeGestureRecognizer alloc]
											 initWithTarget:self action:@selector(OnSwipeRightView:)];
	swipeGestue.direction = UISwipeGestureRecognizerDirectionRight;
	swipeGestue.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeGestue];
	[swipeGestue release];
	
	// 左方向スワイプ
	UISwipeGestureRecognizer *swipeGestueLeft = [[UISwipeGestureRecognizer alloc]
											 initWithTarget:self action:@selector(OnSwipeLeftView:)];
	swipeGestueLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	swipeGestueLeft.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeGestueLeft];
	[swipeGestueLeft release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [super viewDidLoad];
	
    // 背景色の変更 RGB:D8BFD8
    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];

	/*
	deleteNoAlert 
		= [[UIAlertView alloc]
			initWithTitle:
				@"選択画像を削除" message:@"画像が選択されていません" 
				delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK" ];
	*/
	deleteNoAlert = [[UIAlertView alloc] init];
	deleteNoAlert.title = @"選択画像を削除";
	deleteNoAlert.message = @"画像が選択されていません";
	deleteNoAlert.delegate = self;
	[deleteNoAlert addButtonWithTitle:@"OK"];
	
	/*
	deleteCheckAlert 
		= [[UIAlertView alloc]
			initWithTitle:
				@"選択画像を削除" message:@"選択されている画像を削除してよろしいてすか？" 
				delegate:self cancelButtonTitle:@"いいえ" otherButtonTitles:@"は　い"];
	*/
	deleteCheckAlert = [[UIAlertView alloc] init];
	deleteCheckAlert.title = @"選択画像を削除";
    // 2016/9/15 TMS サーバ画像削除対応
	deleteCheckAlert.message = @"選択されている画像を\n削除してよろしいですか？\n\nこの画像をお客様のメールに添付し\nている場合は、お客様がメール内の\n画像を見れなくなってしまいます。";
	deleteCheckAlert.delegate = self;
	[deleteCheckAlert addButtonWithTitle:@"は　い"];
	[deleteCheckAlert addButtonWithTitle:@"いいえ"];

	[actIndView stopAnimating];
	
	// スワイプのセットアップ
	[self setupSwipSupport];
	
	// 画面ロックモードを確認する
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	if ([mainVC isWindowLockState])
	{	tlbSecurity.hidden = NO; }
    
#ifdef CLOUD_SYNC
    _isImageReading = NO;       // イメージ読み込み中フラグをリセット
#endif
    
    _drawView.tag = -1; // tag を0以外にしておかないと、subviewのtag==0が取得出来ない
    isFinishDidLoad = YES;      // ViewDidLoad完了フラグ
    
    //lock scrollview zoom
    _scrollView.maximumZoomScale = 1.0;
    _scrollView.minimumZoomScale = 1.0;
}

// 画面が表示される都度callされる:viewWillAppear
- (void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	[super viewWillAppear : animated];
	
	// 再描画を行わない
    /*
	if (! _isThumbnailRedraw)
	{	
		// サムネイルItemのレイアウト
		UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
		[self thumbnailItemsLayout:(screen.applicationFrame.size.width == 320.0f)];
#else
		[self thumbnailItemsLayout:(screen.applicationFrame.size.width == 768.0f)];	
#endif
		
		return; 
	}
	*/
	// サムネイルの更新
	[self refreshThumbNail];
#ifdef DEBUG
	NSLog(@"viewWillAppear start");
#endif
	
}

// ペイント画面等で追加が有った場合に、選択画像のTAGをインクリメントする
// サムネイルの更新
- (void) refreshThumbNail:(BOOL)addPict
{
    if (addPict) {
        [self incrementTag];
    }
    
    [self refreshThumbNail];
}

// サムネイルの更新
- (void) refreshThumbNail
{
	// サムネイルItemリストの作成
	if (! [self tumbnailItemsMake])
	{	return; }		// 更新の必要なし
		// NSLog(@"tumbnailItemsMake end");
	
	// ScrollViewと描画Viewの作成
	[ self makeScrDrawView];
		// NSLog(@"makeScrDrawView end");
	
	// 選択サムネイルItemの順序Tableの初期化
	if (selectItemOrder == nil)
	{ selectItemOrder = [[NSMutableArray alloc] init];}	
//	else 
//	{	[selectItemOrder removeAllObjects]; }
	
	// サムネイルItemのレイアウト
	UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
	[self thumbnailItemsLayout:(screen.applicationFrame.size.width == 320.0f)];
#else
	[self thumbnailItemsLayout:(screen.applicationFrame.size.width == 768.0f)];
#endif
		// NSLog(@"thumbnailItemsLayout end");
    
    // 選択されているサムネイルの選択枠再描画
    for (NSUInteger i = 0; i < [selectItemOrder count]; i++)
    {
        u_int oIdx
        = (u_int)[((NSString*)[selectItemOrder objectAtIndex:i]) intValue];
        OKDThumbnailItemView *oItem = [self searchThnmbnailItemByTagID:oIdx];
        [oItem setSelectNumber:(u_int)i+1];
        [oItem setSelect:YES];
    }
}

// 一覧の選択TAGのインクリメント
- (void) incrementTag
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    for (NSUInteger i = 0; i < [selectItemOrder count]; i++)
    {
        u_int oIdx
        = (u_int)[((NSString*)[selectItemOrder objectAtIndex:i]) intValue];
        [selectItemOrder replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%ld", (long)++oIdx]];
    }
}

#pragma mark control_events
 
// カメラ画面へ戻る
- (IBAction)OnCameraView
{
	/*
	cameraView = [[camaraViewController alloc] initWithNibName:@"camaraViewController" bundle:nil];
	cameraView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:cameraView animated:YES];
	*/
	
	// 現時点で最上位のViewController(=self)を削除する
	/*
	_isBackCameraView = YES;
	[ [self parentViewController] dismissModalViewControllerAnimated:YES];
	*/
    
#ifdef CLOUD_SYNC
    // イメージの読み込み中は画面遷移しない
    if (_isImageReading)
    {   return; }
#endif

	// MainViewControllerの取得
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// popupWindowを閉じる
	[mainVC closePopupWindow:self];
}

// 選択画像一覧へ
- (IBAction)OnSelectPictView__
{
	if (! [self _isSelectItem]) 
	{
		// 選択なし
		deleteNoAlert.title = @"選択画像一覧へ";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		return;
	}
	
	if (selectPictVC != nil)
	{	[selectPictVC release]; }
	selectPictVC = nil;	
	
	//if (!selectPictVC)
	{
		selectPictVC = [[SelectPictureViewController alloc] 
							initWithNibName:@"SelectPictureViewController" bundle:nil];
	}

	selectPictVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	
	// 画像Imageのリスト（UIImage*のリスト ）を設定
	NSMutableArray *images = [ [NSMutableArray alloc] init];
	
	// 選択サムネイルItemの順序Tableより画像Imageを取得する
	for ( id item in selectItemOrder)
	{
		NSUInteger idx = (NSUInteger)[((NSString*)item) intValue];
		for (id iv in tumbnailItems)
		{	
			if ( ((OKDThumbnailItemView*)iv).tag == idx)
			{
				[images addObject: [((OKDThumbnailItemView*)iv) getImage]];
			}
		}
	}
	[selectPictVC setPictImageItems:images];
	[images release];
	
	selectPictVC.isNavigationCall = NO;
    [self presentViewController:selectPictVC animated:YES completion:nil];
	[selectPictVC setSelectedUserName:self._userName nameColor:self.userNameColor];
	
	if (selectPictVC != nil)
	{	[selectPictVC release]; }
	selectPictVC = nil;	
	
	_isBackCameraView = NO;
	
	// 選択画像一覧へ遷移する場合は、再描画を行わない
	_isThumbnailRedraw = NO;
}

// メモリワーニングが出ている場合に、次画面への遷移を抑制する
- (BOOL)checkEnableTransition
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    BOOL enable = NO;
    
    if (memWarning) {
#ifdef DEBUG
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"ご注意"
                                   message:[NSString stringWithFormat:@"空きメモリ容量が少ない為、\n処理を中断しました\niPad内の不要なアプリケーションを\n終了して下さい\n[%d]",
                                            [DevStatusCheck getFreeMemory]]
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];
#else
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"ご注意"
                                   message:@"空きメモリ容量が少ない為、\n処理を中断しました\niPad内の不要なアプリケーションを\n終了して下さい"
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];
#endif
        [alert show];
        [alert release];
    }
    else {
        enable = YES;
    }
    
    return enable;
}

// 選択画像一覧へ
- (IBAction)OnSelectPictView
{
    if (![self checkEnableTransition]) {
        return;
    }

    if (! [self _isSelectItem])
	{
		// 選択なし
		deleteNoAlert.title = @"選択画像一覧へ";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		return;
	}
	if (![self videoIsSelected]) {
        SelectPictureViewController *_selectPictVC
		= [[SelectPictureViewController alloc]
#ifdef CALULU_IPHONE
		   initWithNibName:@"ip_SelectPictureViewController" bundle:nil];
#else
    initWithNibName:@"SelectPictureViewController" bundle:nil];
#endif
        
        // 遅延して選択画像を表示する
        [self performSelector:@selector(transitionView:)
                   withObject:_selectPictVC afterDelay:0.05f];		// 0.05秒後に起動
        
        
        // 施術情報の設定（画像合成ビューで必要）
        [_selectPictVC setWorkItemInfo:_selectedUserID
                        workItemHistID:-1
                              workDate:[NSDate date]];
        
        
        
        // サムネイル画面からのコールは画面遷移を可とする
        _selectPictVC.isNavigationCall = YES;
        _selectPictVC.isFlickEnable = YES;
		
        // 選択画像の表示
        [self.navigationController pushViewController:_selectPictVC animated:YES];
        
        
        // iOS7で時間を置かずに initWithPicture を呼ぶと、ViewDidLoadが終了していないため
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            // 選択されたユーザ名と施術日の設定
            [_selectPictVC setSelectedUserName:self._userName nameColor:self.userNameColor];
            [_selectPictVC setWorkDateWithString:[Common getDateStringByLocalTime:nil]];
            
            [_selectPictVC release];
        });
    } else {
        SelectVideoViewController *_selectVideoVC =
        [[SelectVideoViewController alloc] initWithNibName:@"SelectVideoViewController" bundle:nil];
        
        // 遅延して選択画像を表示する
        [self performSelector:@selector(transitionSelectVideoView:)
                   withObject:_selectVideoVC afterDelay:0.05f];		// 0.05秒後に起動
        
        // 施術情報の設定（画像合成ビューで必要）
        [_selectVideoVC setWorkItemInfo:_selectedUserID
                        workItemHistID:-1
                              workDate:[NSDate date]];
        
        
        
        // サムネイル画面からのコールは画面遷移を可とする
        _selectVideoVC.isNavigationCall = YES;
        _selectVideoVC.isFlickEnable = YES;
		
        // 選択画像の表示
        [self.navigationController pushViewController:_selectVideoVC animated:YES];
        
        
        // iOS7で時間を置かずに initWithPicture を呼ぶと、ViewDidLoadが終了していないため
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            // 選択されたユーザ名と施術日の設定
            [_selectVideoVC setSelectedUserName:self._userName nameColor:self.userNameColor];
            [_selectVideoVC setWorkDateWithString:[Common getDateStringByLocalTime:nil]];
            
            [_selectVideoVC release];
        });
	}
	_isBackCameraView = NO;
	
	// 選択画像一覧へ遷移する場合は、再描画を行わない
	_isThumbnailRedraw = NO;
}

// 画像比較画面へ
- (IBAction)OnCompPictView
{
    if (![self checkEnableTransition]) {
        return;
    }
    
    if (! [self _isSelectItem])
    {
        // 選択なし
        deleteNoAlert.title = @"モーフィング画面へ";
        deleteNoAlert.message = @"画像が選択されていません";
        [deleteNoAlert show];
        return;
    }
    
    if (selectItemOrder.count < 2){
        deleteNoAlert.title = @"モーフィング画面へ";
        deleteNoAlert.message = @"画像を２枚以上選択してください。";
        [deleteNoAlert show];
        return;
    }
    
    if (selectItemOrder.count > 12){
        deleteNoAlert.title = @"モーフィング画面へ";
        deleteNoAlert.message = @"選択できる画像は１２枚までです。";
        [deleteNoAlert show];
        return;
    }
    
    if (![self videoIsSelected]) {
        PictureCompViewController  *pictureCompVC
        = [[[PictureCompViewController alloc]initWithNibName:@"PictureCompViewController" bundle:nil] autorelease];
        
        pictureCompVC.IsSetLayout = YES;
        
        pictureCompVC.IsOverlap = NO;
        pictureCompVC.IsUpdown = NO;
        pictureCompVC.IsMorphing = YES;
        pictureCompVC.IsNavigationCall = YES;
        
        [pictureCompVC setWorkItemInfo:_selectedUserID workItemHistID:nil];
        
        // 写真合成画面の表示
        [self.navigationController pushViewController:pictureCompVC animated:YES];
            
        // 遅延して選択画像を表示する
        [self performSelector:@selector(transitionPictureCompView:)
                   withObject:pictureCompVC afterDelay:0.05f];        // 0.05秒後に起動
        
    } else {
        deleteNoAlert.title = @"モーフィング画面へ";
        deleteNoAlert.message = @"動画が選択されています。モーフィング機能が有効なのは静止画のみです。";
        [deleteNoAlert show];
        return;
    }
    _isBackCameraView = NO;
    
    // 選択画像一覧へ遷移する場合は、再描画を行わない
    //_isThumbnailRedraw = NO;
}

// iPad2の場合に画像を縮小する
- (UIImage *)resizeImage:(UIImage *)orgImg maxSize:(NSInteger)maxSize
{
    UIImage *resultImg = orgImg;
    BOOL doResize = NO;
    CGRect rect;
    CGSize orgSize = orgImg.size;
    
    BOOL   isPortlate = (orgSize.width<orgSize.height)? YES : NO;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    if (isPortlate && (orgSize.height>maxSize)) {
        doResize = YES;
        rect.size.height = maxSize;
        rect.size.width  = maxSize * orgSize.width / orgSize.height;
    }
    else if (!isPortlate && (orgSize.width>maxSize)) {
        doResize = YES;
        rect.size.height = maxSize * orgSize.height / orgSize.width;
        rect.size.width  = maxSize;
    }
    
    if (doResize) { // リサイズ処理
#ifdef DEBUG
        NSLog(@"[DoResize] [%.01f:%.01f -> %.01f:%.01f]",
              orgSize.width, orgSize.height,
              rect.size.width, rect.size.height);
#endif
        UIGraphicsBeginImageContext(rect.size);     // 合成後画像の枠生成
        [orgImg drawInRect:rect];
        resultImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        //        [resultImg retain];
    }
    
    return resultImg;
}
- (void)transitionPictureCompView:(PictureCompViewController*)pictureCompVC{
    
    // Indicatorの表示
    [MainViewController showIndicatorWithViewController:pictureCompVC];
    NSMutableArray *selectTumbnailList = [self getOrderdTumbnailItems];
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID: _selectedUserID];

    [pictureCompVC setPictImageItems:selectTumbnailList];
    
    [pictureCompVC setSkip:NO];
    
    OKDThumbnailItemView *iv = [selectTumbnailList objectAtIndex:0];
    OKDThumbnailItemView *iv2 = [selectTumbnailList objectAtIndex:1];
    
    UIImage *pict1 = [((OKDThumbnailItemView*)iv) getRealSizeImage:imgFileMng];
    UIImage *pict2 = [((OKDThumbnailItemView*)iv2) getRealSizeImage:imgFileMng];
    
    if (pict1.size.width>WEB_CAM_MID_SIZE || pict1.size.height>WEB_CAM_MID_SIZE) {
        pict1 = [self resizeImage:pict1 maxSize:WEB_CAM_MID_SIZE];
    }
    if (pict2.size.width>WEB_CAM_MID_SIZE || pict2.size.height>WEB_CAM_MID_SIZE) {
        pict2 = [self resizeImage:pict2 maxSize:WEB_CAM_MID_SIZE];
    }
    
    [pictureCompVC setCoordinateThumbnailList];
    
    // Indicatorを閉じる
    [MainViewController closeIndicatorWithViewController:pictureCompVC];
    
    [pictureCompVC initWithPicture:pict1
                     pictureImage2:pict2
                          userName:self._userName nameColor:[UIColor redColor]
                          workDate:@"ー"];
    [imgFileMng release];
}
// 遅延して選択画像を表示する
- (void) transitionView:(SelectPictureViewController*)selectPictVC
{
	// 画像Imageのリスト（UIImage*のリスト ）を設定
	NSMutableArray *images = [ [NSMutableArray alloc] init];
	
	// Imageファイル管理のインスタンスを生成
	//OKDImageFileManager *imgFileMng
    //    = [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
    
#ifdef CLOUD_SYNC
   _isImageReading = YES;       // イメージ読み込み中フラグをセット
    // MainVCのインスタンスの取得
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    // 画像がダウンロードできるまで画面のスワイプを禁止
    [mainVC viewScrollLock:YES];
#endif
    
    // Indicatorの表示
    [MainViewController showIndicatorWithViewController:selectPictVC];
    
	[selectPictVC setPictImageItems:[self getOrderdTumbnailItems]];
    // Indicatorを閉じる
    [MainViewController closeIndicatorWithViewController:selectPictVC];
    
#ifdef CLOUD_SYNC 
    [mainVC viewScrollLock:NO];
    _isImageReading = NO;       // イメージ読み込み中フラグをリセット
#endif
	//[selectPictVC setPictImageItems:images];
	
    [selectPictVC viewWillAppear:NO];
    
    // 2013.0222 K.Nishijima add
    [images release];
}
// 遅延して選択動画を表示する
- (void) transitionSelectVideoView:(SelectVideoViewController*)selectVideoVC
{
    // Indicatorの表示
    // [MainViewController showIndicator];
    [selectVideoVC setMovieItems:[self getOrderdMovies]];
    // Indicatorを閉じる
    // [MainViewController closeIndicator];
//	// 履歴詳細画面からのコールでは、NavigationControlでは遷移しない
    selectVideoVC.isNavigationCall = YES;
	// 選択画像一覧へ遷移する場合は、再描画を行わない
	_isThumbnailRedraw = NO;
	
	// 遷移画面を動画一覧にする
	///////////_windowView = WIN_VIEW_SELECT_VIDEO;
	[selectVideoVC viewWillAppear:NO];
}
// 選択サムネイルItemの順序Tableより画像Imageを取得する
- (NSMutableArray *)getOrderdTumbnailItems{
    NSMutableArray *orderdTumbnailItems = [NSMutableArray array];
	for ( id item in selectItemOrder)
	{
		NSUInteger idx = (NSUInteger)[((NSString*)item) intValue];
        [tumbnailItems retain];
		for (id iv in tumbnailItems)
		{
			if ( ((OKDThumbnailItemView*)iv).tag == idx)
			{
				// サムネイルファイルはここで実サイズ版のファイル名に変える
                NSString *aFile = [((OKDThumbnailItemView*)iv) getFileName];
                NSString *realFile = ([ aFile hasSuffix:THUMBNAIL_SIZE_EXT])?
                [aFile stringByReplacingOccurrencesOfString:THUMBNAIL_SIZE_EXT
                                                 withString:REAL_SIZE_EXT] :
                aFile;
                [((OKDThumbnailItemView*)iv) setFileName:realFile];
                [orderdTumbnailItems addObject:iv];
			}
		}
	}
    return orderdTumbnailItems;
}
// 選択動画の配列
- (NSMutableArray *)getOrderdMovies{
    NSMutableArray *orderdMovies = [NSMutableArray array];
	for ( id item in selectItemOrder)
	{
		NSUInteger idx = (NSUInteger)[((NSString*)item) intValue];
		for (id iv in tumbnailItems)
		{
			if ( ((OKDThumbnailItemView*)iv).tag == idx)
			{
                NSString *tmb = [iv getFileName];
                MovieResource *movie = [[MovieResource alloc] initWithUserId:_selectedUserID fileName:tmb];
                [movie retain];
                [orderdMovies addObject:movie];
                
			}
		}
	}
    return orderdMovies;
}
- (BOOL) _isSelectItem
{
	// 選択個数を確認
	BOOL sel = NO;
	for ( id item in tumbnailItems)
	{
		if (((OKDThumbnailItemView*)item).IsSelected)
		{	
			sel = YES;
			break;
		}
	}
	
	return (sel);
}

// 選択画像をお客様写真に設定
- (IBAction)OnSetUserPicture
{
	OKDThumbnailItemView *itemView = nil;
	
	for ( id item in tumbnailItems)
	{
		if (((OKDThumbnailItemView*)item).IsSelected)
		{	
			if (! itemView)
			{
				itemView = (OKDThumbnailItemView*)item;
			}
			else 
			{
				deleteNoAlert.title = @"お客様写真に設定";
				deleteNoAlert.message = @"画像は１つだけ設定できます";
				[deleteNoAlert show];
				
				return;
			}
		}
	}
	
	if (!itemView) 
	{
		// 選択なし
		deleteNoAlert.title = @"お客様写真に設定";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		
		return;
	}
	
	// ユーザ情報のデータベースを更新
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	// パスを取り除いたファイル名に変換
	/*
	NSString *pictFolder 
		= [NSString stringWithFormat:PICTURE_FOLDER, NSHomeDirectory(), _selectedUserID];
	NSString *fnNoPath 
		= [ [itemView getFileName] stringByReplacingOccurrencesOfString:pictFolder
															 withString:@""];
	*/
    
    // サムネイルファイルはここで実サイズ版のファイル名に変える
    NSString *aFile =[itemView getFileName];
    NSString *realFile = ([ aFile hasSuffix:THUMBNAIL_SIZE_EXT])?
    [aFile stringByReplacingOccurrencesOfString:THUMBNAIL_SIZE_EXT 
                                     withString:REAL_SIZE_EXT] :
    aFile;

	
	if (! [usrDbMng updateUserPicture:
			_selectedUserID pictureURL:realFile ])	// fnNoPath
	{
		deleteNoAlert.title = @"お客様写真に設定";
		deleteNoAlert.message 
			= @"お客様写真の設定に失敗しました\n(誠に恐れ入りますが\n再設定をお願いいたします)";
		[deleteNoAlert show];
	}
	else 
	{
		deleteNoAlert.title = @"お客様写真に設定";
		deleteNoAlert.message 
			= @"選択した画像を\nお客様写真の設定しました\n(お客様選択画面で確認できます)";
		[deleteNoAlert show];
		
	}

	
	[usrDbMng release];
}

// 選択画像を削除
- (IBAction)OnDeleteThubnails
{
	// 選択個数を確認
	/*
	NSUInteger cnt = 0;
	for ( id item in tumbnailItems)
	{
		BOOL sel = ((OKDThumbnailItemView*)item).IsSelected;
		if (sel == YES)
		{	
			cnt++;
			break;
		}
	}
	*/
	//
	if (! [self _isSelectItem])
	{
		// 選択なし
		deleteNoAlert.title = @"選択画像を削除";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
	}
	else 
	{
        BOOL isFromUser = NO;
        for ( id item in tumbnailItems)
        {
            if (((OKDThumbnailItemView*)item).IsSelected)
            {
                NSString *fileName = [((OKDThumbnailItemView*)item) getFileName];
                // userから送られたファイルの場合ファイル名は..._u.jpgになっている
                if ([fileName hasSuffix:@"u.tmb"] || [fileName hasSuffix:@"u.jpg"]) {
                    isFromUser = YES;
                    break;
                }
            }
        }
        if (isFromUser) {
            deleteNoAlert.title = @"選択画像を削除";
            deleteNoAlert.message = @"お客様の写真は削除できません。";
            [deleteNoAlert show];
        } else {
            [deleteCheckAlert show];
        }
	}
	
}

// 右方向のスワイプイベント
- (void)OnSwipeRightView:(id)sender
{
	// 前画面に戻る
	[self OnCameraView];
}

// 左方向のスワイプイベント
- (void)OnSwipeLeftView:(id)sender
{
	// 選択画像一覧へ進む
	[self OnSelectPictView];
}


// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// 削除確認ではいの場合、選択画像を削除
	if ( (alertView == deleteCheckAlert) && (buttonIndex == 0) ) 
	{
		// 削除用リスト
		NSMutableArray *deleteItems = [[NSMutableArray alloc] init];
		NSMutableArray *deleteTags = [[NSMutableArray alloc] init];
		// 削除用ファイルリスト
		NSMutableArray *deleteFiles = [[NSMutableArray alloc] init];
		
		userDbManager *usrDbMng = [[userDbManager alloc] init];
		
		// Imageファイル管理のインスタンスを生成
		OKDImageFileManager *imgFileMng
			= [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
		
		for ( id item in tumbnailItems)
		{
			OKDThumbnailItemView *thItem = (OKDThumbnailItemView*)item;
			if (! thItem.IsSelected)
			{	continue;}
			
			// とりあえず親Viewより削除
			[thItem removeFromSuperview];
			
			// ファイル名の取得：パスを除くファイル名 -> サムネイル拡張子なので、実ファイル拡張子に変更
			// NSString *fileName = [[NSString alloc] initWithString:[item getFileName]];
			NSString *thmbFile = [thItem getFileName];
            NSString *fileName = [thmbFile stringByReplacingOccurrencesOfString:THUMBNAIL_SIZE_EXT 
                                                                     withString:REAL_SIZE_EXT];

#ifdef VER141_LATER
			// ファイルの削除
			[imgFileMng deleteImageBothByRealSize:fileName];
			/*
			if ([[NSFileManager defaultManager] fileExistsAtPath:fileName])
			{
				// 念のためFileの存在確認
				NSError* error;
				[[NSFileManager defaultManager] removeItemAtPath:fileName error:&error];
			}
			*/
#endif		
			// 削除用リストに加える
			[deleteItems addObject:thItem];
			[deleteFiles addObject:[thItem getFileName]];
			
			for (NSUInteger i = 0; i < [selectItemOrder count]; i++) 
			{
				NSUInteger tag = (NSUInteger)[((NSString*)([selectItemOrder objectAtIndex:i])) intValue];
				if (tag == ((OKDThumbnailItemView*)item).tag)
				{
					[deleteTags addObject:[selectItemOrder objectAtIndex:i]];
					break;
				}
			}
			
			// Document以下のファイル名に変換
			NSString *documentFileName =
				// [fileName substringFromIndex:([NSHomeDirectory() length] + 1)];
				[imgFileMng getDocumentFolderFilename:fileName];
            // 動画削除
            if ([item isKindOfClass:[VideoThumbnailItemView class]]) {
                MovieResource *resource = [[MovieResource alloc] initWithPath:documentFileName];
                // データベースの履歴用ユーザ写真を削除:写真urlをキーとして削除
                [usrDbMng deleteHistUserVideo:NSIntegerMin
                                     videoURL:resource.path];
                // データベースの履歴テーブルの代表画像が削除対象であれば無効にする
                [usrDbMng updateHistHeadPictureByNewUrl:resource.thumbnailPath newUrl:nil];
                // ユーザの写真が削除対象であれば無効にする
                [usrDbMng updateUserPictureByNewUrl:fileName newUrl:nil];
                // ファイルの削除  DB更新後に削除する
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:resource.movieFullPath error:&error];
                if (error) {NSLog(@"%@ %@",error.localizedDescription, resource.movieFullPath);}
                error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:resource.thumbnailFullPath error:&error];
                if (error) {NSLog(@"%@ %@",error.localizedDescription, resource.thumbnailFullPath);}
                [resource release];
            } else {
            
			// データベースの履歴用ユーザ写真を削除:写真urlをキーとして削除
			[usrDbMng deleteHistUserPicture:HISTID_INTMIN
								 pictureURL:documentFileName];
			// データベースの履歴テーブルの代表画像が削除対象であれば無効にする
			[usrDbMng updateHistHeadPictureByNewUrl:documentFileName newUrl:nil];
			// ユーザの写真が削除対象であれば無効にする
			[usrDbMng updateUserPictureByNewUrl:fileName newUrl:nil];
            
            // ---->
            // サムネイルからtmbのみの場合に消去できないため以下の処理を追加
#ifdef VER142_LATER
            NSString *fileName1 
                = [fileName stringByReplacingOccurrencesOfString:THUMBNAIL_SIZE_EXT 
                                                      withString:REAL_SIZE_EXT];

            // Document以下のファイル名に変換
            NSString *documentFileName1 =
                [imgFileMng getDocumentFolderFilename:fileName1];
            
            // データベースの履歴用ユーザ写真を削除:写真urlをキーとして削除
            [usrDbMng deleteHistUserPicture:NSIntegerMin
                                 pictureURL:documentFileName1];
            
            // データベースの履歴テーブルの代表画像が削除対象であれば無効にする
            [usrDbMng updateHistHeadPictureByNewUrl:documentFileName1 
                                             newUrl:nil];
            // ユーザの写真が削除対象であれば無効にする
            [usrDbMng updateUserPictureByNewUrl:fileName1 newUrl:nil];
#endif
            // <----
            
            // ファイルの削除 DB更新後に削除する：Ver141
			[imgFileMng deleteImageBothByRealSize:fileName];
            }
		}
		
		// サムネイルItemリストより削除
		for (id delItem in deleteItems) {
			[tumbnailItems removeObject:delItem];
		}
		
		// 選択サムネイルItemの順序Tableより削除
		for (id delTag in deleteTags) {
			[selectItemOrder removeObject:delTag];
		}
		
		// クライアントクラスへ削除イベントを通知する
		if ( (self.delegate) &&
			 ([self.delegate respondsToSelector:@selector(didDeletedThumbnails:deletedFiles:)]))
		{	[self.delegate didDeletedThumbnails:self deletedFiles:deleteFiles]; } 
        
		[imgFileMng release];
		
		[usrDbMng release];
		
		[deleteFiles release];
		
		[deleteTags release];
		
		// 削除用リストのクリア
		[deleteItems release];
		
		// Itemを再度レイアウトする
		UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
		[self thumbnailItemsLayout:(screen.applicationFrame.size.width == 320.0f)];
#else
      	[self thumbnailItemsLayout:(screen.applicationFrame.size.width == 768.0f)];
#endif
	}
	
	// alertの表示を消す
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

// キャンセル
- (IBAction)OnChancel
{
	for ( id item in tumbnailItems)
	{
		// 選択をキャンセルする
		[(OKDThumbnailItemView*)item setSelect:NO];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

// 縦横切り替え後のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{			
	BOOL isPortrait;
	
	switch (toInterfaceOrientation) {
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
	// サムネイルItemのレイアウト
	[self thumbnailItemsLayout:isPortrait];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// if (_isBackCameraView != YES)
	{
		// 現時点で最上位のViewController(=self)を削除する
        [ [self parentViewController] dismissViewControllerAnimated:animated completion:nil];
	}
	
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
   //  [super didReceiveMemoryWarning];
    
	if (selectPictVC != nil)
	{	[selectPictVC release]; }
	selectPictVC = nil;
	
    // Release any cached data, images, etc that aren't in use.
    if (!memWarning) {
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        if ([[mainVC getNowCurrentViewController] isKindOfClass:[ThumbnailViewController class]]) {
#ifdef DEBUG
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"ご注意"
                                       message:[NSString stringWithFormat:@"空きメモリ容量が少ない為、\niPad内の不要なアプリケーションを\n終了して下さい\n[%d]",
                                                [DevStatusCheck getFreeMemory]]
                                      delegate:nil
                             cancelButtonTitle:nil
                             otherButtonTitles:@"OK", nil];
#else
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"ご注意"
                                       message:@"空きメモリ容量が少ない為、\niPad内の不要なアプリケーションを\n終了して下さい"
                                      delegate:nil
                             cancelButtonTitle:nil
                             otherButtonTitles:@"OK", nil];
#endif
            [alert show];
            [alert release];
        }
    }
    memWarning = YES;
    
    [super didReceiveMemoryWarning];
}

// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive {
    memWarning = NO;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [btnUserName release];
    [actIndView release];
    [tlbSecurity release];
    
    deleteNoAlert.delegate = nil;
	[deleteNoAlert release];
    deleteCheckAlert.delegate = nil;
	[deleteCheckAlert release];
	
    [selectItemOrder removeAllObjects];
	[selectItemOrder release];
	
    for ( id vw in _drawView.subviews)
    {
        [((UIView*)vw) removeFromSuperview];
        ((OKDThumbnailItemView *)vw).delegate = nil;
    }
//    for (OKDThumbnailItemView *thmView in tumbnailItems) {
//        [thmView release];
//        thmView.delegate = nil;
//    }
    for (OKDThumbnailItemView *thmView in tumbnailItems) {
        thmView.delegate = nil;
        [thmView removeFromSuperview];
    }
    [tumbnailItems removeAllObjects];
    [tumbnailItems release];
    tumbnailItems = nil;

    // _drawViewを削除する
    [[_scrollView viewWithTag:DRAW_VIEW_TAG] removeFromSuperview];

    [_scrollView removeFromSuperview];
    _scrollView.delegate = nil;
    [_scrollView release];
    
    for (UIGestureRecognizer *gesture in [self.view gestureRecognizers]) {
        if ([gesture isKindOfClass:[UISwipeGestureRecognizer class]]) {
            [self.view removeGestureRecognizer:gesture];
        }
    }
    
	if (selectPictVC != nil)
	{	[selectPictVC release]; }
	selectPictVC = nil;
    
    self.delegate = nil;
		
	// スワイプイベントのリリース:autoreleaseのため不要？
	/*
	for (UIGestureRecognizer *gesture in self.view.gestureRecognizers)
	{	[gesture release];　}
	[self.view.gestureRecognizers release];
	*/
	
    [btnTrash release];
    [toolbarBottom release];
    [toolbarTop release];
    [super dealloc];
}


@end
