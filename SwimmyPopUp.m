 //
//  SwimmyPopUp.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/03/19.
//
//

#import "SwimmyPopUp.h"
#import <MailCore.h>

#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"
#import "OKDThumbnailItemView.h"
#import "OKDImageFileManager.h"
#import "Common.h"

#define ACCOUNT_ID_SAVE_KEY		@"accountIDSave"		// アカウントIDの保存用Key
// サムネイルitemの幅
#define ITEM_WITH	128.0f
// サムネイルitemの高さ -> サムネイル=96 ＋　タイトル高さ=10
#define ITEM_HEIGHT	106.0f

@interface SwimmyPopUp ()

@end

@implementation SwimmyPopUp

@synthesize selectUserID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // ユーザマスタの取得
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	mstUser *user = [usrDbMng getMstUserByID:self.selectUserID];
    
    self.sexSegmentCtrl.selectedSegmentIndex = (user.sex==Men)? 0 : 1;                      // 性別設定
    [btnSetAge setTitle:[NSString stringWithFormat:@"%d",([self calcAge:user] / 10) * 10]   // 年齢設定
               forState:UIControlStateNormal];
	
	// 施術内容一覧の取得
	NSMutableArray *_histUserItems = [usrDbMng getUserWorkItemsByID:self.selectUserID];
    
    self.treatmentField.text = [NSString stringWithFormat:@"%ld", (long)_histUserItems.count];  // 施行回数
    
	// タイトルの角を丸める
	[Common cornerRadius4Control:lblTitle];

    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=7.0) {
        NSArray *arr = @[btnSetAge, _sexSegmentCtrl, _MailSend, btnCancel];
        for (id parts in arr) {
            [parts setBackgroundColor:[UIColor whiteColor]];
            [[parts layer] setCornerRadius:6.0];
            [parts setClipsToBounds:YES];
            [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
            [[parts layer] setBorderWidth:1.0];
        }
    }
    
    _imageLabel2.userInteractionEnabled = YES;
    _imageLabel2.tag = 100;
    imageLabel3.userInteractionEnabled = YES;
    imageLabel3.tag = 101;
    lblBeforeView.userInteractionEnabled = YES;
    lblBeforeView.tag = 200;
    lblAfterView.userInteractionEnabled = YES;
    lblAfterView.tag = 201;
    
    _treatmentField.keyboardType    = UIKeyboardTypeNumberPad;
    _beforeTreatField.keyboardType  = UIKeyboardTypeNumberPad;
    _afterTreatField.keyboardType   = UIKeyboardTypeNumberPad;
    
    _treatmentField.delegate = self;
    _beforeTreatField.delegate = self;
    _afterTreatField.delegate = self;
    
    vcSelSwimmy = nil;
    vcSetAge = nil;
    
    [usrDbMng release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // キーボード表示・非表示の通知の登録
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    lockFlag = NO;
    
    UIScrollView *selScrollView;
    UITextField *selTextField;
    //画像があればスクロールビューに設定
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID: selectUserID];

    // ユーザマスタの取得
	userDbManager *usrDbMng = [[userDbManager alloc] init];
    // 施術内容一覧の取得
    // IDによる施術内容一覧の取得
    NSMutableArray *_histUserItems = [usrDbMng getUserWorkItemsByID:self.selectUserID];

    // 施術前・後の画像設定
    for (int i = 0; i < 2; i++) {
        OKDThumbnailItemView *thumView = [selectImageArray objectAtIndex:i];
        UIImage *pictimage = ([[thumView getFileName] isEqualToString:@"noimage.png"])? [UIImage imageNamed:@"noimage.png"]
        :[thumView getRealSizeImage:imgFileMng];
        UIImage *resizeImage = [self resizedImage:pictimage size:CGSizeMake(240, 180)];
        switch (i) {
            case 0:
                selScrollView = self.myScrollView;
                selTextField  = self.beforeTreatField;
                break;
            case 1:
                selScrollView = self.myScrollView2;
                selTextField  = self.afterTreatField;
            default:
                break;
        }
        //各画像の位置を指定
        CGPoint drawPoint = CGPointMake(0, 0);
        
        //画像を張るビュー設定
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(drawPoint.x,drawPoint.y, resizeImage.size.width, resizeImage.size.height)];
        imageView.image = resizeImage;
        [selScrollView addSubview:imageView];
        [imageView release];
        
        NSInteger j;
        // Document以下のファイル名に変換
        NSString *documentFileName =
        [imgFileMng getDocumentFolderFilename:[thumView getFileName]];
        // ファイル名よりhist_idの取得
        NSInteger _histid = [usrDbMng getHistIDByPictURL4PictTable:documentFileName];
        // 何回目の施術画像か検索
        for (j=0; j<_histUserItems.count; j++) {
            fcUserWorkItem *selectedWorkItem = [_histUserItems objectAtIndex:j];
            if (_histid==selectedWorkItem.histID) {
                break;
            }
        }
        selTextField.text = [NSString stringWithFormat:@"%ld", (long)(_histUserItems.count - j)];   // 施行回数
    }
    [imgFileMng release];
    [usrDbMng release];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 初期化
