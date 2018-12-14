//
//  MailSendPopUp.m
//  iPadCamera
//
//  Created by MacBook on 13/05/24.
//
//

#import "MailSendPopUp.h"
#import "GrayOutImageView.h"
#import "model/OKDImageFileManager.h"
#import "OKDThumbnailItemView.h"
#import "MailAddressSyncManager.h"
#import "Common.h"
#import "shop/ShopManager.h"

#ifdef AIKI_CUSTOM
#import <MailCore.h>  // Mail送信のサポート
#endif

#import "SVProgressHUD.h"

#define MPICT_SV_HEIGHT     250 // Mail Picture ScrollView Height

@interface MailSendPopUp ()

@end

@implementation MailSendPopUp

@synthesize selectUserID;
@synthesize selectHistID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //添付画像枚数を表示
    NSInteger cnt = [selectImageArray count];
    if(cnt > 4) cnt = 4;
    self.imageLabel2.text = [NSString stringWithFormat:@"(全%ld枚)", (long)cnt];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    //一時保存されているメールデータがないかチェック
    BOOL onceSaveFlag = [userDefault boolForKey:@"onceSaveFlag"];
    if (onceSaveFlag) {
        //保存されていたらデータをセットする
        //self.emailField1.text = [userDefault stringForKey:@"mailEmail1"];
        //self.emailField2.text = [userDefault stringForKey:@"mailEmail2"];
        self.emailText.text = [userDefault stringForKey:@"mailBody"];
        self.emailTitle.text = [userDefault stringForKey:@"mailTitle"];
        sendCCFlag = [userDefault boolForKey:@"sendCCFlag"];
        BOOL callCCFlag = [userDefault boolForKey:@"ccAlertShowFlag"];
        //CCが表示中だったなら表示する
        if (callCCFlag) {
            [self addMailCC:nil];
        }
        //userDefaultからデータを削除
        [userDefault removeObjectForKey:@"mailEmail1"];
        [userDefault removeObjectForKey:@"mailEmail2"];
        [userDefault removeObjectForKey:@"mailBody"];
        [userDefault removeObjectForKey:@"mailTitle"];
        [userDefault removeObjectForKey:@"ccAlertShowFlag"];
        [userDefault removeObjectForKey:@"onceSaveFlag"];
        //処理を終了させる
        return;
    }
    // クラウドよりお客様のメールアドレスを取得し、異なればローカルDBのメールアドレス１のみを更新する
//2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ固定メール
#ifndef FOR_SALES
    if(![MailAddressSyncManager syncMailAddresses: selectUserID]) {
        // クラウドよりメールアドレスが失敗した場合、ネットワークに問題があるとして送信不可にする
        self.MailSend.enabled = NO;
    }
#endif
    // ユーザマスタの取得
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	mstUser *user = [usrDbMng getMstUserByID:self.selectUserID];
    
    //データベースからメール情報取得
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *beanArray = [manager selectUserMail];
    [manager release];
    //email設定
    NSString *mail1 = user.email1;
    // NSString *mail2 = user.email2; DELC SASAGE DELETE
    NSArray *mailArray;
    if([mail1 length]){
        //@マークでアドレスとドメインを分離する
        mailArray = [mail1 componentsSeparatedByString:@"@"];
        if ([mailArray count] == 2){
            //分離した文字を各フィールドに設定
            self.emailField1.text = [mailArray objectAtIndex:0];
            self.emailField2.text = [mailArray objectAtIndex:1];
        }else{
            self.emailField1.text = mail1;
        }
    }else{
        //入力されたアドレスを保存しておくフラグをたてる
        addrInsertFlag = TRUE;
    }
    
    //メール本文, タイトル設定
    NSMutableString *body = [NSMutableString string];
    [body appendString:[NSString stringWithFormat:@"%@　%@　様\n", user.firstName, user.secondName]];
    if ([beanArray count] != 0)
    {
        //メールボディ設定
        fcUserMailItemBean *bean = [beanArray objectAtIndex:0];
        NSString *freeText = [bean free_text];
        [body appendString:freeText];
        if(bean.fix_text3 != nil){
            [body appendString:bean.fix_text3];
        }else{
            //署名がDBになければ追加
            [body appendString:@""];
        }
        //BMK版ならホームページも追加
#ifdef AIKI_CUSTOM
        [body appendString:@"（社）日本BMK美健協会 本部\nE-mail : bmkinfomation@gmail.com\n協会HP : http://bmk-assoc.jp/association.html\n協会FB : http://www.facebook.com/bikenDougen"];
#endif

        self.emailText.text = body;
        //タイトル設定
        //データベースからタイトル取得
        userFmdbManager *manager = [[userFmdbManager alloc]init];
        [manager initDataBase];

        self.emailTitle.text = [manager selectMailTitle:bean.title_id];
        [manager release];
        
    }else{
        [body appendString:@"\n\n\n"];
        //署名を追加
        [body appendString:@""];
        //BMK版ならホームページも追加
#ifdef AIKI_CUSTOM
        [body appendString:@"（社）日本BMK美健協会 本部\nE-mail : bmkinfomation@gmail.com\n協会HP : http://bmk-assoc.jp/association.html\n協会FB : http://www.facebook.com/bikenDougen"];
#endif
        self.emailText.text = body;
    }
    
    //2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ固定メール
