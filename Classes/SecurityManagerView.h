//
//  SecurityManagerView.h
//  iPadCamera
//
//  Created by MacBook on 11/07/14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

#ifdef IN_APP_PURCHASES
#import "AppStoreConnector.h"
#endif
#define SECURITY_FAZE_KEY				@"security_last_faze"		// 前回のセキュリティのFaze
#define SECURITY_PWD_WIN_KEY			@"security_pwd_win"			// 画面ロックパスワード
#define SECURITY_PWD_BACKUP_KEY			@"security_pwd_backup"		// PCバックアップパスワード

#define SECURITY_PWD_INIT_VALUE			@"0000"						// パスワード初期値
#define SECURITY_PWD_ADMIN				@"ABCarte1234"              // 固定パスワード

#ifdef DEF_ABCARTE
#define RUNTIME_DISP_IMAGE_FILE			@"abcarte_icon_200.png"             // 動作中表示用Imageのファイル名
#else
#define RUNTIME_DISP_IMAGE_FILE			@"security.png"             // 動作中表示用Imageのファイル名
#endif

#ifdef CALULU_IPHONE
#define RUNTIME_DISP_IMAGE_RES_FILE		@"ip_security.png"			// 動作中表示用Imageのファイル名(Resouece)
#else
#define RUNTIME_DISP_IMAGE_RES_FILE		RUNTIME_DISP_IMAGE_FILE		// 動作中表示用Imageのファイル名(Resouece)
#endif

// パスワード入力ポップアップID
#define POPUP_PASSWORD_INPUT_VIEW_LOCK		0x0010					// View Lock
#define POPUP_PASSWORD_INPUT_WINDOW_LOCK	0x0020					// Window Lock
#define POPUP_PASSWORD_INPUT_PC_BACKUP		0x0100					// PC Backup

// パスワード変更ポップアップID
#define POPUP_PASSWORD_CHANGE				0x1000
#define POPUP_PASSWORD_CHANGE_VIEW_LOCK		0x1010					// View Lock
#define POPUP_PASSWORD_CHANGE_WINDOW_LOCK	0x1020					// Window Lock
#define POPUP_PASSWORD_CHANGE_PC_BACKUP		0x1100					// PC Backup

// セキュリティのFaze : NSUInteger
typedef NS_ENUM(NSUInteger, SECURITY_FAZE) {
	SECURITY_NONE			= 0x0000,				// セキュリティなし：通常状態
	SECURITY_ON				= 0x8000,				// セキュリティあり
	SECURITY_VIEW_LOCK		= SECURITY_ON | 0x10,	// セキュリティあり：View Lock(like Screen Saver)
	SECURITY_WINDOW_LOCK	= SECURITY_ON | 0x20,	// セキュリティあり：Window Lock
	SECURITY_PC_BACKUP		= SECURITY_ON | 0x100,	// セキュリティあり：PC Backup
} ;

@protocol SecurityManagerViewDelegate;

///
/// セキュリティ管理Viewクラス
///
@interface SecurityManagerView : UIView <UIAlertViewDelegate>
{
	SECURITY_FAZE		_securityFaze;			// セキュリティのFaze
	NSString			*_passwordWindow;		// 画面ロック用パスワード(View Lock共通)
	NSString			*_passwordBackup;		// PCバックアップ用パスワード
	
	UIImageView			*ivRuntimeDisp;			//動作中表示用ImageView
	
	UIPopoverController	*popoverCntlPwdInput;	// パスワード入力ポップアップコントローラ
	UIPopoverController	*popoverCntlPwdChange;	// パスワード変更ポップアップコントローラ
    
//    AppStoreConnector   *appStore;              // appStore接続
    UIAlertView         *tap4AlertView;         // スクリーンセーバー以降確認
}

@property(nonatomic, assign)	id<SecurityManagerViewDelegate> delegate;
@property(nonatomic) SECURITY_FAZE	securityFaze;

// クラス初期化：InterfaceBuilderを前提とする
// - (void) init;

// インスタンス初期化
- (void) initInstanceWithDelegate:(id)client;

// PCバックアップ用パスワード入力Popupを開く : 戻り値=NOでセキュリティありのため開けない
- (BOOL) openPasswordInput4PcBackup;

//スクリーンセイバー画面でパスワード入力ポップアップを呼び出す処理
- (void) openPwdPopup;

@end

///
/// セキュリティ管理Viewクラスのdelegate
/// 
@protocol SecurityManagerViewDelegate<NSObject>

@optional

// 遷移の確認
- (BOOL) isDisplayChnageEnable:(NSMutableString*) errMessage;

// フェーズの変更
- (void) securityManager:(id)sender onChangeFaze:(SECURITY_FAZE)faze;

// PCバックアップ／レストア画面への遷移要求
- (void) pcBackupRestoreViewRequest:(id)sender pcBackUpPwd:(NSString*)pwd;

// データの復元完了
- (void) OnCompleteRestore:(id)sender;

@end