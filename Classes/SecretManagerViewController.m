//
//  SecretManagerViewController.m
//  iPadCamera
//
//  Created by TMS on 2016/06/26.
//
//

/*
 ** IMPORT
 */
#import "Common.h"
#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"
#import "SecretManagerViewController.h"
#import "TemplateListTableViewCell.h"
#import "userDbManager.h"
#import "SecretMemoInfo.h"
#import "ThumbnailViewController.h"
#import "OKDImageFileManager.h"

#import "SVProgressHUD.h"

#ifdef USE_ACCOUNT_MANAGER
#import "AccountManager.h"
#import "./others/SalesDataDownloder.h"
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

/*
 ** DEFINE
 */
#define CATEGORY_SEARCH_SAVE_KEY  @"CategorySearchData"

#define ALERT_TAG_DELETE 100
#define ALERT_TAG_HAKI1  101
#define ALERT_TAG_HAKI2  102
#define ALERT_TAG_HAKI3  103
#define ALERT_TAG_HAKI4  104

@implementation SecretManagerViewController

/*
 ** PROPERTY
 */
@synthesize userId;

#pragma mark iOS_Frmaework
/**
 initWithNibName
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self )
	{
        // Custom initialization
		// 初期のウィンドウの位置を設定しておく
		_windowView = WIN_VIEW_BROADCASTMAIL_USER_LIST;
		// テンプレートリスト管理の確保
        _templInfoList = [[TemplateInfoListManager alloc] initWithDelegate:self];
        // シークレットメモリストの確保
        SecretMemoInfoList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

/**
 viewDidLoad
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	// Mainビューの取得
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// カラーの取得
	UIColor* bkColor = [mainVC getColorTable:BK_COLOR_DEFAULT]; // 現在はデフォルト設定で背景色を設定しておく
	
    // 背景色の変更 RGB:D8BFD8
    [self.view setBackgroundColor:bkColor];
	
    //並び方を設定
    orderMode = 2;
    //作業モードの初期化
    workMode = 0;
	// ロードする
	[self refiningSecretMemoDatabase];

	// swipe
	[self setupSwipeRightView];
    
    [btnSakuseibiOrderBy setEnabled:YES];
    [btnSakuseibiOrderBy setAlpha:1.0f];
    [btnSakuseibiOrderByDesc setEnabled:NO];
    [btnSakuseibiOrderByDesc setAlpha:0.5f];
    [btnMemoOrderBy setEnabled:YES];
    [btnMemoOrderBy setAlpha:1.0f];
    [btnMemoOrderByDesc setEnabled:YES];
    [btnMemoOrderByDesc setAlpha:1.0f];
    
    [btnTemplateEditor setEnabled:NO];
    [btnTemplateEditor setAlpha:0.5f];
    [btnSecretMemoDelete setEnabled:NO];
    [btnSecretMemoDelete setAlpha:0.5f];
    
    [self setSecretMemoAllNum];
    
    //作業モードの初期化
    previewMailBody.editable = NO;
    previewMailBody.autocorrectionType = UITextAutocorrectionTypeNo;
    selectedSecretMemoId = 0;
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if ( iOSVersion >= 7.0 ){
        previewBody.frame = CGRectMake(previewBody.frame.origin.x, -20, previewBody.frame.size.width, previewBody.frame.size.height);
    }
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *status = [ud objectForKey:@"add_secret"];
    
    if (status != NULL) {
        [btnSecretMemoDelete setEnabled:NO];
        [btnSecretMemoDelete setAlpha:0.5f];
    }
}

/**
 viewDidUnload
 */
- (void) viewDidUnload
{
	// ボタン類の解放
	[btnTemplateCreator release];
	btnTemplateCreator = nil;
	[btnSecretMemoDelete release];
	btnSecretMemoDelete = nil;
	[btnTemplateEditor release];
	btnTemplateEditor = nil;
	// テーブルビューの解放
	[templateTableView release];
	templateTableView = nil;
    // テンプレートリスト管理の解放
	[_templInfoList release];
	_templInfoList = nil;

	[super viewDidUnload];
}

/**
 viewWillAppear
 */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [self rotateToInterfaceOrientation:self.interfaceOrientation WillRotate:false];
    
    colStatements_j = [NSMutableArray array];
    colStatements_e = [NSMutableArray array];
    NSArray *cols_j = @[@"あ", @"い", @"う", @"え", @"お",
                        @"か_が", @"き_ぎ", @"く_ぐ", @"け_げ", @"こ_ご",
                        @"さ_ざ", @"し_じ", @"す_ず", @"せ_ぜ", @"そ_ぞ",
                        @"た_だ", @"ち_ぢ", @"つ_づ", @"て_で", @"と_ど",
                        @"な", @"に", @"ぬ", @"ね", @"の",
                        @"は_ば_ぱ", @"ひ_び_ぴ", @"ふ_ぶ_ぷ", @"へ_べ_ぺ", @"ほ_ぼ_ぽ",
                        @"ま", @"み", @"む", @"め", @"も",
                        @"や", @"ゆ", @"よ",
                        @"ら", @"り", @"る", @"れ", @"ろ",
                        @"わ", @"を", @"ん",
                        @"A", @"B", @"C", @"D", @"E",
                        @"F", @"G", @"H", @"I", @"J",
                        @"K", @"L", @"M", @"N", @"O",
                        @"P", @"Q", @"R", @"S", @"T",
                        @"U", @"V", @"W", @"X", @"Y",
                        @"Z",
                        @"nn"];
    NSArray *cols_e = @[@"A", @"B", @"C", @"D", @"E",
                        @"F", @"G", @"H", @"I", @"J",
                        @"K", @"L", @"M", @"N", @"O",
                        @"P", @"Q", @"R", @"S", @"T",
                        @"U", @"V", @"W", @"X", @"Y",
                        @"Z",
                        @"あ_い_う_え_お",
                        @"か_が_き_ぎ_く_ぐ_け_げ_こ_ご",
                        @"さ_ざ_し_じ_す_ず_せ_ぜ_そ_ぞ",
                        @"た_だ_ち_ぢ_つ_づ_て_で_と_ど",
                        @"な_に_ぬ_ね_の",
                        @"は_ば_ぱ_ひ_び_ぴ_ふ_ぶ_ぷ_へ_べ_ぺ_ほ_ぼ_ぽ",
                        @"ま_み_む_め_も",
                        @"や_ゆ_よ",
                        @"ら_り_る_れ_ろ",
                        @"わ_を_ん",
                        @"nn"];
}

