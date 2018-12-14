//
//  AccountLoginPopUp.m
//  iPadCamera
//
//  Created by MacBook on 11/09/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AccountLoginPopUp.h"
#ifdef EASY_LOGIN
#import "AccountManager.h"
#import "defines.h"
#endif

#define BIG_SIZE    324.0f      // ショップログインpopup hight
#define SMALL_SIZE  205.0f      // ノーマルログインpopup hight
#define QRWIN_WIDTH 779.0f      // 簡単ログインpopup width
#define QRWIN_HIGHT 340.0f      // 簡単ログインpopup hight
#define QRSMALL_WIDTH 549.0f      // 簡単ログインsmall popup width

#define QRBTN_START     0       // かんたん登録ボタンTAG
#define QRBTN_RESTART   1

#ifdef EASY_LOGIN
#define NRWIN_WIDTH QRSMALL_WIDTH      // ノーマルログインpopup width
#else
#define NRWIN_WIDTH 385.0f      // ノーマルログインpopup width
#endif

///
/// アカウントログインポップアップViewControllerクラス
///
@implementation AccountLoginPopUp

@synthesize myDelegate;     // ポップアップクローズ時の処理を行うため

#ifdef EASY_LOGIN
@synthesize capture;    // QRコードスキャン用
#define QR_MESSAGE  @"赤枠内に QRコード が表示される状態にして\n「かんたん登録開始」をタップしてください。"
#endif

#pragma mark life_cycle

- (id) initWithPopUpViewContoller:(NSUInteger)popUpID 
				popOverController:(UIPopoverController*)controller 
						 callBack:(id)callBackDelegate
{
#ifdef CALULU_IPHONE
	if ((self = [super initWithPopUpViewContoller:popUpID
								popOverController:controller 
										 callBack:callBackDelegate 
                                          nibName:@"ip_AccountLoginPopUp"] ) )
    {
        // nothing to do.
    }
#else
#ifndef CLOUD_SYNC
    if ((self = [super initWithPopUpViewContoller:popUpID
                                popOverController:controller 
                                         callBack:callBackDelegate] ) )
	{
		self.contentSizeForViewInPopover = CGSizeMake(380.0f, 226.0f);
        _isShopSupport = NO;
	}
#else

#if AIKI_CUSTOM || BRANCHE_CUSTOM || NEWS_CUSTOM || DEF_CALULU1 // AIKI, BRANCHE, NEWS, Calulu1 バージョンは店舗IDの指定なし
    NSString *nibName = @"AccountLoginPopUp";
    CGFloat height = 226.0f;
    CGFloat width = NRWIN_WIDTH;
#elif EASY_LOGIN
    NSString *nibName = @"AccountLoginWithQRPopUp";
    CGFloat height = QRWIN_HIGHT;
    CGFloat width = QRWIN_WIDTH;
#else
    NSString *nibName = @"AccountLoginWithShopPopUp";
    CGFloat height = SMALL_SIZE;
    CGFloat width = NRWIN_WIDTH;
#endif // AIKI_CUSTOM || BRANCHE_CUSTOM || NEWS_CUSTOM || DEF_CALULU1
    
    if ((self = [super initWithPopUpViewContoller:popUpID
                                popOverController:controller
                                         callBack:callBackDelegate
                                          nibName:nibName] ) )
    {
        [self changeFrameSize:height width:width];
        _isShopSupport = YES;
        myDelegate = nil;
    }
#endif // #ifndef CLOUD_SYNC
#endif // #ifdef CALULU_IPHONE
	return (self);
}

