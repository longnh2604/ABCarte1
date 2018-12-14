    //
//  HistListViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/12/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Common.h"
#import "HistListViewController.h"
#import "camaraViewController.h"
#import "UserInfoListViewController.h"
#import "UserInfoDispViewSupport.h"
#import "mstUser.h"
#import "fcUserWorkItem.h"
#import "userDbManager.h"
#import "HistListTableViewCell.h"
#import "HistDetailViewController.h"
#import "./model/OKDImageFileManager.h"
#import "AccountManager.h"
#import "WebMailUserStatus.h"
#import "shop/ShopManager.h"
#import "CustomerPopup.h"


// 新規履歴作成のポップアップID
#define POPUP_NEW_HIST		(NSInteger)0x0001

@implementation HistListViewController

@synthesize selectedUserID = _selectedUserID;
@synthesize selectedUserName = _selectedUserName;

static bool     mailItemAdd;
static bool     qrItemAdd;

#pragma mark local_Methods

// 施術内容リストの初期化
- (void)initHistUserItems
{
	// データベースの初期化
	userDbManager *dbMng = [[userDbManager alloc] init];
	
	// 施術内容一覧の取得
	_histUserItems = [dbMng getUserWorkItemsByID:self.selectedUserID];
	[_histUserItems retain];
	
	[dbMng release];
}

// ツールバーItemのEnable設定
- (void)setToolBarItemEnable:(BOOL)isEnable
{
	btnCameraView.enabled = btnHistDetailView.enabled = isEnable;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *status = [ud objectForKey:@"add_carte"];
    
    if (status != NULL) {
        [btnKarteDelete setEnabled:NO];
    } else {
        [btnKarteDelete setEnabled:YES];
    }
}

// 代表写真リストの初期化
- (void) initHeadPictureList
{
	if (_headPictureList)
	{ return; }
	
	_headPictureList = [NSMutableDictionary dictionary];
	[_headPictureList retain];
	
}

// 写真の表示
- (UIImage*) makeImagePictureWithUID:(NSString*) pictUrl userID:(USERID_INT)userID
{
	if ( (!pictUrl) || ((pictUrl) && ([pictUrl length] <= 0) ))
	{	return (nil); }
	
	// NSLog(@"makeImagePicture start ------------------->");
	
	// 代表写真リストの初期化確認
	[self initHeadPictureList];
	
	// 代表写真リストのキャッシュより画像を取得
	UIImage *cashImage = [_headPictureList objectForKey:pictUrl];
	if (cashImage)
	{	return (cashImage); }
	
	OKDImageFileManager *imgFileMng 
		= [[OKDImageFileManager alloc] initWithUserID:userID];
	
	UIImage *drawImg = [imgFileMng getThumbnailSizeImage:pictUrl];
	
	// NSLog(@"<-------------------makeImagePicture end ");
	
	// 代表写真リストのキャッシュに画像を保存
	if (drawImg)
	{ [_headPictureList setObject:drawImg forKey:pictUrl]; }
	
	[imgFileMng release];
	
	return (drawImg);
}

// 写真の表示
- (UIImage*) makeImagePicture:(NSString*)pictUrl pictSize:(CGSize)size
{
	if ( (!pictUrl) || ((pictUrl) && ([pictUrl length] <= 0) ))
	{	return (nil); }
	
	// 代表写真リストの初期化
	if (! _headPictureList)
	{
		_headPictureList = [NSMutableDictionary dictionary];
		[_headPictureList retain];
	}
	
	// 代表写真リストのキャッシュより画像を取得
	UIImage *cashImage = [_headPictureList objectForKey:pictUrl];
	if (cashImage)
	{	return (cashImage); }
	
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
	img = nil;
	fileDat = nil;
	
	// NSLog(@"<-------------------makeImagePicture end ");
	
	// 代表写真リストのキャッシュに画像を保存
	[_headPictureList setObject:drawImg forKey:pictUrl];
	
	return (drawImg);
}

// 履歴用のユーザ写真リストを更新する
- (void) updateHistPicutures
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
	if (! indexPath)
	{	return; }			// 念のため
	
	// 現在選択中の履歴を取得
	fcUserWorkItem *selectedWorkItem = [_histUserItems objectAtIndex:indexPath.row];
	
	// データベースから最新の履歴用のユーザ写真リストを取得する
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	[usrDbMng getHistPictureUrls: selectedWorkItem];
	[usrDbMng release];
	
	// 選択中の代表写真を更新
    // (visibleCellsだけを更新するようにした)
    for (HistListTableViewCell *vcell in [tvHistList visibleCells]) {
        if ([tvHistList indexPathForCell:vcell]==indexPath) {
            [vcell.picture setImage:
             [self makeImagePictureWithUID:selectedWorkItem.headPictureUrl
                                    userID:selectedWorkItem.userID]];
            break;
        }
    }

}

// 最新施術日（であった場合）の編集
-(void)lastWorkItemEdit
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
	if (! indexPath)
	{	return; }			// 念のため
	
	// 現在選択中の履歴を取得
	fcUserWorkItem *selectedWorkItem = [_histUserItems objectAtIndex:indexPath.row];
	
	//最新施術の日付と同様であれば施術内容を更新
	if ( (userView.lastWorkDate) && 
		([userView.lastWorkDate isEqualToDate:
		  selectedWorkItem.workItemDate]) )
	{ 
		userView.lblLastWorkContent.text = 
			[NSString stringWithString: selectedWorkItem.workItemListString];
	}
}

// alert表示
- (void) alertDisp:(NSString*) message alertTitle:(NSString*) altTitle
{
	
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:altTitle
							  message:message
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil
							  ];
	[alertView show];
	[alertView release];	
}

// 選択中の履歴(cell)より履歴IDを取得する： =0：選択なし　< 0：取得失敗
- (HISTID_INT) getHistIdWithSelectedRow : (fcUserWorkItem**)pWorkItem
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
	if (! indexPath)
	{	return (0); }			// 念のため
	
	// 現在選択中の履歴を取得
	fcUserWorkItem *selectedWorkItem = [_histUserItems objectAtIndex:indexPath.row];
	
	// 履歴IDをデータベースよりユーザIDと当日で取得する:当日の履歴がない場合は作成する
	userDbManager *usrDbMng = [[userDbManager alloc] init];
    HISTID_INT hID = [usrDbMng getHistIDWithDateUserID:selectedWorkItem.userID
                                              workDate:selectedWorkItem.workItemDate
                                        isMakeNoRecord:NO];
	[usrDbMng release];
	
	if (pWorkItem)
	{	*pWorkItem = selectedWorkItem; }
	
	return(hID);
}

// 代表写真リストのリリース
- (void) releaseHeadPictureList
{
	// リリース済み
	if (_headPictureList == nil)
	{ return; }
	
	[_headPictureList removeAllObjects];
	[_headPictureList release];
	_headPictureList = nil;
}

