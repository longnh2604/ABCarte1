//
//  BroadcastMailUserListViewController.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/26.
//
//

/**
 ** IMPORT
 */
#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"
#import "BroadcastMailUserListViewController.h"
#import "TemplateCreatorViewController.h"
#import "TemplateManagerViewController.h"
#import "SearchResultTableViewCell.h"
#import "TemplateListTableViewCell.h"
#import "OKDImageFileManager.h"
#import "AccountManager.h"
#import "AccountLoginPopUp.h"
#import "./others/SalesDataDownloder.h"
#import "WebMailUserStatus.h"
#import "userDbManager.h"
#import "userFmdbManager.h"
#import "WebMailLogin.h"
#import "MailAddressSyncManager.h"
#import "BlockMailStatus.h"
#import "ThumbnailViewController.h"
#import "BroadcastMailUserInfoPopupController.h"
#import "shop/ShopManager.h"

#define ALERT_TAG_DELETE_HISTORY		100
#define ALERT_TAG_COMFIRM_TEMPLATE		101
#define ALERT_TAG_SEND_BROADCASTMAIL	102
#define ALERT_TAG_NOT_SELECT_USER		103

#define BTN_ALPHA_INVALID               0.5f    //  ボタンが無効状態の透過値

//  テンプレートカテゴリー選択ボタン機能で使用
#define CATEGORY_SEARCH_SAVE_KEY  @"CategorySearchData"
#define ALERT_TAG_DELETE_TEMPLATE	100
#define ALERT_TAG_INSERT_CATEGORY	101
#define ALERT_TAG_EDIT_CATEGORY		102
#define ALERT_TAG_DELETE_CATEGORY	103
#define ALERT_TAG_CLEARALL_CATEGORY	104


@interface BroadcastMailUserListViewController()
{
}
-(void) enabledSendBtn;
-(NSInteger) getUserTableSectionNum;
-(NSInteger) getUserTableCellNum:(NSInteger) section;
@end

@implementation BroadcastMailUserListViewController

/*
 ** PROPERTY
 */
@synthesize strSearchResult = _strSearchResult;
@synthesize userInfoList = _userInfoList;
@synthesize userMailStatusList = _userMailStatusList;

#pragma mark iOS_Frmaework
/**
 initWithNibName
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
		// 初期のウィンドウの位置を設定しておく
		_windowView = WIN_VIEW_BROADCASTMAIL_USER_LIST;
		// 検索結果のタイトル
		_strSearchResult = [NSString stringWithFormat:@"Title01"];
		// 送信ユーザー情報テーブルの確保
		_arrayBroadcastMailUser = [[NSMutableArray alloc] init];
		// 削除ユーザー情報テーブルの確保
		_arrayRemoveUserList = [[NSMutableDictionary alloc] init];
		// 全選択ボタンの状態：デフォルト全選択
		_selectedAll = YES;
        // 受信拒否者ボタンの状態：デフォルトのボタンラベルが「受信拒否者表示」（リスト上では受信拒否者が表示されていない状態）
        _showBlockMailUser = NO;
		// テンプレートリスト管理の確保
		_templInfoList = [[TemplateInfoListManager alloc] initWithDelegate:self];
		// カテゴリー名
		_arrayCategoryStrings = [[NSMutableArray alloc] init];
		// 選択されているカテゴリー名のロード
		[self initCategoryData];
        
        _previewPicturesList = [[NSMutableArray alloc] init];
        dummyView = [self createDummyView];
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
	
	// スワイプの設定
	[self setupSwipe];
    
    sectionTitles = nil;

	// ユーザー情報の作成
	[self createBroadcastMailUserInfo:NO];
    
    // カテゴリーをロードする
	[self loadCategoryName];
    
    // ロードする
	[self refiningTemplateDatabaseWithCategory:_strSelectCategory];
    
    [self setTemplateAllNum];
    
    activeSections = [[NSMutableArray alloc]init];
}

/**
 viewDidUnload
 */
- (void) viewDidUnload
{
	// ボタン類の解放
	[btnBroadcastMail release];
	btnBroadcastMail = nil;
	[btnTemplateManager release];
	btnTemplateManager = nil;
	[btnMailHistory release];
	btnMailHistory = nil;
	// テーブルビューの解放
	[userTableView release];
	userTableView = nil;
	// ポップオーバーの解放
	[popOverCtrlMailHist release];
	popOverCtrlMailHist = nil;
	// 写真リストの解放
	[_headPictureList release];
	_headPictureList = nil;
	// メール状態リストの解放
	[_userMailStatusList release];
	_userMailStatusList = nil;
	// テンプレートリスト管理の解放
	[_templInfoList release];
	_templInfoList = nil;
	
    [super viewDidUnload];
}

/**
 viewWillAppear
 */
- (void) viewWillAppear:(BOOL)animated
{
	switch ( _windowView )
	{
	case WIN_VIEW_BROADCASTMAIL_USER_LIST:
		{
			// ユーザーのメールアドレスが空ならユーザー情報から削除する
			if( [AccountManager isLogined] )
			{
				[self removeEmptyEmailUser];
			}
		}
		break;
	default:
		break;
	}
    
    [self enabledSendBtn];
    
    NSInteger section, row;
    if( ![_templInfoList getSelectedInfo:&section RowNum:&row] ){
        [self enabledTemplateSelectBtn:NO];
    }
    
    [self rotateToInterfaceOrientation:self.interfaceOrientation WillRotate:false];

	[super viewWillAppear:animated];
}

/**
 viewDidAppear
 */
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	switch ( _windowView )
	{
	case WIN_VIEW_BROADCASTMAIL_USER_LIST:
		{
		}
		break;

	case WIN_VIEW_TEMPLATE_MANAGE:
		{
			// 初期位置に戻しておく
			_windowView = WIN_VIEW_BROADCASTMAIL_USER_LIST;
		}
		break;
            
    case WIN_VIEW_TEMPLATE_CREATOR:
        {
            // カテゴリーをロードする
        }
        break;

	default:
		break;
	}
    
    // カテゴリーをロードする
    [self loadCategoryName];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
}

/**
 didReceiveMemoryWarning
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
	// 送信ユーザー情報の削除
	[_arrayBroadcastMailUser removeAllObjects];
	[_arrayBroadcastMailUser release];
	// ボタン類の解放
	[btnBroadcastMail release];
	[btnTemplateManager release];
	[btnMailHistory release];
	// テーブルビューの解放
	[userTableView release];
	// ポップオーバーの解放
	[popOverCtrlMailHist release];
	// 写真リストの解放
	[_headPictureList release];
	// メール状態リストの解放
	[_userMailStatusList release];
	// テンプレートリスト管理の解放
	[_templInfoList release];
    
    [_previewPicturesList removeAllObjects];
	[_previewPicturesList release];
    
    [dummyView release];
	[super dealloc];
}


#pragma mark SetupUserInterface
/**
 setupSwipe
 スワイプの設定
 */
- (BOOL) setupSwipe
{
	// swipe
	UISwipeGestureRecognizer* swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(OnSwipeRightView:)];
	if ( swipeRight == nil ) return NO;

	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	swipeRight.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeRight];
	[swipeRight release];

	// swipe
	swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hPreviewRightSwaip:)];
	if ( swipeRight == nil ) return NO;
    
	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	swipeRight.numberOfTouchesRequired = 1;
	[preview addGestureRecognizer:swipeRight];
	[swipeRight release];
    
	return YES;
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
 OnItemClicked
 SendMailHistoryPopupのデリゲート
 */