- (id) initWithSwimmySetting:(NSMutableArray *)pictImageItems
                selectUserID:(USERID_INT)userID
                     popUpID:(NSUInteger)popUpID
                isNavigation:(BOOL)isNavigation
                   superView:(id)superView
                    callBack:(id)callBack
{
    if(self = [super initWithPopUpViewContoller:popUpID popOverController:nil callBack:callBack nibName:@"SwimmyPopUp"]) {

        self.contentSizeForViewInPopover = CGSizeMake(588.0f, 622.0f);

        self.selectUserID = userID;
        isNavigationCall = isNavigation;
        tempView = superView;

        // 画像が選択されていない場合のために、ダミー表示を設定
        // サムネイルViewの作成
        OKDThumbnailItemView *thumbnailView
        = [[[OKDThumbnailItemView alloc] initWithFrame:
            CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)] autorelease];
        [thumbnailView setFileName:@"noimage.png"];
        
        selectImageArray = [[NSMutableArray alloc]init];
        [selectImageArray addObject:thumbnailView];
        [selectImageArray addObject:thumbnailView];
        
        //添付画像配列を一時保存
        if ([pictImageItems count]>0) {
            for (int i=0; i<[pictImageItems count]; i++) {
                [selectImageArray replaceObjectAtIndex:i withObject:[pictImageItems objectAtIndex:i]];
            }
        }

    }
    return self;
}

- (void)dealloc {
    [_myScrollView release];
    [_imageLabel2 release];
    [_MailSend release];
    [_imageLabel1 release];
    [_sexLabel release];
    [_sexSegmentCtrl release];
    [_treatmentLabel release];
    [_treatmentField release];
    [_treatmentCntLabel release];
    [_emailText release];
    [_treatmentNo1 release];
    [_treatmentNo2 release];
    [_treatmentNo3 release];
    [_treatmentNo4 release];
    [_myScrollView2 release];
    [btnSetAge release];
    [imageLabel3 release];
    [btnCancel release];
    [lblTitle release];
    [lblBeforeView release];
    [lblAfterView release];
    [_beforeTreatField release];
    [_afterTreatField release];
    if(selectImageArray) {
        [selectImageArray removeAllObjects];
        [selectImageArray release];
    }
    [super dealloc];
}
- (void)viewDidUnload {
    [self setMyScrollView:nil];
    [self setImageLabel2:nil];
    [self setMailSend:nil];
    [self setImageLabel1:nil];
    [self setSexLabel:nil];
    [self setSexSegmentCtrl:nil];
    [self setTreatmentLabel:nil];
    [self setTreatmentField:nil];
    [self setTreatmentCntLabel:nil];
    [self setEmailText:nil];
    [self setTreatmentNo1:nil];
    [self setTreatmentNo2:nil];
    [self setTreatmentNo3:nil];
    [self setTreatmentNo4:nil];
    [self setMyScrollView2:nil];
    [btnSetAge release];
    btnSetAge = nil;
    [imageLabel3 release];
    imageLabel3 = nil;
    [btnCancel release];
    btnCancel = nil;
    [lblTitle release];
    lblTitle = nil;
    [lblBeforeView release];
    lblBeforeView = nil;
    [lblAfterView release];
    lblAfterView = nil;
    [self setBeforeTreatField:nil];
    [self setAfterTreatField:nil];
    [super viewDidUnload];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    switch (touch.view.tag) {
        case 100:       // 施術前
        case 200:
            [self OnSetComparePicture:YES];
            break;
        case 101:       // 施術後
        case 201:
            [self OnSetComparePicture:NO];
            break;
            
        default:
            break;
    }
}

