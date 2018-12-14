    //
//  PcBackupViewController.m
//  iPadCamera
//
//  Created by MacBook on 11/08/05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "userDbManager.h"

#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"

#import "DocumentsArchiver.h"

#import "PcBackupViewController.h"

#import "SecurityManagerView.h"
#ifdef HTTP_ON
#import "HttpFileUpDownLoaderManager.h"
#endif
#import "MailAddressSetPopup.h"
 
// 総数などの無効文字列
#define TOTAL_NUMS_INVALID_STRING		@"-----"

// 圧縮・解凍処理終了フラグ
#define ARCHIVE_PROC_COMLETE			0x8000

// メール送信ボタンで有効なTag
#define MAIL_SEND_INVALID_TAG			0x00		// 無効
#define MAIL_SEND_BACKUP_TAG			0x01		// バックアップ
#define MAIL_SEND_RESTORE_TAG			0x02		// 復元
#define MAIL_SEND_NEW_BACKUP_TAG		0x11		// 最新バックアップ

// メールアドレス設定PopupID
#define MAIL_ADDRESS_SET				0x0010

@implementation PcBackupViewController

@synthesize delegate;

#pragma mark private_mothods

// スワイプのセットアップ
- (void) setupSwipSupport
{
	// 右方向スワイプ:前画面に戻る
	UISwipeGestureRecognizer *swipeGestue = [[UISwipeGestureRecognizer alloc]
											 initWithTarget:self action:@selector(OnBackView:)];
	swipeGestue.direction = UISwipeGestureRecognizerDirectionRight;
	swipeGestue.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeGestue];
	[swipeGestue release];
	
}

// コントロールの角を丸める
- (void) controlsCornerRadius
{
	[Common cornerRadius4Control:lblTitle ];
	[Common cornerRadius4Control:vwBackupContiner ];
	[Common cornerRadius4Control:vwBackupNowState ];
	[Common cornerRadius4Control:vwRestoreContiner ];
	[Common cornerRadius4Control:vwRestoreData ];
}

// 現在の状況の設定
- (void) nowStatSetting
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	
	// データベースより情報を取得
	NSDictionary *infos = [usrDbMng getAllUsersNumNowState];
	if (infos)
	{
		lblBackUserTotal.text 
			= [NSString stringWithFormat:@"%@", [infos objectForKey:@"user_nums"]];
		lblBackPictureTotal.text 
			= [NSString stringWithFormat:@"%@", [infos objectForKey:@"picture_nums"]];
		lblBackHistTotal.text 
			= [NSString stringWithFormat:@"%@", [infos objectForKey:@"hist_nums"]];
	}
	else
	{
		lblBackUserTotal.text = TOTAL_NUMS_INVALID_STRING;
		lblBackPictureTotal.text = TOTAL_NUMS_INVALID_STRING;
		lblBackHistTotal.text = TOTAL_NUMS_INVALID_STRING;
	}		   
	
	[usrDbMng release];
}

// 日付をyyyymmdd形式に変更する
- (NSString*) convDate2Uint:(NSDate*)date isFilenameType:(BOOL)isFileType
{
	if (! date)
	{	return @""; }
	
	NSCalendar *cal 
		= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	// 年、月、日を求める
	unsigned int flag = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
	NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	
	NSDateComponents *comps = [cal components:flag fromDate:date];
	
	NSString *uintDate 
		= (isFileType)?
			[NSString stringWithFormat:@"%04ld%02ld%02ld_%02ld%02ld%02ld",
             (long)[comps year], (long)[comps month], (long)[comps day],
             (long)[comps hour], (long)[comps minute], (long)[comps second] ] :
			[NSString stringWithFormat:@"%04ld年%02ld月%02ld日　%02ld時%02ld分%02ld秒",
             (long)[comps year], (long)[comps month], (long)[comps day],
             (long)[comps hour], (long)[comps minute], (long)[comps second] ];
	
	[cal release];
	
	return (uintDate);
}

