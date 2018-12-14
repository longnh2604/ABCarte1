//
//  SecurityManagerView.m
//  iPadCamera
//
//  Created by MacBook on 11/07/14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SecurityManagerView.h"

#import "PasswordInputPopup.h"
#import "PasswordChangePopup.h"
#ifdef IN_APP_PURCHASES
#include "AppStoreConnector.h"
#endif

#include "defines.h"
#ifdef USE_ACCOUNT_MANAGER
#import "MainViewController.h"
#endif
#ifdef CALULU_IPHONE
#import "MainViewController.h"
#endif

@implementation SecurityManagerView

@synthesize delegate;
@synthesize securityFaze = _securityFaze;

#pragma mark local_methods

// alert表示
- (void) alertDisp:(NSString*) message alertTitle:(NSString*) altTitle
{
	
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:altTitle
							  message:message
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil
							  ];
	[alertView show];
	[alertView release];	
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView == tap4AlertView) {
        switch (buttonIndex) {
            case 0:
                // 最初にセキュリティFazeを移行する
                [self setSecurityFazeWithFaze:SECURITY_VIEW_LOCK];
                
                // 動作中表示用Imageを初期位置に移動
                [self moveRuntimeImage2Init];
                
                // 本Viewの表示状態の設定
                [self setDispState];
                
                // クライアントクラスにフェーズの変更を通知
                [self notifyClient2FazeChange];
                
                // 動作中表示用タイマの起動：停止は、タイマイベントの中で行う
                [NSTimer scheduledTimerWithTimeInterval:3.0f 
                                                 target:self selector:@selector(OnRuntimeDispTimer:) 
                                               userInfo:nil  repeats:YES]; 
                
                // 動作中表示用Imageの画面内移動のため、乱数を初期化しておく
                srandom((unsigned)time(NULL));
                break;
                
            default:
                break;
        }
    }
}

// セキュリティを設定する
- (void) setSecurityFazeWithFaze:(SECURITY_FAZE)faze;
{
	_securityFaze = faze;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// セキュリティのFazeを書き込み
	[defaults setObject:[NSNumber numberWithUnsignedInteger: _securityFaze] 
				 forKey:SECURITY_FAZE_KEY];
	
	[defaults synchronize];
}

// 前回のfazeとパスワードをuserConfigより取得
- (void) getFazePwd2UserConf
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// セキュリティのFaze
	id defObj = [defaults objectForKey:SECURITY_FAZE_KEY];
	if (!defObj) 
	{
		_securityFaze = SECURITY_NONE;
		[defaults setObject:[NSNumber numberWithUnsignedInteger: _securityFaze] 
					 forKey:SECURITY_FAZE_KEY];
	}
	else 
	{
		SECURITY_FAZE securFaze = [((NSNumber*)defObj) unsignedIntegerValue];
		
		switch (securFaze)
		{
			case (SECURITY_WINDOW_LOCK):
				// 画面ロックで終了していた場合はViewLockに変更する
				_securityFaze = SECURITY_VIEW_LOCK;
				break;
			case (SECURITY_NONE):
			case (SECURITY_VIEW_LOCK):
				_securityFaze = securFaze;
				break;
			case (SECURITY_PC_BACKUP):
				// PCバックアップで終了していた場合はセキュリテリなし：通常状態にする
				_securityFaze = SECURITY_NONE;
			default:
				_securityFaze = SECURITY_NONE;
				break;
		}
	}

	// 画面ロック用パスワード
	NSString *pwd = [defaults stringForKey:SECURITY_PWD_WIN_KEY];
	if ( (!pwd) || ((pwd) && ([pwd length] <= 0 ) ) )
	{
		_passwordWindow = SECURITY_PWD_INIT_VALUE;
		[defaults setObject:SECURITY_PWD_INIT_VALUE
					 forKey:SECURITY_PWD_WIN_KEY];
	}
	else 
	{
		_passwordWindow = [NSString stringWithString:pwd];
	}
	// PCバックアップ用パスワード
	NSString *pwd2 = [defaults stringForKey:SECURITY_PWD_BACKUP_KEY];
	if ( (!pwd2) || ((pwd2) && ([pwd2 length] <= 0 ) ) )
	{
		_passwordBackup = SECURITY_PWD_INIT_VALUE;
		[defaults setObject:SECURITY_PWD_INIT_VALUE
					 forKey:SECURITY_PWD_BACKUP_KEY];
	}
	else 
	{
		_passwordBackup = [NSString stringWithString:pwd2];
	}
	
	[defaults synchronize];
	
}

