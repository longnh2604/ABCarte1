//
//  UserInfoEditViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/10/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "defines.h"
#import "Common.h"
#import "NSString+Validation.h"

#import "UserInfoEditViewController.h"
#import "mstUser.h"

#import "UIKanaSupportTextField.h"

#ifdef CLOUD_SYNC
#import "shop/ShopManager.h"
#import "shop/ShopItem.h"
#import "shop/ShopSelectPopup.h"

#import "CloudSyncClientManager.h"
#endif

#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import "DatePickerPopUp.h"

// 2016/7/17 TMS 参照モード追加対応
#define USR_VIEW_MODE_TAG 2

@implementation UserInfoEditViewController

@synthesize editUser;
@synthesize isEditableUserName;
@synthesize viewMode;

#pragma mark private_methods

// 既存ユーザによるコントロールの反映
- (void) updateDataWithExistUser
{
	// タイトルを設定
    txtDialogTitle = @"お客様情報を編集します";
    txtBtnTitle = @"更　新";
    
    //user avatar
    [imvCustomer setImage:[self makeImagePictureWithUID: editUser.pictuerURL
                                                    userID:editUser.userID pictSize:imvCustomer.bounds.size]];
	
	// ユーザの内容を反映
	txtFirstNameCana.text       = editUser.firstNameCana;
	txtSecondNameCana.text      = editUser.secondNameCana;
	txtFirstName.text           = editUser.firstName;
	txtSecondName.text          = editUser.secondName;
	txtUserRegistNumber.text    = [editUser getRegistNumber];
    txtMidName.text             = editUser.middleName;
    
    // 住所の設定
    postal.text             = editUser.postal;
    adr2.text               = editUser.adr2;
    adr3.text               = editUser.adr3;
    adr4.text               = editUser.adr4;
    if ([editUser.adr1 length]>0) {
        btnPrefecture.tag = 1;
        [self dispLabelPrefecture:editUser.adr1];
    } else {
        btnPrefecture.tag = 0;
        [self dispLabelPrefecture:nil];
    }
    
    telephone.text          = editUser.tel;
    txtMobile.text          = editUser.mobile;
	
	segSex.selectedSegmentIndex 
		= (editUser.sex != Men)? (NSInteger)1 : (NSInteger)0;
	
	// 生年月日の設定
	if(editUser.birthDay)
	{
        btnBirthday.tag = 1;
        birthDay = [editUser.birthDay copy];
        [birthDay retain];
        [self dispLabelBirthday:birthDay];
	}
	else
	{
        btnBirthday.tag = 0;    // 生年月日が設定されていないことを示す
        [self dispLabelBirthday:[NSDate date]];
        birthDay = nil;
	}
	
	
	// 血液型の設定
    btnBloodType.tag = editUser.bloadType;
    [self OnBloodSetOK:[self ConvBloodTypeEnum:btnBloodType.tag]];
	
	txtSyumi.text = editUser.syumi;
    //Email欄にアドレスを設定
    emailText1.text = editUser.email1;
    emailText2.text = editUser.email2;

	// 受信拒否設定(e-mailが設定されていなかったら編集不可)
    [self OnEmailEditingDidEnd:nil];
    
	txtViewMemo.text = editUser.memo;
    // 2016/8/12 TMS 顧客情報に担当者を追加
    txtResponsible.text = editUser.responsible;
}

- (IBAction)changeAvatar:(UIButton *)sender {
    if (editUser == nil) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"写真が保存されていません"
                                                            message:@"カルテを作成し写真撮影を行ってください"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    } else {
        if (delegate != nil)
        {
            // クライアントクラスへcallback
            [delegate OnPopUpViewSet:-1 setObject:nil];
        }
        [self closeByPopoverContoller];
        [self goToThumbnailView];
    }
}

