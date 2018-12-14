//
//  AppSettingPopupVC.m
//  iPadCamera
//
//  Created by Long on 2018/01/29.
//

#import "AppSettingPopupVC.h"

#define ACCOUNT_ID_SAVE_KEY             @"accountIDSave"        // アカウントIDの保存用Key
#define ACCOUNT_PWD_SAVE_KEY            @"accountPwdSave"        // アカウントパスワードの保存用Key
#define VERSION_UP_URL_KEY              @"version_up_url"
#define MEMO_UPPER_KEY                  @"memo1Label"
#define MEMO_DOWN_KEY                   @"memo2Label"
#define MEMO_FREE_KEY                   @"memoFreeLabel"
#define APP_LEVEL_KEY                   @"application_level"
#define WEB_SERVER_PORT_NO_KEY          @"webSeverPortNum"
#define MAIL_SEND_RECV_ENABLE_KEY       @"mailSendRecvEnable"
#define PRINTER_ENABLE_KEY              @"printer_enable"
#define WEB_CAMERA_INTERVAL             @"web_camera_interval"
#define WEB_CAMERA_COMMAND_KEY          @"web_camera_command"
#define WEB_CAMERA_COMMAND              @"SnapshotJPEG?Resolution=800x600&Quality=Clarit"
#define WEB_CAMERA_PREV_WAIT            0.15f
#define WEB_CAMERA_URL                  @"192.168.152.50"
#define WEB_CAMERA_URL_KEY              @"web_camera_url"
#define AIR_MICRO_ENABLE_KEY            @"airmicro_enable"
#define AIR_MICRO_SSID                  @"airmicro_ssid"
#define CAMERA_3R_ENABLE_KEY            @"3rcamera_enable"

@interface AppSettingPopupVC (){
    NSUserDefaults *defaults;
    NSString *webMailServer;
    NSInteger onAir;
    NSInteger onPrinter;
    NSInteger on3R;
    BOOL onMemoChange;
}

// IBAction
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIView *infoView;
@property (retain, nonatomic) IBOutlet UIButton *btnCancel;
@property (retain, nonatomic) IBOutlet UIButton *btnConfirm;
// Air Micro
@property (retain, nonatomic) IBOutlet UISwitch *switchAir;
// 3R Camera
@property (retain, nonatomic) IBOutlet UISwitch *switch3R;
// Web camera
//@property (retain, nonatomic) IBOutlet UITextField *tfCameraURL;
//@property (retain, nonatomic) IBOutlet UITextField *tfCameraCommand;
//@property (retain, nonatomic) IBOutlet UITextField *tfUpdateInterval;
// Printer
@property (retain, nonatomic) IBOutlet UISwitch *switchPrinter;
// Memo
@property (retain, nonatomic) IBOutlet UITextField *tfUpperNote;
@property (retain, nonatomic) IBOutlet UITextField *tfDownNote;
@property (retain, nonatomic) IBOutlet UITextField *tfFreeNote;
// Appinfo
@property (retain, nonatomic) IBOutlet UITextField *tfVersion;
@property (retain, nonatomic) IBOutlet UITextField *tfAccount;
@property (retain, nonatomic) IBOutlet UITextField *tfMail;

@property (retain, nonatomic) IBOutlet NSLayoutConstraint *height3R;
@end

@implementation AppSettingPopupVC