#ifdef FOR_SALES
    self.emailTitle.text = @"オカダ電子からのお知らせ";
    self.emailText.text = @"メール サンプル 様\n\nオカダ電子 からのお知らせがございます。\n\n下記のリンクをクリックしてご確認ください。\nhttp://abcarte.jp/abcarte-tools/abcartesync/apps/mail/samplemail/sample_mail_system.png\n\n※ このメールは自動送信されています。\n\nもし、このメールに心当たりがない場合は、恐れ入りますが、下記のメールに送信願います。\nsupport@abcarte.jp";
#endif
	// タイトルの角を丸める
	[Common cornerRadius4Control:lblTitle];

    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=7.0) {
        [self.MailSend setBackgroundColor:[UIColor whiteColor]];
        [[self.MailSend layer] setCornerRadius:6.0];
        [self.MailSend setClipsToBounds:YES];
        [[self.MailSend layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[self.MailSend layer] setBorderWidth:1.0];
        
        [btnCancel setBackgroundColor:[UIColor whiteColor]];
        [[btnCancel layer] setCornerRadius:6.0];
        [btnCancel setClipsToBounds:YES];
        [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[btnCancel layer] setBorderWidth:1.0];
    }
    selectShopID = user.shopID;
    shopName = user.shopName;
    lblEmailNotice.numberOfLines = 2;

    [usrDbMng release];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // キーボード表示・非表示の通知の登録
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    //リストポップアップで何かを選択されたときの通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupEmailTitle:) name:@"SetEmailTitle" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupEmailDomain:) name:@"SetEmailDomain" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupEmailAddr:) name:@"SetEmailAddr" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupEmailCCAddr:) name:@"SetEmailCCAddr" object:nil];
    // 全店共通ユーザの場合サーバ側に登録出来ないので、受信拒否設定ボタンを有効にしない
    if ([[ShopManager defaultManager] isAccountShop] && selectShopID==0) {
        self.MailSend.enabled = NO;
        lblEmailNotice.hidden = NO;
        lblEmailNotice.text = [NSString stringWithFormat:@"注意!! [%@]所属のユーザへは\nメール送信出来ません", shopName];
    } else {
        self.MailSend.enabled = YES;
        lblEmailNotice.hidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // キーボード表示・非表示の通知の解除
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    //設定した通知を解除
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SetEmailTitle" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SetEmailDomain" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SetEmailAddr" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SetEmailCCAddr" object:nil];
    
    //送信が完了していなかったらスレッド終了
    if(aliveThreadFlag){
        [NSThread exit];
        if (indicatorAlert != nil) {
            [indicatorAlert dismissWithClickedButtonIndex:0 animated:NO];
            [indicatorAlert release];
            indicatorAlert = nil;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id) initWithMailSetting:(NSMutableArray *)pictImageItems
              selectUserID:(USERID_INT)userID
              selectHistID:(HISTID_INT)histID
                 pictIndex:(NSInteger)indexID
                   popUpID:(NSUInteger)popUpID
                  callBack:(id)callBack
{
    isSending = NO;
    self.MailSend.enabled = YES;
    //GrayOutImageView *image;
    
    if(self = [super initWithPopUpViewContoller:popUpID
                              popOverController:nil
                                       callBack:callBack
                                        nibName:@"MailSendPopUp"]) {
        
        self.contentSizeForViewInPopover = CGSizeMake(588.0f, 578.0f);
    
        self.selectUserID = userID;
        self.selectHistID = histID;
        
        //宛先で固定で表示されるドメイン配列設定
        addrArray = [[NSArray arrayWithObjects:@"i.softbank.jp", @"ezweb.ne.jp",  @"docomo.ne.jp", @"gmail.com", @"yahoo.co.jp", nil]retain];
        
        //CCフラグを初期化
        sendCCFlag = FALSE;
        //CCテキストも初期化
        ccText = @"";
        //メールアドレス登録フラグ初期化
        addrInsertFlag = FALSE;

        //添付画像配列を一時保存
        selectImageArray = [pictImageItems retain];
        //スレッド監視フラグ初期化
        aliveThreadFlag = FALSE;
        
        dissmissPopupFlag = false;
        
        //送信する画像の枚数チェック
        NSInteger pictCnt = [pictImageItems count];

        //送れる画像は4枚まで
        if (pictCnt > 4)
        {
            pictCnt = 4;
        }
        //画像があればスクロールビューに設定
        OKDImageFileManager *imgFileMng
        = [[OKDImageFileManager alloc]initWithUserID: selectUserID];
        if(pictCnt > 0) {
            for (NSInteger i = 0; i < pictCnt; i++) {
                UIImage *pictimage = (UIImage*)[((OKDThumbnailItemView* )pictImageItems[i])
                                                getRealSizeImage:imgFileMng];
                UIImage *resizeImage = [self resizedImage:pictimage size:CGSizeMake(320, 240)];
                //各画像の位置を指定
                CGPoint drawPoint;
                float scrollFrameHeight = 240;
                switch (i) {
                    case 0:
                        drawPoint = CGPointMake(0, 0);
                        break;
                    case 1:
                        drawPoint = CGPointMake(0, 245);
                        scrollFrameHeight = 485;
                        break;
                    case 2:
                        drawPoint = CGPointMake(0, 490);
                        scrollFrameHeight = 730;
                        break;
                    case 3:
                        drawPoint = CGPointMake(0, 735);
                        scrollFrameHeight = 975;
                        break;
                    default:
                        NSLog(@"スクロールビュー画像設定エラー");
                        drawPoint = CGPointMake(0, 0);
                        break;
                }
                //画像を張るビュー設定
                UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(drawPoint.x,drawPoint.y, resizeImage.size.width, resizeImage.size.height)];
                imageView.image = resizeImage;
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                //画像を張るスクロールビューの設定
                CGRect scrollFrame = self.view.bounds;
                //スクロールさせる
                self.myScrollView.scrollEnabled = YES;
                //バウンドさせない
                self.myScrollView.bounces = NO;
                self.myScrollView.zoomScale = 1.0f;
                //ポップアップビューの原点から指定した位置にスクロールビューをセット
                self.myScrollView.frame = CGRectMake(scrollFrame.origin.x + 89, scrollFrame.origin.y + 122, 320, MPICT_SV_HEIGHT);
                //貼付けた画像のスクロール範囲
                self.myScrollView.contentSize = CGSizeMake(320, scrollFrameHeight);
                [self.myScrollView addSubview:imageView];
                [imageView release];
            }
        }else{
            //画像が無い場合でもスペースをあけるためFrameを設定
            //画像を張るスクロールビューの設定
            CGRect scrollFrame = self.view.bounds;
            //ポップアップビューの原点から指定した位置にスクロールビューをセット
            self.myScrollView.frame = CGRectMake(scrollFrame.origin.x + 89, scrollFrame.origin.y + 122, 320, MPICT_SV_HEIGHT);
        }
        [imgFileMng release];
    }
    return(self);
}
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
            self.myScrollView.frame = CGRectMake(scrollFrame.origin.x + 89, scrollFrame.origin.y + 122, 485, 50);
            //ラベルも移動
            self.imageLabel1.frame = CGRectMake(scrollFrame.origin.x + 4, scrollFrame.origin.y + 112, 77, 32);
            self.imageLabel2.hidden = true;
        }else{
            //通常のキーボード
            CGRect scrollFrame = self.view.bounds;
            self.myScrollView.frame = CGRectMake(scrollFrame.origin.x + 89, scrollFrame.origin.y + 122, 485, 50);
            //ラベルも移動
            self.imageLabel1.frame = CGRectMake(scrollFrame.origin.x + 4, scrollFrame.origin.y + 122, 77, 32);
            self.imageLabel2.frame = CGRectMake(scrollFrame.origin.x + 4, scrollFrame.origin.y + 154, 77, 32);
            self.imageLabel2.hidden = false;
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
        self.myScrollView.frame = CGRectMake(scrollFrame.origin.x + 89, scrollFrame.origin.y + 122, 485, MPICT_SV_HEIGHT);
        //ラベルも元に戻す
        self.imageLabel1.frame = CGRectMake(scrollFrame.origin.x + 4, scrollFrame.origin.y + 246, 77, 32);
        self.imageLabel2.frame = CGRectMake(scrollFrame.origin.x + 4, scrollFrame.origin.y + 277, 77, 32);
        self.imageLabel2.hidden = false;
    }
}