// 圧縮・解凍処理のコントロール設定：待機処理のコンテナとボタンの設定
- (void) setControls4Proccess:(BOOL)isProc
{
	BOOL stat = !isProc;
	
	// ボタンを操作不可に
	btnBackupMake.enabled = stat;
	btnRestoreData.enabled = stat;
	btnPrevBackView.enabled = stat;
	
	// 待機処理のコンテナ表示
	prgWaitProgress.progress = 0.0f;
	vwWaitMessageContiner.hidden = stat;
	if (isProc)
	{	[actIndicator startAnimating]; }
	else 
	{	[actIndicator stopAnimating];}
	
	// とりあえずキーボードは毎回閉じる
	[ txtBackMemo resignFirstResponder];
			
	// 待機処理のコンテナをaninamtion
	vwWaitMessageContiner.alpha = (isProc)? 0.0f : 1.0f;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.5f];
	
	vwWaitMessageContiner.alpha = (isProc)? 1.0f : 0.0f;
	
	[UIView commitAnimations];
}

// バックアップを作成
- (void) backUpMake
{
	// 圧縮情報の取得
	NSMutableDictionary *info = [NSMutableDictionary dictionary];
	[info setObject:[self convDate2Uint:[NSDate date] isFilenameType:NO] forKey:@"create_date"];
	[info setObject:txtBackMemo.text forKey:@"archive_memo"];
	[info setObject:lblBackUserTotal.text forKey:@"user_num"];
	[info setObject:lblBackPictureTotal.text forKey:@"picture_num"];
	[info setObject:lblBackHistTotal.text forKey:@"hist_nums"];
	
	DocumentsArchiver *archiver 
	= [[DocumentsArchiver alloc]initWithArchiveFileName:[self convDate2Uint:[NSDate date] isFilenameType:YES]
											   password:_password
											archiveInfo:info
												 client:self];
	[archiver autorelease];
	
	// 待機処理のコンテナ表示とボタン設定
	lblWaitMessage.text = @"データのバックアップ中...";
	[self setControls4Proccess:YES];
	
	[archiver doArchiveWithOldAcrhDelete:YES];
}

// データの復元
- (void) dataRestore
{
	DocumentsArchiver *archiver 
	= [[DocumentsArchiver alloc]initWithPassword:_password
										  client:self];
	
	[archiver autorelease];
	
	// 待機処理のコンテナ表示とボタン操作不可
	lblWaitMessage.text = @"データの復元中...";
	[self setControls4Proccess:YES];
	
	[archiver doUnArchive];
}

// documentsフォルダより最新のバックアップファイルを取得
- (NSString*) getNewArchiveFile
{
	DocumentsArchiver *archiver = [[DocumentsArchiver alloc] initWithPassword:_password 
																	   client:self];
	
	NSString *file = [archiver searchBackupFile4Restore:nil isOnlyDouments:YES];
	
	[archiver release];
	
	return (file);
	
}

// メール送信ボタンの設定
- (void) mailSendButtonSetting
{
#ifdef HTTP_ON
	// httpサーバが起動していない場合は何もしない:ボタンはhiddenのまま
	iPadCameraAppDelegate *theApp = [UIApplication sharedApplication].delegate;
	if (! theApp.httpServerManager)
	{	return; }
	
	btnPcMailSend.tag = MAIL_SEND_INVALID_TAG;
	btnRestorePcMailSend.tag = MAIL_SEND_INVALID_TAG;
	btnPcMailSend.hidden = YES;
	btnRestorePcMailSend.hidden = YES;
    
    // メール送受信をするかの設定ファイルの確認
    BOOL isMail =[[NSUserDefaults standardUserDefaults] boolForKey:MAIL_SEND_RECV_ENABLE_KEY];
	
	// メールが送信できる場合のみ有効性の設定とhiddenを解除
	Class mail = (NSClassFromString(@"MFMailComposeViewController"));
	if (mail)
	{
		if([mail canSendMail])
		{
			btnMailSetting.hidden = !isMail;
			
			// メール送信の有効性をtagで設定
			btnPcMailSend.tag = MAIL_SEND_BACKUP_TAG;
			btnRestorePcMailSend.tag = MAIL_SEND_RESTORE_TAG;
			
			// hiddenを解除
			btnRestorePcMailSend.hidden = !isMail;
			// バックアップの場合はさらにファイルがあるかを確認
			if ( [self getNewArchiveFile] )
			{ 
				btnPcMailSend.hidden = !isMail; 
			}
			
		}
	}
#endif
}

// httpサーバのIPアドレスを取得
- (NSString*) getIPAddress
{
	// このメソッドがコールされること自体がmailSendButtonSettingによりhttpサーバが起動している
#ifdef HTTP_ON
    iPadCameraAppDelegate *theApp = [UIApplication sharedApplication].delegate;
	return ([theApp.httpServerManager getLocalIpAddress]);
#else
    return @"";
#endif
}

