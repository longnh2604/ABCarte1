//
//  UserInfoDispViewSupport.m
//  iPadCamera
//
//  Created by MacBook on 10/12/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "UserInfoDispViewSupport.h"

#import "userDbManager.h"
#import "mstUser.h"

#import "fcUserWorkItem.h"

#import "UIFlickerButton.h"

#import "OKDImageFileManager.h"

#import "MainViewController.h"

// 2016/6/24 TMS シークレットメモ対応
#import "SecretMemoPasswordInputPopup.h"
#import "SecretMemoPasswordChangePopup.h"
#import "SecretManagerViewController.h"

#ifdef CLOUD_SYNC
#import "shop/ShopManager.h"
#endif

#define SECURITY_PWD_ADMIN				@"ABCarte1234"              // シークレットメモ固定パスワード

@implementation UserInfoDispViewSupport

@synthesize lastWorkDate = _lastWorkDate;
@synthesize lblLastWorkContent;
@synthesize isSexMen = _isSexMen;

USERID_INT  _userID;
id          _ownerView;

#pragma mark localMethod

// ユーザ情報の初期化
- (void) initUserInfo
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
}

//update top image when receive notification
- (void) updateImageTop:(NSNotification *) notification
{
    NSDictionary* userInfo = notification.userInfo;
    NSNumber* total = (NSNumber*)userInfo[@"userID"];
    NSLog (@"Successfully received notification! %i", total.intValue);
    
    // データベースの初期化
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    // ユーザマスタの取得
    mstUser *user = [usrDbMng getMstUserByID:total.intValue];
    
    if (user) {
        // 写真の表示
        [imgViewPicture setImage:[self makeImagePictureWithUID: user.pictuerURL
                                                        userID:user.userID pictSize:imgViewPicture.bounds.size]];
    }
    else {
        [self initUserInfo];
    }
}

// 写真の表示
- (UIImage*) makeImagePictureWithUID:(NSString*)pictUrl 
							  userID:(USERID_INT)userID pictSize:(CGSize)size
{
	if ( (!pictUrl) || ((pictUrl) && ([pictUrl length] <= 0) ))
    {
        UIImage *drawImg = [UIImage imageNamed:@"representative.png"];
        return (drawImg);
    }
	
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
	
	NSData *fileDat = [NSData dataWithContentsOfFile:pictUrl];
	UIImage *img = [UIImage imageWithData:fileDat];
	if (img == nil)
	{ 
		return(nil); 
	}
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
	
	return (drawImg);
}

// 施術内容の更新
- (void) updateWorkItem:(fcUserWorkItem*) workItem Language:(BOOL)isJapanese
{
	// 最終施術日
    lblLastWorkDate.text = [workItem getNewWorkDateByLocalTime:isJapanese];
	self.lastWorkDate = workItem.workItemDate;
	// 最新施術内容
	lblLastWorkContent.text = workItem.workItemListString;	
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
//    userRegistNumberTitle.hidden = ! isDisplay;
//    userRegistNumber.hidden = ! isDisplay;
    userRegistNumberTitle.hidden = NO;
    userRegistNumber.hidden = NO;

	// 書式指定で設定する
	userRegistNumber.text = [userInfo getRegistNumber];
}

// 最新施術内容のタイトルを設定
-(void) setLastWorkTitle
{
	// メモのラベルを設定ファイルから読み込む
	NSDictionary *lables = [Common getMemoLabelsFromDefault];
	
	lblLastWorkTitle.text  = [NSString stringWithFormat:@"%@",
							  [lables objectForKey:@"memo1Label"]];
}

// ダイアログを閉じる
- (void) closeDialogView
{
    // 下表示modalDialogを閉じる
    [MainViewController closeBottomModalDialog];
}