- (void)goToThumbnailView {
    ThumbnailViewController *thumbnailVC = [[ThumbnailViewController alloc]
                                            initWithNibName:@"ThumbnailViewController" bundle:nil];
    
    // 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
    [thumbnailVC setSelectedUserID:self.editUser.userID];
    
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    // サムネイル画面の表示
    [mainVC showPopupWindow:thumbnailVC];
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

// 新規ユーザによるコントロールの反映
- (void) updateDataWithNewUser
{
    //user avatar
    [imvCustomer setImage:[UIImage imageNamed:@"representative.png"]];
	// タイトルを設定
    txtDialogTitle = @"お客様を新規に作成します";
    txtBtnTitle = @"登　録";
	
	// ユーザ名を初期化
	txtFirstNameCana.text = EMPTY_TEXT;
	txtSecondNameCana.text = EMPTY_TEXT;
	txtFirstName.text = EMPTY_TEXT;
	txtSecondName.text = EMPTY_TEXT;
	txtUserRegistNumber.text = EMPTY_TEXT;
    
    postal.text     = EMPTY_TEXT;
    btnPrefecture.tag = 0;
    [self dispLabelPrefecture:nil];
    adr2.text       = EMPTY_TEXT;
    adr3.text       = EMPTY_TEXT;
    adr4.text       = EMPTY_TEXT;
    telephone.text  = EMPTY_TEXT;
    txtMobile.text = EMPTY_TEXT;
	
	// 性別の初期化：女性
	segSex.selectedSegmentIndex = 1;
	
	// 生年月日の設定
    btnBirthday.tag = 0;    // 生年月日が設定されていないことを示す
    [self dispLabelBirthday:[NSDate date]];
			
	// 血液型設定：不明
    btnBloodType.tag = BloadTypeUnKnown;
    [self OnBloodSetOK:[self ConvBloodTypeEnum:btnBloodType.tag]];
		
	// 趣味とメモの初期化
	txtSyumi.text = EMPTY_TEXT;
	txtViewMemo.text = EMPTY_TEXT;
    
    //Email初期化
    emailText1.text = EMPTY_TEXT;
    emailText2.text = EMPTY_TEXT;
    
    // 2016/8/12 TMS 顧客情報に担当者を追加
    txtResponsible.text = EMPTY_TEXT;
	
	// 受信拒否設定(e-mailが設定されていなかったら編集不可)
    [self OnEmailEditingDidEnd:nil];
}

// ユーザ名編集不可の場合の設定
- (void) noEditUserName
{
	txtFirstNameCana.enabled = NO;
	txtSecondNameCana.enabled = NO;
	txtFirstName.enabled = NO;
	txtSecondName.enabled = NO;
}

// 2016/7/17 TMS 参照モード追加対応
// ユーザ情報編集不可の場合の設定
- (void) noEditUserInfo
{
    
    lblDialogTitle.text = @"お客様情報";
    [btnCancel setTitle:@"閉じる" forState:UIControlStateNormal];
    
    txtFirstNameCana.enabled = NO;
    txtSecondNameCana.enabled = NO;
    txtFirstName.enabled = NO;
    txtSecondName.enabled = NO;
    txtUserRegistNumber.enabled = NO;
    btnBirthday.enabled = NO;
    btnBloodType.enabled = NO;
    segSex.enabled = NO;
    postal.enabled = NO;
    btnConvPostal.enabled = NO;
    txtPrefecture.enabled = NO;
    btnPrefecture.enabled = NO;
    btnShopSelectShow.enabled = NO;
    adr2.enabled = NO;
    adr3.enabled = NO;
    adr4.enabled = NO;
    telephone.enabled = NO;
    emailText1.enabled = NO;
    emailText2.enabled = NO;
    swMailBlock.enabled = NO;
    txtSyumi.enabled = NO;
    txtViewMemo.editable = NO;
    btnRegist.enabled = NO;
    segCountry.enabled = NO;
    txtMidName.enabled = NO;
    txtMobile.enabled = NO;
    // 2016/8/12 TMS 顧客情報に担当者を追加
    txtResponsible.enabled = NO;
    txtShopName.enabled = NO;
    lblShopName.hidden = YES;
    txtShopName.alpha = 0.7;
    txtMidName.alpha = 0.7;
    txtMobile.alpha = 0.7;
    txtFirstNameCana.alpha = 0.7;
    txtSecondNameCana.alpha = 0.7;
    txtFirstName.alpha = 0.7;
    txtSecondName.alpha = 0.7;
    txtUserRegistNumber.alpha = 0.7;
    btnBirthday.alpha = 0.7;
    btnBloodType.alpha = 0.7;
    segSex.alpha = 0.7;
    postal.alpha = 0.7;
    btnConvPostal.alpha = 0.7;
    txtPrefecture.alpha = 0.7;
    btnPrefecture.alpha = 0.7;
    btnShopSelectShow.alpha = 0.7;
    adr2.alpha = 0.7;
    adr3.alpha = 0.7;
    adr4.alpha = 0.7;
    telephone.alpha = 0.7;
    emailText1.alpha = 0.7;
    emailText2.alpha = 0.7;
    swMailBlock.alpha = 0.7;
    txtSyumi.alpha = 0.7;
    txtViewMemo.alpha = 0.7;
    btnRegist.alpha = 0;
    segCountry.alpha = 0.7;
    
    txtResponsible.alpha = 0.7;

}

// 入力内容の先頭がひらがなであるかを確認する
- (BOOL) isCheckInputHiragana:(NSString*)text
{
	if ([text length] <= 0)
	{	return (true); }		// 空文字は判定しない
	
	// ひらがなの正規表現
	static NSString *regEx = @"[あ-ん]";
    static NSString *regEx_en = @"[a-zA-Z]";
	
	// 先頭文字を取得
	NSString *topStr = [text substringToIndex:1];
	
	// 先頭文字を正規表現検索
    NSRange range = [topStr rangeOfString:regEx
                                  options:NSRegularExpressionSearch];
    NSRange range_en = [topStr rangeOfString:regEx_en
                                     options:NSRegularExpressionSearch];
    
    BOOL jp = (range.location != NSNotFound)? YES : NO;
    BOOL en = (range_en.location != NSNotFound)? YES : NO;
	
	// != NSNotFoundにてtextをひらがなとする
    if (jp || en) {
        return YES;
    } else {
        return NO;
    }
}

// コンテンツScrollViewのスクロール
- (void) contentsScrollWithYpos:(CGFloat)yPos
{
#ifndef CALULU_IPHONE
    return;         // iPhoneのみ適用
#endif
    
    CGRect frame = scrContents.frame;
	
	frame.origin.x = 0.0f;
    frame.origin.y = yPos;
	
    // scrollViewを移動して表示する 
	[scrContents scrollRectToVisible:frame animated:NO];
}

#ifdef CLOUD_SYNC
// 店舗IDにより店舗itemを取得する
- (ShopItem*) _getShopItemWithShopID:(NSInteger)sID
{
    ShopItem *find = nil;
    
    for (ShopItem *item in _shopItemList)
    {
        if (item.shopID == sID)
        {   
            find = item;
            break;
        }
    }
    
    return (find);
}

// 店舗IDにより店舗Itemリストよりindexを取得する
- (NSInteger) _getShopItemIndexWithShopID:(NSInteger)sID
{
    NSInteger index = 0;
    
    NSInteger find = 0;
    for (ShopItem *item in _shopItemList)
    {
        if (item.shopID == sID)
        {   
            index = find;
            break;
        }
        
        find++;
    }
    
    return (index);
}

#endif

/**
 受信拒否設定をロードする
 */
- (BOOL) loadMailRecieveSetting
{
	return YES;
}

- (void) drawRequired : (BOOL)set {
    if (isJapanese) {
        vwRequired.hidden = YES;
    } else {
        vwRequired.hidden = NO;
        vwRequired.layer.borderWidth = 2.0f;
        vwRequired.layer.borderColor = [[UIColor redColor] CGColor];
        vwRequired.layer.cornerRadius = 10.0f;
    }
}

#pragma mark iOS_Framework

// ユーザ情報編集PopUpの作成
- (id) initWithUserEditPopUpViewContoller:(NSUInteger)popUpID 
				popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate
						user4Edit:(mstUser*)user
{
#ifdef CLOUD_SYNC
    selectShopID = user.shopID;
#endif
#ifndef CALULU_IPHONE
	if (self = [super initWithPopUpViewContoller:popUpID
							   popOverController:controller
										callBack:callBackDelegate] )
#else
   	if (self = [super initWithPopUpViewContoller:popUpID
                               popOverController:controller
                                        callBack:callBackDelegate
                                         nibName:@"ip_UserInfoEditViewController"] )
#endif
	{
		self.editUser = user;
        [self.editUser.birthDay retain];
		self.isEditableUserName = YES;
        

#ifndef CALULU_IPHONE
        self.contentSizeForViewInPopover = CGSizeMake(768.0f, 484.0f);
#endif
	}
	
	return (self);
}

// 新規ユーザ情報PopUpの作成
- (id) initWithNewUserPopUpViewContoller:(NSUInteger)popUpID 
					   popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate
{
#ifndef CALULU_IPHONE
	if (self = [super initWithPopUpViewContoller:popUpID
							   popOverController:controller
										callBack:callBackDelegate] )
#else
        if (self = [super initWithPopUpViewContoller:popUpID
                                   popOverController:controller
                                            callBack:callBackDelegate
                                             nibName:@"ip_UserInfoEditViewController"] )
#endif
	{
		self.editUser = nil;
		self.isEditableUserName = YES;
#ifndef CALULU_IPHONE
		self.contentSizeForViewInPopover = CGSizeMake(768.0f, 484.0f);
#endif
	}
	
	return (self);
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	if (editUser)
	{
		// 既存ユーザによるコントロールの反映
		[self updateDataWithExistUser];
		
		// ユーザ名編集不可の場合の設定
		if (! self.isEditableUserName)
		{	[self noEditUserName]; }
	}
	else 
	{
		// 新規ユーザによるコントロールの反映
		[self updateDataWithNewUser];
		
		// 姓（漢字）TextFieldにフォーカスする（キーボード表示）
		[txtFirstName becomeFirstResponder];
	}
	
	// タイトルの角を丸める
	[Common cornerRadius4Control:lblDialogTitle];
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=7.0) {
        // 青枠表示に変えるパーツの処理
        NSArray *partsArr = @[btnRegist, btnCancel, btnBloodType, btnShopSelectShow, btnConvPostal, segCountry];
        for (id parts in partsArr) {
            [parts setBackgroundColor:[UIColor whiteColor]];
            [[parts layer] setCornerRadius:6.0];
            [parts setClipsToBounds:YES];
            [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
            [[parts layer] setBorderWidth:1.0];
        }
        [segSex setBackgroundColor:[UIColor whiteColor]];
        [[segSex layer] setCornerRadius:5.0];
        [segSex setClipsToBounds:YES];
        [[segSex layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[segSex layer] setBorderWidth:1.0];

        // 生年月日設定ボタン
        [btnBirthday setBackgroundColor:[UIColor whiteColor]];
//        [[btnBirthday layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
//        [[btnBirthday layer] setBorderWidth:1.0];
        
        // 都道府県設定ボタン
        [btnPrefecture setBackgroundColor:[UIColor whiteColor]];
//        [[btnPrefecture layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
//        [[btnPrefecture layer] setBorderWidth:1.0];
    }
    // 生年月日設定ボタン（角丸）
    [[btnBirthday layer] setCornerRadius:6.0];
    [btnBirthday setClipsToBounds:YES];
    
    // 都道府県設定ボタン（角丸）
    [[btnPrefecture layer] setCornerRadius:6.0];
    [btnPrefecture setClipsToBounds:YES];
    
    // 入力キーボードタイプの設定
    postal.keyboardType     = UIKeyboardTypeNumberPad;
    telephone.keyboardType  = UIKeyboardTypeNumberPad;
    emailText1.keyboardType = UIKeyboardTypeEmailAddress;
    txtMobile.keyboardType = UIKeyboardTypeNumberPad;
	
	// かな入力のサポート
	[txtFirstName initWithKanaTextField:txtFirstNameCana];
	[txtSecondName initWithKanaTextField:txtSecondNameCana];
	
	// お客様番号の入力をコントロールする
	txtUserRegistNumber.delegate = self;
    
#ifdef CALULU_IPHONE
    scrContents.contentSize = viewContents.frame.size;
#endif
    
#ifdef CLOUD_SYNC
    // アカウントがある場合、店舗選択関連のコントロールの表示
    if ([[ShopManager defaultManager] isAccountShop])
    {
        btnShopSelectShow.hidden = NO;
        lblShopName.hidden = YES;
        txtShopName.hidden = NO;
        
        // アカウント店舗IDにて可能な店舗Item一覧を取得
        if(!_shopItemList){
            _shopItemList = [[NSMutableArray alloc]init]; 
        }
        [_shopItemList addObjectsFromArray:[[ShopManager defaultManager] getChilidShopItemsByAccountShop]];
        NSInteger accShopLevel = [[ShopManager defaultManager] getShopLevelWithShopID:[[ShopManager defaultManager]getAccountShopID]];
        
        [_shopItemList addObjectsFromArray:[[ShopManager defaultManager]getAllShopList:(accShopLevel + 1)]];
        [_shopItemList retain];
        
        // 編集時：既存ユーザの店舗　新規：アカウント店舗　にてitemを取得する
        ShopItem *item = [self _getShopItemWithShopID:(editUser)?
                            editUser.shopID : [[ShopManager defaultManager] getAccountShopID]];
        lblShopName.text = item.shopName;
        txtShopName.text = item.shopName;
        selectShopID = item.shopID;
    }
#endif

	if ( [[emailText1 text] length] > 0 )
	{
		// 受信拒否設定を設定する
		[self loadMailRecieveSetting];
	}
#ifndef DEF_ABCARTE
    lblMailReject.hidden = YES;
    swMailBlock.hidden = YES;
#endif
    
    //round textview
    txtViewMemo.layer.cornerRadius = 10;
    txtViewMemo.clipsToBounds = true;
    
    btnChangeAvatar.layer.cornerRadius = 10;
    btnChangeAvatar.clipsToBounds = true;
}

- (void)viewWillAppear:(BOOL)animated
{
    //check language
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSString *country = [df stringForKey:@"CUSTOMER_COUNTRY"];
    if (country==nil) {
        [df setValue:@"jp" forKey:@"CUSTOMER_COUNTRY"];
    }
    if ([country isEqualToString:@"en"]) {
        isJapanese = NO;
    } else {
        isJapanese = YES;
    }
    
    // 言語設定による表示の変更
    [self setCountryView];
    
    // 所属店舗に関する注意事項の更新
    [self OnEmailEditingDidEnd:nil];
    
    // 2016/7/17 TMS 参照モード追加対応
    if(viewMode == USR_VIEW_MODE_TAG){
        [self noEditUserInfo];
    }
    
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    mainVC->preventScroll = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    mainVC->preventScroll = NO;
    
    [btnCancel release];
    btnCancel = nil;
    [postal release];
    postal = nil;
    [btnConvPostal release];
    btnConvPostal = nil;
    [adr2 release];
    adr2 = nil;
    [btnBirthday release];
    btnBirthday = nil;
    [adr3 release];
    adr3 = nil;
    [telephone release];
    telephone = nil;
    [btnBloodType release];
    btnBloodType = nil;
    [swMailBlock release];
    swMailBlock = nil;
    [btnPrefecture release];
    btnPrefecture = nil;
    [adr4 release];
    adr4 = nil;
    [lblMailReject release];
    lblMailReject = nil;
    [segCountry release];
    segCountry = nil;
    [lblBloodType release];
    lblBloodType = nil;
    [lblName release];
    lblName = nil;
    [lblKana release];
    lblKana = nil;
    [lblSex release];
    lblSex = nil;
    [lblNameSuffix release];
    lblNameSuffix = nil;
    [lblUserRegistNumber release];
    lblUserRegistNumber = nil;
    [lblBirthday release];
    lblBirthday = nil;
    [lblAddress release];
    lblAddress = nil;
    [txtPrefecture release];
    txtPrefecture = nil;
    [lblTelephone release];
    lblTelephone = nil;
    [lblSyumi release];
    lblSyumi = nil;
    [lblMemo release];
    lblMemo = nil;
    [txtMidName release];
    txtMidName = nil;
    [vwRequired release];
    vwRequired = nil;
    if (_shopItemList) {
        [_shopItemList removeAllObjects];
        _shopItemList = nil;
    }
    [txtFirstNameCana release];
    txtFirstNameCana = nil;
    [txtSecondNameCana release];
    txtSecondNameCana = nil;
    [txtFirstName release];
    txtFirstName = nil;
    [txtSecondName release];
    txtSecondName = nil;
    txtUserRegistNumber.delegate = nil;
    [txtUserRegistNumber release];
    [vwRequired release];
    [segSex release];
    [txtSyumi release];
    [emailText1 release];
    [txtViewMemo release];
    [btnRegist release];
    [lblDialogTitle release];
    [lblShopName release];
    [txtShopName release];
    
    // 2016/8/12 TMS 顧客情報に担当者を追加
    [txtResponsible release];
    txtResponsible = nil;
    [lblResponsible release];
    lblResponsible = nil;
    
//    [editUser release];
    if (editUser)
    {
        editUser.birthDay = nil;
        editUser = nil;
    }
//    popoverController.passthroughViews = nil;
//    popoverController.delegate = nil;
//    [popoverController release];
    popoverController = nil;
    
//    [self release];
}

// 言語設定変更による表示内容の修正
- (void)setCountryView
{
    if (isJapanese) {   // 日本語表示の場合
        // 言語設定ボタンの表示
        [segCountry setTitle:@"Japanese" forSegmentAtIndex:0];
        [segCountry setTitle:@"English" forSegmentAtIndex:1];
        segCountry.selectedSegmentIndex = 0;

        segSex.frame = CGRectMake(478, 80, 94, 30);
        [segSex setTitle:@"男性" forSegmentAtIndex:0];
        [segSex setTitle:@"女性" forSegmentAtIndex:1];
        lblSex.text = @"性別";
        txtFirstName.placeholder = @"(姓を入力)";
        txtSecondName.placeholder = @"(名を入力)";
        lblName.text = @"お名前";
//        lblBirthday.text = @"生年月日";
        [self dispLabelBirthday:birthDay];
        lblUserRegistNumber.text = @"お客様番号";
        txtUserRegistNumber.placeholder = @"番号を入力";
        
        lblAddress.text = @"住所";
        postal.placeholder = @"郵便番号";
        adr2.placeholder = @"郡/市区町村";
        adr3.placeholder = @"以降の住所";
        adr4.placeholder = @"以降の住所";
        
        telephone.placeholder = @"設定されていません";
        lblTelephone.text = @"電話番号";
        emailText1.placeholder = @"設定されていません";
        txtSyumi.placeholder = @"設定されていません";
        lblSyumi.text = @"趣味";
        lblMemo.text = @"備考";
        lblMailReject.text = @"メール受信許可";
        lblEmail.text = @"メール";
        lblMobile.text = @"携帯番号";
        txtMobile.placeholder = @"設定されていません";
        [btnShopSelectShow setTitle:@"店舗選択" forState:UIControlStateNormal];
        
        [btnRegist setTitle:txtBtnTitle forState:UIControlStateNormal];
        [btnCancel setTitle:@"取　消" forState:UIControlStateNormal];
        lblDialogTitle.text = txtDialogTitle;
        
        // 2016/8/12 TMS 顧客情報に担当者を追加
        lblResponsible.text = @"担当者";
        lblBloodType.text = @"血液型";
        [btnBloodType setTitle:@"不 明" forState:UIControlStateNormal];
        txtResponsible.placeholder = @"担当者を入力";
        [btnConvPostal setTitle:@"住所変換" forState:UIControlStateNormal];
        [btnChangeAvatar setTitle:@"画像の選択" forState:UIControlStateNormal];
        [self hiddenControl:NO];
    } else {            // 英語表示の場合
        // 言語設定ボタンの表示
        [segCountry setTitle:@"Japanese" forSegmentAtIndex:0];
        [segCountry setTitle:@"English" forSegmentAtIndex:1];
//        [segCountry setTitle:@"日本語" forSegmentAtIndex:0];
//        [segCountry setTitle:@"英 語" forSegmentAtIndex:1];
        segCountry.selectedSegmentIndex = 1;
        segSex.frame = CGRectMake(478, 80, 120, 30);
        [segSex setTitle:@"Male" forSegmentAtIndex:0];
        [segSex setTitle:@"Female" forSegmentAtIndex:1];
        lblSex.text = @"Sex";
        txtFirstName.placeholder = @"First name";
        txtSecondName.placeholder = @"Last name";
        txtMidName.placeholder = @"Middle name";
        lblName.text = (segSex.selectedSegmentIndex==0)? @"Mr." : @"Ms.";
        [self dispLabelBirthday:birthDay];
        lblUserRegistNumber.text = @"Customer No";
        txtUserRegistNumber.placeholder = @"Number";
        txtResponsible.placeholder = @"Person in charge";
        lblAddress.text = @"Address";
        postal.placeholder = @"Postal code";
        adr2.placeholder = @"County/City";
        adr3.placeholder = @"Sub Address 1";
        adr4.placeholder = @"Sub Address 2";
        txtMobile.placeholder = @"Mobilephone";
        lblMobile.text = @"Mobile No";
        telephone.placeholder = @"Telephone";
        lblTelephone.text = @"Phone No";
        emailText1.placeholder = @"";
        txtSyumi.placeholder = @"Please enter your hobby";
        lblSyumi.text = @"Hobby";
        lblMemo.text = @"Notes";
        lblMailReject.text = @"Receive mail";
        lblEmail.text = @"Email";
        emailText1.placeholder = @"Please enter your email";
        [btnShopSelectShow setTitle:@"Store select" forState:UIControlStateNormal];
        lblBirthday.text = @"Birthday";
        [btnRegist setTitle:@"Entry" forState:UIControlStateNormal];
        [btnCancel setTitle:@"Cancel" forState:UIControlStateNormal];
        lblDialogTitle.text = @"Please enter your personal information";
        lblBloodType.text = @"Blood Type";
        [btnBloodType setTitle:@"Unknown" forState:UIControlStateNormal];
        [btnConvPostal setTitle:@"Conversion" forState:UIControlStateNormal];
        [btnChangeAvatar setTitle:@"Select Image" forState:UIControlStateNormal];
        // 2016/8/12 TMS 顧客情報に担当者を追加
        lblResponsible.text = @"Responsible";
        
        [self hiddenControl:YES];
    }
    [self drawRequired:!isJapanese];
    [self OnEmailEditingDidEnd:nil];
}

// 入力言語切り替え時の表示・非表示制御を行うパーツ
- (void)hiddenControl:(BOOL)isHidden
{
//    btnBloodType.hidden = isHidden;
//    lblBloodType.hidden = isHidden;
    lblKana.hidden = isHidden;
    txtFirstNameCana.hidden = isHidden;
    txtSecondNameCana.hidden = isHidden;
    lblNameSuffix.hidden = isHidden;
    btnPrefecture.hidden = isHidden;
//    btnConvPostal.hidden = isHidden;
    txtPrefecture.hidden = !isHidden;
    txtMidName.hidden = !isHidden;
}

- (void)viewDidAppear:(BOOL)animated
{
#ifdef CLOUD_SYNC
    if (! [[ShopManager defaultManager] isAccountShop])
    {   return; } // 店舗対応でない場合は何もしない
#endif
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
   //  return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
	// 縦向きのみ対応する
	BOOL stat = ((interfaceOrientation == UIDeviceOrientationPortrait) ||
				 (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown) );
	return (stat);
}

/**
 * iOS8以降は各ポップアップでの画面回転制御が有効になる
 */
- (BOOL)shouldAutorotate
{
    return NO;
}

// メール受信設定の取得
- (NSInteger) getMailRecieveSetting
{
    return (swMailBlock.on == YES)? 0 : 1;
}

// e-mailが存在する
- (BOOL) isEmailExist
{
	return ([emailText1.text length] > 0) ? YES : NO;
}


#pragma mark control_events

- (IBAction)onBirthday:(id)sender {
    //日付の設定ポップアップViewControllerのインスタンス生成
	DatePickerPopUp *vcDatePicker
    = [[DatePickerPopUp alloc]initWithDatePopUpViewContoller:USER_SET_BIRTHDAY_POPUP
                                           popOverController:nil
                                                    callBack:self
                                                    initDate:birthDay
                                                  selectLang:isJapanese];
    
	vcDatePicker.contentSizeForViewInPopover = CGSizeMake(332.0f, 364.0f);
	
	// ポップアップViewの表示
	popCtlDatePicker = [[UIPopoverController alloc]
                        initWithContentViewController:vcDatePicker];
	vcDatePicker.popoverController = popCtlDatePicker;

    [popCtlDatePicker presentPopoverFromRect:btnBirthday.bounds
                                      inView:btnBirthday
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:NO];
    
    if (isJapanese) {
        vcDatePicker.lblTitle.text = @"誕生日を設定してください";
    } else {
        vcDatePicker.lblTitle.text = @"Set the date of birth";
        vcDatePicker.isJapanese = NO;
    }
    [popCtlDatePicker release];
	[vcDatePicker release];
    
    // キーボードが表示されていた場合に閉じる
    [self.view endEditing:YES];
}

// 生年月日の表示
- (void) dispLabelBirthday:(NSDate*)date
{
    if (btnBirthday.tag==0) {
        [btnBirthday setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        
        NSString *title;
        if (isJapanese) {
            title = @"　(生年月日を設定してください)";
        } else {
            title = @" Set the date of birth";
        }
        [btnBirthday setTitle:title
                     forState:UIControlStateNormal];
    } else {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        if (isJapanese) {
            [formatter setDateFormat:@"　yyyy年MM月dd日"];
        } else {
            [formatter setDateFormat:@"　MM/dd/yyyy"];
        }
        [btnBirthday setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btnBirthday setTitle:[formatter stringFromDate:date]
                     forState:UIControlStateNormal];
    }
}

// 各TextFieldのEnterキーイベント
- (IBAction)onTextDidEnd:(id)sender
{
	UITextField *textField = (UITextField*)sender;
	
	switch (textField.tag) {
		case 0:
			// 姓
			if ([textField.text length] > 0) {
				[txtSecondName becomeFirstResponder];
				
				// 姓（漢字）の入力で登録ボタンを有効にする
				btnRegist.enabled = YES;
			}
			break;
		case 1:
			// 名
			if ([textField.text length] > 0) {
				[txtFirstNameCana becomeFirstResponder];
			}
			break;
		case 2:
			// 姓:かな
			if ([textField.text length] > 0) {
				[txtSecondNameCana becomeFirstResponder];
			}
			break;
		case 3:
			// 名:かな、お客様番号、趣味
			// キーボードを隠す
			[textField resignFirstResponder];
			
			break;
			
		default:
			break;
	}
}

// 血液型の設定変更
- (IBAction)onBloodTypeChange:(id)sender {
    //日付の設定ポップアップViewControllerのインスタンス生成
	BloodGroupPopUp *vcBloodType
    = [[BloodGroupPopUp alloc]initWithBloodTypePopUpViewContoller:USER_SET_BLOODTYPE_POPUP
                                                popOverController:nil
                                                         callBack:self
                                                        bloodType:[self ConvBloodTypeEnum:btnBloodType.tag]];
    
	// ポップアップViewの表示
	popCtlDatePicker = [[UIPopoverController alloc]
                        initWithContentViewController:vcBloodType];
	vcBloodType.popoverController = popCtlDatePicker;
    
    [popCtlDatePicker presentPopoverFromRect:btnBloodType.bounds
                                      inView:btnBloodType
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:NO];
    [popCtlDatePicker setPopoverContentSize:CGSizeMake(360.0f, 110.0f)];
    
	[vcBloodType release];
    
    // キーボードが表示されていた場合に閉じる
    [self.view endEditing:YES];
}

-(NSInteger)ConvBloodTypeEnum:(NSInteger)blood
{
    NSInteger bloodType;
    switch (blood) {
        case BloadTypeA:
            bloodType = BLOODTYPE_A;
            break;
        case BloadTypeB:
            bloodType = BLOODTYPE_B;
            break;
        case BloadTypeO:
            bloodType = BLOODTYPE_O;
            break;
        case BloadTypeAB:
            bloodType = BLOODTYPE_AB;
            break;
        default:
            bloodType = BLOODTYPE_UNKNOWN;
            break;
    }
    return bloodType;
}

#pragma mark BloodGroupPopUp_Delegate
// 血液型の設定
- (void)OnBloodSetOK:(NSInteger)bloodType
{
    switch (bloodType) {
        case BLOODTYPE_A:
            [btnBloodType setTitle:@"A 型" forState:UIControlStateNormal];
            btnBloodType.tag = BloadTypeA;
            break;
        case BLOODTYPE_B:
            [btnBloodType setTitle:@"B 型" forState:UIControlStateNormal];
            btnBloodType.tag = BloadTypeB;
            break;
        case BLOODTYPE_O:
            [btnBloodType setTitle:@"O 型" forState:UIControlStateNormal];
            btnBloodType.tag = BloadTypeO;
            break;
        case BLOODTYPE_AB:
            [btnBloodType setTitle:@"AB 型" forState:UIControlStateNormal];
            btnBloodType.tag = BloadTypeAB;
            break;
        default:
            [btnBloodType setTitle:@"不 明" forState:UIControlStateNormal];
            btnBloodType.tag = BloadTypeUnKnown;
            break;
    }
}

// メモのキーボードを閉じるボタンのClickイベント(for iPhone)
- (IBAction)onMemoKeybordHide:(id)sender
{
    [txtViewMemo resignFirstResponder];
}

// 店舗名リストの表示ボタン
- (IBAction)onBtnShopSelectShow:(id)sender
{
    [txtFirstName resignFirstResponder];
    [txtSecondName resignFirstResponder];
    [txtFirstNameCana resignFirstResponder];
    [txtSecondNameCana resignFirstResponder];
    [txtUserRegistNumber resignFirstResponder];
    [txtSyumi resignFirstResponder];
    [txtViewMemo resignFirstResponder];


#ifdef CLOUD_SYNC

    if (popoverCntlSelectShop)
    {
        [popoverCntlSelectShop release];
        popoverCntlSelectShop = nil;
    }
    // 店舗対応のみ
    if (! [[ShopManager defaultManager] isAccountShop] )
    {   return; }
    ShopSelectPopup *shopSel
    = [[ShopSelectPopup alloc] initSingleSelectWithSelected:[self _getShopItemWithShopID:(editUser)?
                                                             editUser.shopID : [[ShopManager defaultManager] getAccountShopID]]
                                                    popUpID:USER_EDIT_POPUP_SELECT_SHOP
                                                   callBack:self];
    
    if (isJapanese) {
        [shopSel setLabel:@"登録店舗を選択してください"];
        shopSel.isJapanese = YES;
    } else {
        [shopSel setLabel:@"Please select register store"];
        shopSel.isJapanese = NO;
    }
    
#ifndef CALULU_IPHONE
    UIButton* shopSelectBtn = (UIButton*)sender;

    // ポップアップViewの表示
    popoverCntlSelectShop = 
    [[UIPopoverController alloc] initWithContentViewController:shopSel];
    shopSel.popoverController = popoverCntlSelectShop;
    
    [popoverCntlSelectShop presentPopoverFromRect:shopSelectBtn.bounds
                                           inView:shopSelectBtn
                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                         animated:YES];
    
    [popoverCntlSelectShop setPopoverContentSize:CGSizeMake(560.0f, 370.0f)];
#else
    
#endif
    
    [shopSel release];
#endif
}

/**
 * 郵便番号から住所に変換する
 */
- (IBAction)onBtnConvertPostal:(id)sender {
    if ([postal.text length]!=7 && [postal.text length]!=8) {
        [self alertViewSwow:@"正しい桁数の郵便番号を入力してください"];
        return;
    }
    
//    //get address from google maps API
//    NSString *strRequestParams = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?address=&components=postal_code:%@&sensor=false&language=ja",postal.text];
//
//    strRequestParams = [strRequestParams stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];
//
//    NSURL *url = [NSURL URLWithString:strRequestParams];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//
//    [request setHTTPMethod:@"GET"];
//
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
//        if (!error)
//        {
//            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//
//            if ([json[@"status"] isEqualToString:@"OK"]) {
//                NSArray *resultsArray = json[@"results"];
//                NSDictionary *resultsDictionary = resultsArray[0];
//                NSArray *addressComponents = resultsDictionary[@"address_components"];
//
//                //Declare variables to hold desired results
//                NSString *prefecture = @"";
//                NSString *city = @"";
//                NSString *subAdd1 = @"";
//                NSString *subAdd2 = @"";
//                NSString *finalString = @"";
//
//                //The address_components array contains many dictionaries,
//                //we loop through each dictionary and check the types array
//                for (NSDictionary *addressComponentDictionary in addressComponents) {
//                    NSArray *typesArray = addressComponentDictionary[@"types"];
//
//                    if ([typesArray[0] isEqualToString:@"administrative_area_level_1"]) {
//                        prefecture = addressComponentDictionary[@"long_name"];
//                    }
//                    if ([typesArray[0] isEqualToString:@"locality"]) {
//                        city = addressComponentDictionary[@"long_name"];
//                    }
//                    if ([typesArray[0] isEqualToString:@"political"]) {
//                        if ([typesArray[2] isEqualToString:@"sublocality_level_1"]) {
//                            subAdd1 = addressComponentDictionary[@"long_name"];
//                        }
//                        if ([typesArray[2] isEqualToString:@"sublocality_level_2"]) {
//                            subAdd2 = addressComponentDictionary[@"long_name"];
//                        }
//                    }
//                }
//
//                finalString = [NSString stringWithFormat:@"%@%@%@",city,subAdd1,subAdd2];
//                NSLog(@"%@",finalString);
//
//                btnPrefecture.tag = 1;
//                [self dispLabelPrefecture:prefecture];
//                adr2.text = finalString;
//            } else {
//                btnPrefecture.tag = 0;
//                [self dispLabelPrefecture:nil];
//                adr2.text = @"住所が見つかりません";
//            }
//        } else {
//            btnPrefecture.tag = 0;
//            [self dispLabelPrefecture:nil];
//            adr2.text = @"住所が見つかりません";
//        }
//    }];
    
    NSString *url = [NSString stringWithFormat:@"https://api.zipaddress.net/?zipcode=%@",postal.text];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:[NSURL
                                                      URLWithString:url]];
        NSLog(@"LatestURL:%@",data);
        NSError* error=nil;
        NSDictionary *jsonDict= [NSJSONSerialization JSONObjectWithData:data
                                                                options:kNilOptions error:&error];
        NSLog(@"JSON = %@", [[NSString alloc] initWithData:data encoding:
                             NSUTF8StringEncoding]);
        dispatch_async(dispatch_get_main_queue(), ^{
  
            NSNumber *code = [jsonDict valueForKey:@"code"];
            
            if ([code intValue] == 200) {
                NSDictionary *statuses=[jsonDict objectForKey:@"data"];
                NSLog(@"SomeStatus :%@",statuses);
                adr2.text = [statuses objectForKey:@"address"];
                btnPrefecture.tag = 1;
                [self dispLabelPrefecture:[statuses objectForKey:@"pref"]];
            } else {
                btnPrefecture.tag = 0;
                [self dispLabelPrefecture:nil];
                adr2.text = @"住所が見つかりません";
            }
        } );
    });
}