- (void) OnItemClicked:(id) sender Event:(NSInteger) event
{
	switch ( event )
	{
	case HIST_CLICKED_DELETE:
		{
			UISpecialAlertView* alert = [[UISpecialAlertView alloc] initWithTitle:@"確認"
																		  message:@"履歴を削除しますか？"
																		 delegate:self
																cancelButtonTitle:@"削除"
																otherButtonTitles:@"取消", nil];
			[alert setTag:ALERT_TAG_DELETE_HISTORY];
			[alert showWithCallback:^(NSInteger buttonIndex) {
				// キャンセルされた
				if ( buttonIndex != 0 ) return ;
				// 履歴削除が押された
				userFmdbManager* userFmdbMng = [[userFmdbManager alloc] init];
				[userFmdbMng initDataBase];
				[userFmdbMng removeAllWebMailError];
				[userFmdbMng removeAllWebMailErrorUsers];
				[userFmdbMng release];
			}];
			 
		}
		break;

	case HIST_CLICKED_CANCEL:
		{
			// キャンセルが押されたから閉じる
			if ( popOverCtrlMailHist != nil )
				[popOverCtrlMailHist dismissPopoverAnimated:YES];
		}
		break;
			
	default:
		break;
	}
}

/**
 一斉送信メール送信完了通知
 */
- (void) finishedBroadcastMailInSuccessUsers:(NSArray*)arraySuccessUsers 
								 FailedUsers:(NSArray*)arrayFailedUsers
								  TemplateId:(NSString*)TemplateId
								   Exception:(NSException*)statusException
{
	if ( statusException != nil )
	{
		NSString* code = [statusException name];
		if ( [code isEqualToString:@"500"] == YES )
		{
			// 送信後のアラート（認証エラーの場合は送信がまったくされていないのでDBに書き込まないようにする）
			[self alertOnlyOkWithTitle:@"お知らせ" Message:@"ログインに失敗しました\nもう一度送信して下さい"];
			return;
		}
		else if ( [code isEqualToString:@"-1009"] == YES )
		{
			// 送信後のアラート（オフラインの場合は送信がまったくされていないのでDBに書き込まないようにする）
			[self alertOnlyOkWithTitle:@"お知らせ" Message:@"インターネット接続が不安定なため\nメール送信できませんでした"];
			return;
		}
	}

	// テンプレートのタイトルを取得する
	userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];
	NSString* templateTitle = [userDbMng getTemplateTitleWithID:TemplateId];
	[userDbMng closeDataBase];
	[userDbMng release];

	// 送信ユーザー数
	NSInteger successUsers = [arraySuccessUsers count];
	NSInteger errorUsers = [arrayFailedUsers count];
	
	// エラー情報をDBに追加
	userFmdbManager* userFmdbMng = [[userFmdbManager alloc] init];
	[userFmdbMng initDataBase];

	// 送信履歴をDBに追加
	[userFmdbMng insertWebMailErrorWithTitle:templateTitle SendCount:(successUsers + errorUsers)  ErrorCount:errorUsers];

	// ユーザー毎のエラー情報をDBに追加
	for ( NSDictionary* dic in  arrayFailedUsers )
	{
		USERID_INT userId = (USERID_INT)[(NSNumber*)[dic objectForKey:@"user_id"] integerValue];
		[userFmdbMng insertWebMailErrorCountWithUserID:userId Error:1];
	}
	[userFmdbMng release];

	// リロードする
	[userTableView reloadData];
	
	// 送信後のアラート
	[self alertOnlyOkWithTitle:@"送信完了" Message:@"メールを送信しました"];
}


#pragma mark AlertFunction
/**
 UIAlertViewのデリゲート
 */
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch ( [alertView tag] )
	{
	case ALERT_TAG_DELETE_HISTORY:
		// 閉じる
		[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
		break;

	case ALERT_TAG_COMFIRM_TEMPLATE:
		// テンプレートの確認アラート
		break;

	case ALERT_TAG_SEND_BROADCASTMAIL:
		// メール送信
		break;

	default:
		break;
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger section = 0, row = 0;
    [_templInfoList getSelectedInfo:&section RowNum:&row];
    TemplateInfo *templateInfo = [_templInfoList getTemplateInfoBySection:section RowNum:row];
    
    switch ( [alertView tag] ){
        case ALERT_TAG_SEND_BROADCASTMAIL:;
            if( buttonIndex == 0 ) return;
            NSMutableDictionary* dic = [self makeBroadcastMail];
            // 送信プレビューの表示
            [self PreviewSendMailWithMailData:dic TemplateId:[templateInfo tmplId]];
            break;
    }
}

/**
 OKのみ表示するアラート
 */
- (void) alertOnlyOkWithTitle:(NSString*) strTitle
					  Message:(NSString*) message
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:strTitle
													message:message
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert setTag:0];
	[alert show];
	[alert release];
}

/**
 OK,Cancelを表示するアラート
 */
- (void) alertOkCancelWithTitle:(NSString*) strTitle
						Message:(NSString*) message
							Tag:(NSInteger)tag
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:strTitle
													message:message
												   delegate:self
										  cancelButtonTitle:@"いいえ"
										  otherButtonTitles:@"はい", nil];
	[alert setTag:tag];
	[alert show];
	[alert release];
}

#pragma mark TableView_DataSource
/**
 numberOfSectionsInTableView
 セクション数の設定
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    switch( tableView.tag ){
            //  templateTableView
        case 0:
            return [self getTemplateTableSectionNum];
            //  userTableView
        case 1:
        default:
            return [self getUserTableSectionNum];
    }
}

/**
 tableView: numberOfRowsInSection:
 セクションに含まれるセル数を返す
 */
- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    switch( tableView.tag ){
            //  templateTableView
        case 0:
            return [self getTemplateTableCellNum:section];
            //  userTableView
        case 1:
        default:
            return [self getUserTableCellNum:section];
    }
}

/**
 tableView: titleForHeaderInSection:
 セクションのヘッダータイトルを返す
 */
- (NSString*) tableView:(UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
    switch( tableView.tag ){
            //  templateTableView
        case 0:
            return [_templInfoList getSectionTitle:section];;
            //  userTableView
        case 1:
        default:
            return [sectionTitles objectAtIndex:section];
//            return [[self userInfoList] getSectionTitle:section];
    }
}

/**
 tableView: cellForRowAtIndexPath:
 セルの内容を返す
 */
- (UITableViewCell*) tableView:(UITableView*) tableView
		 cellForRowAtIndexPath:(NSIndexPath*) indexPath
{
    UITableViewCell* cell;
    
    switch (tableView.tag){
        case 0:
            cell = [self createTemplateTableCell:tableView IndexPath:indexPath];
            break;
            
        case 1:
            cell = [self createUserTableCell:tableView IndexPath:indexPath];
            UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hUserListDoubleTap:)];
            doubleTapGesture.numberOfTapsRequired = 2;
            [cell addGestureRecognizer:doubleTapGesture];
            [doubleTapGesture release];
            break;
    }

	return cell;
}

- (UITableViewCell*) createTemplateTableCell:(UITableView*) tableView IndexPath:(NSIndexPath*) indexPath
{
    TemplateListTableViewCell* cell = (TemplateListTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"template_info_cell"];
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
	[self updateTemplateTableCell:cell IndexPath:indexPath];
    
    return cell;
}

/**
 セルの内容更新
 @param cell セル
 @param indexPath インデックス
 @return なし
 */