/**
 viewDidAppear
 */
- (void) viewDidAppear:(BOOL)animated
{
	switch( _windowView )
	{
	case WIN_VIEW_TEMPLATE_MANAGE:
		{
			// なにもしない
		}
		break;
			
	case WIN_VIEW_TEMPLATE_CREATOR:
		{
			// 位置を初期化しておく
			_windowView = WIN_VIEW_TEMPLATE_MANAGE;
            // ロードする
			[self refiningSecretMemoDatabase];
			// テーブルビューのリロード
			[templateTableView reloadData];
			// 再選択
			if ( _oldIndexPath != nil )
			{
				[templateTableView selectRowAtIndexPath:_oldIndexPath
											   animated:YES
										 scrollPosition:UITableViewScrollPositionNone];
			}
		}
		break;
			
	default:
		break;
	}
	[super viewDidAppear:animated];
}

/**
 viewDidDisappear
 */
- (void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
}

/**
 didRecieveMemoryWarning
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 dealloc
 */
- (void) dealloc
{
	// ボタン類の解放
	[btnTemplateCreator release];
	[btnSecretMemoDelete release];
	[btnTemplateEditor release];
	// テーブルビューの解放
	[templateTableView release];
	[_templInfoList release];
    [SecretMemoInfoList release];
    
	[super dealloc];
}


#pragma mark Delegate
/**
 OnSwipeRightView
 @param sender
 @return void
 */
- (void) OnSwipeRightView:(id) sender
{
    
	[self OnReturnUserInfoList];
}

/**
 OnSwipeLeftView
 */
- (void) OnSwipeLeftView:(id) sender
{
}
/**
 alertView
 メモ削除時のアラートに対応
 */
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSInteger tag = [alertView tag];
    if ( tag == ALERT_TAG_DELETE){
		// キャンセル時は何もしない
		if ( buttonIndex != 0 ) return;
        
        [self DeleteSecretMemo];
        
	}else if ( tag == ALERT_TAG_HAKI1){
        // キャンセル時は何もしない
        if ( buttonIndex != 0 ) return;
        [self TransitionNew];
        
    }else if ( tag == ALERT_TAG_HAKI2){
        // キャンセル時は何もしない
        if ( buttonIndex != 0 ){
            // テーブルビューのリロード
            [templateTableView reloadData];
            return;
        }

        [self TransitionEdit];
    }else if ( tag == ALERT_TAG_HAKI3){
        // キャンセル時は何もしない
        if ( buttonIndex != 0 ){
            return;
        }
        
        [self ReturnUserInfoList];
    }else if ( tag == ALERT_TAG_HAKI4){
        // キャンセル時は何もしない
        if ( buttonIndex != 0 ){
            // テーブルビューのリロード
            [templateTableView reloadData];
            // 選択しなおし
            initStr = [self ReSelected];
            
            return;
        }

        [self TransitionEdit];
    }
}

- (void)DeleteSecretMemo{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    
//    [usrDbMng deleteSecretMemoWithDateUserID:userId:selectedSecretMemoId];
    [usrDbMng deleteSecretMemoWithDateUserID:userId :selectedSecretMemoId :selectedSMDate];
    
    [self refiningSecretMemoDatabase];
    
    // テーブルビューのリロード
    [templateTableView reloadData];
    // 選択解除
    [self SelectedRelease];
    
    previewMailBody.editable = NO;
    
    [usrDbMng release];
}

#pragma mark TableView_DataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

/**
 tableView: numberOfRowsInSection:
 セクションに含まれるセル数を返す
 */
- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
	return [SecretMemoInfoList count];
}

/**
 tableView: cellForRowAtIndexPath:
 セルの内容を返す
 */
- (UITableViewCell*) tableView:(UITableView*) tableView
		 cellForRowAtIndexPath:(NSIndexPath*) indexPath
{
	static NSString *CellIndentifier = @"template_info_cell";
	TemplateListTableViewCell* cell = (TemplateListTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIndentifier];
	if ( cell == nil )
	{
		UIViewController* viewController = [[UIViewController alloc] initWithNibName:@"TemplateListTableViewCell" bundle:nil];
		cell = (TemplateListTableViewCell*)[viewController view];
		[viewController release];

		// Mainビューの取得
		MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		UIColor* bkNoSelectCell = [mainVC getColorTable:BK_NOSELECT_CELL]; // 非選択状態のセルの背景色
		UIColor* bkSelectedCell = [mainVC getColorTable:BK_SELECTED_CELL]; // 選択状態のセルの背景色

        // Cell選択時に青色にする(iOS7対応)
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [cell.selectedBackgroundView setBackgroundColor:bkSelectedCell];
        cell.selectedBackgroundView.layer.cornerRadius = 10.0f;
        cell.selectedBackgroundView.layer.masksToBounds = YES;
        // 背景色：F0FFFF
        cell.backgroundColor = bkNoSelectCell;
	}

	// セルの内容更新
	[self updateCell:cell IndexPath:indexPath];
	
	return cell;
}

/**
 セルの内容更新
 @param cell セル
 @param indexPath インデックス
 @return なし
 */
- (void) updateCell:(TemplateListTableViewCell*) cell IndexPath:(NSIndexPath*) indexPath
{
	// テンプレート情報
    SecretMemoInfo* info = [SecretMemoInfoList objectAtIndex:indexPath.row];

    cell.templTitle.text = [self toDateStr:info.sakuseibi];
    BOOL isPortrait = ( self.interfaceOrientation == UIInterfaceOrientationPortrait
                       || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown );
    if(isPortrait ){
        cell.templTitle.font = [UIFont systemFontOfSize:14.0f];
    }else{
        cell.templTitle.font = [UIFont systemFontOfSize:10.0f];
    }
    [cell.templTitle setTextAlignment:NSTextAlignmentCenter];
	// シークレットメモ本文を設定
	cell.templPreview.text = info.memo;
}