#pragma mark
#pragma mark Prefecture Set & Delegate
/**
 * 都道府県選択
 */
- (IBAction)onPrefectureSelect:(id)sender {
    // 設定された都道府県の取得
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *pref;
    
    if (btnPrefecture.tag==1) {
        pref = btnPrefecture.titleLabel.text;
    } else {
        pref = [ud stringForKey:@"lastSetPrefecture"];
    }

    //都道府県の設定ポップアップViewControllerのインスタンス生成
	PrefecturePopUp *vcPrefecturePicker
    = [[PrefecturePopUp alloc]initWithSetting:USER_SET_PREFECTURE_POPUP
                               lastPrefecture:pref
                                     callBack:self];
    
	// ポップアップViewの表示
	popCtlDatePicker = [[UIPopoverController alloc]
                        initWithContentViewController:vcPrefecturePicker];
	vcPrefecturePicker.popoverController = popCtlDatePicker;
    
    [popCtlDatePicker presentPopoverFromRect:btnPrefecture.bounds
                                      inView:btnPrefecture
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:NO];
    if ([vcPrefecturePicker respondsToSelector:@selector(setPreferredContentSize:)]) {
        [vcPrefecturePicker setPreferredContentSize:CGSizeMake(240.0f, 311.0f)];
    }
    
	[vcPrefecturePicker release];
    
    // キーボードが表示されていた場合に閉じる
    [self.view endEditing:YES];
}