#pragma mark public_Methods
// ユーザ情報の設定
- (void) setUserInfo:(USERID_INT)userID Language:(BOOL)isJapanese
{
	// データベースの初期化
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	
	// ユーザマスタの取得
    mstUser *user = [usrDbMng getMstUserByID:userID];
	// 2016/6/24 TMS シークレットメモ対応
    currentUserId = userID;
    
	// ユーザ情報の更新
	if (user) {
		[self updateSelectedUserByUserInfo:user];
		
		//施術内容Itemを取得
        
        fcUserWorkItem *workItem = [[fcUserWorkItem alloc] initWithWorkItem:user.userID userName:[user getUserName]];
		workItem = [usrDbMng getUserWorkItemByID:user.userID
                                       userName:[user getUserName]:workItem];
		
		// 施術内容の更新
		[self updateWorkItem:workItem Language:isJapanese];
        // 2016/6/1 TMS メモリ使用率抑制対応
        [workItem release];
	}
	else {
		[self initUserInfo];
	}
    
    self.isSexMen = (user.sex == Men);
    
    if (!isJapanese) {
        lblBloadType.hidden = YES;
        lblBloadTypeTitle.hidden = YES;
    } else {
        lblBloadType.hidden = NO;
        lblBloadTypeTitle.hidden = NO;
    }
	// 2016/6/1 TMS メモリ使用率抑制対応
    [user release];
	[usrDbMng release];
}

// ユーザ情報の更新
- (void) updateSelectedUserByUserInfo:(mstUser*) userInfo
{
	// 写真の表示
	[imgViewPicture setImage:
	 //[self makeImagePicture: userInfo.pictuerURL pictSize:imgViewPicture.bounds.size]];
	 [self makeImagePictureWithUID: userInfo.pictuerURL 
							userID:userInfo.userID pictSize:imgViewPicture.bounds.size]];
	// 名前
	lblName.text = [userInfo getUserName];
    lblName.textColor = [Common getNameColorWithSex:(userInfo.sex == Men)];
	
	// お客様番号
	[self setRegistNumberWithMstUser:userInfo];
    
	// 性別
	lblSex.text = (userInfo.sex != Men)? @"女性" : @"男性";
	lblSex.textColor = (userInfo.sex != Men)? 
	COLOR_SEX_FEMALE : COLOR_SEX_MALE;
	
	// 生年月日:西暦
	lblBirthday.text = [userInfo getBirthDayByLocalTimeAD];
	// 血液型
	lblBloadType.text = [userInfo getBloadTypeByStrig];
	// 趣味
	lblSyumi.text = userInfo.syumi;
	// メモ
	txtViewMemo.text = userInfo.memo;

#ifndef CLOUD_SYNC
    // 通常版は店舗名は表示しない
    if (! lblShopName.hidden) {
        lblShopName.hidden = YES;
    }
#else
    
    // クラウド版は店舗アカウントの有無で判定する
    if (! ([[ShopManager defaultManager] isAccountShop]) )
    {
        // 店舗アカウントのない場合は非表示とする
        if (! lblShopName.hidden) {
            lblShopName.hidden = YES;
        }
    }
    else {
        if (lblShopName.hidden) {
            lblShopName.hidden = NO;
        }
        lblShopName.text = userInfo.shopName;
    }
#endif

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

// userIDによる初期化:通常表示（ダイアログ表示ではない）
- (id)initWithUserID:(USERID_INT)userID ownerView:(id)ownerView
{
#ifdef CALULU_IPHONE
	self = [super initWithNibName:@"ip_UserInfoDispViewSupport" bundle:nil];
#else
	self = [super initWithNibName:@"UserInfoDispViewSupport" bundle:nil];
#endif
	if (self)
	{
		// userIDとownerViewの保存		
		_userID = userID;
		_ownerView = ownerView;
		
        _isDialogDispUse = NO;
	}
	
	return (self);
}

// userIDによる初期化:ダイアログ表示
- (id)initWithUserID4DialogDisp:(USERID_INT)userID hButtonClick:(onUserInfoButtonClick) hClick
{
#ifdef CALULU_IPHONE
	self = [super initWithNibName:@"ip_UserInfoDispViewSupport" bundle:nil];
#else
	self = [super initWithNibName:@"UserInfoDispViewSupport" bundle:nil];
#endif
	if (self)
	{
		// userIDとownerViewの保存		
		_userID = userID;
		_ownerView = nil;
		
        // ダイアログ表示
        _isDialogDispUse = YES;
        
        // イベントハンドラ保存
        if (hClick)
        { _buttonClickHandler = Block_copy(hClick); }
 	}
	
	return (self);
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateImageTop:)
                                                 name:@"refreshTopImage"
                                               object:nil];
    
	// 2016/6/24 TMS シークレットメモ対応
    iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
	// 位置の設定
    if (! _isDialogDispUse)
    {
        [self.view setFrame:CGRectMake(20.0f, 13.0f, 728.0f, 200.0f)];
    }
    
    // 角を丸くする
    [Common cornerRadius4Control: self.view];
	
	// ユーザ情報の設定
	[self setUserInfo:_userID Language:YES];
	
	// フリックボタンの初期化
    if (_ownerView)
    {
//        [btnUserInfo initialize:_ownerView];
        [btnPictView initialize:_ownerView];
        btnPictView.enabled = NO;
    }
	
	// 背景色の設定