- (NSString *)toDateStr:(NSDate *)date {
    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc] init];
    NSString *outputDateFormatterStr = @"yyyy年MM月dd日 HH時mm分";
    [outputDateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [outputDateFormatter setDateFormat:outputDateFormatterStr];
    NSString *outputDateStr = [outputDateFormatter stringFromDate:date];
    [outputDateFormatter release];
    return outputDateStr;
}

#pragma mark TableView_Delegate
/**
 tableView: didSelectRowAtIndexPath:
 セルタップ時に呼び出される
 */
- (void) tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath*) indexPath
{
    // 作業モードを編集モードに
    if(workMode == 1 && [previewMailBody.text length] > 0){
        [self showAlert2];
    }else if((workMode == 2) && ([initStr compare:previewMailBody.text] != NSOrderedSame)){
        [self showAlert3];
    }else{
        [self TransitionEdit];
    }
    

}

// 編集モードへ
- (void)TransitionEdit{
  
    workMode = 2;
    
    [btnTemplateEditor setEnabled:YES];
    [btnTemplateEditor setAlpha:1.0f];
    [btnSecretMemoDelete setEnabled:YES];
    [btnSecretMemoDelete setAlpha:1.0f];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *status = [ud objectForKey:@"add_secret"];
    
    if (status != NULL) {
        [btnSecretMemoDelete setEnabled:NO];
        [btnSecretMemoDelete setAlpha:0.5f];
    }
    
    NSIndexPath *indexPath = [templateTableView indexPathForSelectedRow];
    
    UITableViewCell* cell = [templateTableView cellForRowAtIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    SecretMemoInfo* info = [SecretMemoInfoList objectAtIndex:indexPath.row];
    previewMailBody.text = info.memo;
    previewMailBody.editable = YES;
    initStr = info.memo;
    selectedSecretMemoId = [info.secretMemoId integerValue];
    
    selectedSMDate = info.sakuseibi;
}

#pragma mark LocalMethod
/**
 setupSwipe
 */
- (BOOL) setupSwipeRightView
{
	UISwipeGestureRecognizer* swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(OnSwipeRightView:)];
	if ( swipeRight == nil ) return NO;
	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	swipeRight.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeRight];
	[swipeRight release];
	return YES;
}

/**
 setupSwipeLeftView
 */
- (BOOL) setupSwipeLeftView:(BOOL) regist
{
	if ( regist == YES )
	{
		BOOL bFind = NO;
		NSArray* array = [self.view gestureRecognizers];
		for ( UISwipeGestureRecognizer* swipe in array )
		{
			// 左スワイプを検索
			if ( swipe.direction == UISwipeGestureRecognizerDirectionLeft )
			{
				bFind = YES;
				break;
			}
		}
		if ( bFind == NO )
		{
			// 左スワイプを追加
			UISwipeGestureRecognizer* swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(OnSwipeLeftView:)];
			if ( swipeLeft == nil ) return NO;
			swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
			swipeLeft.numberOfTouchesRequired = 1;
			[self.view addGestureRecognizer:swipeLeft];
			[templateTableView addGestureRecognizer:swipeLeft];
			[swipeLeft release];
		}
	}
	else
	{
		NSArray* array = [self.view gestureRecognizers];
		for ( UISwipeGestureRecognizer* swipe in array )
		{
			// 左スワイプを削除
			if ( swipe.direction == UISwipeGestureRecognizerDirectionLeft )
			{
				[self.view removeGestureRecognizer:swipe];
				[templateTableView removeGestureRecognizer:swipe];
				break;
			}
		}
	}
	return YES;
}

/**
 */

-(void) setSecretMemoAllNum
{
    lblTemplateAllNum.text = [NSString stringWithFormat:@"登録件数%ld件", (long)[SecretMemoInfoList count]];
}

/**
 カテゴリーでテンプレートを絞り込みする
 */
- (BOOL) refiningSecretMemoDatabase
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
    SecretMemoInfoList = [usrDbMng selectSecretMemoOrderBy:userId :orderMode];
	[usrDbMng release];
	
    lblTemplateAllNum.text = [NSString stringWithFormat:@"登録件数%ld件", (long)[SecretMemoInfoList count]];

	return YES;
}

#pragma mark Instance_Method
/**
 初期化
 */
- (id) initWithDelegate:(id)delegate
{
	self = [self initWithNibName:@"SecretManagerViewController" bundle:nil];
	if ( self )
	{
		// デリゲート
		_delegate = delegate;
	}
	return self;
}


#pragma mark Handler
/**
 OnReturnUserInfoList
 */
- (IBAction) OnReturnUserInfoList
{
    if(workMode == 1 && [previewMailBody.text length] > 0){
        [self showAlertSeni];
    }else if((workMode == 2) && ([initStr compare:previewMailBody.text] != NSOrderedSame)){
        [self showAlertSeni];
    }else{
        [self ReturnUserInfoList];
    }
}

- (void)ReturnUserInfoList{
    MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    UIInterfaceOrientation orient = self.interfaceOrientation;
    if ( UIInterfaceOrientationIsPortrait(orient) )
    {
        // 縦なら横に強制的に値だけ変更
        [mainVC setBeforeInterfaceOrient:UIInterfaceOrientationLandscapeLeft];
    }
    else
    {
        // 横なら縦に強制的に値だけ変更
        [mainVC setBeforeInterfaceOrient:UIInterfaceOrientationPortrait];
    }
    [mainVC closePopupWindow:self];

}

/**
 OnTemplateCreator
 */
- (IBAction) OnTemplateCreator:(id)sender
{
    NSLog(@"in preview = %@ and ordersame = %ld",previewMailBody.text,(long)NSOrderedSame);
    if((workMode == 2) && ([initStr compare:previewMailBody.text] != NSOrderedSame)){
            [self showAlert];
    }else{
        [self TransitionNew];
    }

}