- (void) updateTemplateTableCell:(TemplateListTableViewCell*) cell IndexPath:(NSIndexPath*) indexPath
{
	// テンプレート情報
	TemplateInfo* info = [_templInfoList getTemplateInfoBySection:indexPath.section
														   RowNum:indexPath.row];
	// テンプレートのタイトルを設定
	cell.templTitle.text = [info strTemplateTitle];
	// テンプレートの更新日時を設定
	cell.templUpdateDate.text = [Common getDateStringByLocalTime:[info dateTemplateUpdate]];
	// テンプレート本文を設定
	cell.templPreview.text = [info strTemplateBody];
	// チェックマーク
	cell.accessoryType = [info selected] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (UITableViewCell*) createUserTableCell:(UITableView*) tableView IndexPath:(NSIndexPath*) indexPath
{
    static NSString *CellIndentifier = @"broadcast_mail_user_info_cell";
    SearchResultTableViewCell* cell = (SearchResultTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIndentifier];
    if ( cell == nil )
    {
        UIViewController* viewController = [[UIViewController alloc] initWithNibName:@"SearchResultTableViewCell" bundle:nil];
        cell = (SearchResultTableViewCell*)[viewController view];
        [viewController release];
        
        // UserTableViewCellの初期化
        [self tableView:tableView willDisplayCell:cell forRowAtIndexPath:0];
        [cell initialize];
        [cell setCallbackDelegate:self];
        
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

    [self updateUserTableCell:cell IndexPath:indexPath];
    
    return cell;
}

/**
 セルの内容更新
 @param cell セル
 @param indexPath インデックス
 @return なし
 */
- (void) updateUserTableCell:(SearchResultTableViewCell*) cell IndexPath:(NSIndexPath*) indexPath
{
    // 一斉送信ユーザー情報
    BroadcastMailUserInfo* mailUserInfo = [self getBroadcastMailUserInfoWithSection:indexPath.section
                                                                             RowNum:indexPath.row];
    
    userInfo* info = [mailUserInfo userInfo];
    
    // ユーザー名
    cell.userName.text = [info getUserName];
    // 登録ID
    [cell setRegistNumberWithIntValue:info.registNumber isNameSet:info.isSetUserName];
    // 一斉送信メールユーザー情報の設定
    [cell setMailUserInfo:mailUserInfo];
    
    //  メール受信拒否者テキスト制御
    [cell.blockMail setHidden:![mailUserInfo blockMail]];
    
    cell.userMailAddress.text = mailUserInfo.mailAddress;
    
    // 選択ボタンを使用可
    [cell setEnableSelect:YES];
    // 選択ボタンの状態を変更
    [cell setSelectedButton:[mailUserInfo selected]];
    
    [cell setNeedsDisplay];
}

/**
 iOS7よりTableViewCellの表示が変更になった為
 */
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if ( iOSVersion < 7.0 )
	{
        switch( tableView.tag ){
                //  templateTableView
            case 0:;
                break;
                //  userTableView
            case 1:;
                //SearchResultTableViewCell *userCell = (SearchResultTableViewCell*)cell;
                //userCell.inset = -44.0;
                break;
            default:;
        }
	}
}

#pragma mark TableView_Delegate
/**
 tableView: didSelectRowAtIndexPath:
 セルタップ時に呼び出される
 */
- (void) tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath*) indexPath
{
    switch( tableView.tag ){
        case 0:;
            UITableViewCell* templateTableCell = [tableView cellForRowAtIndexPath:indexPath];
            templateTableCell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            // テンプレート情報
            [_templInfoList UnselectedAll];
            [_templInfoList selecteInfo:indexPath.section RowNum:indexPath.row];
            TemplateInfo* info = [_templInfoList getTemplateInfoBySection:indexPath.section
                                                                   RowNum:indexPath.row];
            
            [self updatePreview:info];
            /**
             updatePreviewで_previewPicturesListが更新される
             */
            if( _previewPicturesList != nil ){
                lblAttachmentImgNum.text = [NSString stringWithFormat:@"添付画像の数：%ld", (long)_previewPicturesList.count ];
                [lblAttachmentImgNum setHidden:NO];
            }
            else{
                [lblAttachmentImgNum setHidden:YES];
            }
            [templateAndPreview setContentOffset:CGPointMake(preview.frame.origin.x, 0) animated:YES];
            [self enabledTemplateSelectBtn:YES];

            [self enabledSendBtn];
            break;
            
        case 1:
        default:;
            
            SearchResultTableViewCell* userTableCell = (SearchResultTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
            BroadcastMailUserInfo* mailUserInfo = [self getBroadcastMailUserInfoWithSection:indexPath.section
                                                                                     RowNum:indexPath.row];
            
            [userTableCell setSelectedButton:[mailUserInfo selected] ? NO : YES];
            [self checkSelectedAllBtn];
            break;
    }
    
}

#pragma mark PopUpViewContollerBaseDelegate

/**
 ポップアップのデリゲート
 */
- (void) OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    dummyView.hidden = YES;
    
	if ( popOverCtrlMailHist != nil )
	{
		[popOverCtrlMailHist release];
		popOverCtrlMailHist = nil;
	}
}

#pragma mark BroadcastMail_Method
/**
 代表画像リストの設定
 */
- (void) setHeadPictureList:(NSDictionary*) dic
{
	if ( _headPictureList != nil )
	{
		[_headPictureList release];
		_headPictureList = nil;
	}
	_headPictureList = [[NSMutableDictionary alloc] initWithDictionary:dic copyItems:YES];
}

/**
 メール一斉送信する
 */
- (NSMutableDictionary*) makeBroadcastMail
{
    NSInteger section, row;
    [_templInfoList getSelectedInfo:&section RowNum:&row];
    TemplateInfo *templateInfo = [_templInfoList getTemplateInfoBySection:section RowNum:row];
    
	// 送信データの設定
	NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
	NSString* title = [templateInfo strTemplateTitle];
	NSString* body = [templateInfo makeTemplateBody];
	NSArray* templatePictures = [templateInfo pictureUrls];

	// 送信画像情報の作成
	NSMutableArray* pictUrls = [[NSMutableArray alloc] init];
	for ( NSArray* pictInfo in templatePictures )
	{
		NSString* localPath = [pictInfo objectAtIndex:1];
		NSString* fileName = [localPath lastPathComponent];
		NSString* url = [NSString stringWithFormat:@"Documents/common/%@", fileName];
		[pictUrls addObject:url];
	}

	// ログイン情報
//2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ一斉メール送信スルー
#ifndef FOR_SALES
	NSString *nonce = [WebMailLogin getNonce];
	NSString *auth = nil;
	if ( !nonce )
	{
		@try {
			[WebMailLogin login:&nonce auth:&auth];
		}
		@catch (NSException *exception) {
			NSLog(@"%@", exception );
			nonce = @"";
		}
		@finally {
		}
	}
	[dic setObject:nonce forKey:@"nonce"];
#endif

	// テンプレートのタイトル
	if ( [title length] > 0 )
		[dic setObject:title forKey:@"title"];
	// テンプレートの本文
	if ( [body length] > 0 )
		[dic setObject:body forKey:@"body"];
	// テンプレート用画像URL
	if ( [pictUrls count] > 0 )
		[dic setObject:pictUrls forKey:@"picture_urls"];

    NSDictionary* replace = [self makeReplaceValue:[templateInfo tmplId]];

	// ユーザー情報の作成
	NSInteger sendCount = 0;
	NSMutableArray* users = [[NSMutableArray alloc] init];
	for ( NSMutableArray* row in _arrayBroadcastMailUser )
	{
		for ( BroadcastMailUserInfo* info in row )
		{
			if ( [info selected] == YES )
			{
				// 置き換え文字列の取得
				NSMutableDictionary* replaceValue = [[NSMutableDictionary alloc] init];

                [replaceValue setObject:[replace objectForKey:@"DATE"] forKey:@"DATE"];
                [replaceValue setObject:[replace objectForKey:@"FIELD1"] forKey:@"FIELD1"];
                [replaceValue setObject:[replace objectForKey:@"FIELD2"] forKey:@"FIELD2"];
                [replaceValue setObject:[replace objectForKey:@"FIELD3"] forKey:@"FIELD3"];

				// ユーザー情報
				NSMutableDictionary* userDic = [[NSMutableDictionary alloc] init];
				NSNumber* userId = [NSNumber numberWithInteger:[[info userInfo] userID]];
				NSString* strName = [NSString stringWithFormat:@"%@ %@", [[info userInfo] firstName], [[info userInfo] secondName]];
				[replaceValue setObject:strName forKey:@"NAME"];
				[userDic setObject:userId forKey:@"id"];
				[userDic setObject:replaceValue forKey:@"replace_values"];

				// ユーザーのルートに追加
				[users addObject:userDic];
				sendCount++;

				// 解放
				[userDic release];
				[replaceValue release];
			}
		}
	}

	// ユーザー情報の追加
	[dic setObject:users forKey:@"users"];
	
	return dic;
}

/**
    ユーザー名以外の置き換え文字を作る
 */