// リスト上の履歴を選択
- (void) selectHistOnListWithRow:(NSUInteger)row
{
	// 施術内容のItem一覧に存在するかを確認
	if ([_histUserItems count] <= row)
	{	return; }
	
	@try
	{
		NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
        //stop to scroll to that cell position
//        [tvHistList selectRowAtIndexPath:path animated:NO
//                           scrollPosition:UITableViewScrollPositionTop];
        [tvHistList selectRowAtIndexPath:path animated:NO
                          scrollPosition:nil];
		[tvHistList.delegate tableView:tvHistList
				didSelectRowAtIndexPath:path];
		}
	@catch (NSException* exception) {
		NSLog(@"selectHistOnListWithRow: Caught %@: %@", 
				[exception name], [exception reason]);
	}
}

// 起動時の遅延処理
- (void) initRunDelay
{
	// 起動時の遅延処理完了フラグをここで初期化
	_isInitRunFinish = NO;
	
	// 遅延させる
	[self performSelector:@selector(onInitRunDelayDone:) 
			   withObject:self afterDelay:0.05f];		// 0.05秒後に起動

}

// 遅延後のコールバック関数
- (void) onInitRunDelayDone:(id)sender
{
	// 起動時の遅延処理完了フラグをここで設定
	_isInitRunFinish = YES;
	
	// リスト上の先頭履歴を選択
	[self selectHistOnListWithRow:0];
}

// 履歴詳細の現在選択の履歴をクリア
- (void) clearHistDetailHistID
{
	@try {
		// 次のViewController(HistListViewController)をMainVCより取得する
		MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		HistDetailViewController* nextVC 
		= (HistDetailViewController*)([mainVC getNextControlWithSelf:self]);
		if (nextVC)
		{
			nextVC.selectedHistID = -1;
		}
	}
	@catch (NSException* exception) {
		NSLog(@"clearHistDetailHistID: Caught %@: %@", 
			  [exception name], [exception reason]);
	}
}

// 新規履歴の作成
- (void) makeNewHistWithDate:(NSDate*)newDate isDuplicateError:(BOOL)isDupErr
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	
	// データベースより選択された日付の履歴が存在しないかを確認する
	NSInteger histID 
	= [usrDbMng getHistIDWithDateUserID:self.selectedUserID 
							   workDate:newDate
						 isMakeNoRecord:NO];
	
	if (histID != -1)
	{
		if (isDupErr)
		{
			[self alertDisp:[NSString stringWithFormat: 
							 @"%@\n(誠に恐れ入りますが\n再操作をお願いいたします)",
							 (histID > 0)? @"既にこの日付の履歴は存在します" : @"履歴の存在確認に失敗しました"]
				 alertTitle:@"新規履歴の作成"];
		}
		[usrDbMng release];
		return;
	}
	
	// データベースに新規履歴を作成する:該当日の履歴がない場合は作成する
	histID = [usrDbMng getHistIDWithDateUserID:self.selectedUserID 
									  workDate:newDate
			  
								isMakeNoRecord:YES];
	[usrDbMng release];
	
	if ( histID < 0)
	{
		if (isDupErr)
		{
			[self alertDisp:@"新規履歴の作成に失敗しました\n(誠に恐れ入りますが\n再操作をお願いいたします)"
				 alertTitle:@"新規履歴の作成"];
		}
		return;
	}
	
	// 施術内容リストの初期化 
	[_histUserItems release];
	[self initHistUserItems];
	
	// スクロールViewの再描画
	[tvHistList reloadSectionIndexTitles];
	[tvHistList reloadData];
	
	// 今回作成した履歴日付が最新となる場合は、最新施術内容を更新
	// TODO： 日付比較の確認
	// if ( [userView.lastWorkDate compare:newDate] == NSOrderedDescending)
	{
		[userView setUserInfo:self.selectedUserID Language:isJapanese];
	}
	
	// ツールバーItemのDisEnable設定
	[self setToolBarItemEnable:NO];
	
	// 新規に作成した履歴を検索
	NSInteger idx = NSIntegerMin;
	NSInteger count = 0;
	for (fcUserWorkItem* item in _histUserItems) {
		if (item.histID == histID)
		{	
			idx = count; 
			break;
		}
		count++;
	}
	if (idx == NSIntegerMin)
	{	return; }
	
	// 先に履歴詳細の現在選択の履歴をクリア
	[self clearHistDetailHistID];
	
	// リスト上の履歴を選択
	[self selectHistOnListWithRow: (NSUInteger)idx];
    
    //add carte check
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *status = [ud objectForKey:@"add_carte"];
    
    if (status == NULL) {
        [ud setObject:@"true" forKey:@"add_carte"];
        [ud synchronize];
    }
    
    [btnKarteDelete setEnabled:NO];
}

//set notification to refresh image when changed
- (void)viewWillAppear:(BOOL)animated {
    NSDictionary* userInfo = @{@"userID": @(_selectedUserID)};
    [[NSNotificationCenter defaultCenter]postNotificationName:@"refreshTopImage" object:self userInfo:userInfo];
    
    [self updateHistUserItemsVisbleCells:YES];
}

// 履歴詳細画面(HistDetailViewController)の更新
- (void) refreshHistDetailVC:(HistDetailViewController*) vc
{
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
	
	if (! indexPath)
	{	
		// 一件も履歴がない場合はここで当日日付で作成を試みる
		if ([_histUserItems count] <= 0)
		{
			// 新規履歴の作成
			[self makeNewHistWithDate:[NSDate date] isDuplicateError:NO];
			
			// リスト上の先頭履歴を選択
			[self selectHistOnListWithRow:0];
			
			if ( ! (indexPath = [tvHistList indexPathForSelectedRow]) )
			{
				// 履歴なし時のViewの更新
				[vc refreshViewWithNoWorkItem:self.selectedUserID 
									 userName:self.selectedUserName];
				return; 
			}
		}
		else 
		{
			// 履歴なし時のViewの更新
			[vc refreshViewWithNoWorkItem:self.selectedUserID 
								 userName:self.selectedUserName];
			return; 
		}
	}
	
	// 現在選択中の履歴,ユーザを取得
	fcUserWorkItem *workItem = [_histUserItems objectAtIndex:indexPath.row];	
	// 現在選択中のViewCellを取得
	HistListTableViewCell *viewCell
    = (HistListTableViewCell*)[tvHistList cellForRowAtIndexPath:indexPath];
    
    [self checkLanguage];
    [userView setUserInfo:self.selectedUserID Language:isJapanese];
    
    // 画像がダウンロードできるまで画面のスワイプを禁止
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:YES];
#ifdef DEBUG
    NSLog(@"HistList Lock");
#endif
	// ここでHistDetailViewをセット
	[vc refreshViewWithWorkItem:workItem 
			  selectediViewCell:viewCell userName:self.selectedUserName];
    
    // 画像がダウンロードが完了したので画面のスワイプを許可
    [mainVC viewScrollLock:NO];
#ifdef DEBUG
    NSLog(@"HistList UnLock");
#endif
}