- (IBAction)onCountrySelect:(id)sender
{
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    
    if (segCountry.selectedSegmentIndex==0) {
        isJapanese = YES;
        [df setValue:@"ja" forKey:@"CUSTOMER_COUNTRY"];
    } else {
        isJapanese = NO;
        [df setValue:@"en" forKey:@"CUSTOMER_COUNTRY"];
    }
    [df synchronize];
    
    [self setCountryView];
}

- (IBAction)onGenerChange:(id)sender {
    if (!isJapanese) {
        lblName.text = (segSex.selectedSegmentIndex==0)? @"Mr." : @"Ms.";
    }
}

/**
 * 都道府県の設定(PrefecturePopUp delegate)
 */
- (void)OnPrefectureSet:(NSString *)prefecture
{
    btnPrefecture.tag = 1;
    [self dispLabelPrefecture:prefecture];
    
    // 設定された都道府県の保存
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:prefecture forKey:@"lastSetPrefecture"];
    [ud synchronize];
}

/**
 * 都道府県の設定キャンセル(PrefecturePopUp delegate)
 */
- (void)OnPrefectureCancel
{
    // なにもしない
}

/**
 * 都道府県の表示
 */
- (void)dispLabelPrefecture:(NSString *)pref
{
//    btnPrefecture.titleLabel.text = pref;
    if (btnPrefecture.tag==0) {
        [btnPrefecture setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        
        [btnPrefecture setTitle:@"都道府県"
                       forState:UIControlStateNormal];
        txtPrefecture.placeholder = @"Prefecture";
    } else {
        [btnPrefecture setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btnPrefecture setTitle:pref
                       forState:UIControlStateNormal];
        txtPrefecture.text = pref;
    }
}

#pragma mark

// キャンセルボタンクリック
// 2012 6/25 伊藤 ポップアップの外をタップしてもポップアップを閉じない処理
// キャンセルの場合もデリゲートへ値を送り、操作負荷を解除する
- (IBAction) OnCancelButton:(id)sender
{
	if (delegate != nil) 
	{		
		// クライアントクラスへcallback
		[delegate OnPopUpViewSet:-1 setObject:nil];
	}	
	[self closeByPopoverContoller];
}

// e-mailの編集が終わった時によびだされる
- (IBAction) OnEmailEditingDidEnd:(id)sender
{
    lblEmailNotice.hidden = YES;
    // e-mailアドレスがある際には受信拒否設定が設定できる
    if ( [[emailText1 text] length] > 0 )
    {
        //Check 全角
        if (emailText1.text.isAllHalfWidthCharacter) {
            if ([self NSStringIsValidEmail:emailText1.text]) {
                // 全店共通ユーザの場合サーバ側に登録出来ないので、受信拒否設定ボタンを有効にしない
                if ([[ShopManager defaultManager] isAccountShop] && selectShopID==0) {
                    lblEmailNotice.hidden = NO;
                    if (isJapanese) {
                        lblEmailNotice.text = [NSString stringWithFormat:@"注意!! [%@]所属のユーザへはメール送信出来ません", lblShopName.text];
                    } else {
                        lblEmailNotice.text = [NSString stringWithFormat:@"!! You can't mail to group of [%@]", lblShopName.text];
                    }
                    [swMailBlock setEnabled:NO];
                } else {
                    [swMailBlock setEnabled:YES];
                }
            }
            else {
                lblEmailNotice.hidden = NO;
                if (isJapanese) {
                    lblEmailNotice.text = @"メールアドレスの形式が不正です";
                } else {
                    lblEmailNotice.text = @"Please enter a valid email address";
                }
            }
        } else {
            lblEmailNotice.hidden = NO;
            if (isJapanese) {
                lblEmailNotice.text = @"メールアドレスの形式が不正です";
            } else {
                lblEmailNotice.text = @"Please enter a valid email address";
            }
        }
    } else {
        [swMailBlock setEnabled:NO];
    }
}

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    NSString *emailRegex = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

#pragma mark PopUpViewContollerBaseDelegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
#ifdef CLOUD_SYNC
	NSMutableArray* tmpArray = [[NSMutableArray alloc]init ];
#endif
	switch (popUpID) 
	{
#ifdef CLOUD_SYNC
        case (NSUInteger)USER_EDIT_POPUP_SELECT_SHOP:
            // 店舗の選択
            [tmpArray addObjectsFromArray:(NSArray*)object];
            NSString* resultValue = [tmpArray objectAtIndex:0];
            NSInteger shopId = resultValue.intValue;
            ShopItem *item = [self _getShopItemWithShopID:shopId];

            selectShopID = item.shopID;
            lblShopName.text = item.shopName;
            txtShopName.text = item.shopName;
            break;
#endif
        case USER_SET_BIRTHDAY_POPUP:
            // 生年月日の設定
            if (birthDay) {
                [birthDay release];
            }
            birthDay = (NSDate *)object;
            [birthDay retain];
            btnBirthday.tag = 1;    // 生年月日が設定された
            [self dispLabelBirthday:birthDay];
            break;
		default:
			break;
	}
#ifdef CLOUD_SYNC
    [tmpArray removeAllObjects];
    [tmpArray release];
#endif
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
#ifndef CALULU_IPHONE
    return (YES);         // iPhoneのみ適用
#endif
    
    if (textField == txtSyumi)
    {
        // 趣味のTextFiledへコンテンツScrollViewをスクロール
        [self contentsScrollWithYpos:txtSyumi.frame.origin.y];
    }
    
    return (YES);
}