- (NSDictionary*) makeReplaceValue:(NSString*)templateId
{
    // DBオープン
	userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];

    // 置き換え文字列の取得
    NSMutableDictionary* replaceValue = [[NSMutableDictionary alloc] init];
    
    // 日付
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy年MM月dd日"];
    [replaceValue setObject:[df stringFromDate:[NSDate date]] forKey:@"DATE"];
    
    // 汎用フィールド
    NSString *gen1FieldId = nil, *gen2FieldId = nil, *gen3FieldId = nil;
    BOOL stat = [userDbMng getGenFieldIdByTemplateId:templateId
                                         Gen1FieldId:&gen1FieldId
                                         Gen2FieldId:&gen2FieldId
                                         Gen3FieldId:&gen3FieldId];
    if ( stat == YES )
    {
        if ( gen1FieldId != nil )
        {
            // Field1
            NSString* fieldId = [userDbMng getGenFieldDataByID:gen1FieldId];
            if ( fieldId != nil && [fieldId length] > 0 )
                [replaceValue setObject:fieldId forKey:@"FIELD1"];
            else
                [replaceValue setObject:@"" forKey:@"FIELD1"];
        }
        else
        {
            // Field1 - 空白で置換されるように空白を入れておく
            [replaceValue setObject:@"" forKey:@"FIELD1"];
        }
        if ( gen2FieldId != nil )
        {
            // Field2
            NSString* fieldId = [userDbMng getGenFieldDataByID:gen2FieldId];
            if ( fieldId != nil && [fieldId length] > 0 )
                [replaceValue setObject:fieldId forKey:@"FIELD2"];
            else
                [replaceValue setObject:@"" forKey:@"FIELD2"];
        }
        else
        {
            // Field2 - 空白で置換されるように空白を入れておく
            [replaceValue setObject:@"" forKey:@"FIELD2"];
        }
        if ( gen3FieldId != nil )
        {
            // Field3
            NSString* fieldId = [userDbMng getGenFieldDataByID:gen3FieldId];
            if ( fieldId != nil && [fieldId length] > 0 )
                [replaceValue setObject:fieldId forKey:@"FIELD3"];
            else
                [replaceValue setObject:@"" forKey:@"FIELD3"];
        }
        else
        {
            // Field3 - 空白で置換されるように空白を入れておく
            [replaceValue setObject:@"" forKey:@"FIELD3"];
        }
    }
    
    [df release];
    
    // DBクローズ
	[userDbMng closeDataBase];
	[userDbMng release];
    
    return replaceValue;
}

/**
 送信メールのプレビュー
 */
- (BOOL) PreviewSendMailWithMailData:(NSDictionary*)dic TemplateId:(NSString*)tmplId
{
	// 送信プレビューの作成
	BroadcastMailSendPopup* mailSend = [[BroadcastMailSendPopup alloc] initWithMailData:dic TemplateId:tmplId PopupId:0x1000 Callback:self];
	if ( mailSend == nil ) return NO;
		
	// 送信プレビューの表示
	if ( popOverCtrlMailHist != nil )
	{
		[popOverCtrlMailHist release];
		popOverCtrlMailHist = nil;
	}
	popOverCtrlMailHist = [[UIPopoverController alloc] initWithContentViewController:mailSend];
    popOverCtrlMailHist.delegate = mailSend;
	mailSend.popoverController = popOverCtrlMailHist;
	[popOverCtrlMailHist presentPopoverFromRect:btnBroadcastMail.bounds
										 inView:btnBroadcastMail
					   permittedArrowDirections:UIPopoverArrowDirectionAny
									   animated:YES];
    [popOverCtrlMailHist setPopoverContentSize:CGSizeMake(580.0f, 640.0f)];
	[mailSend release];
    
    //画面外をタップしてもポップアップが閉じないようにする処理
    dummyView.hidden = NO;
	NSMutableArray *viewCof = [[NSMutableArray alloc]init];
	[viewCof addObject:dummyView];
	popOverCtrlMailHist.passthroughViews = viewCof;
	[viewCof release];

	return YES;
}

/*
 
 */
- (void) SendButtonCallBack:(NSMutableDictionary*)dic
{
    NSInteger section = 0, row = 0;
    [_templInfoList getSelectedInfo:&section RowNum:&row];
    TemplateInfo *templateInfo = [_templInfoList getTemplateInfoBySection:section RowNum:row];
    
	BroadcastMail* mail = [[BroadcastMail alloc] initWithDelegate:self];
	[mail sendBroadcastMail:dic TemplateId:[templateInfo tmplId]];
	[mail release];
}

/**
 getTotalUserTableCellCount
 CELLの総合計
 */
- (NSInteger) getTotalUserTableCellCount
{
	NSInteger nCellCount = 0;
	NSInteger nSection = [self getUserTableSectionNum];
	for( NSInteger i = 0; i < nSection; i++ )
	{
		nCellCount += [self getUserTableCellNum:i];
	}
	return nCellCount;
}

/**
 createBroadcastMailUserInfo
 送信ユーザー情報のデータを作成する
 */
- (BOOL) createBroadcastMailUserInfo:(BOOL) insertBlockMailUser
{
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    
    NSDictionary* blockMailUserList = [manager getWebMailBlockUserList];
    [manager release];
    
    NSMutableArray* mailUserList = [[NSMutableArray alloc] init];
    NSMutableArray *currentActive = [[NSMutableArray alloc] init];  // 有効なセクション
    NSInteger actSectionNum = 0;
    
    _selectedAll = NO;
    
    if (sectionTitles) [sectionTitles release];
    sectionTitles = [[NSMutableArray alloc] init];
    
	NSInteger nSection = [[self userInfoList] getSectionNum];
	for ( NSInteger i = 0; i < nSection; i++ )
	{
		NSMutableArray* _arraySection = [[[NSMutableArray alloc] init] autorelease];
		NSInteger nCell = [[self userInfoList] getUserNum:i];
		for ( NSInteger j = 0; j < nCell; j++ )
		{
			// ユーザー情報の取得
			userInfo* userInfo = [[self userInfoList] getUserInfoBySection:i rowNum:j];
            
			// メールアドレスを確認する
			userDbManager* usrDbMng = [[userDbManager alloc] init];
			mstUser *user = [usrDbMng getMstUserByID:[userInfo userID]];
			[usrDbMng release];
            
            if( [user email1] == nil || [[user email1] length] == 0 ){
                continue;
            }
            // ショップアカウント且つ全店共通ユーザの場合、メール送信出来ないので飛ばす
            if ([[ShopManager defaultManager] isAccountShop] && user.shopID==0) {
                continue;
            }
            
            //  受信拒否
            BOOL isBlockMail = NO;
            NSNumber* userID = [NSNumber numberWithInt:[userInfo userID]];
            if( [blockMailUserList objectForKey:[userID stringValue]] != nil ){
                if( insertBlockMailUser ){
                    isBlockMail = YES;
                }
                else{
                    continue;
                }
            }
            
            //  前回の選択状態を取得
            BOOL isSelected = NO;
            NSInteger active = ([activeSections count]>0)? [[activeSections objectAtIndex:i] intValue] : -1;
            if (active!=-1) {
                isSelected = [self chkOldStatus:userInfo.userID SearchSection:active];
            }
            
            if( isSelected == NO )  _selectedAll = YES;
            
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[_arraySection count]
                                                        inSection:[mailUserList count] ];
            
			// 作成
			BroadcastMailUserInfo* info = [[[BroadcastMailUserInfo alloc] init] autorelease];
            
			// データの設定
			[info setUserInfo:userInfo];
			[info setSelected:isSelected];
            [info setBlockMail:isBlockMail];
            [info setMailAddress:[user email1]];
            [info setIndexPath:indexPath];
			
			// ユーザー追加
			[_arraySection addObject: info];
		}
        // セクションのユーザ数が0の場合は飛ばす
        if ([_arraySection count]==0) {
            [currentActive addObject:[NSNumber numberWithInteger:-1]];
            continue;
        } else {
            [currentActive addObject:[NSNumber numberWithInteger:actSectionNum++]];
        }
		// セクション追加
		[mailUserList addObject:_arraySection];
        // 有効なセクションタイトルを追加
        [sectionTitles addObject:[[self userInfoList] getSectionTitle:i]];
	}
    
    if( _arrayBroadcastMailUser != nil ){
        [_arrayBroadcastMailUser removeAllObjects];
        [_arrayBroadcastMailUser release];
    }
    _arrayBroadcastMailUser = mailUserList;
    
    if (activeSections != nil) {
        [activeSections removeAllObjects];
        [activeSections release];
    }
    activeSections = currentActive;

    // ボタン名の変更
    if ( _selectedAll )     [btnSelectedAll setTitle:@"全件選択" forState:UIControlStateNormal];
    else                    [btnSelectedAll setTitle:@"全選択解除" forState:UIControlStateNormal];
    
	return YES;
}