// 施術前画像選択ボタン
- (IBAction)OnBefore:(id)sender {
    [self OnSetComparePicture:YES];
}

// 施術後画像選択ボタン
- (IBAction)OnAfter:(id)sender {
    [self OnSetComparePicture:NO];
}


#pragma mark -
#pragma mark 操作処理
- (IBAction)OnCancelBtn:(id)sender {
    
    [delegate OnPopUpViewSet:-1 setObject:nil];
    
    if (vcSelSwimmy) {
        [vcSelSwimmy OnCancelButton:nil];
    }
    if (vcSetAge) {
        [vcSetAge OnCancelButton:nil];
    }
    
    [self closeByPopoverContoller];
}

- (IBAction)doMailsend:(id)sender {
    [self callMailSendTask];
}

//メール送信処理
- (void)callMailSendTask
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    // 顧客登録情報
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *accID  = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
    //送信に必要な値を取得
    NSString *senderAddr = @"";
    NSString *smtpServer = @"";
    NSString *smtpUser = @"";
    NSString *smtpPass = @"";
    NSInteger smtpPort = 0;
    NSInteger smtpType = 0;
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *infoBeanArray = [manager selectMailSmtpInfo:1];
    if([infoBeanArray count] != 0){
        mstUserMailItemBean *bean = [infoBeanArray objectAtIndex:0];
        senderAddr = bean.sender_addr;
        smtpServer = bean.smtp_server;
        smtpUser = bean.smtp_user;
        smtpPass = bean.smtp_pass;
        smtpPort = bean.smtp_port;
        smtpType = bean.smtp_auth;
    }
    [manager release];
    
#ifdef DEBUG
    NSString *sendMailAddr = @"nishijima@okada.co.jp";
    NSLog(@"%@", sendMailAddr);
#else
    NSString *sendMailAddr = @"swimmy@calulu4bmk.jp";
#endif

    NSString *mailBody = [NSString
                          stringWithFormat:@"アカウントID,%@\n年齢,%@\n性別,%@\n総施行回数,%d\n施術前回数,%d\n施術後回数,%d\n美健,%d\n美骨,%d\n美脚,%d\nその他,%d\n備考,%@",
                          accID,
                          btnSetAge.titleLabel.text,
                          (self.sexSegmentCtrl.selectedSegmentIndex==0)? @"男性" : @"女性",
                          self.treatmentField.text.intValue,
                          self.beforeTreatField.text.intValue,
                          self.afterTreatField.text.intValue,
                          self.treatmentNo1.on,
                          self.treatmentNo2.on,
                          self.treatmentNo3.on,
                          self.treatmentNo4.on,
                          self.emailText.text];

    // 2byte文字対策：メールsubjectの JIS化 -> BASE64encode -> subjectフォーマット