- (instancetype)init
{
    self = [super initWithNibName:@"AppSettingPopup" bundle:nil];
    if (self != nil)
    {
        // Further initialization if needed
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    defaults = [NSUserDefaults standardUserDefaults];
    [self config];
}

#pragma mark - Config

-(void) config
{
    webMailServer = @"webmail@abcarte.jp";
    //scrollview
    _scrollView.delegate = self;
    _tfUpperNote.delegate = self;
    _tfDownNote.delegate = self;
    _tfFreeNote.delegate = self;
    
    self.heightInforView.constant = 700;
    
    //hide 3R
    self.height3R.constant = 0;
    
    //round button
    _btnCancel.layer.cornerRadius = 10;
    _btnCancel.clipsToBounds = YES;
    _btnConfirm.layer.cornerRadius = 10;
    _btnConfirm.clipsToBounds = YES;
    
    onAir = 0;
    onPrinter = 0;
    on3R = 0;
    
    [self getInfo];
}

#pragma mark - LoadData
- (void) getInfo {

    //Air Micro
    BOOL isAir = [defaults boolForKey:AIR_MICRO_ENABLE_KEY];
    if (!isAir) {
        isAir = NO;
        [defaults setBool:isAir forKey:AIR_MICRO_ENABLE_KEY];
        [defaults synchronize];
    }
    [_switchAir setOn:isAir];
    
    //3R Camera
//    [defaults setBool:false forKey:CAMERA_3R_ENABLE_KEY];
//    [defaults synchronize];
    
//    BOOL is3R = [defaults boolForKey:CAMERA_3R_ENABLE_KEY];
//    if (!is3R) {
//        is3R = NO;
//        [defaults setBool:is3R forKey:CAMERA_3R_ENABLE_KEY];
//        [defaults synchronize];
//    }
//    [_switch3R setOn:is3R];
    
//    // Web Camera
//    NSString *url = [defaults objectForKey:WEB_CAMERA_URL_KEY];
//    if ( url == NULL)
//    {
//        url = WEB_CAMERA_URL;
//        [defaults setValue:url forKey:WEB_CAMERA_URL_KEY];
//        [defaults synchronize];
//    }
//    _tfCameraURL.text = url;
//
//    NSString *cmd = [defaults objectForKey:WEB_CAMERA_COMMAND_KEY];
//    if ( cmd == NULL)
//    {
//        cmd = WEB_CAMERA_COMMAND;
//        [defaults setValue:cmd forKey:WEB_CAMERA_COMMAND_KEY];
//        [defaults synchronize];
//    }
//    _tfCameraCommand.text = cmd;
//
//    NSInteger interval = [defaults integerForKey:WEB_CAMERA_INTERVAL];
//    if (!interval)
//    {
//        _prevWaitInterval = WEB_CAMERA_PREV_WAIT;
//        [defaults setInteger:((CGFloat)_prevWaitInterval * 1000.0f) forKey:WEB_CAMERA_INTERVAL];
//        [defaults synchronize];
//        NSInteger interval = [defaults integerForKey:WEB_CAMERA_INTERVAL];
//        _tfUpdateInterval.text = [@(interval) stringValue];
//    } else {
//        _tfUpdateInterval.text = [@(interval) stringValue];
//    }
    
    //Printer
    BOOL print = NO;
    if (! [defaults objectForKey:PRINTER_ENABLE_KEY])
    {
        [defaults setBool:print forKey:PRINTER_ENABLE_KEY];
        [defaults synchronize];
        [_switchPrinter setOn:print];
    }
    else {
        print = [defaults boolForKey:PRINTER_ENABLE_KEY];
        [_switchPrinter setOn:print];
    }
    
    //Memo
    NSString *memo1  = [defaults stringForKey:MEMO_UPPER_KEY];
    NSString *memo2  = [defaults stringForKey:MEMO_DOWN_KEY];
    NSString *memo  = [defaults stringForKey:MEMO_FREE_KEY];
    
    _tfUpperNote.text = memo1;
    _tfDownNote.text = memo2;
    _tfFreeNote.text = memo;
    
    //AppInfo
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    _tfVersion.text = version;
    
    NSString *accID  = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
    if(accID==NULL) {
        accID = @"未登録";
    }
    _tfAccount.text = accID;
    
    [self getMailInfo];
}

- (void)getMailInfo {
    AccountInfoForWebMail *accountManager = [[AccountInfoForWebMail alloc] initWithDelegate:self];
    [accountManager getAccountInfo];
}

- (void)finishedGetAccountInfoWithCompanyName:(NSString *)companyName email:(NSString *)email exception:(NSException *)exception {
    //2016/1/5 TMS ストア・デモ版統合対応 メール送信情報編集はストア版のみ機能する
#ifndef FOR_SALES
    if (exception != nil) {
        // 接続に失敗した時のみ、ローカルに保存された値を表示する。
        companyName = @"";
        email = @"";
        userFmdbManager *manager = [[userFmdbManager alloc]init];
        [manager initDataBase];
        NSMutableArray *infoBeanArray = [manager selectMailSmtpInfo:1];
        if([infoBeanArray count] != 0){
            mstUserMailItemBean *bean = [infoBeanArray objectAtIndex:0];
            _tfMail.text = bean.smtp_user;
//            email = bean.sender_addr;
        }
        [manager release];
    }
    _tfMail.text = companyName;
//    txtMailAddress.text = email;
#endif
}

- (void)dealloc {
    [_scrollView release];
    [_infoView release];
    [_heightInforView release];
    [_btnCancel release];
    [_switchAir release];
//    [_tfCameraURL release];
//    [_tfCameraCommand release];
//    [_tfUpdateInterval release];
    [_switchPrinter release];
    [_tfUpperNote release];
    [_tfDownNote release];
    [_tfFreeNote release];
    [_tfVersion release];
    [_tfAccount release];
    [_btnConfirm release];
    [_switch3R release];
    [_height3R release];
    [_tfMail release];
    [super dealloc];
}

#pragma mark - IBAction

- (IBAction)btnCancelPressed:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)btnConfirmPressed:(id)sender {
    AccountInfoForWebMail *accountManager = [[AccountInfoForWebMail alloc] initWithDelegate:self];
    [accountManager setCompanyName:_tfMail.text email:webMailServer];
    
    if (_tfUpperNote.text.length > 0 && _tfDownNote.text.length > 0 && _tfFreeNote.text.length > 0) {
        if (onAir == 1) {
            [defaults setBool:true forKey:AIR_MICRO_ENABLE_KEY];
        } else if (onAir == 2) {
            [defaults setBool:false forKey:AIR_MICRO_ENABLE_KEY];
            
            camaraViewController *cameraView
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView;
            
            if (cameraView)
            {
                [cameraView destroyAirMicro];
            }
        }
        
        if (on3R == 1) {
            [defaults setBool:true forKey:CAMERA_3R_ENABLE_KEY];
        } else if (on3R == 2) {
            [defaults setBool:false forKey:CAMERA_3R_ENABLE_KEY];
            
            camaraViewController *cameraView
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView;
            
            if (cameraView)
            {
                [cameraView dismiss3RCamera];
            }
        }
        
        if (onPrinter == 1) {
            [defaults setBool:true forKey:PRINTER_ENABLE_KEY];
        } else if (onPrinter == 2) {
            [defaults setBool:false forKey:PRINTER_ENABLE_KEY];
        }
        
        if (onMemoChange) {
            [defaults setObject:_tfUpperNote.text forKey:MEMO_UPPER_KEY];
            [defaults setObject:_tfDownNote.text forKey:MEMO_DOWN_KEY];
            [defaults setObject:_tfFreeNote.text forKey:MEMO_FREE_KEY];
        }
        
        NSLog(@"up %@ down %@ free %@",_tfUpperNote.text,_tfDownNote.text,_tfFreeNote.text);
        [defaults synchronize];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"reloadMemo" object:nil];
        [self dismissViewControllerAnimated:true completion:nil];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"お知らせ" message:@"メモのいずれかのタイトルが設定されていません。" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)finishedSetAccountInfoWithCompanyName:(NSString *)companyName email:(NSString *)email exception:(NSException *)exception {
    //2016/1/5 TMS ストア・デモ版統合対応 メール送信情報編集はストア版のみ機能する
#ifndef FOR_SALES
    if (exception == nil) {
        
        userFmdbManager *userFmdbMng = [[userFmdbManager alloc]init];
        [userFmdbMng initDataBase];
        
        NSMutableArray *beanArray = [userFmdbMng selectMailSmtpInfo:1];
        if([beanArray count] <= 0)
        {
            //データが無ければ新規でインサート
            [userFmdbMng insertMailSmtpInfo: webMailServer SmtpUser: _tfMail.text];
        }else{
            //データがあればアップデート
            [userFmdbMng updateMailSmtpInfo: webMailServer SmtpUser: _tfMail.text];
        }
        [userFmdbMng release];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"通信エラー"
                                                                       message:@"送信者・送信アドレスの変更に失敗しました。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertViewStyleDefault
                                                handler:nil]];
        
        [self presentViewController:alert animated:NO completion:nil];
    }