/**
 * 受信拒否者の表示・非表示を切り替えた際に、切り替え前の一斉送信メールの選択、解除状態を返す
 */
- (BOOL)chkOldStatus:(NSInteger)userID SearchSection:(NSInteger)section
{
    BOOL isSelected = NO;

    NSArray* oldListInfo = [_arrayBroadcastMailUser objectAtIndex:section];
    for (BroadcastMailUserInfo *info in oldListInfo) {
        if (info.userInfo.userID == userID) {
            isSelected = info.selected;
            break;
        }
    }

    return isSelected;
}

/**
 getBroadcastMailUserInfoWithSection
 送信ユーザー情報を取得する
 */
- (BroadcastMailUserInfo*) getBroadcastMailUserInfoWithSection:(NSInteger) section RowNum:(NSInteger) rowNum
{
	NSMutableArray* _arraySection = (NSMutableArray*)[_arrayBroadcastMailUser objectAtIndex:section];
	if ( _arraySection == nil ) return nil;
	BroadcastMailUserInfo* mailUserInfo = (BroadcastMailUserInfo*)[_arraySection objectAtIndex:rowNum];
	return mailUserInfo;
}

/**
 メールのステータスを確認する
 */
- (BOOL) getMailStatus
{
	if ( mailStatuses == nil )
	{
		// メールステータス
		mailStatuses = [[GetWebMailUserStatuses alloc] initWithDelegate:self];
	}
	// ステータスの確認
	[mailStatuses getStatuses];
	return YES;
}

/**
 ユーザーのメールアドレスが空ならユーザー情報から削除する
 */
- (void) removeEmptyEmailUser
{
	NSInteger section = [_userInfoList getSectionNum];
	for ( NSInteger i = 0; i < section; i++ )
	{
		NSMutableDictionary* arrayUsers = [[[NSMutableDictionary alloc] init] autorelease];
		NSInteger row = [_userInfoList getUserNum:i];
		for ( NSInteger j = 0; j < row; j++ )
		{
			// ユーザー情報取得
			userInfo* info = [_userInfoList getUserInfoBySection:i rowNum:j];

			// メールアドレスを確認する
			userDbManager* usrDbMng = [[userDbManager alloc] init];
			mstUser *user = [usrDbMng getMstUserByID:[info userID]];
			[usrDbMng release];

			// メールアドレスは空な人を削除リストに追加しておく
			if ( [user email1] == nil || [[user email1] length] == 0 )
			{
				[arrayUsers setObject:info forKey:[[NSNumber numberWithInteger:j] description]];
			}
		}
		// dictionary
		[_arrayRemoveUserList setObject:arrayUsers forKey:[[NSNumber numberWithInteger:i] description]];
	}
}

/*
 
 */
-(UIView*)createDummyView
{
    UIView* view;
    view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor clearColor];
    view.hidden = YES;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window == nil) {
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    }
    [window.rootViewController.view addSubview:view];
    
    return view;
}

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
 送信ボタンを有効するか無効にするかの制御を行う
 */
-(void) enabledSendBtn
{
    //  テンプレートが選択されているかのチェック
    NSInteger section = 0, row = 0;
	if ( ![_templInfoList getSelectedInfo:&section RowNum:&row] )
	{
        [btnBroadcastMail setAlpha:BTN_ALPHA_INVALID];
        [btnBroadcastMail setEnabled:NO];
		return;
	}
    
	// ユーザー選択状態の確認（１名でも選択状態なら一斉送信ボタン表示）
	for ( NSMutableArray* row in _arrayBroadcastMailUser ){
		for ( BroadcastMailUserInfo* info in row ){
			if ( [info selected] == YES ){
                //  一斉送信ボタン表示
                [btnBroadcastMail setAlpha:1.0f];
                [btnBroadcastMail setEnabled:YES];
                return;
			}
		}
	}
	
    [btnBroadcastMail setAlpha:BTN_ALPHA_INVALID];
    [btnBroadcastMail setEnabled:NO];
}

/**
 テンプレート再選択ボタンとテンプレート編集ボタンの有効、無効を切り替える
 */
-(void) enabledTemplateSelectBtn:(bool) enabled
{
    if(enabled){
        [btnTemplateSelect setAlpha:1.0f];
        [btnTemplateSelect setEnabled:YES];
        
        [btnTemplateEdit setAlpha:1.0f];
        [btnTemplateEdit setEnabled:YES];
    }else{
        [btnTemplateSelect setAlpha:BTN_ALPHA_INVALID];
        [btnTemplateSelect setEnabled:NO];
        
        [btnTemplateEdit setAlpha:BTN_ALPHA_INVALID];
        [btnTemplateEdit setEnabled:NO];
    }
}

/**
 全選択ボタンの確認
 @param     全て選択されている場合YES
 */
-(void) checkSelectedAllBtn
{
    // 送信ユーザー情報の変更
	NSInteger nSection = [self getUserTableSectionNum];
	for ( NSInteger i = 0; i < nSection; i++ )
	{
		NSInteger nCell = [self getUserTableCellNum:i];
		for ( NSInteger j = 0; j < nCell; j++ )
		{
			BroadcastMailUserInfo* info = [self getBroadcastMailUserInfoWithSection:i RowNum:j];
			if ( info == nil ) continue;
            if( info.selected == NO ){
                [btnSelectedAll setTitle:@"全件選択" forState:UIControlStateNormal];
                _selectedAll = YES;
                return ;
            }
		}
	}
    
    [btnSelectedAll setTitle:@"全選択解除" forState:UIControlStateNormal];
    _selectedAll = NO;
}

/**
 
 */
-(void) touchSelectedButtonDelegate
{
    [self enabledSendBtn];
    [self checkSelectedAllBtn];
}

-(BOOL) touchUserInfoSelectedButton:(BroadcastMailUserInfo*) mailUserInfo;
{
    SearchResultTableViewCell* userTableCell = (SearchResultTableViewCell*)[userTableView cellForRowAtIndexPath:mailUserInfo.indexPath];
    [userTableCell setSelectedButton:[mailUserInfo selected] ? NO : YES];
    return [mailUserInfo selected];
}

-(NSInteger) getUserTableSectionNum
{
    return [_arrayBroadcastMailUser count];
}

-(NSInteger) getUserTableCellNum:(NSInteger) section;
{
    return [[_arrayBroadcastMailUser objectAtIndex:section] count];
}

-(NSInteger) getTemplateTableSectionNum
{
	return [_templInfoList getSectionCounts];
}

