    //
//  UserInfoListViewController.m
//  iPadCamera
//
//  Created by MacBook on 11/04/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "UIView+BlurEffects.h"


// #import "Common.h"
#import "defines.h"

#import "MainViewController.h"
#import "SetUpSmtpPopUp.h"

#import "UserInfoListViewController.h"

#import "HistListViewController.h"
#import "camaraViewController.h"
#import "UserTableViewCell.h"
// #import "ThumbnailViewController.h"

#import "newUserViewController.h"
#import "maintenaceViewController.h"
#import "GojyuonSearchPopup.h"
#import "DatePickerPopUp.h"
#import "UserRegistNuberSearchPopup.h"
#import "DateSearchPopup.h"

#import "userDbManager.h"
#import "mstUser.h"
#import "fcUserWorkItem.h"
#import "userFmdbManager.h"

#import "userInfoListManager.h"
#import "userInfo.h"

#import "./model/OKDImageFileManager.h"
#import "LockWindowPoupup.h"
#import "UIBottomDialogController.h"
//#import "userFmdbManager.h"

#ifdef USE_ACCOUNT_MANAGER
#import "AccountManager.h"
#import "./others/SalesDataDownloder.h"
#endif

#ifdef CALULU_IPHONE
#import "UserInfoDispViewSupport.h"
#endif

#ifdef CLOUD_SYNC
#import "SyncCommon.h"
#import "CloudSyncClientManager.h"
#import "CloudSyncUtility.h"
#import "shop/ShopManager.h"
#import "shop/ShopSelectPopup.h"

#import "WaitProcManager.h"

#import "Reachability.h"

#import "CloudSyncPictureUploadManager.h"

#import "SelectPictureViewController.h"
#import "PicturePaintViewController.h"
#import "MailSettingPopup.h"

#import "NotificationClient.h"
#import "NotificationData.h"
#import "NotificationStore.h"
#import "NotificationSyncer.h"
#import "NotificationsPopupViewController.h"
#import "NotificationForcePopupViewController.h"

#endif
#import "WebMailUserStatus.h"

#import "MailAddressSyncManager.h"
#import "BroadcastMailUserListViewController.h" // Webメール送信選択画面
#import "TemplateManagerViewController.h" // テンプレート管理画面

#import <Crashlytics/Crashlytics.h>

// SearchSentence 定義
#define SS_WORD_IDX     @"五十音で検索"
#define SS_LAST_NAME    @"お客様名で検索"
#define SS_TREAT_DAY    @"来店日で検索"
#define SS_CUSTOMER_NUM @"お客様番号一覧を表示"
#define SS_BIRTHDAY     @"生年月日で検索"
#define SS_LATEST_DAY   @"最新来店日で検索"
#define SS_MEMO         @"メモで検索"
//2016/4/9 TMS 顧客検索条件追加
#define SS_MAIL_ERROR   @"送信メール(エラー) で検索"
#define SS_MAIL_UNREAD  @"送信メール（未読）で検索"
#define SS_MAIL_TENPO_UNREAD   @"受信メール（未読）で検索"
#define SS_MAIL_TENPO_ANSWER   @"受信メール(対応待ち) で検索"
#define SS_CANCEL       @"キャンセル"
// 2016/8/17 担当者検索機能の追加
#define SS_RESPONSIBLE    @"担当者名で検索"

#define ACCOUNT_ID_SAVE_KEY		@"accountIDSave"		// アカウントIDの保存用Key
#define ACCOUNT_PWD_SAVE_KEY	@"accountPwdSave"		// アカウントパスワードの保存用Key

//性別表示用の文字と色
#define STRING_SEX_FEMALE (isJapanese ? @"女性" : @"FEMALE")
#define STRING_SEX_MALE (isJapanese ? @"男性" : @"MALE")
#define COLOR_SEX_FEMALE [UIColor colorWithRed:0.93 green:0.43 blue:0.60 alpha:1.0]
#define COLOR_SEX_MALE [UIColor colorWithRed:0.08 green:0.60 blue:0.87 alpha:1.0]
#define HEADER_TABLE_COLOR [UIColor colorWithRed:41/255.0 green:128/255.0 blue:185/255.0 alpha:1.0]
#define TABLE_CELL_COLOR [UIColor colorWithRed:228/255.0 green:241/255.0 blue:254/255.0 alpha:1.0]

// 2016/7/17 TMS 参照モード追加対応
#define USR_EDIT_MODE_TAG 1
#define USR_VIEW_MODE_TAG 2

#define APP_STORE_SAMPLE_DEF_KEY	@"appstore_sample_download"
#define APP_STORE_SAMPLE_DB_DEF_KEY	@"appstore_sample_db_download"
#define SECRET_MEMO_PWD_KEY			@"secret_memo_pwd_key"		// シークレットメモパスワード
#define SECRET_MEMO__PWD_INIT_VALUE			@"0000"						// シークレットメモパスワード初期値

typedef enum
{
    SEARCH_WORD_IDX,            // 五十音検索
    SEARCH_LAST_NAME_IDX,       // 姓名検索
    SEARCH_TREAT_DAY_IDX,       // 施術日検索
    SEARCH_CUSTOMER_NUM_IDX,    // お客様番号一覧
    SEARCH_BIRTHDAY_IDX,        // 生年月日検索
//    SEARCH_LATEST_DAY_IDX,      // 最新施術日検索
    SEARCH_MEMO_IDX,            // メモ検索
    SEARCH_MAIL_ERROR_IDX,      // メール送信エラー検索
    SEARCH_MAIL_UNREAD_IDX,     // メール未読検索
    //2016/4/9 TMS 顧客検索条件追加
    SEARCH_MAIL_TENPO_UNREAD_IDX,//店舗側メール未読検索
    SEARCH_MAIL_TENPO_ANSWER_IDX,//要対応メール未読検索
    SEARCH_CANCEL_IDX,           // 検索キャンセル
    // 2016/8/17 担当者検索機能の追加
    SEARCH_RESPONSIBLE_IDX       // 担当者名検索
} SEARCH_KIND_INDEX;



@interface BtnGojyuonSearch () {
    BOOL _searching;
    UIImage* _buttonImage;
}
@end
@implementation BtnGojyuonSearch
- (BOOL)searching {
    return _searching;
}
- (void)setSearching:(BOOL)searching {
    _searching = searching;
    if (searching) {
        self.selected = YES;
        self.backgroundColor = [UIColor colorWithRed:0.87 green:0.91 blue:0.94 alpha:1];
        _buttonImage = self.imageView.image;
        [self setImage:nil forState:UIControlStateNormal];
        self.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    else {
        self.selected = NO;
        self.backgroundColor = [UIColor clearColor];
        if (_buttonImage != nil) {
            [self setImage:_buttonImage forState:UIControlStateNormal];
            _buttonImage = nil;
        }
        self.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
    }
}
@end



@interface UserInfoListViewController (private_methods)

#ifdef USE_ACCOUNT_MANAGER
// サンプルデータをダウンロード（販売店様の場合のみ）
- (void) _sampleDataDownload;
#endif

- (void) updateWebMailBlockUserDB;
@end

@implementation UserInfoListViewController

@synthesize userEditerSheet;

// camaraViewController *cameraView;
#pragma mark local_Methods

// 最新履歴の更新：ユーザ詳細情報とユーザ一覧の最新日付と最新施術内容を更新する
- (void) histWorkItemUpdate
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [myTableView indexPathForSelectedRow];
	if (! indexPath)
	{	return; }			// 念のため
	
	// ユーザ情報の取得
	userInfo  *info 
	= [userInfoList getUserInfoBySection:
	   (NSInteger)indexPath.section rowNum:(NSInteger)indexPath.row];
	
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	
	//施術内容Itemを取得
    // 2016/6/1 TMS メモリ使用率抑制対応
    fcUserWorkItem *workItem = [[fcUserWorkItem alloc] initWithWorkItem:currentUserId userName:[info getUserName]];
    workItem = [usrDbMng getUserWorkItemByID:currentUserId
                                    userName:[info getUserName]:workItem];
	//fcUserWorkItem *workItem
	//= [usrDbMng getUserWorkItemByID:currentUserId userName:[info getUserName]];
	
	// リストのユーザ情報で最新施術日付を更新する
	info.lastWorkDate = workItem.workItemDate;
	
	// ユーザ一覧の現在選択されているcellを更新する
	UserTableViewCell *cell 
	= (UserTableViewCell*)[myTableView cellForRowAtIndexPath:indexPath];
    cell.lastDate.text = [info getLastWorkDate:isJapanese];
    cell.birthday.text = [NSString stringWithFormat:@"生年月日　%@",[info getBirthDayByLocalTimeAD:isJapanese]];
    [cell setLanguage:isJapanese];
	
	// ユーザ詳細情報の更新
	[self updateSelectedUserByWorkItem:workItem];
    // 2016/6/1 TMS メモリ使用率抑制対応
    [usrDbMng release];
    [workItem release];
}

// フリッカーボタンの初期化
- (void) flickerButtonSetup
{
	[btnPictuerView initialize:self];
	[btnUserInfo initialize:self];
}

// 写真一覧表示
- (void) OnPictureListView:(id)sender
{
	ThumbnailViewController *thumbnailVC = [[ThumbnailViewController alloc] 
#ifdef CALULU_IPHONE
											initWithNibName:@"ip_ThumbnailViewController" bundle:nil];
#else
											initWithNibName:@"ThumbnailViewController" bundle:nil];
#endif
	
	// 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
	[thumbnailVC setSelectedUserID:currentUserId];
	
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// サムネイル画面の表示
	[mainVC showPopupWindow:thumbnailVC];
	
	[thumbnailVC setSelectedUserName:lblName.text nameColor:[Common getNameColorWithSex:([lblSex.text isEqualToString:STRING_SEX_MALE])]];
    thumbnailVC.delegate = self;
    [thumbnailVC release];
	
	// 遷移画面を（選択）写真一覧にする
	_windowView = WIN_VIEW_SELECT_PICTURE;
    
    _isThumbnailDeleted = NO;

}

// 代表写真リストの初期化
// 2016/6/7 TMS メモリ使用率抑制対応
/*
- (void) initHeadPictureList
{
	if (_headPictureList)
	{ return; }

	_headPictureList = [NSMutableDictionary dictionary];
	[_headPictureList retain];

}*/

// リスト上の指定ユーザを選択
- (void) selectUserOnListWithIndexPath:(NSUInteger)row section:(NSUInteger)section
{
	// ユーザ情報リストに存在するかを確認
    NSLog(@"chuan mo lun");
	if ([userInfoList getUserNum:section] <= 0)
	{	return; }
	
	NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
	[myTableView selectRowAtIndexPath:path animated:NO 
					   scrollPosition:UITableViewScrollPositionTop];
	[myTableView.delegate tableView:myTableView 
			didSelectRowAtIndexPath:path];
}

// 次のViewController(HistListViewController)の更新
- (void) updateNextViewController:(BOOL)isEnforce
{
#ifdef DEBUG
    NSLog(@"CURRENT USER ID : %d  LBLNAME : %@",currentUserId,lblName.text);
#endif
	@try {
		
		// 次のViewController(HistListViewController)をMainVCより取得する
		MainViewController *mainVC 
			= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		HistListViewController* nextVC 
			= (HistListViewController*)([mainVC getNextControlWithSelf:self]);
		if (nextVC)
		{
			// 強制更新
			if (isEnforce)
			{ nextVC.selectedUserID = USERID_INTMIN; }
			
			// Viewの更新
			[nextVC refreshViewWithUserID:currentUserId userName:lblName.text];
		}
	}
	@catch (NSException* exception) {
		NSLog(@"updateNextViewController: Caught %@: %@", 
			  [exception name], [exception reason]);
	}
	
}

// 次のViewController(HistListViewController)の表示セルの更新
- (void) updateNextViewControllerVisbleCells
{
	@try {
		
		// 次のViewController(HistListViewController)をMainVCより取得する
		MainViewController *mainVC 
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		HistListViewController* nextVC 
            = (HistListViewController*)([mainVC getNextControlWithSelf:self]);
		if (nextVC)
		{
			// 表示セルの更新
			[nextVC updateHistUserItemsVisbleCells:NO];
		}
	}
	@catch (NSException* exception) {
		NSLog(@"updateNextViewController: Caught %@: %@", 
			  [exception name], [exception reason]);
	}
	
}

//指定ユーザをTableView上で選択する
- (void)selectedUserOnTableViewWithUID:(NSInteger)userID
{
	NSIndexPath *indexPath = [userInfoList getIndexPathWithUserID:userID];
	
	if (! indexPath)
	{	return; }		// 該当ユーザIDなし
	
	// まずはcellを選択する
	[myTableView selectRowAtIndexPath:indexPath animated:YES 
					   scrollPosition:UITableViewScrollPositionMiddle];
	
	// 選択イベント
	[myTableView.delegate tableView:myTableView didSelectRowAtIndexPath:indexPath];
}

// ひらがなと漢字を判別する
- (SELECT_JYOUKEN_KIND)discrimentKanji:(NSString*)text
{
	// ひらがなの正規表現
	static NSString *regEx = @"[あ-ん]";
	
	// 正規表現検索
	NSRange range = [text rangeOfString:regEx
								options:NSRegularExpressionSearch];
	
	// != NSNotFoundにてtextをひらがなとする
	return ( (range.location != NSNotFound)?
				SELECT_FIRST_NAME_KANA : SELECT_FIRST_NAME );
}

// 一覧の先頭のユーザを選択
- (void) selectListTopUser
{
	NSIndexPath* topPath = [userInfoList getListTopIndexPath];
	if (topPath){
		[self selectUserOnListWithIndexPath:topPath.row 
									section:topPath.section];
	}
	else {
		[self selectUserOnListWithIndexPath:0 section:0];
	}
}

#ifdef TRIAL_VERSION

// 確認ダイアログを表示してCaLuLuホームページを開く
- (void)openCaLuLuHpWithMsg
{
	if (! alertOpenHomePage)
	{
		alertOpenHomePage 
			= [[UIAlertView alloc]
			   initWithTitle:@"ご案内"
			   message:@"お試し版では\n新規にお客様の登録ができません。\n製品版のご案内のため\nABCarteホームページを開きます。"
			   delegate:self
			   cancelButtonTitle:@"OK"
			   otherButtonTitles:@"キャンセル", nil
			   ];
	}
	[alertOpenHomePage show];
	// [alertOpenHomePage release];
}
#endif

// 最新施術内容のタイトルを設定
-(void) setLastWorkTitle
{
	// メモのラベルを設定ファイルから読み込む
	NSDictionary *lables = [Common getMemoLabelsFromDefault];
	
	lblLastWorkTitle.text  = [NSString stringWithFormat:@"%@",
										[lables objectForKey:@"memo1Label"]];
}
#ifdef USE_ACCOUNT_MANAGER
// アカウントログインボタンの表示
- (void) accountLoginBtnShow
{
	// ログイン済みであればボタンを表示しない
	btnAccountLogin.hidden = [AccountManager isLogined];
#ifdef CLOUD_SYNC
#ifndef FOR_SALES
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    // サンプルダウンロードが完了
    // && 前回同期に失敗していない && セキュリティロックでない場合、Cloud同期を行う
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"appstore_sample_download"] &&
        ![CloudSyncClientManager isSyncProcRunnig] &&
        ![mainVC isWindowLockStateALL]) {

        // 2015/05/19 #257 により一旦自動同期を停止
//        [self _doCloud2Sync];
    }
#endif // FOR_SALES
    // Cloudと同期ボタンを表示
    btnMnuCloudSync.hidden = ! [AccountManager isCloud];
#endif
    btnAddUser.hidden = ! [AccountManager isLogined];
}

- (void)_accountLoginBtnShow:(NSNotification *) notification
{
	// アカウントログインボタンの表示
	[self accountLoginBtnShow];
    
    MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    UIViewController *vc = nil;
    
#ifndef AIKI_CUSTOM         //  BMKバージョンは無効になることはない（常に有効）
    // サーバ側のオプションで有効・無効を決定するので、機能を有効にしておく
    // camaraViewControllerの取得
    camaraViewController *cameraView
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView;
    if (cameraView)
    {   [cameraView setWebCameraEnableWithIsFlag:YES]; }
    
#endif
    
    // Mailボタンをここで無効にする
    vc = [ mainVC getVC4ViewControllersWithClass:[SelectPictureViewController class]];
    if (vc)
    {   [(SelectPictureViewController*)vc setMailEnableIsFlag:NO]; }
    vc = [ mainVC getVC4ViewControllersWithClass:[PicturePaintViewController class]];
    if (vc)
    {   [(PicturePaintViewController*)vc setMailEnableIsFlag:NO]; }
    
    // 履歴一覧のメール機能も無効にする
    vc = [ mainVC getVC4ViewControllersWithClass:[HistListViewController class]];
    if (vc)
    {   [(HistListViewController*)vc mailControlsEnableWithFLag:NO]; }

    // QRCode機能も無効にする
    vc = [ mainVC getVC4ViewControllersWithClass:[HistListViewController class]];
    if (vc)
    {   [(HistListViewController*)vc qrControlsEnableWithFLag:NO]; }
    
    // アカウント継続確認エラーで参照画像表示ボタンを非表示
    btnReferenceShow.hidden = YES;
}

// #define SAMPLE_DOWNLOAD_DEBUG

/**
 * アカウントIDの種別チェック
 * "D"で終了するアカウントIDはABCarteForSales専用のIDとするため通常のABCarte,Grant版は使用不可とする
 * "G"で終了するアカウントIDはABCarteForGrant専用のIDとするため通常のABCarte,Demo版は使用不可とする
 */
- (BOOL) checkAccountKind:(NSString *)accountID
{
// 2016/3/24 TMS Grant版対応
#ifndef FOR_SALES
    if([accountID hasSuffix:@"D"] || [accountID hasSuffix:@"d"])
        return NO;
#endif
#ifndef FOR_GRANT
    if([accountID hasSuffix:@"G"] || [accountID hasSuffix:@"g"])
        return NO;
#endif
    
    return YES;
}

// アカウントログインの実施
- (void) doAccountLogin:(NSArray *) array
{
    if (![self checkAccountKind:[array objectAtIndex:0]]) {
        [Common showDialogWithTitle:@"アカウントIDエラー"
                            message:[NSString stringWithFormat:@"アカウント [%@] はこのアプリでは使用いただけません", [array objectAtIndex:0]]];
        
        // 2015/12/22 TMS 初回起動時ログイン必須対応
        [self _showAccontLoginPopUp];
        
        return;
    }
#ifndef SAMPLE_DOWNLOAD_DEBUG
    //2015/10/28 TMS 店舗階層を保持しているアカウントのログイン失敗時対応
    AccountManager *actMng = [[AccountManager alloc]initWithServerHostName:ACCOUNT_HOST_URL];
 #ifdef CLOUD_SYNC
    [actMng isAccountForShop:[array objectAtIndex:0]];
    
    NSString *shopID = @"";
    NSString *shopPwd = @"";
    if ([array count] > 2){
        shopID = [array objectAtIndex:2];
        shopPwd = [array objectAtIndex:3];
    }
    // 店舗アカウントありの場合で店舗アカウントが入力されていない場合は、エラー表示
    if ((actMng.isAccountShop) &&
        ( ([shopID length] <= 0) || ([shopPwd length] <= 0) ) )
    {
        [Common showDialogWithTitle:@"入力項目が不足です"
                            message:@"店舗情報が入力されていません\n再度ログイン願います"];
        [actMng release];
        
        // 2015/12/22 TMS 初回起動時ログイン必須対応
        [self _showAccontLoginPopUp];
        
        return;
    }
    // 店舗アカウントにログインする
    if (actMng.isAccountShop)
    {
        ACCOUNT_RESPONSE response = [actMng shopAccountWithAccountID:[array objectAtIndex:0]
                                                              shopID:shopID shopPassWord:shopPwd];
        BOOL loginOk = (response == ACCOUNT_RSP_SUCCESS);
        if (loginOk)
        {
            // ログイン完了で店舗IDとユーザID基準数を保存する
            ShopManager *shopMng = [ShopManager defaultManager];
            [shopMng setAccountShopID:[shopID intValue]
                              shopPwd:shopPwd
                           userIDBase:[actMng UserIDBaseAtShop]];
        }else{
            [Common showDialogWithTitle:@"入力項目に誤りがあります"
                                message:@"店舗ID、または店舗パスワードに誤りがあります"];
            [actMng release];
            
            // 2015/12/22 TMS 初回起動時ログイン必須対応
            [self _showAccontLoginPopUp];
            
            return;
        }
    }
    else {
        ShopManager *shopMng = [ShopManager defaultManager];
        [shopMng resetAccountShopID];
    }
#endif
    //ログインする
    ACCOUNT_RESPONSE response = [actMng loginWithAccountID:[array objectAtIndex:0]
                                                  passWord:[array objectAtIndex:1] ];
    
    BOOL loginOk = (response == ACCOUNT_RSP_SUCCESS) || (response == ACCOUNT_RSP_DUPLICATE_LOGIN);
    

    //#ifdef CLOUD_SYNC
    if (loginOk) {
        
        // Web参考資料ボタン表示・非表示
        NSString *refurl = [AccountManager isReference];
        if(refurl==NULL)
            btnReferenceShow.hidden = YES;
        else
            btnReferenceShow.hidden = NO;
        
        // 一斉送信ボタンの表示
        [btnBroadcastMail setHidden:![AccountManager isGroupMail]];
    }

/*
	AccountManager *actMng = [[AccountManager alloc]initWithServerHostName:ACCOUNT_HOST_URL];
	ACCOUNT_RESPONSE response = [actMng loginWithAccountID:[array objectAtIndex:0]
												  passWord:[array objectAtIndex:1] ];
	
	BOOL loginOk = (response == ACCOUNT_RSP_SUCCESS) || (response == ACCOUNT_RSP_DUPLICATE_LOGIN);

#ifdef CLOUD_SYNC
    if (loginOk) {
        NSString *shopID = @"";
        NSString *shopPwd = @"";
        if ([array count] > 2){
            shopID = [array objectAtIndex:2];
            shopPwd = [array objectAtIndex:3];
        }
        // 店舗アカウントありの場合で店舗アカウントが入力されていない場合は、エラー表示
        if ((actMng.isAccountShop) &&
            ( ([shopID length] <= 0) || ([shopPwd length] <= 0) ) )
        {
            [Common showDialogWithTitle:@"入力項目が不足です" 
                                 message:@"店舗情報が入力されていません\n再度ログイン願います"];
            [actMng release];
            return;
        }
        // 店舗アカウントにログインする
        if (actMng.isAccountShop)
        {
            response = [actMng shopAccountWithAccountID:[array objectAtIndex:0] 
                                                 shopID:shopID shopPassWord:shopPwd];
            loginOk = (response == ACCOUNT_RSP_SUCCESS);
            if (loginOk)
            {
                // ログイン完了で店舗IDとユーザID基準数を保存する
                ShopManager *shopMng = [ShopManager defaultManager];
                [shopMng setAccountShopID:[shopID intValue]
                                  shopPwd:shopPwd
                               userIDBase:[actMng UserIDBaseAtShop]];
            }
        }
        else {
            ShopManager *shopMng = [ShopManager defaultManager];
            [shopMng resetAccountShopID];
        }

        // Web参考資料ボタン表示・非表示
        NSString *refurl = [AccountManager isReference];
        if(refurl==NULL)
            btnReferenceShow.hidden = YES;
        else
            btnReferenceShow.hidden = NO;
        
        // 一斉送信ボタンの表示
        [btnBroadcastMail setHidden:![AccountManager isGroupMail]];
    }

    
#endif
*/
    if (loginOk)
    {
#ifndef AIKI_CUSTOM
        // 整体向けアカウントの場合は、ここでcameraViewのWebカメラボタンを有効にする:BMKバージョンは常に有効
        if ([AccountManager isAccountManipulative])
        {
            // camaraViewControllerの取得
            camaraViewController *cameraView
                = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView;
            
            if (cameraView)
            {
                [cameraView setWebCameraEnableWithIsFlag:YES];
                cameraView.reInit = YES;
            }
        }
#endif
        // Mail利用可アカウントの場合(ログイン済み)は、ここでMailボタンを有効にする
        if([AccountManager isWebMail])
        {
            MainViewController *mainVC
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
            UIViewController *vc
            = [ mainVC getVC4ViewControllersWithClass:[SelectPictureViewController class]];
            if (vc)
            {   [(SelectPictureViewController*)vc setMailEnableIsFlag:YES]; }
            
            MainViewController *mainVC2
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
            UIViewController *vc2
            = [ mainVC2 getVC4ViewControllersWithClass:[PicturePaintViewController class]];
            if (vc2)
            {   [(PicturePaintViewController*)vc2 setMailEnableIsFlag:YES]; }
            
            // 履歴一覧のメール機能も有効にする
            vc = [ mainVC getVC4ViewControllersWithClass:[HistListViewController class]];
            if (vc)
            {   [(HistListViewController*)vc mailControlsEnableWithFLag:YES]; }
        }
        // QRCodeオプション契約済の場合、ここでQRCodeボタンを有効にする
        if ([AccountManager isQrcode]) {
            MainViewController *mainVC
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;

            // QRCode機能も有効にする
            UIViewController *vc = [ mainVC getVC4ViewControllersWithClass:[HistListViewController class]];
            if (vc)
            {   [(HistListViewController*)vc qrControlsEnableWithFLag:YES]; }
        }
    }
    
    UIAlertView *alertView = [[UIAlertView alloc]
#ifdef VER_113_LATER
							  initWithTitle:(loginOk)? @"ログインが完了しました" : nil
							  message:[actMng getResponseMessage:@"ご登録いただきまして\n誠にありがとうございます\nABCarteの全ての機能が\nご利用いただけます"
													errorMessage: @"ログインできませんでした"]
#else
                              initWithTitle:(loginOk)? @"アカウント情報" : nil
							  message:[actMng getResponseMessage:@"アカウントは\n正常に認証いたしました\n誠にありがとうございました" 
													errorMessage: @"アカウントの認証が\nできませんでした"]
#endif
							  delegate:(loginOk)?  self : nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil
							  ];
	alertView.tag = USER_INFO_LOGIN_OK_DIALOG;
    [alertView show];
	[alertView release];	 

	[actMng release];
	
	if (loginOk)
	{
        // 2015/12/22 TMS 初回起動時ログイン必須対応
        if(backImgView != nil){
            //UIImageView解放
            backImgView.image = nil;
            backImgView.layer.sublayers = nil;
            [backImgView removeFromSuperview];
            backImgView = nil;
        }
        
        if(dmyBtn != nil){;
            [dmyBtn removeFromSuperview];
            dmyBtn = nil;
        }
        
		// 正常にログインが完了すれば、ボタンを隠す
		btnAccountLogin.hidden =YES;
        
        //2012 07/19 伊藤 ログイン成功した場合、次回からサンプルデータをダウンロードしない
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"appstore_sample_download"];
        [defaults setBool:YES forKey:@"appstore_sample_db_download"];
#ifdef CLOUD_SYNC
        if([AccountManager isCloud]) {
            // Cloudと同期ボタンを表示
            btnMnuCloudSync.hidden = NO;
            
            // ログイン完了で同期する
#ifndef FOR_SALES
            isSyncNomal = YES;
            [self _doCloud2Sync];
#endif
        }
#endif
        btnAddUser.hidden = NO;

        // 販売店様の場合は、サンプルデータをダウンロード
        /*dispatch_async(dispatch_get_main_queue(), ^{
            [[NSRunLoop currentRunLoop]  
                runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];
            [self _sampleDataDownload];
        });*/
        if ([AccountManager isWebMail]) {
            // バッヂを取得
            GetWebMailUserStatuses *getStatuses = [[GetWebMailUserStatuses alloc] initWithDelegate:self];
            [getStatuses getStatuses];
        }
    }else{
        // 2015/12/22 TMS 初回起動時ログイン必須対応
        [self _showAccontLoginPopUp];
    }
#else
    // 販売店様の場合は、サンプルデータをダウンロード
    dispatch_async(dispatch_get_main_queue(), ^{
        /*[[NSRunLoop currentRunLoop]
            runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];*/
        [self _sampleDataDownload];
    });
#endif
}

// サンプルデータをダウンロード前の接続確認
- (void) _sampleDataDownload{
#ifdef CLOUD_SYNC
    // クラウド版はクラウドのデータベースを使用するため処理を行わない
    return;
#endif
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if  ([defaults stringForKey:@"accountIDSave"] == nil)
    {   return; }     // 未ログイン
    
    NSString *accountID = [defaults stringForKey:@"accountIDSave"];
    
    // 最後文字が販社様アカウントかを最後の文字で判定
    BOOL stat = ( ([accountID hasSuffix: SALES_ACCOUNT_LAST_WORD]) ||
                 ([accountID hasSuffix: SALES_ACCOUNT_LAST_WORD_SMALL]) );
    if (!stat) {
        return;
    }    
    stat = ( ([defaults objectForKey:APP_STORE_SALES_DEF_KEY] != nil) &&
                 ([defaults boolForKey:APP_STORE_SALES_DEF_KEY]) );
    if (stat) {
        return;
    }  
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"販社用データのダウンロード"
                                                   message:@"この作業は初回のみ有効です\nダウンロードはWiFiでの接続を\n推奨します。"
                                                  delegate:self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
    alert.tag = APP_STORE_SALES_CHECK_DIALOG;
    [alert show];
    [alert release];
}

// サンプルデータをダウンロード（販売店様の場合のみ）
- (void) __sampleDataDownload
{
    BOOL isRefresh = NO;
    SalesDataDownloder *salesData = [[SalesDataDownloder alloc] init];
    BOOL stat = [salesData doDownloadWithStartHandler:^(void)
     {
         // メッセージPopup windowの表示
         [MainViewController showMessagePopupWithMessage:@"サンプルデータをダウンロードします....."];
     }
                           comleteHandler:^(BOOL completeStat)
     {
         // メッセージPopup windowを閉じる
         [MainViewController closeBottomModalDialog];
         
         if (! completeStat)
         {
             UIAlertView *alertView = [[UIAlertView alloc]
                                       initWithTitle:@"サンプルデータの一部がダウンロードできませんでした"
                                       message:@"ネットワークの接続を確認して\nお客様情報一覧を\n再表示してください"
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil
                                       ];
             [alertView show];
             [alertView release];
         }
         else
         {
             // UserInfoListVCのrefresh:初期化
             [self refreshUserInfoListView];
             // 次のViewController(HistListViewController)の更新
             [self updateNextViewController:YES];
         }
     }
                                        isInitRehresh:&isRefresh];
    
    [salesData release];
    
    if (! stat)
    {
        // メッセージPopup windowを閉じる
        [MainViewController closeBottomModalDialog];
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"サンプルデータがダウンロードできませんでした"
                                  message:@"ネットワークの接続を確認して\nお客様情報一覧を\n再表示してください"
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil
                                  ];
        [alertView show];
        [alertView release];
    }
    else if (isRefresh)
    {
        // UserInfoListVCのrefresh:初期化
        [self refreshUserInfoListView];
    }
}

#endif

#ifdef CALULU_IPHONE

// タップジェスチャーのセットアップ
- (void) _setUpTapGesture
{
    // ダブルタップジェスチャーの設定(for iPhone)
	UITapGestureRecognizer *tapGesture 
    = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnUserTableViewCellDoubleTap:)];
	tapGesture.numberOfTouchesRequired = 1;		// 指1本
    tapGesture.numberOfTapsRequired = 2;        // ダブルタップ
	[self.view addGestureRecognizer:tapGesture];
	[tapGesture release];
}