// ポップアップのフレームサイズ変更
- (void)changeFrameSize:(CGFloat)height width:(CGFloat)width
{
    if ([self respondsToSelector:@selector(setPreferredContentSize:)]) {
        [self setPreferredContentSize:CGSizeMake(width, height)];
    } else {
        self.contentSizeForViewInPopover = CGSizeMake(width, height);
    }
#ifdef EASY_LOGIN
    if (isEasyLogin) {
        if (isQRLogin) {
            cameraRectView.hidden = NO;
            //btnCancel.hidden = YES;
            btnOption.hidden = YES;

            [btnLoginStyle setTitle:@"通常登録にする" forState:UIControlStateNormal];
        } else {
            cameraRectView.hidden = YES;
            btnCancel.hidden = NO;
            btnOption.hidden = NO;

            [btnLoginStyle setTitle:@"かんたん登録にする" forState:UIControlStateNormal];
            [self.capture stop];
        }
    }
#endif  // EASY_LOGIN
}

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
	
	// titleの角を丸める
	[Common cornerRadius4Control:IDlblTitle];
    [Common cornerRadius4Control:QRlblTitle];
	
	txtAccountID.tag = 1;
	txtPassword.tag = 2;
    txtShopID.tag = 3;
    txtShopPassword.tag = 4;

    [btnOK setBackgroundColor:[UIColor whiteColor]];
    [[btnOK layer] setCornerRadius:6.0];
    [btnOK setClipsToBounds:YES];
    [[btnOK layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnOK layer] setBorderWidth:1.0];
    
    [btnCancel setBackgroundColor:[UIColor whiteColor]];
    [[btnCancel layer] setCornerRadius:6.0];
    [btnCancel setClipsToBounds:YES];
    [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.863 green:0.078 blue:0.235 alpha:1.0] CGColor]];
    [[btnCancel layer] setBorderWidth:1.0];
    
    [btnOption setBackgroundColor:[UIColor whiteColor]];
    [[btnOption layer] setCornerRadius:6.0];
    [btnOption setClipsToBounds:YES];
    [[btnOption layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnOption layer] setBorderWidth:1.0];
    
    txtAccountID.keyboardType   = UIKeyboardTypeAlphabet;
    txtPassword.keyboardType    = UIKeyboardTypeAlphabet;
    txtShopID.keyboardType      = UIKeyboardTypeAlphabet;
    txtShopPassword.keyboardType = UIKeyboardTypeAlphabet;
#ifdef EASY_LOGIN
    isEasyLogin = YES;      // かんたん登録
    isQRLogin = YES;
    self.capture = [[ZXCapture alloc] init];
    self.capture.camera = self.capture.back;
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.rotation = 90.0f;

    [[cameraRectView layer] setCornerRadius:6.0];

    [[scanRectView layer] setCornerRadius:6.0];
    [scanRectView setClipsToBounds:YES];
    [[scanRectView layer] setBorderColor:[[UIColor colorWithRed:0.863 green:0.078 blue:0.235 alpha:1.0] CGColor]];
    [[scanRectView layer] setBorderWidth:1.0];

//    [btnQRstart setBackgroundColor:[UIColor whiteColor]];
//    [[btnQRstart layer] setCornerRadius:6.0];
//    [btnQRstart setClipsToBounds:YES];
//    [[btnQRstart layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
//    [[btnQRstart layer] setBorderWidth:1.0];

    [btnLoginStyle setBackgroundColor:[UIColor whiteColor]];
    [[btnLoginStyle layer] setCornerRadius:6.0];
    [btnLoginStyle setClipsToBounds:YES];
    [[btnLoginStyle layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnLoginStyle layer] setBorderWidth:1.0];

    self.capture.layer.frame = cameraRectView.bounds;
    [cameraRectView.layer addSublayer:self.capture.layer];

    [cameraRectView bringSubviewToFront:scanRectView];
    [cameraRectView bringSubviewToFront:decodedLabel];
    [cameraRectView bringSubviewToFront:btnQRstart];
    
    btnOption.hidden    = YES;
    btnOK.hidden        = NO;
    //btnCancel.hidden    = YES;
    
    btnOK.enabled       = NO;
    
    accID = NULL;
    accPWD = NULL;
    shopID = NULL;
    shopPWD = NULL;
    PreCheckResult = -1;
    
    [decodedLabel setText:QR_MESSAGE];
    btnQRstart.tag = QRBTN_START;
    
    isQRanalysis = NO;
#else
    isEasyLogin = NO;       // 通常登録
    isQRLogin = NO;
#endif
}

#ifndef EASY_LOGIN
//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    
////    self.capture.delegate = self;
//    self.capture.layer.frame = cameraRectView.bounds;
//    
//    CGAffineTransform captureSizeTransform = CGAffineTransformMakeScale(320 / cameraRectView.frame.size.width, 480 / cameraRectView.frame.size.height);
//    self.capture.scanRect = CGRectApplyAffineTransform(scanRectView.frame, captureSizeTransform);
//}
#endif

- (void)viewDidAppear:(BOOL)animated
{
    if (!isEasyLogin) {
        // キーボードの表示
        [txtAccountID becomeFirstResponder];
    } else {
        
    }
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
    [btnCancel release];
    btnCancel = nil;
    [btnOption release];
    btnOption = nil;
    [lblShopID release];
    lblShopID = nil;
    [lblShopPWD release];
    lblShopPWD = nil;
    [lblDocument release];
    lblDocument = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    
	[QRlblTitle release];
    [IDlblTitle release];
	[txtAccountID release];
	[txtPassword release];
    [txtShopID release];
    [txtShopPassword release];
	[btnOK release];
	
    [btnCancel release];
    [btnOption release];
    [lblShopID release];
    [lblShopPWD release];
    [lblDocument release];
#ifdef EASY_LOGIN
    [scanRectView release];
    [decodedLabel release];
    [btnQRstart release];
    [btnLoginStyle release];
    [cameraRectView release];
#endif
    [lblTitle release];
    [super dealloc];
}