-(NSInteger) getTemplateTableCellNum:(NSInteger) section;
{
	return [_templInfoList getTemplateInfoCountsWithSection:section];
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
        dummyView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
        
        x = btnSelectedAll.frame.origin.x;
        y = 391;
        w = btnSelectedAll.frame.size.width;
        h = btnSelectedAll.frame.size.height;
        btnSelectedAll.frame = CGRectMake(x, y, w, h);
        
        x = btnBlockMailUser.frame.origin.x;
        y = btnSelectedAll.frame.origin.y;
        w = btnBlockMailUser.frame.size.width;
        h = btnBlockMailUser.frame.size.height;
        btnBlockMailUser.frame = CGRectMake(x, y, w, h);
        
        x = userList.frame.origin.x;
        y = 439;
        w = rect.size.width - 40;
        h = 520 + verHeightOfs;
        userList.frame = CGRectMake(x, y, w, h);
        
        x = 20;
        y = 18;
        w = viewCreateAndCategory.frame.size.width;
        h = viewCreateAndCategory.frame.size.height;
        viewCreateAndCategory.frame = CGRectMake(x, y, w, h);
        
        y = 68;
        w = userList.frame.size.width;
        h = 315;
        templateList.frame = CGRectMake(x, y, w, h);
        
        x = rect.size.width - 20 - viewEditAndSelect.frame.size.width;
        y = btnSelectedAll.frame.origin.y;
        w = viewEditAndSelect.frame.size.width;
        h = viewEditAndSelect.frame.size.height;
        viewEditAndSelect.frame = CGRectMake(x, y, w, h);
        
        x = previewPictures.frame.origin.x;
        y = previewPictures.frame.origin.y;
        w = templateList.frame.size.width;
        h = previewPictures.frame.size.height;
        previewPictures.frame = CGRectMake(x, y, w, h);
    }
    else{
        if (rect.size.width < rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        dummyView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
        
        x = btnSelectedAll.frame.origin.x;
        y = 117 - 48;
        w = btnSelectedAll.frame.size.width;
        h = btnSelectedAll.frame.size.height;
        btnSelectedAll.frame = CGRectMake(x, y, w, h);
        
        x = btnBlockMailUser.frame.origin.x;
        y = btnSelectedAll.frame.origin.y;
        w = btnBlockMailUser.frame.size.width;
        h = btnBlockMailUser.frame.size.height;
        btnBlockMailUser.frame = CGRectMake(x, y, w, h);
        
        x = userList.frame.origin.x;
        y = 117;
        w = rect.size.width / 2 - 30;
        h = rect.size.height - (63 + y) + verHeightOfs;
        userList.frame = CGRectMake(x, y, w, h);
        
        x = userList.frame.origin.x + userList.frame.size.width + 20;
        y = btnSelectedAll.frame.origin.y;
        w = viewCreateAndCategory.frame.size.width;
        h = viewCreateAndCategory.frame.size.height;
        viewCreateAndCategory.frame = CGRectMake(x, y, w, h);
        
        y = userList.frame.origin.y;
        w = rect.size.width - x - 20;
        h = userList.frame.size.height;
        templateList.frame = CGRectMake(x, y, w, h);
        
        y = templateList.frame.origin.y + templateList.frame.size.height + 8;
        w = viewEditAndSelect.frame.size.width;
        h = viewEditAndSelect.frame.size.height;
        viewEditAndSelect.frame = CGRectMake(x, y, w, h);
        
        x = previewPictures.frame.origin.x;
        y = previewPictures.frame.origin.y;
        w = templateList.frame.size.width;
        h = previewPictures.frame.size.height;
        previewPictures.frame = CGRectMake(x, y, w, h);
    }
    
    [self previewPicturesLayout];
    
    if( [btnTemplateSelect isEnabled] ){
        [templateAndPreview setContentOffset:CGPointMake(preview.frame.origin.x, 0) animated:NO];
    }
    else{
        [templateAndPreview setContentOffset:CGPointMake(0, 0) animated:NO];
    }
    
    w = templateList.frame.size.width * 2;
    h = templateAndPreview.frame.size.height;
    templateAndPreview.contentSize = CGSizeMake(w, h);
    
    
}

/**
 */
-(void) setTemplateAllNum
{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
	NSMutableArray* _arrayTemplateInfo = nil;
    
    // 全検索する
    _arrayTemplateInfo = [usrDbMng loadTemplateDatabase];
	[usrDbMng release];
    
    lblTemplateAllNum.text = [NSString stringWithFormat:@"全登録件数%ld件", (long)[_arrayTemplateInfo count]];
}

#pragma mark BroadcastMail_Method_Preview

/**
 プレビューの内容を選択されたテンプレートにあわせた内容に更新する
 */
-(void) updatePreview:(TemplateInfo*)templateInfo
{
    if( templateInfo == nil )
    {
        return;
    }
    
    //  メール件名
    previewSubject.text = [templateInfo strTemplateTitle];

    //  メール本文
    NSString* templateBody = [templateInfo makeTemplateBody];
    
    // 名前
    NSString* replaceName = @"顧客名";
    Boolean isBreak = false;
    for ( NSMutableArray* row in _arrayBroadcastMailUser ){
        for ( BroadcastMailUserInfo* info in row ){
            isBreak = true;
            replaceName = [[info userInfo] getUserName];
            break;
        }
        if( isBreak ){
            break;
        }
    }
    
    // 文字列を置き換える
    templateBody = [templateBody stringByReplacingOccurrencesOfString:@"{__NAME__}" withString:replaceName];

    previewMailBody.text = templateBody;
    
    //  メール添付画像
    NSArray* templatePictures = [templateInfo pictureUrls];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
    NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
    OKDImageFileManager* imgFileMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
    NSInteger idx = 0;
    
    //  サブビューを消去
    for( UIView* subView in [previewPictures subviews]){
         [subView removeFromSuperview];
    }
    [_previewPicturesList removeAllObjects];

	//  送信画像情報の作成
	for ( NSArray* pictInfo in templatePictures )
	{
		NSString* strPictId = [pictInfo objectAtIndex:0];
		NSString* localPath = [pictInfo objectAtIndex:1];
		NSString* fileName = [localPath lastPathComponent];
        
        // サムネイルViewの作成
		OKDThumbnailItemView *thumbnailView = [OKDThumbnailItemView alloc];
		[[thumbnailView initWithFrame: CGRectMake(100.0f, 50.0f, ITEM_WITH, ITEM_HEIGHT)] autorelease];
		[thumbnailView setFileName:fileName];
        
		// Document以下のファイル名に変換
		NSString* docFileName = [[NSString alloc] initWithString:[fileName lastPathComponent]];
		docFileName = [docFileName substringToIndex:[docFileName length] - 4];
		[thumbnailView setTitle:docFileName];
        
        thumbnailView.delegate = nil;
        thumbnailView.tag = idx;
        [thumbnailView setImgId:strPictId];
        [thumbnailView setUpdateTime:0];
        [thumbnailView writeToTemplateThumbnail:imgFileMng];
        
        [_previewPicturesList addObject:thumbnailView];
        [previewPictures addSubview:thumbnailView];

        idx++;
	}
    
    [imgFileMng release];
    
    [self previewPicturesLayout];
    
    //  プレビューの表示位置を先頭にする
    [preview setContentOffset:CGPointMake(0, 0) animated:NO];
}

/**
 画像のレイアウト
 */
-(void) previewPicturesLayout
{
    if( [_previewPicturesList count] <= 0 )     return;
    
    int picturesAreaW = previewPictures.frame.size.width - 40;
    int xNum = picturesAreaW / (ITEM_WITH + 20);
    if( xNum <= 0)  xNum = 1;       //  0割回避
    
    CGFloat w = (picturesAreaW / xNum);
    CGFloat h = ITEM_HEIGHT + 10;
    int x = 20 + (w - ITEM_WITH) / 2;
    
    for( OKDThumbnailItemView* view in _previewPicturesList ){
        NSInteger i = view.tag;
        CGFloat posX = x + w * (i % xNum);
        CGFloat posY = h * (i / xNum);
        [view setFrame:CGRectMake( posX, posY, ITEM_WITH, ITEM_HEIGHT)];
    }
    
    w = previewPictures.frame.size.width;
    h = h + (h * ( ([_previewPicturesList count] - 1) / xNum));
    previewPictures.contentSize = CGSizeMake(w, h);
}

#pragma mark TemplateCategory_Method
/**
 initCategoryData
 */
- (void) initCategoryData
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	_strSelectCategory = [defaults stringForKey:CATEGORY_SEARCH_SAVE_KEY];
}

/**
 OnClickedCategoryEditor
 */
- (void) OnClickedItemEditor:(id)sender
					   Event:(NSInteger)event
					   Index:(NSInteger)cellIndex
						Mode:(NSInteger)mode

