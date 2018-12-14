//
//  HistDetailViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/12/09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "MainViewController.h"

#import "HistDetailViewController.h"
#import "HistListViewController.h"

#import "SelectPictureViewController.h"
#import "camaraViewController.h"
// #import "ThumbnailViewController.h"

#import "WorkItemSetPopup.h"
#import "userWorkItemEditPopup.h"
#import "UserInfoEditViewController.h"

#import "HistListTableViewCell.h"

#import "mstUser.h"
#import "fcUserWorkItem.h"

#import "userDbManager.h"

#import "model/OKDImageFileManager.h"

#import "takePicture4PhotoLibrary.h"

#import "MovieResource.h"
#import "SelectVideoViewController.h"

#import "appCapacityManager.h"

#import "DevStatusCheck.h"
#import "CustomerPopup.h"

@implementation HistDetailViewController

@synthesize selectedWorkItem = _selectedWorkItem;
@synthesize selectedUserID = _selectedUserID;
@synthesize selectedUserName = _selectedUserName;
@synthesize selectedHistID = _selectedHistID;
@synthesize selectedViewCell = _selectedViewCell;

//START, 2011.06.18, chen, ADD
@synthesize selectedWorkItem2 = _selectedWorkItem2;
@synthesize lblMemo1;
@synthesize lblMemo2;
@synthesize btnMemo1;
@synthesize btnMemo2;
//END
@synthesize videoPreviewVC;
/*
 ** DEFINE
 */
#define OS_VERSION 7.0f

#pragma mark local_Methods

// フルパスのファイル名からサムネイルのタイトル［yy年mm月dd日 HH時MM分］を取得する
- (NSString*) makeThumbNailTitle:(NSString*)fullPath
{
	// フルパスからファイル名だけを取り出す->yyMMdd_HHmmss.jpg
	NSString *fileName = [fullPath lastPathComponent];
	
	// 文字列から日付を取り出す
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
	[formatter2 setDateFormat:@"20yy年MM月dd日 HH時mm分"];
	
	return ([formatter2 stringFromDate:date]);
}

// サムネイルItemリストの作成（写真データの読み込み含む）
- (void) tumbnailItemsMake
{
	[self.view bringSubviewToFront:actIndView];
	[actIndView startAnimating];
	[self.view bringSubviewToFront:actIndView];	
	
	// サムネイルitemリストの初期化
	if (tumbnailItems != nil)
	{ 
		// 既に表示されているitemViewを全てクリアする
		for (id item in tumbnailItems)
		{	[ ((OKDThumbnailItemView*)item) removeFromSuperview]; }
		
		// リストをクリアする
		[tumbnailItems removeAllObjects];
	}
	else 
	{
		// リストを空で作成
        for (id d in tumbnailItems) {
            [d release];
        }
        [tumbnailItems release];
		tumbnailItems = [ [NSMutableArray alloc] init];
		[tumbnailItems retain];
	}
	
	// 写真の設定
	/////////////////////////////////
	int idx = 0;
	if (self.selectedWorkItem)
	{
		for (id pictUrl in self.selectedWorkItem.picturesUrls)
		{            
			// ファイルのフルパス
			/*NSString * fileName 
				= [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), (NSString*)pictUrl];*/
			// パスを除くファイル名
            NSString *fileName
                = [((NSString*)pictUrl) lastPathComponent];

			// サムネイルViewの作成
			OKDThumbnailItemView *thumbnailView 
				= [[[OKDThumbnailItemView alloc] initWithFrame:
					CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)] autorelease];
			[thumbnailView setFileName:fileName];

            //2012 7/3 伊藤 
            //データベースからタイトルを読み出す
            userDbManager *usrDbMng = [[userDbManager alloc] init];
            // Imageファイル管理のインスタンスを生成
            OKDImageFileManager *imgFileMng
            = [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
            // Document以下のファイル名に変換
            NSString *documentFileName = [[NSString alloc] initWithString:[fileName lastPathComponent]];
            documentFileName = [documentFileName substringToIndex:[documentFileName length] - 3];
            documentFileName = [NSString stringWithFormat:@"%@jpg",documentFileName];
            documentFileName = [imgFileMng getDocumentFolderFilename:documentFileName];
            NSArray* imageProfile = [usrDbMng getImageProfile:documentFileName];
			NSString* imageTitle = @"";
			if ([imageProfile count]>0) {
				imageTitle = [imageProfile objectAtIndex:0];
			}
            if ([imageTitle isEqualToString:@""]) {
                // タイトルの形式をyyyy年mm月dd日　HH時MM分ss秒　形式にする
                [thumbnailView setTitle:[self makeThumbNailTitle:fileName]];
            }else {
                [thumbnailView setTitle:imageTitle];
            }
            [usrDbMng release];
            [imgFileMng release];
/*#else
            [thumbnailView setTitle:[self makeThumbNailTitle:fileName]];

#endif*/
			thumbnailView.delegate = self;
			thumbnailView.tag = idx;
			
			// itemをリストに加える
			[tumbnailItems addObject:thumbnailView];
			
			// 写真コンテナにサムネイルViewを加える
			// DELC SASAGE [viewPictureConteiner addSubview:thumbnailView];

			idx++;
			
			// TODO:scrollView対応必要
			/*
			if (idx >= 8)
			{ break; }
			*/
		}
		for (id videoUrl in self.selectedWorkItem.videosUrls)
		{
			// パスを除くファイル名
            MovieResource *movieResource = [[MovieResource alloc] initWithPath:(NSString *)videoUrl];
			// サムネイルViewの作成
			VideoThumbnailItemView *thumbnailView
            = [[VideoThumbnailItemView alloc] initWithFrame:
               CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)];
			[thumbnailView setFileName:movieResource.thumbnailPath];
            
            //データベースからタイトルを読み出す
            userDbManager *usrDbMng = [[userDbManager alloc] init];
            NSArray* imageProfile = [usrDbMng getVideoProfile:movieResource.path];
            NSString* imageTitle = [imageProfile objectAtIndex:0];
            if ([imageTitle isEqualToString:@""]) {
                // タイトルの形式をyyyy年mm月dd日　HH時MM分ss秒　形式にする
                [thumbnailView setTitle:[self makeThumbNailTitle:movieResource.thumbnailPath]];
            }else {
                [thumbnailView setTitle:imageTitle];
            }
			[movieResource release];
            [usrDbMng release];
			thumbnailView.delegate = self;
			thumbnailView.tag = idx;
			
			// itemをリストに加える
			[tumbnailItems addObject:thumbnailView];
            [thumbnailView release];
//            [movieResource release];
//            [imageProfile release];
//            [imageTitle release];
			// 写真コンテナにサムネイルViewを加える
			// DELC SASAGE [viewPictureConteiner addSubview:thumbnailView];
            
			idx++;
		}
        [tumbnailItems sortUsingComparator:^(id v1, id v2){
            NSString *f1 = [((OKDThumbnailItemView *)v1) getFileName];
            NSString *f2 = [((OKDThumbnailItemView *)v2) getFileName];
            NSComparisonResult result = [f2 compare:f1];
            
			f1 = nil;
			f2 = nil;
            
            return (result);
            
            /*return [[((OKDThumbnailItemView *)v2) getFileName]
             compare:[((OKDThumbnailItemView *)v1) getFileName]];*/
        } ];
        idx = 0;
        for (OKDThumbnailItemView *view in tumbnailItems) {
            view.tag = idx++;
            [viewPictureConteiner addSubview:view];
        }
	}
	
	// 選択サムネイルItemの順序Tableの初期化
	if (selectItemOrder == nil)
	{ selectItemOrder = [[NSMutableArray alloc] init];}	
	else 
	{	[selectItemOrder removeAllObjects]; }	
	
	// Timerにより別スレッドでImageを描画する
	[NSTimer scheduledTimerWithTimeInterval:0.1f 
									 target:self 
								   selector:@selector(OnImageWrite:) 
								   userInfo:nil 
									repeats:NO]; 
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
	
//	for (id item in tumbnailItems)
//	{
//		OKDThumbnailItemView *view = (OKDThumbnailItemView*)item;
//		[view writeToThumbnail:imgFileMng];
//		//[view writeToImage];
//		
//		[view drawRect:view.bounds];
//		// NSLog(@"imageWrite done on %d", ((OKDThumbnailItemView*)item).tag);
//	}
    // 高速列挙でエラーがでたため
        for (int i = 0; i < tumbnailItems.count; i++) {
            OKDThumbnailItemView *view = (OKDThumbnailItemView*)tumbnailItems[i];
            [view writeToThumbnail:imgFileMng];
            [view drawRect:view.bounds];
        }
	[actIndView stopAnimating];
	
	[imgFileMng release];
#ifdef DEBUG
	NSLog(@"complite imageWrite timer");
#endif
}

// サムネイルItemのレイアウト
-(void) thumbnailItemsLayout
{
	// 横方向の数
	CGFloat xNums = (scrollViewPictureConteiner.bounds.size.width == THUBNAIL_CONTEINER_WIDTH)?
						ITEM_X_NUMS : ITEM_X_NUMS_LS;
	// 縦方向の数  height = THUBNAIL_CONTEINER_HEIHT:通常 // THUBNAIL_CONTEINER_HEIGHT_LOCK:画面ロック
	CGFloat yNums = (scrollViewPictureConteiner.bounds.size.height == THUBNAIL_CONTEINER_HEIGHT)?
						ITEM_Y_NUMS : ITEM_Y_NUMS_WIN_LOCK;
	
	// 横マージン
	CGFloat wm = (scrollViewPictureConteiner.bounds.size.width -
				  (ITEM_WITH * xNums) ) / (xNums + 1);
	// 縦マージン
	CGFloat hm = (scrollViewPictureConteiner.bounds.size.height -
				  (ITEM_HEIGHT * yNums) ) / (yNums + 1);
	
	// コンテナViewのサイズ
	NSInteger itemCount = [tumbnailItems count];
	NSInteger ih = itemCount / (NSInteger)xNums; 
	if (ih < (NSInteger)yNums) { ih = (NSInteger)yNums; }
	else if ( (itemCount % (NSInteger)xNums) != 0) { ih++;}
	CGFloat cHeight = (CGFloat)((hm * (ih + 1)) + (ITEM_HEIGHT * ih));
	[viewPictureConteiner setFrame:CGRectMake
		(0.0f, 0.0f, scrollViewPictureConteiner.bounds.size.width, cHeight)];
	
	// Scrollの設定
	[scrollViewPictureConteiner setContentSize: viewPictureConteiner.frame.size];
	
	// 各Itemの通し番号:0〜 tumbnailItemsのcount
	int idx = 0;
	for (id thumbnailView in tumbnailItems)
	{
		// 列数番号：0 〜 (xNums - 1)
		NSInteger ix = idx % (NSInteger)xNums;
		// 行数番号：0 〜 
		NSInteger iy = idx / (NSInteger)xNums;
		
		// 位置設定
		[thumbnailView setFrame:CGRectMake(
							   ((wm * (ix + 1)) + (ITEM_WITH * ix)), 
							   ((hm * (iy + 1)) + (ITEM_HEIGHT * iy)), 
							   ITEM_WITH, 
							   ITEM_HEIGHT)];
		idx++;
		
	}
}