#pragma mark text_field_events

// 編集開始
// - (IBOutlet) onTextEditBegin:(id)sender;

// 文字列変更 
- (IBAction) onChangeText:(id)sender
{
	// １文字でも入力されればOKボタンを有効にする
	btnOK.enabled 
		=  ( ([txtAccountID.text length] > 0) &&
			 ([txtPassword.text length] > 0) );
}

// 編集終了
- (IBAction) onTextDidEnd:(id)sender
{
	
}

// リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender
{
	NSInteger txtTag = ((UITextField*)sender).tag;
    
    // if ( ((UITextField*)sender).tag  == 1 )
    switch (txtTag) {
        // アカウントID
        case 1:
			[txtPassword becomeFirstResponder];
            break;
        // パスワード
        case 2:
            if (! _isShopSupport) {
                // キーボードを閉じる
                [ ((UITextField*)sender) resignFirstResponder];
                
                // OKボタンの押下と同様とする
                if ( btnOK.enabled)
                {
                    [self OnSetButton:btnOK];
                }
            }
            else {
                [txtShopID becomeFirstResponder];
            }
            break;
        // 店舗ID
        case 3:
            [txtShopPassword becomeFirstResponder];
            break;
        // 店舗パスワード
        case 4:
        default:
            // キーボードを閉じる
            [ ((UITextField*)sender) resignFirstResponder];
            
            // OKボタンの押下と同様とする
            if ( btnOK.enabled)
            {
                [self OnSetButton:btnOK];
            }
	}
}

// 店舗オプションボタン押下時
- (IBAction)onOption:(id)sender
{
    if (btnOption.tag==0) {
        // 店舗階層オプション表示
        [self changeFrameSize:BIG_SIZE width:NRWIN_WIDTH];
        btnOption.tag = 1;
        lblShopID.hidden = NO;
        txtShopID.hidden = NO;
        lblShopPWD.hidden = NO;
        txtShopPassword.hidden = NO;
        lblDocument.hidden = NO;
    } else {
        // 店舗階層オプション非表示
        [self changeFrameSize:SMALL_SIZE width:NRWIN_WIDTH];
        btnOption.tag = 0;
        lblShopID.hidden = YES;
        txtShopID.hidden = YES;
        lblShopPWD.hidden = YES;
        txtShopPassword.hidden = YES;
        lblDocument.hidden = YES;
    }
}

#ifdef EASY_LOGIN
// かんたん登録開始
- (IBAction)onQrReadStart:(id)sender {
    if (btnQRstart.tag == QRBTN_START) {
        if (self.capture == nil) {
            self.capture = [[ZXCapture alloc] init];
        }
        self.capture.camera = self.capture.back;
        self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        self.capture.rotation = 90.0f;
        
        self.capture.layer.frame = cameraRectView.bounds;
        [cameraRectView.layer addSublayer:self.capture.layer];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.capture.delegate = self;
            //    self.capture.layer.frame = cameraRectView.bounds;
            
            CGAffineTransform captureSizeTransform = CGAffineTransformMakeScale(320 / cameraRectView.frame.size.width, 480 / cameraRectView.frame.size.height);
            self.capture.scanRect = CGRectApplyAffineTransform(scanRectView.frame, captureSizeTransform);
            [self.capture start];
        });
    } else {
        [self ZXCaptureRestart];
        btnQRstart.tag = QRBTN_START;
        [btnQRstart setTitle:@"かんたん登録開始" forState:UIControlStateNormal];
    }
    
    // QRコードリード開始時に、クリアする
    txtAccountID.text = NULL;
    txtPassword.text = NULL;
    txtShopID.text = NULL;
    txtShopPassword.text = NULL;
    decodedLabel.text = NULL;

    [cameraRectView bringSubviewToFront:scanRectView];
    [cameraRectView bringSubviewToFront:decodedLabel];
    [cameraRectView bringSubviewToFront:btnQRstart];
    [decodedLabel setText:QR_MESSAGE];

    [self onChangeText:NULL];
}