//スクリーンセイバー画面でパスワード入力ポップアップを呼び出す処理
- (void) openPwdPopup
{
    // パスワード入力Popupを開く
    [self openPwdInputPopup:POPUP_PASSWORD_INPUT_VIEW_LOCK];
}

// リソースの画像を確認
- (UIImage*) checkResorceImage
{
	UIImage *img = nil;
	
	// リソース画像の物理ファイルのフルパス
	NSArray *paths 
		= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *resPath 
		= [[paths objectAtIndex:0] stringByAppendingPathComponent:RUNTIME_DISP_IMAGE_FILE];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	
	//リソース画像が存在しているかどうかの確認
	if (![manager fileExistsAtPath:resPath]) 
	{
		NSError* error = nil;
		
		// リソース画像をバンドルからをDocmentフォルダにコピー
		NSString *tempPath 
			= [[[NSBundle mainBundle] resourcePath]
			   stringByAppendingPathComponent:RUNTIME_DISP_IMAGE_RES_FILE];
		if(! [manager copyItemAtPath:tempPath toPath:resPath error:&error] )
		{
			NSLog(@" checkResorceImage copy error %@", [error localizedDescription]);
			// 後で、リソースから直接生成
			img = nil;
		}
	}
	
	//  UIImageに変換
	NSData *fileDat = [NSData dataWithContentsOfFile:resPath];
	//[fileDat autorelease];
	img = [UIImage imageWithData:fileDat];
	
	if (! img)
	{
		// 変換失敗などは、リソースから直接生成
		img = [UIImage imageNamed:RUNTIME_DISP_IMAGE_RES_FILE];
	}
	
	return (img);
}

//動作中表示用ImageViewのインスタンス作成
- (void) makeRuntimeImgVw
{
	// リソースの画像を確認
	UIImage *img = [self checkResorceImage];
	// NSLog (@"makeRuntimeImgVw image size %f / %f", img.size.width, img.size.height);
	
	// ImageViewの生成:位置は、Timer内で設定する
	ivRuntimeDisp = [[UIImageView alloc] 
					 initWithFrame:CGRectMake(0.0f, 0.0f, img.size.width, img.size.height)];
	
	// リソースの画像を割り当てる
	ivRuntimeDisp.image = img;
	
	// 初期状態は非表示
	ivRuntimeDisp.hidden = YES;
	
	[self addSubview:ivRuntimeDisp];
}

// タップジェスチャーのセットアップ
- (void) tapGestureSupport
{
#ifndef AIKI_CUSTOM
#ifndef SCREEN_LOCK_DISABLE
	// 画面ロック　指2本で有効
	UITapGestureRecognizer *tapGesture2 
		= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnWindowLock)];
	tapGesture2.numberOfTouchesRequired = 2;	// 指2本
	tapGesture2.numberOfTapsRequired  = 2;		// ダブルタップ
	[ self.superview addGestureRecognizer:tapGesture2];
	[tapGesture2 release];
#endif
#endif
    
#ifdef DEF_CALULU1	
	// PCバックアップ　指3本で有効
	UITapGestureRecognizer *tapGesture3 
		= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnPcBackUp)];
	tapGesture3.numberOfTouchesRequired = 3;	// 指3本
	tapGesture3.numberOfTapsRequired  = 2;		// ダブルタップ
	[ self.superview addGestureRecognizer:tapGesture3];
	[tapGesture3 release];
#else
#if APPSTORE_DISTRIBUTION_VERSION && IN_APP_PURCHASES
    //App Storeへ
	UITapGestureRecognizer *tapGesture3
        = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnRegistApp)];
	tapGesture3.numberOfTouchesRequired = 3;		// 指3本
	tapGesture3.numberOfTapsRequired  = 2;		// ダブルタップ
	[ self.superview addGestureRecognizer:tapGesture3];
	[tapGesture3 release];