// 施術内容などのControlへの設定
-(void) setWorkItem2Control
{
	// 施術日、内容、メモの設定
	lblWorkDate.text = (self.selectedWorkItem)?
	[self.selectedWorkItem getNewWorkDateByLocalTime:isJapanese] : NO_DEFINE_NEW_WORK_DATE_STR;
#ifdef DEBUG
	NSLog(@"%s[%d] %@", __func__, isJapanese, lblWorkDate.text);
#endif
	tvWorkItem.text = (self.selectedWorkItem)?
		self.selectedWorkItem.workItemListString : @"";
	tvWorkItem.tag = 0;
	
	tvWorkItem2.text = (self.selectedWorkItem)?
		self.selectedWorkItem.workItemListString2 : @"";
	tvWorkItem2.tag = 1;
	
	tvMemo.text = (self.selectedWorkItem)?
		[self.selectedWorkItem getTopMemo] : NO_TOP_MEMO_STR;
	
	// 項目編集のリストの初期設定
	NSUInteger idx = 0;
	for (NSMutableArray* names in _itemEdits)
	{	
		[names removeAllObjects]; 
		if (self.selectedWorkItem)
		{
			NSMutableArray* listNumber = (idx==0)? 
				self.selectedWorkItem.workItemListNumber:
				self.selectedWorkItem.workItemListNumber2;
			for (NSString* name in listNumber)
			{	[ names addObject:name]; }
		}
		idx++;
	}
	
	// 施術内容の作業用変数を初期化
	if (_workItemIDs)
	{
		[_workItemIDs removeAllObjects];
	}
	else 
	{
		_workItemIDs = [ [NSMutableArray alloc] init];
		[_workItemIDs retain];
	}
	/*
	if (self.selectedWorkItem)
	{
		for (id itemID in self.selectedWorkItem.workItemListNumber)
		{
			// 作業用の施術内容ID一覧にそのままコピーする
			[_workItemIDs addObject:itemID];
		}
	}
	*/
	
	//START, 2011.06.18, chen, ADD
	// 施術内容2の作業用変数を初期化
	if (_workItemIDs2)
	{
		[_workItemIDs2 removeAllObjects];
	}
	else 
	{
		_workItemIDs2 = [ [NSMutableArray alloc] init];
		[_workItemIDs2 retain];
	}
	/*
	if (self.selectedWorkItem)
	{
		for (id itemID in self.selectedWorkItem.workItemListNumber2)
		{
			// 作業用の施術内容ID一覧にそのままコピーする
			[_workItemIDs2 addObject:itemID];
		}
	}
	*/
	//END
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

// Alertダイアログの初期化
-(void) initAlertDialog
{
	deleteNoAlert = [[UIAlertView alloc] init];
	deleteNoAlert.title = @"選択画像を削除";
	deleteNoAlert.message = @"画像が選択されていません";
	deleteNoAlert.delegate = self;
	[deleteNoAlert addButtonWithTitle:@"OK"];
	
	deleteCheckAlert = [[UIAlertView alloc] init];
	deleteCheckAlert.title = @"選択画像を削除";
	// 2016/9/15 TMS サーバ画像削除対応
	deleteCheckAlert.message = @"選択されている画像を\n削除してよろしいですか？\n\nこの画像をお客様のメールに添付し\nている場合は、お客様がメール内の\n画像を見れなくなってしまいます。";
	deleteCheckAlert.delegate = self;
	[deleteCheckAlert addButtonWithTitle:@"は　い"];
	[deleteCheckAlert addButtonWithTitle:@"いいえ"];
	
	modifyCheckAlert = [[UIAlertView alloc] init];
	modifyCheckAlert.title = @"施術内容（またはメモ）は\n編集されています";
	modifyCheckAlert.message = @"施術内容を更新しますか？\n（「いいえ」を選ぶと編集内容は\n破棄されます）";
	modifyCheckAlert.delegate = self;
	[modifyCheckAlert addButtonWithTitle:@"は　い"];
	[modifyCheckAlert addButtonWithTitle:@"いいえ"];
	
	headPictrueCheckAlert = [[UIAlertView alloc] init];
	headPictrueCheckAlert.title = @"選択を代表画像にする";
	headPictrueCheckAlert.message = @"選択した画像を\n履歴の代表写真にしますか？";
	headPictrueCheckAlert.delegate = self;
	[headPictrueCheckAlert addButtonWithTitle:@"は　い"];
	[headPictrueCheckAlert addButtonWithTitle:@"いいえ"];
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

-(NSString*) getDocumentPath:(OKDThumbnailItemView*)item
{
	// パスなしファイル名をサムネイルItemより取得
	NSString *fileName = [item getFileName];
	
	// Imageファイル管理のインスタンスを生成
	OKDImageFileManager *imgFileMng
		= [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];		
	
	// HomeDirectory部を取り除く
	// ret = [fullPath substringFromIndex:([ NSHomeDirectory() length] + 1) ];
	
	// Document以下のファイル名に変換
	NSString *documentFileName =
		[imgFileMng getDocumentFolderFilename:fileName];
	
	[imgFileMng release];
	fileName = nil;
	
	return (documentFileName);
}

// 更新と取消ボタンのenable設定
- (void)setEnableWorkItemButton:(BOOL)isEnable
{
	btnUpdateWorkItem.enabled =
		btnChancelWorkItem.enabled = isEnable;
}

// 施術内容マスタテーブルの初期化
- (void) initWorkItemMasterTable:(userDbManager*)usrDbMng
{
	if (_workItemMasterTable)
	{	[_workItemMasterTable release]; }
	
	BOOL isDbOpen = NO;
	if (! usrDbMng)
	{
		usrDbMng = [[userDbManager alloc] init];
		isDbOpen = YES;
	}
	
	// データベースから施術内容マスタテーブルを取得
	_workItemMasterTable = [usrDbMng getWorkItemTable:ITEM_EDIT_USER_WORK1_TABLE];
	[_workItemMasterTable retain];
	
	if (isDbOpen)
	{	[usrDbMng release]; }
}

//START, 2011.06.18, chen, ADD
// 施術内容マスタテーブルの初期化
- (void) initWorkItemMasterTable2:(userDbManager*)usrDbMng
{
	if (_workItemMasterTable2)
	{	[_workItemMasterTable2 release]; }
	
	BOOL isDbOpen = NO;
	if (! usrDbMng)
	{
		usrDbMng = [[userDbManager alloc] init];
		isDbOpen = YES;
	}
	
	// データベースから施術内容マスタテーブルを取得
	_workItemMasterTable2 = [usrDbMng getWorkItemTable:ITEM_EDIT_USER_WORK2_TABLE];
	[_workItemMasterTable2 retain];
	
	if (isDbOpen)
	{	[usrDbMng release]; }
}


// 項目編集リストの初期化
- (void)initItemEdits
{
	_itemEdits = [NSMutableArray array];
	[_itemEdits retain];
	
	for (NSInteger i = 0; i < 2; i++)
	{
		NSMutableArray *item = [NSMutableArray array];
		[item retain];
		[_itemEdits addObject:item];
        [item release];
	}
}

//END

// 写真の表示
- (UIImage*) makeImagePicture:(NSString*)pictUrl pictSize:(CGSize)size
{
	if ( (!pictUrl) || ((pictUrl) && ([pictUrl length] <= 0) ))
	{	return (nil); }
	
	// NSLog(@"makeImagePicture start ------------------->");
	
	NSData *fileDat 
	= [NSData dataWithContentsOfFile:
	   [NSString stringWithFormat:@"%@/%@", 
		NSHomeDirectory(), pictUrl]];
	// NSLog(@"makeImagePicture read data end");
	
	UIImage *img = [UIImage imageWithData:fileDat];
	if (img == nil)
	{ 
		return(nil); 
	}
	// NSLog(@"makeImagePicture make UIImage end");
	
	// return(img);
	
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
//    [img release];
//    [fileDat release];
	img = nil;
	fileDat = nil;
	
	// NSLog(@"<-------------------makeImagePicture end ");
	
	return (drawImg);
}

// スクロールビューのピンチ（ズーム）機能の設定
-(void) setupScrollViewZoom
{
	// ピンチ（ズーム）機能の追加:delegate指定
	[scrollViewPictureConteiner setDelegate:self];
	
	// スクロールビューの拡大と縮小の範囲設定（これがないとズームしない）
	[scrollViewPictureConteiner setMinimumZoomScale:1.0f];
	[scrollViewPictureConteiner setMaximumZoomScale:10.0f];
}

// 写真一覧表示
- (IBAction) OnPictureListView:(id)sender
{
	ThumbnailViewController *thumbnailVC = [[ThumbnailViewController alloc] 
											initWithNibName:@"ThumbnailViewController" bundle:nil];
	
	// 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
	[thumbnailVC setSelectedUserID:self.selectedUserID];
	
	// サムネイル画面の表示
	[self.navigationController pushViewController:thumbnailVC animated:YES];
	
	[thumbnailVC setSelectedUserName:self.selectedUserName
						   nameColor:[Common getNameColorWithSex:userView.isSexMen]];
	
	[thumbnailVC release];
	
	// 遷移画面を（選択）写真一覧にする
	_windowView = WIN_VIEW_SELECT_PICTURE;
}

// 日付を数値(yyyymmdd)に変更する
- (NSUInteger) convDate2Uint:(NSDate*)date
{
	if (! date)
	{	return NSUIntegerMax; }
	
	NSCalendar *cal 
		= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	// 年、月、日を求める
	unsigned int flag = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	
	NSDateComponents *comps = [cal components:flag fromDate:date];
	
	NSUInteger uintDate 
		= ([comps year] * 10000) + ([comps month] * 100) + [comps day];
	
	[cal release];
	
	return (uintDate);
}

// 履歴日付が当日かを判定する
- (BOOL) isWorkDateToday
{
	NSUInteger workDate 
		= [self convDate2Uint: self.selectedWorkItem.workItemDate];
	NSUInteger now
		= [self convDate2Uint: [NSDate date]];
	
	return (workDate == now);
}

// サムネイルの更新の確認
- (BOOL) isThimbnailRefresh
{
	if ( (! tumbnailItems) || (! self.selectedWorkItem) )
	{	return (YES); }
	
	return ( ([tumbnailItems count]) 
			!= ([self.selectedWorkItem.picturesUrls count]) );
}

// サムネイルの更新
- (void) refreshThumbnail
{
	// サムネイルの更新の確認
	// if ([self isThimbnailRefresh])
	{
		if (selectItemOrder)
		{
			[selectItemOrder release]; 
			selectItemOrder = nil; 
		}
		
		// サムネイルItemリストの作成（写真データの読み込み含む）
		[self tumbnailItemsMake];
		
		// サムネイルItemのレイアウト
		[self thumbnailItemsLayout];
	}
	
	// 再描画を行わない
	_isThumbnailRedraw = NO;
	
}

// baseパネル用ScrollViewのスクロール
- (void) basePanleScrollWithYpos:(CGFloat)yPos
{
	CGRect frame = scrollViewBasePanel.frame;
	
	frame.origin.x = 0.0f;
    frame.origin.y = yPos;
	
    // scrollViewを移動して表示する 
	[scrollViewBasePanel scrollRectToVisible:frame animated:NO];
	
}

// お客様情報更新
- (void) userInfoUpadte
{
	// ユーザマスタの取得
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	mstUser *user = [usrDbMng getMstUserByID:self.selectedUserID];	
	
	if (popoverCntlEditUser)
	{
		[popoverCntlEditUser release];
		popoverCntlEditUser = nil;
	}
	
	// ユーザ情報編集のViewControllerのインスタンス生成
	UserInfoEditViewController *vcEditUser 
	= [[UserInfoEditViewController alloc]initWithUserEditPopUpViewContoller:POPUP_EDIT_USR
														  popOverController:nil
																   callBack:self
																  user4Edit:user];
	vcEditUser.isEditableUserName = NO;
	
	// ポップアップViewの表示
	popoverCntlEditUser = 
	[[UIPopoverController alloc] initWithContentViewController:vcEditUser];
	vcEditUser.popoverController = popoverCntlEditUser;
	[popoverCntlEditUser presentPopoverFromRect:userView.view.bounds
										 inView:self.view
					   permittedArrowDirections:UIPopoverArrowDirectionUp
									   animated:YES];
	
	// [popoverCntlEditUser setPopoverContentSize:CGSizeMake(768.0f, 375.0f) animated:NO];
	
    //2012 6/25 伊藤 画面外をタップしてもポップアップが閉じないようにする処理
    NSMutableArray *viewCof = [[NSMutableArray alloc]init];
    [viewCof addObject:self.view];

    popoverCntlEditUser.passthroughViews = viewCof;
    [viewCof release];
    
	[vcEditUser release];
	
	[usrDbMng release];	
}

// フリーメモTextViewの入力開始
- (BOOL) freeMemoShouldBeginEditing:(UITextView *)textView
{
    isTvMemoFocus = YES;
    
    // フリーメモの位置調整
    [self _setFreeMemoLocationWithPortrait:
         scrollViewPictureConteiner.bounds.size.width == THUBNAIL_CONTEINER_WIDTH];
    
    // デバイスが横向きの場合のみ、メモまで、スクロールする
	if (scrollViewPictureConteiner.bounds.size.width != THUBNAIL_CONTEINER_WIDTH)
	{
		[self basePanleScrollWithYpos:textView.frame.origin.y- 6];   // 完了ボタンが切れるので、6pixelあげる
	}
	
	// メモ入力なしの場合は、ここで内容を削除する
	if ([tvMemo.text isEqualToString:NO_TOP_MEMO_STR])
	{
		tvMemo.text = nil;
	}
	
    btnFreeMemoKbHider.hidden = NO;
    
	return (YES);
}

// フリーメモTextViewの入力完了
- (BOOL) freeMemoShouldEndEditing:(UITextView *)textView
{
    // メモ入力なしの場合は、"(なし)"を設定
	if ((! tvMemo.text) ||
		((tvMemo) && ([tvMemo.text length] <= 0)) )
	{	tvMemo.text = NO_TOP_MEMO_STR;}	
	
	// 内容が編集されていれば更新と取消ボタンをenable
	if (! [[self.selectedWorkItem getTopMemo] isEqualToString:textView.text])
	{ [self setEnableWorkItemButton:YES]; }
	
	isTvMemoFocus = NO;
    
    btnFreeMemoKbHider.hidden = YES;
    
    // フリーメモの位置調整
    [self _setFreeMemoLocationWithPortrait:
        scrollViewPictureConteiner.bounds.size.width == THUBNAIL_CONTEINER_WIDTH];
    
    return (YES);
}

#define TEXT_VIEW_MEMO_MARGIN 3.0f

// フリーメモの位置調整
- (void) _setFreeMemoLocationWithPortrait:(BOOL)isPortraite
{
#ifndef CALULU_IPHONE
    return;     // iPhone版のみ対応
#endif

    CGRect freeMemoframe = tvWorkItem2.frame;
    
    // 縦向きの場合でフォーカスのある場合のみ定型メモ２の位置に合わせる（高さも応じて変更）
    CGFloat yPos = ( (isPortraite) && (isTvMemoFocus))?
        freeMemoframe.origin.y :
        freeMemoframe.origin.y + freeMemoframe.size.height + TEXT_VIEW_MEMO_MARGIN;
    CGFloat height = ( (isPortraite) && (isTvMemoFocus))?
        freeMemoframe.size.height * 2 + TEXT_VIEW_MEMO_MARGIN :
    freeMemoframe.size.height;
    
    CGRect tvMemoFrame = tvMemo.frame;
    // フリーメモの位置調整
    tvMemo.frame = CGRectMake(tvMemoFrame.origin.x, yPos,
                              tvMemoFrame.size.width, height);
    
    // 定型メモ２のラベルの表示制御 （ロック中除く）
    if (tlbSecurity.hidden)
    {   lblMemo2.hidden = ( (isPortraite) && (isTvMemoFocus)); }
    
    // フリーメモのラベルの位置調整
    CGRect lblMemoFrame = lblFreeMemo.frame;
    CGFloat yPos2 = tvMemo.frame.origin.y + (tvMemo.frame.size.height - lblMemoFrame.size.height) / 2.0f;
    if ( (!isPortraite) && (isTvMemoFocus)) { yPos2 += TEXT_VIEW_MEMO_MARGIN; }
    lblFreeMemo.frame = CGRectMake(lblMemoFrame.origin.x, yPos2, lblMemoFrame.size.width, lblMemoFrame.size.height);
    
    // 完了ボタンの位置調整
    if (isTvMemoFocus)
    {
        CGRect btnFrame = btnFreeMemoKbHider.frame;
        CGFloat yPos3 = (isPortraite)?
            lblFreeMemo.frame.origin.y - (btnFrame.size.height + TEXT_VIEW_MEMO_MARGIN) :
            tvMemo.frame.origin.y - TEXT_VIEW_MEMO_MARGIN;
        btnFreeMemoKbHider.frame = CGRectMake(btnFrame.origin.x, yPos3, btnFrame.size.width, btnFrame.size.height);
    }
    
    
}

/**
 * 言語設定の状況確認
 */
- (void)checkLanguage
{
	// ユーザ設定を取得
	isJapanese = NO;
	NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
	NSString *country = [df stringForKey:@"USER_COUNTRY"];
	// 2015/10/27 TMS iOS9対応
	if ([country isEqualToString:@"ja-JP"] || [country isEqualToString:@"ja"]) {
		isJapanese = YES;
	}
}

#pragma mark public_Methods

// Viewの更新
- (void) refreshViewWithWorkItem:(fcUserWorkItem *)workItem 
			   selectediViewCell:(HistListTableViewCell *)viewCell
						userName:(NSString*)userName
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
//    _windowView = WIN_VIEW_HIST_DETAIL;
	// 履歴IDに変化があるか？
	if (self.selectedHistID == workItem.histID)
	{	
		// 先に選択中の施術履歴を更新
		self.selectedWorkItem = workItem;
		
		// 代表写真の変更があったかもしれないので常に更新
		[self checkLanguage];
		[userView setUserInfo:self.selectedUserID Language:isJapanese];	
		
		// 履歴IDに変化がない場合は枚数の相違の確認によりサムネイルを更新する
		if ([self isThimbnailRefresh])
		{	[self refreshThumbnail]; }
		
		// 施術内容などのControlへの設定
		[self setWorkItem2Control];
		
		return;
	}
	
	// 各プロパティを設定
	self.selectedWorkItem	= workItem;	
	self.selectedHistID		= workItem.histID;
	self.selectedViewCell	= viewCell;
	
	// ユーザ情報Viewを更新（代表写真または名前に変更の可能性があるので常に更新）
	// if (self.selectedUserID	!= workItem.userID)
	{
		self.selectedUserID		= workItem.userID;
		self.selectedUserName	= userName;
		[userView setUserInfo:self.selectedUserID Language:isJapanese];
	}
	
	// サムネイルの更新
	[self refreshThumbnail];
	
	// 施術内容マスタテーブルの初期化
	[self initWorkItemMasterTable:nil];
	
	//START, 2011.06.19, chen, ADD
	//self.selectedWorkItem2 = workItem;
	[self initWorkItemMasterTable2:nil];
	//END
	
	// 当日のみカメラ画面ボタンを表示
	btnCamera.hidden = ! [self isWorkDateToday];
	// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
	// 当日のみボディチェックシート画面ボタンを表示
	btnBodyCheckBtn.hidden = ! [self isWorkDateToday];
#endif
}

// 履歴なし時のViewの更新
- (void) refreshViewWithNoWorkItem:(USERID_INT)userID userName:(NSString*)userName
{
	// 各プロパティを初期設定
	self.selectedWorkItem	= nil;	
	self.selectedHistID		= HISTID_INTMIN;
	self.selectedViewCell	= nil;
	
	// ユーザ情報Viewを更新
	if (self.selectedUserID	!= userID)
	{
		self.selectedUserID		= userID;
		self.selectedUserName	= userName;
	}
	[userView setUserInfo:self.selectedUserID Language:isJapanese];		// 代表写真の変更があったかもしれないので常に更新
	
	// 施術内容などのControlへの設定
	[self setWorkItem2Control];
	
	// サムネイルの更新
	[self refreshThumbnail];
	
	// 施術内容マスタテーブルの初期化
	[self initWorkItemMasterTable:nil];
	
	//START, 2011.06.19, chen, ADD
	self.selectedWorkItem2  = nil;
	//END
	
	// カメラ画面ボタンを非表示
	btnCamera.hidden = NO;
}

//START, 2011.06.18, chen, ADD
//load default memo1/memo2 label
- (void)loadSettings: (id) sender
{	
	// メモのラベルを設定ファイルから読み込む
	NSDictionary *lables = [Common getMemoLabelsFromDefault];
	
	lblMemo1.text = [lables objectForKey:@"memo1Label"];
	lblMemo2.text = [lables objectForKey:@"memo2Label"];
	lblFreeMemo.text = [lables objectForKey:@"memoFreeLabel"];
	
//	[btnMemo1 setTitle:[NSString stringWithFormat: @"%@の設定", lblMemo1.text]
//			  forState:UIControlStateNormal];
//	[btnMemo2 setTitle:[NSString stringWithFormat: @"%@の設定", lblMemo2.text]
//			  forState:UIControlStateNormal];
	[btnMemo1 setTitle:[NSString stringWithFormat: @"設定"]
			  forState:UIControlStateNormal];
	[btnMemo2 setTitle:[NSString stringWithFormat: @"設定"]
			  forState:UIControlStateNormal];
}

//refresh memo setting
- (void) reloadMemoSetting:(NSNotification *) notification
{
	[Common reloadMemo];
	[self loadSettings:nil];
	
	MainViewController *mainVC
	= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	HistListViewController *histListVC
	= (HistListViewController*)[mainVC getPrevControlWithSelf:self];
	// 施術内容と表示されているセルの更新
	[histListVC->tvHistList reloadData];
}

//open dialog when click on menu workitem master edit button
-(IBAction) OnWorkItemMasterSelect:(id)sender
{
	/*
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@""
														delegate:self 
											   cancelButtonTitle:@"Cancel"
										  destructiveButtonTitle:nil 
											   otherButtonTitles:lblMemo1.text, lblMemo2.text, nil];
	[action showInView:self.view];
	[action release];
    */
}

//dialog show select master item memo1/memo2 
-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0) 
	{
		_currentMemo = 1;
		[self OnWorkItemMasterEdit:nil];
	}
	else if(buttonIndex == 1)
	{
		_currentMemo = 2;
		[self OnWorkItemMasterEdit2:nil];
	}
	
}
//END