//    NSString *mailTitle = [NSString stringWithFormat:@"%@%@%@", @"=?ISO-2022-JP?B?", [self base64EncodeString:self.emailTitle.text], @"?="];
    NSString *mailTitle = [NSString stringWithFormat:@"Swimmy[%@]", accID];
    
    //メール設定
    CTCoreMessage *mailMsg = [[CTCoreMessage alloc] init];
    [mailMsg setTo:[NSSet setWithObject:[CTCoreAddress addressWithName:@" " email:sendMailAddr]]];
    [mailMsg setFrom:[NSSet setWithObject:[CTCoreAddress addressWithName:@"Calulu4BMK" email:senderAddr]]];
    [mailMsg setBody:mailBody];
    [mailMsg setSubject:mailTitle];
    
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID: selectUserID];
    for (int i = 0; i < [selectImageArray count]; i++) {
        // 画像が選択されていなければ添付しない
        if ([[(OKDThumbnailItemView*)[selectImageArray objectAtIndex:i] getFileName] isEqualToString:@"noimage.png"]) {
            continue;
        }

        // 選択中の画像を取得
        UIImage *image = (UIImage *)[(OKDThumbnailItemView*)[selectImageArray objectAtIndex:i] getRealSizeImage:imgFileMng];
        // UIImageをJpeg化して、NSDATAに入れる
        NSData *jpgData = UIImageJPEGRepresentation(image, 0.8);
        NSString *contentType = @"application/octet-stream";
        
        // ファイル名に日付を入れるため
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
        
        // 添付ファイル名生成　アカウントID_月日_番号.jpg
        CTCoreAttachment *attach =
        [[CTCoreAttachment alloc] initWithData:jpgData
                                   contentType:contentType
                                      filename:[NSString stringWithFormat:@"%@_%02ld%02ld_%d.jpg",
                                                accID, (long)[components month], (long)[components day], i+ 1]];
        
        [mailMsg addAttachment:attach];
        [attach release];
        [calendar release];
    }
    [imgFileMng release];
    //インジケーター画面の設定、表示
    indicatorAlert =
    [[UIAlertView alloc] initWithTitle:@"メール送信中" message:@"　" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake( 125, 80, 30, 30 )] autorelease];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [indicatorAlert addSubview:indicator];
    [indicator startAnimating];
    [indicatorAlert show];
    
    //メール送信
    mailError = nil;
    //メール送信に必要な値設定
    NSMutableDictionary* param = [[[NSMutableDictionary alloc]init]autorelease];
    [param setObject:mailMsg forKey:@"mailMsg"];
    [param setObject:smtpServer forKey:@"smtpServer"];
    [param setObject:smtpUser forKey:@"smtpUser"];
    [param setObject:smtpPass forKey:@"smtpPass"];
    [param setObject:[NSNumber numberWithInteger:smtpPort] forKey:@"smtpPort"];
    [param setObject:[NSNumber numberWithInteger:smtpType] forKey:@"smtpType"];
    
    aliveThreadFlag = TRUE;
    
    //タイムアウト設定(30秒)
    struct timeval delay = {  30, 0 };
    mailstream_network_delay = delay;
    
    //メール送信スレッド生成
    [NSThread detachNewThreadSelector:@selector(sendMailThread:)
                             toTarget:self
                           withObject:param];
    [mailMsg release];
}

//メール送信スレッド
- (void)sendMailThread:(id)param
{
    //メール送信に必要な値を取得
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CTCoreMessage *mailMsg  = [param objectForKey:@"mailMsg"];
    NSString *smtpServer    = [param objectForKey:@"smtpServer"];
    NSString *smtpUser      = [param objectForKey:@"smtpUser"];
    NSString *smtpPass      = [param objectForKey:@"smtpPass"];
    u_int smtpPort          = [[param objectForKey:@"smtpPort"] intValue];
    u_int smtpType          = [[param objectForKey:@"smtpType"] intValue];
    //認証方式設定
    CTSMTPConnectionType type;
    switch (smtpType) {
        case 0:
            type = CTSMTPConnectionTypePlain;
            break;
        case 1:
            type = CTSMTPConnectionTypeStartTLS;
            break;
        case 2:
            type = CTSMTPConnectionTypeTLS;
            break;
        default:
            type = CTSMTPConnectionTypePlain;
            break;
    }
    //メール送信
    int retryCnt = 0;
    while (retryCnt < 3) {
        BOOL success = [CTSMTPConnection sendMessage:mailMsg
                                              server:smtpServer
                                            username:smtpUser
                                            password:smtpPass
                                                port:smtpPort
                                      connectionType:type
                                             useAuth:YES
                                               error:&mailError];
        if (!success) {
            NSLog(@"Mail send Error");
            NSString *errorMessage = [mailError localizedDescription];
            NSLog(@"message:%@",errorMessage);
            retryCnt++;
        }else{
            //送信成功
            break;
        }
    }
    
    [self performSelectorOnMainThread:@selector(mailThreadEnd) withObject:nil waitUntilDone:NO];
    [pool release];
    [NSThread exit];
    
}