// 次のViewController(HistDetailViewController)の更新
- (void) updateNextViewController
{
	@try {
		// 次のViewController(HistListViewController)をMainVCより取得する
		MainViewController *mainVC 
			= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		HistDetailViewController* nextVC 
			= (HistDetailViewController*)([mainVC getNextControlWithSelf:self]);
		if (nextVC)
		{
			// 履歴詳細画面(HistDetailViewController)の更新
			[self refreshHistDetailVC:nextVC];
            [mainVC setScrollViewWidth:YES];
		}
	}
	@catch (NSException* exception) {
		NSLog(@"updateNextViewController: Caught %@: %@", 
			  [exception name], [exception reason]);
	}
	
}

// ユーザ代表写真を取得  -> INNER JOIN または LEFT JOINがうまくとれない: libraryの要因？
- (NSString*) getPictUrlWithHistID:(HISTID_INT)histID dbManager:(userDbManager*) dbMng
{
    // データベースをOPENする
    if (! [dbMng openDataBase])
    {  return (nil); }
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT mst_user.picture_url FROM hist_user_work"];
    [sql appendString:@"	LEFT OUTER JOIN mst_user"];
    [sql appendString:@"		ON hist_user_work.user_id = mst_user.user_id"];
    [sql appendString:@" WHERE hist_id = ?"];
         
    __block NSString *url = nil;
    
   [dbMng _selectSqlTemplateWithSql:sql 
                                bindHandler:^(sqlite3_stmt* sqlstmt)
             {  
                 sqlite3_bind_int(sqlstmt, 1, histID);
             }
                           iterationHandler:^(sqlite3_stmt* sqlstmt)
             {
                 u_int idx = 0;
                 url = [dbMng makeSqliteStmt2String:sqlstmt index:idx++];
                 
                 // 1行のみ取得
                 return (NO);
             }
             ];
    
    return (url);

}