#endif
#endif
    // 2015/05/18 ４本指画面ロックの停止
#ifndef AIKI_CUSTOM
	// セキュリティ画面(スクリーンセーバー風)　指4本で有効
//	UITapGestureRecognizer *tapGesture4 
//		= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnScreenSaverShow)];
//	tapGesture4.numberOfTouchesRequired = 4;		// 指4本
//	tapGesture4.numberOfTapsRequired  = 2;		// ダブルタップ
//	[ self.superview addGestureRecognizer:tapGesture4];
//	[tapGesture4 release];
#endif
    
    // DBのバックアップを作成する。
    // CaluluII / ABCarte では無効とする
#ifdef ENABLE_BACKUP
	// PCバックアップ
	UITapGestureRecognizer *tapGesture5
        = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnPcBackUp)];
#ifndef MDM_DISTRIBUTION_VERSION
	tapGesture5.numberOfTouchesRequired = 5;	// 指5本
#else
    tapGesture5.numberOfTouchesRequired = 3;	// 指3本
#endif
	tapGesture5.numberOfTapsRequired  = 2;		// ダブルタップ
	[ self.superview addGestureRecognizer:tapGesture5];
	[tapGesture5 release];
#endif
    
}

// 本Viewの表示状態の設定
- (void) setDispState
{
	self.hidden = (_securityFaze != SECURITY_VIEW_LOCK);
}

// クライアントクラスにフェーズの変更を通知
- (void) notifyClient2FazeChange
{
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(securityManager:onChangeFaze:)]))
	{
		[self.delegate securityManager:self onChangeFaze:_securityFaze];
	}
}

// 動作中表示用Imageを初期位置に移動
- (void) moveRuntimeImage2Init
{
	// デバイスの有効な画面サイズを取得
	// CGSize szDev = [[UIScreen mainScreen] applicationFrame].size;
	CGSize szDev = self.frame.size;
	
	// 動作中表示用Imageのサイズ
	CGSize szImg = ivRuntimeDisp.frame.size;
	
	// 動作中表示用Imageを画面中央に移動
	ivRuntimeDisp.frame 
		= CGRectMake((szDev.width - szImg.width) / 2.0f, (szDev.height - szImg.height) / 2.0f, 
					 szImg.width, szImg.height);
	
	// 動作中表示用Imageを表示
	ivRuntimeDisp.hidden = NO;
} 

// 乱数により動作中表示用Imageを画面範囲内で移動させる
- (void) moveRuntimeImage2Random
{
	// デバイスの有効な画面サイズを取得 
	// applicationFrameはrandscape時に縦と横が逆になる：pplicationFrame size 748.000000 / 1024.000000
	// CGSize szDev = [[UIScreen mainScreen] applicationFrame].size;
	CGSize szDev = self.frame.size;
	
	/*NSLog (@"applicationFrame size %f / %f", szDev.width, szDev.height);
	NSLog (@"view size %f / %f", self.frame.size.width, self.frame.size.height);*/
	
	// 動作中表示用Imageのサイズ
	CGSize szImg = ivRuntimeDisp.frame.size;
	
	// 乱数により各座標位置：Imageが画面内に収まるようにする
	int xPos = rand() % ((NSInteger)(szDev.width - szImg.width));
	int yPos = rand() % ((NSInteger)(szDev.height - szImg.height));
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.5f];

	// 動作中表示用Imageを移動
	[ivRuntimeDisp setFrame: 
		CGRectMake((CGFloat)xPos, (CGFloat)yPos, szImg.width, szImg.height)];
	
	[UIView commitAnimations];
#ifdef DEBUG
	 NSLog (@"moveRuntimeImage2Random at %f / %f", (CGFloat)xPos, (CGFloat)yPos);
#endif
}

