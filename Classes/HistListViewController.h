//
//  HistListViewController.h
//  iPadCamera
//
//  Created by MacBook on 10/12/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Common.h"

#import "MainViewController.h"

#import "iPadCameraAppDelegate.h"
#import "ThumbnailViewController.h"

#import "DatePickerPopUp.h"

#import "UIFlickerButton.h"
#import "UserInfoDispViewSupport.h"

#import "WebMailListViewController.h"
#import "QRCodeViewController.h"
#import "def64bit_common.h"

@class UserInfoDispViewSupport;

// 履歴表示ViewのControllerクラス
@interface HistListViewController : UIViewController
	<PopUpViewContollerBaseDelegate, UIAlertViewDelegate, UIFlickerButtonDelegate, UserInfoDispViewSupportDelegate,
	 MainViewControllerDelegate, LongTotchDelegate, ThumbnailVCDelegate, WebMailListViewControllerDelegate,
	 QRCodeViewControllerDelegate>
{
	// ツールバーItem
	IBOutlet UIBarButtonItem	*btnUserListView;		// お客様一覧に戻るボタン
	IBOutlet UIBarButtonItem	*btnPictureListView;	// 写真一覧表示ボタン
	IBOutlet UIBarButtonItem	*btnCameraView;			// カメラ画面へボタン
	IBOutlet UIBarButtonItem	*btnHistDetailView;		// 履歴詳細の表示ボタン
	
	IBOutlet UIBarButtonItem	*btnNewkarteMake;		// 新規カルテの作成ボタン
	IBOutlet UIBarButtonItem	*btnKarteDelete;		// 選択カルテの削除ボタン
    
    IBOutlet UIBarButtonItem    *btnWebMail;            // メール一覧ボタン
    IBOutlet UIBarButtonItem    *userStatusLabel;       // 未読情報など
	IBOutlet UIBarButtonItem	*btnQRCode;
	
	IBOutlet UIToolbar			*tlbSecurity;			// セキュリティ表示用ツールバー
	
	UserInfoDispViewSupport		*userView;				// 最新施術ViewController
	
	UIPopoverController			*popCtlDatePicker;		// 新規履歴ポップアップコントローラ
	
	USERID_INT					_selectedUserID;		// 選択されたユーザのID
	NSString					*_selectedUserName;		// 選択されたユーザ名
	NSMutableArray				*_histUserItems;		// 施術内容のItem一覧
	
	IPAD_CAMERA_WINDOW_VIEW		_windowView;			// 遷移する画面
	
	UIAlertView					*alertHistDelete;		// 履歴削除Alertダイアログ
	
	NSMutableDictionary			*_headPictureList;		// 代表写真リストのキャッシュ
	
	BOOL						_isInitRunFinish;		// 起動時の遅延処理完了フラグ
	
	BOOL						_isThumbnailDeleted;	// 写真一覧で削除されたか
    
    WebMailListViewController   *mailVC;                // メール・ビュ DELC SASAGE
	QRCodeViewController		*QRCode;				// QRコード表示用
    IBOutlet UIToolbar          *tlbMain;               // メインのツールバー
    BOOL                        _isThumPopUpLock;       // サムネイル表示画面の二重起動防止
	BOOL						_isQRCodeHidden;		// QRコード表示フラグ
    
    BOOL                        isJapanese;             // 言語環境設定フラグ
    
    @public
    // tableView関連
    IBOutlet UITableView        *tvHistList;            // 履歴リスト用TableView
}

////////////////////////////////////////////////////////////////////////////
// ツールバーItem
////////////////////////////////////////////////////////////////////////////

// お客様一覧に戻る
- (IBAction) OnUserListView:(id)sender;
// 写真一覧表示
- (IBAction) OnPictureListView:(id)sender;
// カメラ画面へ
- (IBAction) OnCameraView:(id)sender;
// 履歴詳細の表示
- (IBAction) OnHistDetailView:(id)sender;

// 新規カルテの作成
- (IBAction) OnNewKarteMake:(id)sender;
// 選択カルテの削除
- (IBAction) OnDeleteKarte:(id)sender;
// メール一覧の表示
- (IBAction) OnWebMailList:(id)sender;

////////////////////////////////////////////////////////////////////////////
// プロパティ
////////////////////////////////////////////////////////////////////////////
@property(nonatomic)			USERID_INT	selectedUserID;
@property(nonatomic, copy)		NSString	*selectedUserName;

////////////////////////////////////////////////////////////////////////////
// メソッド
////////////////////////////////////////////////////////////////////////////

// Viewの更新
- (void) refreshViewWithUserID:(USERID_INT)userID userName:(NSString*)name;

// 施術内容と表示されているセルの更新
- (void) updateHistUserItemsVisbleCells:(BOOL)isItemUpdate;

// Viewの日付による更新
- (void) refrshViewWithDate:(NSDate*)date;

// メール関連のコントロール設定
- (void) mailControlsEnableWithFLag:(BOOL)isEnable;

// QRCodeのコントロール設定
- (void) qrControlsEnableWithFLag:(BOOL)isEnable;

// メールViewの表示設定
- (void) mailViewShowWithFlag:(BOOL)isShow;

// QRコードの表示設定
- (void) qrcodeViewShowWithFlag:(BOOL)isShow;

@end