// 登録スタイルの変更 かんたん <==> 通常
- (IBAction)onChageLoginStyle:(id)sender {
    isQRLogin = !isQRLogin;
    
    if (isQRLogin) {
        [self changeFrameSize:QRWIN_HIGHT width:QRWIN_WIDTH];
        [decodedLabel setText:QR_MESSAGE];
    } else {
        if (btnOption.tag==0) {
            // 店舗階層オプション非表示
            [self changeFrameSize:SMALL_SIZE width:QRSMALL_WIDTH];
            lblShopID.hidden = YES;
            txtShopID.hidden = YES;
            lblShopPWD.hidden = YES;
            txtShopPassword.hidden = YES;
            lblDocument.hidden = YES;
        } else {
            // 店舗階層オプション表示
            [self changeFrameSize:BIG_SIZE width:QRSMALL_WIDTH];
            lblShopID.hidden = NO;
            txtShopID.hidden = NO;
            lblShopPWD.hidden = NO;
            txtShopPassword.hidden = NO;
            lblDocument.hidden = NO;
        }
        [decodedLabel setText:NULL];
    }
}
#endif // EASY_LOGIN

// キャンセルボタンを押した場合
- (void)OnCancelButton:(id)sender
{
    //2016/4/18 TMS 取消ボタン押下時の処理を変更　現状はポップアップを消しているが、ポップアップはそのままで入力値をクリア
    txtAccountID.text = @"";
    txtPassword.text = @"";
    txtShopID.text = @"";
    txtShopPassword.text = @"";
    btnOK.enabled       = NO;
   //[super OnCancelButton:sender];
    [self closeProcess];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
    // 2015/12/22 TMS 初回起動時ログイン必須対応
    //[self closeProcess];
    return;
}

// ポップアップの枠外を押した場合にここにくる
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self closeProcess];
    return;
}

// 2015/12/22 TMS 初回起動時ログイン必須対応
- (BOOL)popoverControllerShouldDismissPopover: popoverController{
    return NO;
}

// ポップアップクローズ時の処理を呼び出す
- (void)closeProcess
{
    // 2015/12/22 TMS 初回起動時ログイン必須対応
    //if (myDelegate) {
     //   [myDelegate closeAccountLoginPopUp];
    //}
}

#pragma mark override

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	// アカウントIDとパスワード入力された文字を返す
	NSArray *arr = (! _isShopSupport)?
        [NSArray arrayWithObjects:txtAccountID.text, txtPassword.text, nil] :
        [NSArray arrayWithObjects:txtAccountID.text, txtPassword.text, 
                                    txtShopID.text, txtShopPassword.text, nil];
    
    // アカウントログイン処理が走っているはずなので、ポップアップクローズ処理を後回しにさせる為
    dispatch_async(dispatch_get_main_queue(), ^{
        [myDelegate closeAccountLoginPopUp];
    });
	
	return (arr);
}

#pragma mark - Private Methods

#ifdef EASY_LOGIN
- (void)checkAccountValidity
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif

    AccountManager *actMng = [[AccountManager alloc]initWithServerHostName:ACCOUNT_HOST_URL];
    
    NSData *data;

    ACCOUNT_RESPONSE response = [actMng checkAccountValidity:accID
                                             accountPassWord:accPWD
                                                      shopID:shopID
                                                shopPassWord:shopPWD
                                                 accountType:accTYPE
                                                    respData:&data];
    
    if (response == ACCOUNT_RSP_SUCCESS) {
        
    }
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
}

// QRで読み込んだデータのフォーマットチェック
//
// 固定文字列,アカウントタイプ,アカウントID,アカウントパスワード,ショップID,ショップパスワード
// abcarte,shop,treetest-01,abcd1234,20001001,abcd1234
//
- (BOOL)checkQRreadString:(NSString*)contents
{
    NSString *qrtype = NULL;
    NSArray *parser = [contents componentsSeparatedByString:@","];
    
    if (parser.count == 4)
    {
        qrtype  = [parser objectAtIndex:0];
        accTYPE = [parser objectAtIndex:1];
        accID   = [parser objectAtIndex:2];
        accPWD  = [parser objectAtIndex:3];
        shopID  = NULL;
        shopPWD = NULL;
    }
    else if (parser.count == 6)
    {
        qrtype  = [parser objectAtIndex:0];
        accTYPE = [parser objectAtIndex:1];
        accID   = [parser objectAtIndex:2];
        accPWD  = [parser objectAtIndex:3];
        shopID  = [parser objectAtIndex:4];
        shopPWD = [parser objectAtIndex:5];
    }

    if ([qrtype isEqualToString:@"abcarte"])
        return YES;
    else
        return NO;
}