// インスタンス初期化
- (void) initInstance
{
	// NSLog(@"SecurityManagerView : initInstance");
		
	// 前回のfazeとパスワードをuserConfigより取得
	[self getFazePwd2UserConf];
	
	//動作中表示用ImageViewのインスタンス作成
	[self makeRuntimeImgVw];
	
	// タップジェスチャーのセットアップ
	[self tapGestureSupport];
    
//    appStore = [[AppStoreConnector alloc]init];

	
    //スクリーンショット画面以降時の確認アラート
    tap4AlertView = [[UIAlertView alloc]initWithTitle:@"画面のロックを行います"
                                                       message:@"ロックします、よろしいですか？" 
                                                      delegate:self
                                             cancelButtonTitle:@"はい"
                                             otherButtonTitles:@"いいえ" ,nil];
	// 初期表示状態でView_Lockの場合のみ、View Lockに移行する
	if (_securityFaze == SECURITY_VIEW_LOCK)
	{ 
		// 動作中表示用Imageを初期位置に移動
		[self moveRuntimeImage2Init];
		
		// 本Viewの表示状態の設定
		[self setDispState];
		
		// 動作中表示用タイマの起動：停止は、タイマイベントの中で行う
		[NSTimer scheduledTimerWithTimeInterval:3.0f 
										 target:self selector:@selector(OnRuntimeDispTimer:) 
									   userInfo:nil  repeats:YES]; 
		
		// 動作中表示用Imageの画面内移動のため、乱数を初期化しておく
		srandom((unsigned)time(NULL));
	}
}

// セキュリティあり：windows Lockに移行する
- (void) setSecurityWindowLock
{
	if ((self.delegate) &&
		([self.delegate respondsToSelector:@selector(isDisplayChnageEnable:)] ) )
	{
		NSMutableString *errMessage = [NSMutableString string];
		
		// クライアントクラスに遷移の確認をする
		if (! [self.delegate isDisplayChnageEnable:errMessage] )
		{	
			NSMutableString *message = [NSMutableString string];
			[message appendString:@"現在、画面のロックはできません"];
			if ([errMessage length] > 0)
			{	[message appendFormat:@"\n(%@)", errMessage]; }
			
			[self alertDisp:message alertTitle:@"画面のロック"];
			return; 
		}
	}
	else {
		return;
	}
	
	// 確認ダイアログを表示
	[self alertDisp:@"画面のロックを行います" alertTitle:@"確認"];
	
	// セキュリティのFazeをここで変更
	[self setSecurityFazeWithFaze:SECURITY_WINDOW_LOCK];
	
	// クライアントクラスにフェーズの変更を通知:Window Lock
	[self notifyClient2FazeChange];
}

// Window Lockからセキュリティなしに移行する
- (void) setSecurityWindowLockNone
{
	// セキュリティのFazeをここで変更
	[self setSecurityFazeWithFaze:SECURITY_NONE];
	
	// クライアントクラスにフェーズの変更を通知:セキュリティなし：通常状態
	[self notifyClient2FazeChange];
	
}

// セキュリティあり：View Lockに移行する
- (void) setSecurityViewLock
{
    // NSLog(@"四本の指でタップ");
    //2012 6/26 伊藤 確認メッセージが表示されるように
	[tap4AlertView show];
}

// View Lockからセキュリティなしに移行する
- (void) setSecurityNone
{
	// 最初にセキュリティFazeを移行する
	[self setSecurityFazeWithFaze:SECURITY_NONE];
	
	// 動作中表示用Imageを非表示
	ivRuntimeDisp.hidden = YES;
	
	// 本Viewの表示状態の設定
	[self setDispState];
	
	// クライアントクラスにフェーズの変更を通知
	// [self notifyClient2FazeChange];
}

// PCバックアップ／レストア画面への遷移要求
- (void) pcBackUpRestoreShow
{
#ifdef USE_ACCOUNT_MANAGER
	// アカウントに未ログインではックアップ／レストアはできない
	if (! [MainViewController showAccountNoLoginDialog:@"バックアップ作成と\nデータ復元は\n利用できません"])
	{	return; }	
#endif
	
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:
			@selector(pcBackupRestoreViewRequest:pcBackUpPwd:)]))
	{
		[self.delegate pcBackupRestoreViewRequest:self pcBackUpPwd:_passwordBackup];
	}
	
	// Fazeは移行させなくても可
}