// ユーザ情報の操作のアクションシートを表示
- (void) _userInfoOprActionSheetDisp
{
    // portraite以外では表示しない
    if (! [MainViewController isNowDeviceOrientationPortrate] )
    {   return; }
    
    UIActionSheet *sheet;
    
    if (currentUserId > 0)
    {
        NSArray *names= [lblName.text componentsSeparatedByString:@"　"];
                          // [NSCharacterSet characterSetWithCharactersInString:@"　"]];
        NSString *name = [NSString stringWithFormat:@"%@ %@", 
                          ([names count] > 0)? [names objectAtIndex:0] : @" ", 
                          ([names count] > 1)? [names objectAtIndex:1] : @" "];
        NSString *tl0 = [NSString stringWithFormat:@"%@様の詳細を表示", name];
        NSString *tl1 = [NSString stringWithFormat:@"%@様の情報を編集", name];
        NSString *tl3 = [NSString stringWithFormat:@"%@様の情報を削除", name];
    
        sheet =
        [[UIActionSheet alloc] initWithTitle:@"内容を選択してください" 
                                    delegate:self 
                           cancelButtonTitle:@"キャンセル"
                      destructiveButtonTitle:nil
                           otherButtonTitles:@"新規お客様の作成", tl0, tl1, tl3, nil];
       
        
        sheet.tag = 10;
        
        // 削除ボタンを赤色に
        sheet.destructiveButtonIndex = 3;
    }
    else 
    {
        sheet =
        [[UIActionSheet alloc] initWithTitle:@"内容を選択してください" 
                                    delegate:self 
                           cancelButtonTitle:@"キャンセル"
                      destructiveButtonTitle:nil
                           otherButtonTitles:@"新規お客様の作成", nil];
        sheet.tag = 19;

    }
        
    [sheet autorelease];
    sheet.actionSheetStyle = UIActionSheetStyleDefault;
    
    
    // アクションシートを表示する
    [sheet showInView:self.view];
    // [sheet showFromRect:btnGojyuonSearch.bounds inView:btnGojyuonSearch animated:YES];
    
}
#endif

#ifndef CALULU_IPHONE

// ユーザ情報の操作のアクションシートを表示
- (void) _userInfoOprActionSheetDisp
{
    UIActionSheet *sheet;
    NSArray *names= [lblName.text componentsSeparatedByString:@"　"];
    // [NSCharacterSet characterSetWithCharactersInString:@"　"]];
    NSString *name = [NSString stringWithFormat:@"%@ %@",
                      ([names count] > 0)? [names objectAtIndex:0] : @" ",
                      ([names count] > 1)? [names objectAtIndex:1] : @" "];
    NSString *tl1 = [NSString stringWithFormat:@"%@様の情報を編集", name];
    NSString *tl3 = [NSString stringWithFormat:@"%@様の情報を削除", name];

    if (iOSVersion<8.0) {
        if (currentUserId > 0)
        {
            // (ログインしていない or WebMail契約していない) ならばサーバ設定ボタンを表示しない
            sheet =
            [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                        delegate:self
                               cancelButtonTitle:@"キャンセル"
                          destructiveButtonTitle:nil
                               otherButtonTitles:tl1, tl3, @"キャンセル", nil];
            
            sheet.cancelButtonIndex = 2;
            
            // 削除ボタンを赤色に
            sheet.destructiveButtonIndex = 1;
            
            sheet.tag = 10;
        }
        else
        {
            sheet =
            [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                        delegate:self
                               cancelButtonTitle:@"キャンセル"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"キャンセル", nil];
            sheet.tag = 19;
            sheet.cancelButtonIndex = 0;
        }
        
        [sheet autorelease];
        sheet.actionSheetStyle = UIActionSheetStyleDefault;
        
        
        // アクションシートを表示する
        // [sheet showInView:self.view];
        [sheet showFromRect:btnMnuEditer.bounds inView:btnMnuEditer animated:YES];
        
        self.userEditerSheet = sheet;
    } else {
#ifdef SUPPORT_IOS8
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"内容を選択してください"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:tl1
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // お客様情報の編集
                                                    [self OnUserInfoUpadte:btnUserInfoEdit];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:tl3
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
                                                    // お客様情報の削除
                                                    [self OnUserInfoDelete:btnUserInfoDelete];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"キャンセル"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    
                                                }]];
        // 吹き出し元の設定
        UIPopoverPresentationController *pop = [alert popoverPresentationController];
        pop.sourceView = btnMnuEditer;
        pop.sourceRect = btnMnuEditer.bounds;

        [self presentViewController:alert animated:YES completion:nil];
#endif
    }
}

#endif

// その他の情報を表示
- (void) _otherInfoActionSheetDisp
{
    UIActionSheet *sheet;
    
    NSString *tl0 = @"メール情報の設定";
#ifdef DEF_ABCARTE
    NSString *tl1 = @"ABCarte のHPを参照";
#else
    NSString *tl1 = @"CaLuLu のHPを参照";
#endif
    NSString *tl2 = @"アプリの設定";
    NSString *tl3 = @"店舗の選択";
    NSString *tl4 = (isJapanese)? @"Language select" : @"言語環境の設定";
    NSString *tl5 = @"お知らせを閲覧する";
#ifndef FOR_SALES
    NSString *tl6 = @"ログアウト";
#endif
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *shopID = [defaults stringForKey:ACCOUNT_SHOP_ID_KEY];
    
    if (([defaults stringForKey:@"accountIDSave"] == nil) || ([AccountManager isWebMail]==NO))
    {
        // (ログインしていない or WebMail契約していない) ならばサーバ設定ボタンを表示しない
#ifdef FOR_REJECT
        sheet =
        [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                    delegate:self
                           cancelButtonTitle:@"キャンセル"
                      destructiveButtonTitle:nil
                           otherButtonTitles:tl4, tl2, tl5, @"キャンセル", nil];
#else
        sheet =
        [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                    delegate:self
                           cancelButtonTitle:@"キャンセル"
                      destructiveButtonTitle:nil
                           otherButtonTitles:tl4, tl1, tl2, tl5, @"キャンセル", nil];
#endif
        
        sheet.cancelButtonIndex = 4;
        
    }
    else if(shopID.length>1) {
        //2016/1/5 TMS ストア・デモ版統合対応 HPへのリンクはデモ版のみ
		// (ログイン済み かつ WebMail契約済 かつ 店舗契約有り) ならばメール送信サーバの設定ボタンを表示
#ifdef FOR_SALES
        sheet = [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                            delegate:self
                                   cancelButtonTitle:@"キャンセル"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:tl0, tl3, tl4, tl1, tl2, tl5, @"キャンセル", nil];
#else

        sheet = [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                            delegate:self
                                   cancelButtonTitle:@"キャンセル"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:tl0, tl3, tl4, tl2, tl5, tl6, @"キャンセル", nil];
#endif
		sheet.cancelButtonIndex = 6;
    }
	else
	{
        //2016/1/5 TMS ストア・デモ版統合対応 HPへのリンクはデモ版のみ
		// (ログイン済み かつ WebMail契約済) ならばメール送信サーバの設定ボタンを表示
#ifdef FOR_SALES
        sheet = [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                            delegate:self
                                   cancelButtonTitle:@"キャンセル"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:tl0, tl4, tl1, tl2, tl5, @"キャンセル", nil];
#else
        sheet = [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                            delegate:self
                                   cancelButtonTitle:@"キャンセル"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:tl0, tl4, tl2, tl5, tl6, @"キャンセル", nil];
#endif
		sheet.cancelButtonIndex = 5;
    }

    sheet.tag = 500;
    [sheet autorelease];
    sheet.actionSheetStyle = UIActionSheetStyleDefault;

    // アクションシートを表示する
    [sheet showFromRect:btnSanshouPage.bounds inView:btnSanshouPage animated:YES];
    self.userEditerSheet = sheet;
}

//old define
//#define OS8_SERVERINFO  0
//#define OS8_SHOPINFO    1
//#define OS8_SETLANG     2
////2016/1/5 TMS ストア・デモ版統合対応 HPへのリンクはデモ版のみ
//#ifdef FOR_SALES
//#define OS8_HPURL       3
//#define OS8_USERINFO    4
//#define OS8_NOTIFICATIONS 5
//#else
//#define OS8_USERINFO    3
//#define OS8_NOTIFICATIONS 4
//#define OS8_LOGOUT 5
//#endif

//new define
#define OS8_SHOPINFO    0
#define OS8_SETLANG     1
//2016/1/5 TMS ストア・デモ版統合対応 HPへのリンクはデモ版のみ
#ifdef FOR_SALES
#define OS8_HPURL       2
#define OS8_USERINFO    3
#define OS8_NOTIFICATIONS 4
#else
#define OS8_USERINFO    2
#define OS8_NOTIFICATIONS 3
#define OS8_LOGOUT 4
#endif

- (void) _otherInfoActionSheetDispOS8
{
#ifdef SUPPORT_IOS8
#ifdef DEF_ABCARTE
//2016/1/5 TMS ストア・デモ版統合対応 HPへのリンクはデモ版のみ
#ifdef FOR_SALES
    NSArray *jmenus = @[@"店舗の選択", @"Language select",
                        @"ABCarte のHPを参照", @"アプリの設定", @"お知らせを閲覧する", @"キャンセル"];
    NSArray *emenus = @[@"店舗の選択", @"言語環境の設定",
                        @"ABCarte のHPを参照", @"アプリの設定", @"お知らせを閲覧する", @"キャンセル"];
#else

    NSArray *jmenus = @[@"店舗の選択", @"Language select",
                        @"アプリの設定", @"お知らせを閲覧する", @"ログアウト", @"キャンセル"];
    NSArray *emenus = @[@"店舗の選択", @"言語環境の設定",
                        @"アプリの設定", @"お知らせを閲覧する", @"ログアウト", @"キャンセル"];
#endif
    NSArray *menus = (isJapanese)? jmenus : emenus;
#else
    NSArray *menus = [NSArray arrayWithObjects:
                      @"店舗の選択",
                      @"CaLuLu のHPを参照", @"アプリの設定", @"お知らせを閲覧する", @"キャンセル", nil];
#endif
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *shopID = [defaults stringForKey:ACCOUNT_SHOP_ID_KEY];
    
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"内容を選択してください"
                                        message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    [menus enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqualToString:nil]) {
            *stop = YES;
        } else {
            switch (idx) {
//                case OS8_SERVERINFO: // メール情報の設定
//                    if (([defaults stringForKey:@"accountIDSave"] != nil) && ([AccountManager isWebMail]==YES))
//                    {
//                        [alert addAction:[UIAlertAction actionWithTitle:obj
//                                                                  style:UIAlertActionStyleDefault
//                                                                handler:^(UIAlertAction *action) {
//                                                                    // メール送信サーバの設定画面を表示
//                                                                    [self SmtpInfoSetUp];
//                                                                }]];
//                    }
//                    break;
                case OS8_SHOPINFO: // 店舗情報の表示
                    if (shopID.length>1) {
                        [alert addAction:[UIAlertAction actionWithTitle:obj
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [self OnBtnShopSelect:nil];
                                                                }]];
                    }
                    break;
                case OS8_SETLANG: // 言語環境設定
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                // 言語環境設定
                                                                [self changeLanguage];
                                                            }]];
                    break;
//2016/1/5 TMS ストア・デモ版統合対応 HPへのリンクはデモ版のみ
#ifdef FOR_SALES
                case OS8_HPURL: // ABCarteのHP参照
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                // アプリのHP表示
                                                                [self appliDocUrl];
                                                            }]];
                    break;
#endif
                case OS8_USERINFO: // アプリの設定
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                // アプリの設定
//                                                                [self OnCustomerInfo:nil];
                                                                [self showAppSettingPopup];
                                                            }]];
                    break;
                case OS8_NOTIFICATIONS:
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                // 通知閲覧ポップアップの表示
                                                                [self _showNotificationsPopup];
                                                            }]];
                    break;
#ifndef FOR_SALES
                case OS8_LOGOUT:
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                // ログアウトAlertダイアログの表示
                                                                alertLogout.message = [NSString stringWithFormat:
                                                                                               @"ABCarteからログアウトします。\nよろしいですか？\n（ログアウトの前に同期されます。）"];
                                                                [alertLogout show];
                                                            }]];
                    break;
#endif
                default:    // キャンセル
                    // キャンセル用のアクション追加
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction *action) {
                                                            }]];
                    break;
            }
            
        }
    }];
    // 吹き出し元の設定
    UIPopoverPresentationController *pop = [alert popoverPresentationController];
    pop.sourceView = btnSanshouPage;
    pop.sourceRect = btnSanshouPage.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
#endif
}

//検索バーと編集ボタンの表示制御
- (void) _dispCtrlSearchBar : (BOOL)isShow
{

    mySearchBar.hidden = !isShow;           // 検索バーの設定
#ifdef CALULU_IPHONE
    if (btnAccountLogin.hidden)
    { btnMnuCloudSync.hidden = isShow; }
#else
//    btnMnuEditer.hidden = isShow;           // メニューの編集ボタンの設定（常に検索バーの反転）
    btnSanshouPage.hidden = isShow;
    if ([AccountManager isGroupMail]) {
        btnBroadcastMail.hidden = isShow;
    }
//    btnSanshouPage.hidden = isShow;         // HPボタンの設定
    
    // 新規ユーザ追加ボタン(ログイン済みの場合のみ表示
    btnAddUser.hidden = (isShow)? YES : ![AccountManager isLogined];

#endif

    if(!isShow) {
        NSString *refurl = [AccountManager isReference];
        if(refurl==NULL)
            btnReferenceShow.hidden = YES;
        else
            btnReferenceShow.hidden = NO;
    } else {
        btnReferenceShow.hidden = YES;
    }
#ifndef DEF_ABCARTE
    btnMnuEditer.hidden = isShow;
#endif
//#ifdef AIKI_CUSTOM
//    if (isShow)
//    { btnReferenceShow.hidden = isShow; }
//    else    // 検索解除の場合は,ログイン済みのみ参照画像ボタンを表示
//    { btnReferenceShow.hidden = !([AccountManager isLogined]); };
//#endif
}

#ifdef CLOUD_SYNC
// Cloud同期のアクションシートを表示
- (void) _cloudSyncActionSheetDisp
{
#ifndef CALULU_IPHONE
    UIActionSheet *sheet =
        [[UIActionSheet alloc] initWithTitle:@"クラウドと同期しますか？"       // @"クラウドと同期する方法を選択します"
                                    delegate:self 
                           cancelButtonTitle:@"キャンセル"
                      destructiveButtonTitle:nil
                           // otherButtonTitles:@"クラウドと同期する", @"クラウドへアップロードする", @"キャンセル", nil];
                           otherButtonTitles:@"クラウドと同期する", @"キャンセル", nil];
    sheet.cancelButtonIndex = 2;
#else
    UIActionSheet *sheet =
        [[UIActionSheet alloc] initWithTitle:@"クラウドと同期しますか？" 
                                    delegate:self 
                           cancelButtonTitle:@"キャンセル"
                      destructiveButtonTitle:nil
                           // otherButtonTitles:@"クラウドと同期する", @"クラウドへアップロードする", nil];
                           otherButtonTitles:@"クラウドと同期する", nil];
#endif
    sheet.tag = 128;

    [sheet autorelease];
    sheet.actionSheetStyle = UIActionSheetStyleDefault;
    
    // アクションシートを表示する
    // [sheet showInView:self.view];
    [sheet showFromRect:btnMnuCloudSync.bounds inView:btnMnuCloudSync animated:YES];
}

// クラウドと同期する
- (void) _doCloud2Sync
{
    
    //2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
#ifdef FOR_SALES
    //2015/2/2 TMS アカウントの有効性チェック対応
    if([self isAccountStateChk]){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"アプリ終了の確認"
                                  message:@"アプリ終了後に再度アプリを起動すると最新のデモ用データが更新されます。アプリを終了してもよろしいですか？"
                                  delegate: self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:@"キャンセル", nil
                                  ];
        alertView.tag = DEMO_DATA_SYNC_DIALOG;
        [alertView show];
        [alertView release];
    }else{
        [self alertDisp2:@"アカウントが利用不可となっている\nためABCarteをご利用できません。"
              alertTitle:@"アカウント利用不可"];
            isSyncActive = YES;
    }
#else
    
    isSyncActive = YES;
    // メッセージPopup windowの表示
    [MainViewController showMessagePopupWithMessage:@"クラウドと同期を開始します....."];
    
    // 写真アップロードを中断する
    CloudSyncPictureUploadManager *pictUploader
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cloudPictureUploader;
    [pictUploader uploadInnterrupt];
    
    // 動画アップロードを中断する
    VideoUploader *videoUploader
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).videoUploader;
    [videoUploader uploadInnterrupt];
    
    // 契約オプションチェック
    AccountManager *acMgr = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).accountCountine;
    if (![acMgr doAccountOptionCheck]) {
        // メッセージPopup windowを閉じる
        [MainViewController closeBottomModalDialog];
        isSyncActive = NO;
        return;
    }
    
    if (![AccountManager isCloud]) {
        [MainViewController closeBottomModalDialog];
        isSyncActive = NO;
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _syncNotifications];
        [self _doCloud2SyncMain];
    });
}

// 通知をサーバーから取得する(同期処理)
- (void)_syncNotifications {
    NotificationClient* client = [[NotificationClient alloc] initWithAccountHostUrl:ACCOUNT_HOST_URL];
    NSArray* notificationsData = [client fetchNotifications];
    if (notificationsData == nil) {
        NSLog(@"[_syncNotifications] cannot fetch notifications");
        [client release];
        return;
    }
    NotificationStore *store = [[NotificationStore alloc] init];
    if (![store initializeDatabase]) {
        NSLog(@"[_syncNotifications] initializeDatabase failed");
        [client release];
        [store release];
        return;
    }
    NSArray* readNotifications = [store getReadNotifications];
    if (readNotifications == nil) {
        readNotifications = @[];
    }

    NSMutableArray* notifications = [NSMutableArray array];
    for (NotificationData* data in notificationsData) {
        Notification *notification = [[Notification alloc] init];
        notification.id = data.id;
        notification.title = data.title;
        notification.body = data.body;
        notification.createdAt = data.createdAt;
        notification.forcePopupDeadline = data.forcePopupDeadline;
        Notification *readNotification = [self _findReadNotification:readNotifications byId:data.id];
        if (readNotification != nil && !data.isRead) {
            // ローカルでは既読だがサーバー側は既読出なかった場合、ローカルの状態を維持する
            notification.isRead = readNotification.isRead;
            notification.readAt = readNotification.readAt;
            notification.isReadSynced = NO;
        } else {
            // ローカルで既読出なかった場合や、サーバー・ローカル共に既読の場合、サーバー側のデータを反映させる
            notification.isRead = data.isRead;
            notification.readAt = data.readAt;
            notification.isReadSynced = data.isRead; // サーバー側が既読の場合は同期済みに設定する
        }
        
        if (data.type == 1) {
            // ブロードキャスト通知の場合は常に同期済みとして扱い、サーバーには既読状態を送信しない
            notification.isReadSynced = YES;
        }

        [notifications addObject:notification];
    }
    if (![store deleteAllNotifications]) {
        NSLog(@"[_syncNotifications] deleteAllNotifications failed");
        [client release];
        [store release];
        return;
    }
    if (![store insertNotifications:notifications]) {
        NSLog(@"[_syncNotifications] insertNotifications failed");
        [client release];
        [store release];
        return;
    }
    
    NotificationSyncer* syncer = [[NotificationSyncer alloc] initWithClient:client store:store];
    if (![syncer sync]) {
        NSLog(@"[_syncNotifications] notification sync failed");
        [syncer release];
        [client release];
        [store release];
        return;
    }
    
    [syncer release];
    [client release];
    [store release];
    return;
}

- (Notification *)_findReadNotification:(NSArray*) notifications byId:(NSInteger)notificationId {
    for (Notification* notification in notifications) {
        if (notification.id == notificationId && notification.isRead) {
            return notification;
        }
    }
    return nil;
}


- (void)_showForcePopupNotificationsIfFound {
    NotificationStore *store = [[NotificationStore alloc] init];
    if (![store initializeDatabase]) {
        NSLog(@"[_showForcePopupNotifications] initializeDatabase failed");
        [store release];
        return;
    }
    NSArray* forcePopupNotifications = [store getNotificationsToDisplay:[NSDate date]];
    if (forcePopupNotifications == nil || forcePopupNotifications.count == 0) {
        [store release];
        return;
    }
    NotificationForcePopupViewController *vc = [[NotificationForcePopupViewController alloc] init];
    vc.notifications = forcePopupNotifications;
    [vc setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:vc animated:YES completion:nil];
    [vc release];
}

/*
 通知をサーバーから非同期で取得し、ポップアップ表示すべき通知が存在した場合それを表示する。
 ただし、この処理はアプリ存続中1度しか実行されない
 */
- (void)_syncAndShowNotificationsOnce {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self _syncNotifications];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _showForcePopupNotificationsIfFound];
            });
        });
    });
}


- (void)_doCloud2SyncMain {
    // クラウドと同期処理の実行
    [CloudSyncClientManager clientSyncProc : ^(SYNC_RESPONSE_STATE result)
     {
         
         if (result == SYNC_RSP_OK)
         {
             if(isSyncNomal == YES){
                 userDbManager *usrDbMng = [[userDbManager alloc] init];
                 if (! [usrDbMng userpictureUpgradeVer114])
                 {
                     NSLog (@"databesa update error for ver114 !!!");
                 }
                 if (! [usrDbMng mstuserUpgradeVer122])
                 {
                     NSLog (@"databesa update error for ver122 !!!");
                 }
                 if (! [usrDbMng mstuserUpgradeVer140]) {
                     NSLog (@"databesa update error for ver140 !!!");
                 }
                 if (! [usrDbMng mstuserUpgradeVer172]) {
                     NSLog (@"databesa update error for ver172 !!!");
                 }
                 
                 // 2016/6/24 TMS シークレットメモ対応
                 if(![usrDbMng secretUserMemoTableMake]){
                     NSLog (@"database update error for secretUserMemoTableMake !!!");
                 }
                 
                 // 2016/8/12 TMS 顧客情報に担当者を追加
                 if (! [usrDbMng mstuserUpgradeVer215]) {
                     NSLog (@"databesa update error for ver215 !!!");
                 }
                 
                 [usrDbMng release];
             
                 // 現在選択中の店舗IDの初期化：選択可能な店舗をすべて選択する
                 [[ShopManager defaultManager] setSelectedShopIDsDefault];
                 
                 //先に全ユーザでユーザ情報リストを更新
                 [userInfoList setUserInfoList:@"" selectKind:SELECT_NONE];
                 
                 // ユーザ情報リストより先頭のユーザ情報を取得
                 userInfo* topInfo = [userInfoList getListTopUserInfo];
                 currentUserId = (topInfo)? topInfo.userID : -1;
                 
                 // 検索解除にする（削除したユーザを一覧から表示しないようにする）
                 btnSearch.tag = 1;
                 [self OnSerach:nil];
                 
                 // 先頭ユーザが取得できなかった場合は、次のViewController(HistListViewController)の強制更新
                 if (currentUserId < 0)
                 {	[self updateNextViewController:YES]; }
                 
                 // 店舗対応のみ店舗選択ボタンを表示
                 //                 if ( [[ShopManager defaultManager] isAccountShop] )
                 //                 {   btnShopSelect.hidden = NO; }
             }
             // メッセージPopup windowを閉じる
             [MainViewController closeBottomModalDialog];

             [self _showForcePopupNotificationsIfFound];
             
             //                 [self alertDisp:@"クラウドと同期が完了しました" alertTitle:nil];
#ifdef DEF_ABCARTE
             if(isSyncNomal == NO){
                 
                 [MainViewController showMessagePopupWithMessage:@"初期化をしています..."];
                 
                 AccountManager *actMng = [[AccountManager alloc]initWithServerHostName:ACCOUNT_HOST_URL];
                 ACCOUNT_RESPONSE response = [actMng logout];
                 
                 if(response == ACCOUNT_RSP_SUCCESS){
                     
                     NSFileManager *fileMng = [NSFileManager defaultManager];
                     NSString *folderPath = [NSString stringWithFormat:@"%@/Documents",
                                             NSHomeDirectory()];
                     for ( NSString *path in [fileMng contentsOfDirectoryAtPath:folderPath error:nil] )
                     {
                         [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",
                                                                           folderPath,path] error:nil];
                     }
                     
                     //tmp以下削除
                     folderPath = [NSString stringWithFormat:@"%@/tmp",
                             NSHomeDirectory()];
                     
                     for ( NSString *path in [fileMng contentsOfDirectoryAtPath:folderPath error:nil] )
                     {
                         [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",
                                                                           folderPath,path] error:nil];
                     }
                     
                     //Library/Caches以下削除
                     folderPath = [NSString stringWithFormat:@"%@/Library/Caches",
                             NSHomeDirectory()];
                     
                     for ( NSString *path in [fileMng contentsOfDirectoryAtPath:folderPath error:nil] )
                     {
                         [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",
                                                                           folderPath,path] error:nil];
                     }
                     
                     ShopManager *shopMng = [ShopManager defaultManager];
                     [shopMng initAccountShopID];
                     
                     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                     
                     // ダウンロードキー情報をクリア
                     [defaults removeObjectForKey:APP_STORE_SAMPLE_DEF_KEY];
                     [defaults removeObjectForKey:APP_STORE_SAMPLE_DB_DEF_KEY];
                     [defaults setObject:SECRET_MEMO__PWD_INIT_VALUE
                                  forKey:SECRET_MEMO_PWD_KEY];
                     [defaults synchronize];

                     [[NSNotificationCenter defaultCenter] addObserver:self
                                                              selector:@selector(downloadEnd:)
                                                                  name:@"sampleDlEnded" object:nil];
                     
                     [((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]) appStoreSampleDownload];
                     
                 }else{
                     
                    [MainViewController closeLockWindow];
                     
                    [self alertDisp:@"ログアウトに失敗しました。" alertTitle:@"ログアウト失敗"];
                 }
             }else{
                 //2015/11/17 TMS アカウントの有効性チェック対応
                 if([self isAccountStateChk]){
                     
                     if ([AccountManager isWebMail]) {
                         firstWebMailBlockCheck = NO;
                         [self updateWebMailBlockUserDB];
                     }
                     
                     NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                     float size = [ud floatForKey:@"usedSize"];     // 写真使用容量
                     float disk = [ud floatForKey:@"contractSize"]; // 契約ディスク容量
                     float msize = [ud floatForKey:@"movieSize"];   // 動画使用容量
                         
#ifdef DEBUG
            NSLog(@"picture [%.2f MB] : movie [%.2f MB] : disk [%.1f GB]", (size / 1024 / 1024), (msize / 1024 / 1024), (disk / 1024 / 1024 / 1024));
#endif
                     float capacity = (size + msize) / disk * 100;
                     // アラートは１日一回のみ表示
                     NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                     [formatter setLocale:[NSLocale systemLocale]];
                     [formatter setTimeZone:[NSTimeZone systemTimeZone]];
                     [formatter setDateFormat:@"yyyy-MM-dd"];
                     NSDate* disksizecheck = [formatter dateFromString:[ud stringForKey:@"disksizecheck"]];
                     NSComparisonResult result;
                     if (!disksizecheck) {
                         result = NSOrderedDescending;
                     }else{
                         NSDate *now = [formatter dateFromString:[formatter stringFromDate:[NSDate date]]];
                         result = [now compare:disksizecheck];
                     }
                     // 契約ディスク容量が10G未満であれば、80%で警告
                     if((disk / 1024 / 1024 / 1024) < 10.0){
                         if((capacity >= 80.0f) && (result == NSOrderedDescending)) {
                             [self alertDisp:[NSString stringWithFormat:@"クラウドと同期が完了しました\nクラウド使用量 %.2f %%\nデータの整理またはクラウド容量の追加をご検討ください。", capacity] alertTitle:@"同期完了"];
                             [ud setObject:[formatter stringFromDate:[NSDate date]] forKey:@"disksizecheck"];
                             [ud synchronize];

                         } else {
                             [self alertDisp:[NSString stringWithFormat:@"クラウドと同期が完了しました\nクラウド使用量 %.2f %%", capacity] alertTitle:@"同期完了"];
                         }
                     // 契約ディスク容量が10G以上であれば、残量２G未満で警告
                     }else if((disk / 1024 / 1024 / 1024) >= 10.0){
                         if(((disk / 1024 / 1024 / 1024) - ((size / 1024 / 1024 / 1024) + (msize / 1024 / 1024 / 1024)) < 2.0) && (result == NSOrderedDescending)) {
                             [self alertDisp:[NSString stringWithFormat:@"クラウドと同期が完了しました\nクラウド使用量 %.2f %%\nデータの整理またはクラウド容量の追加をご検討ください。", capacity] alertTitle:@"同期完了"];
                             [ud setObject:[formatter stringFromDate:[NSDate date]] forKey:@"disksizecheck"];
                             [ud synchronize];
                             
                         } else {
                             [self alertDisp:[NSString stringWithFormat:@"クラウドと同期が完了しました\nクラウド使用量 %.2f %%", capacity] alertTitle:@"同期完了"];
                         }
                     }
                 }else{
                     [self alertDisp2:@"アカウントが利用不可となっている\nためABCarteをご利用できません。"
                           alertTitle:@"アカウント利用不可"];
                 }
             }
#else
             [self alertDisp:@"クラウドと同期が完了しました" alertTitle:@"同期完了"];
#endif
         }
         else
         {
             //2015/11/17 TMS アカウントの有効性チェック対応
             if([self isAccountStateChk]){
                 // メッセージPopup windowを閉じる
                 [MainViewController closeBottomModalDialog];
                 
                 [self alertDisp:[CloudSyncUtility getSyncResponseStateWithState:result]
                      alertTitle:@"クラウドと同期ができませんでした"];
             }else{
                 [self alertDisp2:@"アカウントが利用不可となっている\nためABCarteをご利用できません。"
                       alertTitle:@"アカウント利用不可"];
             }
         }
         
         // 写真アップロードを再開(起動)する
         CloudSyncPictureUploadManager *pictUploader
         = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cloudPictureUploader;
         [pictUploader uploadRestart];
         
         // 動画アップロードを再開(起動)する
         VideoUploader *videoUploader
         = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).videoUploader;
         [videoUploader uploadRestart];
         
         // camaraViewControllerの取得
         camaraViewController *cameraView
         = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView;
         if (cameraView) {
             cameraView.reInit = YES;
         }
         isSyncActive = NO;
         
         if (result == SYNC_RSP_OK) {
             NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
             [ud setObject:nil forKey:@"first_add"];
             [ud setObject:nil forKey:@"add_secret"];
             [ud setObject:nil forKey:@"add_carte"];
             [ud synchronize];
         }
     }
     ];
#endif
}