- (void)ZXCaptureRestart
{
    // QRコードリード開始時に、クリアする
    txtAccountID.text = NULL;
    txtPassword.text = NULL;
    txtShopID.text = NULL;
    txtShopPassword.text = NULL;
//    decodedLabel.text = NULL;

    isQRanalysis = NO;
    
    self.capture.delegate = NULL;
    self.capture = nil;
    self.capture = [[ZXCapture alloc] init];
    self.capture.camera = self.capture.back;
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.rotation = 90.0f;
    self.capture.layer.frame = cameraRectView.bounds;
    CGAffineTransform captureSizeTransform = CGAffineTransformMakeScale(320 / cameraRectView.frame.size.width, 480 / cameraRectView.frame.size.height);
    self.capture.scanRect = CGRectApplyAffineTransform(scanRectView.frame, captureSizeTransform);
    [cameraRectView.layer addSublayer:self.capture.layer];
    [cameraRectView bringSubviewToFront:scanRectView];
    [cameraRectView bringSubviewToFront:decodedLabel];
    [cameraRectView bringSubviewToFront:btnQRstart];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.capture start];
//    });
}

#pragma mark - ZXCaptureDelegate Methods

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
    if (!result) return;
    
    if (isQRanalysis) return;
    
    isQRanalysis = YES;
    
    // Vibrate
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

    [self.capture stop];
    
    if (![self checkQRreadString:result.text])
    {
        [decodedLabel setText:@"登録用のQRコードではありません。\n正しい登録用コードを用意して再度撮影をお願いします。"];
        // QR読み取りに失敗した場合、またはアカウント登録用QRでなかった場合に再度QR読み取りを立ち上げる
        [self ZXCaptureRestart];
        btnQRstart.tag = QRBTN_START;
    }
    else
    {
        // ログイン前チェック
        [self checkAccountValidity];
    }
}

#pragma mark - XML_parse_section

/**
 // 通常アカウントの場合
 <account_check result="0">
 <value accID="xtest-005C" company="お客様デモ用"/>
 </account_check>
 
 // ショップアカウントの場合
 <account_check result="0">
 <value accID="treetest-02" company="グループ試験" shopID="2001002" shopPWD="abcd1234"/>
 </account_check>
 
 // エラーの場合
 <account_check result="1">
 <message er="登録内容が異なります（ショップアカウント）"/>
 </account_check>
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict
{
#ifdef DEBUG
    NSLog(@"parse <%@> 開始", elementName);
    for (id key in attributeDict) {
        NSLog(@"%@=%@", key, [attributeDict objectForKey:key]);
    }
#endif
    
    // 結果の取得
    if ([elementName isEqualToString:@"account_check"]) {
        NSString *result = [attributeDict objectForKey:@"result"];
        // 結果コードの取得
        PreCheckResult = [result integerValue];
    }
    
    // アカウント名称 ショップ名称の取得
    if ([elementName isEqualToString:@"value"]) {
        accountName = [[attributeDict objectForKey:@"company"] copy];
        shopName    = [[attributeDict objectForKey:@"shopName"] copy];
    }
    
    // エラーメッセージの取得
    if ([elementName isEqualToString:@"message"]) {
        errMsg0     = [[attributeDict objectForKey:@"er0"] copy];
        errMsg1     = [[attributeDict objectForKey:@"er1"] copy];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog (@"parseErrorOccurred:%@", parseError);
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError {
    NSLog (@"validationErrorOccurred:%@", validationError);
}

// XMLデコード終了処理
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    NSString *display;
    
    // ログイン前チェックが正常終了した場合
    if (PreCheckResult == 0) {
        txtAccountID.text = accID;
        txtPassword.text = accPWD;
        txtShopID.text = shopID;
        txtShopPassword.text = shopPWD;
        
        if ([accTYPE isEqualToString:@"shop"]) {
            display = [NSString stringWithFormat:@"アカウント名 : %@\nショップ名　 : %@\nで登録してよろしければOKボタンを\nタップしてください。",
                       accountName, shopName];
        }
        else
        {
            display = [NSString stringWithFormat:@"アカウント名 : %@\nで登録してよろしければOKボタンを\nタップしてください。",
                       accountName];
        }
        [btnQRstart setTitle:@"かんたん登録 再試行" forState:UIControlStateNormal];
        btnQRstart.tag = QRBTN_RESTART;
        [self onChangeText:NULL];
    }
    // ログイン前チェックでエラーが発生した場合
    else
    {
        display = [NSString stringWithFormat:@"%@\n%@", errMsg0, errMsg1];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self ZXCaptureRestart];
            btnQRstart.tag = QRBTN_START;
        });
    }
    [decodedLabel setText:display];
}
#endif  // EASY_LOGIN

#pragma mark public_methods


@end