//履歴からemailタイトル取得
- (void)setupEmailTitle:(NSNotification *)notification
{
    NSLog(@"setupEmailTitle");
    NSString *data = [[notification userInfo] objectForKey:@"SelectData"];
    self.emailTitle.text = data;
    
    [popover dismissPopoverAnimated:YES];
}

//履歴からemailドメイン取得
- (void)setupEmailDomain:(NSNotification *)notification
{
    NSLog(@"setupEmailDomain");
    NSString *data = [[notification userInfo] objectForKey:@"SelectData"];
    self.emailField2.text = data;
    
    [popover dismissPopoverAnimated:YES];
}

//履歴からemailアドレス取得
- (void)setupEmailAddr:(NSNotification *)notification
{
    NSLog(@"setupEmailAddr");
    NSString *data = [[notification userInfo] objectForKey:@"SelectData"];
    
    NSArray *mailArray = [data componentsSeparatedByString:@"@"];
    if ([mailArray count] == 2){
        self.emailField1.text = [mailArray objectAtIndex:0];
        self.emailField2.text = [mailArray objectAtIndex:1];
    }else{
        self.emailField1.text = data;
    }
    
    [popover dismissPopoverAnimated:YES];
}

//履歴からccアドレス取得
- (void)setupEmailCCAddr:(NSNotification *)notification
{
    NSLog(@"setupEmailCCAddr");
    NSString *data = [[notification userInfo] objectForKey:@"SelectData"];
    NSLog(@" data : %@", data);
    
    [popover dismissPopoverAnimated:YES];
}