// 管理ファイルよりPC送信メールアドレスを取得
- (NSString*) getMailAddress4SendToPc
{
	NSString * addr;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (! (addr = [defaults stringForKey:@"MailAddress4SendToPc"]) )
	{
		addr = @"";
	}
	
	return (addr);
}

// 管理ファイルにPC送信メールアドレスを設定
- (void) setMailAddress4SendToPc:(NSString*)addr
{
	// 現在の設定値を確認
	NSString* nowAddr = [self getMailAddress4SendToPc];
	
	if ([nowAddr isEqualToString:addr])
	{	return; }		// 変更なし
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:addr forKey:@"MailAddress4SendToPc"];
	
	[defaults synchronize];
}

// メール送信
- (void) sendMailWithTitle:(NSString*) mailTitle mailBody:(NSString*)body
{
	// 本文の注記を追加
	NSMutableString *hBody = [NSMutableString string];
	[hBody appendString:@"----------------------------"];
	[hBody appendString:@"-------------------------------------------------------\n"];
	[hBody appendString:@"このメールはiPadアプリケーション「ABCarte」より送信されました\n"];
	[hBody appendString:@"お心当たりのない方は、このメールを削除していただくようにお願いします。\n"];
	[hBody appendString:@"----------------------------"];
	[hBody appendString:@"-------------------------------------------------------\n\n"];
	
	// メールコントローラ作成
	MFMailComposeViewController *mailVC
		= [[MFMailComposeViewController alloc] init];
	mailVC.mailComposeDelegate = self;
	
	// 管理ファイルよりPC送信メールアドレスを取得
	NSArray *to = [NSArray arrayWithObject:[self getMailAddress4SendToPc]];
	[mailVC setToRecipients:to];			// 宛先
	[mailVC setSubject:mailTitle];			// 件名
	[mailVC setMessageBody:[NSString stringWithFormat:@"%@%@", hBody, body] 
					isHTML:NO];				// 本文
	
    [self presentViewController:mailVC animated:YES completion:nil];
	[mailVC release];
}		 

#pragma mark life_cycle
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