#endif
}

- (IBAction)onSwitchAir:(id)sender {
    UISwitch *mySwitch = (UISwitch *)sender;
    if ([mySwitch isOn]) {
        onAir = 1;
    } else {
        onAir = 2;
    }
}

- (IBAction)onSwitch3R:(id)sender {
    UISwitch *mySwitch = (UISwitch *)sender;
    if ([mySwitch isOn]) {
        on3R = 1;
    } else {
        on3R = 2;
    }
}

- (IBAction)onSwitchPrinter:(id)sender {
    UISwitch *mySwitch = (UISwitch *)sender;
    if ([mySwitch isOn]) {
        onPrinter = 1;
    } else {
        onPrinter = 2;
    }
}

#pragma mark - Delegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (((textField.tag == 2) || (textField.tag == 3) || (textField.tag == 4)) && textField.text.length > 0) {
        onMemoChange = true;
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    return YES;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [self.view endEditing:YES];
    return YES;
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
    {
        // Assign new frame
        CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        [UIView animateWithDuration:0.3 animations:^{
            CGRect f = self.view.frame;
            f.origin.y = -keyboardSize.height/2;
            self.view.frame = f;
        }];
    }
}

-(void)keyboardDidHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = 0.0f;
        self.view.frame = f;
    }];
}

#pragma mark - Gesture

#pragma mark - Utils


@end