// サムネイルと選択セルの更新
- (void) thumbnailSelectedCellRefresh
{

	// データベースから最新の履歴用のユーザ写真リストを取得する
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	[usrDbMng getHistPictureUrls: self.selectedWorkItem];
    [usrDbMng getHistVideoUrls:self.selectedWorkItem];
	[usrDbMng release];

	// サムネイルリストと取得したユーザ写真リスト（の長さ）が異なれば、再描画する
	if ([tumbnailItems count] != (self.selectedWorkItem.picturesUrls.count + self.selectedWorkItem.videosUrls.count))
	{
		// サムネイルItemリストの作成（写真データの読み込み含む）
		[self tumbnailItemsMake];
		
		// サムネイルItemのレイアウト
		[self thumbnailItemsLayout];
	}
	
	// 遷移元画面のTableViewCellの更新
//	if(self.selectedViewCell)
//	{
//		[self.selectedViewCell.picture setImage:
//		 [self makeImagePicture: self.selectedWorkItem.headPictureUrl
//					   pictSize:self.selectedViewCell.picture.bounds.size]];
//	}	
}

// ユーザ情報Viewの更新
- (void) refreshUserInfoView
{
	[userView setUserInfo:self.selectedUserID Language:isJapanese];
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

#pragma mark iOS_Frmaework

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
		// メンバの初期化
		tumbnailItems = nil;
		_scrollView = nil;
		_drawView = nil;
		
		_workItemIDs = nil;
		
		_isThumbnailRedraw = YES;
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
    [super viewDidLoad];
	
	//set notification memo
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadMemoSetting:)
												 name:@"reloadMemo"
											   object:nil];
	
    // 背景色の変更 RGB:D8BFD8
//    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];
	self.view.backgroundColor = [UIColor colorWithRed:204/255.0f green:149/255.0f blue:187/255.0f alpha:1.0f];
	
	// ユーザ情報Viewを表示
	userView = 
		[[UserInfoDispViewSupport alloc] initWithUserID:self.selectedWorkItem.userID ownerView:self];
	// 背景色：ADD8E6
	userView.view.backgroundColor = [UIColor colorWithRed:249/255.0f green:245/255.0f blue:247/255.0f alpha:1.0f];
	userView.delegate = self;
	
	[self.view addSubview:userView.view];
	// [userView release];
	
	selectItemOrder = nil;
	
	// 施術内容などのControlへの設定
	[self setWorkItem2Control];
	
	// サムネイルItemリストの作成（写真データの読み込み含む）
	[self tumbnailItemsMake];
	
	// サムネイルItemのレイアウト
	[self thumbnailItemsLayout];
	
	// スクロールビューのピンチ（ズーム）機能の設定
	[self setupScrollViewZoom];

	// 再描画を行わない
	_isThumbnailRedraw = NO;
	
	// 施術内容マスタテーブルの初期化
	[self initWorkItemMasterTable:nil];
	
	// 施術内容マスタテーブルの初期化
	[self initWorkItemMasterTable2:nil];
	
	// 項目編集リストの初期化
	[self initItemEdits];
	
	// Alertダイアログの初期化
	[self initAlertDialog];
	
	// フリックボタンの初期化
	[btnFlicker initialize:self];
	
	// 当日のみカメラ画面ボタンを表示（ただし、履歴なし時を除く）
	btnCamera.hidden 
		= ( (! [self isWorkDateToday]) && (self.selectedHistID == HISTID_INTMIN) );
		// = !([_selectedWorkItem.newWorkDate isEqualToDate:[NSDate date]]);
	
	// basePanelの背景色設定
	vwBasePanel.backgroundColor = [Common getScrollViewBackColor];
	
	isTvMemoFocus = NO;
	
	//START, 2011.06.18, chen, ADD
	[self loadSettings:nil];
	//END
    
    // 写真アルバムからの取り込みのインスタンス生成
#ifndef CALULU_IPHONE
    _takePictureAlbum = [[takePicture4PhotoLibrary alloc] initWithPreView:vwPictureAlbumPrev 
                                                               popupButton:btnPictureAlbum];
#else
    MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    _takePictureAlbum = [[takePicture4PhotoLibrary alloc] initWithPreView:vwPictureAlbumPrev 
                                                              popupButton:btnPictureAlbum
                                                     parentViewController:mainVC];
#endif
	_windowView = WIN_VIEW_HIST_DETAIL;
	
	//round textview
	tvWorkItem.layer.cornerRadius = 20;
	tvWorkItem.clipsToBounds = true;
	tvWorkItem2.layer.cornerRadius = 20;
	tvWorkItem2.clipsToBounds = true;
	tvMemo.layer.cornerRadius = 20;
	tvMemo.clipsToBounds = true;
}