// 初期化
- (id) initWithPassword:(NSString*)password
			  ownerView:(id)owner
			restoreCompleteHandler:(restoreComplete)handler
{
#ifdef CALULU_IPHONE
	self = [self initWithNibName:@"ip_PcBackupViewController" bundle:nil];
#else
	self = [self initWithNibName:@"PcBackupViewController" bundle:nil];
#endif
	if (self)
	{
		// パスワードの保存
		_password = password;
		
		self.delegate = owner;
		
		// データの復元の完了時のハンドラの保存  :_hRestorecomplete(self)
		_hRestorecomplete = handler;
			// _hRestorecomplete(self); -> ここでは実行できる
		
		popoverMailSend = nil;
	}
	return (self);
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// スワイプのセットアップ
	[self setupSwipSupport];
	
	// コントロールの角を丸める
	[self controlsCornerRadius];
	
	// 現在の状況の設定
	[self nowStatSetting];
	
	// 復元される情報の設定
	[self restoreInfoSetting];
	
	// メール送信ボタンの設定
	[self mailSendButtonSetting];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
#ifdef CALULU_IPHONE
    return (UIInterfaceOrientationIsPortrait(interfaceOrientation));
#else
    return YES;
#endif
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewWillDisappear:(BOOL)animated
{
	// キーボードを閉じる
	[ txtBackMemo resignFirstResponder];
	
	// NSLog (@"itemEditerPopup viewWillDisappear");
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    if (popoverMailSend)
	{	[popoverMailSend release]; }
	
	[super dealloc];
}


#pragma mark control_events

// メールアドレス設定
- (IBAction) OnMailAddressSet:(id)sender
{
	if (popoverMailSend)
	{
		[popoverMailSend release];
		popoverMailSend = nil;
	}

	// メールアドレス設定PopupViewControllerのインスタンス生成
	MailAddressSetPopup *vcMailAddrSet
		=[[MailAddressSetPopup alloc]initPopUpViewWithPopupID:(NSUInteger)MAIL_ADDRESS_SET
												  mailAddress:[self getMailAddress4SendToPc]
											popOverController:nil callBack:self];
#ifndef CALULU_IPHONE
	// メールアドレス設定PopupViewControllerのサイズ
	CGSize szPopup = CGSizeMake(424.0f, 174.0f);
	vcMailAddrSet.contentSizeForViewInPopover = szPopup;
	
	// ポップアップViewの表示
	popoverMailSend = 
		[[UIPopoverController alloc] initWithContentViewController:vcMailAddrSet];
	vcMailAddrSet.popoverController = popoverMailSend;
	[popoverMailSend presentPopoverFromRect:btnMailSetting.frame
									inView:vwBackupContiner
				   permittedArrowDirections:UIPopoverArrowDirectionUp
								   animated:YES];
#else
    [MainViewController showModalDialog:vcMailAddrSet parentView:self.view isDispBottom:NO];
#endif
    
    [vcMailAddrSet release];
	
		  
}

// PCへメール送信
- (IBAction) OnPcMailSend:(id)sender
{
	NSInteger tag =  (sender)? ((UIButton*)sender).tag : MAIL_SEND_NEW_BACKUP_TAG;
	
	if (tag == MAIL_SEND_INVALID_TAG)
	{	return; }		// 念のため有効性を確認
	
	NSMutableString *body = [NSMutableString string];
	
	switch(tag)
	{
		// バックアップのメール送信
		case MAIL_SEND_NEW_BACKUP_TAG:
			[body appendString:@"最新のバックアップを「CaLuLu」よりこのパソコンに転送するには\n"];
			[body appendString:@"下記のURL（リンク）をクリックしてください\n\n\n"];
			[body appendFormat:@"%@/%@", 
				[self getIPAddress], [self getNewArchiveFile]];
			break;
		case MAIL_SEND_BACKUP_TAG:
			[body appendString:@"最新のバックアップを「CaLuLu」よりこのパソコンに転送するには\n"];
			[body appendString:@"下記のURL（リンク）をクリックしてください\n\n\n"];
			[body appendFormat:@"%@/backup.html", [self getIPAddress]];
			break;
		
		// データの復元のメール送信
		case MAIL_SEND_RESTORE_TAG:
			[body appendString:@"このパソコンにあるバックアップを「CaLuLu」に転送するには\n"];
			[body appendString:@"下記のURL（リンク）をクリックしてください\n\n\n"];
			[body appendFormat:@"%@/restore.html", [self getIPAddress]];
			break;
	}
	
	// メール送信
	[self sendMailWithTitle:(tag == 1)? @"バックアップをこのパソコンにダウンロード" :@"このパソコンから復元用データをアップロード" 
					   mailBody:body];
}

// バックアップを作成
- (IBAction) OnBackUpMake:(id)sender
{
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"確認願います"
							  message:@"バックアップを作成します\nよろしいですか？"
							  delegate:self
							  cancelButtonTitle:@"は　い" 
							  otherButtonTitles:@"いいえ", nil];
	alertView.tag = DOC_ARCHIVE_PROC_ZIP;
	[alertView show];
	[alertView release];
	
}

// PC転送データを削除
- (IBAction) OnPcRecvDataDelete:(id)sender
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;
	
	// Tempフォルダを検索
	NSString *tmpFolder = NSTemporaryDirectory();
	NSArray *fileList
		= [manager contentsOfDirectoryAtPath:tmpFolder error:&error];
	if (error)
	{	
		NSLog (@"OnPcRecvDataDelete fileList get error in temp folder:%@", error);
		return;
	}
	for (NSInteger idx = ([fileList count] -1); idx >= 0; idx--) // -> 降順
	{
		NSString *fileName = [fileList objectAtIndex:idx];
		if ([fileName hasSuffix:@"zip"])
		{
			// ファイルが見つかった
			NSString *file = [tmpFolder stringByAppendingPathComponent:fileName];
			
			// ファイルの削除
			[manager removeItemAtPath:file error:&error];
			if (error)
			{	
				NSLog (@"OnPcRecvDataDelete delete file error in temp folder:%@", error);
			}
		}
	}
	
	// 復元情報の更新
	[self restoreInfoSetting];
}

// 復元情報の更新
- (IBAction) OnUpadteRestoreInfo:(id)sender
{
	[self restoreInfoSetting];
}