//2015/11/17 TMS アカウントの有効性チェック対応
//アカウントの有効性を取得
- (BOOL)isAccountStateChk{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *accID  = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
    
    if([accID length] > 0){
        AccountManager *actMng = [[AccountManager alloc]initWithServerHostName:ACCOUNT_HOST_URL];
        
        if([actMng isAccountStateChk:accID] == 0){
            if (actMng.isState == 1){
                //アカウントが有効な場合は次へ
                return YES;
            }else if(actMng.isState != 1){
                //アカウントが無効な場合は、メッセージを表示し、すべての操作を不可とする。
                MainViewController *mainVC
                = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
                
                UIView *uv = [[UIView alloc] init];
                uv.frame = mainVC.view.bounds;
                uv.backgroundColor = [UIColor  blackColor];
                uv.alpha = 0.5;
                [mainVC.view addSubview:uv];
                
                if (actMng.isState == -9){
                    //アカウントが抹消な場合は、端末内のファイルを削除。
                    NSFileManager *fileMng = [NSFileManager defaultManager];
                    
                    NSString* path=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
                    NSArray *fList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
                    
                    for(int i = 0;[fList count] > i;i++){
                        for(int i = 0;[fList count] > i;i++){
                            NSLog(@"met moi vai 1");
                            NSString *delFile = [NSString stringWithFormat:@"%@/%@",
                                                 path, [fList objectAtIndex:i] ];
                            if ([fileMng fileExistsAtPath:delFile]){
                                [fileMng removeItemAtPath:delFile error:NULL];
                            }
                        }
                    }
                    
                    //tmp以下削除
                    path = [NSString stringWithFormat:@"%@/tmp",
                            NSHomeDirectory()];
                    
                    fList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
                    for(int i = 0;[fList count] > i;i++){
                        NSLog(@"met moi vai 2");
                        NSString *delFile = [NSString stringWithFormat:@"%@/%@",
                                             path, [fList objectAtIndex:i] ];
                        if ([fileMng fileExistsAtPath:delFile]){
                            [fileMng removeItemAtPath:delFile error:NULL];
                        }
                    }
                    
                    //Library/Caches以下削除
                    path = [NSString stringWithFormat:@"%@/Library/Caches",
                            NSHomeDirectory()];
                    
                    fList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
                    for(int i = 0;[fList count] > i;i++){
                        NSLog(@"met moi vai 3");
                        NSString *delFile = [NSString stringWithFormat:@"%@/%@",
                                             path, [fList objectAtIndex:i] ];
                        if ([fileMng fileExistsAtPath:delFile]){
                            [fileMng removeItemAtPath:delFile error:NULL];
                        }
                    }
                }
                return NO;
            }
        }
    }
    return YES;
}

// クラウドへアップロード確認AlertViewの表示
- (void) _cloudUploadAlertShow
{
#ifdef CALULU_IPHONE
    NSString *devKind = @"iPhone";
#else
    NSString *devKind = @"iPad";
#endif
    NSString *msg = [NSString stringWithFormat:
                      @"この%@のデータを\nクラウドにアップロードします\nよろしいですか？\nご注意）クラウドデータは\n全て上書きされます",
                      devKind];
    UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"クラウドへのアップロード"
							  message:msg
							  delegate:self
							  cancelButtonTitle:@"は い"
							  otherButtonTitles:@"いいえ", nil
							  ];
	alertView.tag = CLOUD_UPLOAD_OK_DIALOG;
    [alertView show];
	[alertView release];
}

// クラウドへアップロード
- (void) _doCloud2Upload
{
    // メッセージPopup windowの表示
    [MainViewController showMessagePopupWithMessage:@"クラウドへのアップロードを開始します....."];
    
    // クラウドと同期処理の実行
    [CloudSyncClientManager clientSyncProc : ^(SYNC_RESPONSE_STATE result)
     {
         // メッセージPopup windowを閉じる
         [MainViewController closeBottomModalDialog];
         
         if (result == SYNC_RSP_OK)
         {
             [self alertDisp:@"クラウドへのアップロードが\n完了しました" alertTitle:nil];
         }
         else
         {
             
             [self alertDisp:[CloudSyncUtility getSyncResponseStateWithState:result]
                  alertTitle:@"クラウドへのアップロードができませんでした"];
         }
     }
     ];
}

#endif

/**
 * 処理中プログレスパネル表示
 */
- (UILockWindowController *)ProgressView:(NSString *)message
{
    // 画面LockのVCのインスタンス生成
    LockWindowPoupup *lock = [[LockWindowPoupup alloc] initWithLockMode:YES
                                                                message:message];
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    UILockWindowController *_bottomDialog = [[UILockWindowController alloc]initWithParentView:mainVC.view];
    // 処理中インジケータの表示
    [_bottomDialog presentDialogViewController:lock animated:YES isDispBottom:NO];
    [lock release];
    
    return _bottomDialog;
}

/**
 *  カルテ数更新
 */
-(void) updateLblCustomerKarteAll
{
//    int nKarte = [[userInfoList getAllUserInfo] count];
//    lblCustomerCarteAll.text = [NSString stringWithFormat:@"%d件",nKarte];
    lblCustomerCarteAll.text = [NSString stringWithFormat:@"%ld件", (long)[userInfoList getShopUserInfo]];
}

#pragma mark -
#pragma mark ACCOUNT_LOGIN
#ifdef USE_ACCOUNT_MANAGER
// アカウントログインPopupの表示
- (void) _showAccontLoginPopUp
{
    if (popoverCntlAccountLogin)
	{
		[popoverCntlAccountLogin release];
		popoverCntlAccountLogin = nil;
	}
	
	// お客様番号による検索のViewControllerのインスタンス生成
	AccountLoginPopUp *vcAccPoup
    = [[AccountLoginPopUp alloc]initWithPopUpViewContoller:POPUP_ACCOUNT_LOGIN
                                         popOverController:nil  callBack:self];
	// ポップアップViewの表示
#ifndef CALULU_IPHONE
	popoverCntlAccountLogin = 
    [[UIPopoverController alloc] initWithContentViewController:vcAccPoup];
    popoverCntlAccountLogin.delegate = vcAccPoup;   // ポップアップ枠外の押下を検知させるため
    vcAccPoup.myDelegate = self;                    // ポップアップクローズ処理を行うため
	vcAccPoup.popoverController = popoverCntlAccountLogin;
    // 2015/12/22 TMS 初回起動時ログイン必須対応
    dmyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    dmyBtn.frame = CGRectMake(self.view.frame.size.width/3, self.view.frame.size.height/2.1, 10, 10);
    [self.view addSubview:dmyBtn];
    
	[popoverCntlAccountLogin presentPopoverFromRect:dmyBtn.bounds
											 inView:dmyBtn
						   permittedArrowDirections:0
										   animated:YES];
    
#else
    [MainViewController showModalDialog:vcAccPoup parentView:nil isDispBottom:NO];
#endif
	[vcAccPoup release];
}

#ifdef CLOUD_SYNC
// 店舗の選択
- (void) _selectedShopWithIDS:(NSArray*)selectedIDs
{
    // 現在選択中の店舗IDの設定
    [[ShopManager defaultManager] setSelectedShopIDsWithArray:selectedIDs];
    
    // 選択したショップリストをUserDefaultsに保存する
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:selectedIDs forKey:@"SEL_SHOPS_ARRAY"];
    [ud synchronize];
    
    //先に全ユーザでユーザ情報リストを更新
    [userInfoList setUserInfoList:@"" selectKind:SELECT_NONE];
    
    // ユーザ情報リストより先頭のユーザ情報を取得
    userInfo* topInfo = [userInfoList getListTopUserInfo];
    currentUserId = (topInfo)? topInfo.userID : -1;
    
    // 検索解除にする（削除したユーザを一覧から表示しないようにする）
    btnSearch.tag = 1;
    [self OnSerach:nil];
    
    // 先頭ユーザが取得できなかった場合は、次のViewController(HistListViewController)の強制更新
    if (currentUserId < 0)
    {	[self updateNextViewController:YES]; }
    
}
#endif

// お問い合わせ:メール送信
- (void) _contactMailSend
{
    if(![MFMailComposeViewController canSendMail ]) {
        NSLog(@"NOT MAIL ACCOUNT");
        NSString *message = @"利用可能なメールアカウントが\n設定されていません。\n機器本体の「設定」内の\n「メール/連絡先/カレンダー」より\nメールアカウントの設定を\n行ってください。";

        UIAlertView *alert =[ [UIAlertView alloc]initWithTitle:@"お問い合わせメール送信" 
                                                       message:message
                                                      delegate:nil 
                                             cancelButtonTitle:@"O K"
                                             otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    // メールコントローラ作成
	MFMailComposeViewController *mailVC
        = [[MFMailComposeViewController alloc] init];
	mailVC.mailComposeDelegate = self;
    
    NSString *apli;
#ifdef DEF_ABCARTE
    apli = @"ABCarte";
#else
    apli = @"CaLuLu";
#endif
    
    // メール本文作成
    NSMutableString *body = [NSMutableString string];
#ifndef CALULU_IPHONE
    [body appendString:@"---------------------------------------------------------\n"];
    [body appendString:[NSString stringWithFormat:@"%@のお問い合わせ (メールフォーム)\n", apli]];
    [body appendString:@"---------------------------------------------------------\n"];
    [body appendString:@"\n"];
#endif
    [body appendString:@"（誠に恐れ入りますが、お名前、メールアドレス、お問い合わせ内容の"];
    [body appendString:@"ご記入をお願いいたします。）"];
    [body appendString:@"\n"];
#ifndef CALULU_IPHONE
    [body appendString:@"=============================================================\n"];
#else
    [body appendString:@"===========================\n"];
#endif
    [body appendString:@"\nお名前：\n"];
    [body appendString:@"\nメールアドレス：\n"];
    [body appendString:@"\nお問い合わせ内容：\n\n"];
#ifndef CALULU_IPHONE
    [body appendString:@"=============================================================\n"];
#else
    [body appendString:@"===========================\n"];
#endif
    [body appendString:@"\n"];
    [body appendString:@"（ご記入後、「送信」をタップするとメールが送信されます。）\n"];
        
    [mailVC setToRecipients:
        [NSArray arrayWithObject:CONTACT_MAIL_SEND_ADDR]];              // 宛先
	[mailVC setSubject:[NSString stringWithFormat:@"%@について", apli]]; // 件名
	[mailVC setMessageBody:body isHTML:NO];                             // 本文
    // MainViewControllerの取得
	MainViewController *mVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mVC presentViewController:mailVC animated:YES completion:nil];
    
    [mailVC release];
}

#endif

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
#ifndef USE_ACCOUNT_MANAGER
    return;
#endif

	NSString *message = nil;
	
	switch (result) {
		case MFMailComposeResultCancelled:
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
			message = @"お問い合わせメールを送信しました";
			break;
		case MFMailComposeResultFailed:
			message = @"お問い合わせメール送信に失敗しました\nネットワークの設定などを確認願います";
			break;
		default:
			break;
	}

    // MainViewControllerの取得
	MainViewController *mVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mVC dismissViewControllerAnimated:YES completion:nil];
	
	if (!message)
	{	return; }
	
	UIAlertView *alert =[ [UIAlertView alloc]initWithTitle:@"お問い合わせメール送信" 
												   message:message 
												  delegate:nil 
										 cancelButtonTitle:@"O K"
										 otherButtonTitles:nil];
	[alert show];
	[alert release];
}

#pragma mark iOS_Frmaework

/*
 // The designated initializer. Override to perform setup that is required before the view is loaded.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	[super loadView];
    
    //2015/11/17 TMS アカウントの有効性チェック対応
    if([self isAccountStateChk]){
        //アカウント有効の場合は次へ
    }else{
        [self alertDisp2:@"アカウントが利用不可となっている\nためABCarteをご利用できません。"
              alertTitle:@"アカウント利用不可"];
    }
    
	popoverCntlNewUser = popoverCntlEditUser = popoverCntlSmtpSetup
	= popoverCntlEditWorkItem = popoverCntlMainte = popoverCntlRegNumSearch = nil;
#ifdef CLOUD_SYNC
    popoverCntlSelectShop = nil;
#endif
	
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDの初期化：選択可能な店舗をすべて選択する
    [[ShopManager defaultManager] setSelectedShopIDsDefault];
#endif

    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    if ([defaluts boolForKey:@"appstore_sample_db_download"]) {
    // ----------
    // DB読み込みのための処理中インジケータ表示
    
    // 画面LockのVCのインスタンス生成
    LockWindowPoupup *lock = [[LockWindowPoupup alloc] initWithLockMode:YES
                                                                message:@"顧客データの読み取り中です"];
	MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    UILockWindowController *_bottomDialog = [[UILockWindowController alloc]initWithParentView:mainVC.view];
    // 処理中インジケータの表示
    [_bottomDialog presentDialogViewController:lock animated:YES isDispBottom:NO];
    
    // 2013.11.01 DB登録件数が多いときに、画面表示までに時間がかかりすぎるとアプリが強制終了
    // される件の回避策として、非同期に処理するようにする
    dispatch_async(dispatch_get_main_queue(), ^{
        // ユーザー情報リストの初期化して、全ユーザを設定しておく
        userInfoList = [[userInfoListManager alloc] init];
        [userInfoList setUserInfoList:@"" selectKind:SELECT_NONE];
        // DB読み込み終了後、検索解除の動作を行って再表示させる
        btnSearch.tag = 1;
		// tableViewの再読み込み
		[myTableView reloadSectionIndexTitles];
        [indexTableView reloadSectionIndexTitles];
		[myTableView reloadData];
        [self updateLblCustomerKarteAll];
        [self selectListTopUser];
        // 処理中インジケータを閉じる
        [_bottomDialog dismissDialogViewControllerAnimated:YES];
        
        // 閉じる毎にインスタンスは破棄する
        [_bottomDialog release];
        [lock release];
        
        // 再表示後、検索ボタンの状態を元に戻す
        btnSearch.tag = 0;
        //        _bottomDialog = nil;
    });
        
    }

	// 検索条件の初期化
	selectJyoukenKind = (NSUInteger)SELECT_NONE;
	
	// 遷移画面の初期化（本画面：顧客一覧画面）
	_windowView = WIN_VIEW_USER_LIST;
	
	// お客様番号による検索での前回検索数値の初期化
	_lastUserRegistNum4Search = REGIST_NUMBER_INVALID;

	// WebMailユーザー作成用
	createUser = [[CreateWebMailUser alloc] initWithDelegate:self];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    //save user info for crash report case
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [CrashlyticsKit setUserIdentifier:[defaults stringForKey:@"accountIDSave"]];
    [defaults setBool:false forKey:@"CarteFromNew"];
    //disable 3r
    [defaults setBool:false forKey:@"3rcamera_enable"];
    [defaults synchronize];
    
    // 背景色の変更 RGB:D8BFD8
    [self.view setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1.0]];
	
	// 現在選択ユーザの初期化
	[self initSelectedUser];
	
	// alertViewダイアログの初期化
	[self initAlertView];
	
	// メンテナンスボタンの有効／無効設定
	[self maitenaceButtonEnable];
	
	// フリッカーボタンの初期化
	[self flickerButtonSetup];
	
    // 2016/6/7 TMS メモリ使用率抑制対応
    //_headPictureList
	//_headPictureList = nil;

	// 先頭のユーザを選択
	[self selectListTopUser];

	// 最新施術内容のタイトルを設定
	[self setLastWorkTitle];
	
#ifdef USE_ACCOUNT_MANAGER
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(_accountLoginBtnShow:) 
												name:ACCOUNT_CONTINUE_ERROR_NOIFY object:nil];
#endif
    
#ifdef CALULU_IPHONE
    // タップジェスチャーのセットアップ
    [self _setUpTapGesture];
//#ifdef CLOUD_SYNC
    // 同期バージョンはデフォルトで検索バーを非表示にする
    mySearchBar.hidden = YES;
    
//#endif

#endif
    
#ifdef CLOUD_SYNC
    // 店舗対応のみ店舗選択ボタンを表示
    if ( [[ShopManager defaultManager] isAccountShop] )
    {
//        btnShopSelect.hidden = NO;
        [lblLastWorkContent setFrame:CGRectMake(lblLastWorkContent.frame.origin.x,
                                                lblLastWorkContent.frame.origin.y,
                                                364 - 115 - 10,
                                                lblLastWorkContent.frame.size.height)];
        [self.view bringSubviewToFront:btnShopSelect];
    }
    
    // 写真アップロードを再開(起動)する
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    [app setSyncPictUploaderRun:YES];
#endif
    if([AccountManager isMovie]) {
        // 動画アップロードを再開(起動)する
        [app setSyncVideoUploaderRun:YES];
    }
    _isThumbnailDeleted = NO;
    
    self.userEditerSheet = nil;

    // 参照画像表示ボタンの非表示:ログイン済みのみ
    NSString *refurl = [AccountManager isReference];
    if(refurl == NULL)
        btnReferenceShow.hidden = YES;
    else
        btnReferenceShow.hidden = NO;

    userMailStatusList = [[[NSMutableDictionary alloc] init] retain];

	// 一斉送信ボタンの表示
	[btnBroadcastMail setHidden:![AccountManager isGroupMail]];
    
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    if ([df floatForKey:@"video_max_duration"] == 0.0f) {
        [df setFloat:10.0f forKey:@"video_max_duration"]; // 初期値は10秒
    }
    if ([df floatForKey:@"video_max_rectime"] == 0.0f) {
        [df setFloat:10.0f forKey:@"video_max_rectime"]; // 初期値は10秒
    }
#ifdef TABLE_INDEX
    [self setSourceData];

    iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(iOSVersion>=7.0) {
        UIColor *backColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.5f];
        indexTableView.sectionIndexBackgroundColor = backColor;
    }
    if(iOSVersion>=6.0) {
        indexTableView.sectionIndexColor = [UIColor darkGrayColor];
    }
    [indexView setBackgroundColor:[UIColor clearColor]];
#endif
    [indexView setAlpha:0.0];
    
    vcEditUser = nil;
    privacyView = [[UIView alloc] initWithFrame:app.window.frame];
    
    firstWebMailBlockCheck = NO;
    
    // 2016/7/17 TMS 参照モード追加対応
    btnUserInfoEdit.tag = USR_EDIT_MODE_TAG;
    btnUserInfoView.tag = USR_VIEW_MODE_TAG;
    
    onReverseSort = false;
}

// 初回表示後のイベント
- (void)viewDidAppear:(BOOL)animated
{
#ifdef CLOUD_SYNC
    // 店舗対応のみ店舗選択ボタンを表示
    if ( [[ShopManager defaultManager] isAccountShop] )
    {
//        btnShopSelect.hidden = NO;
        [lblLastWorkContent setFrame:CGRectMake(lblLastWorkContent.frame.origin.x,
                                                lblLastWorkContent.frame.origin.y,
                                                364 - 115 - 10,
                                                lblLastWorkContent.frame.size.height)];
        [self.view bringSubviewToFront:btnShopSelect];
    }
    
    // 写真アップロードを再開(起動)する
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    [app setSyncPictUploaderRun:YES];
#endif
    if([AccountManager isMovie]) {
        // 動画アップロードを再開(起動)する
        [app setSyncVideoUploaderRun:YES];
    }
	
    //2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
    //2012 07/19 伊藤 サンプルデータのダウンロード待ち
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    // iPadCamera-info.plistよりバージョン番号を取得:Bundle Versionキーで設定
    NSString *ver
    = [ [[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    // 設定ファイルよりバージョン番号を取得
    NSString *setVer = [defaluts stringForKey:@"appInfo_version"];
    // 双方が異なれば、アップデートと判定
    BOOL isUpdateVersion = ! [setVer isEqualToString:ver];
    
	if(([defaluts objectForKey:@"appstore_sample_download"] == nil
        || ![defaluts boolForKey:@"appstore_sample_download"] ||
        isUpdateVersion)
       ){
#ifndef CALULU_IPHONE
        [MainViewController showMessagePopupWithMessage:@"初期設定をしています\nこの作業は初回起動時に実行されます"];
#else
        [MainViewController showMessagePopupWithMessage:@"初期設定をしています..."];
#endif
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadEnd:)
                                                     name:@"sampleDlEnded" object:nil];
    }else{
        // 2015/12/22 TMS 初回起動時ログイン必須対応
        if (! [AccountManager isLogined]){
            // アカウントログインPopupの表示
            [self _showAccontLoginPopUp];
            
            backImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.height)];
            
            //端末の向きに応じた背景画像を設定
            UIDevice *dev = [UIDevice currentDevice];
            if (dev.orientation == UIDeviceOrientationLandscapeLeft || dev.orientation == UIDeviceOrientationLandscapeRight) {
                [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte-Landscape@2x.png"]];
            }else if (dev.orientation == UIDeviceOrientationPortraitUpsideDown || dev.orientation == UIDeviceOrientationPortrait){
                [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte@2x.png"]];
            }else{
                [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte@2x.png"]];
            }
            
            [self.view addSubview:backImgView];
        }else{
#ifndef FOR_SALES
            // デモ版ではアプリ起動時に通知確認・表示処理を行わない
            [self _syncAndShowNotificationsOnce];
#endif
        }
    }
    
	// 遷移元の画面により処理を決める
	switch (_windowView)
	{
		case (WIN_VIEW_USER_LIST):
		// 本画面：顧客一覧画面
#ifdef USE_ACCOUNT_MANAGER
			// アカウントログインボタンの表示
			[self accountLoginBtnShow];
#endif
			break;

		case (WIN_VIEW_HIST_LIST):
		// 履歴一覧画面
			// 最新履歴の更新：ユーザ詳細情報とユーザ一覧の最新日付と最新施術内容を更新する
			[self histWorkItemUpdate];
			
			// 現在選択ユーザの画像ファイル更新:ユーザ情報も更新
			[self updateUserPictureAtviewDidAppear:YES];
            
            // メール&QRコードの表示を一旦なくす
            MainViewController *mainVC
                = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
            UIViewController *vc
                = [ mainVC getVC4ViewControllersWithClass:[HistListViewController class]];
            if (vc)
            {
				[(HistListViewController*)vc mailViewShowWithFlag:NO];
				[(HistListViewController*)vc qrcodeViewShowWithFlag:NO];
			}

#ifdef CLOUD_SYNC
            if(![AccountManager isCloud]) btnMnuCloudSync.hidden = YES;
            else if([AccountManager isLogined] && [AccountManager isCloud]) btnMnuCloudSync.hidden = NO;
            // 同期の再開の確認
            [self doSyncAtRunnigTime];
#endif
			break;

		case (WIN_VIEW_SELECT_PICTURE):
		// 写真一覧表示
			// 現在選択ユーザの画像ファイル更新:ユーザ代表写真のみ更新 
            [self updateUserPictureAtviewDidAppear:NO];
            // 写真の削除があった場合は、履歴画面を更新
            if (_isThumbnailDeleted)
            {   [self updateNextViewControllerVisbleCells]; }
			break;

		case (WIN_VIEW_CAMERA):
		// カメラ画面
			// 次のViewController(HistListViewController)の更新
            [self histWorkItemUpdate];
            
            // 現在選択ユーザの画像ファイル更新:ユーザ情報も更新
            [self updateUserPictureAtviewDidAppear:YES];
            
			[self updateNextViewController:YES];
			break;

		case (WIN_VIEW_BROADCASTMAIL_USER_LIST):
		// 送信ユーザー選択画面
			break;

		case (WIN_VIEW_TEMPLATE_MANAGE):
		// テンプレート管理画面
			break;

		default:
			break;
	}
	
	// 代表写真リストの初期化
    // 2016/6/7 TMS メモリ使用率抑制対応
	//[self initHeadPictureList];

#ifdef USE_ACCOUNT_MANAGER    
    // 販売店様の場合は、サンプルデータをダウンロード（ログイン時にダウンロードが失敗した場合）
    [self _sampleDataDownload];
#endif
    if ([AccountManager isWebMail]) {
        [self updateWebMailBlockUserDB];
    }
    
    // ユーザ設定を取得
    [self checkLanguage];
}

- (void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    // ユーザ設定を取得
    [self checkLanguage];
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

/**
    受信拒否データベースを更新
 */
-(void)updateWebMailBlockUserDB
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
#ifdef WEB_MAIL_FUNC
    //  受信拒否ユーザー状態を「端末からのみアクセスするDB」に保存
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 10分以上経過しないと、サーバへの確認を行わないようにする
#ifdef DEBUG
        if (![self checkNeedUpdate:2] && isSyncActive==NO) return;
#else
        if (![self checkNeedUpdate:10] && isSyncActive==NO) return;
#endif

        // バッジの更新
        GetWebMailUserStatuses *getStatuses = [[GetWebMailUserStatuses alloc] initWithDelegate:self];
        [getStatuses getStatuses];  // =>  finishedGetWebMailUserStatuses:statuses;

        // バックグランドで実行（非同期）
        NSArray *arrays = [BlockMailStatus syncAllBlockMailStatus:nil];

        if (arrays) {
            userFmdbManager *manager = [[userFmdbManager alloc]init];
            
            // 取得した受信拒否情報で更新を行う
            for (NSDictionary *dic in arrays) {
                if ([[dic objectForKey:@"u_id"] integerValue]>0) {
                    if ([[dic objectForKey:@"is_rejected"] respondsToSelector:@selector(integerValue)]) {
                        [manager updateWebMailBlockUser:[[dic objectForKey:@"u_id"] intValue]
                                             BlockState:[[dic objectForKey:@"is_rejected"] integerValue]];
                    } else {
                        NSLog(@"mail reject flag update error!!");
                    }
                }
            }
            [arrays release];
            [manager release];
        }
    });
#endif
}

/**
 * 一定時間経過しているか確認(webmail ステータス確認)
 */
- (BOOL) checkNeedUpdate:(NSInteger)interval
{
    // 起動直後の一回目だけは必ずOKとする
    if (!firstWebMailBlockCheck) {
        firstWebMailBlockCheck = YES;
        return YES;
    }
    // 最終チェック時間確認用
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate* lastcheck = [formatter dateFromString:[ud stringForKey:@"webmail_status"]];
    
    NSString* nowString = [formatter stringFromDate:[NSDate date]];
    NSDate *now = [formatter dateFromString:nowString];
    
#ifdef DEBUG
    NSLog(@"[WEB] last[%@] : now[%@]", [formatter stringFromDate:lastcheck], nowString);
#endif
    
    // 最終時間登録がない場合は確認を行う(初期起動時だと思われるため)
    if (!lastcheck) {
        [ud setObject:[formatter stringFromDate:[NSDate date]] forKey:@"webmail_status"];
        [ud synchronize];
        return YES;
    }
    float diff = [now timeIntervalSinceDate:lastcheck];
    
    int mm = (int)(diff / 60);
    
    // ステータス確認インターバル(デフォルト10分以上)
    if (mm > interval) {
#ifdef DEBUG
        NSLog(@"CheckOverTime(DBupload) [%d]", mm);
#endif
        [ud setObject:[formatter stringFromDate:[NSDate date]] forKey:@"webmail_status"];
        [ud synchronize];
        return YES;
    }
#ifdef DEBUG
    NSLog(@"No Status check [last check : %@ / %.2f(sec)]", [formatter stringFromDate:lastcheck], diff);
#endif
    return NO;
}

/**
 * 初回のサンプルダウンロード終了後の通知で呼ばれる
 */
-(void)downloadEnd:(id)sender{
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    [MainViewController closeLockWindow];
    [self performSelectorOnMainThread:@selector(refreshUserInfoListView) withObject:nil waitUntilDone:YES]; 

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"sampleDlEnded" object:nil];
    
    NSFileManager *fileMng = [NSFileManager defaultManager];
    NSString *folderPath = [NSString stringWithFormat:@"%@/Documents",
                            NSHomeDirectory()];
    
    // バッジを初期化
    [UIApplication sharedApplication].applicationIconBadgeNumber = -1;
    
    if([defaluts boolForKey:@"appstore_sample_download"]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"初期設定"
                                                            message:@"初期設定が\n完了いたしました。"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }else {
        // ダウンロードエラーを示す
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"初期設定"
                                                            message:@"初期設定に\n失敗しました。\nネットワークの設定を\n確認してください。\n次回起動時にログインされていない場合\n再び初期設定を行います。"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }
    // サンプルダウンロード終了後に、履歴一覧画面を再度表示し直す
    [self updateNextViewController:YES];
    
    // 2015/12/22 TMS 初回起動時ログイン必須対応
    if (! [AccountManager isLogined]){
        // アカウントログインPopupの表示
        [self _showAccontLoginPopUp];
        
        backImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.height)];

        //端末の向きに応じた背景画像を設定
        UIDevice *dev = [UIDevice currentDevice];
        if (dev.orientation == UIDeviceOrientationLandscapeLeft || dev.orientation == UIDeviceOrientationLandscapeRight) {
            [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte-Landscape@2x.png"]];
        }else if (dev.orientation == UIDeviceOrientationPortraitUpsideDown || dev.orientation == UIDeviceOrientationPortrait){
            [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte@2x.png"]];
        }else{
            [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte@2x.png"]];
        }
        
        [self.view addSubview:backImgView];
    } else {
#ifndef FOR_SALES
        // デモ版ではアプリ起動時に通知確認・表示処理を行わない
        [self _syncAndShowNotificationsOnce];
#endif
    }
}

// 現在選択ユーザの初期化
- (void) initSelectedUser
{
	lblName.text = @"お客様未選択";
	lblSex.text = @"";
	lblLastWorkDate.text = @"----年--月--日　--曜日";
	lblLastWorkContent.text = @"";
	lblBirthday.text = @"平成--年--月--日";
	lblBloadType.text = @"--";
	lblSyumi.text = @"";
	txtViewMemo.text = @"";
	imgViewPicture.image = nil;
    lblShopName.text = @"";
    lblhobby.text = @"";
    lblBloodType.text = @"";
    [topImgCus setImage:[UIImage imageNamed:@"noImage.png"]];
    
	// 現在選択ユーザ枠の角を丸くする
    [Common cornerRadius4Control:imgViewNowUsrFrame];
	
	// 背景色の設定：ADD8E6
//	imgViewNowUsrFrame.backgroundColor = [UIColor colorWithRed:0.678 green:0.847 blue:0.902 alpha:1.0];
	imgViewNowUsrFrame.backgroundColor = [UIColor colorWithRed:0.753 green:0.753 blue:0.753 alpha:1.0];
	
	currentUserId = -1;
}

// alertViewダイアログの初期化
- (void) initAlertView
{
	alertUserInfoDelete = [[UIAlertView alloc] init];
	alertUserInfoDelete.title = @"お客様情報の初期化";
	alertUserInfoDelete.message = @"お客様情報と全ての画像を削除します。よろしいですか？\n(削除すると元に戻せません。)";
	alertUserInfoDelete.delegate = self;
	[alertUserInfoDelete addButtonWithTitle:@"は　い"];
	[alertUserInfoDelete addButtonWithTitle:@"いいえ"];
    
    alertLogout = [[UIAlertView alloc] init];
    alertLogout.title = @"ログアウト（初期化）";
    alertLogout.message = @"ABCarteからログアウトします。\nよろしいですか？\n（ログアウトの前に同期されます。）";
    alertLogout.delegate = self;
    [alertLogout addButtonWithTitle:@"は　い"];
    [alertLogout addButtonWithTitle:@"いいえ"];
	
#ifdef TRIAL_VERSION
	alertOpenHomePage = nil;		// 初期化はopenCaLuLuHpWithMsgメソッドで行う
#endif
}

// 現在選択ユーザの表示
- (void) dispSelectedUser:(mstUser*) userInfo userWorkItem:(fcUserWorkItem*)workItem
{
	// ユーザ情報を更新
	[self updateSelectedUserByUserInfo:userInfo];
	
	// 施術内容で更新
	[self updateSelectedUserByWorkItem:workItem];
	
	// ツールバーボタンのEnable設定
	[self setToolButtonEnable:YES];
}

// お客様番号の設定 isNameSet:ユーザ名が設定されているか？
- (void) setRegistNumberWithMstUser:(mstUser*) userInfo
{
	// コントロールの表示
	BOOL isDisplay = YES;
	
	// 設定されていない場合は、表示しない
	if (! [userInfo isRegistNumberValid] )
	{	isDisplay = NO; }
	
	// ユーザ名が設定されていない場合は、お客様番号がユーザ名となるので表示しない
	if (! [userInfo isSetUserName] )
	{	isDisplay = NO; }
	
	// 表示する
	userRegistNumberTitle.hidden = ! isDisplay;
	userRegistNumber.hidden = ! isDisplay;
	
	// 書式指定で設定する
	userRegistNumber.text = [userInfo getRegistNumber];
}

// 現在選択ユーザのユーザ情報を更新
- (void) updateSelectedUserByUserInfo:(mstUser*) userInfo
{
	// 写真の表示
	[imgViewPicture setImage:
		// [self makeImagePicture: userInfo.pictuerURL pictSize:imgViewPicture.bounds.size]];
		[self makeImagePictureWithUIDSize:userInfo.pictuerURL 
								   userID:userInfo.userID fitSize:imgViewPicture.bounds.size]];
	
	// 名前
    lblName.text = [userInfo getUserName];
    lblName.textColor = [Common getNameColorWithSex:(userInfo.sex == Men)];
    
    lblLastWorkDateTitle.text = (isJapanese)? @"最新来店日" : @"Latest day";
    lblBirthdayTitle.text = (isJapanese)? @"生年月日" : @"Birth date";
    userRegistNumberTitle.text = (isJapanese)? @"お客様番号" : @"Number";
    userNameHonoTitle.hidden = !isJapanese;
	
	// お客様番号
	[self setRegistNumberWithMstUser:userInfo];
	
	// 性別
	lblSex.text = (userInfo.sex != Men)? STRING_SEX_FEMALE : STRING_SEX_MALE;
	lblSex.textColor = (userInfo.sex != Men) ? COLOR_SEX_FEMALE : COLOR_SEX_MALE;
	
    //趣味
    lblhobby.text = userInfo.syumi;
    
    //bloodtype
    lblBloodType.text = [userInfo getBloadTypeByStrig];
    
    //round memo and top view
    viewMemo.layer.cornerRadius = 20;
    viewMemo.clipsToBounds = true;

    viewCusTop.layer.cornerRadius = 20;
    viewCusTop.clipsToBounds = true;
    
	// 生年月日:西暦
    lblBirthday.text = [NSString stringWithFormat:@"%@",[userInfo getBirthDayByLocalTimeAD:isJapanese]];
	// 血液型
	lblBloadType.text = [userInfo getBloadTypeByStrig];
	// 趣味
	lblSyumi.text = userInfo.syumi;
	// メモ
	txtViewMemo.text = userInfo.memo;
    
    //set top customer's image
    if ([userInfo.pictuerURL  isEqual: @""]) {
        [topImgCus setImage:[UIImage imageNamed:@"noImage.png"]];
    } else {
        [topImgCus setImage:[self makeImagePictureWithUIDSize:userInfo.pictuerURL
                                                       userID:userInfo.userID fitSize:topImgCus.bounds.size]];
    }
    
#ifdef CLOUD_SYNC
    if (lblShopName.hidden)
    {   lblShopName.hidden = NO; }
    lblShopName.text = userInfo.shopName;
#endif
	
}

// 現在選択ユーザの施術内容で更新
- (void) updateSelectedUserByWorkItem:(fcUserWorkItem*)workItem
{
	// 最終施術日
    lblLastWorkDate.text = [workItem getNewWorkDateByLocalTime:isJapanese];
	// 最新施術内容
	lblLastWorkContent.text = workItem.workItemListString;
}

// 現在選択ユーザ情報一覧の更新
- (void) updateSelectedUserList:(mstUser*)updateUser lastDate:(NSDate*)date;
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	// tableViewで選択中のcellを取得
	NSIndexPath *indexPath = [myTableView indexPathForSelectedRow];
	if (indexPath == nil)
	{	return; }
	UserTableViewCell *cell = (UserTableViewCell*)[myTableView cellForRowAtIndexPath:indexPath];
	if (cell == nil)
	{	return; }
	
	// ユーザ情報一覧管理クラスの内容の取得
	userInfo  *info 
	= [userInfoList getUserInfoBySection:
	   (NSInteger)indexPath.section rowNum:(NSInteger)indexPath.row];
	
	//cellとユーザ情報一覧管理クラスの内容を更新する：imageはこの画面は変更できない
	if( updateUser)
	{ 
		// ユーザ情報一覧管理クラスの内容を更新
		info.firstName = updateUser.firstName;
		info.secondName = updateUser.secondName;
        info.middleName = updateUser.middleName;
		info.registNumber = updateUser.registNumber;
#ifdef CLOUD_SYNC

		info.shopName = updateUser.shopName;
#endif
		
		// cellを更新
		cell.userName.text = [info getUserName];
		[cell setRegistNumberWithIntValue:info.registNumber isNameSet:info.isSetUserName];
		[cell setSexText:info.sex];	
#ifdef CLOUD_SYNC
        [cell setShopName:info.shopName];
#endif
	}
	if (date)
	{ 
		info.lastWorkDate = date;
        cell.lastDate.text = [info getLastWorkDate:isJapanese];
	}
    [cell setLanguage:isJapanese];
}