//    self.view.backgroundColor = [Common getUserInfoBackColor];
    self.view.backgroundColor = [UIColor colorWithRed:255/255.0f green:186/255.0f blue:234/255.0f alpha:1.0f];
	
	// 最新施術内容のタイトルを設定
	[self setLastWorkTitle];
    
#ifdef CALULU_IPHONE
    if (! _isDialogDispUse)
    { self.view.hidden = YES; }    // iPhoneバージョンでは通常表示では表示しない
#endif
    
    //round textview
    txtViewMemo.layer.cornerRadius = 20;
    txtViewMemo.clipsToBounds = true;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [userNameHonoTitle release];
    userNameHonoTitle = nil;
    [lblBloadTypeTitle release];
    lblBloadTypeTitle = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTopImage" object:nil];
}

- (void)dealloc {
   
    if (_isDialogDispUse)
    {   Block_release(_buttonClickHandler); }
    
    [userNameHonoTitle release];
    [lblBloadTypeTitle release];
    
    [imgViewPicture release];
    [lblName release];
    [userRegistNumber release];
    [lblSex release];
    [lblLastWorkDate release];
    [lblLastWorkTitle release];
    [lblLastWorkContent release];
    [lblBirthday release];
    [lblBloadType release];
    [lblSyumi release];
    [txtViewMemo release];
//    [btnUserInfo release];
    [btnPictView release];
    [lblShopName release];
    
    [super dealloc];
}


#pragma mark control_events

// お客様情報の編集
- (IBAction) onUserInfo:(id)sender
{
    // ダイアログを閉じる
    [self closeDialogView];
    
    if (_buttonClickHandler)
    {   _buttonClickHandler(((UIBarButtonItem*)sender).tag); }
    
}