// データの復元
- (IBAction) OnDataRestore:(id)sender
{
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"確認願います"
							  message:@"データを復元します\nよろしいですか？"
							  delegate:self
							  cancelButtonTitle:@"は　い" 
							  otherButtonTitles:@"いいえ", nil];
	alertView.tag = DOC_ARCHIVE_PROC_UNZIP;
	[alertView show];
	[alertView release];
}
// 前画面に戻る
- (IBAction) OnBackView:(id)sender
{
	
	// 圧縮・解凍処理中は遷移しない
	if (! vwWaitMessageContiner.hidden)
	{	return; }
	
	// MainViewControllerの取得
	MainViewController *mainVC 
	= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// popupWindowを閉じる
	[mainVC closePopupWindow:self];
	
}

// テキスト編集：リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender
{
	// キーボードを閉じる
	[ ((UITextField*)sender) resignFirstResponder];
}

#pragma mark DocumentsArchiverDelegate

// 処理の進捗
- (void) DocumentsArchiver:(id)sender 
		   progressPercent:(NSUInteger)percent ProcKind:(ZIP_UNZIP_PROC_KIND) kind
{
	// NSLog (@"progressPercent %03d[percent] kind:%d", percent, kind);
	prgWaitProgress.progress = (float)percent / 100.0f;
}

// 処理の完了
- (void) DocumentsArchiver:(id)sender 
		  completeProcKind:(ZIP_UNZIP_PROC_KIND) kind result:(BOOL)stat
{
	// NSLog (@"comlite proc %d result:%@", kind, (stat)? @"OK" : @"ERROR");
	
	// 待機処理のコンテナ表示とボタン操作可
	[self setControls4Proccess:NO];
    
    // メール送受信をするかの設定ファイルの確認
    BOOL isMail =[[NSUserDefaults standardUserDefaults] boolForKey:MAIL_SEND_RECV_ENABLE_KEY];
	
	// 結果ダイアログの表示
	NSMutableString *message = [NSMutableString string];
	[message appendFormat:@"%@\n",
				(kind == DOC_ARCHIVE_PROC_ZIP)? @"バックアップの作成" : @"データの復元"];
	[message appendFormat:@"%@", (stat)? @"が完了しました" : @"に失敗しました"];
	if ( (kind == DOC_ARCHIVE_PROC_UNZIP) && (stat) )
	{
		[message appendString:@"\n(OKをタッチすると\nお客様一覧画面を表示します)"];
	}
	else if ( (kind == DOC_ARCHIVE_PROC_ZIP) && (stat) && (isMail) )
	{
		// バックアップの作成でPCへのメール送信ボタンのhiddenを解除
		if (btnPcMailSend.tag == MAIL_SEND_BACKUP_TAG)
		{	btnPcMailSend.hidden = NO; }
		
		[message appendString:@"\nこのバックアップを\nPCでダウンロードできるように\nメール送信しますか？"];
	}
	
	UIAlertView *alertView;

	if ((kind == DOC_ARCHIVE_PROC_ZIP) && (stat) && (isMail) )
	{
		alertView = [[UIAlertView alloc]
					 initWithTitle:@"処理の完了"
					 message:message
					 delegate:self
					 cancelButtonTitle:@"は い" otherButtonTitles:@"いいえ", nil];
	}
	else
	{
		alertView = [[UIAlertView alloc]
							  initWithTitle:@"処理の完了"
							  message:message
							  delegate:( (kind == DOC_ARCHIVE_PROC_UNZIP) && (stat) )? self : nil 
							  cancelButtonTitle:@"OK" otherButtonTitles:nil];
	}
	alertView.tag = ARCHIVE_PROC_COMLETE | kind;
	
	[alertView show];
	[alertView release];
	
	// バックアップ処理完了時は、復元される情報の設定
	if ( (kind == DOC_ARCHIVE_PROC_ZIP) && (stat) )
	{	[self restoreInfoSetting]; }
}