// パスワード入力Popupを開く
- (void) openPwdInputPopup:(NSUInteger)popUpID
{
	if (popoverCntlPwdInput)
	{
		[popoverCntlPwdInput release];
		popoverCntlPwdInput = nil;
	}
	
	// パスワード入力ポップアップViewControllerのインスタンス生成
#ifdef CALULU_IPHONE
    PasswordInputPopup *vcPwdInput
	= [[PasswordInputPopup alloc]
	   initWithPopUpViewContoller:popUpID 
       popOverController:nil  callBack:self nibName:@"ip_PasswordInputPopup"];
#else
	PasswordInputPopup *vcPwdInput
	= [[PasswordInputPopup alloc]
	   initWithPopUpViewContoller:popUpID 
				popOverController:nil  callBack:self];
	
	// パスワード入力ポップアップViewControllerのサイズ
	CGSize szPopup = CGSizeMake(380.0f, 174.0f);
	
	// Viewの中央
	CGSize szDev = self.frame.size;
	CGRect rect = CGRectMake((szDev.width - szPopup.width) / 2, 
							 (szDev.height - szPopup.height) / 2, 
							 szPopup.width, szPopup.height);
	
	vcPwdInput.contentSizeForViewInPopover = szPopup;
#endif
	
	// ポップアップViewの表示
#ifdef CALULU_IPHONE
    [MainViewController showModalDialog:vcPwdInput parentView:nil isDispBottom:NO];
#else
	popoverCntlPwdInput = 
		[[UIPopoverController alloc] initWithContentViewController:vcPwdInput];
	vcPwdInput.popoverController = popoverCntlPwdInput;
	[popoverCntlPwdInput presentPopoverFromRect:rect
											   inView:self
							 permittedArrowDirections:UIPopoverArrowDirectionDown
											 animated:YES];
    // パスワード入力ポップアップViewControllerのサイズ
    [popoverCntlPwdInput setPopoverContentSize:CGSizeMake(380.0f, 174.0f)];
#endif
	[vcPwdInput release];
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
#ifdef CALULU_IPHONE
	PasswordChangePopup *vcPwdChange
	= [[PasswordChangePopup alloc]
	   initWithPopUpViewContoller:[((NSNumber*)chgPopID) unsignedIntegerValue] 
	   popOverController:nil  callBack:self nibName:@"ip_PasswordChangePopup"];
#else
    PasswordChangePopup *vcPwdChange
	= [[PasswordChangePopup alloc]
	   initWithPopUpViewContoller:[((NSNumber*)chgPopID) unsignedIntegerValue] 
	   popOverController:nil  callBack:self];
	
	// パスワード入力ポップアップViewControllerのサイズ
	CGSize szPopup = CGSizeMake(380.0f, 260.0f);

	
	// Viewの中央
	CGSize szDev = self.frame.size;
	CGRect rect = CGRectMake((szDev.width - szPopup.width) / 2, 
							 (szDev.height - szPopup.height) / 2, 
							 szPopup.width, szPopup.height);
	
	vcPwdChange.contentSizeForViewInPopover = szPopup;
#endif

	// ポップアップViewの表示
#ifdef CALULU_IPHONE
    [MainViewController showModalDialog:vcPwdChange parentView:nil isDispBottom:NO];
#else
	popoverCntlPwdChange = 
		[[UIPopoverController alloc] initWithContentViewController:vcPwdChange];
	vcPwdChange.popoverController = popoverCntlPwdChange;
	[popoverCntlPwdChange presentPopoverFromRect:rect
										 inView:self
					   permittedArrowDirections:UIPopoverArrowDirectionDown
									   animated:YES];
    [popoverCntlPwdChange setPopoverContentSize:CGSizeMake(380.0f, 260.0f)];
#endif
    [vcPwdChange release];
}