// ユーザ代表写真を取得 
- (NSString*) getPictUrlWithUserID:(USERID_INT)userID dbManager:(userDbManager*) dbMng
{
    // データベースをOPENする
    if (! [dbMng openDataBase])
    {  return (nil); }
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT picture_url FROM mst_user"];
    [sql appendString:@"  WHERE user_id = ?"];
    
    __block NSString *url = nil;
    
    [dbMng _selectSqlTemplateWithSql:sql 
                         bindHandler:^(sqlite3_stmt* sqlstmt)
     {  
         sqlite3_bind_int(sqlstmt, 1, userID);
     }
                    iterationHandler:^(sqlite3_stmt* sqlstmt)
     {
         u_int idx = 0;
         url = [dbMng makeSqliteStmt2String:sqlstmt index:idx++];
         
         // 1行のみ取得
         return (NO);
     }
     ];
    
    // 拡張子を取り除く
    NSString *noExtUrl = [url stringByDeletingPathExtension];
    [url release];
    
    return (noExtUrl);
    
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
- (void) refreshViewWithUserID:(USERID_INT)userID userName:(NSString*)name
{
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
	// 遷移画面を本画面種別（履歴一覧）にする
	_windowView = WIN_VIEW_HIST_LIST;
	
    //2012 6/22 伊藤 対象お客様を変更した際、ビューをリセット
	MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    if(mainVC.getNowPage != 0) {
#ifdef DEBUG
        NSLog(@"WebMail check Page [%ld]", (long)mainVC.getNowPage);
#endif
        return;
    }
    
    //全てのViewにUnloadメッセージを送信
    [mainVC unloadAllViewSend];	
	if (userID == self.selectedUserID)
	{	
	// ユーザに変化なし
		// ユーザ情報Viewは必ず更新する
		[userView setUserInfo:self.selectedUserID Language:isJapanese];
		return; 
	}		
	
	// 現在選択中のユーザIDと名前を更新
	self.selectedUserID = userID;
	self.selectedUserName = name;
#ifdef DEBUG
	NSLog (@"refreshViewWithUserID start-----------------------");
#endif
	
	// ユーザ情報Viewを更新
	[userView setUserInfo:self.selectedUserID Language:isJapanese];
#ifdef DEBUG
	NSLog(@"update userInfoView");
#endif
    // メールアドレスを確認する
    userDbManager* usrDbMng = [[userDbManager alloc] init];
    mstUser *user = [usrDbMng getMstUserByID:_selectedUserID];
    [usrDbMng release];
    if ([[user email1] length]==0 ||
        ([[ShopManager defaultManager] isAccountShop] && user.shopID==0)) {
        // メールアドレスの登録が無いもしくは
        // ショップアカウントで、全店共通ユーザの場合、メール関連表示無し
        [self mailControlsEnableWithFLag:NO];
    } else {
        [self mailControlsEnableWithFLag:YES];
    }
	
	// 施術内容リストの初期化
	if (_histUserItems)
	{	[_histUserItems release]; }
	[self initHistUserItems];
#ifdef DEBUG
	NSLog(@"update initHistUserItems");
#endif
	
	// 代表写真リストの初期化
	if (_headPictureList)
	{	[_headPictureList removeAllObjects];}
	else
	{
		_headPictureList = [NSMutableDictionary dictionary];
		[_headPictureList retain];
	}
#ifdef DEBUG
	NSLog(@"update headPictureList");
#endif
	
	// スクロールViewの再描画
	[tvHistList reloadSectionIndexTitles];
	[tvHistList reloadData];
#ifdef DEBUG
	NSLog(@"update HistList scroll view");
#endif
	
	// ツールバーItemのDisEnable設定
	[self setToolBarItemEnable:NO];
	
	// 起動時の遅延処理
	[self initRunDelay];
#ifdef DEBUG
	NSLog (@"----------------------- refreshViewWithUserID end");
#endif
}

// 施術内容と表示されているセルの更新
- (void) updateHistUserItemsVisbleCells:(BOOL)isItemUpdate
{
	// 施術内容リストの初期化 
	[_histUserItems release];
	[self initHistUserItems];
	
	// 表示されているセルを全て更新する
	for(HistListTableViewCell *cell in [tvHistList visibleCells])
	{
		// 該当セルの履歴を取得
		fcUserWorkItem *cellWorkItem 
		= [_histUserItems objectAtIndex:cell.cellRow];
		
        if (![cellWorkItem.headPictureUrl isEqualToString:@""]) {
            [cell.picture setImage:
             [self makeImagePictureWithUID:cellWorkItem.headPictureUrl
                                    userID:cellWorkItem.userID]];
        } else {
            if (cellWorkItem.picturesUrls.count > 0) {
                if ([cellWorkItem.picturesUrls[0] isEqualToString:@""]) {
                    [cell.picture setImage:[UIImage imageNamed:@"noImage.png"]];
                } else {
                    [cell.picture setImage:[self makeImagePictureWithUID:cellWorkItem.picturesUrls[0] userID:cellWorkItem.userID]];
                }
            } else {
                [cell.picture setImage:[UIImage imageNamed:@"noImage.png"]];
            }
        }
        
//        if ([cellWorkItem.headPictureUrl  isEqual: @""]) {
//            [cell.picture setImage:[UIImage imageNamed:@"noImage.png"]];
//        } else {
//            NSLog(@"headpicture %@",cellWorkItem.headPictureUrl);
//            [cell.picture setImage:
//             [self makeImagePictureWithUID:cellWorkItem.headPictureUrl
//                                    userID:cellWorkItem.userID]];
//        }
		
		if (isItemUpdate)
		{
            cell.workDate.text = [cellWorkItem getNewWorkDateByLocalTime:isJapanese];
			cell.workItem.text = cellWorkItem.workItemListString;
            cell.workItem2.text = cellWorkItem.workItemListString2;
			cell.memo.text = [cellWorkItem getTopMemo];
			[cell setSectionIndex:0 index:cell.cellRow];
		}
	}
}

// Viewの日付による更新
- (void) refrshViewWithDate:(NSDate*)date
{
	// 施術内容一覧に指定日付が存在するか？
	
	// リスト上の履歴を選択
	NSUInteger idx = 0;
	NSUInteger find = NSUIntegerMax;
	for (fcUserWorkItem *item in _histUserItems)
	{
		if ([Common convDate2Uint:item.workItemDate] 
			== [Common convDate2Uint:date] )
		{ 
			find = idx;
			break;
		}
		idx++;
	}
		
	// 施術内容リストの初期化 
	[_histUserItems release];
	[self initHistUserItems];
	
	if (find == NSUIntegerMax)
	{	
		// 指定日付が存在しない場合はスクロールViewの再描画
		[tvHistList reloadSectionIndexTitles];
		[tvHistList reloadData];
	
		// 今回作成した履歴日付が最新となる場合は、最新施術内容を更新
		// TODO： 日付比較の確認
		// if ( [userView.lastWorkDate compare:newDate] == NSOrderedDescending)
		{
			[userView setUserInfo:self.selectedUserID Language:isJapanese];
		}
	
		// ツールバーItemのDisEnable設定
		[self setToolBarItemEnable:NO];
	}
	
	// 該当日付のセルを選択する
	[self selectHistOnListWithRow:(find == NSUIntegerMax)? 0 : find];
	
	// 次のViewController(HistDetailViewController)の更新
	[self updateNextViewController];
}

// メール関連のコントロール設定
- (void) mailControlsEnableWithFLag:(BOOL)isEnable
{
    NSArray *ctrls = [tlbMain items];
    NSMutableArray *ctrlsApplay = nil;
    if (!isEnable && mailItemAdd) {
        // メール一覧ボタンと未読情報を非表示にする:itemsから除去する
        ctrlsApplay = [NSMutableArray array];
        for (NSUInteger idx = 0; idx < [ctrls count]; idx++) {
            id item = [ctrls objectAtIndex:idx];
            if ( (item != btnWebMail) && (item != userStatusLabel) ) {
                [ctrlsApplay addObject:item];
            }
        }
        mailItemAdd = NO;
        [tlbMain setItems:ctrlsApplay animated:NO];
    }
    else if(isEnable && !mailItemAdd) {
        // メール一覧ボタンと未読情報を表示にする:itemsに追加する
        ctrlsApplay = [NSMutableArray arrayWithArray:ctrls];
        [ctrlsApplay insertObject:userStatusLabel atIndex:3];
        [ctrlsApplay insertObject:btnWebMail atIndex:4];
        
        mailItemAdd = YES;
        [tlbMain setItems:ctrlsApplay animated:NO];
    }
    
}

// QRCodeのコントロール設定
- (void) qrControlsEnableWithFLag:(BOOL)isEnable
{
    NSArray *ctrls = [tlbMain items];
    NSMutableArray *ctrlsApplay = nil;
    if (!isEnable && qrItemAdd) {
        // QRCodeボタンを非表示にする:itemsから除去する
//        [btnQRCode setBackButtonBackgroundImage:[UIImage imageNamed:@"toolbar_mail20x20.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        ctrlsApplay = [NSMutableArray array];
        for (NSUInteger idx = 0; idx < [ctrls count]; idx++) {
            id item = [ctrls objectAtIndex:idx];
            if ( (item != btnQRCode) ) {
                [ctrlsApplay addObject:item];
            }
        }
        qrItemAdd = NO;
        [tlbMain setItems:ctrlsApplay animated:NO];
    }
    else if(isEnable && !qrItemAdd) {
        float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

        // QRCodeボタンを表示にする:itemsに追加する
        ctrlsApplay = [NSMutableArray arrayWithArray:ctrls];

        if (iOSVersion<7.0f) {
            [ctrlsApplay insertObject:btnQRCode atIndex:5];
        } else {
            [ctrlsApplay insertObject:btnQRCode atIndex:6];
        }

        qrItemAdd = YES;
        [tlbMain setItems:ctrlsApplay animated:NO];
    }
}

// メールViewの表示設定
- (void) mailViewShowWithFlag:(BOOL)isShow
{
    // mailVC.view.hidden = !isShow;
    [mailVC notifyViewShowWithFlag:isShow];
}

// QRコードの表示設定
- (void) qrcodeViewShowWithFlag:(BOOL)isShow
{
	_isQRCodeHidden = !isShow;
	[[QRCode view]setHidden:_isQRCodeHidden];
}


#pragma mark iOS_Frmaework
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
    // 背景色の変更 RGB:D8BFD8
    self.view.backgroundColor = [UIColor colorWithRed:204/255.0f green:149/255.0f blue:187/255.0f alpha:1.0f];
//    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];
	
	// ユーザ情報Viewを表示
	userView = 
		[[UserInfoDispViewSupport alloc] initWithUserID:self.selectedUserID ownerView:self];
    userView.delegate = self;
	// 背景色：ADD8E6
	userView.view.backgroundColor = [UIColor colorWithRed:249/255.0f green:245/255.0f blue:247/255.0f alpha:1.0f];
    
	[self.view addSubview:userView.view];
    
    [userView showThumbnailViewBtn];
	// [userView release];
	
	// 施術内容リストの初期化
	[self initHistUserItems];
	
	// 遷移画面を本画面種別（履歴一覧）にする
	_windowView = WIN_VIEW_HIST_LIST;
	
	alertHistDelete = nil;
	
	_headPictureList = nil;	
	// メール・ビューの作成
    mailVC = [[WebMailListViewController alloc]
                                         initWithNibName:@"WebMailListViewController" bundle:nil];
    CGRect mf = mailVC.view.frame;
    mailVC.userId = self.selectedUserID;
    mailVC.view.frame = CGRectMake(20, 220, mf.size.width, mf.size.height);
    [self.view addSubview:mailVC.view];
    mailVC.view.hidden = YES;
    mailVC.delegate = self;
    mailItemAdd = YES;
	// QRコードの作成
	_isQRCodeHidden = YES;
	QRCode = [[QRCodeViewController alloc] initWithUserId:self.selectedUserID Delegate:self];
	QRCode.view.frame = CGRectMake(20, 220, mf.size.width, mf.size.height);
    [self.view addSubview:QRCode.view];
	QRCode.view.hidden = _isQRCodeHidden;
    
	// 起動時の遅延処理
	[self initRunDelay];
    
    // 未ログインの場合は、メール関連のコントロールを非表示にする
    if (! [AccountManager isLogined] || ![AccountManager isWebMail])
    {   [self mailControlsEnableWithFLag:NO]; }

    // QRCodedオプション契約により有効無効を設定する
    qrItemAdd = YES;
    if (![AccountManager isQrcode]) {
        [self qrControlsEnableWithFLag:NO];
    }
}