// 現在選択ユーザの画像ファイル更新：他画面遷移時（viewDidAppear）に実行
//		isUserInfoRefresh:ユーザ情報の更新フラグ
- (void) updateUserPictureAtviewDidAppear:(BOOL)isUserInfoRefresh
{
	if (currentUserId <= 0)
	{	return; }		//選択中ユーザなし
	
	// データベースよりユーザ（マスタ）の取得
	// ユーザマスタの取得
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	mstUser *user = [usrDbMng getMstUserByID:currentUserId];
	
	if (user)
	{
		if (! isUserInfoRefresh)
		{
			// 現在選択ユーザの画像のみ更新
			[imgViewPicture setImage:
				// [self makeImagePicture: user.pictuerURL pictSize:imgViewPicture.bounds.size]];
				[self makeImagePictureWithUIDSize:user.pictuerURL 
									   userID:user.userID fitSize:imgViewPicture.bounds.size]];
		}
		else 
		{
			// 現在選択ユーザ情報を更新
			[self updateSelectedUserByUserInfo:user];
		}

		//  現在選択ユーザ情報一覧の画像更新
		// tableViewで選択中のcellを取得
		NSIndexPath *indexPath = [myTableView indexPathForSelectedRow];
		if (indexPath == nil)
		{	
        //2012 6/21 リークしていたため修正　伊藤
            [usrDbMng release];
            return;
        }
		UserTableViewCell *cell = (UserTableViewCell*)[myTableView cellForRowAtIndexPath:indexPath];
		if (cell == nil)
		{	            
        //2012 6/21 リークしていたため修正　伊藤
            [usrDbMng release];
            return;
        }
		
		// ユーザ情報一覧管理クラスの画像URLも更新
		userInfo  *info 
		= [userInfoList getUserInfoBySection:
		   (NSInteger)indexPath.section rowNum:(NSInteger)indexPath.row];
		info.pictureURL = [NSString stringWithString:user.pictuerURL];
		
		// 選択中のcellの画像を更新
        if ([info.pictureURL  isEqual: @""]) {
            [cell.picture setImage:[UIImage imageNamed:@"noImage.png"]];
        } else {
            [cell.picture setImage:[self makeImagePictureWithUID: info.pictureURL userID:info.userID]];
        }

	}
	
	[usrDbMng release];
}

// ツールバーボタンのEnable設定
- (void) setToolButtonEnable:(BOOL)enable
{
	// 念のため現在選択中のユーザ確認
	if ( (currentUserId < 0) && (enable) )
	{	return; }
	
	// ツールバーボタン設定
	btnUserInfoEdit.enabled = btnWorkUpdate.enabled = btnHistListView.enabled
	= btnCameraView.enabled = btnUserInfoDelete.enabled = enable;
}

// 写真の表示
- (UIImage*) makeImagePictureWithUID:(NSString*) pictUrl userID:(USERID_INT)userID
{
	if ( (!pictUrl) || ((pictUrl) && ([pictUrl length] <= 0) ))
	{	return (nil); }
	
	// NSLog(@"makeImagePicture start ------------------->");
	
	// 代表写真リストの初期化確認
    // 2016/6/7 TMS メモリ使用率抑制対応
	//[self initHeadPictureList];
	
	// 代表写真リストのキャッシュより画像を取得
    // 2016/6/7 TMS メモリ使用率抑制対応
	//UIImage *cashImage = [_headPictureList objectForKey:pictUrl];
	//if (cashImage)
	//{	return (cashImage); }
	OKDImageFileManager *imgFileMng 
		= [[OKDImageFileManager alloc] initWithUserID:userID];
#ifdef DEBUG
	NSLog(@"DELC SASAGE TEMP %@", pictUrl);
#endif
	UIImage *drawImg = [imgFileMng getThumbnailSizeImage:pictUrl];
	
	// NSLog(@"<-------------------makeImagePicture end ");
	
	// 代表写真リストのキャッシュに画像を保存
    // 2016/6/7 TMS メモリ使用率抑制対応
	//if (drawImg)
	//{ [_headPictureList setObject:drawImg forKey:pictUrl]; }
	
	[imgFileMng release];
	
	return (drawImg);
}

// サイズを指定して写真の表示
- (UIImage*) makeImagePictureWithUIDSize:(NSString*) pictUrl 
                                  userID:(USERID_INT)userID
                                 fitSize:(CGSize)size
{
	if ( (!pictUrl) || ((pictUrl) && ([pictUrl length] <= 0) ))
	{	return (nil); }
	
	OKDImageFileManager *imgFileMng 
		= [[OKDImageFileManager alloc] initWithUserID:userID];
	
        // UIImage *drawImg = [imgFileMng getRealSizeImageWithSize:pictUrl fitSize:size];
    // サイズを指定してイメージの取得 : 実サイズ→サムネイルサイズの順で取得する
    UIImage *drawImg = [imgFileMng getSizeImageWithSize:pictUrl fitSize:size];
		
	[imgFileMng release];
	
	return (drawImg);
}

// 写真の表示
- (UIImage*) makeImagePicture:(NSString*)pictUrl pictSize:(CGSize)size
{
	if ( (!pictUrl) || ((pictUrl) && ([pictUrl length] <= 0) ))
	{	return (nil); }
	
	// NSLog(@"makeImagePicture start ------------------->");
	
	// 代表写真リストの初期化確認
    // 2016/6/7 TMS メモリ使用率抑制対応
	//[self initHeadPictureList];
	
	// 代表写真リストのキャッシュより画像を取得
    // 2016/6/7 TMS メモリ使用率抑制対応
	//UIImage *cashImage = [_headPictureList objectForKey:pictUrl];
	//if (cashImage)
	//{	return (cashImage); }
	
	NSData *fileDat = [NSData dataWithContentsOfFile:pictUrl];
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
    // 2016/6/7 TMS メモリ使用率抑制対応
	//[_headPictureList setObject:drawImg forKey:pictUrl];
	
	
	return (drawImg);
}

// 画像ファイルをフォルダ以下全てを削除する
- (void) allDeletePictureFiles:(USERID_INT)userID
{
	OKDImageFileManager *fileManager 
		= [[OKDImageFileManager alloc]initWithUserID:userID];
	
	// 指定フォルダ（ユーザ）の全てのイメージ（実サイズ版と縮小版の両方）の削除
	[fileManager deleteAllImageWithIsDelFolder:YES];
	
	[fileManager release];
}

// alert表示
- (void) alertDisp:(NSString*) message alertTitle:(NSString*) altTitle
{
    if(iOSVersion<8.0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:altTitle
                                  message:message
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil
                                  ];
        [alertView show];
        [alertView release];	
    } else {
#ifdef SUPPORT_IOS8
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:altTitle
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertViewStyleDefault
                                                handler:nil]];
        
        [self presentViewController:alert animated:NO completion:nil];
#endif
    }
}

//2015/11/17 TMS アカウントの有効性チェック対応
- (void) alertDisp2:(NSString*) message alertTitle:(NSString*) altTitle
{
    if(iOSVersion<8.0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:altTitle
                                  message:message
                                  delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:nil
                                  ];
        [alertView show];
        [alertView release];
    } else {
#ifdef SUPPORT_IOS8
        
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:altTitle
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self presentViewController:alertView animated:NO completion:nil];
        });

#endif
    }
}

// メンテナンスボタンの有効／無効設定
- (void) maitenaceButtonEnable
{
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	// 設定ファイルよりアプリケーションレベルを取得
	NSString *appLevel = [ defaluts stringForKey:@"application_level"];
	
	if (! appLevel) {
		// btnMaintenace.enabled = NO;
		btnMaintenace.width = 0.001f;
		return;
	}
	
	if ( (! [appLevel isEqualToString:@"administrator"]) &&
		(! [appLevel isEqualToString:@"developer"]) )
	{
		// administratorまたはdeveloper以外ではメンテナンスボタンは無効
		// -> hiddenプロパティがないので、widthで設定する
		btnMaintenace.width = 0.001f;
	}
}

// 施術日による検索Popupの表示
- (void) dispWorkDateSearchPopup
{
	// 日付の設定ポップアップのViewControllerのインスタンス生成
	DatePickerPopUp *vcDatePicker 
        = [[DatePickerPopUp alloc]initWithPopUpViewContoller:POPUP_SEARCH_WORK_DATE
                                           popOverController:nil 
                                                    callBack:self];
#ifndef CALULU_IPHONE
	vcDatePicker.contentSizeForViewInPopover = CGSizeMake(332.0f, 364.0f);
	
	// ポップアップViewの表示
	UIPopoverController *popoverCntl = [[UIPopoverController alloc] 
										initWithContentViewController:vcDatePicker];
	vcDatePicker.popoverController = popoverCntl;
	[popoverCntl presentPopoverFromRect:
	 btnGojyuonSearch.bounds 
								 inView:btnGojyuonSearch 
			   permittedArrowDirections:UIPopoverArrowDirectionUp
							   animated:YES];
    [popoverCntl setPopoverContentSize:CGSizeMake(332.0f, 364.0f)];
#else
    // modalDialogの表示
    [MainViewController showModalDialog:vcDatePicker parentView:nil isDispBottom:NO];
#endif
	vcDatePicker.lblTitle.text = @"検索する来店日を設定してください";
	
    [popoverCntl release];
	[vcDatePicker release];
}

// 施術日による検索Popupの表示
- (void) dispDateSearchPopup
{
    // 日付の設定ポップアップのViewControllerのインスタンス生成
    DateSearchPopup *vcDaySearch
    = [[DateSearchPopup alloc]initWithPopUpViewContoller:POPUP_SEARCH_WORK_DATE
                                       popOverController:nil
                                                callBack:self];

//    vcDaySearch.contentSizeForViewInPopover = CGSizeMake(332.0f, 364.0f);
    
    // ポップアップViewの表示
    UIPopoverController *popoverCntl = [[UIPopoverController alloc]
                                        initWithContentViewController:vcDaySearch];
    vcDaySearch.popoverController = popoverCntl;
    [popoverCntl presentPopoverFromRect:btnGojyuonSearch.bounds
                                 inView:btnGojyuonSearch
               permittedArrowDirections:UIPopoverArrowDirectionUp
                               animated:YES];
    [popoverCntl setPopoverContentSize:CGSizeMake(487.0f, 260.0f)];
    
    [popoverCntl release];
    [vcDaySearch release];
}

// お客様番号による検索
- (void) dispRegistNumberSearchPopup
{
	if (popoverCntlRegNumSearch)
	{
		[popoverCntlRegNumSearch release];
		popoverCntlRegNumSearch = nil;
	}
	
	// お客様番号による検索のViewControllerのインスタンス生成
	UserRegistNuberSearchPopup *vcRegNum
		= [[UserRegistNuberSearchPopup alloc]initWithLastRegNumPopUpViewContoller:POPUP_SEARCH_REGSIT_NUM
									   popOverController:nil 
												callBack:self
										LastRegistNumber:_lastUserRegistNum4Search];
#ifndef CALULU_IPHONE
	// ポップアップViewの表示
	popoverCntlRegNumSearch = 
		[[UIPopoverController alloc] initWithContentViewController:vcRegNum];
	vcRegNum.popoverController = popoverCntlRegNumSearch;
	[popoverCntlRegNumSearch presentPopoverFromRect:btnGojyuonSearch.bounds 
											 inView:btnGojyuonSearch 
						   permittedArrowDirections:UIPopoverArrowDirectionUp
										   animated:YES];
    [popoverCntlRegNumSearch setPopoverContentSize:CGSizeMake(332.0f, 240.0f)];
#else
    [MainViewController showModalDialog:vcRegNum parentView:nil isDispBottom:NO];
#endif
	[vcRegNum release];
}

// お客様番号一覧より検索
-(void) searchByRegistNumberNew:(NSString*)regNumber
{
    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = [self ProgressView:@"お客様番号の検索中です"];
    
    // 処理中ステータスを表示させる
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //お客様番号でユーザ情報リストを更新：番号部分一致検索
        [userInfoList
         setUserInfoListWithRegistNumberNew:regNumber];
        
        [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
        
        // tableViewの再読み込み
        [myTableView reloadSectionIndexTitles];
        [indexTableView reloadSectionIndexTitles];
        [myTableView reloadData];
        [self updateLblCustomerKarteAll];
        [self chkResultCount];
        
        // ツールバーボタンのEnable設定
        [self setToolButtonEnable:NO];
        
        // 現在選択ユーザの初期化
        // [self initSelectedUser];
        // 先頭のユーザを選択
        [self selectUserOnListWithIndexPath:0 section:0];
        // 処理中インジケータを閉じる
        [_bottomDialog dismissDialogViewControllerAnimated:YES];
        [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
    });
}

-(void) searchByRegistNumber:(NSInteger)regNumber
{
    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = [self ProgressView:@"お客様番号の検索中です"];
    
    // 処理中ステータスを表示させる
    dispatch_async(dispatch_get_main_queue(), ^{

        //お客様番号でユーザ情報リストを更新：番号部分一致検索
        [userInfoList
         setUserInfoListWithRegistNumber:regNumber];
        
        [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
        
        // tableViewの再読み込み
        [myTableView reloadSectionIndexTitles];
        [indexTableView reloadSectionIndexTitles];
        [myTableView reloadData];
        [self updateLblCustomerKarteAll];
        [self chkResultCount];
        
        // ツールバーボタンのEnable設定
        [self setToolButtonEnable:NO];
        
        // 現在選択ユーザの初期化
        // [self initSelectedUser];
        // 先頭のユーザを選択
        [self selectUserOnListWithIndexPath:0 section:0];
        // 処理中インジケータを閉じる
        [_bottomDialog dismissDialogViewControllerAnimated:YES];
        [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
    });
}

/**
 生年月日による検索Popupの表示
 */
- (void) dispBirthdaySearchPopup
{
	BirthdaySearchPopup* popup = [[BirthdaySearchPopup alloc] initWithDelegate:self];

	if ( popup != nil )
	{
		// ポップオーバーの表示
		UIPopoverController* controller = [[UIPopoverController alloc] initWithContentViewController:popup];
		[popup setPopOverController:controller];
		[controller presentPopoverFromRect:btnGojyuonSearch.bounds
									inView:btnGojyuonSearch
				  permittedArrowDirections:UIPopoverArrowDirectionAny
								  animated:YES];
        [controller setPopoverContentSize:CGSizeMake(400.0f, 305.0f)];
        [controller release];
	}
	//
	[popup release];
}

/**
 最新施術日による検索Popupの表示
 */
- (void) dispLastWorkDateSearchPopup
{
	LastWorkDateSearchPopup* popup = [[LastWorkDateSearchPopup alloc] initWithDelegate:self];
	
	if ( popup != nil )
	{
		// ポップオーバーの表示
		UIPopoverController* controller = [[UIPopoverController alloc] initWithContentViewController:popup];
		[popup setPopOverController:controller];
		[controller presentPopoverFromRect:btnGojyuonSearch.bounds
									inView:btnGojyuonSearch
				  permittedArrowDirections:UIPopoverArrowDirectionAny
								  animated:YES];
        [controller setPopoverContentSize:CGSizeMake(650.0f, 304.0f)];
        [controller release];
	}
	//
	[popup release];
}

/**
 メモによる検索Popupの表示
 */
- (void) dispMemoSearchPopup
{
	MemoSearchPopup* popup = [[MemoSearchPopup alloc] initWithDelegate:self];
	
	if ( popup != nil )
	{
		// ポップオーバーの表示
		UIPopoverController* controller = [[UIPopoverController alloc] initWithContentViewController:popup];
		[popup setPopOverController:controller];
		[controller presentPopoverFromRect:btnGojyuonSearch.bounds
									inView:btnGojyuonSearch
				  permittedArrowDirections:UIPopoverArrowDirectionAny
								  animated:YES];
        [controller setPopoverContentSize:CGSizeMake(325.0f, 601.0f)];
        [controller release];
	}
	//
	[popup release];
}


//////////////////////////////////////////////////////////
// ツールバーItem
//////////////////////////////////////////////////////////
// メール情報の編集
- (IBAction)OnEditMailSetting:(id)sender{
    
    /*
	// ポップアップViewの表示
	popoverCntlEditUser =
    [[UIPopoverController alloc] initWithContentViewController:vcEditUser];
	vcEditUser.popoverController = popoverCntlEditUser;
	[popoverCntlEditUser presentPopoverFromRect:imgViewNowUsrFrame.bounds
										 inView:self.view
					   permittedArrowDirections:UIPopoverArrowDirectionUp
									   animated:YES];
     */
}
// 新規お客様
- (IBAction) OnNewUer:(id)sender
{
#ifdef TRIAL_VERSION
	// トライアルバージョンの場合は新規ユーザの作成ができなくする
	[self openCaLuLuHpWithMsg];
	return;
#endif
	
#ifdef USE_ACCOUNT_MANAGER
	// アカウントに未ログインでは新規ユーザの作成はできない
	if (! [MainViewController showAccountNoLoginDialog:@"新規にお客様の\n作成はできません"])
	{	return; }
#endif

//2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ顧客作成は１０件まで
#ifdef FOR_SALES
    userDbManager2 *usrDbMng2 = [[userDbManager2 alloc] init];
    NSInteger countOfStoreUsers = [usrDbMng2 getCountStoreUsers];
    //NSArray *users = [usrDbMng getAllUsers];
    if (countOfStoreUsers >=10) {
        [self alertDisp:@"デモバージョンのため\n１０件を超えるお客様の作成はできません\n"
             alertTitle:@"デモ版"];
        [usrDbMng2 release];
        return;
    }
    [usrDbMng2 release];
#endif
    
	// 横向きのときは、新規登録ができないようにダイアログを表示する
	// MainViewControllerの取得
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController; 
	if (UIInterfaceOrientationIsLandscape([mainVC getNowDeviceOrientation]) )
	{
		[ self alertDisp:@"新規にお客様を作成するときは\niPadを縦向きにしてください" 
			  alertTitle:@"お客様の新規作成"];
		return;
	}
	
	if (popoverCntlEditUser)
	{
		[popoverCntlEditUser release];
		popoverCntlEditUser = nil;
	}
	
	// ユーザ情報編集のViewControllerのインスタンス生成
	vcEditUser
		= [[UserInfoEditViewController alloc]
		   initWithNewUserPopUpViewContoller:POPUP_NEW_USER
			   popOverController:nil
			   callBack:self];
//    mainVC.enableRotate = NO;
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    app.navigationController.enableRotate = NO;
    [privacyView setFrame:app.window.frame];
    privacyView.backgroundColor = [UIColor colorWithPatternImage:[[mainVC getMainViewController] blurredSnapshotWithBlurType:BlurEffectsTypeLight]];
    [self.view addSubview:privacyView];

#ifndef CALULU_IPHONE
	// ポップアップViewの表示
	popoverCntlEditUser = 
		[[UIPopoverController alloc] initWithContentViewController:vcEditUser];
	vcEditUser.popoverController = popoverCntlEditUser;
#ifdef DEF_ABCARTE
	[popoverCntlEditUser presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2, 0, 1, 1)
										 inView:self.view
					   permittedArrowDirections:UIPopoverArrowDirectionUp
									   animated:YES];
#else
    [popoverCntlEditUser presentPopoverFromRect:lblLastWorkDate.bounds
                                         inView:self.view
                       permittedArrowDirections:UIPopoverArrowDirectionUp
                                       animated:YES];
#endif
	
    [popoverCntlEditUser setPopoverContentSize:CGSizeMake(740.0f, 660.0f) animated:NO];
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:vcEditUser];
#endif
	
    //画面外をタップしてもポップアップが閉じないようにする処理
    //2012 6/25 伊藤 お客様情報編集中にポップアップが閉じない処理の一部
    NSMutableArray *viewCof = [[NSMutableArray alloc]init];
    [viewCof addObject:self.view];
    [viewCof addObject:mainVC.view];
    popoverCntlEditUser.passthroughViews = viewCof;
    self.view.userInteractionEnabled = NO;
    [mainVC viewScrollLock:YES];

    [viewCof release];
    
	[vcEditUser release];
}

// 新規お客様
- (IBAction) OnNewUer_:(id)sender
{
	if (popoverCntlNewUser)
	{
		[popoverCntlNewUser release];
		popoverCntlNewUser = nil;
	}
	
	// 新規ユーザViewControllerのインスタンス生成
	newUserViewController *vcNewUser = 
		[[newUserViewController alloc]initWithPopUpViewContoller:POPUP_NEW_USER
											   popOverController:popoverCntlNewUser
														callBack:self];
	vcNewUser.contentSizeForViewInPopover = CGSizeMake(320.0f, 220.0f);
	
	// ポップアップViewの表示
	popoverCntlNewUser = [[UIPopoverController alloc] 
						  initWithContentViewController:vcNewUser];
	// [popoverCntlNewUser setContentViewController:vcNewUser animated:NO];
	vcNewUser.popoverController = popoverCntlNewUser;
	[popoverCntlNewUser presentPopoverFromRect:
	 imgViewNowUsrFrame.bounds 
										inView:imgViewNowUsrFrame 
					  permittedArrowDirections:UIPopoverArrowDirectionUp 
									  animated:YES];
	// [popoverCntlNewUser setPopoverContentSize:CGSizeMake(320.0f, 180.0f)];
	
	[vcNewUser release];
	
}

// 検索解除
- (IBAction) OnSerach:(id)sender
{
	if (btnSearch.tag == 1) 
	{
		// 検索解除
		// キーボードを隠す
		[mySearchBar resignFirstResponder];
		// 検索文字のクリア：解除となる
		mySearchBar.text = @"";
        
        // 検索バーを隠す
        [self _dispCtrlSearchBar:NO];
        
		// 検索解除ボタンの無効設定
		// btnSearch.enabled = NO;
		
		// 検索ボタンの役割設定
		btnSearch.title = @"検索条件";
        btnGojyuonSearch.searching = NO;
		btnSearch.tag = 0;
        
        [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
        
        selectJyoukenKind = SELECT_NONE;

		// 処理中ステータス表示
        UILockWindowController *_bottomDialog = [self ProgressView:@"顧客データの読み取り中です"];

        // わざと DISPATCH_QUEUE_PRIORITY_LOW で優先度を下げて、処理中ステータスを表示させる
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            //全ユーザでユーザ情報リストを更新
            if (sender)
            {	[userInfoList setUserInfoList:@"" selectKind:SELECT_NONE]; }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // tableViewの再読み込み
                [myTableView reloadSectionIndexTitles];
                [indexTableView reloadSectionIndexTitles];
                [myTableView reloadData];
                [self updateLblCustomerKarteAll];
                
                // ツールバーボタンのEnable設定
                [self setToolButtonEnable:NO];
                
                if (currentUserId >= 0)
                {
                    //現在選択中のユーザをTableView上で選択する
                    [self selectedUserOnTableViewWithUID:currentUserId];
                }
                else 
                {
                    // 現在選択ユーザの初期化
                    [self initSelectedUser];
                }
                // 処理中インジケータを閉じる
                [_bottomDialog dismissDialogViewControllerAnimated:YES];
                [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
            });
        });
	}
	else if (btnSearch.tag == 2)  
	{
		// お客様番号検索用アクションシートを作る
#ifndef CALULU_IPHONE
        UIActionSheet *sheet;
        if(iOSVersion<8.0) {
            sheet =
            [[UIActionSheet alloc] initWithTitle:@"検索する条件を選んでください"
                                        delegate:self
                               cancelButtonTitle:@"キャンセル"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"お客様番号で検索",@"お客様番号一覧を再表示",@"お客様名一覧を表示", @"キャンセル", nil];
        } else {
#ifdef SUPPORT_IOS8
            NSArray *searchConditions = [NSArray arrayWithObjects:@"お客様番号で検索",@"お客様番号一覧を再表示",@"お客様名一覧を表示", @"キャンセル", nil];
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"検索する条件を選んでください"
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleActionSheet];
            [searchConditions enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
                if ([obj isEqualToString:nil]) {
                    *stop = YES;
                } else if ([obj isEqualToString:@"キャンセル"]) {
                    // キャンセル用のアクション追加
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction *action) {
                                                                [self actionSheetHandlerWithRegistNumSearch:idx];
                                                            }]];
                } else {
                    // 通常検索アクション追加
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [self actionSheetHandlerWithRegistNumSearch:idx];
                                                            }]];
                    
                }
            }];
            UIPopoverPresentationController *pop = [alert popoverPresentationController];
            pop.sourceView = btnGojyuonSearch;
            pop.sourceRect = btnGojyuonSearch.bounds;
            
            [self presentViewController:alert animated:YES completion:nil];
#endif
        }
#else
        UIActionSheet *sheet;
        if ([MainViewController isNowDeviceOrientationPortrate])
        {
            sheet =
            [[UIActionSheet alloc] initWithTitle:@"検索する条件を選んでください" 
                                        delegate:self 
                               cancelButtonTitle:@"キャンセル"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"お客様番号で検索", @"お客様番号一覧を再表示",@"お客様名一覧を表示", nil];
        }
        else
        {
            sheet =
            [[UIActionSheet alloc] initWithTitle:@"検索する条件を選んでください" 
                                        delegate:self 
                               cancelButtonTitle:@"キャンセル"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"お客様番号一覧を再表示",@"お客様名一覧を表示", nil];
        }
#endif
        if (iOSVersion<8.0) {
            [sheet autorelease];
            sheet.actionSheetStyle = UIActionSheetStyleDefault;
#ifndef CALULU_IPHONE
            sheet.cancelButtonIndex = 3;
#endif
            sheet.tag = 2;
            
            // アクションシートを表示する
            [sheet showFromRect:btnGojyuonSearch.bounds inView:btnGojyuonSearch animated:YES];
        }
	}
#ifdef CALULU_IPHONE
	else if (btnSearch.tag == 100)  
	{
		// 検索で表示されているkeyboardを隠す
		[mySearchBar resignFirstResponder];
		
		// 検索文字のクリア：解除となる
		mySearchBar.text = @"";
        
        // 検索バーを隠す
        [self _dispCtrlSearchBar:NO];

		// 検索解除ボタンの無効設定
		// btnSearch.enabled = NO;
		
		// 検索ボタンの役割設定
		btnSearch.title = @"検索条件";
        btnGojyuonSearch.searching = NO;
		btnSearch.tag = 0;
	}