{
	EditorPopup* editor = (EditorPopup*)sender;
    
	// ポップオーバーを閉じる
	if ( _popOverCtrlCategory != nil )
		[_popOverCtrlCategory dismissPopoverAnimated:YES];
	
	switch ( event )
	{
        case CLICKED_SELECT:
		{
			// 選択なし
			if ( cellIndex == -1 )
			{
				[templateTableView reloadData];
				break;
			}
            
            // カテゴリーをロードする
            [self loadCategoryName];
            
			// 選択されたカテゴリーを設定しておく
			_strSelectCategory = [editor getCellNameFromIndex:cellIndex];
            
			// 絞り込み検索
			[self refiningTemplateDatabaseWithCategory:_strSelectCategory];
			
			// テーブルビューの再描画
			[templateTableView reloadData];

            [self OnTemplateSelect:btnTemplateSelect];
		}
            break;
            
        default:
            break;
	}
}

/**
 カテゴリーでテンプレートを絞り込みする
 */
- (BOOL) refiningTemplateDatabaseWithCategory:(NSString*)strCategory
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	NSMutableArray* _arrayTemplateInfo = nil;
	if ( strCategory == nil || [strCategory isEqualToString:@"なし"] == YES )
	{
		// 全検索する
        // 2016/5/10 TMS テンプレートの並び順をタイトル順にする
		_arrayTemplateInfo = [usrDbMng loadTemplateDatabaseOrderBy];
	}
	else
	{
		// DBから絞り込み検索で取得する
        // 2016/5/10 TMS テンプレートの並び順をタイトル順にする
        _arrayTemplateInfo = [usrDbMng refiningTemplateDatabaseWithCategoryOrderBy:strCategory];
	}
	[usrDbMng release];
	
	// 選択されていたテンプレートを取得しておく
	NSInteger section = 0, row = 0;
	BOOL bSelected = [_templInfoList getSelectedInfo:&section RowNum:&row];
	
	// テンプレートのリストに設定する
	if ( [[_templInfoList dicTemplateInfo] count] > 0 )
	{
		// 削除しておく
		[_templInfoList removeAllObjects];
	}
	[_templInfoList setTemplateList:_arrayTemplateInfo];
	
	// 選択されていたテンプレートを再度選択しておく
	if ( bSelected == YES )
	{
		[_templInfoList selecteInfo:section RowNum:row];
	}
    
    lblSelectedCategoryName.text = strCategory;
    
    NSInteger templateNum = 0;
    NSInteger templateCategoryNum = [_templInfoList getSectionCounts];
    for( int i = 0; i < templateCategoryNum; i++ ){
        templateNum += [_templInfoList getTemplateInfoCountsWithSection:i];
    }
    lblSelectedCategoryNum.text = [NSString stringWithFormat:@"%ld件表示中", (long)templateNum];
    
	return YES;
}

/**
 テンプレートの作成が終了した際に呼び出される
 */
- (void) finishedTemplateCreatorView:(NSString*)categoryName
                          TemplateId:(NSString*)templateId
{
    NSString *categoryNameNasi = @"なし";
    
	// カテゴリーをロードする
	[self loadCategoryName];
	// ロードする
    if( ![_strSelectCategory isEqualToString:categoryNameNasi]
       && categoryName != nil
       && ![_strSelectCategory isEqualToString:categoryName] ){
        if( [categoryName length] == 0 )    categoryName = categoryNameNasi;
        _strSelectCategory = categoryName;
    }
    [self refiningTemplateDatabaseWithCategory:_strSelectCategory];
    
	// テーブルビューのリロード
	[templateTableView reloadData];

    //  indexPathを取得する
    NSIndexPath* indexPath = nil;
    if(templateId != nil)
    {
        //  選択されているカテゴリの番号を探す
        NSInteger nasiSection;    //  なし　のセクション番号を保存しておく
        NSInteger section = [self getTemplateTableSectionNum] - 1;
        for( ; section >= 0; section-- )
        {
            TemplateInfo* info = [_templInfoList getTemplateInfoBySection:section
                                                                   RowNum:0];
            if( [info categoryName] == nil ){
                nasiSection = section;
                if( [categoryName isEqualToString:categoryNameNasi] ){
                    break;
                }
            }
            if([categoryName isEqualToString:[info categoryName]])    break;
        }
        if( section < 0 )   section = nasiSection;      //  セクションが見つからないのはカテゴリが消去された可能性があるのでカテゴリ　なし　から探す
        //  作成・編集されたTemplateInfoの番号を探す
        NSInteger row = [self getTemplateTableCellNum:section] - 1;
        for( ; row >= 0; row-- )
        {
            TemplateInfo* info = [_templInfoList getTemplateInfoBySection:section
                                                                   RowNum:row];
            if([templateId isEqualToString:[info tmplId]])  break;
        }
        indexPath = [NSIndexPath indexPathForRow:row
                                       inSection:section];
    }
    else
    {
        indexPath = _oldIndexPath;
    }
    
    if( indexPath != nil )
    {
        // 再選択
        [templateTableView selectRowAtIndexPath:indexPath
                                       animated:NO              //  プレビューに切り替わるアニメーションが入るため、選択した項目への移動アニメーションはなし
                                 scrollPosition:UITableViewScrollPositionMiddle];
        
        // テンプレート情報
        [_templInfoList UnselectedAll];
        [_templInfoList selecteInfo:indexPath.section RowNum:indexPath.row];
        TemplateInfo* templateInfo = [_templInfoList getTemplateInfoBySection:indexPath.section
                                                                       RowNum:indexPath.row];
        
        [self updatePreview:templateInfo];
        if( _previewPicturesList != nil ){
            lblAttachmentImgNum.text = [NSString stringWithFormat:@"添付画像の数：%ld", (long)_previewPicturesList.count ];
            [lblAttachmentImgNum setHidden:NO];
        }
        else{
            [lblAttachmentImgNum setHidden:YES];
        }
        
        [templateAndPreview setContentOffset:CGPointMake(preview.frame.origin.x, 0) animated:YES];
        [self enabledTemplateSelectBtn:YES];
        
        [self enabledSendBtn];
    }
    [self setTemplateAllNum];
}

/**
 カテゴリー名を取得する
 */
- (void) loadCategoryName
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	if ( [_arrayCategoryStrings count] > 0 )
	{
		// 何かしら文字列が追加されていた場合は一旦破棄する
		[_arrayCategoryStrings removeAllObjects];
	}
	[usrDbMng loadCategoryName:&_arrayCategoryStrings];
	[usrDbMng release];
}

/**
 createAlertViewForNoSelect
 非選択の場合のアラートを表示する
 */
- (UISpecialAlertView*) createAlertViewForNoSelect
{
	return [[UISpecialAlertView alloc] initWithTitle:@"選択"
											 message:@"選択されていません"
											delegate:self
								   cancelButtonTitle:@"取消"
								   otherButtonTitles:nil, nil];
}

#pragma mark BroadcastMail_Handler
/**
 OnReturnUserInfoList
 */
- (IBAction) OnReturnUserInfoList
{
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
 OnBroadcastMail
 */
- (IBAction) OnBroadcastMail:(id)sender
{
#if 1
    // ユーザー選択状態の確認（１名でも選択状態なら一斉送信ボタン表示）
	for ( NSMutableArray* row in _arrayBroadcastMailUser ){
		for ( BroadcastMailUserInfo* info in row ){
			if ( [info selected] == YES && [info blockMail] == YES ){
                //  送信リストに受信拒否者が含まれている。
                [self alertOkCancelWithTitle:@"一斉送信メール"
                                     Message:@"メール送信対象に「受信拒否設定」のお客様が含まれています。\n送信しますか？"
                                         Tag:ALERT_TAG_SEND_BROADCASTMAIL];
                return;
			}
		}
	}
    
	NSMutableDictionary* dic = [self makeBroadcastMail];

    TemplateInfo *templateInfo;
    NSInteger section = 0, row = 0;
    if( [_templInfoList getSelectedInfo:&section RowNum:&row] ){
        templateInfo = [_templInfoList getTemplateInfoBySection:section RowNum:row];
    }
    
    // 送信プレビューの表示
	[self PreviewSendMailWithMailData:dic TemplateId:[templateInfo tmplId]];

#else
//	[self alertOkCancelWithTitle:@"一斉送信メール" Message:@"メールを送信しますか？" Tag:ALERT_TAG_SEND_BROADCASTMAIL];
#endif
}

/**
 OnTemplateManager
 */
- (IBAction) OnTemplateManager:(id)sender
{
	// 確保
	TemplateManagerViewController* controller = [TemplateManagerViewController alloc];
	[controller initWithDelegate:self];
	
	// popup表示
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC showPopupWindow:controller];
	
	// 遷移先の設定
	_windowView = WIN_VIEW_TEMPLATE_MANAGE;
	
	// 後片付け
	[controller release];
}