//メール送信が完了したときに呼ばれる
- (void)mailThreadEnd
{
    //アラート削除
    [indicatorAlert dismissWithClickedButtonIndex:0 animated:NO];
    [indicatorAlert release];
    indicatorAlert = nil;
    
    //送信結果表示
    if (mailError != nil) {
        UIAlertView *errorAlert =[[UIAlertView alloc] initWithTitle:@"送信エラー" message:@"メール送信に失敗しました" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        //メール送信中に画面向きがかわったならポップアップを再表示
        if (dissmissPopupFlag) {
            //すぐに実行しても表示されないので遅延実行
            [self performSelector:@selector(callReloadPopup) withObject:nil afterDelay:0.5];
        }
    }else{
        UIAlertView *okAlert =[[UIAlertView alloc] initWithTitle:@"送信完了" message:@"メール送信に成功しました" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [okAlert show];
        
        //ポップアップを閉じる
        if(delegate != nil)
        {
            [delegate OnPopUpViewSet:-1 setObject:nil];
        }
        
        [self closeByPopoverContoller];
    }
    //スレッド実行フラグを無効化
    aliveThreadFlag = FALSE;
}

#pragma mark -
#pragma mark その他処理
//キーボードの表示
- (void)keyboardWillShow:(NSNotification *)notification
{
    NSLog(@"keyboardWillShow");
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (UIInterfaceOrientationIsLandscape(orientation) )
    {
        CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        //キーボードが予測変換機能付きかチェック
        if(keyboardRect.size.width > 352){
            //キーボードが予測変換機能付き
            CGRect scrollFrame = self.view.bounds;
            self.myScrollView.frame = CGRectMake(scrollFrame.origin.x + 52, scrollFrame.origin.y + 84, 240, 65);
            self.myScrollView2.frame = CGRectMake(scrollFrame.origin.x + 300, scrollFrame.origin.y + 84, 240, 65);
            //ラベルも移動
            self.imageLabel1.hidden = true;
            self.imageLabel2.hidden = true;
            imageLabel3.hidden = true;
            self.sexLabel.hidden = true;
            self.sexSegmentCtrl.hidden = true;
            self.treatmentLabel.hidden = true;
            self.treatmentField.hidden = true;
            self.treatmentCntLabel.hidden = true;
        }else{
            //通常のキーボード
            CGRect scrollFrame = self.view.bounds;
            self.myScrollView.frame = CGRectMake(scrollFrame.origin.x + 52, scrollFrame.origin.y + 120, 240, 85);
            self.myScrollView2.frame = CGRectMake(scrollFrame.origin.x + 300, scrollFrame.origin.y + 120, 240, 85);
            //ラベルも移動
            self.sexLabel.hidden = false;
            self.sexSegmentCtrl.hidden = false;
            self.treatmentLabel.hidden = false;
            self.treatmentField.hidden = false;
            self.treatmentCntLabel.hidden = false;
           self.imageLabel1.hidden = true;
            self.imageLabel2.hidden = true;
            imageLabel3.hidden = true;
        }
    }
}

//キーボードの非表示
- (void)keyboardWillHide:(NSNotification *)notification
{
    NSLog(@"keyboardWillHide");
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (UIInterfaceOrientationIsLandscape(orientation) )
    {
        //画像の表示エリアを元に戻す
        CGRect scrollFrame = self.view.bounds;
        self.myScrollView.frame = CGRectMake(scrollFrame.origin.x + 52, scrollFrame.origin.y + 135, 240, 180);
        self.myScrollView2.frame = CGRectMake(scrollFrame.origin.x + 300, scrollFrame.origin.y + 135, 240, 180);
        //ラベルも元に戻す
        self.imageLabel1.hidden = false;
        self.imageLabel2.hidden = false;
        imageLabel3.hidden = false;
        self.sexLabel.hidden = false;
        self.sexSegmentCtrl.hidden = false;
        self.treatmentLabel.hidden = false;
        self.treatmentField.hidden = false;
        self.treatmentCntLabel.hidden = false;
    }
}

// ==================================================
// 画像の拡大縮小
// 入力
// (UIImage *)image 拡大/縮小したい画像
// (CGRect)rect 拡大/縮小後のサイズ
// 出力
// 拡大/縮小した画像
// ==================================================
- (UIImage*)resizedImage:(UIImage*)img size:(CGSize)size
{
    CGFloat imgWidth = img.size.width;
    CGFloat imgHeight = img.size.height;
    CGFloat width_ratio  = size.width  / imgWidth;
    CGFloat height_ratio = size.height / imgHeight;
    CGFloat ratio = (width_ratio < height_ratio) ? width_ratio : height_ratio;
    CGSize resized_size = CGSizeMake(img.size.width*ratio, img.size.height*ratio);
//    //横が320でないなら320にする
//    if (resized_size.width != 320) {
//        resized_size.width = 320;
//    }
//    //縦が240でないなら240にする
//    if (resized_size.height != 240) {
//        resized_size.height = 240;
//    }
    UIGraphicsBeginImageContext(resized_size);
    [img drawInRect:CGRectMake(0, 0, resized_size.width, resized_size.height)];
    UIImage* resized_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized_image;
}

// 年齢計算（生年月日が未登録の場合０を返す）
- (int) calcAge:(mstUser *)user
{
    NSCalendar *callendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    
    NSDate *birthday = (user.birthDay==nil)? now : user.birthDay;
    
    NSCalendarUnit unit = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *elapsed = [callendar components:unit fromDate:birthday toDate:now options:0];
    
    return (int)elapsed.year;
}

// 数値入力テキストフィールドのデリゲート
// 数値以外をはじく
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ( (string != nil) && (![string  isEqual: @""]) ) {
        if (![self isNumber:string]) {
            return NO;
        }
    }
    return YES;
}

// 入力されたものが数値であるかを判定する
- (BOOL)isNumber:(NSString *)value {
    
    // 空文字の場合はNO
    if ( (value == nil) || ([@"" isEqualToString:value]) ) {
        return NO;
    }
    
    NSInteger l = [value length];
    
    BOOL b = NO;
    for (NSInteger i = 0; i < l; i++) {
        NSString *str =
        [[value substringFromIndex:i] substringToIndex:1];
        
        const char *c =
        [str cStringUsingEncoding:NSASCIIStringEncoding];
        
        if ( c == NULL ) {
            b = NO;
            break;
        }
        
        if ((c[0] >= 0x30) && (c[0] <= 0x39)) {
            b = YES;
        } else {
            b = NO;
            break;
        }
    }
    
    if (b) {
        return YES;  // 数値文字列である
    } else {
        return NO;
    }  
}

#pragma mark -
#pragma mark 年齢設定

// 年齢設定ポップアップ
- (IBAction)OnSetAge:(id)sender {
    if (lockFlag) { // 他のボタンとの同時押し回避
        return;
    }
    lockFlag = YES;
    // ユーザ情報編集のViewControllerのインスタンス生成
    vcSetAge
    = [[AgePickerPopUp alloc]initWithAgeSetting:btnSetAge.titleLabel.text.integerValue
                                        popUpID:5
       
                                       callBack:self];
    
    // MainViewControllerの取得
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:YES];
    self.view.userInteractionEnabled = NO;
    
    // 設定前の年齢保持
    preAge = [btnSetAge.titleLabel.text copy];
    
    // 年齢設定ポップアップ画面を表示
    popoverCntlSetAge =
    [[UIPopoverController alloc] initWithContentViewController:vcSetAge];
    vcSetAge.popoverController = popoverCntlSetAge;
    [popoverCntlSetAge presentPopoverFromRect:btnSetAge.bounds
                                       inView:btnSetAge
                     permittedArrowDirections:UIPopoverArrowDirectionAny
                                     animated:YES];
    [popoverCntlSetAge setPopoverContentSize:CGSizeMake(240.0f, 330.0f)];
    
    //画面外をタップしてもポップアップが閉じないようにする処理
    NSMutableArray *viewCof = [[NSMutableArray alloc]init];
    
    [viewCof addObject:mainVC.view];
    [viewCof addObject:self.view];
    // isNavigationCallの呼び出し時のみ
    if(isNavigationCall)
        [viewCof addObject:tempView];
    popoverCntlSetAge.passthroughViews = viewCof;
    [viewCof release];
    [popoverCntlSetAge release];
    [vcSetAge release];
}