#endif
	else 
	{
		// 通常検索用アクションシートを作る
#ifndef CALULU_IPHONE
        UIActionSheet *sheet;
        if(iOSVersion<8.0) {
#ifdef DEF_ABCARTE
            if (isJapanese) {
                sheet =
                [[UIActionSheet alloc] initWithTitle:@"検索する条件を選んでください"
                                            delegate:self
                                   cancelButtonTitle:SS_CANCEL
                              destructiveButtonTitle:nil
                                   otherButtonTitles:SS_WORD_IDX,       SS_LAST_NAME,   SS_RESPONSIBLE,   SS_TREAT_DAY,
                                                     SS_CUSTOMER_NUM,    SS_BIRTHDAY,    //SS_LATEST_DAY,
                                                    //2016/4/9 TMS 顧客検索条件追加
                                                     SS_MEMO,  SS_MAIL_UNREAD,  SS_MAIL_TENPO_UNREAD,            SS_MAIL_TENPO_ANSWER,  SS_MAIL_ERROR,
                                                     SS_CANCEL,          nil];
            } else {
                sheet =
                [[UIActionSheet alloc] initWithTitle:@"検索する条件を選んでください"
                                            delegate:self
                                   cancelButtonTitle:SS_CANCEL
                              destructiveButtonTitle:nil
                                   otherButtonTitles:SS_TREAT_DAY,
                                                     SS_CUSTOMER_NUM,    SS_BIRTHDAY,    //SS_LATEST_DAY,
                                                    //2016/4/9 TMS 顧客検索条件追加
                                                    SS_MEMO,  SS_MAIL_UNREAD,  SS_MAIL_TENPO_UNREAD,            SS_MAIL_TENPO_ANSWER,  SS_MAIL_ERROR,
                                                    SS_CANCEL,          nil];
            }
#else
            sheet =
            [[UIActionSheet alloc] initWithTitle:@"検索する条件を選んでください"
                                        delegate:self
                               cancelButtonTitle:SS_CANCEL
                          destructiveButtonTitle:nil
                               otherButtonTitles:SS_WORD_IDX,       SS_LAST_NAME,   SS_RESPONSIBLE,   SS_TREAT_DAY,
                                                SS_CUSTOMER_NUM,    SS_BIRTHDAY,    //SS_LATEST_DAY,
                                                SS_MEMO,
                                                SS_CANCEL, nil];
#endif
        } else {
#ifdef SUPPORT_IOS8
#ifdef DEF_ABCARTE
            NSArray *jpConditions = @[SS_WORD_IDX,      SS_LAST_NAME,   SS_RESPONSIBLE,   SS_TREAT_DAY,
                                      SS_CUSTOMER_NUM,  SS_BIRTHDAY,
                                      //2016/4/9 TMS 顧客検索条件追加
                                      SS_MEMO,  SS_MAIL_UNREAD,SS_MAIL_TENPO_UNREAD,
                                      SS_MAIL_TENPO_ANSWER,          SS_MAIL_ERROR,
                                      SS_CANCEL];
            NSArray *enConditions = @[SS_TREAT_DAY,
                                      SS_CUSTOMER_NUM,  SS_BIRTHDAY,
                                      //2016/4/9 TMS 顧客検索条件追加
                                      SS_MEMO,  SS_MAIL_UNREAD,SS_MAIL_TENPO_UNREAD,
                                      SS_MAIL_TENPO_ANSWER,          SS_MAIL_ERROR,
                                      SS_CANCEL];
            NSArray *searchConditions = (isJapanese)? jpConditions : enConditions;
            //2016/4/9 TMS 顧客検索条件追加
            int btn_jidx[] = {SEARCH_WORD_IDX, SEARCH_LAST_NAME_IDX, SEARCH_RESPONSIBLE_IDX, SEARCH_TREAT_DAY_IDX,
                              SEARCH_CUSTOMER_NUM_IDX, SEARCH_BIRTHDAY_IDX, SEARCH_MEMO_IDX,
                               SEARCH_MAIL_UNREAD_IDX, SEARCH_MAIL_TENPO_UNREAD_IDX, SEARCH_MAIL_TENPO_ANSWER_IDX,SEARCH_MAIL_ERROR_IDX, SEARCH_CANCEL_IDX};
            int btn_eidx[] = {SEARCH_TREAT_DAY_IDX, SEARCH_CUSTOMER_NUM_IDX, SEARCH_BIRTHDAY_IDX,
                              SEARCH_MEMO_IDX, SEARCH_MAIL_UNREAD_IDX, SEARCH_MAIL_TENPO_UNREAD_IDX, SEARCH_MAIL_TENPO_ANSWER_IDX, SEARCH_MAIL_ERROR_IDX,SEARCH_CANCEL_IDX};
            int *lang_idx = (isJapanese)? btn_jidx : btn_eidx;
#else
            NSArray *searchConditions = @[SS_WORD_IDX,      SS_LAST_NAME,   SS_RESPONSIBLE,   SS_TREAT_DAY,
                                         SS_CUSTOMER_NUM,   SS_BIRTHDAY,    //SS_LATEST_DAY,
                                         SS_MEMO,
                                         SS_CANCEL];
#endif
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"検索する条件を選んでください"
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleActionSheet];

            [searchConditions enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
                NSUInteger search_idx = lang_idx[idx];
                if ([obj isEqualToString:nil]) {
                    *stop = YES;
                } else if ([obj isEqualToString:SS_CANCEL]) {
                    // キャンセル用のアクション追加
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction *action) {
                                                                [self actionSheetHandlerWithNormalSearch:search_idx];
                                                            }]];
                } else {
                    // 通常検索アクション追加
                    [alert addAction:[UIAlertAction actionWithTitle:obj
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [self actionSheetHandlerWithNormalSearch:search_idx];
                                                            }]];

                }
            }];
            UIPopoverPresentationController *pop = [alert popoverPresentationController];
            pop.sourceView = btnGojyuonSearch;
            pop.sourceRect = btnGojyuonSearch.bounds;

            [self presentViewController:alert animated:YES completion:nil];
#endif // SUPPORT_IOS8
        }
#else
        UIActionSheet *sheet;
        if ([MainViewController isNowDeviceOrientationPortrate])
        {
            sheet =
            [[UIActionSheet alloc] initWithTitle:@"検索する条件を選んでください" 
                                        delegate:self 
                               cancelButtonTitle:@"キャンセル"
                          destructiveButtonTitle:nil
                                otherButtonTitles:@"五十音で検索", @"お客様名で検索", @"来店日で検索", @"お客様番号一覧を表示", nil];
        }
        else
        {
            sheet =
            [[UIActionSheet alloc] initWithTitle:@"検索する条件を選んでください" 
                                        delegate:self 
                               cancelButtonTitle:@"キャンセル"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"お客様番号一覧を表示", nil];
        }
            
#endif
        if (iOSVersion<8.0) {
            [sheet autorelease];
            sheet.actionSheetStyle = UIActionSheetStyleDefault;
#ifndef CALULU_IPHONE
#ifdef DEF_ABCARTE
            //2016/4/9 TMS 顧客検索条件追加
            if (isJapanese) {
                sheet.cancelButtonIndex = 12;
            } else {
                sheet.cancelButtonIndex = 9;
            }
#else
            sheet.cancelButtonIndex = 7;
#endif  // DEF_ABCARTE
#endif  // CALULU_IPHONE
            sheet.tag = 0;
            
            // アクションシートを表示する
            [sheet showFromRect:btnGojyuonSearch.bounds inView:btnGojyuonSearch animated:YES];
        }
	}
}

/**
 * メール送信者情報設定ポップアップの表示
 * @param なし
 * @return なし
 */
- (void)SmtpInfoSetUp
{
    if (popoverCntlSmtpSetup)
	{
		[popoverCntlSmtpSetup release];
		popoverCntlSmtpSetup = nil;
	}
    MailSettingPopup *mailSettingViewController =
    [[MailSettingPopup alloc] initPopUpViewWithPopupID:POPUP_MAIL_SETTING
                                     popOverController:popoverCntlSmtpSetup
                                              callBack:self];
    
	popoverCntlSmtpSetup =
    [[UIPopoverController alloc] initWithContentViewController:mailSettingViewController];
    
	mailSettingViewController.popoverController = popoverCntlSmtpSetup;
#ifndef CALULU_IPHONE
	// ポップアップViewの表示
	[popoverCntlSmtpSetup presentPopoverFromRect:btnMnuEditer.bounds
										 inView:btnSanshouPage
					   permittedArrowDirections:UIPopoverArrowDirectionUp
									   animated:YES];
    [popoverCntlSmtpSetup setPopoverContentSize:CGSizeMake(400.0f, 195.0f)];
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:setupSmtpViewController];
#endif
    [mailSettingViewController release];
}

// お客様情報更新
- (IBAction) OnUserInfoUpadte:(id)sender
{
    // 横向きのときは、顧客編集ができないようにダイアログを表示する
	// MainViewControllerの取得
	MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController; 
	if (UIInterfaceOrientationIsLandscape([mainVC getNowDeviceOrientation]) )
	{
        [ self alertDisp:@"お客様の情報を編集するときは\niPadを縦向きにしてください"
              alertTitle:@"お客様の情報を編集"];
        return;
	}
    
	// 念のため現在選択中のユーザを確認
	if (currentUserId <= 0)
	{	return; }

//2016/3/17 TMS デモ版のみログイン確認を回避
#ifndef FOR_SALES
    // アカウントログイン済みの時のみ有効(アカウントログイン済みかつAppStore購入でない場合)
    if([AccountManager isLogined] && ![AccountManager isAppleStore]) {
        // クラウドよりお客様のメールアドレスを取得し、異なればローカルDBのメールアドレス１のみを更新する
        [MailAddressSyncManager syncMailAddresses:currentUserId];
    }
#endif
	
	// ユーザマスタの取得
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	mstUser *user = [usrDbMng getMstUserByID:currentUserId];	

    if (popoverCntlEditUser) {
        popoverCntlEditUser.passthroughViews = nil;
        popoverCntlEditUser = nil;
    }
    if (vcEditUser) {
        [vcEditUser release];
        vcEditUser = nil;
    }
	// ユーザ情報編集のViewControllerのインスタンス生成
	vcEditUser
        = [[UserInfoEditViewController alloc]initWithUserEditPopUpViewContoller:POPUP_EDIT_USER
                                                              popOverController:nil
                                                                       callBack:self
                                                                      user4Edit:user];
    
    vcEditUser.viewMode = (int)[sender tag];
    
//    mainVC.enableRotate = NO;
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    app.navigationController.enableRotate = NO;

    [privacyView setFrame:app.window.frame];
    privacyView.backgroundColor = [UIColor colorWithPatternImage:[[mainVC getMainViewController] blurredSnapshotWithBlurType:BlurEffectsTypeLight]];
    [self.view addSubview:privacyView];
#ifdef WEB_MAIL_FUNC
	// BlockMailStatusを取得する
	if ( blockMailStatus != nil )
	{
		[blockMailStatus release];
		blockMailStatus = nil;
	}
	
    // アカウントログイン済かつAppStore購入でない場合
    if([AccountManager isLogined] && ![AccountManager isAppleStore] &&
       (![[ShopManager defaultManager] isAccountShop] || user.shopID!=0)) {
        blockMailStatus = [[BlockMailStatus alloc] initWithDelegate:vcEditUser];
        [blockMailStatus setUserId:currentUserId];
        [blockMailStatus getBlockMailStatus];
    }
#endif
#ifndef CALULU_IPHONE
	// ポップアップViewの表示
	popoverCntlEditUser = 
        [[UIPopoverController alloc] initWithContentViewController:vcEditUser];
	vcEditUser.popoverController = popoverCntlEditUser;
#ifdef DEF_ABCARTE
	[popoverCntlEditUser presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2, 0, 1, 1)
										 inView:self.view
					   permittedArrowDirections:UIPopoverArrowDirectionUp
									   animated:YES];
#else
    [popoverCntlEditUser presentPopoverFromRect:lblLastWorkDate.bounds
                                         inView:self.view
                       permittedArrowDirections:UIPopoverArrowDirectionUp
                                       animated:YES];
#endif
	[popoverCntlEditUser setPopoverContentSize:CGSizeMake(740.0f, 660.0f) animated:NO];
//    [popoverCntlEditUser setPopoverContentSize:CGSizeMake(740.0f, 513.0f) animated:NO];
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:vcEditUser];
#endif
	
    //画面外をタップしてもポップアップが閉じないようにする処理
    //2012 6/25 伊藤 お客様情報編集中にポップアップが閉じない処理の一部
    NSMutableArray *viewCof = [[NSMutableArray alloc]init];
    [viewCof addObject:self.view];
    [viewCof addObject:mainVC.view];
    popoverCntlEditUser.passthroughViews = viewCof;
    self.view.userInteractionEnabled = NO;
    [mainVC viewScrollLock:YES];
    
    [viewCof release];
    
	[vcEditUser release];
    [user release];
	[usrDbMng release];
}

// お客様情報削除
- (IBAction) OnUserInfoDelete:(id)sender
{
	// 念のため現在選択中のユーザを確認
	if (currentUserId <= 0)
	{	return; }
    
#ifdef USE_ACCOUNT_MANAGER
	// アカウントに未ログインではユーザの削除はできない
	if (! [MainViewController showAccountNoLoginDialog:@"お客様の削除\nはできません"])
	{	return; }
#endif
	
	// ユーザ情報削除AlertViewの表示
	alertUserInfoDelete.message = [NSString stringWithFormat: 
								   @"%@様情報と全ての画像を削除します。よろしいですか？\n(削除すると元に戻せません。)",
								   lblName.text];
	[alertUserInfoDelete show];
	
}

// 履歴一覧の表示へ
- (IBAction) OnHistWorkView:(id)sender
{
	// 念のため現在選択中のユーザを確認
	if (currentUserId <= 0)
	{	return; }
	
	HistListViewController *window  
	= [[HistListViewController alloc]
	   initWithNibName:@"HistListViewController" bundle:nil];
	
	// 現在選択中のユーザIDと名前を渡す
	window.selectedUserID = currentUserId;
	window.selectedUserName = lblName.text;
	
	[self.navigationController pushViewController:window animated:YES];
	
	[window release];
	
	// 遷移画面を履歴一覧にする
	_windowView = WIN_VIEW_HIST_LIST;
}

// カメラ画面へ
- (IBAction) OnCameraView:(id)sender
{
	// 念のため現在選択中のユーザを確認
	if (currentUserId <= 0)
	{	return; }
	
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
	
	// 履歴IDをデータベースよりユーザIDと当日で取得する:当日の履歴がない場合は作成する
	HISTID_INT hID;
	userDbManager *usrDbMng = [[userDbManager alloc] init];
    
    hID = [usrDbMng getHistIDWithDateUserID:currentUserId workDate:[NSDate date] isMakeNoRecord:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"in bool value = %d",[defaults boolForKey:@"CarteFromNew"]);
    if (hID < 0) {
        NSLog(@"No Data remain");
        [defaults setBool:YES forKey:@"CarteFromNew"];
        [defaults synchronize];
    } else {
        [defaults setBool:NO forKey:@"CarteFromNew"];
        [defaults synchronize];
    }
    
	if ( (hID = [usrDbMng getHistIDWithDateUserID:currentUserId 
										 workDate:[NSDate date]
								   isMakeNoRecord:YES] ) < 0)
	{
		// エラーでも続行する
		NSLog(@"getHistIDWithDateUserID error on iPadCameraVC! but continue");
	}
	
	// 取得した履歴IDと当日を渡す
	cameraView.histID = hID;
	cameraView.workDate = [NSDate date];
	
	// カメラ画面の表示
	[mainVC showPopupWindow:cameraView];
		// [mainVC.navigationController pushViewController:cameraView animated:NO];
    // iOS7で時間を置かずに setSelectedUser を呼ぶと、ViewDidLoadが終了していないため
    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        // 現在選択中のユーザIDを渡す
        [cameraView setSelectedUser:currentUserId userName:lblName.text nameColor:[Common getNameColorWithSex:([lblSex.text isEqualToString:STRING_SEX_MALE])]];
        
        // 現在のデバイスの向きを取得
        UIInterfaceOrientation orient = [mainVC getNowDeviceOrientation];
        // デバイスの向きを設定する
        [cameraView willRotateToInterfaceOrientation:orient duration:(NSTimeInterval)0];
    });

	[cameraView release];

    // cameraView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    // [self presentModalViewController:cameraView animated:YES];
	
	[usrDbMng release];
	 
	// 遷移画面をカメラ画面にする
	_windowView = WIN_VIEW_CAMERA;
}

// メンテナンス
- (IBAction) OnMaintenace:(id)sender
{
	if (popoverCntlMainte)
	{
		[popoverCntlMainte release];
		popoverCntlMainte = nil;
	}
	
	// メンテナンスViewControllerのインスタンス生成
	maintenaceViewController *vc = [[maintenaceViewController alloc] initWithPopUpViewContoller:
									POPUP_MAINTENACE
																			  popOverController:nil
																					   callBack:self];
	vc.contentSizeForViewInPopover = CGSizeMake(320.0f, 240.0f);
	
	popoverCntlMainte = [[UIPopoverController alloc] 
						 initWithContentViewController:vc];
	// [popoverCntlMainte setContentViewController:vc animated:NO];
	vc.popoverController = popoverCntlMainte;
	[popoverCntlMainte presentPopoverFromBarButtonItem:btnMaintenace 
							  permittedArrowDirections:UIPopoverArrowDirectionDown 
											  animated:YES];
	
	[vc release];
	
}

// 五十音検索
- (IBAction)onTopImgPressed:(id)sender {
}

- (IBAction) OnGojyuonSearch:(id)sender
{
	if (popoverCntlGojyuSearch)
	{
		[popoverCntlGojyuSearch release];
		popoverCntlGojyuSearch = nil;
	}
	
	// 五十音検索のViewControllerのインスタンス生成
#ifndef CALULU_IPHONE
    GojyuonSearchPopup *vcGoSearch 
        = [[GojyuonSearchPopup alloc]initWithPopUpViewContoller:POPUP_SEARCH_GOJYUON
                                              popOverController:nil 
                                                       callBack:self];
#else
	
	GojyuonSearchPopup *vcGoSearch 
        = [[GojyuonSearchPopup alloc]initWithPopUpViewContoller:POPUP_SEARCH_GOJYUON
                                              popOverController:nil 
                                                       callBack:self nibName:@"ip_GojyuonSearchPopup"];
#endif
	
	// ポップアップViewの表示
#ifndef CALULU_IPHONE
	popoverCntlGojyuSearch = [[UIPopoverController alloc] 
							  initWithContentViewController:vcGoSearch];
	vcGoSearch.popoverController = popoverCntlGojyuSearch;
	[popoverCntlGojyuSearch presentPopoverFromRect:btnGojyuonSearch.bounds 
											inView:btnGojyuonSearch 
						  permittedArrowDirections:UIPopoverArrowDirectionUp 
										  animated:YES];
    [popoverCntlGojyuSearch setPopoverContentSize:CGSizeMake(680.0f, 305.0f)];
#else
    [MainViewController showModalDialog:vcGoSearch parentView:nil isDispBottom:NO];
#endif
	
	[vcGoSearch release];
}

// 特定のブラウザページへ遷移
- (IBAction)OnJumpSanshouPage:(id)sender
{
    if (iOSVersion<8.0) {
        [self _otherInfoActionSheetDisp];
    } else {
        [self _otherInfoActionSheetDispOS8];
    }
}

#ifdef DEF_ABCARTE
#define DEFAULT_HP  @"http://www.abcarte.jp"
#else
#define DEFAULT_HP  @"http://www.calulu.jp/kinou.html"
#endif
// アプリケーションHPを表示
- (void) appliDocUrl
{
    // 取扱説明書URLの取得
    NSString *urlString  = [AccountManager isHpUrl];
#ifdef DEBUG
    NSLog(@"doc_url [%@]", urlString);
#endif
    if(urlString==NULL)
        urlString = DEFAULT_HP;
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
}

#ifdef VER_113_LATER
#define ACCOUNT_GET_BUTTON_TITLE        @"アカウントへログイン"
#else
#define ACCOUNT_GET_BUTTON_TITLE        @"アカウント情報の入力"
#endif

// アカウントログインボタン
- (IBAction) OnAccountLogin:(id)sender
{
#ifndef USE_ACCOUNT_MANAGER
	// アカウント管理が有効時のみ
	return;
#else
    if(iOSVersion<8.0) {

        UIActionSheet *sheet =
        [[UIActionSheet alloc] initWithTitle:@"ログインされていません"
                                    delegate:self
                           cancelButtonTitle:@"キャンセル"
                      destructiveButtonTitle:nil
#ifndef CALULU_IPHONE
#ifdef FOR_REJECT
                           otherButtonTitles:ACCOUNT_GET_BUTTON_TITLE, @"キャンセル", nil];
#else
                           otherButtonTitles:@"お問い合わせ", ACCOUNT_GET_BUTTON_TITLE, @"キャンセル", nil];
#endif
#else
    otherButtonTitles:@"お問い合わせ", ACCOUNT_GET_BUTTON_TITLE, nil];
#endif
        sheet.tag = 64;
        
        [sheet autorelease];
        sheet.actionSheetStyle = UIActionSheetStyleDefault;
        
        // アクションシートを表示する
        [sheet showInView:self.view];
    } else {    // iOS8以降での動作
#ifdef SUPPORT_IOS8
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"ログインされていません"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];
#ifdef FOR_REJECT
        [alert addAction:[UIAlertAction actionWithTitle:ACCOUNT_GET_BUTTON_TITLE
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // アカウント管理が有効時のみ:お問い合わせとログイン
                                                    [self _actionLoginContact:0];
                                                }]];
#else
        [alert addAction:[UIAlertAction actionWithTitle:@"お問い合わせ"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // アカウント管理が有効時のみ:お問い合わせとログイン
                                                    [self _actionLoginContact:0];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:ACCOUNT_GET_BUTTON_TITLE
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // アカウント管理が有効時のみ:お問い合わせとログイン
                                                    [self _actionLoginContact:1];
                                                }]];
#endif
        [alert addAction:[UIAlertAction actionWithTitle:@"キャンセル"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) {
                                                    
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
#endif
    }
    
#endif
}

// ユーザ情報の操作ボタン(for iPhone)
- (IBAction) OnUserInfoOprButton:(id)sender
{
#ifndef CALULU_IPHONE
    return;
#else
    // ユーザ情報の操作のアクションシートを表示
    [self _userInfoOprActionSheetDisp];
#endif
}

#ifdef CLOUD_SYNC

// 店舗の選択 (for iPad)
- (IBAction) OnBtnShopSelect:(id)sender
{
#ifdef CALULU_IPHONE
    return;
#endif
    
    if (popoverCntlSelectShop)
    {
        [popoverCntlSelectShop release];
        popoverCntlSelectShop = nil;
    }
    
    // 店舗選択ポップアップのViewControllerのインスタンス生成 : POPUP_SELECT_SHOP
    ShopSelectPopup *shopSel
        = [[ShopSelectPopup alloc] initMultiSelectWithItems:nil 
                                                    popUpID:POPUP_SELECT_SHOP callBack:self];
#ifndef CALULU_IPHONE  
    // ポップアップViewの表示
    
    popoverCntlSelectShop = 
        [[UIPopoverController alloc] initWithContentViewController:shopSel];
    shopSel.popoverController = popoverCntlSelectShop;
    CGRect rect = [self.view convertRect:btnSanshouPage.bounds fromView:btnSanshouPage];
    [popoverCntlSelectShop presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    if ([shopSel respondsToSelector:@selector(setPreferredContentSize:)]) {
        [shopSel setPreferredContentSize:CGSizeMake(560.0f, 370.0f)];
    }
#else
    
#endif
    
    [shopSel release];
    
}
#endif

// 編集 (for iPad)
- (IBAction) OnBtnMnuEditer:(id)sender
{
#ifdef CALULU_IPHONE
    return;
#endif
    // ユーザ情報の操作のアクションシートを表示
    [self _userInfoOprActionSheetDisp];
}

// Cloudと同期ボタン
- (IBAction) OnBtnMnuCloud:(id)sender
{
#ifdef CLOUD_SYNC
    // Cloud同期のアクションシートを表示
    [self _cloudSyncActionSheetDisp];
#endif
}

// 参考画像の表示ボタン
- (IBAction) OnBtnReferenceShow:(id)sender
{
    [MainViewController showReferenseWeb];
}
//////////////////////////////////////////////////////////

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

// 縦横切り替え後のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef CALULU_IPHONE
    // ユーザ情報の操作ボタンはportraitのみ有効
    btnUserInfoOprate.enabled = UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
#else
    
#ifdef BTN_MNU_EDITER_PRORAMBLE_ROTATE
    // 編集ボタン(for iPad)を常に画面中央にf
    CGRect btnRect = btnMnuEditer.frame;
    
    /*CGRect scrRect = [[UIScreen mainScreen] applicationFrame]; 
    CGFloat xPos = (scrRect.size.width - btnRect.size.width) / 2.0f;*/
    
    CGFloat xPos 
        = UIInterfaceOrientationIsPortrait(toInterfaceOrientation)? 325.0f : 453.0f;
    
    btnMnuEditer.frame 
        = CGRectMake(xPos, btnRect.origin.y, btnRect.size.width, btnRect.size.height);
#else
    // 編集ボタンをIBのAutosizingで左右のMargin設定を外すこと
#endif
    @try {
        if (self.userEditerSheet.isVisible)
        {
            [self.userEditerSheet dismissWithClickedButtonIndex:4 animated:NO];
        }
        // アカウントログインポップアップを表示中に画面回転が行われた場合の処理
        // 2015/12/22 TMS 初回起動時ログイン必須対応
        if(popoverCntlAccountLogin != nil){
            NSLog(@"popoverCntlAccountLogin != nil");
            dmyBtn.frame = CGRectMake(self.view.frame.size.width/3, self.view.frame.size.height/2.1, 10, 10);
            
            [popoverCntlAccountLogin presentPopoverFromRect:dmyBtn.bounds
                                                     inView:dmyBtn
                                   permittedArrowDirections:0
                                                   animated:NO];
            
            backImgView.frame = CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.height);
            
            if (toInterfaceOrientation == UIDeviceOrientationLandscapeLeft || toInterfaceOrientation == UIDeviceOrientationLandscapeRight) {
                [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte-Landscape@2x.png"]];
            }else if (toInterfaceOrientation == UIDeviceOrientationPortraitUpsideDown || toInterfaceOrientation == UIDeviceOrientationPortrait){
                [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte@2x.png"]];
            }else{
                [backImgView setImage:[UIImage  imageNamed:@"Default_abcarte@2x.png"]];
            }
        }else{
            NSLog(@"popoverCntlAccountLogin == nil");
        }
            
    }
    @catch (NSException *exception) {
        
    }
    
#endif
}
- (void)viewWillDisappear:(BOOL)animated
{
	// 現時点で最上位のViewController(=self)を削除する
	// [ [self parentViewController] dismissModalViewControllerAnimated:animated]; 
}

- (void)didReceiveMemoryWarning {
	
	@try
	{
		// Releases the view if it doesn't have a superview.
		// [super didReceiveMemoryWarning];
	}
	@catch (NSException* exception) {
		NSLog(@"UserInfoVC didReceiveMemoryWarning: Caught %@: %@", 
			  [exception name], [exception reason]);
	}
	
	// Release any cached data, images, etc that aren't in use.
	
    // 2016/6/7 TMS メモリ使用率抑制対応
	//[_headPictureList removeAllObjects];
	//[_headPictureList release];
	//_headPictureList = nil;
}

- (void)viewDidUnload {
    [lblLastWorkDateTitle release];
    lblLastWorkDateTitle = nil;
    [indexView release];
    indexView = nil;
    [indexTableView release];
    indexTableView = nil;
    [btnCustomerInfo release];
    btnCustomerInfo = nil;
    [btnUserInfo release];
    btnUserInfo = nil;
    [btnAddUser release];
    btnAddUser = nil;
    [btnSanshouPage release];
    btnSanshouPage = nil;
    [userNameHonoTitle release];
    userNameHonoTitle = nil;
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    
	if (popoverCntlNewUser) 
		[popoverCntlNewUser release];
	if (popoverCntlEditUser) 
		[popoverCntlEditUser release];
    if (popoverCntlSmtpSetup)
		[popoverCntlSmtpSetup release];
	if (popoverCntlEditWorkItem)
		[popoverCntlEditWorkItem release];
	if (popoverCntlMainte)
		[popoverCntlMainte release];
	if (popoverCntlRegNumSearch)
		[popoverCntlRegNumSearch release];
#ifdef USE_ACCOUNT_MANAGER
    if (popoverCntlAccountLogin)
        [popoverCntlAccountLogin release];
#endif
#ifdef CLOUD_SYNC
    if (popoverCntlSelectShop)
        [popoverCntlSelectShop release];
#endif
	
	/*
	 if (cameraView)
	 [cameraView release];
	 */
	
    [userNameHonoTitle release];
	
    // 2016/6/7 TMS メモリ使用率抑制対応
	//[_headPictureList removeAllObjects];
	//[_headPictureList release];
	//_headPictureList = nil;
	// [userMailStatusList removeAllObjects];
    [userMailStatusList release];
#ifdef TRIAL_VERSION
	if (alertOpenHomePage)
	{	[alertOpenHomePage release]; }
#endif
	
    [btnSanshouPage release];
    [btnAddUser release];
    [btnUserInfo release];
    [btnCustomerInfo release];
#ifdef WEB_MAIL_FUNC
	[blockMailStatus release];
#endif
	[createUser release];
    [indexTableView release];
    [indexView release];
    [lblLastWorkDateTitle release];
    [topImgCus release];
    [lblhobby release];
    [viewMemo release];
    [lblBloodType release];
    [viewCusTop release];
    [super dealloc];
}


#pragma mark UISearchBarDelegate

// return NO to not become first responder
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	return (YES);
}

// called when text starts editing
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
#ifdef CALULU_IPHONE
	btnSearch.title = @"検索解除";
    btnGojyuonSearch.searching = YES;
	btnSearch.tag = 100;
#endif
}

// 検索ボタン
- (void) searchBarSearchButtonClicked: (UISearchBar *) searchBar
{
	// キーボードを隠す
	[searchBar resignFirstResponder];
    
    // 検索バーを非表示にする
    [self _dispCtrlSearchBar:NO];
	
	NSLog(@"searchBarBarSearchButtonClicked at text=%@", searchBar.text);
	
	// 検索解除ボタンの有効設定
	// btnSearch.enabled = ([searchBar.text length] > 0);
	
	// 検索ボタンの役割設定
	if ([searchBar.text length] > 0)
	{
		btnSearch.title = @"検索解除";
        btnGojyuonSearch.searching = YES;
		btnSearch.tag = 1;
	}
	else 
	{
		btnSearch.title = @"検索条件";
        btnGojyuonSearch.searching = NO;
		btnSearch.tag = 0;
	}
	
	// 姓（漢字）の場合は入力文字でひらがなと漢字を判別する
	SELECT_JYOUKEN_KIND kind = (selectJyoukenKind == (NSUInteger)SELECT_FIRST_NAME)?
		[self discrimentKanji:searchBar.text] : (SELECT_JYOUKEN_KIND)selectJyoukenKind;
	
	//検索文字列でユーザ情報リストを更新
	[userInfoList setUserInfoList:searchBar.text selectKind:kind];
	
	// tableViewの再読み込み
	[myTableView reloadSectionIndexTitles];
    [indexTableView reloadSectionIndexTitles];
	[myTableView reloadData];
    [self updateLblCustomerKarteAll];
}
//2016/8/10 TMS お客様名検索対応
/**
 お客様名での検索
 */
- (void)OnUserNameSearch:(id)sender
{
    selectJyoukenKind = (NSUInteger)SELECT_FIRST_NAME;
    
    NSString *sei = [(NSArray *)sender objectAtIndex:0];
    NSString *mei = [(NSArray *)sender objectAtIndex:1];
    // 姓（漢字）の場合は入力文字でひらがなと漢字を判別する
    SELECT_JYOUKEN_KIND kind = (selectJyoukenKind == (NSUInteger)SELECT_FIRST_NAME)?
    [self discrimentKanji:sei] : (SELECT_JYOUKEN_KIND)selectJyoukenKind;
    
    SELECT_JYOUKEN_KIND kind2 = (selectJyoukenKind == (NSUInteger)SELECT_FIRST_NAME)?
    [self discrimentKanji:mei] : (SELECT_JYOUKEN_KIND)selectJyoukenKind;
    
    //検索文字列でユーザ情報リストを更新
    [userInfoList setUserInfoList:sei:mei selectKind:kind selectKind2:kind2];
    
    // ボタンの設定
    btnSearch.title = @"検索解除";
    btnGojyuonSearch.searching = YES;
    btnSearch.tag = 1;
    
    [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];

    // tableViewの再読み込み
    [myTableView reloadSectionIndexTitles];
    [indexTableView reloadSectionIndexTitles];
    [myTableView reloadData];
    [self updateLblCustomerKarteAll];

}