- (BOOL)textField:(UITextField *)textField 
			shouldChangeCharactersInRange:(NSRange)range 
						replacementString:(NSString *)string
{
#ifdef CALULU_IPHONE
    if (textField == txtSyumi)
    {   return (YES); }      // 趣味は無制限でOK
#endif
    
    // お客様番号専用:念のため
	if (textField != txtUserRegistNumber)
	{	return (NO); }
	
    // 数値入力TextFieldの入力文字種別と文字数を制限する
	return ([Common checkNumericInputTextLengh:textField inRange:range 
							  replacementString:string
									  maxLength:REGIST_NUMBER_LENGTH]);
}

#pragma mark UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	BOOL stat = NO;
    
    if (textView == txtViewMemo)
    {
        // メモTextViewへコンテンツScrollViewをスクロール
        [self contentsScrollWithYpos:txtViewMemo.frame.origin.y];
        // メモのキーボードを閉じるボタンを表示
        btnMemoKeybordHide.hidden = NO;
        
        stat = YES;
	}
	return (stat);
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	BOOL stat = NO;
    
    if (textView == txtViewMemo)
    {
        // メモのキーボードを閉じるボタンを非表示
        btnMemoKeybordHide.hidden = YES;
        
        stat = YES;
	}
	
	return (stat);
}