// ポップアップ側の設定値をリアルタイムに取得
- (void)OnCheckAge:(NSInteger)age
{
    if (age>6 || age<1) {
        [btnSetAge setTitle:@"その他" forState:UIControlStateNormal];
    } else {
        [btnSetAge setTitle:[NSString stringWithFormat:@"%ld", (long)(age * 10)]
                   forState:UIControlStateNormal];
    }
}

// キャンセルの場合、設定前の状態に戻す
- (void)OnAgeSetCancel
{
    [btnSetAge setTitle:preAge forState:UIControlStateNormal];
    [preAge release];
    
    // 操作可能に戻す
    self.view.userInteractionEnabled = YES;
    lockFlag = NO;
    
    vcSetAge = nil;
}

// 年齢確定
- (void)OnAgeSetOK
{
    // ポップアップ表示前に保持した値をリリースするだけ
    [preAge release];

    // 操作可能に戻す
    self.view.userInteractionEnabled = YES;
    lockFlag = NO;
    
    vcSetAge = nil;
}

#pragma mark 比較写真設定
- (void) OnSetComparePicture:(BOOL)before
{
    if (lockFlag) { // 同時押し回避
        return;
    }
    lockFlag = YES;
    isBefore = before;
    _beforeSelect = before;

    NSString *lblString;
    if (before) {
        lblString = @"施術 前 の写真を選択してください";
    } else {
        lblString = @"施術 後 の写真を選択してください";
    }
    // ユーザ情報編集のViewControllerのインスタンス生成
    vcSelSwimmy
    = [[selectSwimmyPicture alloc] initWithSwimmyPicture:1010
                                       popOverController:nil
                                                callBack:self
                                            selectUserID:selectUserID
                                                   title:lblString];
    
    // MainViewControllerの取得
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:YES];
    self.view.userInteractionEnabled = NO;
    
    UILabel *lblSelected;
    
    // 施術前後どちらのラベル
    if (before) lblSelected = lblBeforeView;
    else        lblSelected = lblAfterView;
    
    // 比較写真選択画面を表示
    popoverCntlSelSwimmy =
    [[UIPopoverController alloc] initWithContentViewController:vcSelSwimmy];
    vcSelSwimmy.popoverController = popoverCntlSelSwimmy;