// 画面が表示される都度callされる:viewDidAppear
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear : animated];

    MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    // 言語環境設定チェック
    [self checkLanguage];

	// 遷移元の画面により処理を決める
	switch (_windowView)
	{
		case (WIN_VIEW_HIST_LIST):
		// 履歴一覧画面（本画面）

            ////2012 6/25 伊藤 履歴詳細に前画面のデータが残らないよう修正
            if ([_histUserItems count] <= 0) {
                HistDetailViewController* nextVC 
                = (HistDetailViewController*)([mainVC getNextControlWithSelf:self]);
                nextVC.selectedUserID = self.selectedUserID;
                nextVC.selectedUserName = self.selectedUserName;
                nextVC.selectedWorkItem = [[fcUserWorkItem alloc]initWithWorkItem:self.selectedUserID userName:self.selectedUserName];
                [nextVC refreshViewWithNoWorkItem:self.selectedUserID userName:self.selectedUserName];
            }
			// 履歴用のユーザ写真リストを更新する
			[self updateHistPicutures];

            // 一覧の現在選択中のrowを取得して、再選択(reloadする前にrow取得しないと選択が解除される)
            NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
            // スクロールViewの再描画
            [tvHistList reloadData];
            [self selectHistOnListWithRow:indexPath.row];
            
			break;
		case (WIN_VIEW_HIST_DETAIL):
		// 履歴詳細画面
			// 最新施術日（であった場合）の編集
			[self lastWorkItemEdit];
			// 履歴用のユーザ写真リストを更新する
			[self updateHistPicutures];
			// 最新施術内容(代表写真)の更新
            [userView setUserInfo:self.selectedUserID Language:isJapanese];
            // 施術内容と表示されているセルの更新
            [self updateHistUserItemsVisbleCells:YES];
			// 最新施術内容の更新
//            [userView setUserInfo:self.selectedUserID Language:isJapanese];
			break;
		case (WIN_VIEW_CAMERA): // mainViewControllerから飛んでこない（現在無効と思われる）
		// カメラ画面
			// 履歴用のユーザ写真リストを更新する
			[self updateHistPicutures];
			break;			
		case (WIN_VIEW_SELECT_PICTURE):
		// 選択画像一覧
			// 写真一覧で削除された場合のみ適用
			if (_isThumbnailDeleted)
			{
				// 施術内容と表示されているセルの更新
				[self updateHistUserItemsVisbleCells:NO];
			}
			// 最新施術内容の更新
			[userView setUserInfo:self.selectedUserID Language:isJapanese];
			break;
		default:
			break;
	}
	
    //2012 6/21 伊藤 連続でページめくりが起こらないように修正
	[mainVC setScrollViewWidth:YES];
	// 代表写真リストの初期化
	[self initHeadPictureList];
	// QRコードの表示フラグ初期化
	[self qrcodeViewShowWithFlag:NO];

    // メールアドレスを確認する
    userDbManager* usrDbMng = [[userDbManager alloc] init];
    mstUser *user = [usrDbMng getMstUserByID:_selectedUserID];
    [usrDbMng release];

#ifdef WEB_MAIL_FUNC
    // メール情報の更新
#ifdef DEBUG
    NSLog(@"mailVC refresh");
#endif
    if([AccountManager isWebMail] && [[user email1] length]!=0) {
		UserInfoListViewController* userVC = (UserInfoListViewController*)[mainVC getUserInfoViewController];
		if ( userVC != nil )
		{
            [self mailControlsEnableWithFLag:YES];
			NSDictionary* dicMail = [userVC getMailStatusList];
			if ( dicMail != nil && [dicMail count] > 0 )
			{
				WebMailUserStatus* userStatus = [dicMail objectForKey:[NSNumber numberWithInteger:self.selectedUserID]];
				if ( userStatus != nil )
				{
					[mailVC setUserId:self.selectedUserID];
					[mailVC finishedGetWebMailUserStatus:[userStatus userId]
												  unread:[userStatus unread]
											  userUnread:[userStatus userUnread]
												   check:[userStatus check]
									  notification_error:[userStatus notification_error]
											   exception:nil];
				}
				else
				{
					[mailVC setUserId:self.selectedUserID];
					[mailVC finishedGetWebMailUserStatus:self.selectedUserID
												  unread:0
											  userUnread:0
												   check:0
									  notification_error:0
											   exception:nil];
				}
			}
		}
    } else {
        [self mailControlsEnableWithFLag:NO];
    }
    
    if ([AccountManager isQrcode]) {
        [self qrControlsEnableWithFLag:YES];
    } else {
        [self qrControlsEnableWithFLag:NO];
    }
#ifdef DEBUG
    NSLog(@"mailVC refresh end");
#endif
#endif
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

#ifdef CALULU_IPHONE
// 縦横切り替え後のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // 新規カルテのボタンはportraitのみ有効
    btnNewkarteMake.enabled = UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
    //メール・ビューに縦横切り替えイベントを渡す
    [mailVC willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
#else
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //メール・ビューに縦横切り替えイベントを渡す
    [mailVC willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[QRCode willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
#endif

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
	
	// 代表写真リストのリリース
	[self releaseHeadPictureList];
	
	// 代表写真リストの初期化
	// _headPictureList = [NSMutableDictionary dictionary];
	// [_headPictureList retain];
}

/*
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// 代表写真リストのリリース
	[self releaseHeadPictureList];
}
*/

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	// 代表写真リストのリリース
	[self releaseHeadPictureList];
}


- (void)dealloc {
	
	if (popCtlDatePicker)
	{	[popCtlDatePicker release]; }
	
	if (alertHistDelete)
	{	[alertHistDelete release]; }
	
	[_histUserItems release];
	
	// 代表写真リストのリリース
	[self releaseHeadPictureList];
	// QRコード
	[QRCode release];

    [super dealloc];
}

#pragma mark MainViewControllerDelegate

// 新規View画面への遷移
//		return: 次に表示する画面のViewController  nilで遷移をキャンセル
- (UIViewController*) OnTransitionNewView:(id)sender
{
	//NSLog(@"OnTransitionNewView at HistListViewController");
	
	// 通常は、履歴一覧は既にload済みである
	return (nil);
	
#ifdef TRANSITION_NEW_VIEW_MODE
	
	// 選択中の履歴(cell)より履歴IDを取得する： =0：選択なし　< 0：取得失敗
	NSInteger hID;
	if ( (hID = [self getHistIdWithSelectedRow:nil]) <= 0)
	{
		NSLog(@"HistListView : OnTransitionNewView error on getHistIDWithDateUserID!");
		return (nil);	// nilで画面遷移をしない
	}
		
	HistDetailViewController *window  
		= [[HistDetailViewController alloc]
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
            initWithNibName:@"HistDetailForGrantViewController" bundle:nil];
#else
            initWithNibName:@"HistDetailViewController" bundle:nil];
#endif
	
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
	
	// 現在選択中の履歴,ユーザを渡す
	window.selectedWorkItem = [_histUserItems objectAtIndex:indexPath.row];	
	window.selectedUserID = self.selectedUserID;
	window.selectedUserName = self.selectedUserName;
	window.selectedHistID = hID;
	window.selectedViewCell 
		= (HistListTableViewCell*)[tvHistList cellForRowAtIndexPath:indexPath];
	
	// 遷移画面を履歴詳細画面にする
	_windowView = WIN_VIEW_HIST_DETAIL;
	
	return (window);
#endif
}