//編集されているメールの内容を一時保存
- (BOOL) onceSaveMailData{
    NSLog(@"onceSaveMailData");
    //メール送信中なら消さない
    if (aliveThreadFlag) {
        dissmissPopupFlag = true;
        return false;
    }
    //履歴ポップアップが表示されていたら非表示に
    if (popover != nil) {
        if (popover.popoverVisible) {
            [popover dismissPopoverAnimated:YES];
        }
    }
    //各値を取得
    NSString *mailEmail1 = self.emailField1.text;
    NSString *mailEmail2 = self.emailField2.text;
    NSString *mailBody = self.emailText.text;
    NSString *mailTitle = self.emailTitle.text;
    //値を保存
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:mailEmail1 forKey:@"mailEmail1"];
    [userDefault setObject:mailEmail2 forKey:@"mailEmail2"];
    [userDefault setObject:mailBody forKey:@"mailBody"];
    [userDefault setObject:mailTitle forKey:@"mailTitle"];
    //CCがあったら保存
    if(sendCCFlag && ([ccText length] != 0)){
        [userDefault setObject:ccText forKey:@"mailCC"];
        [userDefault setBool:sendCCFlag forKey:@"sendCCFlag"];
    }
    //アラートが表示されているかチェック
    if(ccAlert != nil){
        if (ccAlert.isVisible) {
            //表示されていたらフラグを保存して非表示にする
            [ccAlert dismissWithClickedButtonIndex:0 animated:YES];
            [userDefault setBool:YES forKey:@"ccAlertShowFlag"];
            //入力内容も保存
            [userDefault setObject:[ccTextField text] forKey:@"mailEditCC"];
        }
        [ccAlert release];
        ccAlert = nil;
    }
    //一時保存フラグをたてる
    [userDefault setBool:YES forKey:@"onceSaveFlag"];
    [userDefault synchronize];
    return true;
}

//テキストフィールドデリゲート
-(void)textFieldDidBeginEditing:(UITextField*)textField
{
    NSInteger tag = [textField tag];
    TextLogTableViewController *tableview = nil;
    switch (tag) {
        case 201:
        case 204:
            break; //DELC SASAGE
            //emailFild1
            NSLog(@"emailFild1");
            userDbManager *usrDbMng = [[userDbManager alloc] init];
            mstUser *user = [usrDbMng getMstUserByID:self.selectUserID];
            
            //アドレスがあればポップアップで表示
            NSString *mail1 = user.email1;
            // NSString *mail2 = user.email2; // DELC SASAGE
            if ([mail1 length] /* || [mail2 length]*/) {
                //メールを表示する配列に追加
                NSMutableArray *emailArray = [NSMutableArray array];
                if ([mail1 length]) {
                    [emailArray addObject:mail1];
                }
                /*
                if ([mail2 length]) {
                    [emailArray addObject:mail2];
                }
                 */
                //メールリストを表示
                tableview = [[TextLogTableViewController alloc]initWithStyle:UITableViewStylePlain cellItemsArray:emailArray TaskTag:tag];
                // Popoverのインスタンス生成
                popover = [[UIPopoverController alloc] initWithContentViewController: tableview];
                // Popoverを表示する
                [popover presentPopoverFromRect:textField.bounds inView:textField permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            }
            
            
            [usrDbMng release];
            break;
        case 202:
            //emailFild2
            NSLog(@"emailFild2");
            //ドメインリスト表示
            tableview = [[TextLogTableViewController alloc]initWithStyle:UITableViewStylePlain cellItemsArray:addrArray TaskTag:tag];
            // Popoverのインスタンス生成
            popover = [[UIPopoverController alloc] initWithContentViewController: tableview];
            // Popoverを表示する
            [popover presentPopoverFromRect:textField.bounds inView:textField permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            break;
        case 203:
            //emailTitle
            NSLog(@"emailTitle");
            NSArray     *titleArray;
            userFmdbManager *manager = [[userFmdbManager alloc]init];
            [manager initDataBase];
            titleArray = [manager selectAllMailTitle];
            [manager release];
            
            //タイトル履歴が無ければポップアップを表示しない
            if (![titleArray count]) {
                return;
            }
            //履歴表示
            tableview = [[TextLogTableViewController alloc]initWithStyle:UITableViewStylePlain cellItemsArray:titleArray TaskTag:tag];
            // Popoverのインスタンス生成
            popover = [[UIPopoverController alloc] initWithContentViewController: tableview];
            // Popoverを表示する
            [popover presentPopoverFromRect:textField.bounds inView:textField permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            break;
        default:
            break;
    }
    if (tableview) [tableview release];
}

//アラートビューデリゲート
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger tag = [alertView tag];
    switch (tag) {
        case -1009:
            [self mailSendThreadEnd:YES Code:tag];
            break;
        case 301:
            //メール内容を保存
            [self callMailDataSaveTask];
            break;
        case 302:
            //あて先(CC)追加処理から
            [ccTextField resignFirstResponder];
            if (buttonIndex == 1) {
                // OK
                //CCに入力があるときのみ処理を実行
                if ([[ccTextField text]length] != 0) {
                    ccText = [ccTextField text];
                    sendCCFlag = TRUE;
                }else{
                    ccText = @"";
                    sendCCFlag = FALSE;
                }
            }else{
                //Cancel
//                ccText = [ccTextField text];
                if (!sendCCFlag) {
                    ccText = @"";
                }
            }
            break;
        //2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ固定メール
        case 303:
            break;
        default:
            break;
    }
    //CC入力アラートを消す
    if(ccAlert != nil){
        if (ccAlert.isVisible) {
            [ccAlert dismissWithClickedButtonIndex:0 animated:YES];
        }
        [ccAlert release];
        ccAlert = nil;
    }
}

- (void)dealloc {
//    [_MailCancel release];
    [_MailSend release];
    [_myScrollView release];
    [selectImageArray release];
    [addrArray release];
    [btnCancel release];
    [lblTitle release];
    [lblEmailNotice release];
    [super dealloc];
}
- (void)viewDidUnload {
//    [self setMailCancel:nil];
    [self setMailSend:nil];
    [self setMyScrollView:nil];
    [btnCancel release];
    btnCancel = nil;
    [lblTitle release];
    lblTitle = nil;
    [lblEmailNotice release];
    lblEmailNotice = nil;
    [super viewDidUnload];
}

//メール送信実行アクション
- (IBAction)doMailsend:(UIButton *)sender {
  
//2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ固定メール
#ifdef FOR_SALES
    NSString *altMsg = @"";
    
    if([self mailSend:MDM_MAILTO_SITE_URL]){
        altMsg = @"メールを送信しました";
    }else{
        altMsg = @"メール送信に失敗しました";
    }
    
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:@"メール送信" message:altMsg
                              delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alert.tag = 303;
    [alert show];
#else
    if (sendCCFlag) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"あて先(CC)送信確認"
                                                        message:[NSString stringWithFormat:@"%@にもメールを送ります。\nよろしいですか？", ccText]
                                                       delegate:self
                                              cancelButtonTitle:@"NO"
                                              otherButtonTitles:@"YES", nil];
        alert.tag = 301;
        [alert show];
        [alert release];
    }else{
        //メール内容を保存
        [self callMailDataSaveTask];
    }
#endif

}