//新規モードへ遷移
- (void)TransitionNew{
    
    previewMailBody.editable = YES;
    
    [self SelectedRelease];
    
    workMode = 1;
    
    [previewMailBody becomeFirstResponder];
    
    [btnTemplateEditor setEnabled:YES];
    [btnTemplateEditor setAlpha:1.0f];
    
    // テーブルビューのリロード
    [templateTableView reloadData];
    

}

- (void)SelectedRelease{

    [btnTemplateEditor setEnabled:NO];
    [btnTemplateEditor setAlpha:0.5f];
    [btnSecretMemoDelete setEnabled:NO];
    [btnSecretMemoDelete setAlpha:0.5f];
    
    if(workMode == 2 || workMode == 3){
        
        float x = previewMailBody.frame.origin.x;
        float y = previewMailBody.frame.origin.y;
        float w = previewMailBody.frame.size.width;
        float h = previewMailBody.frame.size.height;
        [previewMailBody removeFromSuperview];
        previewMailBody.frame = CGRectMake(x, y, w, h);
        [preview addSubview:previewMailBody];
        
        previewMailBody.text = @"";
    }
    selectedSecretMemoId = 0;
    
    workMode = 0;
}

/**
 OnSecretMemoDelete
 */
- (IBAction) OnSecretMemoDelete:(id)sender
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [templateTableView indexPathForSelectedRow];
	if ( indexPath == nil )
	{
		[Common showDialogWithTitle:@"注意" message:@"シークレットメモが選択されていません"];
		return;
	}

    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion < 8.0f) {
        //テンプレート削除用アラートの表示
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"シークレットメモの削除"
                                                            message:@"選択しているシークレットメモを削除しますか？"
                                                           delegate:self
                                                  cancelButtonTitle:@"はい"
                                                  otherButtonTitles:@"いいえ", nil];
        [alertView setTag:ALERT_TAG_DELETE];
        [alertView show];
        [alertView release];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"シークレットメモの削除"
                                                                       message:@"選択しているシークレットメモを削除しますか？"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"はい"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self DeleteSecretMemo];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"いいえ"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)_doCloud2SyncMain {
    // クラウドと同期処理の実行
    [CloudSyncClientManager clientSyncProc : ^(SYNC_RESPONSE_STATE result)
     {
         BOOL isSyncNomal = YES;
         
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
             }
      
#ifdef DEF_ABCARTE
             if(isSyncNomal == NO){
                 
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
                     
                     [self alertDisp:@"ログアウトに失敗しました。" alertTitle:@"ログアウト失敗"];
                 }
             }else{
                 //2015/11/17 TMS アカウントの有効性チェック対応
                 if([self isAccountStateChk]){
                     
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
             
             NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
             [ud setObject:nil forKey:@"first_add"];
             [ud synchronize];
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
         
//         [indicator stopAnimating];
//         [pending dismissViewControllerAnimated:true completion:nil];
//         pending = nil;
         
         if (result == SYNC_RSP_OK) {
             NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
             [ud setObject:nil forKey:@"first_add"];
             [ud setObject:nil forKey:@"add_secret"];
             [ud setObject:nil forKey:@"add_carte"];
             [ud synchronize];
         }
         
         [indicator stopAnimating];
         [SVProgressHUD dismiss];
         
     }
     ];
}

- (void) alertDisp2:(NSString*) message alertTitle:(NSString*) altTitle
{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:altTitle
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:alertView animated:NO completion:nil];
    });
}

// alert表示
- (void) alertDisp:(NSString*) message alertTitle:(NSString*) altTitle
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:altTitle
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertViewStyleDefault
                                            handler:nil]];
    
    [self presentViewController:alert animated:NO completion:nil];
}

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

- (void) allListClear
{
    for (id usrList in userInfoListArray)
    {
        [ (NSMutableArray*)usrList removeAllObjects];
    }
}

- (void) addWhereStatementWithStringBuffer:(NSMutableString*)sqlAdd
{
    ShopManager *shopMng = [ShopManager defaultManager];
    
    // 店舗アカウントでない場合は追加しない
    if (! [shopMng isAccountShop] )
    {   return; }
    
    // 現在選択中の店舗ID一覧の取得
    NSArray *selectedShops = [shopMng getSeletedShopIDs];
    
    // 一覧がない場合は追加しない
    if ([selectedShops count] <= 0)
    {   return; }
    
    NSMutableString *shops = [NSMutableString string];
    for (NSString* sID in selectedShops)
    {
        if ([shops length] > 0)
        {   [shops appendString:@" OR "]; }
        
        [shops appendFormat:@"mst_user.shop_id = %@", sID];
    }
    
    [sqlAdd appendString:@" AND ("];
    [sqlAdd appendString:shops];
    [sqlAdd appendString:@" ) "];
}