#pragma mark UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    // 列数を返す : いずれも１列とする
    return (1);
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
#ifdef CLOUD_SYNC
    
    // 店舗対応を確認
    if (! [[ShopManager defaultManager] isAccountShop])
    {   return (1); }
    
    // 行数を返す
    return (1);
#else
    return (1);
#endif
}

#pragma mark  UIPickerViewDelegate
#ifdef CLOUD_SYNC

-(NSString*)pickerView:(UIPickerView*)pickerView
           titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    ShopItem *item = [_shopItemList objectAtIndex:row];
    if (item)
    {   return (item.shopName); }
    else 
    {   return (@"(店舗名なし)"); }
}
#endif

- (void)pickerView:(UIPickerView *)pickerView 
      didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
#ifdef CLOUD_SYNC
    
    // 店舗対応を確認
    if (! [[ShopManager defaultManager] isAccountShop])
    {   return; }
#else
    return;
#endif
}


#pragma mark BlockMailStatus_Delegate
/**
 受信拒否設定の受信終了
 */
- (void) finishedBlockMailStatus:(USERID_INT)userId BlockStatus:(BOOL)blockStatus
{
	if ( [[emailText1 text] length] > 0 )
	{
#ifdef DEBUG
		NSLog( @"finishedBlockMailStatus user = %d, status = %d", userId, blockStatus );
#endif
		// 受信拒否セグメントの設定
        swMailBlock.on = ((blockStatus == NO) ? YES : NO);
	}
}