#ifdef FOR_SALES
//2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ固定メール
- (BOOL) mailSend:(NSString*)webUrl
{
    //NSData *data = nil;
    
    BOOL rt = NO;
    
    @try {
        
        // URLの設定
        
        NSMutableURLRequest *req
        = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:webUrl] ];
        
        // methodはPOST
        [req setHTTPMethod:@"POST"];
        
        // リクエストパラメータの設定
        NSMutableData *body =[NSMutableData data];
        
        NSString *newMail1 = self.emailField1.text;
        NSString *newMail2 = self.emailField2.text;
        NSString *saveAddr = [NSString stringWithFormat:@"%@@%@",newMail1, newMail2];
        
        [self setRequestParm:body toAdress:saveAddr MailTitle:self.emailTitle.text MailHonbun:self.emailText.text];
        [req setHTTPBody:body];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        
        //接続
        [NSURLConnection sendSynchronousRequest:req
                              returningResponse:&response
                                          error:&error];
        if (error)
        {
            NSLog(@"getImageData error -> %@", [error localizedDescription]);
            rt = NO;
        }else{
            rt = YES;
        }
        
        
    }
    @catch (NSException *exception) {
        NSLog(@"getImageData exception: Caught %@: %@",
              [exception name], [exception reason]);
        rt = NO;
    }
    
    if(delegate != nil)
    {
        [delegate OnPopUpViewSet:-1 setObject:nil];
    }
    
    [self closeByPopoverContoller];
    
    return rt;
}

//2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ固定メール
- (void) setRequestParm:(NSMutableData*) body
               toAdress:(NSString*)adress MailTitle:(NSString*)title MailHonbun:(NSString*)honbun
{
    // サイトログインID
    [body appendData:[[NSString stringWithFormat:@"adress=%@&", adress]
                      dataUsingEncoding:NSUTF8StringEncoding] ];
    
    [body appendData:[[NSString stringWithFormat:@"title=%@&", title]
                      dataUsingEncoding:NSUTF8StringEncoding] ];
    
    [body appendData:[[NSString stringWithFormat:@"honbun=%@&", honbun]
                      dataUsingEncoding:NSUTF8StringEncoding] ];
    
    return;
}
#endif