- (void) setUserInfoList:(NSString*)searchKeyword selectKind:(SELECT_JYOUKEN_KIND)kind
{
    //リストの全クリア
    [self allListClear];
    
    // 全検索か？
    searchKind = ([searchKeyword length] <= 0)?
    SEARCH_KIND_ALL : SEARCH_KIND_ONE_STRING;
    
    // データベースの初期化
    userDbManager *dbMng = [[userDbManager alloc] init];
    
    // 該当行のuser一覧
    NSMutableArray *users;
    
    if (searchKind == SEARCH_KIND_ALL)
    {
        // 全検索
        for (NSUInteger i = 0; i < [self getSectionMax]; i++)
        {
            // 各行のSQLステートメント文字取り出し:あ,い,う,え,お
            NSString *sqlState = [self checkLanguage]?
            (NSString*)[colStatements_j objectAtIndex:i] : (NSString*)[colStatements_e objectAtIndex:i];
            
            NSMutableString *sqlAdd = [NSMutableString string];
            [sqlAdd appendString:sqlState];
#ifdef CLOUD_SYNC
            // 現在選択中の店舗IDによる条件の追加
            [self addWhereStatementWithStringBuffer:sqlAdd];
#endif
            if (i < ([self getSectionMax] - 1) ) {
                // お客様番号でのSQLステートメントがない場合のみ適用する
                [sqlAdd appendString:@" ORDER BY first_name_kana, second_name_kana"];
            }
            else {
                [sqlAdd appendString:@" ORDER BY regist_number"];
            }
          
            // 該当行のユーザ情報一覧の取得
            users = [dbMng getUserInfoListBySearch:sqlAdd];
            
            // 指定行のリストを取り出して、ユーザ一覧を加える
            NSMutableArray    *list
            = [userInfoListArray objectAtIndex:i];
            for (id user in users)
            { [list addObject:user]; }
        }
    }
    else
    {
        // 検索指定
        
        // 検索文字よりSQLステートメントを生成
        // first_name_kana LIKE 'けんさく%'
        NSMutableString *sqlState = nil;
        switch (kind) {
            case SELECT_FIRST_NAME_KANA:
                sqlState
                = [NSMutableString stringWithFormat:@" first_name_kana LIKE '%@%%'",
                   searchKeyword];
                break;
            case SELECT_FIRST_NAME:
                sqlState
                = [NSMutableString stringWithFormat:@" first_name LIKE '%@%%'",
                   searchKeyword];
                break;
            case SELECT_LAST_WORK_DATE:
                // 将来対応
                break;
            default:
                break;
        }
        
        if (! sqlState)
        {
            [dbMng release];
            return;}
        
#ifdef CLOUD_SYNC
        // 現在選択中の店舗IDによる条件の追加
        [self addWhereStatementWithStringBuffer:sqlState];
#endif
        // 検索文字に該当するのユーザ情報一覧の取得
        [sqlState appendString:@" ORDER BY first_name_kana"];
        users = [dbMng getUserInfoListBySearch:sqlState];
        // 検索指定の場合は、先頭リストを取り出して、ユーザ一覧を加える
        NSMutableArray    *list
        = [userInfoListArray objectAtIndex:0];
        for (id user in users)
        { [list addObject:user]; }
        
        if ([searchKeyword length] > 0) {
            searchNameTitle = [NSString stringWithFormat:@"お客様名「%@」で検索　　%lu 件",
                               searchKeyword, (unsigned long)[users count]];
            [searchNameTitle retain];
        } else {
            searchNameTitle = @"";
        }
    }
    [dbMng release];
    
}

- (BOOL)checkLanguage
{
    // ユーザ設定を取得
    BOOL isJapanese = NO;
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSString *country = [df stringForKey:@"USER_COUNTRY"];
    // 2015/10/27 TMS iOS9対応
    if ([country isEqualToString:@"ja-JP"] || [country isEqualToString:@"ja"] || [country isEqualToString:@"en-JP"]) {
        isJapanese = YES;
    }
    return isJapanese;
}

- (NSInteger)getSectionMax
{
    NSInteger max = SECTION_MAX;
    
    if (![self checkLanguage]) {
        max = SECTION_EMAX;
    }
    
    return max;
}

/**
 OnTemplateEditor
 */

- (IBAction) OnTemplateEditor:(id)sender
{
    
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    
    if(workMode == 1){
        //シークレットメモの登録
        NSDate *now = [NSDate date];
        [usrDbMng insertSecretMemoWithDateUserID:userId:1:previewMailBody.text :now];
        
        [self refiningSecretMemoDatabase];
        // テーブルビューのリロード
        [templateTableView reloadData];
        
        float x = previewMailBody.frame.origin.x;
        float y = previewMailBody.frame.origin.y;
        float w = previewMailBody.frame.size.width;
        float h = previewMailBody.frame.size.height;
        [previewMailBody removeFromSuperview];
        previewMailBody.frame = CGRectMake(x, y, w, h);
        [preview addSubview:previewMailBody];
        
        previewMailBody.text = @"";
        previewMailBody.editable = NO;
        
        
        //選択解除
        [self SelectedRelease];
        
        [previewMailBody resignFirstResponder];
        
    }else if(workMode == 2){
        //シークレットメモの更新
       [usrDbMng updateSecretMemoWithDateUserID:userId:selectedSecretMemoId:previewMailBody.text:selectedSMDate];
        //initStr =  [NSString stringWithFormat: @"%@", previewMailBody.text];
        //NSString *aaa = previewMailBody.text;
        //NSLog(@"aaa = %@ を更新",aaa);
        //initStr = @"ABC";
        
        [self refiningSecretMemoDatabase];
        // テーブルビューのリロード
        [templateTableView reloadData];
        // 選択しなおし
        initStr = [self ReSelected];
        
        [previewMailBody resignFirstResponder];
    }
    
    [usrDbMng release];
}