#pragma mark PopUpViewContollerBase_override

#pragma mark - override_methods
// delegate objectの設定:設定ボタンのclick時にsetDelegateObjectの前にコールされる
// NOを返すとイベントを中止する
//    remark : このメソッドにて設定値の検証を行い、ダイアログを表示する
//             デフォルトはYESを返す
- (BOOL) preProcessValidate
{
    // 名前部分がすべてASCII文字の場合、振り仮名部分に姓・名をそのままコピーする
    [self setPhonetic];

    if ([txtUserRegistNumber.text length] <= 0)
	{
		if ( (([txtFirstName.text length] <= 0) || ([txtFirstNameCana.text length] <= 0)) )
		{
			// 姓の入力は必須とする
			[self alertViewSwow:@"姓またはお客様番号は\n必ず入力してください"];
			return (NO);
		}
	}
	
	// 姓（かな）の先頭文字がひらがなであるかを確認
	if (! [self isCheckInputHiragana:txtFirstNameCana.text] )
	{
		[self alertViewSwow:@"姓（かな）の先頭は\n必ずひらがなで入力してください"];
		return (NO);
	}
    
    //Check Email Valid
//    if (swMailBlock.on ) {
//        if ([emailText1.text length] <= 0) {
//            [self alertViewSwow:@"メールアドレスを入力してください"];
//            return NO;
//        } else {
//            if(![self NSStringIsValidEmail:emailText1.text] || !emailText1.text.isAllHalfWidthCharacter) {
//                [self alertViewSwow:@"メールアドレスの形式が不正です"];
//                return NO;
//            }
//        }
//    }
    if ([emailText1.text length] <= 0) {
        return YES;
    } else {
        if (![self NSStringIsValidEmail:emailText1.text] || !emailText1.text.isAllHalfWidthCharacter) {
            [self alertViewSwow:@"メールアドレスは半角英数字で入力してください"];
            return NO;
        }
    }
    
    return (YES);
}

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	/* 
	 設定内容がOKの条件：お客様番号の入力の場合は全てOKとなる
	 姓		| 姓（かな）	| お客様番号	| 判定
	 -------+-----------+-----------+-------
	  ○		| ○			| ○(-)		| OK
	  ○		| ○			| ×			| OK
	  ○		| ×			| ○			| OK
	  ○		| ×			| ×			| NG
	  ×		| ○			| ○			| OK
	  ×		| ×			| ○			| OK
	  ×		| ○			| ×			| NG
	  ×		| ×			| ○			| OK
	  ×		| ×			| ×			| NG
	 */
    // 名前部分がすべてASCII文字の場合、振り仮名部分に姓・名をそのままコピーする
    [self setPhonetic];