#pragma mark UIAlertViewDelegate
// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSUInteger tagVal;
	if ( alertView.tag & ARCHIVE_PROC_COMLETE)
	{
		tagVal = alertView.tag & ~ARCHIVE_PROC_COMLETE;
		
		switch (tagVal) {
			case DOC_ARCHIVE_PROC_UNZIP:
				// データの復元の完了時のハンドラの実行
					// _hRestorecomplete(self);
				if ( (self.delegate) && 
					([self.delegate respondsToSelector:@selector(OnCompleteRestore:)]))
				{	[((id<SecurityManagerViewDelegate>)(self.delegate)) OnCompleteRestore:self]; }
				break;
			case DOC_ARCHIVE_PROC_ZIP:
				if (buttonIndex == 0)
				{
					// PCへメール送信ボタン （バックアップ）
					[self OnPcMailSend: btnPcMailSend];
				}
			default:
				break;
		}
	}
	else {
		
		if (buttonIndex != 0)
		{	return; }
		
		switch (alertView.tag) {
			case DOC_ARCHIVE_PROC_ZIP:
				// バックアップを作成
				[self backUpMake];
				break;
			case DOC_ARCHIVE_PROC_UNZIP:
				// データの復元
				[self dataRestore];
				break;
			default:
				break;
		}
	}

}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	NSString *message = nil;
	
	switch (result) {
		case MFMailComposeResultCancelled:
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
			message = @"メールを送信しました";
			break;
		case MFMailComposeResultFailed:
			message = @"メール送信に失敗しました\nネットワークの設定などを確認願います";
			break;
		default:
			break;
	}
	
    [self dismissViewControllerAnimated:YES completion:nil];
	
	if (!message)
	{	return; }
	
	UIAlertView *alert =[ [UIAlertView alloc]initWithTitle:@"メール送信" 
												   message:message 
												  delegate:nil 
										 cancelButtonTitle:@"O K"
										 otherButtonTitles:nil];
	[alert show];
	[alert release];
}

#pragma mark PopUpViewContollerBaseDelegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
	switch (popUpID) {
		case MAIL_ADDRESS_SET:
			// メールアドレスの設定
			[self setMailAddress4SendToPc:(NSString*)object];
			break;
		default:
			break;
	}
}

#pragma mark public_methods

// 復元される情報の設定
- (void) restoreInfoSetting
{
	DocumentsArchiver *archiver = [[DocumentsArchiver alloc] initWithPassword:_password 
																	   client:self];
	BOOL isFind;
	NSDictionary *infoTable = [archiver getArchiveInfoWithFindInTemp:&isFind];
	
	// 圧縮情報をコントロールに設定
	if (infoTable)
	{
		// Tempフォルダにある=PCからの転送データ
		btnPcRecvDataDelete.hidden	= (! isFind);
		lblRestoreDataSource.text	= (! isFind)? @"(iPad内バックアップ)" : @"(PC転送データ)";
		lblRestoreCreateDate.text	= [infoTable objectForKey:@"create_date"];
		lblRestoreMemo.text			= [infoTable objectForKey:@"archive_memo"];
		lblRestoreUserTotal.text	= [infoTable objectForKey:@"user_num"];
		lblRestorePictureTotal.text = [infoTable objectForKey:@"picture_num"];
		lblRestoreHistTotal.text	= [infoTable objectForKey:@"hist_nums"];
		btnRestoreData.enabled		= YES;
	}
	else {
		btnPcRecvDataDelete.hidden	= YES;
		lblRestoreDataSource.text	= (archiver.docArchiveError != DOC_ARCHIVE_PWD_COLLECT)?
										@"(復元できるデータはありません)" : @"(パスワードが異なっています)";
		lblRestoreCreateDate.text	= TOTAL_NUMS_INVALID_STRING;
		lblRestoreMemo.text			= TOTAL_NUMS_INVALID_STRING;
		lblRestoreUserTotal.text	= TOTAL_NUMS_INVALID_STRING;
		lblRestorePictureTotal.text = TOTAL_NUMS_INVALID_STRING;
		lblRestoreHistTotal.text	= TOTAL_NUMS_INVALID_STRING;
		btnRestoreData.enabled		= NO;
	}
	
	// PC転送データの場合は、Tempフォルダエラー内容を確認
	lblRestorePcTransDataError.text = @"";
	if (! isFind)
	{
		switch (archiver.docArchiveError4Temp) {
			case DOC_ARCHIVE_NO_ERROR:
				break;
			case DOC_ARCHIVE_PWD_COLLECT:
				lblRestorePcTransDataError.text 
					= @"PC転送データはパスワードが異なります";
				break;
			default:
				lblRestorePcTransDataError.text 
					= @"PC転送データはエラーのため削除しました";
				break;
		}
	}
	
	[archiver release];
}


@end