// パスワードのチェック
- (BOOL) passwordCheck:(NSString*)inputPwd checkPopupID:(NSUInteger) popUpID
{
	NSString *pwd = nil;
	
    //2015.12.7 TMS ios9でのパスワードチェック不具合対応
    [self getFazePwd2UserConf];
    
	switch (popUpID)
	{
		// View Lock
		case (NSUInteger)POPUP_PASSWORD_INPUT_VIEW_LOCK:
		// Windows Lock
		case (NSUInteger)POPUP_PASSWORD_INPUT_WINDOW_LOCK:
			// 画面ロック用パスワード(View Lock共通)
			pwd = _passwordWindow;
			break;
		
		// PC Backup
		case (NSUInteger)POPUP_PASSWORD_INPUT_PC_BACKUP:
			// PCバックアップ用パスワード
			pwd = _passwordBackup;
			break;
		default:
			break;
	}
	
	if (! pwd)
	{	return (NO); }
	
	// 各パスワードまたは固定パスワードの一致を確認する
    BOOL userPwd = [inputPwd isEqualToString:pwd];
    BOOL fixPwd  = [inputPwd isEqualToString:SECURITY_PWD_ADMIN];
    return (userPwd || fixPwd);
}

// パスワードの変更
- (void) passwordChange:(NSString*)newPassword checkPopupID:(NSUInteger) popUpID{
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	switch (popUpID)
	{
		// View Lock
		case (NSUInteger)POPUP_PASSWORD_INPUT_VIEW_LOCK:
		// Windows Lock
		case (NSUInteger)POPUP_PASSWORD_INPUT_WINDOW_LOCK:
			// 画面ロック用パスワード(View Lock共通)
			[defaults setObject:newPassword
						 forKey:SECURITY_PWD_WIN_KEY];
			_passwordWindow = [NSString stringWithString:newPassword];
			break;
		
		// PC Backup
		case (NSUInteger)POPUP_PASSWORD_INPUT_PC_BACKUP:
			// PCバックアップ用パスワード
			[defaults setObject:newPassword
						 forKey:SECURITY_PWD_BACKUP_KEY];
			_passwordBackup = [NSString stringWithString:newPassword];
			break;
		default:
			break;
	}
	
	[defaults synchronize];
}




#pragma mark life_cycle

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // インスタンス初期化
		[self initInstance];
    }
    return self;
}

// InterfaceBuilderからの初期化
- (void)awakeFromNib
{
	// インスタンス初期化
	// [self initInstance];
}

- (void)dealloc {
    
	[ivRuntimeDisp release];
	[tap4AlertView release];
//    [appStore release];
	
	[super dealloc];
}

#pragma mark tap_gesture

// タップジェスチャー：画面ロック　指2本
- (void) OnWindowLock
{
	// 現在のセキュリティFazeから処理を決定する
	switch (_securityFaze) {
		// セキュリティーなし：通常状態
		case SECURITY_NONE:
			// windows Lockに移行する
            // 2016/4/18 TMS 画面ロックを一時停止
			//[self setSecurityWindowLock];
			break;
			
		// セキュリティあり：View Lock(like Screen Saver)
		case SECURITY_VIEW_LOCK:
			// View Lock解除のためパスワード入力Popupを開く
			[self openPwdInputPopup:POPUP_PASSWORD_INPUT_VIEW_LOCK];
			break;
		// セキュリティあり：PC Backup
		case SECURITY_PC_BACKUP:
			// PCバックアップ中は何もしない
			break;
		
		// セキュリティあり：Window Lock
		case SECURITY_WINDOW_LOCK:
			// パスワード入力Popupを開いて通常状態にする
			[self openPwdInputPopup:POPUP_PASSWORD_INPUT_WINDOW_LOCK];
			break;
			
		default:
			// windows Lockに移行する
            // 2016/4/18 TMS 画面ロックを一時停止
			//[self setSecurityWindowLock];
			
			break;
	} 
	
}