#ifdef VER130_LATER
	if ([txtUserRegistNumber.text length] <= 0)
	{
		if ( (([txtFirstName.text length] <= 0) || ([txtFirstNameCana.text length] <= 0)) )
		{
			// 姓の入力は必須とする
			[self alertViewSwow:@"姓またはお客様番号は\n必ず入力してください"];
			return (nil);
		}
	}
	
	// 姓（かな）の先頭文字がひらがなであるかを確認
	if (! [self isCheckInputHiragana:txtFirstNameCana.text] )
	{
		[self alertViewSwow:@"姓（かな）の先頭は\n必ずひらがなで入力してください"];
		return (nil);
	}
#endif
	
	// 新規ユーザの場合は、ここでインスタンスを作成
	if (! self.editUser)
	{
		self.editUser 
			= [[mstUser alloc] initWithNewUser: txtFirstName.text 
									secondName:txtSecondName.text
                                    middleName:txtMidName.text
								 firstNameCana:txtFirstNameCana.text 
								secondNameCana:txtSecondNameCana.text
								  registNumber:txtUserRegistNumber.text		
										sex:(segSex.selectedSegmentIndex != 0)? Lady : Men];
	}
	else 
	{
		// コントロールの内容にてユーザ情報を更新する
		//////////////////////////////////////////////////

		editUser.firstNameCana = txtFirstNameCana.text;
		editUser.secondNameCana = txtSecondNameCana.text;
        editUser.middleName = txtMidName.text;
		editUser.firstName = txtFirstName.text;
		editUser.secondName = txtSecondName.text;
		editUser.registNumber = ([txtUserRegistNumber.text length] > 0)?
			[txtUserRegistNumber.text intValue] : REGIST_NUMBER_INVALID;
		editUser.sex = (segSex.selectedSegmentIndex != 0)?
					Lady : Men;
	}
    
    // 住所、電話番号の設定
    editUser.postal = postal.text;
    if (isJapanese) {
        editUser.adr1   = btnPrefecture.titleLabel.text;
    } else {
        editUser.adr1   = txtPrefecture.text;
    }
    editUser.adr2   = adr2.text;
    editUser.adr3   = adr3.text;
    editUser.adr4   = adr4.text;
    
    editUser.tel    = telephone.text;
    editUser.mobile = txtMobile.text;
	
	// 生年月日の設定
    if (btnBirthday.tag != 0) {
        editUser.birthDay = birthDay;
    } else {
        editUser.birthDay = nil;
    }
	
	// 血液型の設定
    editUser.bloadType = (BLOAD_TYPE)btnBloodType.tag;
	
	editUser.syumi = txtSyumi.text;
    
    //Email設定
    editUser.email1 = emailText1.text;
    editUser.email2 = emailText2.text;
    
	editUser.memo = txtViewMemo.text;

    // 受信拒否設定
    editUser.blockMail = !swMailBlock.on;

    // 2016/8/12 TMS 顧客情報に担当者を追加
    editUser.responsible = txtResponsible.text;
    
#ifdef CLOUD_SYNC
    if ( [[ShopManager defaultManager] isAccountShop])
    {   
        editUser.shopID = selectShopID;
        editUser.shopName = lblShopName.text;
    }
#endif
	return (editUser);
}

/**
 *　名前部分がすべてASCII文字の場合、振り仮名部分に姓・名をそのままコピーする
 */
- (void)setPhonetic
{
    if ([txtFirstNameCana.text length]<1) {
        NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:txtFirstName.text];
        NSCharacterSet *asciiWithoutSpaceCharacterSet = [NSCharacterSet characterSetWithRange:NSMakeRange(0x21, 0x5e)];
        // 入力文字がASCIIのみで構成されている時のみコピー
        if ([asciiWithoutSpaceCharacterSet isSupersetOfSet:stringCharacterSet]) {
            txtFirstNameCana.text = txtFirstName.text;
        }
    }
    if ([txtSecondNameCana.text length]<1) {
        NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:txtSecondName.text];
        NSCharacterSet *asciiWithoutSpaceCharacterSet = [NSCharacterSet characterSetWithRange:NSMakeRange(0x21, 0x5e)];
        // 入力文字がASCIIのみで構成されている時のみコピー
        if ([asciiWithoutSpaceCharacterSet isSupersetOfSet:stringCharacterSet]) {
            txtSecondNameCana.text = txtSecondName.text;
        }
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [btnCancel release];
    btnCancel = nil;
    [postal release];
    postal = nil;
    [btnConvPostal release];
    btnConvPostal = nil;
    [adr2 release];
    adr2 = nil;
    [btnBirthday release];
    btnBirthday = nil;
    [adr3 release];
    adr3 = nil;
    [telephone release];
    telephone = nil;
    [btnBloodType release];
    btnBloodType = nil;
    [swMailBlock release];
    swMailBlock = nil;
    [btnPrefecture release];
    btnPrefecture = nil;
    [adr4 release];
    adr4 = nil;
    [lblMailReject release];
    lblMailReject = nil;
    [segCountry release];
    segCountry = nil;
    [lblBloodType release];
    lblBloodType = nil;
    [lblName release];
    lblName = nil;
    [lblKana release];
    lblKana = nil;
    [lblSex release];
    lblSex = nil;
    [lblNameSuffix release];
    lblNameSuffix = nil;
    [lblUserRegistNumber release];
    lblUserRegistNumber = nil;
    [lblBirthday release];
    lblBirthday = nil;
    [lblAddress release];
    lblAddress = nil;
    [txtPrefecture release];
    txtPrefecture = nil;
    [lblTelephone release];
    lblTelephone = nil;
    [lblSyumi release];
    lblSyumi = nil;
    [lblMemo release];
    lblMemo = nil;
    [txtMidName release];
    txtMidName = nil;
    [vwRequired release];
    vwRequired = nil;
    [lblEmailNotice release];
    lblEmailNotice = nil;
    // 2016/8/12 TMS 顧客情報に担当者を追加
    [txtResponsible release];
    txtResponsible = nil;
    [lblResponsible release];
    lblResponsible = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    if (self.editUser)
    {
        self.editUser.birthDay = nil;
        self.editUser = nil;
    }
    popoverController.delegate = nil;
#ifdef CLOUD_SYNC
    [_shopItemList release];
#endif
[btnCancel release];
    [postal release];
    [btnConvPostal release];
    [adr2 release];
    [btnBirthday release];
    [adr3 release];
    [telephone release];
    [btnBloodType release];
    [swMailBlock release];
    [btnPrefecture release];
    [adr4 release];
    [lblMailReject release];
    [segCountry release];
    [lblBloodType release];
    [lblName release];
    [lblKana release];
    [lblSex release];
    [lblNameSuffix release];
    [lblUserRegistNumber release];
    [lblBirthday release];
    [lblAddress release];
    [txtPrefecture release];
    [lblTelephone release];
    [lblSyumi release];
    [lblMemo release];
    [txtMidName release];
    [vwRequired release];
    [lblEmailNotice release];
    // 2016/8/12 TMS 顧客情報に担当者を追加
    [txtResponsible release];
    [lblResponsible release];
    [imvCustomer release];
    [lblEmail release];
    [btnChangeAvatar release];
    [txtShopName release];
    [super dealloc];
}

@end