#pragma mark
#pragma mark Mail Send process for BMK
#ifdef AIKI_CUSTOM
//メール送信処理
- (void)callMailSendTask
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
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
    
    NSString *snedMailAddr = [NSString stringWithFormat:@"%@@%@", self.emailField1.text, self.emailField2.text];
    NSString *mailBody = self.emailText.text;
    // 2byte文字対策：メールsubjectの JIS化 -> BASE64encode -> subjectフォーマット
    NSString *mailTitle = [NSString stringWithFormat:@"%@%@%@", @"=?ISO-2022-JP?B?", [self base64EncodeString:self.emailTitle.text], @"?="];
    
    //メール設定
    CTCoreMessage *mailMsg = [[CTCoreMessage alloc] init];
    [mailMsg setTo:[NSSet setWithObject:[CTCoreAddress addressWithName:@" " email:snedMailAddr]]];
    if(sendCCFlag && ([ccText length] != 0)){
        [mailMsg setCc:[NSSet setWithObject:[CTCoreAddress addressWithName:@"　" email:ccText]]];
    }
    [mailMsg setFrom:[NSSet setWithObject:[CTCoreAddress addressWithName:@"Calulu4BMK" email:senderAddr]]];
    [mailMsg setBody:mailBody];
    [mailMsg setSubject:mailTitle];
    
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID: selectUserID];
    for (int i = 0; i < [selectImageArray count]; i++) {
        // 選択中の画像を取得
        UIImage *image = (UIImage*)[((OKDThumbnailItemView* )selectImageArray[i])
                                        getRealSizeImage:imgFileMng];
        UIImage *resizeImage = [self resizedImage:image size:CGSizeMake(320, 240)];
        // UIImageをJpeg化して、NSDATAに入れる
        NSData *jpgData = UIImageJPEGRepresentation(resizeImage, 0.8);
        NSString *contentType = @"application/octet-stream";
        
        CTCoreAttachment *attach = [[CTCoreAttachment alloc] initWithData:jpgData contentType:contentType filename:[NSString stringWithFormat:@"attach0%d.jpg", i+ 1]];
        
        [mailMsg addAttachment:attach];
    }
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
    [param setObject:[NSNumber numberWithInt:smtpPort] forKey:@"smtpPort"];
    [param setObject:[NSNumber numberWithInt:smtpType] forKey:@"smtpType"];
    
    aliveThreadFlag = TRUE;
    
    //タイムアウト設定(30秒)
    struct timeval delay = {  30, 0 };
    mailstream_network_delay = delay;
    
    //メール送信スレッド生成
    [NSThread detachNewThreadSelector:@selector(sendMailThread:)
                             toTarget:self
                           withObject:param];
}

//メール送信スレッド
- (void)sendMailThread:(id)param
{
    //メール送信に必要な値を取得
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CTCoreMessage *mailMsg = [param objectForKey:@"mailMsg"];
    NSString *smtpServer = [param objectForKey:@"smtpServer"];
    NSString *smtpUser = [param objectForKey:@"smtpUser"];
    NSString *smtpPass = [param objectForKey:@"smtpPass"];
    NSInteger smtpPort = [[param objectForKey:@"smtpPort"] intValue];
    NSInteger smtpType = [[param objectForKey:@"smtpType"] intValue];
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
            NSString *errorMessage = [mailError localizedDescription];
            NSLog(@"Mail send Error");
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
#else
#pragma mark Mail Send Process for ABCarte Webmail
- (void)callMailSendTask
{
    //２重送信防止
    if (isSending) {
        return;
    }
    isSending = YES;
    self.MailSend.enabled = NO;
    // 送信者情報
    NSString *senderName = @"";
    NSString *senderEmail = @"";
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *infoBeanArray = [manager selectMailSmtpInfo:1];
    if([infoBeanArray count] != 0){
        mstUserMailItemBean *bean = [infoBeanArray objectAtIndex:0];
        senderName = bean.smtp_user;
        senderEmail = bean.sender_addr;
    }
    [manager release];

    if ([self.emailField1.text length]==0 || [self.emailField2.text length]==0) {
        // メールアドレスが入力されていない場合の処理
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"アドレスエラー"
                                  message:@"メールアドレスが入力されていません。"
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil
                                  ];
        [alertView show];
        [alertView release];
        isSending = NO;
        self.MailSend.enabled = YES;
        return;
    }
    [MailAddressSyncManager updateUserLocalAndWeb: selectUserID mailAddress:[NSString stringWithFormat:@"%@@%@", self.emailField1.text, self.emailField2.text] updateHandler:^(BOOL result){
        WebMailSender *sender = [[WebMailSender alloc] initWithDelegate:self];
        sender.dissmissPopupFlag = false;
        
        NSMutableArray *pictures = [[NSMutableArray array] retain];
        for (OKDThumbnailItemView * oti in selectImageArray) {
            [pictures addObject:
             [NSString stringWithFormat:@"Documents/User%08d/%@",
              selectUserID, oti.getFileName]];
        }
        
        float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        // メール送信待機ダイアログ表示
        // (iOS8だと、横画面の時に正しく表示されないため、非表示に)
        if (iOSVersion < 8.0f) {
            [SVProgressHUD showWithStatus:@"メール送信中...." maskType:SVProgressHUDMaskTypeGradient];
        }
        
        // メール送信処理
        [sender mailSendTaskWithUserId:selectUserID
                            senderName:[senderName retain]
                           senderEmail:[senderEmail retain]
                                 title:[self.emailTitle.text retain]
                                  body:[self.emailText.text retain]
                              pictures:(NSArray *)pictures];
    }];
    
}
#endif
#pragma mark