// 画面が表示される都度callされる:viewWillAppear
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear : animated];
	
	memWarning = NO;
	
    //2012 6/22 連続ページめくりを防ぐ処理 mainVCのスクロールビューの幅設定
    MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC setScrollViewWidth:YES];
    
	// 再描画を行わない
	if (! _isThumbnailRedraw)
	{	return; }
	
	// サムネイルと選択セルの更新
	[self thumbnailSelectedCellRefresh];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	// 言語環境設定チェック
	[self checkLanguage];
	
    if ((_windowView == WIN_VIEW_SELECT_VIDEO) ||
        (_windowView ==  WIN_VIEW_HIST_LIST)||
        (_windowView ==  WIN_VIEW_HIST_DETAIL) ||
        (_windowView == WIN_VIEW_SELECT_PICTURE)) {
        [self thumbnailSelectedCellRefresh];
    }
    if ((_windowView == WIN_VIEW_SELECT_PICTURE) ||
        (_windowView == WIN_VIEW_SELECT_VIDEO)) {
        //[self refreshThumbnail];
        
        // Timerにより別スレッドでImageを描画する
        [NSTimer scheduledTimerWithTimeInterval:0.1f
                                         target:self
                                       selector:@selector(OnImageWrite:)
                                       userInfo:nil 
                                        repeats:NO];
        
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC deleteViewControllersFromNextIndex];
    }
	if ((_windowView ==  WIN_VIEW_HIST_LIST)||
        (_windowView ==  WIN_VIEW_HIST_DETAIL)) {
		// メール表示を一旦なくす
		MainViewController *mainVC
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		UIViewController *vc
		= [ mainVC getVC4ViewControllersWithClass:[HistListViewController class]];
		if (vc) {
			[(HistListViewController*)vc mailViewShowWithFlag:NO];
			[(HistListViewController*)vc qrcodeViewShowWithFlag:NO];
		}
	}
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    // return YES;
	
	// とりあえず回転不可にする
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// 縦横切り替え後のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	BOOL isPortrait;
	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			// 縦向け
			isPortrait = YES;
			break;
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			isPortrait = NO;
			break;
		default:
			isPortrait = NO;	// 念のため
			break;
	}
	
	CGFloat width  = (isPortrait)? HIST_DTL_BASE_PANEL_WIDTH_PRT : HIST_DTL_BASE_PANEL_WIDTH_ORT;
	CGFloat height = HIST_DTL_BASE_PANEL_HEIGHT;
	
	vwBasePanel.frame = CGRectMake(0.0f, 0.0f, width, height);
	[scrollViewBasePanel setContentSize:CGSizeMake(width, height)];
	
	// サムネイルItemのレイアウト
	[self thumbnailItemsLayout];
    
    // フリーメモの位置調整 (iPhoneのみ)
    [self _setFreeMemoLocationWithPortrait:UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
	
	// 横向きが対象
	if (!isPortrait)
	{	
		CGFloat yPos = -1.0f;
		if (isTvMemoFocus)
		{
			// メモ入力中はメモ位置まで、スクロールする
			yPos = tvMemo.frame.origin.y - 6;   // 完了ボタンが切れるので、6pixelあげる
		} 
		else if ([self selectThubnailItemNums] > 0)
		{
			// 写真の選択がある場合は、 baseパネル用ScrollViewを一番下までスクロールする
			yPos = height - scrollViewBasePanel.frame.size.height;
		}
		
		if (yPos > 0)
		{	[self basePanleScrollWithYpos:yPos]; }
	}
    
    // 写真情報編集ボタンはPortraitのみ有効（iPhone）
#ifdef CALULU_IPHONE
    btnEditImageProfile.enabled = isPortrait;
#endif
}	

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
	if (!memWarning) {
		MainViewController *mainVC
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		if ([[mainVC getNowCurrentViewController] isKindOfClass:[HistDetailViewController class]]) {
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
}

// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive {
	memWarning = NO;
}

- (void)viewDidUnload {
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	// 遷移画面を本画面種別（履歴詳細画面）にする
	_windowView = WIN_VIEW_HIST_DETAIL;
}

- (void)dealloc {
	
	if (popoverCntlWorkItemSet)
		[popoverCntlWorkItemSet release];
	if (popoverCntlEditUser)
		[popoverCntlEditUser release];
    if (popoverCntlEditUser)
        [popoverCntlEditUser release];
	[deleteNoAlert release];
	[deleteCheckAlert release];
	[modifyCheckAlert release];
	[headPictrueCheckAlert release];
	
	[_workItemMasterTable release];
    for (id d in selectItemOrder) {
        [d release];
    }
	[selectItemOrder release];
    selectItemOrder = nil;
    for (id d in tumbnailItems) {
        [d release];
    }
	[tumbnailItems release];
	tumbnailItems = nil;
	[_workItemIDs release];
	
	//START, 2011.06.18, chen, ADD
	[_workItemMasterTable2 release];
	[_workItemIDs2 release];
	[lblMemo1 release];
	[lblMemo2 release];
	[btnMemo1 release];
	[btnMemo2 release];
	//END
	
	[userView release];
	
	// [userView release]; -> self.viewにてretainのため不要
	
	for (NSMutableArray *items in _itemEdits)
	{
		[items removeAllObjects];
		[items release];
		items = nil;
	}
	[_itemEdits release];
	_itemEdits = nil;
    
	[_takePictureAlbum release];
		
	[super dealloc];
}

#pragma mark MainViewControllerDelegate
- (void) transitionView:(SelectPictureViewController*)selectPictVC
{
	// 画像Imageのリスト（UIImage*のリスト ）を設定
	// NSMutableArray *images = [ [NSMutableArray alloc] init]; // DELC SASAGE
	
	// Imageファイル管理のインスタンスを生成
	OKDImageFileManager *imgFileMng
		= [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
#ifdef CLOUD_SYNC
    // MainVCのインスタンスの取得
    MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    // 画像がダウンロードできるまで画面のスワイプを禁止
    [mainVC viewScrollLock:YES];
#endif
    
    // Indicatorの表示
    [MainViewController showIndicator];
	[selectPictVC setPictImageItems:[self getOrderdTumbnailItems]];
    // Indicatorを閉じる
    [MainViewController closeIndicator];
    
#ifdef CLOUD_SYNC
    // 画像がダウンロードが完了したので画面のスワイプを許可
    [mainVC viewScrollLock:NO];
#endif
	[imgFileMng release];

	// 履歴詳細画面からのコールでは、NavigationControlでは遷移しない
	selectPictVC.isNavigationCall = NO;
    
	// 選択画像一覧へ遷移する場合は、再描画を行わない
	_isThumbnailRedraw = NO;
	
	// 遷移画面を（選択）写真一覧にする
	_windowView = WIN_VIEW_SELECT_PICTURE;
	[selectPictVC viewWillAppear:NO];
	
}
- (void) transitionVideoView:(SelectVideoViewController*)selectMovieVC
{
    // Indicatorの表示
    // [MainViewController showIndicator];
    [selectMovieVC setMovieItems:[self getOrderdMovies]];
    // Indicatorを閉じる
    // [MainViewController closeIndicator];
	// 履歴詳細画面からのコールでは、NavigationControlでは遷移しない
	selectMovieVC.isNavigationCall = NO;
    
	// 選択画像一覧へ遷移する場合は、再描画を行わない
	_isThumbnailRedraw = NO;
	
	// 遷移画面を動画一覧にする
	_windowView = WIN_VIEW_SELECT_VIDEO;
	[selectMovieVC viewWillAppear:NO];
}
// 新規View画面への遷移
//		return: 次に表示する画面のViewController  nilで遷移をキャンセル
- (UIViewController*) OnTransitionNewView:(id)sender
{
	//NSLog(@"OnTransitionNewView at HistDetailViewController");
	
	if ([btnUpdateWorkItem isEnabled])
	{
		// 施術内容（メモ含む）が編集されていれば、alertを表示して画面遷移しない
		[modifyCheckAlert show];
		
		// 選択なし
		return (nil);
	}
	
	if ([self selectThubnailItemNums] <= 0) 
	{
		// 選択なし
		//show message alert when no image selected(for the case of save image in paint mode)
		UIAlertView *alert =[ [UIAlertView alloc]initWithTitle:@""
													   message:@"画像が選択されていません"
													  delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
		[alert show];
		[alert release];
		
		return (nil);
	}
	if ([self videoIsSelected]) {
        SelectVideoViewController *selectVideoVC = [[[SelectVideoViewController alloc]
                                                    initWithNibName:@"SelectVideoViewController" bundle:nil] autorelease];
        return selectVideoVC;
    }else {
		if (![self checkEnableTransition]) {
			return nil;
		}
        SelectPictureViewController *selectPictVC
		= [[[SelectPictureViewController alloc]
#ifdef CALULU_IPHONE
		   initWithNibName:@"ip_SelectPictureViewController" bundle:nil] autorelease];
#else
    initWithNibName:@"SelectPictureViewController" bundle:nil] autorelease];
#endif
        
        // [self transitionView:selectPictVC];
        
        return (selectPictVC);
    }
}

// 新規View画面への遷移でViewがLoadされた後にコールされる
- (void) OnTransitionNewViewDidLoad:(id)sender transitionVC:(UIViewController*)tVC
{
    if ([tVC isKindOfClass:[SelectVideoViewController class]]) {
        SelectVideoViewController *selectVideoVC = (SelectVideoViewController*)tVC;
        
        // 選択ユーザと施術日の設定
        [selectVideoVC setSelectedUserName:self.selectedUserName isSexMen:userView.isSexMen];
        [selectVideoVC setWorkDateWithString:lblWorkDate.text];
        
        // 施術情報の設定（画像合成ビューで必要）
        [selectVideoVC setWorkItemInfo:self.selectedUserID
                       workItemHistID:self.selectedHistID
                             workDate:self.selectedWorkItem.workItemDate];
        
        // 遅延して選択動画を表示する
        [self performSelector:@selector(transitionVideoView:)
                   withObject:selectVideoVC afterDelay:0.05f];		// 0.05秒後に起動

    } else if([tVC isKindOfClass:[SelectPictureViewController class]]){
        SelectPictureViewController *selectPictVC = (SelectPictureViewController*)tVC;
        
        // 選択ユーザと施術日の設定
        [selectPictVC setSelectedUserName:self.selectedUserName isSexMen:userView.isSexMen];
        [selectPictVC setWorkDateWithString:lblWorkDate.text];
        
        // 施術情報の設定（画像合成ビューで必要）
        [selectPictVC setWorkItemInfo:self.selectedUserID
                       workItemHistID:self.selectedHistID
                             workDate:self.selectedWorkItem.workItemDate];
        
        // 遅延して選択画像を表示する
        [self performSelector:@selector(transitionView:)
                   withObject:selectPictVC afterDelay:0.05f];		// 0.05秒後に起動
	}
	// メモのキーボードを隠す
	[tvMemo resignFirstResponder];
}

// 既存View画面への遷移
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC
{
    // 履歴詳細画面に戻るたびに写真・動画選択画面を消しているはずなので、viewdidappearが呼ばれている限りはここに来ない。
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
//    MainViewController *mainVC
//    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
//    [mainVC deleteViewControllersFromNextIndex];
//    [self OnTransitionNewView:sender];
//    return NO;
	// NSLog(@"OnTransitionExsitView at HistDetailViewController");
	
    // 選択されているかを確認する
    BOOL isSelected = ([self selectThubnailItemNums] > 0);
    
    if ([btnUpdateWorkItem isEnabled])
    {
        // 施術内容（メモ含む）が編集されていれば、alertを表示して画面遷移しない
        [modifyCheckAlert show];
        
        // 選択なし
        return (NO);
    }
    if ([tVC isKindOfClass:[SelectVideoViewController class]]) {
        SelectVideoViewController *selectVideoVC = (SelectVideoViewController*)tVC;
        // 選択ユーザと施術日の設定
        [selectVideoVC setSelectedUserName:self.selectedUserName isSexMen:userView.isSexMen];
        [selectVideoVC setWorkDateWithString:lblWorkDate.text];
        
        // 施術情報の設定（画像合成ビューで必要）
        [selectVideoVC setWorkItemInfo:self.selectedUserID
                        workItemHistID:self.selectedHistID
                              workDate:self.selectedWorkItem.workItemDate];
        if (isSelected)
        {
            // 遅延して選択画像を表示する
            [self performSelector:@selector(transitionVideoView:)
                       withObject:selectVideoVC afterDelay:0.05f];		// 0.05秒後に起動
            // メモのキーボードを隠す
            [tvMemo resignFirstResponder];
        }
        
        // 選択により表示する
        if ( (tVC) && [tVC isKindOfClass:[SelectPictureViewController class] ])
        {   tVC.view.hidden = ! isSelected; }
        
    } else {
        SelectPictureViewController *selectPictVC = (SelectPictureViewController*)tVC;
        
        // 選択ユーザと施術日の設定
        [selectPictVC setSelectedUserName:self.selectedUserName isSexMen:userView.isSexMen];
        [selectPictVC setWorkDateWithString:lblWorkDate.text];
        
        // 施術情報の設定（画像合成ビューで必要）
        [selectPictVC setWorkItemInfo:self.selectedUserID
                       workItemHistID:self.selectedHistID
                             workDate:self.selectedWorkItem.workItemDate];
        if (isSelected)
        {
            // 遅延して選択画像を表示する
            [self performSelector:@selector(transitionView:)
                       withObject:selectPictVC afterDelay:0.05f];		// 0.05秒後に起動
            // メモのキーボードを隠す
            [tvMemo resignFirstResponder];
        }
        
        // 選択により表示する
        if ( (tVC) && [tVC isKindOfClass:[SelectPictureViewController class] ])
        {   tVC.view.hidden = ! isSelected; }
    }
    
    // 選択なしの場合は、画面遷移しない
    return (isSelected);
}