/**
 OnMailHistory
 */
- (IBAction) OnMailHistory:(id)sender
{
	if ( popOverCtrlMailHist != nil )
	{
		[popOverCtrlMailHist release];
		popOverCtrlMailHist = nil;
	}

	SendMailHistoryPopup* sendMailHist = [[SendMailHistoryPopup alloc] initWithMailHistId:0
																				 delegate:self
																		popOverController:nil];
	if ( sendMailHist != nil )
	{
		popOverCtrlMailHist = [[UIPopoverController alloc] initWithContentViewController:sendMailHist];
		[sendMailHist setPopOverController: popOverCtrlMailHist];
		[popOverCtrlMailHist presentPopoverFromRect:btnMailHistory.bounds
											 inView:btnMailHistory
						   permittedArrowDirections:UIPopoverArrowDirectionAny
										   animated:YES];
        [popOverCtrlMailHist setPopoverContentSize:CGSizeMake(365.0f, 420.0f)];
	}
	[sendMailHist release];
}

/**
 OnSelectedAll
 */
- (IBAction) OnSelectedAll:(id)sender
{
    // 選択状態の更新を実施
    [self createBroadcastMailUserInfo:_showBlockMailUser];
    // 送信ユーザー情報の変更
	NSInteger nSection = [self getUserTableSectionNum];
	for ( NSInteger i = 0; i < nSection; i++ )
	{
		NSInteger nCell = [self getUserTableCellNum:i];
		for ( NSInteger j = 0; j < nCell; j++ )
		{
			BroadcastMailUserInfo* info = [self getBroadcastMailUserInfoWithSection:i RowNum:j];
			if ( info == nil ) continue;
            
            [info setSelected:_selectedAll];
		}
	}
	[self checkSelectedAllBtn];
    
	// 再描画
	[userTableView reloadData];
}

/**
    受信拒否者表示ボタン
 */
-(IBAction) OnBlockMailUser:(id)sender
{
	// ボタン名の変更
	_showBlockMailUser = (_showBlockMailUser == YES) ? NO : YES;
	if ( _showBlockMailUser == YES ){
		[btnBlockMailUser setTitle:@"受信拒否者非表示" forState:UIControlStateNormal];
    }
	else{
		[btnBlockMailUser setTitle:@"受信拒否者表示" forState:UIControlStateNormal];
    }
    
    // ユーザー情報の作成
    [self createBroadcastMailUserInfo:_showBlockMailUser];

    // tableViewの再読み込み
    [userTableView reloadSectionIndexTitles];
    [userTableView reloadData];
}

-(IBAction) OnTemplateSelect:(id)sender
{
    [templateAndPreview setContentOffset:CGPointMake(0, 0) animated:YES];
    [self enabledTemplateSelectBtn:NO];
    [_templInfoList UnselectedAll];
    [self enabledSendBtn];
    [lblAttachmentImgNum setHidden:YES];

}

/**
 新規作成ボタンアクション
 */
- (IBAction) OnTemplateCreator:(id)sender
{
    // 確保
	TemplateCreatorViewController* controller = [TemplateCreatorViewController alloc];
	[controller initWithTemplateInfo:nil Delegate:self];
	
	// popup表示
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC showPopupWindow:controller];
	
	// 遷移先の設定
	_windowView = WIN_VIEW_TEMPLATE_CREATOR;
	
	// 後片付け
	[controller release];
}

/**
 カテゴリ選択ボタンアクション
 */
- (IBAction) OnTemplateCategory:(id)sender
{
	if ( _popOverCtrlCategory != nil )
	{
		[_popOverCtrlCategory release];
		_popOverCtrlCategory = nil;
	}
	
	// ポップオーバーの表示
	EditorPopup* editorPopup = [[EditorPopup alloc] initWithCategory:_arrayCategoryStrings
															   title:@"カテゴリー選択"
														selectString:_strSelectCategory
															delegate:self
															 popOver:nil];
	if ( editorPopup != nil )
	{
		_popOverCtrlCategory = [[UIPopoverController alloc] initWithContentViewController:editorPopup];
		[editorPopup setPopOverController: _popOverCtrlCategory];
		[_popOverCtrlCategory presentPopoverFromRect:btnTemplateCategory.bounds
                                             inView:btnTemplateCategory
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                           animated:YES];
        [_popOverCtrlCategory setPopoverContentSize:CGSizeMake(420.0f, 513.0f)];
        [editorPopup enabledEditBtn:NO];
        [editorPopup release];
	}
}

/**
 テンプレート編集ボタンアクション
 */
- (IBAction) OnTemplateEditor:(id)sender
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [templateTableView indexPathForSelectedRow];
	if ( indexPath == nil ) return;
	{
		NSInteger section = 0, row = 0;
		if ( [_templInfoList getSelectedInfo:&section RowNum:&row] == YES )
		{
			// indexPathを作成しておく
			indexPath = [NSIndexPath indexPathForRow:row inSection:section];
		}
	}
	if ( _oldIndexPath )
	{
		[_oldIndexPath release];
		_oldIndexPath = nil;
	}
	_oldIndexPath = indexPath;
	[_oldIndexPath retain];
    
	// 現在選択中のテンプレート情報を取得
	TemplateInfo* info = [_templInfoList getTemplateInfoBySection:indexPath.section
														   RowNum:indexPath.row];
	
	// 確保
	TemplateCreatorViewController* controller = [TemplateCreatorViewController alloc];
	[controller initWithTemplateInfo:info Delegate:self];
	
	// popup表示
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC showPopupWindow:controller];
	
	// 遷移先の設定
	_windowView = WIN_VIEW_TEMPLATE_CREATOR;
	
	// 後片付け
	[controller release];
}

/**
 ユーザーリストのセルをダブルタップした際のアクション
 ユーザー情報ポップオーバーを表示する
 */
- (void)hUserListDoubleTap:(UIGestureRecognizer *)sender
{
    SearchResultTableViewCell* view = (SearchResultTableViewCell*)sender.view;
    
    // 送信プレビューの作成
    BroadcastMailUserInfoPopupController* userInfoPopupCV = [[BroadcastMailUserInfoPopupController alloc] initWithUserInfo:view.mailUserInfo PopupId:0x1000 CallBack:self];
    if ( userInfoPopupCV == nil ) return;
    
    // 送信プレビューの表示
    if ( popOverCtrlMailHist != nil )
    {
        [popOverCtrlMailHist release];
        popOverCtrlMailHist = nil;
    }
    popOverCtrlMailHist = [[UIPopoverController alloc] initWithContentViewController:userInfoPopupCV];
    popOverCtrlMailHist.delegate = userInfoPopupCV;
    userInfoPopupCV.popoverController = popOverCtrlMailHist;
    [popOverCtrlMailHist presentPopoverFromRect:sender.view.bounds
                                         inView:sender.view
                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                       animated:YES];
    [popOverCtrlMailHist setPopoverContentSize:CGSizeMake(600.0f, 180.0f)];
    [userInfoPopupCV release];
}

/**
 プレビュー画面をタップした際のアクション
 プレビューからテンプレート一覧表示に戻る
 */
- (void)hPreviewRightSwaip:(UIGestureRecognizer *)sender
{
    [templateAndPreview setContentOffset:CGPointMake(0, 0) animated:YES];
    [self enabledTemplateSelectBtn:NO];
    [_templInfoList UnselectedAll];
    [self enabledSendBtn];
    [lblAttachmentImgNum setHidden:YES];
}

@end