// 既存View画面への遷移
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
	
	// 履歴詳細画面(HistDetailViewController)の更新
	[self refreshHistDetailVC: (HistDetailViewController*)tVC];
	
	// 遷移画面を履歴詳細画面にする
	_windowView = WIN_VIEW_HIST_DETAIL;
	
	return (YES);				// 履歴選択なしでも画面遷移する
}

// 画面終了の通知
- (BOOL) OnUnloadView:(id)sender
{
	MainViewController* mainVC = (MainViewController*)sender;
	// 画面ロック状態であれば、ユーザ一覧に遷移しない
	if ([mainVC isWindowLockState] )
	{	return (NO); }
	else 
	{	return (YES); }
}

// 画面ロックモード変更
- (void) OnWindowLockModeChange:(BOOL)isLock
{
	// 画面ロックにより、セキュリティ用ツールバーを表示
	tlbSecurity.hidden = ! isLock;
}

#pragma mark ThumbnailVCDelegate

// サムネイルの削除イベント
- (void) didDeletedThumbnails:(id)sender deletedFiles:(NSArray*)files
{
	_isThumbnailDeleted = YES;
}

#pragma mark ToolbarItem

// お客様一覧に戻る
- (IBAction) OnUserListView:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
	
	// 遷移画面をユーザ一覧にする（念のため）
	_windowView = WIN_VIEW_USER_LIST;
}

// 写真一覧表示
- (IBAction) OnPictureListView:(id)sender
{
    // 画面遷移直後にサムネイル表示を行おうとすると、二重起動になることがあるため
    if(_isThumPopUpLock) return;
    _isThumPopUpLock = YES;
    
	ThumbnailViewController *thumbnailVC = [[ThumbnailViewController alloc] 
											 initWithNibName:@"ThumbnailViewController" bundle:nil];
	
	// 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
	[thumbnailVC setSelectedUserID:self.selectedUserID ];
	
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// サムネイル画面の表示
	[mainVC showPopupWindow:thumbnailVC];
	
    // iOS7で時間を置かずに initWithPicture を呼ぶと、ViewDidLoadが終了していないため
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        // thumbnailVC のViewDidLoadが終了していない場合に 300ms ウエイトを実施
        while (!thumbnailVC.isFinishDidLoad) {
            struct timespec wait;
            wait.tv_sec = 300000 / (1000 * 1000);
            wait.tv_nsec = (300000 % (1000 * 1000)) * 1000;
            nanosleep(&wait, nil);
        }
        [thumbnailVC setSelectedUserName:self.selectedUserName
                               nameColor:[Common getNameColorWithSex:userView.isSexMen]];
        thumbnailVC.delegate = self;
        [thumbnailVC release];
        _isThumPopUpLock = NO;
    });
	
	// 遷移画面を（選択）写真一覧にする
	_windowView = WIN_VIEW_SELECT_PICTURE;
	
	_isThumbnailDeleted = NO;
}

// カメラ画面へ
- (IBAction) OnCameraView:(id)sender
{
	if (! tlbSecurity.hidden)
    {   return; }       // ロック中は写真をとれない
    
    // 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
	if (! indexPath)
	{	return; }			// 念のため
	
	// 現在選択中の履歴を取得
	fcUserWorkItem *selectedWorkItem = [_histUserItems objectAtIndex:indexPath.row];
	
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
		
	// 履歴IDをデータベースよりユーザIDと当日で取得する:該当日の履歴がない場合でも作成しない
	HISTID_INT hID;
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	if ( (hID = [usrDbMng getHistIDWithDateUserID:selectedWorkItem.userID 
										 workDate:selectedWorkItem.workItemDate
								   isMakeNoRecord:NO] ) < 0)
	{
		// エラーでも続行する
		NSLog(@"HistListView : getHistIDWithDateUserID error on iPadCameraVC! but continue");
	}
	
	// 取得した履歴IDと施術日を渡す
	cameraView.histID = hID;
	cameraView.workDate = selectedWorkItem.workItemDate;
	
	
	// カメラ画面の表示
	[mainVC showPopupWindow:cameraView];
		// cameraView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		// [self presentModalViewController:cameraView animated:YES];
	
    // iOS7で時間を置かずに setSelectedUser を呼ぶと、ViewDidLoadが終了していないため
    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
	// 現在選択中のユーザIDを渡す
	[cameraView setSelectedUser:selectedWorkItem.userID 
					   userName:self.selectedUserName
					  nameColor:[Common getNameColorWithSex:userView.isSexMen]];
	
	// 現在のデバイスの向きを取得
	UIInterfaceOrientation orient = [mainVC getNowDeviceOrientation];
	// デバイスの向きを設定する
	[cameraView willRotateToInterfaceOrientation:orient duration:(NSTimeInterval)0];
    });
	
	// 遷移画面をカメラ画面にする
	_windowView = WIN_VIEW_CAMERA;
    //2012 6/22 伊藤 リークしていたため修正
    [usrDbMng release];
    [cameraView release];
}

// 履歴詳細の表示
- (IBAction) OnHistDetailView:(id)sender
{
	// 選択中の履歴(cell)より履歴IDを取得する： =0：選択なし　< 0：取得失敗
	HISTID_INT hID;
	if ( (hID = [self getHistIdWithSelectedRow:nil]) < 0)
	{
		NSLog(@"HistListView : OnHistDetailView error on getHistIDWithDateUserID!");
		return;
	}
	
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
	
	HistDetailViewController *window  
	= [[HistDetailViewController alloc]
       // 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
       initWithNibName:@"HistDetailForGrantViewController" bundle:nil];
#else
       initWithNibName:@"HistDetailViewController" bundle:nil];
#endif
	
	// 現在選択中の履歴,ユーザを渡す
	window.selectedWorkItem = [_histUserItems objectAtIndex:indexPath.row];	
	window.selectedUserID = self.selectedUserID;
	window.selectedUserName = self.selectedUserName;
	window.selectedHistID = hID;

    window.selectedViewCell = nil;
    // (visibleCellsだけを更新するようにした)
    for (HistListTableViewCell *vcell in [tvHistList visibleCells]) {
        if ([tvHistList indexPathForCell:vcell]==indexPath) {
            window.selectedViewCell
            = (HistListTableViewCell*)[tvHistList cellForRowAtIndexPath:indexPath];
            break;
        }
    }
	
	[self.navigationController pushViewController:window animated:YES];
	
	[window release];
	
	// 遷移画面を履歴詳細画面にする
	_windowView = WIN_VIEW_HIST_DETAIL;
}