// 画面終了の通知
- (BOOL) OnUnloadView:(id)sender
{
	BOOL stat = YES;
	if ([btnUpdateWorkItem isEnabled])
	{
		// 施術内容（メモ含む）が編集されていれば、alertを表示して画面遷移しない
		[modifyCheckAlert show];
		
		stat = NO;
	}
	
	if (stat)
	{	
		// メモのキーボードを隠す
		[tvMemo resignFirstResponder];
	}
	
	return (stat);
}

// 画面ロックモード変更
- (void) OnWindowLockModeChange:(BOOL)isLock
{
	// 画面ロックにより、セキュリティ用ツールバーを表示
	tlbSecurity.hidden = ! isLock;
	
	// 写真ラベルの位置を変更
    CGRect setFrame = lblPicture.frame;
#ifdef CALULU_IPHONE
    setFrame.origin.y = (isLock)? 205.0f : 312.0f;
#else
    setFrame.origin.y = (isLock)? 334.0f : 577.0f;      // 619 -> 577
#endif
	lblPicture.frame = setFrame;
	
    // 写真ボタンの表示:当日で画面ロックでない場合にカメラ画面ボタンを表示
	btnCamera.hidden = ! ( [self isWorkDateToday] && ! isLock) ;
    
    // 写真アルバム取り込みボタン
    btnPictureAlbum.hidden = isLock;
	
	// 施術内容１、２とフリーメモとそのラベル:画面ロックにより非表示
    tvWorkItem.hidden = tvWorkItem2.hidden = tvMemo.hidden = isLock;
	lblMemo1.hidden = lblMemo2.hidden = lblFreeMemo.hidden = isLock;
    
    // 選択画像を解除ボタン:画面ロックにより非表示
    btnSelectedImgRelease.hidden = isLock;

#ifdef CALULU_IPHONE
    // メモ入力完了ボタンも画面ロックにより非表示
    if (isLock)
    {   btnFreeMemoKbHider.hidden = YES; }
#endif	
    
	// サムネイルのスクロールView関連
    setFrame = scrollViewPictureConteiner.frame;
#ifdef CALULU_IPHONE
	setFrame.origin.y = (isLock)? 20.0f : 230.0f;
	setFrame.size.height = (isLock)? 390.0f : 180.0f;
#else
	setFrame.origin.y = (isLock)? 85.0f : 474.0f;
	setFrame.size.height = (isLock)? 616.0f : 227.0f;
#endif
	scrollViewPictureConteiner.frame = setFrame;
	viewPictureConteiner.frame = CGRectMake(0.0f, 0.0f, setFrame.size.width, setFrame.size.height);
    
    // 画面ロック時はスクロール上限でも無効にする
    // scrollViewPictureConteiner.bounces = ! isLock; -> スクロールの動作が鈍くなる
	
	// サムネイルItemのレイアウト
	[self thumbnailItemsLayout];
}

#pragma mark ToolbarItem

// 更新
- (IBAction) OnUpdateData:(id)sender
{
	// 更新と取消ボタンをdisable
	[self setEnableWorkItemButton:NO];
		
	// 施術内容(IDリストと内容文字列)をメンバ変数に設定
	self.selectedWorkItem.workItemListString = [[NSMutableString alloc] initWithString:tvWorkItem.text];
	
	// 施術内容2(IDリストと内容文字列)をメンバ変数に設定
	self.selectedWorkItem.workItemListString2 = [[NSMutableString alloc] initWithString:tvWorkItem2.text];
	
	// メモをメンバ変数に設定：メモリスト先頭に設定する
	[self.selectedWorkItem.userMemos removeAllObjects];
	if ([tvMemo.text length] > 0)
		[self.selectedWorkItem.userMemos addObject:tvMemo.text];
	else 
		tvMemo.text = [self.selectedWorkItem getTopMemo];
	
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	
	// 施術内容のデータベース更新
	/*[usrDbMng updateUserWorkItemList:
				  self.selectedWorkItem.histID  
				  workItemListNumber:_workItemIDs];
	[usrDbMng updateUserWorkItemList2:
	 self.selectedWorkItem.histID  
				  workItemListNumber:_workItemIDs2];*/
	static ITEM_EDIT_KIND kinds[] = {ITEM_EDIT_USER_WORK1, ITEM_EDIT_USER_WORK2};
	[usrDbMng updateUserItemEditWithString:self.selectedWorkItem.histID
								 itemKinds:kinds 
								 itemEdits:_itemEdits];
	
	// メモのデータベース更新
	[usrDbMng updateUserWorkMemoList:
					self.selectedWorkItem.histID  
					userMemos:self.selectedWorkItem.userMemos];
	
	
	[usrDbMng release];
	
	//最新施術の日付と同様であれば施術内容を更新
	if ( (userView.lastWorkDate) && 
		 ([userView.lastWorkDate isEqualToDate:
				self.selectedWorkItem.workItemDate]) )
	{ 
		userView.lblLastWorkContent.text = 
			[NSString stringWithString: tvWorkItem.text];
	}
	
}

// 取り消し
- (IBAction) OnChancel:(id)sender
{
	// 施術内容を元に戻す
	[self setWorkItem2Control];
	
	// 更新と取消ボタンをdisable
	[self setEnableWorkItemButton:NO];

	
}

// 履歴一覧に戻る
- (IBAction) OnHistListView:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

// カメラ画面へ
- (IBAction) OnCameraView:(id)sender
{
	// MainViewControllerの取得
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// camaraViewControllerの取得
	camaraViewController *cameraView
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView;
	
	if (!cameraView)
	{
		cameraView = [[camaraViewController alloc] 
#ifdef CALULU_IPHONE
					  initWithNibName:@"ip_camaraViewController" bundle:nil];
#else
     				  initWithNibName:@"camaraViewController" bundle:nil];
#endif
		((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView
			= cameraView;
	}
		
	// 取得した履歴IDと施術日を渡す
	cameraView.histID = self.selectedHistID;
    // NSLog (@"selectedWorkItem work date %@", self.selectedWorkItem.workItemDate);
	cameraView.workDate = self.selectedWorkItem.workItemDate;
	
	// カメラ画面の表示
	[mainVC showPopupWindow:cameraView];
		//cameraView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		//[self presentModalViewController:cameraView animated:YES];
	
    // iOS7で時間を置かずに setSelectedUser を呼ぶと、ViewDidLoadが終了していないため
    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
	// 現在選択中のユーザIDを渡す
	[cameraView setSelectedUser:self.selectedWorkItem.userID 
					   userName:self.selectedUserName
					  nameColor:[Common getNameColorWithSex:userView.isSexMen]];
	
	// 現在のデバイスの向きを取得
	UIInterfaceOrientation orient = [mainVC getNowDeviceOrientation];
	// デバイスの向きを設定する
	[cameraView willRotateToInterfaceOrientation:orient duration:(NSTimeInterval)0];
    });
	
	// カメラ画面へ遷移する場合は、再描画を行う
	_isThumbnailRedraw = YES;
	
	[cameraView release];
}

// 2016/2/18 TMS グラント対応
// ボディチェックシート画面へ
#ifdef FOR_GRANT
- (IBAction) OnBodyCheckSheetView:(id)sender
{
	// MainViewControllerの取得
	MainViewController *mainVC
	= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// camaraViewControllerの取得
	BodyCheckViewController *bodyCheckView
	= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).bodyCheckView;
	
	if (!bodyCheckView)
	{
		bodyCheckView = [[BodyCheckViewController alloc]initWithNibName:@"BodyCheckView" bundle:nil];

		((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).bodyCheckView
		= bodyCheckView;
	}

	// ボディチェックシート画面の表示
	bodyCheckView.selectedUserName = self.selectedUserName;
	[mainVC showPopupWindow:bodyCheckView];
	
	
	[bodyCheckView release];
	
	// iOS7で時間を置かずに setSelectedUser を呼ぶと、ViewDidLoadが終了していないため
	double delayInSeconds = 0.05;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		//選択中のユーザーIDをセット
		[bodyCheckView setUser:self.selectedUserID];
	});

	_isThumbnailRedraw = YES;
}
#endif
// 写真アルバム取り込み
- (IBAction)OnPhotoAlbum:(id)sender
{
    // アプリケーション使用容量設定値の自動設定を行う
    APCValueEnable valEnable = [appCapacityManager setAutoAppUsingCapacity];
    if (valEnable.freeDevSpace < 100.0f) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ご注意"
														message:@"空き容量が100MB未満になった為、\n画像・動画の撮影を中止します\niPad内の不要なコンテンツ等を\n削除し容量を確保して下さい"
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		
		return;
	} else if (valEnable.freeDevSpace < 500.0f) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ご注意"
														message:@"空き容量が500MB未満になりました\n不要なコンテンツ等を削除し、\n容量を確保して下さい\n空き容量が100MB未満になると、\nデータ保護の為に画像・動画の撮影が\n出来なくなります"
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];

//        // 空き容量がないので、この画面を閉じて前画面に戻る
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^{
//            [Common showDialogWithTitle:@"ご注意"
//                                message:@"お使いのiPadには\n空き容量がありません\n\n不要なコンテンツなどを\n削除して空き容量を\n確保してください"];
//        });
//        
//        return;
    }
    
    // ユーザIDと履歴IDを渡す
    _takePictureAlbum.userID = self.selectedUserID;
    _takePictureAlbum.histID = self.selectedHistID;
    
    [_takePictureAlbum takePicureWithCompliteHandler:^(UIImage *image) {
        
        // 写真の取り込み成功 : サムネイルと選択セルの更新
        [self thumbnailSelectedCellRefresh];
    }];
}

// 選択画像の表示
- (IBAction) OnSelectPictureView:(id)sender
{
	if ([self selectThubnailItemNums] <= 0)
	{
		// 選択なし
		deleteNoAlert.title = @"選択画像の表示";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		return;
	}
    if ([self videoIsSelected]) {
        // 動画が選択されている場合
        SelectVideoViewController *selectVideoVC
		= [[SelectVideoViewController alloc]
           initWithNibName:@"SelectVideoViewController" bundle:nil];
        
        // 動画のリストを設定
        [selectVideoVC setMovieItems:[self getOrderdMovies]];
        selectVideoVC.isNavigationCall = YES;
		
        // 選択画像の表示
        [self.navigationController pushViewController:selectVideoVC animated:YES];
        
        // 選択ユーザと施術日の設定
        [selectVideoVC setSelectedUserName:self.selectedUserName isSexMen:userView.isSexMen];
        [selectVideoVC setWorkDateWithString:lblWorkDate.text];
        
        [selectVideoVC release];
        
        // 選択画像一覧へ遷移する場合は、再描画を行わない
        _isThumbnailRedraw = NO;
    } else {
        // 画像が選択されている場合
        SelectPictureViewController *selectPictVC
		= [[SelectPictureViewController alloc]
           initWithNibName:@"SelectPictureViewController" bundle:nil];
        
        // 画像Imageのリスト（UIImage*のリスト ）を設定
        // DELC SASAGE //NSMutableArray *images = [ [NSMutableArray alloc] init];
        
        // Imageファイル管理のインスタンスを生成
        OKDImageFileManager *imgFileMng
		= [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
        
        [selectPictVC setPictImageItems:[self getOrderdTumbnailItems]]; //DELC SASAGE
        
        [imgFileMng release];
        
        // [images release]; // DELC SASAGE
        
        selectPictVC.isNavigationCall = YES;
		
        // 選択画像の表示
        [self.navigationController pushViewController:selectPictVC animated:YES];
        
        // 選択ユーザと施術日の設定
        [selectPictVC setSelectedUserName:self.selectedUserName isSexMen:userView.isSexMen];
        [selectPictVC setWorkDateWithString:lblWorkDate.text];
        
        [selectPictVC release];
        
        // 選択画像一覧へ遷移する場合は、再描画を行わない
        _isThumbnailRedraw = NO;
    }

}
- (NSMutableArray *)getOrderdTumbnailItems{
    NSMutableArray *orderdTumbnailItems = [NSMutableArray array];
	for ( id item in selectItemOrder)
	{
		NSUInteger idx = (NSUInteger)[((NSString*)item) intValue];
		for (id iv in tumbnailItems)
		{
			if ( ((OKDThumbnailItemView*)iv).tag == idx)
			{
                [orderdTumbnailItems addObject:iv];
			}
		}
	}
    return orderdTumbnailItems;
}
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
                
				tmb = nil;
			}
		}
	}
    return orderdMovies;
}
// お客様一覧の表示
- (IBAction) OnUserListView:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark InnerDispButton

// 施術日の設定
- (IBAction) OnSetWorkDate:(id)sender
{
	
}