// 2016/8/17 担当者検索機能の追加
/**
 担当者名での検索
 */
- (void)OnResponsibleSearch:(id)sender
{
    selectJyoukenKind = (NSUInteger)SELECT_FIRST_NAME;
    
    NSString *responsibleName = (NSString *)sender;

    //検索文字列でユーザ情報リストを更新
    [userInfoList setUserInfoList:responsibleName];
    
    // ボタンの設定
    btnSearch.title = @"検索解除";
    btnGojyuonSearch.searching = YES;
    btnSearch.tag = 1;
    
    [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
    
    // tableViewの再読み込み
    [myTableView reloadSectionIndexTitles];
    [indexTableView reloadSectionIndexTitles];
    [myTableView reloadData];
    [self updateLblCustomerKarteAll];
    
}

// 検索文字の変更
- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *) searchText
{
	// 検索解除ボタンの有効設定
	// btnSearch.enabled = ([searchText length] > 0);
	
	// 検索ボタンの役割設定
	if ([searchBar.text length] > 0)
	{
		btnSearch.title = @"検索解除";
        btnGojyuonSearch.searching = YES;
		btnSearch.tag = 1;
	}
	else 
	{
		btnSearch.title = @"検索条件";
        btnGojyuonSearch.searching = NO;
		btnSearch.tag = 0;
	}	
	/*
	// 姓（漢字）の場合は入力文字でひらがなと漢字を判別する
	SELECT_JYOUKEN_KIND kind = (selectJyoukenKind == (NSUInteger)SELECT_FIRST_NAME)?
		[self discrimentKanji:searchBar.text] : (SELECT_JYOUKEN_KIND)selectJyoukenKind;
		
	//検索文字列でユーザ情報リストを更新
	[userInfoList 
		setUserInfoList:searchBar.text selectKind:kind];
	
	// tableViewの再読み込み
	[myTableView reloadSectionIndexTitles];
    [indexTableView reloadSectionIndexTitles];
	[myTableView reloadData];
    [self updateLblCustomerKarteAll];
     */
}

/**
 顧客一覧の並び替え
 */
- (IBAction)OnSearchBySort : (id)sender
{
    BOOL conditions = NO;
    
    if([btnSort.titleLabel.text compare:@"△▼"] == NSOrderedSame){
        onReverseSort = false;
        [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
    }else{
        onReverseSort = true;
       [btnSort setTitle:@"△▼" forState:UIControlStateNormal];
    }
    if([ btnSearch.title compare:@"検索解除"] == NSOrderedSame){
         conditions = YES;
    }else{
         conditions = NO;
    }
    //並び替え
    [userInfoList sortUserInfoList:conditions];

    // tableViewの再読み込み
    [myTableView reloadSectionIndexTitles];
    [indexTableView reloadSectionIndexTitles];
    [myTableView reloadData];
}

// 
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    // 検索バーを非表示にする
    [self _dispCtrlSearchBar:NO];
    
    return (YES);
}

// キャンセルボタン
- (void) searchBarCancelButtonClicked: (UISearchBar *) searchBar
{
	// キーボードを隠す
	[searchBar resignFirstResponder];
    
    // 検索バーを非表示にする
    [self _dispCtrlSearchBar:NO];
}

#pragma mark MainViewControllerDelegate

// 新規View画面への遷移
//		return: 次に表示する画面のViewController  nilで遷移をキャンセル
- (UIViewController*) OnTransitionNewView:(id)sender
{
	//NSLog(@"OnTransitionNewView at UserInfoListVC");

	// 通常は、履歴一覧は既にload済みである
	return (nil);
	
#ifdef TRANSITION_NEW_VIEW_MODE
	// 念のため現在選択中のユーザを確認
	if (currentUserId <= 0)
	{	return (nil); }			// nilで画面遷移をしない
	
	HistListViewController *window  
	= [[HistListViewController alloc]
	   initWithNibName:@"HistListViewController" bundle:nil];
	
	// 現在選択中のユーザIDと名前を渡す
	window.selectedUserID = currentUserId;
	window.selectedUserName = lblName.text;
	
	// 遷移画面を履歴一覧にする
	_windowView = WIN_VIEW_HIST_LIST;
	
	return (window);
#endif
	
}

// 既存View画面への遷移
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC
{
	// NSLog(@"OnTransitionExsitView at UserInfoListVC");
	
	// 念のため現在選択中のユーザを確認
	if (currentUserId <= 0)
	{	return (NO); }			// NOで画面遷移をしない
	
	// Viewの更新
	HistListViewController *window = (HistListViewController*)tVC;
    NSLog(@"CURRENT USER ID : %d",currentUserId);
	[window refreshViewWithUserID:currentUserId userName:lblName.text];
    
	// 遷移画面を履歴一覧にする
	_windowView = WIN_VIEW_HIST_LIST;
    
    // 検索のキーボードが表示されている場合は閉じる
    [mySearchBar resignFirstResponder];
	
	return (YES);				// 画面遷移する
}

// ロック画面への遷移確認:実装しない場合は遷移可とみなす
- (BOOL) OnDisplayChangeEnable:(id)sender disableReason:(NSMutableString*) message
{
	BOOL stat;
	
	// 選択ユーザがある場合は、遷移可とする
	if (currentUserId > 0)
	{	
		stat = YES;
		
		MainViewController* mainVC = (MainViewController*)sender;
		
		HistListViewController *window = (HistListViewController*)
			[mainVC getVC4ViewControllersWithClass:[HistListViewController class]];
		if (window)
		{
			// 次ページViewの更新
			[window refreshViewWithUserID:currentUserId userName:lblName.text];
			// 遷移画面を履歴一覧にする
			_windowView = WIN_VIEW_HIST_LIST;
			// 次ページへ進む：履歴一覧画面
			[mainVC fowordNextPage];
		}
        // ユーザ情報編集画面ポップアップが表示されている場合に、閉じる
        if (vcEditUser) {
            [vcEditUser OnCancelButton:nil];
        }
	}
	else 
	{
		stat = NO;
		[message appendString:@"(お客様が選択されていません)"];
	}

	return (stat);
}

#pragma mark UITableViewDataSource

// セクション数の設定：ロード時にcallback
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView==indexTableView) {
        return 0;
    }
	return [userInfoList getSectionNum];
}

// セクション内のセルの数の設定：ロード時にcallback
- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
    if (tableView==indexTableView) {
        return 0;
    }

	return [userInfoList getUserNum:section];
}

// セクションのタイトルの設定：ロード時にcallback
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView==indexTableView) {
        return nil;
    }
	// NSLog(@"called titleForHeaderInSection at section %d", section);
	return [userInfoList getSectionTitle:section];
}

#ifdef TABLE_INDEX
/**
 * 各セクションのヘッダに使用するviewを返す (各セクションに表示する文字もここで設定する必要が有る)
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // 指定セクションにのみ検索条件を表示させるため
    if ((section == 0 && selectJyoukenKind!=SELECT_NONE) || selectJyoukenKind==SELECT_GOJYUON_NAME) {
        UILabel *v = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 25)];
       [v setBackgroundColor:HEADER_TABLE_COLOR];
        v.textColor = [UIColor whiteColor];
        v.text = [NSString stringWithFormat:@"　　%@",[self tableView:tableView titleForHeaderInSection:section]];
        
        [self initSelectedUser];
        
        return v;
    }
    if (!zeroSizeView_) {
        zeroSizeView_ = [[UIView alloc] initWithFrame:CGRectZero];
    }
    if (section == 0) {
        return zeroSizeView_;
    } else {
        return zeroSizeView_;
    }
}

/**
 * 各セクションのヘッダ高さを返す
 */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ((section == 0 && selectJyoukenKind!=SELECT_NONE) || selectJyoukenKind==SELECT_GOJYUON_NAME) {
        return 25;
    } else {
        return 0;
    }
}
#endif

// セルの内容を設定：ロード時にcallbackおよびスクロール時
- (UITableViewCell *)tableView:(UITableView*)tableView 
		 cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    
#ifdef TABLE_INDEX
    if (indexView.alpha != 0.0f) {
        [self indexDispControll];
    }
#endif
	static NSString *CellIndentifier = @"user_info_view_cell";
	UserTableViewCell *cell 
		= (UserTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIndentifier];
	if (cell == nil)
	{
		UIViewController *viewController = [[UIViewController alloc]
#ifdef CALULU_IPHONE
											initWithNibName:@"ip_UserTableViewCell"
#else
#ifdef TABLE_INDEX
											initWithNibName:@"UserTableViewCell4idx"
#else
											initWithNibName:@"UserTableViewCell"
#endif // TABLE_INDEX
#endif
											bundle:nil];
		cell = (UserTableViewCell*)viewController.view;
        // viewControllerをreleaseしてしまうと、画面を回転させた時に落ちてしまう
//		[viewController release];
		
		// UserTableViewCellの初期化
        [self tableView:tableView willDisplayCell:cell forRowAtIndexPath:0];
		[cell initialize:self tableView:myTableView];
		
        // Cell選択時に青色にする(iOS7対応) → xib上のselectedBGViewで選択時の表示を行うよう変更したため、削除。

#ifdef DEBUG
		NSLog(@"make user_info_view_cell at section:%ld row:%ld",
              (long)indexPath.section, (long)indexPath.row);
#endif
	}
	
	// ユーザ情報の取得
	userInfo  *info 
	= [userInfoList getUserInfoBySection:
	   (NSInteger)indexPath.section rowNum:(NSInteger)indexPath.row];
	
	// Cellの設定
	cell.userName.text = [info getUserName];
	[cell setRegistNumberWithIntValue:info.registNumber isNameSet:info.isSetUserName];
    
    //cell image
    if ([info.pictureURL  isEqual: @""]) {
        [cell.picture setImage:[UIImage imageNamed:@"noImage.png"]];
    } else {
        [cell.picture setImage:[self makeImagePictureWithUID: info.pictureURL userID:info.userID]];
    }
    
    cell.lastDate.text = [info getLastWorkDate:isJapanese];
	[cell setSexText:info.sex];
    // 生年月日:西暦
    cell.birthday.text = [NSString stringWithFormat:@"生年月日　%@",[info getBirthDayByLocalTimeAD:isJapanese]];
	[cell setSectionIndex:indexPath.section index:indexPath.row];
#ifdef CLOUD_SYNC
    [cell setShopName:info.shopName];   // 店舗名の設定
#else
    [cell setShopName:nil];
#endif
	cell.userID = info.userID;
    [cell setLanguage:isJapanese];

    cell.mailTitleOnUserUnreadLabel.text    = (isJapanese)? @"未開封" : @"Unread";
    cell.mailTitleOffUserUnreadLabel.text   = (isJapanese)? @"未開封" : @"Unread";
    cell.mailTitleOnErrorLabel.text         = (isJapanese)? @"エラー" : @"Error";
    cell.mailTitleOffErrorLabel.text        = (isJapanese)? @"エラー" : @"Error";
    cell.mailTitleOnReplyUnreadLabel.text   = (isJapanese)? @"受信" : @"Receive";
    cell.mailTitleOffReplyUnreadLabel.text  = (isJapanese)? @"受信" : @"Receive";
    cell.mailTitleOnCheckLabel.text         = (isJapanese)? @"要対応" : @"Support";
    cell.mailTitleOffCheckLabel.text        = (isJapanese)? @"要対応" : @"Support";

    [self resetMailBadgesOfCell:cell];
    if([AccountManager isWebMail]) {
        id statusObj = userMailStatusList[[NSNumber numberWithInt:info.userID]];
        if (statusObj != nil) {
            WebMailUserStatus *status = (WebMailUserStatus *)statusObj;
            [self updateMailBadgesOfCell:cell status:status];
        }
    }
    
	return(cell);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *currentSelectedIndexPath = [tableView indexPathForSelectedRow];
    if (currentSelectedIndexPath != nil)
    {
        [[tableView cellForRowAtIndexPath:currentSelectedIndexPath] setBackgroundColor:[UIColor clearColor]];
    }
    
    return indexPath;
}

// iOS7よりTableViewCellの表示が変更になった為
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (cell.isSelected == YES)
    {
        [cell setBackgroundColor:TABLE_CELL_COLOR];
    }
    else
    {
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    
    if(iOSVersion<7.0) {
        UserTableViewCell *iCell = (UserTableViewCell *) cell;
        iCell.inset = -44.0;
    }
}

// 画面上に見えているセルの表示更新
- (void)updateVisibleCells {
    
    // バッジ表示件数の初期化
     applicationIconBadgeNumber = 0;
     
     NSMutableArray* users = nil;
     userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];
     
     users = [userDbMng getAllUsers];
     //全顧客からのメール受信件数の取得
     for ( userInfo* user in users )
     {
         if( user == nil ){
         break;
         }
         
         id statusObj = [userMailStatusList objectForKey:[NSNumber numberWithInteger:[user userID]]];
         
         if (statusObj != nil) {
             WebMailUserStatus *userStatus = (WebMailUserStatus *)statusObj;
             applicationIconBadgeNumber = applicationIconBadgeNumber + userStatus.unread;
         }
     }
     
     //バッジの表示
     [UIApplication sharedApplication].applicationIconBadgeNumber = applicationIconBadgeNumber;
    

    for (UserTableViewCell *cell in [myTableView visibleCells]){
        [self updateCell:cell atIndexPath:[myTableView indexPathForCell:cell]];
    }
    
    [userDbMng release];
}

// 表示更新内容
- (void)updateCell:(UserTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Update Cells
    if([AccountManager isWebMail]) {
        // ユーザ情報の取得
        userInfo  *info
        = [userInfoList getUserInfoBySection:
           (NSInteger)indexPath.section rowNum:(NSInteger)indexPath.row];
        id statusObj = userMailStatusList[[NSNumber numberWithInt:info.userID]];
        if (statusObj != nil) {
            WebMailUserStatus *status = (WebMailUserStatus *)statusObj;
            [self updateMailBadgesOfCell:cell status:status];
        }
    }
}

// メールバッジ表示更新
- (void)resetMailBadgesOfCell:(UserTableViewCell*)cell {
    cell.mailUserUnread.hidden = YES;
    cell.mailError.hidden = YES;
    cell.mailReplyUnread.hidden = YES;
    cell.mailCheck.hidden = YES;
}
- (void)updateMailBadgesOfCell:(UserTableViewCell*)cell status:(WebMailUserStatus*)status {
    [self updateMailBadgeView:cell.mailUserUnread label:cell.mailUserUnreadLabel number:status.userUnread];
    [self updateMailBadgeView:cell.mailReplyUnread label:cell.mailReplyUnreadLabel number:status.unread];
    [self updateMailBadgeView:cell.mailCheck label:cell.mailCheckLabel number:status.check];
    [self updateMailBadgeView:cell.mailError label:cell.mailErrorLabel number:status.notification_error];
}
- (void)updateMailBadgeView:(UIView*)view label:(UILabel*)label number:(NSInteger)number {
    view.hidden = (number == 0);
    label.text = [NSString stringWithFormat:@"%ld",(long)number];
}

/**
 * 検索の結果表示するべきデータの有無をチェックする
 */
- (void)chkResultCount
{
    NSInteger resultNum = 0;
    // 結果データ数が0で無ければすぐに抜ける
    for (NSInteger i=0; i<[userInfoList getSectionNum] && resultNum<1; i++) {
        resultNum += [userInfoList getUserInfoNums:i];
    }
    if (resultNum < 1) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"検索結果"
                                  message:@"検索結果は ０件でした"
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil
                                  ];
        [alertView show];
        [alertView release];
    }
}

#pragma mark TABLE INDEX
#ifdef TABLE_INDEX
/**
 * インデックス表示する文字のデータ列
 */
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // インデックス用のUITableViewにだけ値を返す
    if (tableView==indexTableView) {
        if (onReverseSort) {
            return [userInfoList getSectionTitleArray:true];
        } else {
            return [userInfoList getSectionTitleArray];
        }
    }
    return nil;
//    return titles;
}

/**
 * インデックスを操作した時に、呼び出されるDelegate
 */
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (tableView == indexTableView) {
        NSLog(@"hay day nhi");
        if (index < 72) {
            if ([userInfoList getUserNum:index]>0) {
                NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:index];
                [myTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }
    }
    return (NSInteger)(index);
//    return [titles indexOfObject:title];
}

/**
 * デフォルトのインデックス表示文字列(現在未使用)
 */
- (void)setSourceData
{
    // セクションタイトルのアレイ作成
//    titles = [NSArray arrayWithObjects:
//              @"あ", @"い", @"う", @"え", @"お",
//              @"か", @"き", @"く", @"け", @"こ",
//              @"さ", @"し", @"す", @"せ", @"そ",
//              @"た", @"ち", @"つ", @"て", @"と",
//              @"な", @"に", @"ぬ", @"ね", @"の",
//              @"は", @"ひ", @"ふ", @"へ", @"ほ",
//              @"ま", @"み", @"む", @"め", @"も",
//              @"や", @"ゆ", @"よ",
//              @"ら", @"り", @"る", @"れ", @"ろ",
//              @"わ", @"を", @"ん", nil];
    titles = [NSArray arrayWithObjects:
              @"あ", @"", @"", @"", @"",
              @"か", @"か", @"", @"", @"",
              @"さ", @"", @"さ", @"", @"",
              @"た", @"", @"た", @"", @"",
              @"な", @"", @"", @"", @"",
              @"は", @"", @"", @"", @"",
              @"ま", @"", @"", @"", @"",
              @"や", @"", @"",
              @"ら", @"", @"", @"", @"",
              @"わ", @"", @"", nil];
    [titles retain];
}
#endif

/**
 * UITableViewのインデックスを一定時間後に消す為の処理
 * 操作をqueueに入れた後にキャンセルする為の処理を入れている。下記を参照
 * http://glayash.blogspot.jp/2013/03/blocksclosures.html
 * (blocksのclosures的特性を使ったGCDキャンセル法)
 */
- (void)indexDispControll
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    static u_int32_t token;
    
    @synchronized(self) {
        token = arc4random_uniform(UINT32_MAX);
    }
    u_int32_t itsToken = token;
    
    [indexView.layer removeAllAnimations];  // 実行中のアニメーション停止
    [indexView setAlpha:1.0f];              // インデックスの表示
    
    // 非操作状態になってから５秒後にインデックスを消す
    double delayInSeconds = 5.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        // 処理がqueueされてから、再度操作された場合に、処理をキャンセルする
        @synchronized(self) {
            if (token != itsToken) {
                return;
            }
        }
        // １秒掛けて消す
        [UIView animateWithDuration:1.0f
                              delay:0.0f
                            options:UIViewAnimationCurveEaseIn
                         animations:^{
                             [indexView setAlpha:0.0f];
                         }completion:^(BOOL finished) {
                             // 何もしない
                         }];
    });
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
    selectedCellCoordinate = rectInTableView.origin.y;
    NSLog(@"in selected cell %f",selectedCellCoordinate);
    
    [[tableView cellForRowAtIndexPath:indexPath] setBackgroundColor:TABLE_CELL_COLOR];
    
#ifdef TABLE_INDEX
    [self indexDispControll];
#endif
	
	// ユーザ情報の取得
	userInfo  *info 
	= [userInfoList getUserInfoBySection:
	   (NSInteger)indexPath.section rowNum:(NSInteger)indexPath.row];
	// ユーザマスタの取得
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	mstUser *user = [usrDbMng getMstUserByID:info.userID];
	
	// DBが古い場合に mst_user のテーブル更新の必要が生じるため
    if (!user)
    {
        userDbManager *usrDbMngt = [[userDbManager alloc]init];
        [usrDbMngt userpictureUpgradeVer114];
        [usrDbMngt mstuserUpgradeVer122];
        [usrDbMngt mstuserUpgradeVer140];
        [usrDbMngt mstuserUpgradeVer172];
        // 2016/8/12 TMS 顧客情報に担当者を追加
        [usrDbMngt mstuserUpgradeVer215];
        [usrDbMngt release];
        user = [usrDbMng getMstUserByID:info.userID];
    }
	if (!user)
	{
		[ self alertDisp:@"内部エラーが発生しました\n誠に恐れ入りますが\nABCarteの再起動を\nお願いいたします\n（内部情報：DB ACCESS ERROR）"
			  alertTitle:@"iPadが不安定な状態です"];
		if (usrDbMng)
		{[usrDbMng release];}
		
		return;
	}
	
	// 現在選択中のユーザの設定
	currentUserId = info.userID;
	
	//施術内容Itemを取得
    // 2016/6/1 TMS メモリ使用率抑制対応
    fcUserWorkItem *workItem = [[fcUserWorkItem alloc] initWithWorkItem:currentUserId userName:[info getUserName]];
    workItem = [usrDbMng getUserWorkItemByID:currentUserId
                                    userName:[info getUserName]:workItem];
	//fcUserWorkItem *workItem = [usrDbMng
	//							getUserWorkItemByID:currentUserId userName:[info getUserName]];
	
	// 現在選択ユーザの表示
	[self dispSelectedUser:user userWorkItem:workItem];
	
	[usrDbMng release];
    // 2016/6/1 TMS メモリ使用率抑制対応
    [workItem release];
	
	// 次のViewController(HistListViewController)の更新
	[self updateNextViewController:NO];
}

#pragma mark ThumbnailVCDelegate

// サムネイルの削除イベント
- (void) didDeletedThumbnails:(id)sender deletedFiles:(NSArray*)files
{
	_isThumbnailDeleted = YES;
}

#pragma mark LongTotchDelegate

// セルの長押しのイベント
-(void) OnLongTotch:(id)sender
{
    // NSLog(@"長押し");
    /* 2012 07/19 伊藤 長押し削除機能が誤削除の原因になっているようなのでコメントアウト
	
	// 長押ししたセルのユーザと現在選択ユーザが異なる場合は、削除しない
	if ( cell.userID != currentUserId)
	{	
		NSLog(@"exit delete user diffrent userID -> curernt select:%d  delete:%d",
					currentUserId, cell.userID);
		return; 
	}
	
	// お客様情報削除
	[self OnUserInfoDelete:btnUserInfoDelete];
     */
}

#pragma mark UIFlickerButtonDelegate

// フリックイベント
- (void)OnFlicked:(id)sender flickState:(FLICK_STATE)state
{
	switch ( ((UIFlickerButton*)sender).tag) 
	{
		case FLICK_NEXT_PREV_VIEW:
			// 履歴一覧画面に遷移
			if (state == FLICK_LEFT)
			{
				// 左方向のフリックのみ履歴一覧画面に遷移
				// [self OnHistWorkView:btnHistListView];
			}
			break;
			
		case FLICK_USER_INFO_ON:
			// 現在選択ユーザ情報ボタン
			switch (state)
		{
			case FLICK_RIGHT:
			case FLICK_UP:
			case FLICK_DOWN:
				// 新規お客様
				[self OnNewUer:btnNewUser];
				break;
			case FLICK_LEFT:
				// 左方向のフリックのみ履歴一覧画面に遷移
				// [self OnHistWorkView:btnHistListView];
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
    //check coordinate of button
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:myTableView];
    buttonPosition.y -= 10;
    NSLog(@"in button position x = %f y = %f ",buttonPosition.x,buttonPosition.y);
    
	// 画面ロックモードを確認する
	MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	switch ( ((UIFlickerButton*)sender).tag)
	{
		case FLICK_CAMERA_VIEW:
            if (buttonPosition.y== selectedCellCoordinate) {
                [self OnCameraView:btnCameraView];
                
//                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//                [defaults setBool:YES forKey:@"CarteFromNew"];
//                [defaults synchronize];
            }
			// カメラ画面へ
			break;
		case FLICK_NEXT_PREV_VIEW:
			// 履歴一覧画面に遷移
			// [self OnHistWorkView:btnHistListView];
			break;
		case FLICK_USER_INFO_ON:
            // ユーザ情報の箇所で２本指ダブルタップで画面をロックすると
            // ロック後にここに飛んでくるため。
            if([mainVC isWindowLockState]) break;
			// 現在選択ユーザ情報ボタン:お客様情報更新
			[self OnUserInfoUpadte:btnUserInfoEdit];
			break;
		case FLICK_PICT_LIST_VIEW:
			// 現在選択ユーザ代表写真ボタン:写真一覧表示
			[self OnPictureListView:sender];
			break;
		default:
			break;
	}
}

// 長押しイベント
- (void)OnLongTouchDown:(id)sender
{
	switch ( ((UIFlickerButton*)sender).tag) 
	{
		case FLICK_NEXT_PREV_VIEW:
		case FLICK_USER_INFO_ON:
			// お客様情報削除
			// 削除できないように修正
			//[self OnUserInfoDelete:btnUserInfoDelete];
			break;
		default:
			break;
	}
}

#pragma mark UserTableViewCellGesture

#ifdef CALULU_IPHONE
// ユーザのテーブルセルのタップジェスチャーイベント：ダブルタップ
- (void) OnUserTableViewCellDoubleTap:(id)sender
{
    UIGestureRecognizer* ges = sender;
    CGPoint pt = [ges locationInView:ges.view];
    if (pt.x < 80.0f)
    {   
        ges.cancelsTouchesInView = YES;
        // 画面左側は写真のダブルタップと見なしてアクションシートは表示しないでカメラ画面に遷移
        [self OnCameraView:btnCameraView];
        
        return;
    }
    
    // ユーザ情報の操作のアクションシートを表示
    [self _userInfoOprActionSheetDisp];
}
#endif

// popupViewのDelegate
#pragma mark PopUpViewContollerBaseDelegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
	userDbManager *usrDbMng;
	mstUser *user;
	fcUserWorkItem	*workItem;
	
    //Popupを閉じた際にmyTableViewを操作可能にする
    //2012 6/25 伊藤 お客様情報編集中にポップアップが閉じない処理の一部
    self.view.userInteractionEnabled = YES;
    MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:NO];
    
    // 言語設定確認
    [self checkLanguage];

	switch (popUpID) 
	{
		case (NSUInteger)POPUP_NEW_USER:
			// 新規ユーザPopupView
			user = (mstUser*)object;
#ifdef DEBUG
			NSLog(@"new user popup result -> name=%@ %@",
				  user.firstName, user.secondName);
#endif
            // 写真アップロードを中断する
            CloudSyncPictureUploadManager *pictUploader
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cloudPictureUploader;
            [pictUploader uploadInnterrupt];
            
            // 動画アップロードを中断する
            VideoUploader *videoUploader
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).videoUploader;
            [videoUploader uploadInnterrupt];
            
			// データベースに登録する
			usrDbMng = [[userDbManager alloc] init];
			USERID_INT userID = [usrDbMng registNewUser:user];
			/*
			if (userID == DUPLICATE_USER_NAME_ID)
            {
                [self alertDisp:@"同じ名前のお客様がいます\n(誠に恐れ入りますが\n再登録をお願いいたします)" 
					 alertTitle:@"新規お客様登録"];
				[usrDbMng release];
				return;
            }
            else 
			*/
            if (userID < 0)
			{
				[self alertDisp:@"新規お客様の登録に失敗しました\n(誠に恐れ入りますが\n再登録をお願いいたします)" 
					 alertTitle:@"新規お客様登録"];
				[usrDbMng release];
				return;
			}
            // クラウドと同期処理の実行
			[CloudSyncClientManager clientUserInfoSyncProc:^(SYNC_RESPONSE_STATE result) {
				if ( result == SYNC_RSP_OK )
				{
#ifdef DEF_ABCARTE
					// WebMail用のユーザーを作成する
					[createUser createWebMailUserWithID:currentUserId BlockMail:user.blockMail];
#endif
                    // デバイス内部のDB更新
                    [self setUserMailBlockStatus:currentUserId rejectStatus:user.blockMail];
				}
				else if (result != SYNC_RSP_OK)
                {
					NSLog(@"user infoの更新に失敗");
                }
 			}
													userId:userID];
 
			// 現在選択ユーザのユーザ情報を表示
			[self updateSelectedUserByUserInfo:user];
			[self updateSelectedUserByWorkItem
			 :[[fcUserWorkItem alloc]initWithWorkItem:user.userID userName:user.firstName]];
			
			// 現在選択中のユーザの設定
			currentUserId = userID;
			
			[usrDbMng release];

			// 検索解除にする（新規ユーザを一覧に表示）
			btnSearch.tag = 1;
			[self OnSerach:btnSearch];
			
			//現在選択中のユーザをTableView上で選択する
			//[self selectedUserOnTableViewWithUID:userID];
            [myTableView reloadSectionIndexTitles];
            [indexTableView reloadSectionIndexTitles];
            [myTableView reloadData];
            [self updateLblCustomerKarteAll];
			
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0f * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 写真アップロードを再開(起動)する
//            CloudSyncPictureUploadManager *pictUploader
//            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cloudPictureUploader;
            [pictUploader uploadRestart];
            
            // 動画アップロードを再開(起動)する
