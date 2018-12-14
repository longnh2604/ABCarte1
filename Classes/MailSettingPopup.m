//
//  MailSettingPopup.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/11.
//
//

#import "MailSettingPopup.h"
#import "Common.h"
#import "userFmdbManager.h"

@interface MailSettingPopup ()

@end

@implementation MailSettingPopup
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

// 初期化 :
- (id) initPopUpViewWithPopupID:(NSUInteger)popUpID
			  popOverController:(UIPopoverController*)controller
					   callBack:(id)callBackDelegate
{
    if (self = [super initWithPopUpViewContoller:popUpID
                               popOverController:controller
                                        callBack:callBackDelegate
                                         nibName:@"MailSettingPopup"]){
        AccountInfoForWebMail *accountManager = [[AccountInfoForWebMail alloc] initWithDelegate:self];
        [accountManager getAccountInfo];
        _senderName = @"";
        _mailAddress = @"";
        addressOK = NO;
        nameOK = NO;
    }
	return (self);
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
            companyName = bean.smtp_user;
            email = bean.sender_addr;
        }
        [manager release];
        
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"エラー" message:@"サーバに接続出来ません。\n情報は最新ではない可能性があります。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    txtSenderName.text = companyName;
    txtMailAddress.text = email;
#endif
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
    
	// titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
	
	txtMailAddress.text = _mailAddress;
    txtSenderName.text = _senderName;
    
    txtMailAddress.enabled = NO;        // メールアドレスは読取専用
    
    [btnReset setBackgroundColor:[UIColor whiteColor]];
    [[btnReset layer] setCornerRadius:6.0];
    [btnReset setClipsToBounds:YES];
    [[btnReset layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnReset layer] setBorderWidth:1.0];
    
    [btnOK setBackgroundColor:[UIColor whiteColor]];
    [[btnOK layer] setCornerRadius:6.0];
    [btnOK setClipsToBounds:YES];
    [[btnOK layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnOK layer] setBorderWidth:1.0];

    [btnCancel setBackgroundColor:[UIColor whiteColor]];
    [[btnCancel layer] setCornerRadius:6.0];
    [btnCancel setClipsToBounds:YES];
    [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnCancel layer] setBorderWidth:1.0];
}

- (void)viewDidAppear:(BOOL)animated
{
	// キーボードの表示
	[txtSenderName becomeFirstResponder];
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
    [btnReset release];
    btnReset = nil;
    [btnCancel release];
    btnCancel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    
	[_mailAddress release];
	
    [btnReset release];
    [btnCancel release];
	[super dealloc];
}

#pragma mark text_field_events

// 編集開始
// - (IBOutlet) onTextEditBegin:(id)sender;

// 文字列変更
- (IBAction) onChangeMailAddress:(id)sender
{
	// ３文字以上入力されていて、@がふくまれていればOKボタンを有効にする
	addressOK = NO;
	if([txtMailAddress.text length] > 3)
	{
		NSRange range = [txtMailAddress.text rangeOfString:@"@"];
		if (range.location != NSNotFound)
		{	addressOK = YES; }
	}
	
	btnOK.enabled = addressOK && nameOK;
}
// 文字列変更
- (IBAction) onChangeName:(id)sender
{
	// 1文字以上入力されていればOKボタンを有効にする
	nameOK = NO;
	if([txtSenderName.text length] > 0)
	{
        nameOK = YES;
	}
	
	btnOK.enabled = addressOK && nameOK;
}
// 編集終了
- (IBAction) onTextDidEnd:(id)sender
{
	
}

// リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender
{
	// キーボードを閉じる
	[ ((UITextField*)sender) resignFirstResponder];
	
	// OKボタンの押下と同様とする
	if ( btnOK.enabled)
	{
		[self OnSetButton:btnOK];
	}
}

#pragma mark button_events
- (IBAction)onResetButton:(id)sender {
    UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"確認" message:@"通知メールアドレスをデフォルトにリセットします。" delegate:self cancelButtonTitle:@"はい" otherButtonTitles:@"いいえ" ,nil];
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        
//2016/1/5 TMS ストア・デモ版統合対応 メール送信情報編集はストア版のみ機能する
#ifndef FOR_SALES
        AccountInfoForWebMail *accountManager = [[AccountInfoForWebMail alloc] initWithDelegate:self];
        [accountManager resetAccountInfo];
#endif
    }
}
- (void)finishedResetAccountInfoWithCompanyName:(NSString *)companyName email:(NSString *)email exception:(NSException *)exception{
    if (exception == nil) {
        txtSenderName.text = companyName;
        txtMailAddress.text = email;
        userFmdbManager *userFmdbMng = [[userFmdbManager alloc]init];
        [userFmdbMng initDataBase];
        
        NSMutableArray *beanArray = [userFmdbMng selectMailSmtpInfo:1];
        if([beanArray count] <= 0)
        {
            //データが無ければ新規でインサート
            [userFmdbMng insertMailSmtpInfo: txtMailAddress.text SmtpUser: txtSenderName.text];
        }else{
            //データがあればアップデート
            [userFmdbMng updateMailSmtpInfo: txtMailAddress.text SmtpUser: txtSenderName.text];
        }
        [userFmdbMng release];
    } else {
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"通信エラー" message:@"送信者アドレスのリセットに失敗しました。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}
#pragma mark override

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
    AccountInfoForWebMail *accountManager = [[AccountInfoForWebMail alloc] initWithDelegate:self];
    [accountManager setCompanyName:txtSenderName.text email:txtMailAddress.text];
    // パスワード入力された文字を返す
	return (txtMailAddress.text);
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
            [userFmdbMng insertMailSmtpInfo: txtMailAddress.text SmtpUser: txtSenderName.text];
        }else{
            //データがあればアップデート
            [userFmdbMng updateMailSmtpInfo: txtMailAddress.text SmtpUser: txtSenderName.text];
        }
        [userFmdbMng release];
    } else {
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"通信エラー" message:@"送信者・送信アドレスの変更に失敗しました。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
#endif
}
#pragma mark public_methods

@end