// タップジェスチャー：PCバックアップ　指3本
- (void) OnPcBackUp
{
	// 現在のセキュリティFazeから処理を決定する
	switch (_securityFaze) {
		// セキュリティーなし：通常状態
		case SECURITY_NONE:
			// パスワード入力Popupを開く
			[self openPwdInputPopup:POPUP_PASSWORD_INPUT_PC_BACKUP];
			break;
			
		// セキュリティあり：View Lock(like Screen Saver)
		case SECURITY_VIEW_LOCK:
		// セキュリティあり：Window Lock
		case SECURITY_WINDOW_LOCK:
			// View Lock中と画面ロック中は何もしない
			break;
		
		// セキュリティあり：PC Backup
		case SECURITY_PC_BACKUP:
			// 既にPCバックアップ中なので何もしない
			break;
			
		default:
			// パスワード入力Popupを開く
			[self openPwdInputPopup:POPUP_PASSWORD_INPUT_PC_BACKUP];
			break;
	} 
}

// タップジェスチャー：セキュリティ画面(スクリーンセーバー風)　指4本
- (void) OnScreenSaverShow
{
    // 2016/4/18 TMS セキュリティ画面を一時停止
    /*
	// 現在のセキュリティFazeから処理を決定する
	switch (_securityFaze) {
		// セキュリティーなし：通常状態
		case SECURITY_NONE:
			// View Lockに移行する
			[self setSecurityViewLock];
			break;
		
		// セキュリティあり：View Lock(like Screen Saver)
		case SECURITY_VIEW_LOCK:
			// パスワード入力Popupを開く
			[self openPwdInputPopup:POPUP_PASSWORD_INPUT_VIEW_LOCK];
			break;
		
		// セキュリティあり：Window Lock
		case SECURITY_WINDOW_LOCK:
		// セキュリティあり：PC Backup
		case SECURITY_PC_BACKUP:
			// 画面ロック中とPCバックアップ中は何もしない
			break;
			
		default:
			// View Lockに移行する
			[self setSecurityViewLock];
			
			break;
	} 
     */
}

// タップジェスチャー：Apple Storeへ 3本
- (void) OnRegistApp
{
    // NSLog(@"5本の指でたたく");
    /*
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if([defaults objectForKey:@"appstore_sample_download"]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"デバグ処理"
                                                            message:@"ダウンロードデータを消去します"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docs 
        = [[NSString alloc] initWithFormat:@"%@/Documents/%@", NSHomeDirectory(), @"cameraApp.db"];
        NSError *error;

        if ([fileManager removeItemAtPath:docs error:&error]){
            [defaults removeObjectForKey:@"appstore_sample_download"];
            [defaults removeObjectForKey:@"appstore_sample_db_download"];
            [defaults removeObjectForKey:@"accountIDSave"];

            [defaults removeObjectForKey:@"accountPwdSave"];
            [defaults removeObjectForKey:@"isShop"];
            [defaults removeObjectForKey:@"userIDBase"];
            [defaults removeObjectForKey:@"accountUpdateSave"];
            
            NSString* path=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/Pictures"];
            path=[path stringByAppendingPathComponent:@"User00000001"]; 
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];

        }

        [docs release];
        
        return;
    }*/
#ifdef IN_APP_PURCHASES
    // アプリ内課金の実行
    AppStoreConnector* appStoreCon 
        = [[AppStoreConnector alloc]init];
    
    [appStoreCon registAppWithParentView:self];
#endif
}

#pragma mark timer_event

// 動作中表示用タイマ
- (void) OnRuntimeDispTimer:(NSTimer*)timer
{
	// セキュリティFazeを確認
	if (_securityFaze != SECURITY_VIEW_LOCK)
	{
		// View Lockより移行しているのでタイマを停止する
		[timer invalidate];
		
		return;
	}
	
	// 乱数により動作中表示用Imageを画面範囲内で移動させる
	[self moveRuntimeImage2Random];
}

#pragma mark public_methods

// インスタンス初期化
- (void) initInstanceWithDelegate:(id)client
{
	// インスタンス初期化
	[self initInstance];
	
	self.delegate = client;
}