//- (IBAction) OnTemplateEditor:(id)sender
//{
//
//    userDbManager *usrDbMng = [[userDbManager alloc] init];
//
//    if(workMode == 1){
//
//        //シークレットメモの登録
//        NSDate *now = [NSDate date];
//
//        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
//        NSString *status = [ud objectForKey:@"add_secret"];
//
//        if (status == NULL) {
//            [ud setObject:@"true" forKey:@"add_secret"];
//            [ud synchronize];
//        }
//
//        [btnSecretMemoDelete setEnabled:NO];
//        [btnSecretMemoDelete setAlpha:0.5f];
//
//        REACHABLE_STATUS rStat
//        = [ReachabilityManager reachabilityStatusWithHostName: ACCOUNT_HOST_URL];
//        if (rStat != REACHABLE_HOST)
//        {
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"シークレットメモはネットワークに接続している時のみご利用頂けます。"
//                                                                message:@"ネットワーク接続のご確認をお願いします。"
//                                                               delegate:self
//                                                      cancelButtonTitle:@"OK"
//                                                      otherButtonTitles:nil];
//            [alertView show];
//            [alertView release];
//            return;
//        }
//
//        [usrDbMng insertSecretMemoWithDateUserID:userId:1:previewMailBody.text :now];
//
//        [self refiningSecretMemoDatabase];
//        // テーブルビューのリロード
//        [templateTableView reloadData];
//
//        float x = previewMailBody.frame.origin.x;
//        float y = previewMailBody.frame.origin.y;
//        float w = previewMailBody.frame.size.width;
//        float h = previewMailBody.frame.size.height;
//        [previewMailBody removeFromSuperview];
//        previewMailBody.frame = CGRectMake(x, y, w, h);
//        [preview addSubview:previewMailBody];
//
//        previewMailBody.text = @"";
//        previewMailBody.editable = NO;
//
//        //選択解除
//        [self SelectedRelease];
//
//        [SVProgressHUD showProgress:0.5 status:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
//        indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.view.center.x - 150, self.view.center.y - 150, 300, 300)];
//        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
//        [self.view addSubview:indicator];
//        [indicator startAnimating];
//        [indicator setHidesWhenStopped:YES];
//
////         メッセージPopup windowの表示
////        [MainViewController showMessagePopupWithMessage:@"クラウドと同期を開始します....."];
//
//        // 写真アップロードを中断する
//        CloudSyncPictureUploadManager *pictUploader
//        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cloudPictureUploader;
//        [pictUploader uploadInnterrupt];
//
//        // 動画アップロードを中断する
//        VideoUploader *videoUploader
//        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).videoUploader;
//        [videoUploader uploadInnterrupt];
//
//        // 契約オプションチェック
//        AccountManager *acMgr = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).accountCountine;
//        if (![acMgr doAccountOptionCheck]) {
//            // メッセージPopup windowを閉じる
//            [MainViewController closeBottomModalDialog];
//            return;
//        }
//
//        if (![AccountManager isCloud]) {
//            [MainViewController closeBottomModalDialog];
//            return;
//        }
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [self _doCloud2SyncMain];
//        });
//
//    }else if(workMode == 2){
//        //シークレットメモの更新
//        [usrDbMng updateSecretMemoWithDateUserID:userId:selectedSecretMemoId:previewMailBody.text:selectedSMDate];
//        //initStr =  [NSString stringWithFormat: @"%@", previewMailBody.text];
//        //NSString *aaa = previewMailBody.text;
//        //NSLog(@"aaa = %@ を更新",aaa);
//        //initStr = @"ABC";
//
//        [self refiningSecretMemoDatabase];
//        // テーブルビューのリロード
//        [templateTableView reloadData];
//        // 選択しなおし
//        initStr = [self ReSelected];
//
//        [previewMailBody resignFirstResponder];
//    }
//
//    [usrDbMng release];
//}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    BOOL nowOrientation = (self.interfaceOrientation == UIInterfaceOrientationPortrait
                           || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    BOOL toOrientation = (toInterfaceOrientation == UIInterfaceOrientationPortrait
                          || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    if( nowOrientation != toOrientation ){
        [self rotateToInterfaceOrientation:self.interfaceOrientation WillRotate:true];
    }
}

/**
 端末の回転によるレイアウト変更
 */