//    [popoverCntlSelSwimmy presentPopoverFromRect:lblSelected.bounds
//                                       inView:lblSelected
//                     permittedArrowDirections:UIPopoverArrowDirectionAny
//                                     animated:YES];
//    [popoverCntlSelSwimmy setPopoverContentSize:CGSizeMake(607.0f, 512.0f)];
    
    CGRect rect = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, 1, 1);
    [popoverCntlSelSwimmy presentPopoverFromRect:rect
                                          inView:self.view
                        permittedArrowDirections:0
                                        animated:YES];
    [popoverCntlSelSwimmy setPopoverContentSize:CGSizeMake(607.0f, 512.0f)];
    
    //画面外をタップしてもポップアップが閉じないようにする処理
    NSMutableArray *viewCof = [[NSMutableArray alloc]init];
    
    [viewCof addObject:mainVC.view];
    [viewCof addObject:self.view];
    // isNavigationCallの呼び出し時のみ
    if(isNavigationCall)
        [viewCof addObject:tempView];
    popoverCntlSelSwimmy.passthroughViews = viewCof;
    [viewCof release];
    [popoverCntlSelSwimmy release];
    [vcSelSwimmy release];
}

- (void)onRotationView:(BOOL)before {
    [self OnSetComparePicture:before];
}

// キャンセル
- (void)OnSelectComparePictureCancel
{
    // 操作可能に戻す
    self.view.userInteractionEnabled = YES;
    lockFlag = NO;
    
    vcSelSwimmy = nil;
}

// 送信画像確定
- (void)OnSelectComparePictureSet:(NSMutableArray *)view
{
    // 選択された画像にする
    [self setSelectedPicture:view];
    
    // 操作可能に戻す
    self.view.userInteractionEnabled = YES;
    lockFlag = NO;
    
    vcSelSwimmy = nil;
}

// 選択された画像に置き換える
- (void)setSelectedPicture:(NSMutableArray *)view
{
    // 施術前後のどちらか？
    NSInteger idx = (isBefore)? 0 : 1;

    // 現在表示されている画像を一旦削除する
    for (UIView *cv in self.myScrollView.subviews) {
        [cv removeFromSuperview];
    }
    for (UIView *cv in self.myScrollView2.subviews) {
        [cv removeFromSuperview];
    }
    
    //添付画像配列を一時保存
    NSMutableArray *tmpImageArray = [selectImageArray copy];
    
    [selectImageArray replaceObjectAtIndex:idx withObject:[view objectAtIndex:0]];
    
    [tmpImageArray release];
   
    [self viewWillAppear:Nil];
//    [self.myScrollView setNeedsDisplay];
//    [self.myScrollView2 setNeedsDisplay];
}
@end