- (void)mailSendThreadEnd:(NSDictionary*)respDic Code:(NSInteger)code
{
    // NSLog(@"%s",__func__);
    // メール送信待機ダイアログを閉じる
    [SVProgressHUD dismiss];
    
    //ポップアップを閉じる
    if(delegate != nil)
    {
        [delegate OnPopUpViewSet:MAILSEND_POPUP_ID setObject:nil];
    }
    
    [self closeByPopoverContoller];
    
    //スレッド実行フラグを無効化
    aliveThreadFlag = FALSE;
    
}//ポップアップの再表示
- (void)callReloadPopup
{
    //ポップの再表示を通知
    NSNotification *notif = [NSNotification notificationWithName:@"reloadMailPopup" object:nil];
    [[NSNotificationCenter defaultCenter]postNotification:notif];
}

//メールデータをデータベースに保存する
- (void)callMailDataSaveTask
{
    //設定されているメール情報を取得
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *beanArray = [manager selectUserMail];
    
    //データの存在チェックフラグ
    BOOL noDataFlag = FALSE;
    
    //署名
    NSString *shomei = @"";
    if ([beanArray count] != 0)
    {
        fcUserMailItemBean *bean = [beanArray objectAtIndex:0];
        if(bean.fix_text3 != nil){
            shomei = bean.fix_text3;
        }
    }else{
        noDataFlag = TRUE;
    }
    NSString *homepage = @"（社）日本BMK美健協会 本部\nE-mail : bmkinfomation@gmail.com\n協会HP : http://bmk-assoc.jp/association.html\n協会FB : http://www.facebook.com/bikenDougen";
    
    //email登録
    userDbManager *usrDbMng = [[userDbManager alloc] init];
	mstUser *user = [usrDbMng getMstUserByID:self.selectUserID];
    NSString *mail1 = user.email1;
    NSString *mail2 = user.email2;
    //メールが両方とも登録されていなかったら今回入力されたアドレスを設定する
    if(![mail1 length] && ![mail2 length] && [self.emailField1.text length] && [self.emailField2.text length]){
        NSString *newMail1 = self.emailField1.text;
        NSString *newMail2 = self.emailField2.text;
        NSString *saveAddr = [NSString stringWithFormat:@"%@@%@",newMail1, newMail2];
        user.email1 = saveAddr;
        [usrDbMng updateMstUser:user];
        // クラウドと同期処理の実行
        [CloudSyncClientManager clientUserInfoSyncProc: ^(SYNC_RESPONSE_STATE result)
         {
             if (result != SYNC_RSP_OK)
             {
                 NSLog(@"user infoの更新に失敗");
             }
             //メール送信
             [self callMailSendTask];
         }
                                                userId:self.selectUserID
         ];
    }else{
        //メール送信
        [self callMailSendTask];
    }
    
    [usrDbMng release];
    
    //smtpID
    NSInteger smtpID = 0;
    
    //タイトルID取得
    NSInteger titleID = [manager insertMailTitle:self.emailTitle.text];
    
    //入力されたメール本文を取得
    NSString *mailText = self.emailText.text;
    //改行で分離して一番上にある名前を取得する
    NSArray *mailTextArray = [mailText componentsSeparatedByString:@"\n"];
    NSString *name = [mailTextArray objectAtIndex:0];
    //メール本文から名前の部分を削除
    NSString *replaceText1 = [mailText stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@\n", name] withString:@""];
    //署名を削除
    NSString *replaceText2 = [replaceText1 stringByReplacingOccurrencesOfString:shomei withString:@""];
    //協会ホームページを削除
    NSString *saveText = [replaceText2 stringByReplacingOccurrencesOfString:homepage withString:@""];
    
    //データベースに保存
    if (noDataFlag) {
        //新規なら追加
        [manager insertUserMail:smtpID TitleID:titleID MailHead1:@"" MailHead2:@"" MailSignature:shomei MailText:saveText];
    }else{
        //データがあるなら更新
        [manager updateUserMail:smtpID TitleID:titleID MailHead1:@"" MailHead2:@"" MailSignature:shomei MailText:saveText];
    }
    
    [manager release];
}

- (IBAction)OnCancelButton:(id)sender {
    if(delegate != nil)
    {
        [delegate OnPopUpViewSet:-1 setObject:nil];
    }

    [self closeByPopoverContoller];
}

//メールにCCを追加
- (IBAction)addMailCC:(UIButton *)sender
{
    //アラートであて先(CC)入力画面を表示
    ccAlert = [[UIAlertView alloc] initWithTitle:@"あて先(CC)入力"
                                                    message:@" "
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    ccAlert.tag = 302;
	ccTextField = [[UITextField alloc] initWithFrame:CGRectMake(12, 45, 260, 25)];
    //一時保存にデータがあればそれを表示
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    BOOL callCCFlag = [userDefault boolForKey:@"ccAlertShowFlag"];
    if (callCCFlag) {
        ccTextField.text = [userDefault stringForKey:@"mailEditCC"];
    }else{
        //なければ保存されているCCを表示
        if(ccText != nil){
            ccTextField.text = ccText;
        }
    }
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 60);
	[ccAlert setTransform:transform];
	[ccTextField setBackgroundColor:[UIColor whiteColor]];
	[ccAlert addSubview:ccTextField];
	[ccAlert show];
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
    BOOL isPortlate = (imgWidth<=imgHeight)? YES : NO;
    CGSize resized_size;

    if (isPortlate) {
        resized_size.height = 240;
        resized_size.width  = 240*imgWidth/imgHeight;
    } else {
        resized_size.width  = 320;
        resized_size.height = 320*imgHeight/imgWidth;
    }

    UIGraphicsBeginImageContext(resized_size);
    [img drawInRect:CGRectMake(0, 0, resized_size.width, resized_size.height)];
    UIImage* resized_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized_image;
}

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short _base64DecodingTable[256] = {
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
	-2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
	-2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};

- (NSString *) base64EncodeString: (NSString *) strData {
	return [self base64EncodeData: [strData dataUsingEncoding: NSISO2022JPStringEncoding] ];
}

- (NSString *) base64EncodeData: (NSData *) objData {
	const unsigned char * objRawData = [objData bytes];
	char * objPointer;
	char * strResult;
    
	// Get the Raw Data length and ensure we actually have data
	int intLength = (int)[objData length];
	if (intLength == 0) return nil;
    
	// Setup the String-based Result placeholder and pointer within that placeholder
	strResult = (char *)calloc(((intLength + 2) / 3) * 4, sizeof(char));
	objPointer = strResult;
    
	// Iterate through everything
	while (intLength > 2) { // keep going until we have less than 24 bits
		*objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
		*objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
		*objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
		*objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
        
		// we just handled 3 octets (24 bits) of data
		objRawData += 3;
		intLength -= 3;
	}
    
	// now deal with the tail end of things
	if (intLength != 0) {
		*objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
		if (intLength > 1) {
			*objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
			*objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
			*objPointer++ = '=';
		} else {
			*objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
			*objPointer++ = '=';
			*objPointer++ = '=';
		}
	}
    
	// Terminate the string-based result
	*objPointer = '\0';
    
	// Return the results as an NSString object
	return [NSString stringWithCString:strResult encoding:NSASCIIStringEncoding];
}

+ (NSData *) base64DecodeString: (NSString *) strBase64 {
	const char * objPointer = [strBase64 cStringUsingEncoding:NSASCIIStringEncoding];
	int intLength = (int)strlen(objPointer);
	int intCurrent;
	int i = 0, j = 0, k;
    
	unsigned char * objResult;
	objResult = calloc(intLength, sizeof(char));
    
	// Run through the whole string, converting as we go
	while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
		if (intCurrent == '=') {
			if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
				// the padding character is invalid at this point -- so this entire string is invalid
				free(objResult);
				return nil;
			}
			continue;
		}
        
		intCurrent = _base64DecodingTable[intCurrent];
		if (intCurrent == -1) {
			// we're at a whitespace -- simply skip over
			continue;
		} else if (intCurrent == -2) {
			// we're at an invalid character
			free(objResult);
			return nil;
		}
        
		switch (i % 4) {
			case 0:
				objResult[j] = intCurrent << 2;
				break;
                
			case 1:
				objResult[j++] |= intCurrent >> 4;
				objResult[j] = (intCurrent & 0x0f) << 4;
				break;
                
			case 2:
				objResult[j++] |= intCurrent >>2;
				objResult[j] = (intCurrent & 0x03) << 6;
				break;
                
			case 3:
				objResult[j++] |= intCurrent;
				break;
		}
		i++;
	}
    
	// mop things up if we ended on a boundary
	k = j;
	if (intCurrent == '=') {
		switch (i % 4) {
			case 1:
				// Invalid state
				free(objResult);
				return nil;
                
			case 2:
				k++;
				// flow through
			case 3:
				objResult[k] = 0;
		}
	}
    
	// Cleanup and setup the return NSData
	NSData * objData = [[[NSData alloc] initWithBytes:objResult length:j] autorelease];
	free(objResult);
	return objData;
}
-(NSString*) getDocumentPath:(OKDThumbnailItemView*)item
{
	// パスなしファイル名をサムネイルItemより取得
	NSString *fileName = [item getFileName];
	
	// Imageファイル管理のインスタンスを生成
	OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID:selectUserID];
	
	// HomeDirectory部を取り除く
	// ret = [fullPath substringFromIndex:([ NSHomeDirectory() length] + 1) ];
	
	// Document以下のファイル名に変換
	NSString *documentFileName =
    [imgFileMng getDocumentFolderFilename:fileName];
	
	[imgFileMng release];
	
	return (documentFileName);
}
@end