//            VideoUploader *videoUploader
//            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).videoUploader;
            [videoUploader uploadRestart];
            });

			break;
		case (NSUInteger)POPUP_EDIT_USER:
			// ユーザ情報編集
			user = (mstUser*)object;
			
			usrDbMng = [[userDbManager alloc] init];
            userFmdbManager *manager = [[userFmdbManager alloc]init];
            
			// 元のユーザ情報を取得しておく
			mstUser *oriUser = [usrDbMng getMstUserByID:user.userID];
			
			// データベースを更新する
			if (![usrDbMng updateMstUser:user] || ![manager updateWebMailBlockUser:user.userID BlockState:user.blockMail])
			{
				[self alertDisp:@"お客様情報の編集に失敗しました\n(誠に恐れ入りますが\n再編集をお願いいたします)" 
					 alertTitle:@"お客様情報編集"];
			}
			else 
			{
				//施術内容Itemを取得
				/*
				 fcUserWorkItem *workItem = [usrDbMng 
				 getUserWorkItemByID:user.userID userName:nil];
				 */
				
				// 現在選択ユーザのユーザ情報更新
				[self updateSelectedUserByUserInfo:user];
				
				// 元のユーザ情報の姓（かな）と変更がある場合は、ViewTableを更新する
				if ((oriUser) 
					&& (! [user.firstNameCana isEqualToString:oriUser.firstNameCana]))
				{
                    // 検索解除にする(検索解除時に、tableViewの再読み込みも行っている)
                    btnSearch.tag = 1;
                    [self OnSerach:btnSearch];

					// tableViewの再読み込み
//					[myTableView reloadSectionIndexTitles];
//                    [indexTableView reloadSectionIndexTitles];
//					[myTableView reloadData];
//                    [self updateLblCustomerKarteAll];
//                    [self chkResultCount];
				}
				else 
				{
					// 現在選択ユーザ情報一覧の更新
					[self updateSelectedUserList:user lastDate:nil];
				}
				
			}
			
            // クラウドと同期処理の実行
            [CloudSyncClientManager clientUserInfoSyncProc: ^(SYNC_RESPONSE_STATE result)
             {
                 if (result != SYNC_RSP_OK)
                 {
                     NSLog(@"user infoの更新に失敗");
                 } else {
                     // デバイス内部のDB更新
                     [self setUserMailBlockStatus:user.userID rejectStatus:user.blockMail];
                 }
             }
                                                    userId:user.userID
             ];
			[usrDbMng release];
            [manager release];
			break;
			
		case (NSUInteger)POPUP_EDIT_WORK_ITEM:
			// 施術内容の編集
			workItem = (fcUserWorkItem*)object;
			
			// データベースを更新する
			usrDbMng = [[userDbManager alloc] init];
			
			if (! [usrDbMng updateUserWorkItem:workItem])
			{
				[self alertDisp:@"施術内容の編集に失敗しました\n(誠に恐れ入りますが\n再編集をお願いいたします)" 
					 alertTitle:@"施術内容編集"];
			}
			else 
			{
				// 現在選択ユーザの施術内容を更新
				[self updateSelectedUserByWorkItem:workItem];
				
				// 現在選択ユーザ情報一覧の更新
				[self updateSelectedUserList:nil lastDate:workItem.workItemDate];
			}
			
			[usrDbMng release];
			
			break;
			
		case (NSUInteger)POPUP_MAINTENACE:
			// メンテナンス
			
			// 現在選択ユーザの初期化
			[self initSelectedUser];
			currentUserId = -1;
			
			// ツールバーボタンのEnable設定
			[self setToolButtonEnable:NO]; 
			
			// tableViewの再読み込み
			[myTableView reloadSectionIndexTitles];
            [indexTableView reloadSectionIndexTitles];
			[myTableView reloadData];
            [self updateLblCustomerKarteAll];
            [self chkResultCount];
			
			break;
            
        case (NSUInteger)POPUP_SEARCH_USER_NAME:
            // メンテナンス
            
            
            break;
			
		case (NSUInteger)POPUP_SEARCH_GOJYUON:
			// 五十音検索
			selectJyoukenKind = (NSUInteger)SELECT_GOJYUON_NAME;
            
			btnSearch.title = @"検索解除";
            btnGojyuonSearch.searching = YES;
			btnSearch.tag = 1;
			
            [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
            
			// パラメータは検索文字列
			NSMutableArray	*searchStrings = (NSMutableArray*)object;
            
            // 処理中ステータス表示
            UILockWindowController *_bottomDialog = [self ProgressView:@"指定文字で検索中です"];
            
            // 処理中ステータスを表示させる
            dispatch_async(dispatch_get_main_queue(), ^{
			
                //検索文字列でユーザ情報リストを更新
                [userInfoList
                 setUserInfoListWithGojyuon:searchStrings];
                
                // tableViewの再読み込み
                [myTableView reloadSectionIndexTitles];
                [indexTableView reloadSectionIndexTitles];
                [myTableView reloadData];
                [self updateLblCustomerKarteAll];
                [self chkResultCount];
                
                // ツールバーボタンのEnable設定
                [self setToolButtonEnable:NO]; 
                // 現在選択ユーザの初期化
                [self initSelectedUser];

                // 処理中インジケータを閉じる
                [_bottomDialog dismissDialogViewControllerAnimated:YES];
                [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
            });
			break;
			
		case (NSUInteger)POPUP_SEARCH_WORK_DATE:
			// 施術日で検索
			
			btnSearch.title = @"検索解除";
            btnGojyuonSearch.searching = YES;
			btnSearch.tag = 1;
			
             [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
            
			// パラメータは日付
			NSDate	*searchDate = (NSDate*)object;
			
			//施術日でユーザ情報リストを更新
			[userInfoList 
             setUserInfoListWithWorkDate:searchDate:SELECT_WORK_DATE];
			
			// tableViewの再読み込み
			[myTableView reloadSectionIndexTitles];
            [indexTableView reloadSectionIndexTitles];
			[myTableView reloadData];
            [self updateLblCustomerKarteAll];
            [self chkResultCount];
			
			// ツールバーボタンのEnable設定
			[self setToolButtonEnable:NO]; 
			// 現在選択ユーザの初期化
			// [self initSelectedUser];
			// 先頭のユーザを選択
			[self selectUserOnListWithIndexPath:0 section:0];
			
			break;
			
		case (NSUInteger)POPUP_SEARCH_REGSIT_NUM:
		// お客様番号による検索:パラメータは検索するお客様番号の一部
			
			// お客様番号による検索での前回検索数値をここで保存する
            _lastUserRegistNum4Search = [(NSString*)object intValue];
			
			//お客様番号でユーザ情報リストを更新：番号部分一致検索
			[self searchByRegistNumber:(NSString*)object];
			
			break;
            
		case (NSUInteger)POPUP_MAIL_SETTING:
            break;
#ifdef USE_ACCOUNT_MANAGER
		case (NSUInteger)POPUP_ACCOUNT_LOGIN:
		// アカウントログイン
			[self doAccountLogin:(NSArray*)object];
			break;
#endif
#ifdef CLOUD_SYNC
        case (NSUInteger)POPUP_SELECT_SHOP:
        // 店舗の選択
            [self _selectedShopWithIDS:(NSArray*)object];
            break;
#endif
		default:
			break;
	}
	
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    app.navigationController.enableRotate = YES;
    [privacyView removeFromSuperview];
}

/**
 * メール受信拒否のステータスを反映させる
 * @param NSInteger userID      ユーザ番号
 * @param BOOL      status      受信拒否ステータス
 * @return なし
 */
- (void)setUserMailBlockStatus:(USERID_INT)userID rejectStatus:(BOOL)status
{
    userFmdbManager *manager = [[userFmdbManager alloc]init];

    [manager updateWebMailBlockUser:userID
                         BlockState:status];
    [manager release];
}

// ポップアップビュー終了後に呼び出される
- (void)OnPopupViewFinished:(NSUInteger)popUpID setObject:(id)object Sender:(id)sender
{
	userFmdbManager* userFmdbMng = [[userFmdbManager alloc] init];
	[userFmdbMng initDataBase];
	BOOL isExist = [userFmdbMng isWebMailUser:currentUserId];
	[userFmdbMng release];
#ifdef WEB_MAIL_FUNC
	if ( isExist == YES )
	{
		// 一回以上メール送信した事があるユーザー
		if ( popUpID == POPUP_EDIT_USER )
		{
			// emailが無い場合は無視
			UserInfoEditViewController* editView = (UserInfoEditViewController*)sender;
			if ( [editView isEmailExist] == NO ) return;

			// 受信拒否設定
			if ( blockMailStatus == nil )
			{
				blockMailStatus = [[BlockMailStatus alloc] initWithDelegate:nil];
				[blockMailStatus setUserId:currentUserId];
			}
			BOOL blockMail = ([editView getMailRecieveSetting] == 0) ? NO : YES;
			[blockMailStatus setBlockMailStatus:blockMail];
            
            [self redrawTable];
		}
	}
	else
	{
		if ( [sender isKindOfClass:[UserInfoEditViewController class]] )
		{
			// emailが無い場合は無視
			UserInfoEditViewController* editView = (UserInfoEditViewController*)sender;
			if ( [editView isEmailExist] == NO ) return;
			BOOL blockMail = ([editView getMailRecieveSetting] == 0) ? NO : YES;
			
			// メール送信していない場合はサーバー側にユーザー情報がない
			// WebMail用のユーザーを作成する
			[createUser createWebMailUserWithID:currentUserId BlockMail:blockMail];
		}
	}
#endif
}

// アカウントログインポップアップクローズ時の処理
- (void)closeAccountLoginPopUp
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    ((AccountLoginPopUp *)popoverCntlAccountLogin.delegate).myDelegate = nil;
    popoverCntlAccountLogin = nil;
}

#pragma mark UIAlertViewDelegate
// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	userDbManager *usrDbMng = nil;
	userFmdbManager* usrFMDB = nil;
	
	// ユーザ情報削除Alertダイアログではいの場合、ユーザー情報を初期化
	if ( (alertView == alertUserInfoDelete) && (buttonIndex == 0) ) 
	{
		// DBからユーザー情報を削除する
		BOOL bSuccess = YES;
		do
		{
			// データベースよりユーザ情報（マスタ）と施術内容を削除する
			usrDbMng = [[userDbManager alloc] init];
			if ( ! [usrDbMng deleteUserInfoWorkItems:currentUserId])
			{
				bSuccess = NO;
				break;
			}
			
			// FMDBからユーザー情報を削除する
			usrFMDB = [[userFmdbManager alloc] init];
			[usrFMDB initDataBase];
			if ( ![usrFMDB removeUserMailInfo:currentUserId] )
			{
				bSuccess = NO;
				break;
			}
		} while (0);
		
		if ( usrDbMng != nil )
			[usrDbMng release];
		if ( usrFMDB != nil )
			[usrFMDB release];

		if ( bSuccess != YES )
		{
			[self alertDisp:@"お客様情報の削除に失敗しました\n(誠に恐れ入りますが\n再度削除をお願いいたします)"
				 alertTitle:@"新規お客様削除"];
			return;
		}
		
		// 画像ファイルをフォルダ以下全てを削除する
		[self allDeletePictureFiles:currentUserId];

		//先に全ユーザでユーザ情報リストを更新
		[userInfoList setUserInfoList:@"" selectKind:SELECT_NONE];
		
		// ユーザ情報リストより先頭のユーザ情報を取得
		userInfo* topInfo = [userInfoList getListTopUserInfo];
		currentUserId = (topInfo)? topInfo.userID : -1;
		
		// 検索解除にする（削除したユーザを一覧から表示しないようにする）
		btnSearch.tag = 1;
		[self OnSerach:nil];
		
		// 先頭ユーザが取得できなかった場合は、次のViewController(HistListViewController)の強制更新
		if (currentUserId < 0)
		{	[self updateNextViewController:YES]; }
	}
#ifdef TRIAL_VERSION
	else if ( (alertView == alertOpenHomePage) && (buttonIndex == 0) ) 
	{
		// OKの場合のみCaLuLuホームページを開く
		[Common openCaluLuHomePage];
	}
#endif
    else if ( alertView.tag == USER_INFO_LOGIN_OK_DIALOG)
    {   
        // 販売店様の場合は、サンプルデータをダウンロード
        /*[[NSRunLoop currentRunLoop]  
             runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];*/
        [self _sampleDataDownload];
    }else if ( (alertView.tag == APP_STORE_SALES_CHECK_DIALOG) && (buttonIndex == 0)){
        [self __sampleDataDownload];

    }
#ifdef CLOUD_SYNC 
    else if ( (alertView.tag == CLOUD_UPLOAD_OK_DIALOG)  && (buttonIndex == 0) ) 
    {
        // クラウドへアップロード
        [self _doCloud2Upload];
    }
    else if (alertView.tag == CLOUD_RESTART_DIALOG)
    {
        if (buttonIndex == 0)
        {   
            // クラウドと同期
            isSyncNomal = YES;
            [self _doCloud2Sync];
        }
        else if (buttonIndex == 1) {
            // 同期処理の実行中をクリアする：２回目以降は再開の確認をしないようにする
            [CloudSyncClientManager syncPhaseReset];
        }
    }
#endif
    else if (alertView.tag == LANGUAGE_INFO_DIAG) {
        // ユーザ設定を取得
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        if (buttonIndex==0) {
            isJapanese = NO;
            // 国の設定(英語圏)
            [df setValue:@"en" forKey:@"USER_COUNTRY"];
        } else {
            isJapanese = YES;
            // 国の設定(日本語圏)
            [df setValue:@"ja" forKey:@"USER_COUNTRY"];
        }
        [df synchronize];
        // 言語選択後の再表示
        [self redrawTable];
    }
    // ログアウトAlertダイアログではいの場合、同期実行
    else if ( (alertView == alertLogout) && (buttonIndex == 0) )
    {
        // クラウドと同期
        isSyncNomal = NO;
        [self _doCloud2Sync];
    }
 //2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
#ifdef FOR_SALES
    else if (alertView.tag == DEMO_DATA_SYNC_DIALOG){
        if (buttonIndex == 0){
            // ヴァージョン番号を強制的に変更し、再起動時にアップデート処理を走らせる。
            NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
            [df setObject:@"force_update" forKey:@"appInfo_version"];
            [df synchronize];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                exit(0);
            });
        } else {
            
        }
    }
#endif
}

/**
 * 言語環境切り替え後の、再表示処理
 */
- (void)redrawTable
{
    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = (isJapanese)?
    [self ProgressView:@"顧客データの読み取り中です"]: [self ProgressView:@"Reading customer data..."];
    
    // わざと DISPATCH_QUEUE_PRIORITY_LOW で優先度を下げて、処理中ステータスを表示させる
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        //全ユーザでユーザ情報リストを更新
        [userInfoList setUserInfoList:@"" selectKind:SELECT_NONE];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // tableViewの再読み込み
            [myTableView reloadSectionIndexTitles];
            [indexTableView reloadSectionIndexTitles];
            [myTableView reloadData];
            [self updateLblCustomerKarteAll];
            
            // ツールバーボタンのEnable設定
            [self setToolButtonEnable:NO];
            
            if (currentUserId >= 0)
            {
                //現在選択中のユーザをTableView上で選択する
                [self selectedUserOnTableViewWithUID:currentUserId];
            }
            else
            {
                // 現在選択ユーザの初期化
                [self initSelectedUser];
            }
            // 処理中インジケータを閉じる
            [_bottomDialog dismissDialogViewControllerAnimated:YES];
            [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
        });
    });
}

#pragma mark UIActionSheetDelegate

// 通常検索（btnSearch.tag=0）の場合のアクションシートの処理
- (void) actionSheetHandlerWithNormalSearch:(NSInteger)buttonIndex
{
#ifdef CALULU_IPHONE
    if (! [MainViewController isNowDeviceOrientationPortrate] )
    {
        // お客様番号一覧より検索
        [self searchByRegistNumber:REGIST_NUMBER_INVALID];
        mySearchBar.hidden = YES;	// 検索バーを非表示（氏名検索をしない）
        btnSearch.tag = 2;	// お客様番号検索へ
        return;
    }
#endif
    
    
    NameSearchPopup *nameSearch;
    ResponsibleSearchPopup *responsibleSearchPopup;

    switch (buttonIndex) {
		case SEARCH_WORD_IDX:
			// 五十音による検索
//            selectJyoukenKind = (NSUInteger)SELECT_GOJYUON_NAME;
			[self OnGojyuonSearch:nil];
			break;
		case SEARCH_LAST_NAME_IDX:
            /*
			// お客様の姓で検索（漢字またはひらがな）
			
			mySearchBar.placeholder 
				= @"検索するお客様の姓を入力してください。（例：あ、日本、等）";
            
            // 検索バーを表示する
            [self _dispCtrlSearchBar : YES];
            
			[mySearchBar becomeFirstResponder];
             */
            
            // 日付の設定ポップアップのViewControllerのインスタンス生成
            
//            selectJyoukenKind = (NSUInteger)SELECT_FIRST_NAME;
            
            nameSearch
            = [[NameSearchPopup alloc]initWithPopUpViewContoller:POPUP_SEARCH_USER_NAME
                                               popOverController:nil
                                                        callBack:self];
            // ポップアップViewの表示
            UIPopoverController *popoverCntl = [[UIPopoverController alloc]
                                                initWithContentViewController:nameSearch];
            nameSearch.popoverController = popoverCntl;
            
            [popoverCntl presentPopoverFromRect:btnGojyuonSearch.bounds
                                         inView:btnGojyuonSearch
                       permittedArrowDirections:UIPopoverArrowDirectionUp
                                       animated:YES];
            [popoverCntl setPopoverContentSize:CGSizeMake(487.0f, 180.0f)];
            
            [popoverCntl release];
            [nameSearch release];
            
			break;
        // 2016/8/17 担当者検索機能の追加
        case SEARCH_RESPONSIBLE_IDX:
//            selectJyoukenKind = (NSUInteger)SELECT_FIRST_NAME;
            
            responsibleSearchPopup
            = [[ResponsibleSearchPopup alloc]initWithPopUpViewContoller:POPUP_SEARCH_RESPONSIBLE                                               popOverController:nil
                                                        callBack:self];
            // ポップアップViewの表示
            UIPopoverController *rPopoverCntl = [[UIPopoverController alloc]
                                                initWithContentViewController:responsibleSearchPopup];
            responsibleSearchPopup.popoverController = rPopoverCntl;
            [rPopoverCntl presentPopoverFromRect:btnGojyuonSearch.bounds
                                         inView:btnGojyuonSearch
                       permittedArrowDirections:UIPopoverArrowDirectionUp
                                       animated:YES];
            [rPopoverCntl setPopoverContentSize:CGSizeMake(412.0f, 131.0f)];

            [rPopoverCntl release];
            [responsibleSearchPopup release];
            
            break;
		case SEARCH_TREAT_DAY_IDX:
			// 最終施術日（以降）: 施術日による検索
			selectJyoukenKind = (NSUInteger)SELECT_WORK_DATE;
//			[self dispWorkDateSearchPopup];		// 施術日による検索Popupの表示
            [self dispDateSearchPopup];
			break;
		case SEARCH_CUSTOMER_NUM_IDX:
			// お客様番号一覧より*検索
            NSLog(@"vao day chang");
            selectJyoukenKind = SELECT_CUSTOMER_ID;
			[self searchByRegistNumber:REGIST_NUMBER_INVALID];
            // 検索バーを非表示（氏名検索をしない）
            [self _dispCtrlSearchBar:NO];
			btnSearch.tag = 2;	// お客様番号検索へ
			break;

		case SEARCH_BIRTHDAY_IDX:
			{ // 生年月日で検索
                selectJyoukenKind = SELECT_BIRTY_DAY;
				// 生年月日による検索Popupの表示
				[self dispBirthdaySearchPopup];
			}
			break;

//		case SEARCH_LATEST_DAY_IDX:
//			{ // 最新施術日で検索
//				// 最新施術日による検索Popupの表示
//                selectJyoukenKind = SELECT_LAST_WORK_DATE;
//				[self dispLastWorkDateSearchPopup];
//			}
//			break;

		case SEARCH_MEMO_IDX:
			{ // メモで検索
                selectJyoukenKind = SELECT_MEMO;
				// メモによる検索Popupの表示
				[self dispMemoSearchPopup];
			}
			break;

		case SEARCH_MAIL_ERROR_IDX:
#ifndef DEF_ABCARTE
            break;
#endif
            { // メール送信エラーで検索
                selectJyoukenKind = SELECT_MAIL_ERROR;
                // メール送信エラーによる検索
                btnSearch.title = @"検索解除";
                btnGojyuonSearch.searching = YES;
                btnSearch.tag = 1;
                
                [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
                
                // 処理中ステータス表示
                UILockWindowController *_bottomDialog = [self ProgressView:@"メール送信エラーの検索中です"];
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    [userInfoList setUserInfoListWithMailSendError:self->userMailStatusList];
                    
                    // tableViewの再読み込み
                    [myTableView reloadSectionIndexTitles];
                    [indexTableView reloadSectionIndexTitles];
                    [myTableView reloadData];
                    [self updateLblCustomerKarteAll];
                    [self chkResultCount];
                    
                    // ツールバーボタンのEnable設定
                    [self setToolButtonEnable:NO];
                    // 現在選択ユーザの初期化
                    [self initSelectedUser];
                    // 処理中インジケータを閉じる
                    [_bottomDialog dismissDialogViewControllerAnimated:YES];
                    [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
                });
            }
			break;
		case SEARCH_MAIL_UNREAD_IDX:
#ifndef DEF_ABCARTE
            break;
#endif
            { // メール未開封者で検索
                selectJyoukenKind = SELECT_MAIL_UNREAD;
                // メール未開封者による検索
                btnSearch.title = @"検索解除";
                btnGojyuonSearch.searching = YES;
                btnSearch.tag = 1;
                
                [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
            
                // 処理中ステータス表示
                UILockWindowController *_bottomDialog = [self ProgressView:@"メール未開封者の検索中です"];
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    [userInfoList setUserInfoListWithMailUnRead:self->userMailStatusList];
                    
                    // tableViewの再読み込み
                    [myTableView reloadSectionIndexTitles];
                    [indexTableView reloadSectionIndexTitles];
                    [myTableView reloadData];
                    [self updateLblCustomerKarteAll];
                    [self chkResultCount];
                    
                    // ツールバーボタンのEnable設定
                    [self setToolButtonEnable:NO];
                    // 現在選択ユーザの初期化
                    [self initSelectedUser];

                    // 処理中インジケータを閉じる
                    [_bottomDialog dismissDialogViewControllerAnimated:YES];
                    [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
                });
            }
            break;
        //2016/4/9 TMS 顧客検索条件追加
        case SEARCH_MAIL_TENPO_UNREAD_IDX:
#ifndef DEF_ABCARTE
            break;
#endif
        { // 店舗側メール未開封で検索
            selectJyoukenKind = SELECT_MAIL_TENPO_UNREAD_IDX;
            // 店舗側メール未開封による検索
            btnSearch.title = @"検索解除";
            btnGojyuonSearch.searching = YES;
            btnSearch.tag = 1;
            
             [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
            
            // 処理中ステータス表示
            UILockWindowController *_bottomDialog = [self ProgressView:@"店舗側メール未開封の検索中です"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [userInfoList setUserInfoListWithMailTenpoUnRead:self->userMailStatusList];
                
                // tableViewの再読み込み
                [myTableView reloadSectionIndexTitles];
                [indexTableView reloadSectionIndexTitles];
                [myTableView reloadData];
                [self updateLblCustomerKarteAll];
                [self chkResultCount];
                
                // ツールバーボタンのEnable設定
                [self setToolButtonEnable:NO];
                // 現在選択ユーザの初期化
                [self initSelectedUser];
                
                // 処理中インジケータを閉じる
                [_bottomDialog dismissDialogViewControllerAnimated:YES];
                [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
            });
        }
            break;
        case SEARCH_MAIL_TENPO_ANSWER_IDX:
#ifndef DEF_ABCARTE
            break;
#endif
        { // 要対応で検索
            selectJyoukenKind = SELECT_MAIL_TENPO_UNREAD_IDX;
            // 要対応による検索
            btnSearch.title = @"検索解除";
            btnGojyuonSearch.searching = YES;
            btnSearch.tag = 1;
            
             [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
            
            // 処理中ステータス表示
            UILockWindowController *_bottomDialog = [self ProgressView:@"要対応のお客様の検索中です"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [userInfoList setUserInfoListWithMailTenpoAnswer:self->userMailStatusList];
                
                // tableViewの再読み込み
                [myTableView reloadSectionIndexTitles];
                [indexTableView reloadSectionIndexTitles];
                [myTableView reloadData];
                [self updateLblCustomerKarteAll];
                [self chkResultCount];
                
                // ツールバーボタンのEnable設定
                [self setToolButtonEnable:NO];
                // 現在選択ユーザの初期化
                [self initSelectedUser];
                
                // 処理中インジケータを閉じる
                [_bottomDialog dismissDialogViewControllerAnimated:YES];
                [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
            });
        }
            break;
		default:
			break;
	}
	
}

// お客様番号検索の場合のアクションシート処理
- (void) actionSheetHandlerWithRegistNumSearch:(NSInteger)buttonIndex
{
#ifdef CALULU_IPHONE
    if (! [MainViewController isNowDeviceOrientationPortrate] )
    {
        switch (buttonIndex) {
             case 0:
                 // お客様番号一覧を表示
                NSLog(@"maybe");
                 [self searchByRegistNumber:REGIST_NUMBER_INVALID];
                 break;
             case 1:
                 // お客様名一覧を表示
                 btnSearch.tag = 1;
                 [self OnSerach:btnSearch];
#ifndef CLOUD_SYNC
//                 mySearchBar.hidden = NO;	// 検索バーを表示に戻す
#endif
                 break;
            default:
                break;
        }
        return;
    }
#endif
    
    switch (buttonIndex) {
		case 0:
			// お客様番号で検索
			[self dispRegistNumberSearchPopup];
			break;
		case 1:
			// お客様番号一覧を表示
			[self searchByRegistNumber:REGIST_NUMBER_INVALID];
			break;
		case 2:
			// お客様名一覧を表示
			btnSearch.tag = 1;
			[self OnSerach:btnSearch];
			
#ifndef CLOUD_SYNC
//            mySearchBar.hidden = NO;	// 検索バーを表示に戻す
#endif
			break;			
		default:
			break;
	}
}

#ifdef CALULU_IPHONE

// お客様情報の詳細を表示
- (void) showUserInfoDispDialog
{
    UserInfoDispViewSupport *userInfoDisp =
        [[UserInfoDispViewSupport alloc] initWithUserID4DialogDisp:currentUserId 
                                                      hButtonClick:^(NSInteger tag){
                                                          switch (tag)
                                                          {
                                                              case USER_INFO_DISP_BTN_EDIT:
                                                              // お客様情報更新    
                                                                  [self OnUserInfoUpadte:btnUserInfoEdit];
                                                                  break;
                                                              case USER_INFO_DISP_BTN_THUMBNAIL:
                                                              // サムネイル(写真一覧)表示
                                                                  [self OnPictureListView:self];
                                                                  break;
                                                          }
                                                      }];
    [MainViewController showBottomModalDialog:userInfoDisp];
    [userInfoDisp release];
}
#endif


#ifdef CALULU_IPHONE
// ユーザ情報操作のアクションシート処理(iPhone版)
- (void) _actionSheetUserInfo:(NSInteger) buttonIndex
{
    switch (buttonIndex) {
        case 0:
            // 新規お客様の作成
            [self OnNewUer:btnNewUser];
            break;
        case 1:
            // お客様情報の詳細を表示
            [self showUserInfoDispDialog];
            break;
        case 2:
            // お客様情報の編集
            [self OnUserInfoUpadte:btnUserInfoEdit];
            break;
        
        case 3:
            // お客様情報の削除
            [self OnUserInfoDelete:btnUserInfoDelete];
            break;
        default:
            break;
    }
    
    self.userEditerSheet = nil;
}
#endif

#ifndef CALULU_IPHONE
// ユーザ情報操作のアクションシート処理(iPad版)
- (void) _actionSheetUserInfo:(NSInteger) buttonIndex
{
    {
        // (ログインしていない or WebMail契約が無い) ばあい通常のものを使用
        switch (buttonIndex) {
            case 0:
                // お客様情報の編集
                [self OnUserInfoUpadte:btnUserInfoEdit];
                break;
            case 1:
                // お客様情報の削除
                [self OnUserInfoDelete:btnUserInfoDelete];
                break;
            default:
                break;
        }
    }
    self.userEditerSheet = nil;
}

/**
 * Reject 11.13 対策
 * ABCarteHPへの参照リンクを削除する
 */
#define NOLOGIN_SETLANG     0
#ifdef FOR_REJECT
#define NOLOGIN_USERINFO    1
#define NOLOGIN_NOTIFICATIONS 2
#else
#define NOLOGIN_HPURL       1
#define NOLOGIN_USERINFO    2
#define NOLOGIN_NOTIFICATIONS 3
#endif

#define TREE_SERVERINFO     0
#define TREE_SHOPSELECT     1
#define TREE_SETLANG        2
#ifdef FOR_SALES
#define TREE_HPURL          3
#define TREE_USERINFO       4
#define TREE_NOTIFICATIONS  5
#else
#define TREE_USERINFO       3
#define TREE_NOTIFICATIONS  4
#endif

#define LOGIN_SERVERINFO    0
#define LOGIN_SETLANG       1
#ifdef FOR_SALES
#define LOGIN_HPURL         2
#define LOGIN_USERINFO      3
#define LOGIN_NOTIFICATIONS 4
#else
#define LOGIN_USERINFO      2
#define LOGIN_NOTIFICATIONS 3
#endif

// ユーザ情報操作のアクションシート処理(iPad版)
- (void) _otherActionSheetUserInfo:(NSInteger) buttonIndex
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *shopID = [defaults stringForKey:ACCOUNT_SHOP_ID_KEY];

    if  (([defaults stringForKey:@"accountIDSave"] == nil) || ([AccountManager isWebMail]==NO))
    {
        // (ログインしていない or WebMail契約が無い) ばあい通常のものを使用
        switch (buttonIndex) {
            case NOLOGIN_SETLANG:
                // 言語環境設定
                [self changeLanguage];
                break;
#ifndef FOR_REJECT
            case NOLOGIN_HPURL:
                // アプリのHP表示
                [self appliDocUrl];
                break;
#endif
            case NOLOGIN_USERINFO:
                // アプリの設定
                [self OnCustomerInfo:nil];
                break;
            case NOLOGIN_NOTIFICATIONS:
                [self _showNotificationsPopup];
            default:
                break;
        }
    }else if(shopID.length>1){
        //ログイン済み かつ 店舗契約有り ならメール送信サーバの設定に対応したものを使用
        switch (buttonIndex) {
            case TREE_SERVERINFO:
                // メール送信サーバの設定画面を表示
                [self SmtpInfoSetUp];
                break;
            case TREE_SHOPSELECT:
                // 店舗選択
                [self OnBtnShopSelect:nil];
                break;
            case TREE_SETLANG:
                // 言語環境設定
                [self changeLanguage];
                break;
#ifdef FOR_SALES
            case TREE_HPURL:
                // アプリのHP表示
                [self appliDocUrl];
                break;
#endif
            case TREE_USERINFO:
                // アプリの設定
                [self OnCustomerInfo:nil];
                break;
            case TREE_NOTIFICATIONS:
                [self _showNotificationsPopup];
                break;
            default:
                break;
        }
    }else{
        //ログイン済みならメール送信サーバの設定に対応したものを使用
        switch (buttonIndex) {
            case LOGIN_SERVERINFO:
                // メール送信サーバの設定画面を表示
                [self SmtpInfoSetUp];
                break;
            case LOGIN_SETLANG:
                // 言語環境設定
                [self changeLanguage];
                break;
#ifdef FOR_SALES
            case LOGIN_HPURL:
                // アプリのHP表示
                [self appliDocUrl];
                break;
#endif
            case LOGIN_USERINFO:
                // アプリの設定
                [self OnCustomerInfo:nil];
                break;
            case LOGIN_NOTIFICATIONS:
                [self _showNotificationsPopup];
                break;
            default:
                break;
        }
    }
    
    self.userEditerSheet = nil;
}
#endif

- (void) _showNotificationsPopup {
    UINavigationController *nc = [NotificationsPopupViewController createNavigationController];
    [nc setModalPresentationStyle:UIModalPresentationFormSheet];
    [nc setAutomaticallyAdjustsScrollViewInsets:NO];
    [self presentViewController:nc animated:YES completion:nil];
}

- (void) showAppSettingPopup {
    AppSettingPopupVC *appSettingPopup = [[AppSettingPopupVC alloc] init];
    appSettingPopup.modalPresentationStyle = UIModalPresentationFormSheet;
    appSettingPopup.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:appSettingPopup animated:YES completion:nil];
    appSettingPopup.view.superview.center = self.view.center;
}

/**
 */
- (void) _broadcastmailActionSheetUserInfo:(NSInteger) buttonIndex
{
	switch ( buttonIndex )
	{
	case 0:
		//　Webメール一斉送信
		[self OnBoradcastMailingList:nil];
		break;

	case 1:
		// テンプレート管理画面
		[self OnTemplateManager:nil];
		break;

	default:
		break;
	}
    self.userEditerSheet = nil;
}

#ifdef USE_ACCOUNT_MANAGER
// アカウント管理が有効時のみ:お問い合わせとログイン
- (void) _actionLoginContact:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
#ifndef FOR_REJECT
            // お問い合わせ:メール送信
            [self _contactMailSend];
            break;
        case 1:
#endif
            // アカウントログインPopupの表示
            [self _showAccontLoginPopUp];
        default:
            break;
    }
}
#endif

#ifdef CLOUD_SYNC

// クラウドとの同期
- (void) _actionCloudSync:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            // クラウドと同期
            isSyncNomal = YES;
            [self _doCloud2Sync];
            break;
        case 1:
        {
            // クラウドへアップロードする(確認AlertViewの表示)
            // [self _cloudUploadAlertShow];
            break;
        }
        default:
            break;
    }
}

#endif