// サムネイル一覧表示ボタンの表示
- (void)showThumbnailViewBtn
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(193, 149, 59, 44);
    UIImage *img = [UIImage imageNamed:@"representative _btn.png"];
    [btn setBackgroundImage:img forState:UIControlStateNormal];
    [btn addTarget:self
            action:@selector(OnSingleTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
}
// お客様写真の一覧（サムネイル）の表示
- (IBAction) onThumbnailViewDisp:(id)sender
{
    // ダイアログを閉じる
    [self closeDialogView];
    
    if (_buttonClickHandler)
    {   _buttonClickHandler(((UIBarButtonItem*)sender).tag); }
}

// view(ダイアログ)を閉じる
- (IBAction) onViewClose:(id)sender
{
    // ダイアログを閉じる
    [self closeDialogView];
}

/**
 シークレットメモ画面
 */
- (IBAction)OnSecretManager:(id)sender
{
    
    if (popoverCntlPwdInput)
    {
        [popoverCntlPwdInput release];
        popoverCntlPwdInput = nil;
    }
    
    // パスワード入力ポップアップViewControllerのインスタンス生成
    SecretMemoPasswordInputPopup *vcPwdInput
    = [[SecretMemoPasswordInputPopup alloc]
       initWithPopUpViewContoller:POPUP_SECRET_MEMO_PASSWORD
       popOverController:nil  callBack:self];
    
    // パスワード入力ポップアップViewControllerのサイズ
    CGSize szPopup = CGSizeMake(380.0f, 174.0f);
    
    // Viewの中央
    CGSize szDev = self.view.superview.frame.size;
    CGRect rect = CGRectMake((szDev.width - szPopup.width) / 2,
                             (szDev.height - szPopup.height) / 2,
                             szPopup.width, szPopup.height);
    
    vcPwdInput.contentSizeForViewInPopover = szPopup;
    
    // ポップアップViewの表示
    popoverCntlPwdInput =
    [[UIPopoverController alloc] initWithContentViewController:vcPwdInput];
    vcPwdInput.popoverController = popoverCntlPwdInput;
    [popoverCntlPwdInput presentPopoverFromRect:rect
                                         inView:self.view
                       permittedArrowDirections:UIPopoverArrowDirectionDown
                                       animated:YES];
    // パスワード入力ポップアップViewControllerのサイズ
    [popoverCntlPwdInput setPopoverContentSize:CGSizeMake(380.0f, 174.0f)];
    
    [vcPwdInput release];
}

- (IBAction)onCustomerPreview:(UIButton *)sender {
    [self.delegate onPreviewCustomer:self];
}

// パスワード変更Popupを開く
- (void) openPwdChangePopup:(id)chgPopID
{
    if (popoverCntlPwdChange)
    {
        [popoverCntlPwdChange release];
        popoverCntlPwdChange = nil;
    }
    // パスワード変更ポップアップViewControllerのインスタンス生成
    SecretMemoPasswordChangePopup *vcPwdChange
    = [[SecretMemoPasswordChangePopup alloc]
       initWithPopUpViewContoller:[((NSNumber*)chgPopID) unsignedIntegerValue]
       popOverController:nil  callBack:self];
    // パスワード入力ポップアップViewControllerのサイズ
    CGSize szPopup = CGSizeMake(380.0f, 260.0f);
    
    
    // Viewの中央
    CGSize szDev = self.view.superview.frame.size;
    CGRect rect = CGRectMake((szDev.width - szPopup.width) / 2,
                             (szDev.height - szPopup.height) / 2,
                             szPopup.width, szPopup.height);
    
    vcPwdChange.contentSizeForViewInPopover = szPopup;
    // ポップアップViewの表示
    popoverCntlPwdChange =
    [[UIPopoverController alloc] initWithContentViewController:vcPwdChange];
    vcPwdChange.popoverController = popoverCntlPwdChange;
    [popoverCntlPwdChange presentPopoverFromRect:rect
                                          inView:self.view
                        permittedArrowDirections:UIPopoverArrowDirectionDown
                                        animated:YES];
    [popoverCntlPwdChange setPopoverContentSize:CGSizeMake(380.0f, 260.0f)];
    [vcPwdChange release];
}

// パスワードのチェック
- (BOOL) passwordCheck:(NSString*)inputPwd
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *pwd = [defaults stringForKey:SECRET_MEMO_PWD_KEY];
    if ( (!pwd) || ((pwd) && ([pwd length] <= 0 ) ) )
    {
        pwd = SECRET_MEMO__PWD_INIT_VALUE;
        _passwordSecretMemo = SECRET_MEMO__PWD_INIT_VALUE;
        [defaults setObject:SECRET_MEMO__PWD_INIT_VALUE
                     forKey:SECRET_MEMO_PWD_KEY];
        [defaults synchronize];
    }
    // 各パスワードまたは固定パスワードの一致を確認する
    BOOL userPwd = [inputPwd isEqualToString:pwd];
    BOOL fixPwd  = [inputPwd isEqualToString:SECURITY_PWD_ADMIN];
    return (userPwd || fixPwd);
}