// 項目編集ポップアップの表示
- (void) dispItemEditerPopupWithEditKind:(ITEM_EDIT_KIND)editKind
{
	// メモ入力のためキーボードが表示されている場合は、ここで閉じる
	[tvMemo resignFirstResponder];
    
    btnFreeMemoKbHider.hidden = YES;
	
	if (popoverCntlWorkItemSet)
	{
		[popoverCntlWorkItemSet release];
		popoverCntlWorkItemSet = nil;
	}
	
	UITextView *tv = (editKind == ITEM_EDIT_USER_WORK1)?
						tvWorkItem : tvWorkItem2;
	
	//施術内容の設定ポップアップViewControllerのインスタンス生成
	itemEditerPopup *vcItemEditer
		= [[itemEditerPopup alloc] initWithHistID:self.selectedHistID
									 itemEditKind:editKind
								   itemListString:tv.text
								  popOverController:nil
										   callBack:self];
#ifndef CALULU_IPHONE
	// ポップアップViewの表示
	popoverCntlWorkItemSet = [[UIPopoverController alloc] 
							  initWithContentViewController:vcItemEditer];
	vcItemEditer.popoverController = popoverCntlWorkItemSet;
	popoverCntlWorkItemSet.delegate = self;	// ポップアップクローズ処理を行うため
	[popoverCntlWorkItemSet presentPopoverFromRect:tv.bounds 
											inView:tv 
						  permittedArrowDirections:UIPopoverArrowDirectionAny
										  animated:YES];
	
	[popoverCntlWorkItemSet setPopoverContentSize:CGSizeMake(560.0f, 280.0f)];
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:vcItemEditer];
#endif
	// ポップアップタイトルの設定
	NSString *memeTitle 
		= (editKind == ITEM_EDIT_USER_WORK1)? lblMemo1.text : lblMemo2.text;
	[vcItemEditer setPopupTitleWithUserName:self.selectedUserName
								  memoTitle:memeTitle];
	
	[vcItemEditer release];

	// ポップアップを開いた時は回転禁止にする
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    app.navigationController.enableRotate = NO;
}

// 施術内容の設定
- (IBAction) OnSetworkItem:(id)sender
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	CGFloat offset = (iOSVersion<7.0)? 0.0f : 20.0f;

	if (scrollViewBasePanel.contentOffset.y > (20.0 + offset)) {
		[scrollViewBasePanel setContentOffset:CGPointMake(0, 20 + offset) animated:YES];
		// スクロールのアニメーション終了後にポップアップを表示させるため
		double delayInSeconds = 0.3;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^{
			// 項目編集ポップアップの表示
			[self dispItemEditerPopupWithEditKind:ITEM_EDIT_USER_WORK1];
		});
	} else {
		// 項目編集ポップアップの表示
		[self dispItemEditerPopupWithEditKind:ITEM_EDIT_USER_WORK1];
	}
}

// 施術内容の設定
- (IBAction) OnSetworkItem2:(id)sender
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	CGFloat offset = (iOSVersion<7.0)? 0.0f : 20.0f;

	if (scrollViewBasePanel.contentOffset.y > (115.0 + offset)) {
		[scrollViewBasePanel setContentOffset:CGPointMake(0, 115 + offset) animated:YES];
		// スクロールのアニメーション終了後にポップアップを表示させるため
		double delayInSeconds = 0.3;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^{
			// 項目編集ポップアップの表示
			[self dispItemEditerPopupWithEditKind:ITEM_EDIT_USER_WORK2];
		});
	} else {
		// 項目編集ポップアップの表示
		[self dispItemEditerPopupWithEditKind:ITEM_EDIT_USER_WORK2];
	}
}

// 施術内容の設定
- (IBAction) OnSetworkItem_:(id)sender
{
//TODO:	2012.07.25	伊藤	サーバー側が対応するまでCLOUD_SYNC版では使用不可
#ifndef CLOUD_SYNC
	// メモ入力のためキーボードが表示されている場合は、ここで閉じる
	[tvMemo resignFirstResponder];
	
	_currentMemo = 1;
	// [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
	
	if (popoverCntlWorkItemSet)
	{
		[popoverCntlWorkItemSet release];
		popoverCntlWorkItemSet = nil;
	}
	
	//施術内容の設定ポップアップViewControllerのインスタンス生成
	WorkItemSetPopup *vcWorkItemSet
		= [[WorkItemSetPopup alloc] initWithMasterTable:
									  _workItemMasterTable
									  popOverController:nil
											   callBack:self];
	vcWorkItemSet.contentSizeForViewInPopover = CGSizeMake(560.0f, 280.0f);
	
	// ポップアップViewの表示
	popoverCntlWorkItemSet = [[UIPopoverController alloc] 
							  initWithContentViewController:vcWorkItemSet];
	vcWorkItemSet.popoverController = popoverCntlWorkItemSet;
	[popoverCntlWorkItemSet presentPopoverFromRect:tvWorkItem.bounds 
											inView:tvWorkItem 
						  permittedArrowDirections:UIPopoverArrowDirectionDown 
										  animated:YES];
	// 現在の設定を反映する
	[vcWorkItemSet setSelectedState:_workItemIDs];
	// ポップアップタイトルの設定
	[vcWorkItemSet setPopupTitleWithUserName:self.selectedUserName];
	
	[vcWorkItemSet release];
#endif
}

//START, 2011.06.18, chen, ADD
// 施術内容の設定
- (IBAction) OnSetworkItem2_:(id)sender
{
	// メモ入力のためキーボードが表示されている場合は、ここで閉じる
	[tvMemo resignFirstResponder];
	_currentMemo = 2;
	// [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
	
	if (popoverCntlWorkItemSet)
	{
		[popoverCntlWorkItemSet release];
		popoverCntlWorkItemSet = nil;
	}
	
	//施術内容の設定ポップアップViewControllerのインスタンス生成
	WorkItemSetPopup *vcWorkItemSet
	= [[WorkItemSetPopup alloc] initWithMasterTable:
	   _workItemMasterTable2
								  popOverController:nil
										   callBack:self];
	
	// ポップアップViewの表示
	popoverCntlWorkItemSet = [[UIPopoverController alloc] 
							  initWithContentViewController:vcWorkItemSet];
	vcWorkItemSet.popoverController = popoverCntlWorkItemSet;
	[popoverCntlWorkItemSet presentPopoverFromRect:tvWorkItem2.bounds 
											inView:tvWorkItem2 
						  permittedArrowDirections:UIPopoverArrowDirectionDown 
										  animated:YES];
	
	[popoverCntlWorkItemSet setPopoverContentSize:CGSizeMake(560.0f, 280.0f)];
	// 現在の設定を反映する
	[vcWorkItemSet setSelectedState:_workItemIDs2];
	// ポップアップタイトルの設定
	[vcWorkItemSet setPopupTitleWithUserName:self.selectedUserName];
	
	[vcWorkItemSet release];
}
//END

// 施術マスタの編集
- (IBAction) OnWorkItemMasterEdit:(id)sender
{
	if (popoverCntlWorkMasterEdit)
	{
		[popoverCntlWorkMasterEdit release];
		popoverCntlWorkMasterEdit = nil;
	}
	
	// 施術内容のマスタ編集ポップアップViewControllerのインスタンス生成
	userWorkItemEditPopup *vcWorkItemEdit
		= [[userWorkItemEditPopup alloc]
				initWithWorkItemMaster:POPUP_WORK_ITEM_EDIT 
		   popOverController:nil 
					callBack:self
		   workItemMasterTable:_workItemMasterTable];
	
	// ポップアップViewの表示
	popoverCntlWorkMasterEdit = 
		[[UIPopoverController alloc] initWithContentViewController:vcWorkItemEdit];
	vcWorkItemEdit.popoverController = popoverCntlWorkMasterEdit;
	[popoverCntlWorkMasterEdit presentPopoverFromRect:tvWorkItem.bounds
										 inView:tvWorkItem
					   permittedArrowDirections:UIPopoverArrowDirectionDown
									   animated:YES];

	[popoverCntlWorkMasterEdit setPopoverContentSize:CGSizeMake(560.0f, 300.0f)];
	// タイトルの設定
	vcWorkItemEdit.lblTitle.text = @"施術マスタを編集します";
	
	[vcWorkItemEdit release];
	
}

//START, 2011.06.18, chen, ADD
- (IBAction) OnWorkItemMasterEdit2:(id)sender
{
	if (popoverCntlWorkMasterEdit)
	{
		[popoverCntlWorkMasterEdit release];
		popoverCntlWorkMasterEdit = nil;
	}
	// 施術内容のマスタ編集ポップアップViewControllerのインスタンス生成
	userWorkItemEditPopup *vcWorkItemEdit
	= [[userWorkItemEditPopup alloc]
	   initWithWorkItemMaster:POPUP_WORK_ITEM_EDIT 
	   popOverController:nil 
	   callBack:self
	   workItemMasterTable:_workItemMasterTable2];
	
	// ポップアップViewの表示
	popoverCntlWorkMasterEdit = 
	[[UIPopoverController alloc] initWithContentViewController:vcWorkItemEdit];
	vcWorkItemEdit.popoverController = popoverCntlWorkMasterEdit;
	[popoverCntlWorkMasterEdit presentPopoverFromRect:tvWorkItem2.bounds
											   inView:tvWorkItem2
							 permittedArrowDirections:UIPopoverArrowDirectionDown
											 animated:YES];
	
	[popoverCntlWorkMasterEdit setPopoverContentSize:CGSizeMake(560.0f, 300.0f)];
	// タイトルの設定
	vcWorkItemEdit.lblTitle.text = @"施術マスタを編集します";
	
	[vcWorkItemEdit release];
	
}
//END

// 選択を代表画像にする
- (IBAction) OnSetHeadPicture:(id)sender
{
	NSInteger selectNums;
	
	if ((selectNums = [self selectThubnailItemNums]) <= 0) 
	{
		// 選択なし
		deleteNoAlert.title = @"選択を代表画像にする";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		return;
	}
	
	if (selectNums > 1)
	{
		// 選択なし
		deleteNoAlert.title = @"選択を代表画像にする";
		deleteNoAlert.message = @"代表画像にできるのは\n１つだけです";
		[deleteNoAlert show];
		return;
	}
	
	[headPictrueCheckAlert show];
}

// 選択画像を削除
- (IBAction) OnDeletePicture:(id)sender
{
	if ([self selectThubnailItemNums] <= 0) 
	{
		// 選択なし
		deleteNoAlert.title = @"選択画像を削除";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		return;
	}
	
	// 削除ダイアログの表示
	[deleteCheckAlert show];
	
}

// 選択画像を解除
- (IBAction) OnChancelPicture:(id)sender
{
	if ([self selectThubnailItemNums] <= 0) 
	{
		// 選択なし
		deleteNoAlert.title = @"選択を解除";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		return;
	}

    
    for ( id item in tumbnailItems)
	{
		// 選択をキャンセルする
		[(OKDThumbnailItemView*)item setSelect:NO];
	}
}