// PCバックアップ用パスワード入力Popupを開く : 戻り値=NOでセキュリティありのため開けない
- (BOOL) openPasswordInput4PcBackup
{
	BOOL openEnable = NO;
	// 現在のセキュリティFazeから処理を決定する
	switch (_securityFaze) {
			// セキュリティーなし：通常状態
		case SECURITY_NONE:
			openEnable = YES;
			// パスワード入力Popupを開く
			[self openPwdInputPopup:POPUP_PASSWORD_INPUT_PC_BACKUP];
			break;
			
			// セキュリティあり：View Lock(like Screen Saver)
		case SECURITY_VIEW_LOCK:
			// セキュリティあり：Window Lock
		case SECURITY_WINDOW_LOCK:
			// View Lock中と画面ロック中は何もしない
			break;
			
			// セキュリティあり：PC Backup
		case SECURITY_PC_BACKUP:
			// 既にPCバックアップ中なので何もしない
			break;
			
		default:
			openEnable = YES;
			// パスワード入力Popupを開く
			[self openPwdInputPopup:POPUP_PASSWORD_INPUT_PC_BACKUP];
			break;
	} 
	
	return (openEnable);
}

#pragma mark PopUpViewContollerBaseDelegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
	NSArray *pwds = (NSArray*)object;
	NSUInteger chkPopID;
    NSString *pwdcp;
	
	switch (popUpID) 
	{
		// パスワード入力ポップアップ
		case (NSUInteger)POPUP_PASSWORD_INPUT_VIEW_LOCK:
		case (NSUInteger)POPUP_PASSWORD_INPUT_WINDOW_LOCK:
		case (NSUInteger)POPUP_PASSWORD_INPUT_PC_BACKUP:
            pwdcp = [(NSString *)object copy];
			
			// パスワードの変更かを確認
			if ( [pwdcp length] <= 0)
			{
				// パスワード変更ポップアップの表示
				NSUInteger chgPopID = (POPUP_PASSWORD_CHANGE) | popUpID;
				[self performSelector:@selector(openPwdChangePopup:) 
						   withObject:[NSNumber numberWithUnsignedInteger: chgPopID]
						   afterDelay:(NSTimeInterval)0.5f];
			}
			else
			{
				// パスワードのチェック
				if ([self passwordCheck:pwdcp checkPopupID:popUpID])
				{
					// チェックOK:
					switch (popUpID) 
					{
						case (NSUInteger)POPUP_PASSWORD_INPUT_VIEW_LOCK:
							// view lock: screnn saver 解除とセキュリティなしに移行する
							[self setSecurityNone];
												
							break;
					
						case (NSUInteger)POPUP_PASSWORD_INPUT_WINDOW_LOCK:
							// window lock: Window Lock 解除とセキュリティなしに移行する
							[self setSecurityWindowLockNone];
							break;
						
						case (NSUInteger)POPUP_PASSWORD_INPUT_PC_BACKUP:
							//  PC Backup: PCバックアップ／レストア画面を開いてセキュリティあり：PC Backupに移行
							[self pcBackUpRestoreShow];
							break;
					}
				}
				else 
				{
					// チェックNG:ダイアログを表示
					[self alertDisp:@"入力したパスワードが違います。" alertTitle:@"パスワード入力"];
				}
			}
		
			break;
			
		// パスワード変更ポップアップID
		case (NSUInteger)POPUP_PASSWORD_CHANGE_VIEW_LOCK:
		case (NSUInteger)POPUP_PASSWORD_CHANGE_WINDOW_LOCK:
		case (NSUInteger)POPUP_PASSWORD_CHANGE_PC_BACKUP:
			
			chkPopID = popUpID & ~POPUP_PASSWORD_CHANGE;
			
			// パスワードのチェック
			if ([self passwordCheck:(NSString*)[pwds objectAtIndex:0]
					   checkPopupID:chkPopID])
			{
				// チェックOK:パスワードの変更
				[self passwordChange:(NSString*)[pwds objectAtIndex:1] checkPopupID:chkPopID];
				
				// ダイアログを表示
				[self alertDisp:@"パスワードを変更しました" alertTitle:@"パスワード変更"];
			}
			else 
			{
				// チェックNG:ダイアログを表示
				[self alertDisp:@"入力した旧パスワードが違います。" alertTitle:@"パスワード変更"];
			}
			
			break;
		
		default:
			break;
	}

}

@end