// popupViewのDelegate
#pragma mark PopUpViewContollerBaseDelegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    NSString *pwdcp;
    NSArray *pwds = (NSArray*)object;
    
    self.view.userInteractionEnabled = YES;
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:NO];
    
    switch (popUpID)
    {
         case (NSUInteger)POPUP_SECRET_MEMO_PASSWORD:
            
            pwdcp = [(NSString *)object copy];
            
            // パスワードの変更かを確認
            if ( [pwdcp length] <= 0)
            {
                // パスワード変更ポップアップの表示
                NSUInteger chgPopID = (POPUP_SECRET_MEMO_PASSWORD_CHANGE) | popUpID;
                [self performSelector:@selector(openPwdChangePopup:)
                           withObject:[NSNumber numberWithUnsignedInteger: chgPopID]
                           afterDelay:(NSTimeInterval)0.5f];
            }else{
                // パスワードのチェック
                if ([self passwordCheck:pwdcp])
                {
                    //シークレットメモ画面へ遷移
                    SecretManagerViewController* controller = [SecretManagerViewController alloc];
                    [controller initWithNibName:@"SecretManagerViewController" bundle:nil];
                    [controller setUserId:currentUserId];
                    NSLog(@"show UserId = %d",currentUserId);
                    // popup表示
                    MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
                    [mainVC showPopupWindow:controller];
                    
                    // 後片付け
                    [controller release];
                }
                else
                {
                    // チェックNG:ダイアログを表示
                    [self alertDisp:@"入力したパスワードが違います。" alertTitle:@"パスワード入力"];
                }
                
            }
            
            break;
        case (NSUInteger)POPUP_SECRET_MEMO_PASSWORD_CHANGE:
            if ( [(NSString*)[pwds objectAtIndex:0] length] > 0){
                // パスワードのチェック
                if ([self passwordCheck:(NSString*)[pwds objectAtIndex:0]])
                {
                    // チェックOK:パスワードの変更
                    [self passwordChange:(NSString*)[pwds objectAtIndex:1]];
                    
                    // ダイアログを表示
                    [self alertDisp:@"パスワードを変更しました" alertTitle:@"パスワード変更"];
                }
                else
                {
                    // チェックNG:ダイアログを表示
                    [self alertDisp:@"入力した旧パスワードが違います。" alertTitle:@"パスワード変更"];
                }
            }else{
                [self passwordReset];
                // ダイアログを表示
                [self alertDisp:@"パスワードをリセット（初期化）しました" alertTitle:@"パスワードリセット"];
            }
            break;
        default:
            break;
    }
    
    //iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    //app.navigationController.enableRotate = YES;
}

// パスワードの変更
- (void) passwordChange:(NSString*)newPassword{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:newPassword
                 forKey:SECRET_MEMO_PWD_KEY];
    _passwordSecretMemo = [NSString stringWithString:newPassword];
    
    [defaults synchronize];
}

// パスワードのリセット
- (void) passwordReset{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:SECRET_MEMO__PWD_INIT_VALUE
                 forKey:SECRET_MEMO_PWD_KEY];
    _passwordSecretMemo = SECRET_MEMO__PWD_INIT_VALUE;
    
    [defaults synchronize];
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

-(NSString*) getDocumentFolderFilenameWithUID:(int)uidFolderName
                             fileNameNoFolder:(NSString*)fileName
{
    return ([NSString stringWithFormat:@"Documents/User%08d/%@",
             uidFolderName, fileName]);
}

- (void) onRemoveAvatar {
     // ユーザマスタの取得
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    mstUser *user = [usrDbMng getMstUserByID:currentUserId];
    [usrDbMng updateUserPicture:user.userID pictureURL:NULL];
    [usrDbMng updateUserPictureNew:user.userID pictureURL:NULL complete:^(BOOL completed) {
        if (completed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [imgViewPicture setImage:[UIImage imageNamed:@"representative.png"]];
            });
        }
    }];
}

- (void)OnSingleTap:(id)sender{
    //show the photo handle option
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"内容を選択してください"
                                                       delegate:self
                                              cancelButtonTitle:@"キャンセル"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"写真一覧",@"写真解除",@"キャンセル",nil];
    [sheet autorelease];
    sheet.actionSheetStyle = UIActionSheetStyleDefault;
    [sheet showFromRect:imgViewPicture.bounds inView:self.view animated:true];
}

//actionsheet delegate
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self.delegate OnSingleTap:self];
            break;
        case 1:
            [self onRemoveAvatar];
            break;
        case 2:
            NSLog(@"Cancel");
            break;
        default:
            break;
    }
}

@end