-(void) rotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation WillRotate:(bool) willRotate
{
    /**
     この関数が呼ばれた際のViewControllerの端末方向を判定している。
     willRotation~だと回転開始時の端末の向きを取得して
     */
    
    BOOL isPortrait = ( interfaceOrientation == UIInterfaceOrientationPortrait
                  || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown );     //  レイアウト変更後の画面が縦画面か？
    
    if( willRotate ){
        //  interfaceOrientationが画面のレイアウト変更前の端末の向き
        isPortrait = !isPortrait;
    }
    
    int x, y, w, h;
    int verHeightOfs = 0;     //  iOS7を基準としている
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if ( iOSVersion < 7.0 ){
        verHeightOfs = -20;
    }
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    if( isPortrait ){
        
        if (rect.size.width > rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        x = 20;
        y = 72;
        w = rect.size.width - 40;
        h = 358;
        preview.frame = CGRectMake(x, y, w, h);
        
        previewMailBody.frame = CGRectMake(0, -10, 728, 347);

        x = 209;
        y = 450;
        w = btnSakuseibiOrderByDesc.frame.size.width;
        h = btnSakuseibiOrderByDesc.frame.size.height;
        btnSakuseibiOrderByDesc.frame = CGRectMake(x, y, w, h);
        
        x = btnSakuseibiOrderByDesc.frame.origin.x + btnSakuseibiOrderByDesc.frame.size.width + 3;
        w = btnSakuseibiOrderBy.frame.size.width;
        h = btnSakuseibiOrderBy.frame.size.height;
        btnSakuseibiOrderBy.frame = CGRectMake(x, y, w, h);
        
        x = btnSakuseibiOrderBy.frame.origin.x + btnSakuseibiOrderBy.frame.size.width + 3;
        w = btnMemoOrderByDesc.frame.size.width;
        h = btnMemoOrderByDesc.frame.size.height;
        btnMemoOrderByDesc.frame = CGRectMake(x, y, w, h);
        
        x = btnMemoOrderByDesc.frame.origin.x + btnMemoOrderByDesc.frame.size.width + 3;
        w = btnMemoOrderBy.frame.size.width;
        h = btnMemoOrderBy.frame.size.height;
        btnMemoOrderBy.frame = CGRectMake(x, y, w, h);
        
        x = rect.size.width - 20 - btnSecretMemoDelete.frame.size.width;
        y = 438;
        w = btnSecretMemoDelete.frame.size.width;
        h = btnSecretMemoDelete.frame.size.height;
        btnSecretMemoDelete.frame = CGRectMake(x, y, w, h);
        
        x = btnSecretMemoDelete.frame.origin.x - 8 - btnTemplateEditor.frame.size.width;
        y = btnSecretMemoDelete.frame.origin.y;
        w = btnTemplateEditor.frame.size.width;
        h = btnTemplateEditor.frame.size.height;
        btnTemplateEditor.frame = CGRectMake(x, y, w, h);
        
        x = 20;
        y = btnSecretMemoDelete.frame.origin.y;
        w = btnTemplateCreator.frame.size.width;
        h = btnTemplateCreator.frame.size.height;
        btnTemplateCreator.frame = CGRectMake(x, y, w, h);
        
        x = 20;
        y = 490;
        w = preview.frame.size.width;
        h = rect.size.height - 20 - y + verHeightOfs;
        templateList.frame = CGRectMake(x, y, w, h);
        
        for(int i = 0;i < [SecretMemoInfoList count];i++){
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            TemplateListTableViewCell *cell = [templateTableView cellForRowAtIndexPath:indexPath];
            cell.templTitle.font = [UIFont systemFontOfSize:14.0f];
            [templateTableView performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
        }
    }
    else{
        if (rect.size.width < rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        
        x = 200;
        y = 32;
        w = btnSakuseibiOrderByDesc.frame.size.width;
        h = btnSakuseibiOrderByDesc.frame.size.height;
        btnSakuseibiOrderByDesc.frame = CGRectMake(x, y, w, h);
        
        x = btnSakuseibiOrderByDesc.frame.origin.x + btnSakuseibiOrderByDesc.frame.size.width + 8;
        w = btnSakuseibiOrderBy.frame.size.width;
        h = btnSakuseibiOrderBy.frame.size.height;
        btnSakuseibiOrderBy.frame = CGRectMake(x, y, w, h);
        
        x = btnSakuseibiOrderBy.frame.origin.x + btnSakuseibiOrderBy.frame.size.width + 8;
        w = btnMemoOrderByDesc.frame.size.width;
        h = btnMemoOrderByDesc.frame.size.height;
        btnMemoOrderByDesc.frame = CGRectMake(x, y, w, h);
        
        x = btnMemoOrderByDesc.frame.origin.x + btnMemoOrderByDesc.frame.size.width + 8;
        w = btnMemoOrderBy.frame.size.width;
        h = btnMemoOrderBy.frame.size.height;
        btnMemoOrderBy.frame = CGRectMake(x, y, w, h);
        
        x = 20;
        y = 72;
        w = rect.size.width / 2 - 30;
        h = rect.size.height - 20 - btnSecretMemoDelete.frame.size.height - 10 - y + verHeightOfs;
        templateList.frame = CGRectMake(x, y, w, h);
        
        x = templateList.frame.origin.x + templateList.frame.size.width - btnSecretMemoDelete.frame.size.width;
        y = templateList.frame.origin.y + templateList.frame.size.height + 10;
        w = btnSecretMemoDelete.frame.size.width;
        h = btnSecretMemoDelete.frame.size.height;
        btnSecretMemoDelete.frame = CGRectMake(x, y, w, h);
        
        x = btnSecretMemoDelete.frame.origin.x - 8 - btnTemplateEditor.frame.size.width;
        y = btnSecretMemoDelete.frame.origin.y;
        w = btnTemplateEditor.frame.size.width;
        h = btnTemplateEditor.frame.size.height;
        btnTemplateEditor.frame = CGRectMake(x, y, w, h);
        
        x = btnTemplateEditor.frame.origin.x - 98 - btnTemplateEditor.frame.size.width;
        y = btnTemplateEditor.frame.origin.y;
        w = btnTemplateCreator.frame.size.width;
        h = btnTemplateCreator.frame.size.height;
        btnTemplateCreator.frame = CGRectMake(x, y, w, h);
        
        x = templateList.frame.origin.x + templateList.frame.size.width + 20;
        y = templateList.frame.origin.y;
        w = rect.size.width - 20 - x;
        h = rect.size.height - 20 - y + verHeightOfs;
        preview.frame = CGRectMake(x, y, w, h);
        
        previewMailBody.frame = CGRectMake(0, -10, w, h);
        
        for(int i = 0;i < [SecretMemoInfoList count];i++){
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            TemplateListTableViewCell *cell = [templateTableView cellForRowAtIndexPath:indexPath];
            cell.templTitle.font = [UIFont systemFontOfSize:10.0f];
            [templateTableView performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [templateTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

/**
 作成日の昇順
 */
- (IBAction) OnOrderBySakuseibi:(id)sender{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    orderMode = 1;
    SecretMemoInfoList = [usrDbMng selectSecretMemoOrderBy:userId :orderMode];
    [usrDbMng release];
    
    [btnSakuseibiOrderBy setEnabled:NO];
    [btnSakuseibiOrderBy setAlpha:0.5f];
    [btnSakuseibiOrderByDesc setEnabled:YES];
    [btnSakuseibiOrderByDesc setAlpha:1.0f];
    [btnMemoOrderBy setEnabled:YES];
    [btnMemoOrderBy setAlpha:1.0f];
    [btnMemoOrderByDesc setEnabled:YES];
    [btnMemoOrderByDesc setAlpha:1.0f];

    
    // テーブルビューのリロード
    [templateTableView reloadData];
    // 選択行を選択しなおす
    [self ReSelected];
}

/**
 作成日の降順
 */
- (IBAction) OnOrderBySakuseibiDesc:(id)sender{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    orderMode = 2;
    SecretMemoInfoList = [usrDbMng selectSecretMemoOrderBy:userId :orderMode];
    [usrDbMng release];
    
    [btnSakuseibiOrderBy setEnabled:YES];
    [btnSakuseibiOrderBy setAlpha:1.0f];
    [btnSakuseibiOrderByDesc setEnabled:NO];
    [btnSakuseibiOrderByDesc setAlpha:0.5f];
    [btnMemoOrderBy setEnabled:YES];
    [btnMemoOrderBy setAlpha:1.0f];
    [btnMemoOrderByDesc setEnabled:YES];
    [btnMemoOrderByDesc setAlpha:1.0f];
    
    // テーブルビューのリロード
    [templateTableView reloadData];
    // 選択行を選択しなおす
    [self ReSelected];
    

}

/**
 本文の昇順
 */
- (IBAction) OnOrderByMemo:(id)sender{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    orderMode = 3;
    SecretMemoInfoList = [usrDbMng selectSecretMemoOrderBy:userId :orderMode];
    [usrDbMng release];
    
    [btnSakuseibiOrderBy setEnabled:YES];
    [btnSakuseibiOrderBy setAlpha:1.0f];
    [btnSakuseibiOrderByDesc setEnabled:YES];
    [btnSakuseibiOrderByDesc setAlpha:1.0f];
    [btnMemoOrderBy setEnabled:NO];
    [btnMemoOrderBy setAlpha:0.5f];
    [btnMemoOrderByDesc setEnabled:YES];
    [btnMemoOrderByDesc setAlpha:1.0f];
    
    // テーブルビューのリロード
    [templateTableView reloadData];
    // 選択行を選択しなおす
    [self ReSelected];
}

/**
 本文の降順
 */
- (IBAction) OnOrderByMemoDesc:(id)sender{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    orderMode = 4;
    SecretMemoInfoList = [usrDbMng selectSecretMemoOrderBy:userId :orderMode];
    [usrDbMng release];
    
    [btnSakuseibiOrderBy setEnabled:YES];
    [btnSakuseibiOrderBy setAlpha:1.0f];
    [btnSakuseibiOrderByDesc setEnabled:YES];
    [btnSakuseibiOrderByDesc setAlpha:1.0f];
    [btnMemoOrderBy setEnabled:YES];
    [btnMemoOrderBy setAlpha:1.0f];
    [btnMemoOrderByDesc setEnabled:NO];
    [btnMemoOrderByDesc setAlpha:0.5f];
    
    // テーブルビューのリロード
    [templateTableView reloadData];
    // 選択行を選択しなおす
    [self ReSelected];
}

// 選択行を選択しなおす
- (NSString*)ReSelected{
    
    NSString *ret = @"";
    if(selectedSecretMemoId != 0){
        
        NSInteger index = 0;
        
        for(int i = 0;i < [SecretMemoInfoList count];i++){
            SecretMemoInfo *memoInfo = [SecretMemoInfoList objectAtIndex:i];
            if(selectedSecretMemoId == [memoInfo.secretMemoId integerValue]){
                index = i;
                ret = memoInfo.memo;
                break;
            }
        }
        
        [templateTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:0];
    }
    
    return ret;
}

- (void)showAlert
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion < 8.0f) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"シークレットメモ"
                                  message:@"編集中の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集中の内容は\n破棄されます）"
                                  delegate:self
                                  cancelButtonTitle:@"はい"
                                  otherButtonTitles:@"いいえ",nil
                                  ];
        [alertView setTag:ALERT_TAG_HAKI1];
        [alertView show];
        [alertView release];
    } else {

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"シークレットメモ"
                                                                       message:@"編集中の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集中の内容は\n破棄されます）"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"は　い"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self TransitionNew];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"いいえ"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [templateTableView reloadData];
                                                    
                                                    initStr = [self ReSelected];
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showAlert2{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion < 8.0f) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"シークレットメモ"
                                  message:@"編集中の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集中の内容は\n破棄されます）"
                                  delegate:self
                                  cancelButtonTitle:@"はい"
                                  otherButtonTitles:@"いいえ",nil
                                  ];
        [alertView setTag:ALERT_TAG_HAKI2];
        [alertView show];
        [alertView release];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"シークレットメモ"
                                                                       message:@"編集中の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集中の内容は\n破棄されます）"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"は　い"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self TransitionEdit];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"いいえ"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // テーブルビューのリロード
                                                    [templateTableView reloadData];
                                                    
                                                    initStr = [self ReSelected];
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showAlert3{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion < 8.0f) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"シークレットメモ"
                                  message:@"編集中の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集中の内容は\n破棄されます）"
                                  delegate:self
                                  cancelButtonTitle:@"はい"
                                  otherButtonTitles:@"いいえ",nil
                                  ];
        [alertView setTag:ALERT_TAG_HAKI4];
        [alertView show];
        [alertView release];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"シークレットメモ"
                                                                       message:@"編集中の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集中の内容は\n破棄されます）"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"は　い"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self TransitionEdit];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"いいえ"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // テーブルビューのリロード
                                                    [templateTableView reloadData];
                                                    // 選択しなおし
                                                    initStr = [self ReSelected];
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showAlertSeni{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion < 8.0f) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"シークレットメモ"
                                  message:@"編集中の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集中の内容は\n破棄されます）"
                                  delegate:self
                                  cancelButtonTitle:@"はい"
                                  otherButtonTitles:@"いいえ",nil
                                  ];
        [alertView setTag:ALERT_TAG_HAKI3];
        [alertView show];
        [alertView release];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"シークレットメモ"
                                                                       message:@"編集中の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集中の内容は\n破棄されます）"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"は　い"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self ReturnUserInfoList];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"いいえ"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    
                                                    [templateTableView reloadData];
                                                    
                                                    initStr = [self ReSelected];
                                                    
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification{

    BOOL isPortrait = ( self.interfaceOrientation == UIInterfaceOrientationPortrait
                       || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown );
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    
    int x, y, w, h;
    
    if(!isPortrait ){
        
        if (rect.size.width < rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        
        x = templateList.frame.origin.x + templateList.frame.size.width + 20;
        
        preview.frame = CGRectMake(x, templateList.frame.origin.y, rect.size.width - 20 - x,(rect.size.height - 20 - templateList.frame.origin.y)/2.6);
        previewMailBody.frame = CGRectMake(0, -10, rect.size.width - 20 - x,((rect.size.height - 20 - templateList.frame.origin.y)/2.6)-10);
    }else{
        
        if (rect.size.width > rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        x = 20;
        y = 72;
        w = rect.size.width - 40;
        h = 358;
        preview.frame = CGRectMake(x, y, w, h);
        previewMailBody.frame = CGRectMake(0, -10, 728, 347);
    }
}

- (void)keyboardWillHide:(NSNotification *)notification{
    
    BOOL isPortrait = ( self.interfaceOrientation == UIInterfaceOrientationPortrait
                       || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown );
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    
    int x, y, w, h;
    
    if(isPortrait ){
        if (rect.size.width > rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        x = 20;
        y = 72;
        w = rect.size.width - 40;
        h = 358;
        preview.frame = CGRectMake(x, y, w, h);
        previewMailBody.frame = CGRectMake(0, -10, 728, 347);
    }else{
        if (rect.size.width < rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        x = templateList.frame.origin.x + templateList.frame.size.width + 20;
        y = templateList.frame.origin.y;
        w = rect.size.width - 20 - x;
        h = rect.size.height - 20 - y;
        preview.frame = CGRectMake(x, y, w, h);
        previewMailBody.frame = CGRectMake(0, -10, w, h);
        [previewMailBody setNeedsDisplay];
    }
}

@end