// 新規カルテの作成
- (IBAction) OnNewKarteMake:(id)sender
{
	if (popCtlDatePicker)
	{
#if 1 // 不具合対応 kikuta - start - 2014/01/29
        // Popupoverが表示されていたら閉じる
        if ( [popCtlDatePicker isPopoverVisible] )
        {
            [popCtlDatePicker dismissPopoverAnimated:YES];
        }
#endif //  不具合対応 kikuta - end - 2014/01/29
		[popCtlDatePicker release];
		popCtlDatePicker = nil;
	}
	
	//日付の設定ポップアップViewControllerのインスタンス生成
	DatePickerPopUp *vcDatePicker
    = [[DatePickerPopUp alloc] initWithDatePopUpViewContoller:POPUP_NEW_HIST
                                            popOverController:nil
                                                     callBack:self
                                                     initDate:[NSDate date]];

#ifndef CALULU_IPHONE
	// ポップアップViewの表示
	popCtlDatePicker = [[UIPopoverController alloc] 
							  initWithContentViewController:vcDatePicker];
	vcDatePicker.popoverController = popCtlDatePicker;
	/*
	[popCtlDatePicker presentPopoverFromRect:tvHistList.bounds 
									  inView:tvHistList 
					permittedArrowDirections:UIPopoverArrowDirectionDown 
									animated:YES];
	 */
	[popCtlDatePicker presentPopoverFromBarButtonItem:btnNewkarteMake 
							 permittedArrowDirections:UIPopoverArrowDirectionUp 
											 animated:YES];
    
    [popCtlDatePicker setPopoverContentSize:CGSizeMake(332.0f, 364.0f) animated:NO];
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:vcDatePicker];
#endif
    //　2016/4/30 TMS 施術日→来店日に変更
    vcDatePicker.lblTitle.text = @"新規作成する来店日を設定してください";
	[vcDatePicker release];
    [popCtlDatePicker release];
	
}

// 選択カルテの削除
- (IBAction) OnDeleteKarte:(id)sender
{	
	if (! alertHistDelete)
	{
		alertHistDelete =
			[[UIAlertView alloc] initWithTitle:@"選択履歴の削除" 
									   message:@"選択した履歴を削除します。\nよろしいですか？\n(削除すると元に戻せません。)"
									  delegate:self 
							 cancelButtonTitle:@"は　い" 
							 otherButtonTitles:@"いいえ", nil];
	}
	[alertHistDelete show];
}
// メール一覧の表示
- (IBAction) OnWebMailList:(id)sender{
    mailVC.view.hidden = NO;
    [mailVC refreshWithUserId:self.selectedUserID];
}

// QRコードの表示
- (IBAction) OnQRCode:(id)sender
{
	_isQRCodeHidden = !_isQRCodeHidden;
	QRCode.view.hidden = _isQRCodeHidden;
	if ( _isQRCodeHidden == NO )
	{
		// QRコードの作成
		[QRCode createQRCodeWithUserId:self.selectedUserID Delegate:self];
	}
}

- (void)setStatusText:(NSString *)string{
    ((UIButton *)userStatusLabel.customView).titleLabel.text = string;
}
#pragma mark UITableViewDataSource

// セクション数の設定：ロード時にcallback
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// NSLog(@"called numberOfSectionsInTableView");
	return ( (_isInitRunFinish)? 1 : 0);		// 起動時の遅延処理完了を確認
}

// セクション内のセルの数の設定：ロード時にcallback
- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
	// NSLog(@"called numberOfRowsInSection at section %d", section);
	return ([_histUserItems count]);
}

// セクションのタイトルの設定：ロード時にcallback
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// NSLog(@"called titleForHeaderInSection at section %d", section);
	
	// タイトルはなし
	return (@"");
}

// セルの内容を設定：ロード時にcallbackおよびスクロール時
- (UITableViewCell *)tableView:(UITableView*)tableView 
		 cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString *CellIndentifier = @"hist_list_view_cell";
	HistListTableViewCell *cell 
		= (HistListTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIndentifier];
	if (cell == nil)
	{
		UIViewController *viewController = [[UIViewController alloc]
#ifdef CALULU_IPHONE
											initWithNibName:@"ip_HistListTableViewCell"
#else
											initWithNibName:@"HistListTableViewCell"
#endif
											bundle:nil];
		cell = (HistListTableViewCell*)viewController.view;
		[viewController release];
		
		// HistListTableViewCellの初期化
        [self tableView:tableView willDisplayCell:cell forRowAtIndexPath:0];
//        [cell initialize:self tableView:tvHistList];
		
        // Cell選択時に青色にする(iOS7対応)
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [cell.selectedBackgroundView setBackgroundColor:[UIColor colorWithRed:0 green:(122.0f/255.0f) blue:1 alpha:1]];
        cell.selectedBackgroundView.layer.cornerRadius = 10.0f;
        cell.selectedBackgroundView.layer.masksToBounds = YES;
        // 背景色：F0FFFF
        cell.backgroundColor = [UIColor colorWithRed:0.941 green:1.0 blue:1.0 alpha:1.0];
        
#ifdef DEBUG
		NSLog(@"make hist_list_view_cell at section:%ld row:%ld",
              (long)indexPath.section, (long)indexPath.row);
#endif
	}
	
    [cell initialize:self tableView:tvHistList];
    
	// 履歴の取得
	fcUserWorkItem  *workItem 
	   = [_histUserItems objectAtIndex:indexPath.row];
	
	// Cellの設定
#ifdef DEBUG
	NSLog(@" headPictureUrl=%@  workDate=%@ workItem=%@ memo=%@",
		  workItem.headPictureUrl, 
          [workItem getNewWorkDateByLocalTime:isJapanese],
		  workItem.workItemListString, 
		  [workItem getTopMemo]);
#endif
    if (![workItem.headPictureUrl isEqualToString:@""]) {
        [cell.picture setImage:
         [self makeImagePictureWithUID:workItem.headPictureUrl
                                userID:workItem.userID]];
    } else {
        if (workItem.picturesUrls.count > 0) {
            if ([workItem.picturesUrls[0] isEqualToString:@""]) {
                [cell.picture setImage:[UIImage imageNamed:@"noImage.png"]];
            } else {
                [cell.picture setImage:[self makeImagePictureWithUID:workItem.picturesUrls[0] userID:workItem.userID]];
            }
        } else {
            [cell.picture setImage:[UIImage imageNamed:@"noImage.png"]];
        }
    }
    