- (IBAction)onSave:(UIButton *)sender {
    // 更新と取消ボタンをdisable
    [self setEnableWorkItemButton:NO];
    
    // 施術内容(IDリストと内容文字列)をメンバ変数に設定
    self.selectedWorkItem.workItemListString = [[NSMutableString alloc] initWithString:tvWorkItem.text];
    
    // 施術内容2(IDリストと内容文字列)をメンバ変数に設定
    self.selectedWorkItem.workItemListString2 = [[NSMutableString alloc] initWithString:tvWorkItem2.text];
    
    // メモをメンバ変数に設定：メモリスト先頭に設定する
    [self.selectedWorkItem.userMemos removeAllObjects];
    if ([tvMemo.text length] > 0)
        [self.selectedWorkItem.userMemos addObject:tvMemo.text];
    else
        tvMemo.text = [self.selectedWorkItem getTopMemo];
    
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    
    static ITEM_EDIT_KIND kinds[] = {ITEM_EDIT_USER_WORK1, ITEM_EDIT_USER_WORK2};
    [usrDbMng updateUserItemEditWithString:self.selectedWorkItem.histID
                                 itemKinds:kinds
                                 itemEdits:_itemEdits];
    
    // メモのデータベース更新
    [usrDbMng updateUserWorkMemoList:
     self.selectedWorkItem.histID
                           userMemos:self.selectedWorkItem.userMemos];
    
    
    [usrDbMng release];
    
    //最新施術の日付と同様であれば施術内容を更新
    if ( (userView.lastWorkDate) &&
        ([userView.lastWorkDate isEqualToDate:
          self.selectedWorkItem.workItemDate]) )
    {
        userView.lblLastWorkContent.text =
        [NSString stringWithString: tvWorkItem.text];
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"保存しました" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onTurnBack:(UIButton *)sender {
    // 施術内容を元に戻す
    [self setWorkItem2Control];
    
    // 更新と取消ボタンをdisable
    [self setEnableWorkItemButton:NO];
}

// 2012 6/29 伊藤 選択画像のタイトル、コメント編集
- (IBAction)OnEditImageProfire:(id)sender{
	NSInteger selectNums;
	
	if ((selectNums = [self selectThubnailItemNums]) <= 0) 
	{
		// 選択なし
		deleteNoAlert.title = @"画像のプロフィール編集";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		return;
	}
	
	if (selectNums > 1)
	{
		// 選択なし
		deleteNoAlert.title = @"画像のプロフィール編集";
		deleteNoAlert.message = @"一度に編集できるのは\n１つだけです";
		[deleteNoAlert show];
		return;
	}
    
	if (popoverCntlEditUser)
	{
		[popoverCntlEditUser release];
		popoverCntlEditUser = nil;
	}
    
    userDbManager *usrDbMng = [[userDbManager alloc] init];
	
	// 選択サムネイルItemよりDocument以下のファイル名を取得
	NSUInteger idx 
	= (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:0]) intValue];
	OKDThumbnailItemView *item = [self searchThnmbnailItemByTagID:idx];
	
	// NSString *pictUrl = [[NSString alloc]initWithString:[item getFileName]];
     NSString *pictUrl = [item getFileName];

	// ユーザ情報編集のViewControllerのインスタンス生成
	// ユーザ情報編集のViewControllerのインスタンス生成
	PhotoCommentPopup *vcPhotoCom
	= [[PhotoCommentPopup alloc]initPhotoSettingWithPictureURL:pictUrl
                                                  selectUserID:_selectedUserID
                                                  selectHistID:_selectedHistID
                                                       popUpID:POPUP_EDIT_IMAGE_PROFILE
                                                      callBack:self ];
#ifndef CALULU_IPHONE
	
	popoverCntlEditImageProfile = 
	[[UIPopoverController alloc] initWithContentViewController:vcPhotoCom];
	vcPhotoCom.popoverController = popoverCntlEditImageProfile;
	[popoverCntlEditImageProfile presentPopoverFromRect:btnEditImageProfile.bounds
                                                 inView:btnEditImageProfile
                               permittedArrowDirections:UIPopoverArrowDirectionAny
                                               animated:YES];
	[popoverCntlEditImageProfile setPopoverContentSize:CGSizeMake(720.0f, 314.0f)];
	popoverCntlEditImageProfile.delegate = self;
	
	// MainViewControllerの取得
//	MainViewController *mainVC
//	= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    //画面外をタップしてもポップアップが閉じないようにする処理
//    NSMutableArray *viewCof = [[NSMutableArray alloc]init];
//
//    [viewCof addObject:mainVC.view];
//    [viewCof addObject:self.view];
//    popoverCntlEditImageProfile.passthroughViews = viewCof;
//    [viewCof release];
	
	// MainViewControllerの取得
	MainViewController *mainVC
	= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC viewScrollLock:YES];
	self.view.userInteractionEnabled = NO;
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:vcPhotoCom];
#endif
    [usrDbMng release];
	pictUrl = nil;
	[vcPhotoCom release];
	[popoverCntlEditImageProfile release];
}

// フリーメモのキーボードを隠す
- (IBAction) OnHideFreeMemoKeyBord:(id)sender
{
    if (! isTvMemoFocus)
    {   return; }
    
    // フリーメモTextViewの入力完了
    [self freeMemoShouldEndEditing:tvMemo];
    
    // フリーメモのキーボードを閉じる
    [tvMemo resignFirstResponder];
}

#pragma mark OKDThumbnailItemViewDelegate
// サムネイル選択イベント
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
		for (int i = 0; i < [selectItemOrder count]; i++)
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
		[item setSelectNumber:(int)[selectItemOrder count]];
	}

}
- (void)doubleTapVideoThumbnail:(NSURL *)url {
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    if (!self.videoPreviewVC) {
        self.videoPreviewVC = [[VideoPreviewViewController alloc] init];
    }
    //[self.videoPreviewVC setMovie:movie];
    [mainVC.view addSubview:self.videoPreviewVC.view];
}
#pragma mark WorkItemSetPopupDelegate
// 各施術内容をクリックした時のイベント
- (void)OnWorkItemSet:(WORKITEM_INT)workItemID isSelect:(BOOL)isSelect
{
	// IDを文字列化する
	NSString *iDs = [NSString stringWithFormat:@"%d", workItemID];
	
	BOOL isChange = NO;
	if (_currentMemo == 1) 
	{
		//  作業用の施術内容ID一覧の更新
		if (isSelect)
		{
			// 選択されたのでリストに追加する:念の為重複チェック
			if (! [_workItemIDs containsObject:iDs] )
			{
				[_workItemIDs addObject:iDs];
				isChange = YES;
			}
		}
		else 
		{
			// 解除されたのでリストより取り除く
			if ([_workItemIDs containsObject:iDs] )
			{
				[_workItemIDs removeObject:iDs];
				isChange = YES;
			}
		}
		
		// 作業用の施術内容ID一覧を並び替える
		[_workItemIDs sortUsingComparator:^(id obj1, id obj2)
		 {
			 return [obj1 compare:obj2];
		 }];
		
		// 施術内容の文字列の更新
		NSMutableString *workItem = [NSMutableString string];
		for (id idN in _workItemIDs)
		{
			if ([workItem length] > 0)
			{	[workItem appendString:@"・"]; }
			
			// 施術マスタテーブルよりIDにて内容（文字列）を取り出す
			[workItem appendString:[_workItemMasterTable objectForKey:idN]];
		}
		tvWorkItem.text = workItem;
	}
	//START, 2011.06.18, chen, ADD
	else if(_currentMemo == 2)
	{
		//  作業用の施術内容ID一覧の更新
		if (isSelect)
		{
			// 選択されたのでリストに追加する:念の為重複チェック
			if (! [_workItemIDs2 containsObject:iDs] )
			{
				[_workItemIDs2 addObject:iDs];
				isChange = YES;
			}
		}
		else 
		{
			// 解除されたのでリストより取り除く
			if ([_workItemIDs2 containsObject:iDs] )
			{
				[_workItemIDs2 removeObject:iDs];
				isChange = YES;
			}
		}
		
		// 作業用の施術内容ID一覧を並び替える
		[_workItemIDs2 sortUsingComparator:^(id obj1, id obj2)
		 {
			 return [obj1 compare:obj2];
		 }];
		
		// 施術内容の文字列の更新
		NSMutableString *workItem = [NSMutableString string];
		for (id idN in _workItemIDs2)
		{
			if ([workItem length] > 0)
			{	[workItem appendString:@"・"]; }
			
			// 施術マスタテーブルよりIDにて内容（文字列）を取り出す
			[workItem appendString:[_workItemMasterTable2 objectForKey:idN]];
		}
		tvWorkItem2.text = workItem;
	}
	//END
	
	// 更新と取消ボタンをenable
	if (isChange)
	{	[self setEnableWorkItemButton:YES];}
	
	// [workItem release];
}

// 全て選択解除
- (void)OnAllWorkItemReset
{
	if (_currentMemo == 1) 
	{
		// 最初から何も選択されていない
		if ( [_workItemIDs count] <= 0)
		{	return; }
		
		[_workItemIDs removeAllObjects];
		tvWorkItem.text = @"";
	}
	//START, 2011.06.18, chen, ADD
	else if(_currentMemo == 2)
	{
		// 最初から何も選択されていない
		if ( [_workItemIDs2 count] <= 0)
		{	return; }
		
		[_workItemIDs2 removeAllObjects];
		tvWorkItem2.text = @"";
	}
	//END
	
	// 更新と取消ボタンをenable
	[self setEnableWorkItemButton:YES];
	
}

#pragma mark itemEditerPopupDelegate

// 項目編集種別によるtextViewを取得
- (UITextView*) getWorkItemTextView:(ITEM_EDIT_KIND)editKind
{
	UITextView* tv = nil;
	switch (editKind) {
		case ITEM_EDIT_USER_WORK1:
			tv = tvWorkItem;
			//idx = 0;
			break;
		case ITEM_EDIT_USER_WORK2:
			tv = tvWorkItem2;
			//idx = 1;
			break;
		default:
			break;
	}
	
	return(tv);
}

// 項目をクリックした時のイベント
- (void)OnItemSetWithSelecteds:(NSArray*)selecteds itemEditKind:(ITEM_EDIT_KIND)editKind
{
	// 項目編集種別によるtextViewを取得
	UITextView* tv = [self getWorkItemTextView:editKind];
	
	// 施術内容の文字列の更新
	NSMutableString *workItem = [NSMutableString string];
	for (id name in selecteds)
	{
		if ([workItem length] > 0)
		{	[workItem appendString:@"・"]; }
		
		// 施術マスタテーブルよりIDにて内容（文字列）を取り出す
		[workItem appendString:name];
	}
	tv.text = workItem;	
	
	// 更新と取消ボタンをenable
	[self setEnableWorkItemButton:YES];
	
	// 選択中の名前リストの保存
	NSMutableArray *names = [_itemEdits objectAtIndex:tv.tag];
	[names removeAllObjects];
	for (id name in selecteds)
	{	[names addObject:name]; }
}

// 全ての項目の選択解除
- (void)OnAllItemReset:(ITEM_EDIT_KIND)editKind
{
	// 項目編集種別によるtextViewを取得
	UITextView* tv = [self getWorkItemTextView:editKind];
	
	// 内容をクリア
	tv.text = @"";
	
	// 更新と取消ボタンをenable
	[self setEnableWorkItemButton:YES];
	
	// 選択中の名前リストの保存(クリア)
	NSMutableArray *names = [_itemEdits objectAtIndex:tv.tag];
	[names removeAllObjects];
}

// ポップアップを閉じる時に、回転許可を戻す
- (void)afterPopupClose
{
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    app.navigationController.enableRotate = YES;
}

#pragma mark UIPopoverControllerDelegate
// ポップアップの画面外をタップして閉じた時に呼ばれる
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[self afterPopupClose];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
	self.view.userInteractionEnabled = YES;
}

#pragma mark PopUpViewContollerBaseDelegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    //2012 6/25 伊藤 お客様情報編集中にポップアップが閉じない処理の一部
    self.view.userInteractionEnabled = YES;
    MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:NO];

	userDbManager *usrDbMng;
	mstUser *user;
	
	switch (popUpID)
	{
		case (NSUInteger)POPUP_EDIT_USR:
		// ユーザ情報編集
			user = (mstUser*)object;
			
			usrDbMng = [[userDbManager alloc] init];
			
			// データベースを更新する
			if (! [usrDbMng updateMstUser:user])
			{
				deleteNoAlert.message = @"お客様情報の編集に失敗しました\n(誠に恐れ入りますが\n再編集をお願いいたします)" ;
				deleteNoAlert.title = @"お客様情報編集";
				[deleteNoAlert show];
			}
			else 
			{
				// ユーザ情報Viewを更新
				[userView setUserInfo:self.selectedUserID Language:isJapanese];
				
				// 選択中ユーザ名の更新
				self.selectedUserName = [NSString stringWithFormat:@"%@ %@", 
											user.firstName, user.secondName];
			}
			
			[usrDbMng release];
			
			break;
			
		case POPUP_WORK_ITEM_EDIT:
		// 施術内容のマスタ編集
			
			usrDbMng = [[userDbManager alloc] init];
			if(_currentMemo == 1)
			{
				// 編集された施術マスタのテーブルにてデータベースの施術マスタを更新する
				if (! [usrDbMng updateWorkItemMstWithEditedTable:(NSMutableDictionary*)object
													   tableName:ITEM_EDIT_USER_WORK1_TABLE])
				{
					deleteNoAlert.message 
					= @"施術内容マスタの編集\nに失敗しました\n(誠に恐れ入りますが\n再編集をお願いいたします)" ;
					deleteNoAlert.title = @"施術内容マスタ編集";
					[deleteNoAlert show];
				}
				else 
				{
					// ユーザ情報Viewを更新
					[userView setUserInfo:self.selectedUserID Language:isJapanese];
					if (self.selectedWorkItem)
					{
						// 選択中の施術履歴の更新
						[usrDbMng getWorkItemListWithWorkItem : self.selectedWorkItem];
						
						// 施術内容の更新
						tvWorkItem.text = self.selectedWorkItem.workItemListString;
					}
					// 施術内容マスタテーブルの初期化
					[self initWorkItemMasterTable:usrDbMng];
					
					// MainViewControllerの取得
					MainViewController *mainVC 
					= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
					// 呼び出しもと（履歴一覧）のVCを取得
					HistListViewController *histListVC
					= (HistListViewController*)[mainVC getPrevControlWithSelf:self];
					// 施術内容と表示されているセルの更新
					[histListVC updateHistUserItemsVisbleCells:YES];
				}
			}
			//START, 2011.06.18, chen, ADD
			else if(_currentMemo == 2)
			{
				// 編集された施術マスタのテーブルにてデータベースの施術マスタを更新する
				if (! [usrDbMng updateWorkItemMstWithEditedTable:(NSMutableDictionary*)object
													   tableName:ITEM_EDIT_USER_WORK2_TABLE])
				{
					deleteNoAlert.message 
					= @"施術内容マスタの編集\nに失敗しました\n(誠に恐れ入りますが\n再編集をお願いいたします)" ;
					deleteNoAlert.title = @"施術内容マスタ編集";
					[deleteNoAlert show];
				}
				
				else 
				{
					// ユーザ情報Viewを更新
					[userView setUserInfo:self.selectedUserID Language:isJapanese];
										// ユーザ情報Viewを更新
					if (self.selectedWorkItem)
					{
						// 選択中の施術履歴の更新
						[usrDbMng getWorkItemListWithWorkItem2 : self.selectedWorkItem];
						
						// 施術内容の更新
						tvWorkItem2.text = self.selectedWorkItem.workItemListString2;
					}
					
					
					// 施術内容マスタテーブルの初期化
					[self initWorkItemMasterTable2:usrDbMng];
					
					// MainViewControllerの取得
					MainViewController *mainVC 
					= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
					// 呼び出しもと（履歴一覧）のVCを取得
					HistListViewController *histListVC
					= (HistListViewController*)[mainVC getPrevControlWithSelf:self];
					// 施術内容と表示されているセルの更新
					[histListVC updateHistUserItemsVisbleCells:YES];
				}
				
			}
			//End
			[usrDbMng release];
			
			break;
        case POPUP_EDIT_IMAGE_PROFILE:
            // サムネイルItemリストの作成（写真データの読み込み含む）
            [self tumbnailItemsMake];
            
            // Itemを再度レイアウトする
            [self thumbnailItemsLayout];
            
            // 代表写真の変更があったかもしれないので常に更新
            [userView setUserInfo:self.selectedUserID Language:isJapanese];
            
            // 再描画を行わない
            _isThumbnailRedraw = NO;
            break;
		default:
			break;
	}
	self.view.userInteractionEnabled = YES;
	//[popoverController release];
	// popoverController = nil;
}