// アクションシート（設定ボタンによる）delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (actionSheet.tag) 
	{
		case 0:
        {
            //2016/4/9 TMS 顧客検索条件追加
            // 2016/8/17 担当者検索機能の追加
            int btn_jidx[] = {SEARCH_WORD_IDX,          SEARCH_LAST_NAME_IDX,   SEARCH_RESPONSIBLE_IDX,
                            SEARCH_TREAT_DAY_IDX,SEARCH_CUSTOMER_NUM_IDX,  SEARCH_BIRTHDAY_IDX,    SEARCH_MEMO_IDX,    SEARCH_MAIL_UNREAD_IDX, SEARCH_MAIL_TENPO_UNREAD_IDX, SEARCH_MAIL_TENPO_ANSWER_IDX,SEARCH_MAIL_ERROR_IDX, SEARCH_CANCEL_IDX};
            int btn_eidx[] = {SEARCH_TREAT_DAY_IDX,     SEARCH_CUSTOMER_NUM_IDX, SEARCH_BIRTHDAY_IDX,
                              SEARCH_MEMO_IDX,  SEARCH_MAIL_UNREAD_IDX, SEARCH_MAIL_TENPO_UNREAD_IDX, SEARCH_MAIL_TENPO_ANSWER_IDX,          SEARCH_MAIL_ERROR_IDX,
                              SEARCH_CANCEL_IDX,        SEARCH_CANCEL_IDX,      SEARCH_CANCEL_IDX};
            NSInteger chk_idx;
            if (isJapanese) {
#ifdef DEBUG
                NSLog(@"isJapanese[%ld]", (long)buttonIndex);
#endif
                //2016/4/9 TMS 顧客検索条件追加
                chk_idx = (buttonIndex > 11)? 11 : buttonIndex;
            } else {
#ifdef DEBUG
                NSLog(@"notJapanese[%ld]", (long)buttonIndex);
#endif
                //2016/4/9 TMS 顧客検索条件追加
                chk_idx = (buttonIndex > 8)? 8 : buttonIndex;
            }
            NSInteger lang_idx = (isJapanese)? btn_jidx[chk_idx] : btn_eidx[chk_idx];

			// 通常検索（btnSearch.tag=0）の場合のアクションシートの処理
			[self actionSheetHandlerWithNormalSearch:lang_idx];
        }
			break;
		case 2:
			// お客様番号検索の場合のアクションシート処理
            NSLog(@"help");
			[self actionSheetHandlerWithRegistNumSearch:buttonIndex];
			break;
        case 10:
            // ユーザ情報操作のアクションシート処理
//#ifndef CALULU_IPHONE
//            if (buttonIndex > 0)
//            {   buttonIndex++; }      // iPadの場合は、お客様の詳細表示なし
//#endif
            [self _actionSheetUserInfo:buttonIndex];
            break;
        case 19:
            // ユーザ情報操作のアクションシート処理:新規作成のみ
            [self _actionSheetUserInfo:2];
            break;

#ifdef USE_ACCOUNT_MANAGER
        case 64:
            // アカウント管理が有効時のみ:お問い合わせとログイン
            [self _actionLoginContact:buttonIndex];
            break;
#endif

#ifdef CLOUD_SYNC
        case 128:
            // クラウドとの同期
            [self _actionCloudSync:buttonIndex];
            break;
#endif
        case 500:
            // その他ボタン
            [self _otherActionSheetUserInfo:buttonIndex];
            break;
		case 1000:
			// 一斉送信ボタン
			[self _broadcastmailActionSheetUserInfo:buttonIndex];
			break;
		default:
			break;
	}
}


#pragma mark BirthdaySearchPopupDelegate
/**
 BirthdaySearchPopupからのコールバック
 */
- (void) OnSearch:(id)sender Cancel:(BOOL)cancel
{
	BirthdaySearchPopup* popup = (BirthdaySearchPopup*)sender;
	if ( popup == nil ) return;

	// キャンセル
	if ( cancel == YES )
	{
		// ポップオーバーを閉じる
		UIPopoverController* controller = [popup popOverController];
		if ( controller != nil )
			[controller dismissPopoverAnimated:YES];
		return;
	}

	// ユーザーリストの絞り込み
	switch ( [popup getSegmentIndex] )
	{
	case SEGMENT_BIRTHDAY:
		{
			// パラメータは日付
			NSDate	*searchDate = [popup getBirthDay];
			
			// 誕生日でユーザ情報リストを更新
			[userInfoList setUserInfoListWithBirthDate:searchDate From:nil SearchSelect:SELECT_BIRTY_DAY];
		}
		break;
		
	case SEGMENT_MONTH:
		{
			// 誕生月
			NSDate* startMonth = [popup getBirthMonth:YES];
			NSDate* endMonth = [popup getBirthMonth:NO];
			if ( [endMonth isEqualToDate:startMonth] )
			{
				// 開始と終了が同じだったので終了をnilに設定
				[userInfoList setUserInfoListWithBirthDate:startMonth
													  From:nil
											  SearchSelect:SELECT_BIRTY_MONTH];
			}
			else
			{
				// 誕生月でユーザ情報リストを更新
				[userInfoList setUserInfoListWithBirthDate:startMonth
													  From:endMonth
											  SearchSelect:SELECT_BIRTY_MONTH];
			}
		}
		break;

	case SEGMENT_YEAR:
		{
			// 誕生年
			NSDate* startYear = [popup getBirthYear:YES];
			NSDate* endYear = [popup getBirthYear:NO];
			if ( [endYear isEqualToDate:startYear] )
			{
				// 開始と終了が同じだったので終了をnilに設定
				[userInfoList setUserInfoListWithBirthDate:startYear
													  From:nil
											  SearchSelect:SELECT_BIRTY_YEAR];
			}
			else
			{
				// 誕生年でユーザ情報リストを更新
				[userInfoList setUserInfoListWithBirthDate:startYear
													  From:endYear
											  SearchSelect:SELECT_BIRTY_YEAR];
			}
		}
		break;

	default:
		{
			// ポップオーバーを閉じる
			UIPopoverController* controller = [popup popOverController];
			if ( controller != nil )
				[controller dismissPopoverAnimated:YES];
		}
		return;
	}
	
	// ボタンの設定
	btnSearch.title = @"検索解除";
    btnGojyuonSearch.searching = YES;
	btnSearch.tag = 1;
    
     [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];

	// tableViewの再読み込み
	[myTableView reloadSectionIndexTitles];
    [indexTableView reloadSectionIndexTitles];
	[myTableView reloadData];
    [self updateLblCustomerKarteAll];
    [self chkResultCount];
    
	// ツールバーボタンのEnable設定
	[self setToolButtonEnable:NO];
	// 先頭のユーザを選択
	[self selectUserOnListWithIndexPath:0 section:0];

	// ポップオーバーを閉じる
	UIPopoverController* controller = [popup popOverController];
	if ( controller != nil )
		[controller dismissPopoverAnimated:YES];
}


#pragma mark LastWorkDatePopupDelegate
/**
 LastWorkDatePopupからのコールバック
 */
- (void) OnLastWorkDateSearch:(id)sender Cancel:(BOOL)cancel
{
	LastWorkDateSearchPopup* popup = (LastWorkDateSearchPopup*)sender;
	if ( cancel == YES )
	{
		// ポップオーバーを閉じる
		UIPopoverController* controller = [popup popOverController];
		[controller dismissPopoverAnimated:YES];
		return;
	}

	// 検索する期間を取得する
	NSDateComponents* start = [[NSDateComponents alloc] init];
	NSDateComponents* end   = [[NSDateComponents alloc] init];
	[popup getSelectedTerm:&start End:&end];

	// うるう年の判定をしておく
	if ( [LastWorkDateSearchPopup isLeapYear:start.year] == YES )
	{
		if ( start.month == 2 && start.day > 30 )
		{
			[self alertDisp:@"検索開始日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
			return;
		}
	}
	if ( [LastWorkDateSearchPopup isLeapYear:end.year] == YES )
	{
		if ( start.month == 2 && start.day > 30 )
		{
			[self alertDisp:@"検索終了日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
			return;
		}
	}

    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = [self ProgressView:@"最新来店日の検索中です"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 施術日の期間検索をする
        if ( [userInfoList setUserInfoListWithLastWorkTerm:start End:end isLatest:YES] == NO )
        {
            // 処理中インジケータを閉じる
            [_bottomDialog dismissDialogViewControllerAnimated:NO];
            [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
            [self alertDisp:@"検索日が間違っています\n検索できませんでした。" alertTitle:@"検索終了"];
            // 一度検索を行うとリストが初期化されるため、再読み込みを行わせる
            btnSearch.tag = 1;
            [self OnSerach:self];
            return;
        }
        
        // ボタンの設定
        btnSearch.title = @"検索解除";
        btnGojyuonSearch.searching = YES;
        btnSearch.tag = 1;
        
        [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
        
        // tableViewの再読み込み
        [myTableView reloadSectionIndexTitles];
        [indexTableView reloadSectionIndexTitles];
        [myTableView reloadData];
        [self updateLblCustomerKarteAll];
        [self chkResultCount];
        
        // ツールバーボタンのEnable設定
        [self setToolButtonEnable:NO];
        // 先頭のユーザを選択
        [self selectUserOnListWithIndexPath:0 section:0];
        // 処理中インジケータを閉じる
        [_bottomDialog dismissDialogViewControllerAnimated:YES];
        [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
    });
	
	// ポップオーバーを閉じる
	UIPopoverController* controller = [popup popOverController];
	if ( controller != nil )
		[controller dismissPopoverAnimated:YES];
}

#pragma mark DateSearchPopupDelegate (日付検索関連)
/**
 施術日での検索
 */
- (void)OnNormalWorkSearch:(id)sender
{
    // 検索する期間を取得する
    NSDateComponents* start = [(NSArray *)sender objectAtIndex:0];
    NSDateComponents* end   = [(NSArray *)sender objectAtIndex:1];
    //    [popup getSelectedTerm:&start End:&end];
    
    // うるう年の判定をしておく
    if ( [LastWorkDateSearchPopup isLeapYear:start.year] == YES )
    {
        if ( start.month == 2 && start.day > 30 )
        {
            [self alertDisp:@"検索開始日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
            return;
        }
    }
    if ( [LastWorkDateSearchPopup isLeapYear:end.year] == YES )
    {
        if ( start.month == 2 && start.day > 30 )
        {
            [self alertDisp:@"検索終了日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
            return;
        }
    }
    
    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = [self ProgressView:@"来店日の検索中です"];
    
    [self searchLatestCommonAction:_bottomDialog
                          startDay:start
                            endDay:end
                          isLatest:NO
                     resultComment:nil];
}

/**
 最新施術日での検索
 */
- (void)OnLatestWorkSearch:(id)sender
{
    // 検索する期間を取得する
    NSDateComponents* start = [(NSArray *)sender objectAtIndex:0];
    NSDateComponents* end   = [(NSArray *)sender objectAtIndex:1];
//    [popup getSelectedTerm:&start End:&end];
    
    // うるう年の判定をしておく
    if ( [LastWorkDateSearchPopup isLeapYear:start.year] == YES )
    {
        if ( start.month == 2 && start.day > 30 )
        {
            [self alertDisp:@"検索開始日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
            return;
        }
    }
    if ( [LastWorkDateSearchPopup isLeapYear:end.year] == YES )
    {
        if ( start.month == 2 && start.day > 30 )
        {
            [self alertDisp:@"検索終了日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
            return;
        }
    }
    
    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = [self ProgressView:@"最新来店日の検索中です"];
    
    [self searchLatestCommonAction:_bottomDialog
                          startDay:start
                            endDay:end
                          isLatest:YES
                     resultComment:nil];
}

/**
 初回施術日での検索
 */
- (void)OnFirstWorkSearch:(id)sender
{
    // 検索する期間を取得する
    NSDateComponents* start = [(NSArray *)sender objectAtIndex:0];
    NSDateComponents* end   = [(NSArray *)sender objectAtIndex:1];
    //    [popup getSelectedTerm:&start End:&end];
    
    // うるう年の判定をしておく
    if ( [LastWorkDateSearchPopup isLeapYear:start.year] == YES )
    {
        if ( start.month == 2 && start.day > 30 )
        {
            [self alertDisp:@"検索開始日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
            return;
        }
    }
    if ( [LastWorkDateSearchPopup isLeapYear:end.year] == YES )
    {
        if ( start.month == 2 && start.day > 30 )
        {
            [self alertDisp:@"検索終了日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
            return;
        }
    }
    
    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = [self ProgressView:@"初回来店日の検索中です"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 施術日の期間検索をする
        if ( [userInfoList setUserInfoListWithFirstWorkTerm:start End:end] == NO )
        {
            // 処理中インジケータを閉じる
            [_bottomDialog dismissDialogViewControllerAnimated:NO];
            [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
            [self alertDisp:@"検索日が間違っています\n検索できませんでした。" alertTitle:@"検索終了"];
            // 一度検索を行うとリストが初期化されるため、再読み込みを行わせる
            btnSearch.tag = 1;
            [self OnSerach:self];
            return;
        }
        
        // ボタンの設定
        btnSearch.title = @"検索解除";
        btnGojyuonSearch.searching = YES;
        btnSearch.tag = 1;
        
        [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
        
        // tableViewの再読み込み
        [myTableView reloadSectionIndexTitles];
        [indexTableView reloadSectionIndexTitles];
        [myTableView reloadData];
        [self updateLblCustomerKarteAll];
        [self chkResultCount];
        
        // ツールバーボタンのEnable設定
        [self setToolButtonEnable:NO];
        // 先頭のユーザを選択
        [self selectUserOnListWithIndexPath:0 section:0];
        // 処理中インジケータを閉じる
        [_bottomDialog dismissDialogViewControllerAnimated:YES];
        [_bottomDialog release];    // 閉じる毎にインスタンスは破棄する
    });
    
}

/**
 来店間隔による検索
 */
- (void)OnIntervalWorkSearch:(id)sender
{
    NSInteger yValue = [[(NSArray *)sender objectAtIndex:0] integerValue];
    NSInteger iValue = [[(NSArray *)sender objectAtIndex:1] integerValue];

    // 検索する期間を取得する
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSUInteger flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    // 指定日数の過去日付を計算
    NSDate *latestDay = [NSDate dateWithTimeIntervalSinceNow:-60*60*24*iValue];
    NSDateComponents* end = [cal components:flags fromDate:latestDay];
    // 検索開始日付を計算(指定が無ければ1970から)
    NSDate *startDay = (yValue==0)? [NSDate dateWithTimeIntervalSince1970:0] :
                                    [NSDate dateWithTimeIntervalSinceNow:-60*60*24*365*yValue];
    NSDateComponents* start = [cal components:flags fromDate:startDay];
    
#ifdef DEBUG
    NSLog(@"Interval Search %ld/%ld/%ld - %ld/%ld/%ld",
          (long)start.year, (long)start.month, (long)start.day, (long)end.year, (long)end.month, (long)end.day);
#endif
    
    // うるう年の判定をしておく
    if ( [LastWorkDateSearchPopup isLeapYear:start.year] == YES )
    {
        if ( start.month == 2 && start.day > 30 )
        {
            [self alertDisp:@"検索開始日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
            return;
        }
    }
    if ( [LastWorkDateSearchPopup isLeapYear:end.year] == YES )
    {
        if ( start.month == 2 && start.day > 30 )
        {
            [self alertDisp:@"検索終了日が閏年のためありません\n検索できませんでした。" alertTitle:@"検索終了"];
            return;
        }
    }
    
    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = [self ProgressView:@"来店間隔の検索中です"];
    
    NSString *comment = (yValue==0)? [NSString stringWithFormat:@"%ld 日以上来店間隔があるお客様 ", (long)iValue]:
                                     [NSString stringWithFormat:@"%ld 年以内で %ld 日以上来店間隔があるお客様 ",
                                      (long)yValue, (long)iValue];
    
    [self searchLatestCommonAction:_bottomDialog
                          startDay:start
                            endDay:end
                          isLatest:YES
                     resultComment:comment];
}

- (void)searchLatestCommonAction:(UILockWindowController *)dialog
                        startDay:(NSDateComponents *)start
                          endDay:(NSDateComponents *)end
                        isLatest:(BOOL)isLatest
                   resultComment:(NSString *)comment
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // 施術日の期間検索をする
        if ( [userInfoList setUserInfoListWithLastWorkTerm:start End:end isLatest:isLatest] == NO )
        {
            // 処理中インジケータを閉じる
            [dialog dismissDialogViewControllerAnimated:NO];
            [dialog release];    // 閉じる毎にインスタンスは破棄する
            [self alertDisp:@"検索日が間違っています\n検索できませんでした。" alertTitle:@"検索終了"];
            // 一度検索を行うとリストが初期化されるため、再読み込みを行わせる
            btnSearch.tag = 1;
            [self OnSerach:self];
            return;
        }
        
        // ボタンの設定
        btnSearch.title = @"検索解除";
        btnGojyuonSearch.searching = YES;
        btnSearch.tag = 1;
        
        [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
        
        if (comment) {
            [userInfoList setTitle:comment];
        }
        
        // tableViewの再読み込み
        [myTableView reloadSectionIndexTitles];
        [indexTableView reloadSectionIndexTitles];
        [myTableView reloadData];
        [self updateLblCustomerKarteAll];
        [self chkResultCount];
        
        // ツールバーボタンのEnable設定
        [self setToolButtonEnable:NO];
        // 先頭のユーザを選択
        [self selectUserOnListWithIndexPath:0 section:0];
        // 処理中インジケータを閉じる
        [dialog dismissDialogViewControllerAnimated:YES];
        [dialog release];    // 閉じる毎にインスタンスは破棄する
    });

}

#pragma mark MemoSearchPopupDelegate
/**
 MemoSearchPopupからのコールバック
 */
- (void) OnMemoSearch:(id)sender Kind:(NSInteger) kind
{
	MemoSearchPopup* popup = (MemoSearchPopup*)sender;
	if ( kind == 0 )
	{
		// ポップオーバーを閉じる
		UIPopoverController* controller = [popup popOverController];
		[controller dismissPopoverAnimated:YES];
		return;
	}

	// 選択されたメモを取得する
	NSMutableDictionary* dicMemo = [NSMutableDictionary dictionary];
	[popup getMemoStringInArray:dicMemo];
	
	// メモを検索する
	if ( [userInfoList setUserInfoListWithMemo:dicMemo And:((kind == 1) ? YES : NO)] == NO )
	{
		[self alertDisp:@"検索日が間違っています\n検索できませんでした。" alertTitle:@"検索終了"];
		return;
	}
	
	// ボタンの設定
	btnSearch.title = @"検索解除";
    btnGojyuonSearch.searching = YES;
	btnSearch.tag = 1;
    
    [btnSort setTitle:@"▲▽" forState:UIControlStateNormal];
	
	// tableViewの再読み込み
	[myTableView reloadSectionIndexTitles];
    [indexTableView reloadSectionIndexTitles];
	[myTableView reloadData];
    [self updateLblCustomerKarteAll];
    [self chkResultCount];
	
	// ツールバーボタンのEnable設定
	[self setToolButtonEnable:NO];
	// 先頭のユーザを選択
	[self selectUserOnListWithIndexPath:0 section:0];
	
	// ポップオーバーを閉じる
	UIPopoverController* controller = [popup popOverController];
	if ( controller != nil )
		[controller dismissPopoverAnimated:YES];
}


#pragma mark CreateWebMailUserDelegate
// WebMailユーザー作成完了通知
- (void) finishedCreateWebMailUser:(NSInteger)userId Resp:(BOOL)createStatus BlockMail:(BOOL)blockMail
{
	if ( createStatus == NO )
	{
		// ユーザーの作成失敗
		NSLog( @"Fail CreateWebMailUser user_id = %ld", (long)userId );
	}
	else
	{
		// 受信拒否設定
		if ( blockMailStatus == nil )
		{
			blockMailStatus = [[BlockMailStatus alloc] initWithDelegate:nil];
			[blockMailStatus setUserId:currentUserId];
		}
		[blockMailStatus setBlockMailStatus:blockMail];

		// web_mail_userを作成しておく
		userFmdbManager* userFmdbMng = [[userFmdbManager alloc] init];
		[userFmdbMng initDataBase];
		FMDatabase *db = [userFmdbMng databaseConnect];
		BOOL ok = YES;
		[db open];
		[db beginTransaction];
		ok = [userFmdbMng updateUntil:0 userId:currentUserId db:db];
		if ( ok )
		{
			[db commit];
		}
		else
		{
			[db rollback];
		}
		[db close];
		[userFmdbMng release];
	}
}

#pragma mark public_methods

// メール状態を取得する
- (NSMutableDictionary*) getMailStatusList
{
	return userMailStatusList;
}

// viewのrefresh:初期化
- (void) refreshUserInfoListView
{
	// --------------------------------------------
	// メンバ変数関連の初期化：クリア
	// --------------------------------------------
	
	// ユーザー情報リストの初期化
	if (userInfoList)
	{	
		[userInfoList allListClear];
		[userInfoList release];
		userInfoList = nil;
	}
	userInfoList = [[userInfoListManager alloc] init];
	
	// 代表写真リストのキャッシュのクリア
    // 2016/6/7 TMS メモリ使用率抑制対応
    /*
	if (_headPictureList)
	{
		[_headPictureList removeAllObjects];
		[_headPictureList release];
		_headPictureList = nil;
	}*/
	
	// 検索条件の初期化
	selectJyoukenKind = (NSUInteger)SELECT_FIRST_NAME;
	
	// 遷移画面の初期化（本画面：顧客一覧画面）
	_windowView = WIN_VIEW_USER_LIST;
	
	// お客様番号による検索での前回検索数値の初期化
	_lastUserRegistNum4Search = REGIST_NUMBER_INVALID;
	
	//先に全ユーザでユーザ情報リストを更新
	[userInfoList setUserInfoList:@"" selectKind:SELECT_NONE];
	
	// --------------------------------------------
	// TableViewと代表写真の設定
	// --------------------------------------------
	
	// ユーザ情報リストより先頭のユーザ情報を取得
	userInfo* topInfo = [userInfoList getListTopUserInfo];
	currentUserId = (topInfo)? topInfo.userID : -1;
	
	// 検索解除にする
	btnSearch.tag = 1;
	[self OnSerach:nil];
	
	// 先頭ユーザが取得できなかった場合は、次のViewController(HistListViewController)の強制更新
	if (currentUserId < 0)
	{	[self updateNextViewController:YES]; }
}

/**
 * 一件のユーザWebMailステータスを即時更新する
 */
- (void)setWebMailUserStatus:(WebMailUserStatus *)statusObj UserID:(NSInteger)userId
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [(NSMutableDictionary *)userMailStatusList removeObjectForKey:[NSNumber numberWithInteger:userId]];
    
    [(NSMutableDictionary *)userMailStatusList setObject:statusObj forKey:[NSNumber numberWithInteger:userId]];
    
    [self updateVisibleCells];
}

- (void)finishedGetWebMailUserStatuses:(NSDictionary *)statuses exception:(NSException *)exception{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    if (exception == nil) {
        [userMailStatusList release];
        userMailStatusList = [NSMutableDictionary dictionaryWithDictionary:statuses];
//        userMailStatusList = statuses;
        [userMailStatusList retain];
    } else {
        // 通信に失敗した時にはローカルから取得
//        userFmdbManager *manager = [[userFmdbManager alloc]init];
//        [manager initDataBase];
//        userMailStatusList = [manager getStatuses];
//        [userMailStatusList retain];
//        [manager release];
        // 通信に失敗した時は、現在持っているステータスを変更しない
    }
    // 見えているCellだけを更新する
    // (縦画面から横画面に表示した段階で見えなくなったCellがdeallocされていると思われる)
    [self updateVisibleCells];

    if (currentUserId >= 0)
    {
        if (selectJyoukenKind==SELECT_GOJYUON_NAME) {
//            [self histWorkItemUpdate];
			// tableViewの再読み込み
//			[myTableView reloadSectionIndexTitles];
//			[myTableView reloadData];
//            [self initSelectedUser];
        } else {
            //現在選択中のユーザをTableView上で選択する
            [self selectedUserOnTableViewWithUID:currentUserId];
        }
    }
}
// ログイン完了後の処理
- (void) loginedProc
{
    [self accountLoginBtnShow];
    /*
    // 正常にログインが完了すれば、ボタンを隠す
    btnAccountLogin.hidden =YES;
#ifdef CLOUD_SYNC
    if([AccountManager isCloud]) {
        // Cloudと同期ボタンを表示
        btnMnuCloudSync.hidden = NO;
        
        // ログイン完了で同期する
        // [self _doCloud2Sync];
    }
#endif
     */
}

#ifdef CLOUD_SYNC
// 同期が未完了の場合は再度、同期を行う
-(void) doSyncAtRunnigTime
{
    // クラウド契約が無い場合、何もしない
    if(![AccountManager isCloud]) return;

    // 同期が実行中でなければ何もしない
    if (! [CloudSyncClientManager isSyncProcRunnig] )
    {   return; }

    // ロック画面が表示中（同期プロセスが実行中）であれば、確認ダイアログを出さないで処理を継続させる
    if(MainViewController.isDisplayBottomModalDialog) return;

    // 同期の確認ダイアログを表示する
    NSString *msg = @"前回の同期は\nまだ完了していません\n今すぐ同期を再開しますか？";
    
    UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"同期の再開"
							  message:msg
							  delegate:self
							  cancelButtonTitle:@"は い"
							  otherButtonTitles:@"いいえ", nil
							  ];
	alertView.tag = CLOUD_RESTART_DIALOG;
    [alertView show];
	[alertView release];
}

// 端末固有ユーザIDの取得（取得できていない場合）
-(void) getUserIdBase4NoGet
{
    @try {
        
        // 端末固有ユーザIDが取得済みであるかを確認
        NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
        if ([defaluts objectForKey:@"userIDBase"])
        {   return; }   // 登録済み
        
        // 未ログインの場合は対象外
        if (! [AccountManager isLogined])
        {   return; }
        
        //　アカウントに再ログインすることで、ユーザIDを取得
        // Global Queueの取得
        dispatch_queue_t queue = 
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        // スレッド処理
        dispatch_async(queue, ^{
            
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            NSLog(@"start get user id base by re-login thread!!");
            
            AccountManager *actMng = nil;
            @try {
                
                // アカウントIDとパスワードを保存データより取得
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *accID  = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
                NSString *accPwd = [defaults stringForKey:ACCOUNT_PWD_SAVE_KEY];
                
                actMng = [[AccountManager alloc]initWithServerHostName:ACCOUNT_HOST_URL];
                ACCOUNT_RESPONSE response = [actMng loginWithAccountID:accID
                                                              passWord:accPwd ];
                
                BOOL loginOk = (response == ACCOUNT_RSP_SUCCESS) || (response == ACCOUNT_RSP_DUPLICATE_LOGIN);
                
                 NSLog(@"end get user id base by re-login thread result:%@ at response:%ld",
                       (loginOk)? @"succsess" : @"error", (long)response);
            }
            @catch (NSException *exception) {
                NSLog(@"getUserIdBase4NoGet worker thread: Caught %@: %@", 
                      [exception name], [exception reason]);
            }
            @finally {
                [actMng release];
            }
            
            
            [pool release];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"getUserIdBase4NoGet: Caught %@: %@", 
              [exception name], [exception reason]);

    }
}

#endif

/**
 * 言語環境設定
 */
- (void)changeLanguage
{
    NSString *msg   = (isJapanese)? @"Please select language." : @"言語を設定してください。";
    NSString *title = (isJapanese)? @"Language environment" : @"言語環境";
    NSString *btn1  = @"Japanese";
    NSString *btn2  = @"English";

    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:title
                              message:msg
                              delegate:self
                              cancelButtonTitle:btn2
                              otherButtonTitles:btn1, nil
                              ];
    alertView.tag = LANGUAGE_INFO_DIAG;
    [alertView show];
    [alertView release];
}

/**
 * 顧客情報表示
 */
- (IBAction)OnCustomerInfo:(id)sender {
    
    // アプリバージョン情報
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    // 顧客登録情報
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *accID  = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
    NSString *shopID = [defaults stringForKey:ACCOUNT_SHOP_ID_KEY];
    if(accID==NULL) {
        accID = @"未登録";
    }
    
    //端末識別番号
    NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    NSString* userIDBase = [defaluts objectForKey:@"userIDBase"];
    
    NSString *msg1 = [NSString stringWithFormat:
                     @"%@ ver %@\nユーザーID : %@(%@)", MYAPP_NAME, version, accID, userIDBase];
    NSString *msg2 = [NSString stringWithFormat:
                     @"%@ ver %@\nユーザーID : %@(%@)\nショップID : %@", MYAPP_NAME, version, accID, userIDBase, shopID];
    NSString *msg = (shopID.length>1)? msg2 : msg1;

    UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"ユーザー情報"
							  message:msg
							  delegate:self
							  cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil
							  ];
	alertView.tag = CUSTOMER_INFO_DIAG;
    [alertView show];
	[alertView release];
}

/**
 Webメール一斉送信
 */
- (IBAction)OnBroadcastMail:(id)sender
{
    NSString *tl0 = @"Webメール一斉送信";
    NSString *tl1 = @"テンプレート管理";

    if (iOSVersion<8.0) {
        // (ログイン済み かつ WebMail契約済) ならばメール送信サーバの設定ボタンを表示
        UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                                           delegate:self
                                                  cancelButtonTitle:@"キャンセル"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:tl0, tl1, @"キャンセル", nil];
        sheet.cancelButtonIndex = 2;
        sheet.tag = 1000;
        [sheet autorelease];
        sheet.actionSheetStyle = UIActionSheetStyleDefault;
        
        // アクションシートを表示する
        [sheet showFromRect:btnBroadcastMail.bounds inView:btnBroadcastMail animated:YES];
        self.userEditerSheet = sheet;
    } else {
#ifdef SUPPORT_IOS8
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"内容を選択してください"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:tl0
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self OnBoradcastMailingList:nil];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:tl1
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self OnTemplateManager:nil];
                                                }]];
        UIPopoverPresentationController *pop = [alert popoverPresentationController];
        pop.sourceView = btnBroadcastMail;
        pop.sourceRect = btnBroadcastMail.bounds;
        
        [self presentViewController:alert animated:YES completion:nil];
#endif
    }
}

/**
 送信ユーザーの選択
 */
- (IBAction)OnBoradcastMailingList:(id)sender
{
    // 処理中ステータス表示
    UILockWindowController *_bottomDialog = [self ProgressView:@"メール送信者リストの準備中です"];
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        // 確保
        BroadcastMailUserListViewController* controller = [BroadcastMailUserListViewController alloc];
        [controller initWithNibName:@"BroadcastMailUserListViewController" bundle:nil];
        [controller setUserInfoList: userInfoList];
        [controller setHeadPictureList:_headPictureList];
        [controller setUserMailStatusList:userMailStatusList];
        
        // popup表示
        MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC showPopupWindow:controller];
        
        // 遷移先の設定
        _windowView = WIN_VIEW_BROADCASTMAIL_USER_LIST;
        
        // 後片付け
        [controller release];
        [_bottomDialog dismissDialogViewControllerAnimated:YES];
        [_bottomDialog release];
    });
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    if(touch.phase == UITouchPhaseBegan) {
        
    }
}

/**
 テンプレート管理画面
 */
- (IBAction)OnTemplateManager:(id)sender
{
	// 確保
	TemplateManagerViewController* controller = [TemplateManagerViewController alloc];
	[controller initWithNibName:@"TemplateManagerViewController" bundle:nil];
	[controller setUserId:currentUserId];
	
	// popup表示
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC showPopupWindow:controller];
	
	// 遷移先の設定
	_windowView = WIN_VIEW_TEMPLATE_MANAGE;
	
	// 後片付け
	[controller release];
}
@end