//    if ([workItem.headPictureUrl  isEqual: @""]) {
//        [cell.picture setImage:[UIImage imageNamed:@"noImage.png"]];
//    } else {
//        NSLog(@"headpicture %@",workItem.headPictureUrl);
//        [cell.picture setImage:
//         [self makeImagePictureWithUID:workItem.headPictureUrl
//                                userID:workItem.userID]];
//    }
		/*[self makeImagePicture: workItem.headPictureUrl
					  pictSize:cell.picture.bounds.size]];*/
	
    cell.workDate.text = [workItem getNewWorkDateByLocalTime:isJapanese];
	cell.workItem.text = workItem.workItemListString;
	cell.workItem2.text = workItem.workItemListString2; 
	cell.memo.text = [workItem getTopMemo];
	[cell setSectionIndex:indexPath.section index:indexPath.row];
	
    
	return(cell);
}

// iOS7よりTableViewCellの表示が変更になった為
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(iOSVersion<7.0) {
        HistListTableViewCell *iCell = (HistListTableViewCell *) cell;
        iCell.inset = -44.0;
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// NSLog(@" selected cell at %d", indexPath.row);
	
	// ツールバーItemのEnable設定
	[self setToolBarItemEnable:YES];
	
	// 次のViewController(履歴詳細)の更新
	[self updateNextViewController];
}

#pragma mark PopUpViewContollerBaseDelegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
	NSDate	*newDate;
	
	switch (popUpID) 
	{
		case (NSUInteger)POPUP_NEW_HIST:
		// 新規履歴PopupView
			
			// 選択された新規履歴の日付
			newDate = (NSDate*)object;
			
			// 新規履歴の作成
			[self makeNewHistWithDate:newDate isDuplicateError:YES];
						
			break;
		
		default:
			break;
	}
	
	//[popoverController release];
	// popoverController = nil;
}

#pragma mark LongTotchDelegate

// セルの長押しのイベント
-(void) OnLongTotch:(id)sender
{
#ifdef DEBUG
    NSLog(@"長押し");
#endif
    /* 2012 07/19 伊藤 長押し削除機能が誤削除の原因になっているようなのでコメントアウト
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [tvHistList indexPathForSelectedRow];
	if (! indexPath)
	{	return; }		// 選択なし
	
	HistListTableViewCell *cell = (HistListTableViewCell*)sender;
	
	// 長押ししたセルのRowと現在セルのRowが異なる場合は、削除しない
	if ( cell.cellRow != indexPath.row)
	{	
		NSLog(@"exit delete Hist work item for diffrent row -> current select:%d  delete:%d",
			 indexPath.row, cell.cellRow);
		return; 
	}
	
	// 選択の履歴を削除
	[self OnDeleteKarte:sender];
    */
}

#pragma mark UIFlickerButtonDelegate
// フリックイベント
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
				// 右方向のフリック:ユーザ一覧画面に戻る
					[self OnUserListView:sender];
					break;
				case FLICK_LEFT:
				// 左方向のフリック:履歴詳細画面に遷移
					[self OnHistDetailView:sender];
					break;
				default:
					break;
			} 
			break;
		default:
			break;
	}
}

- (void)OnSingleTap:(id)sender{
    [self OnPictureListView:sender];
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
			// 履歴詳細画面に遷移
			[self OnHistDetailView:sender];
			break;
		case FLICK_PICT_LIST_VIEW:
			// 現在選択ユーザ代表写真ボタン:写真一覧表示
			[self OnPictureListView:sender];
			break;
		default:
			break;
	}
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

// 長押しイベント
- (void)OnLongTouchDown:(id)sender
{
#ifdef DEBUG
    NSLog(@"長押し");
#endif
    /* 2012 07/19 伊藤 長押し削除機能が誤削除の原因になっているようなのでコメントアウト
	// 選択の履歴を削除
	[self OnDeleteKarte:sender];
     */
}

#pragma mark UIAlertViewDelegate
// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// 履歴の削除で「はい」のみ有効
	if (buttonIndex != 0)
	{ return;}
	
	// 選択中の履歴(cell)より履歴IDを取得する： =0：選択なし　< 0：取得失敗
	fcUserWorkItem	*userWorkItemBuf;
	HISTID_INT histID = [self getHistIdWithSelectedRow:&userWorkItemBuf];
	if (histID < 0)
	{
		[self alertDisp:@"履歴情報が取得できませんでした\n(誠に恐れ入りますが\n再操作をお願いいたします)"
			 alertTitle:@"選択履歴の削除"];
		return;
	}
	
	// データベースより履歴（とその関連情報）の削除
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	if (! [usrDbMng deleteHistWithHistID:histID] )
	{
		[self alertDisp:@"履歴の削除に失敗しました\n(誠に恐れ入りますが\n再操作をお願いいたします)"
			 alertTitle:@"選択履歴の削除"];
        [usrDbMng release];
		return;
		
	}
    
    // ここで、ユーザ代表写真を取得 (later ver 113) : 拡張子なし
        // NSString *usrPictUrl = [self getPictUrlWithHistID:histID dbManager:usrDbMng];
    NSString *usrPictUrl = [self getPictUrlWithUserID:_selectedUserID dbManager:usrDbMng];
    
    
    // Imageファイル管理のインスタンスを生成
	OKDImageFileManager *imgFileMng
        = [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
    for (NSString* fileName in userWorkItemBuf.picturesUrls)
    {
        NSString *fnNoPath
             = ([fileName length] > FILE_NAME_LEN_EXT)?
                    [fileName lastPathComponent] : [NSString stringWithString:fileName];
        
        // 履歴の削除では、ユーザ代表写真は削除しない (later ver 113)
        if ([fnNoPath hasPrefix:usrPictUrl])
        {   continue; }
        
        // ファイルの削除
		[imgFileMng deleteImageBothByRealSize:fnNoPath];
    }
    // TODO:hist idに基づく動画の全削除
    for (NSString* fileName in userWorkItemBuf.videosUrls)
    {
        // MovieResource *resource = [[MovieResource alloc] initWithUserId:self.selectedUserID fileName:fileName];
        MovieResource *resource = [[MovieResource alloc] initWithPath:fileName];
        NSLog(@"remove video %@",resource.path);
        NSError *error = nil;
        [resource remove:&error];
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }
        [resource release];
    }
		
	// 今回	削除した履歴日付が最新となる場合は、最新施術内容を更新
	if ( (userView.lastWorkDate) && 
		([userView.lastWorkDate isEqualToDate:
		  userWorkItemBuf.workItemDate]) )		
	{
		[userView setUserInfo:self.selectedUserID Language:isJapanese];
	}
	// 施術内容リストの初期化
    [_histUserItems release];
	[self initHistUserItems];
	
	// スクロールViewの再描画
	[tvHistList reloadSectionIndexTitles];
	[tvHistList reloadData];
	
	// ツールバーItemのDisEnable設定
	[self setToolBarItemEnable:NO];
    
	// リスト上の先頭履歴を選択
	[self selectHistOnListWithRow:0];

    [imgFileMng release];
    [usrDbMng release];
}

#pragma mark QRCodeViewControllerDelegate
// QRコード終了
- (void) OnQRCodeFinished:(id)sender UserId:(NSInteger)userId
{
	_isQRCodeHidden = YES;
}

@end