#pragma mark UIFlickerButtonDelegate
// フリックイベント　//DELC SASAGE 調査：フリックしても呼ばれない？
- (void)OnFlicked:(id)sender flickState:(FLICK_STATE)state
{
	switch ( ((UIFlickerButton*)sender).tag) 
	{
		case FLICK_NEXT_PREV_VIEW:
			// 画面遷移
		case FLICK_USER_INFO_ON:
			// ユーザ情報上ボタン
			switch (state) {
				case FLICK_RIGHT:
					// 右方向のフリック:履歴一覧画面に戻る
					[self OnHistListView:sender];
					break;
				case FLICK_LEFT:
					// 左方向のフリック:履歴写真一覧画面に遷移
					// [self OnHistPictListView:sender];
					// 左方向のフリック:選択画像表示に遷移
					if ([self selectThubnailItemNums] > 0)
					{  [self OnSelectPictureView:sender]; }
					break;
				default:
					break;
			} 
			break;
		default:
			break;
	}
}

// ダブルタップイベント
- (void)OnDoubleTap:(id)sender
{
	switch ( ((UIFlickerButton*)sender).tag) 
	{
		case FLICK_CAMERA_VIEW:
			// カメラ画面へ
			[self OnCameraView:sender];
			break;
		case FLICK_NEXT_PREV_VIEW:
			// 左方向のフリック:選択画像表示に遷移
			if ([self selectThubnailItemNums] > 0) 
			{  [self OnSelectPictureView:sender]; }
			break;
		case FLICK_PICT_LIST_VIEW:
			// 現在選択ユーザ代表写真ボタン:写真一覧表示
			[self OnPictureListView:sender];
			break;
		case FLICK_USER_INFO_ON:
			// ユーザ情報上ボタン:お客様情報更新
#ifdef VER113_LATER
			[self userInfoUpadte];
#else
            // ユーザ情報はユーザ一覧のみで編集できるものとする : Ver113
#endif
			break;
		default:
			break;
	}
}

#pragma mark UIAlertViewDelegate

// 選択画像の削除
- (void) selectedPictureDelete
{
    // 削除用リスト
    NSMutableArray *deleteItems = [[NSMutableArray alloc] init];
    NSMutableArray *deleteTags = [[NSMutableArray alloc] init];
    
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
        
        // ファイル名の取得：パスを除くファイル名
        NSString *fileName = [thItem getFileName];
#ifdef VER130_LATER
        // ファイルの削除
        [imgFileMng deleteImageBothByRealSize:fileName];
        /*
         if ([[NSFileManager defaultManager] fileExistsAtPath:fileName])
         {
         // 念のためFileの存在確認
         NSError* error=nil;
         [[NSFileManager defaultManager] removeItemAtPath:fileName error:&error];
         }
         */
#endif
        // 削除用リストに加える
        [deleteItems addObject:thItem];
        
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

        if ([item isKindOfClass:[VideoThumbnailItemView class]]) {
            MovieResource *resource = [[MovieResource alloc] initWithPath:documentFileName];
            // データベースの履歴用ユーザ写真を削除:写真urlをキーとして削除
            [usrDbMng deleteHistUserVideo:self.selectedHistID
                                 videoURL:resource.path];
            // データベースの履歴テーブルの代表画像が削除対象であれば無効にする
            [usrDbMng updateHistHeadPictureByNewUrl:resource.thumbnailPath newUrl:nil];
            // ユーザの写真が削除対象であれば無効にする
            [usrDbMng updateUserPictureByNewUrl:resource.thumbnailPath newUrl:nil];
            // ファイルの削除  DB更新後に削除する
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:resource.movieFullPath error:&error];
            if (error) {NSLog(@"%@",error.localizedDescription);}
			error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:resource.thumbnailFullPath error:&error];
            if (error) {NSLog(@"%@",error.localizedDescription);}
            [resource release];
        } else {
            // データベースの履歴用ユーザ写真を削除:写真urlをキーとして削除
            [usrDbMng deleteHistUserPicture:self.selectedHistID
                                 pictureURL:documentFileName];
            // データベースの履歴テーブルの代表画像が削除対象であれば無効にする
            [usrDbMng updateHistHeadPictureByNewUrl:documentFileName newUrl:nil];
            // ユーザの写真が削除対象であれば無効にする
            [usrDbMng updateUserPictureByNewUrl:fileName newUrl:nil];
            
            // ファイルの削除  DB更新後に削除する：ver130
            [imgFileMng deleteImageBothByRealSize:fileName];
        }
        
		fileName = nil;
    }
    
    // サムネイルItemリストより削除
    for (id delItem in deleteItems) {
        [tumbnailItems removeObject:delItem];
    }
    
    // 選択サムネイルItemの順序Tableより削除
    for (id delTag in deleteTags) {
        [selectItemOrder removeObject:delTag];
    }
    //NSLog(@"AAAAA");
    // データベースから最新の履歴用のユーザ写真リストを取得する
	[usrDbMng getHistPictureUrls:self.selectedWorkItem];
    // [usrDbMng getHistVideoUrls:self.selectedWorkItem];
    //[self.selectedWorkItem.videosUrls removeAllObjects];
    
    [imgFileMng release];
    
    [usrDbMng release];
    
    [deleteTags release];
    
    // 削除用リストのクリア
    [deleteItems release];
    
    [self thumbnailSelectedCellRefresh];
    // サムネイルItemリストの作成（写真データの読み込み含む）
	[self tumbnailItemsMake];
	
	// Itemを再度レイアウトする
	[self thumbnailItemsLayout];
	
	// 代表写真の変更があったかもしれないので常に更新
	[userView setUserInfo:self.selectedUserID Language:isJapanese];
	//NSLog(@"CCCCCCCCCC");
	// 再描画を行わない
	_isThumbnailRedraw = NO;
}

// 修正確認による施術内容の設定
- (void)modifyCheckWorkItem:(NSInteger)buttonIndex
{
	//  修正内容を更新
	if (buttonIndex == 0)
	{
		[self OnUpdateData:btnUpdateWorkItem];
	}
	// 修正内容を取消
	else 
	{
		[self OnChancel:btnChancelWorkItem];
	}	
}

// 代表写真の設定
- (void)setHeadPicture
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	
	// 選択サムネイルItemよりDocument以下のファイル名を取得
	NSUInteger idx 
	= (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:0]) intValue];
	OKDThumbnailItemView *item = [self searchThnmbnailItemByTagID:idx];
	
	NSString *pictUrl = [ self getDocumentPath : item];
	
	// 代表画像をデータベースに設定する
	if (! [usrDbMng updateHistHeadPicture:
		   self.selectedHistID
							   pictureURL:pictUrl 
						  isEnforceUpdate:YES])
	{
		deleteNoAlert.title = @"選択を代表画像にする";
		deleteNoAlert.message 
		= @"履歴の代表画像の設定に失敗しました\n(誠に恐れ入りますが\n再設定をお願いいたします)";
		[deleteNoAlert show];
	}
	/*
	else 
	{
		deleteNoAlert.title = @"選択を代表画像にする";
		deleteNoAlert.message 
		= @"選択した画像を\n履歴の代表画像の設定しました\n(お客様選択画面で確認できます)";
		[deleteNoAlert show];
		
	}
	*/
	
	[usrDbMng release];
	
	// 遷移元画面のTableViewCellの更新
//	if(self.selectedViewCell)
//	{
//		[self.selectedViewCell.picture setImage:
//		 [self makeImagePicture: pictUrl
//					   pictSize:self.selectedViewCell.picture.bounds.size]];
//	}
	
}

// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// 削除確認ではいの場合、選択画像を削除
	if ( (alertView == deleteCheckAlert) && (buttonIndex == 0) )
	{
		[self selectedPictureDelete];
	}
	// 修正確認の場合
	else if (alertView == modifyCheckAlert)
	{
		[self modifyCheckWorkItem:buttonIndex];
	}
	// 代表写真の設定ではいの場合
	else if ( (alertView == headPictrueCheckAlert) && (buttonIndex == 0) )
	{
		[self setHeadPicture];
	}
	
	// alertの表示を消す
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

#pragma mark UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	BOOL stat = NO;
    
    if (textView == tvMemo)
    {
        // フリーメモTextViewの入力開始
        stat = [self freeMemoShouldBeginEditing:textView];
	}
    else if (textView == tvWorkItem)
    {
        // 項目編集ポップアップの表示
        [self dispItemEditerPopupWithEditKind:ITEM_EDIT_USER_WORK1];
    }
    else if (textView == tvWorkItem2)
    {
        // 項目編集ポップアップの表示
        [self dispItemEditerPopupWithEditKind:ITEM_EDIT_USER_WORK2];
    }
	
	return (stat);
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	BOOL stat = YES;
    
    if (textView == tvMemo)
    {
        // フリーメモTextViewの入力完了
        stat = [self freeMemoShouldEndEditing:textView];
	}
	
	return (stat);
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == tvMemo)
    {
        // フリーメモTextViewの場合、何かの入力で変更ありとする
        [self setEnableWorkItemButton:YES];
	}

}
#pragma mark video用
- (BOOL)videoIsSelected {
	if ([self selectThubnailItemNums] <= 0) {
        return NO;
    }
    NSUInteger oIdx = (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:0]) intValue];
    OKDThumbnailItemView *oItem = [self searchThnmbnailItemByTagID:oIdx];
    return [oItem isKindOfClass:[VideoThumbnailItemView class]];
}

- (void)onPreviewCustomer:(id)sender {
	CustomerPopup *customPopup = [[CustomerPopup alloc] init];
	customPopup.modalPresentationStyle = UIModalPresentationFormSheet;
	customPopup.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self presentViewController:customPopup animated:YES completion:nil];
	customPopup.view.superview.center = self.view.center;
	
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	mstUser *user = [usrDbMng getMstUserByID:self.selectedUserID];
	//customer's info
	customPopup.tfFirstName.text = user.firstName;
	customPopup.tfLastName.text = [NSString stringWithFormat:@"%@%@",user.middleName,user.secondName];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd"];
	customPopup.tfBirthday.text = [formatter stringFromDate:user.birthDay];
	
	if (user.sex == 0) {
		customPopup.tfGenre.text = @"女性";
	} else if (user.sex == 1) {
		customPopup.tfGenre.text = @"男性";
	} else {
		customPopup.tfGenre.text = @"不明";
	}
	
	customPopup.tfBloodType.text = [self ConvertBloodTypeEnum:user.bloadType];
	customPopup.tfCustomerNo.text = [user getRegistNumber];
	customPopup.tfPersonInCharge.text = user.responsible;
	customPopup.tfAddress.text = [NSString stringWithFormat:@"%@%@%@%@",user.adr1,user.adr2,user.adr3,user.adr4];
	customPopup.tfMobile.text = user.mobile;
	customPopup.tfPhone.text = user.tel;
	customPopup.tfMail.text = user.email1;
	customPopup.tfHobby.text = user.syumi;
	customPopup.tvMemo.text = user.memo;
}

-(NSString *)ConvertBloodTypeEnum:(NSInteger)blood
{
	NSString *bloodType;
	switch (blood) {
		case BloadTypeA:
			bloodType = @"A 型";
			break;
		case BloadTypeB:
			bloodType = @"B 型";
			break;
		case BloadTypeO:
			bloodType = @"O 型";
			break;
		case BloadTypeAB:
			bloodType = @"AB 型";
			break;
		default:
			bloodType = @"不明";
			break;
	}
	return bloodType;
}

@end
