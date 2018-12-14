//
//  UserInfoListViewController.h
//  iPadCamera
//
//  Created by MacBook on 11/04/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Common.h"
#import "iPadCameraAppDelegate.h"
#import "UITableViewItemButton.h"

// MFMailComposeViewControllerのサポート：要 MessageUI.framework
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "ThumbnailViewController.h"
#import "GetWebMailUserStatuses.h"
#import "ReferenceWeb.h"
#import "BirthdaySearchPopup.h"
#import "LastWorkDateSearchPopup.h"
#import "MemoSearchPopup.h"
#import "BlockMailStatus.h"
#import "CreateWebMailUser.h" // WebMailユーザー作成用
#import "UserInfoEditViewController.h"
#ifdef USE_ACCOUNT_MANAGER
#import "AccountLoginPopUp.h"
#endif
#import "DateSearchPopup.h"
//2016/8/10 TMS お客様名検索対応
#import "NameSearchPopup.h"
#import "def64bit_common.h"
//2016/1/5 TMS ストア・デモ版統合対応
#import "userDbManager2.h"
// 2016/8/17 担当者検索機能の追加
#import "ResponsibleSearchPopup.h"
#import "AppSettingPopupVC.h"

// popupViewのID定義
typedef enum
{
	POPUP_NEW_USER			= 0x0001,		// 新規ユーザ
	POPUP_EDIT_USER			= 0x0010,		// ユーザ情報編集
	POPUP_EDIT_WORK_ITEM	= 0x0100,		// 施術内容編集
	POPUP_SEARCH_GOJYUON	= 0x1000,		// 五十音検索
	POPUP_SEARCH_WORK_DATE	= 0x2000,		// 施術日で検索
    //2016/8/10 TMS お客様名検索対応
    POPUP_SEARCH_USER_NAME  = 0x3000,       // ユーザー名で検索
	POPUP_SEARCH_REGSIT_NUM	= 0x4000,		// お客様番号で検索
    // 2016/8/17 担当者検索機能の追加
    POPUP_SEARCH_RESPONSIBLE= 0x5000,		// 担当者名で検索
	POPUP_MAINTENACE		= 0x8001,		// メンテナンス
    POPUP_EDIT_SMTP_INFO    = 0x8010,       //SMTP設定編集
    POPUP_MAIL_SETTING      = 0x8011,       // メール設定
#ifdef USE_ACCOUNT_MANAGER
	POPUP_ACCOUNT_LOGIN		= 0x10000,		// アカウントログイン
#endif
#ifdef CLOUD_SYNC
    POPUP_SELECT_SHOP       = 0x0800,       // 店舗の選択
#endif
} POPUP_VIEW_ID;

#define USER_INFO_LOGIN_OK_DIALOG   0x20000 // ログイン完了後のダイアログTag
#define APP_STORE_SALES_CHECK_DIALOG      0x80000 // サンプルのダウンロード開始の確認

#ifdef CLOUD_SYNC
#define CLOUD_UPLOAD_OK_DIALOG      0x40000 // クラウドへアップロードのダイアログTag
#define CLOUD_RESTART_DIALOG        0x40001 // クラウドへ同期再開のダイアログTag
#endif

#define CUSTOMER_INFO_DIAG          0x50000 // 顧客情報表示ダイアログTag
#define LANGUAGE_INFO_DIAG          0x60000 // 言語環境設定ダイアログTag
//2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
#define DEMO_DATA_SYNC_DIALOG       0x70000 // DEMO版最新データ同期ダイアログTag // DELC Sasage

@class	mstUser;
@class	userInfoListManager;
@class	fcUserWorkItem;
@class	UIFlickerButton;
@class  WebMailUserStatus;

@protocol MainViewControllerDelegate;
@protocol BirthdaySearchPopupDelegate;



#import "IBDesignableView.h"
@interface BtnGojyuonSearch : IBDesignableButton
@property BOOL searching;
@end



@interface UserInfoListViewController : UIViewController 
<
UIAlertViewDelegate,                    UIActionSheetDelegate,
UIScrollViewDelegate,                   UIFlickerButtonDelegate,
MainViewControllerDelegate,             LongTotchDelegate,
MFMailComposeViewControllerDelegate,    ThumbnailVCDelegate,
GetWebMailUserStatusesDelegate,         BirthdaySearchPopupDelegate,
LastWorkDateSearchPopupDelegate,        MemoSearchPopupDelegate,
CreateWebMailUserDelegate,DateSearchPopupDelegate,
NameSearchPopupDelegate

#ifdef USE_ACCOUNT_MANAGER
,AccountLoginPopUpDelegate
#endif
>
{
	// 現在選択ユーザー
	IBOutlet UIImageView	*imgViewPicture;		// 写真
	IBOutlet UILabel		*lblName;				// 名前（姓＋名）
    IBOutlet UILabel        *userNameHonoTitle;     // 敬称
	IBOutlet UILabel		*userRegistNumberTitle;	// お客様番号タイトル
    IBOutlet UILabel        *userRegistNumber;		// お客様番号
	IBOutlet UILabel		*lblSex;				// 性別
	IBOutlet UILabel		*lblLastWorkDate;		// 最新施術日
    IBOutlet UILabel        *lblLastWorkDateTitle;  // 最新施術日タイトル
	IBOutlet UILabel		*lblLastWorkTitle;		// 最新施術内容タイトル
	IBOutlet UILabel		*lblLastWorkContent;	// 最新施術内容
    IBOutlet UILabel		*lblBirthday;			// 生年月日
    IBOutlet UILabel		*lblBirthdayTitle;		// 生年月日タイトル
	IBOutlet UILabel		*lblBloadType;			// 血液型
    IBOutlet UILabel        *lblBloodType;
    IBOutlet UILabel		*lblSyumi;				// 趣味
    IBOutlet UILabel        *lblhobby;
    IBOutlet UILabel        *lblCustomerCarteAll;   // 全顧客の総カルテ数
	IBOutlet UITextView		*txtViewMemo;			// メモ
	IBOutlet UIImageView	*imgViewNowUsrFrame;	// 現在選択ユーザのフレーム
    IBOutlet UIView         *viewMemo;
    IBOutlet UIView         *viewCusTop;
    IBOutlet UIFlickerButton	*btnPictuerView;	// 写真一覧画面へ						:tag=257
	IBOutlet UIFlickerButton	*btnUserInfo;		// ユーザ情報の編集／削除　新規ユーザ作成	:tag=256
    IBOutlet UILabel        *lblShopName;              // 店舗名

    IBOutlet UIImageView *topImgCus;
    // 検索
	IBOutlet UISearchBar		*mySearchBar;
	// tableView関連
	IBOutlet UITableView		*myTableView;       // ユーザ情報を表示するテーブルView
    IBOutlet UITableView        *indexTableView;    // TableViewのインデックス制御用
    IBOutlet UIView             *indexView;         // インデックスを貼付けるView
	
	// ツールバーItem
	IBOutlet UIBarButtonItem	*btnNewUser;		// 新規お客様
	IBOutlet UIBarButtonItem	*btnSearch;			// 検索解除
	IBOutlet UIBarButtonItem	*btnUserInfoEdit;	// お客様情報編集
	IBOutlet UIBarButtonItem	*btnWorkUpdate;		// 施術内容更新
	IBOutlet UIBarButtonItem	*btnUserInfoDelete;	// お客様情報削除
	IBOutlet UIBarButtonItem	*btnHistListView;	// 履歴一覧の表示
	IBOutlet UIBarButtonItem	*btnCameraView;		// カメラ画面へ
	IBOutlet UIBarButtonItem	*btnMaintenace;		// メンテナンス
	
	// リスト上部のメニューボタン
    IBOutlet BtnGojyuonSearch   *btnGojyuonSearch;	// 五十音検索
    IBOutlet UIButton           *btnSanshouPage;    // ブランザページ参照ボタン
	IBOutlet UIButton			*btnAccountLogin;	// アカウントログインボタン
    IBOutlet UIButton           *btnMnuEditer;      // 編集ボタン(for iPad)
    IBOutlet UIButton           *btnShopSelect;     // 店舗の選択ボタン (for iPad)
    IBOutlet UIButton           *btnMnuCloudSync;   // Cloudと同期ボタン
    IBOutlet UIButton           *btnAddUser;        // 新規ユーザー追加ボタン
    IBOutlet UIButton           *btnCustomerInfo;   // 登録ユーザ情報ボタン
	IBOutlet UIButton			*btnBroadcastMail;	// 一斉送信
    IBOutlet UIButton           *btnSort;           // ソートボタン
    
    IBOutlet UIButton           *btnUserInfoOprate; // ユーザ情報の操作ボタン(for iPhone)
    // 2016/7/17 TMS 参照モード追加対応
    IBOutlet UIButton           *btnUserInfoView; // ユーザ情報の参照ボタン
    
    // IBOutlet UIButton           *btnWebMail;
    
// #ifdef AIKI_CUSTOM
    IBOutlet UIButton           *btnReferenceShow;  // 参考画像の表示ボタン
// #endif
    
	
	UIPopoverController		*popoverCntlNewUser;	// 新規ユーザ用ポップアップコントローラ
	UIPopoverController		*popoverCntlEditUser;	// ユーザ編集用ポップアップコントローラ
    UIPopoverController     *popoverCntlSmtpSetup;
	UIPopoverController		*popoverCntlEditWorkItem;// 施術内容編集用ポップアップコントローラ
	UIPopoverController		*popoverCntlMainte;		// メンテナンス用ポップアップコントローラ
	UIPopoverController		*popoverCntlGojyuSearch;// 五十音検索用ポップアップコントローラ
	UIPopoverController		*popoverCntlRegNumSearch;// お客様検索用ポップアップコントローラ
#ifdef CLOUD_SYNC
    UIPopoverController		*popoverCntlSelectShop;  // 店舗選択用ポップアップコントローラ
#endif
#ifdef USE_ACCOUNT_MANAGER
	UIPopoverController		*popoverCntlAccountLogin;	// アカウントログイン用ポップアップコントローラ
#endif
	UIPopoverController     *popoverCntlMailSetting;  // メール情報の設定
    
	UIAlertView				*alertUserInfoDelete;	// ユーザ情報削除Alertダイアログ
    
    UIAlertView				*alertLogout;            // ログアウトAlertダイアログ
#ifdef TRIAL_VERSION
	UIAlertView				*alertOpenHomePage;		// ホームページOpen確認ダイアログ
#endif
	userInfoListManager		*userInfoList;			// ユーザ情報リスト
	USERID_INT				currentUserId;			// 現在選択中のユーザID
	
	NSUInteger				selectJyoukenKind;		// 検索条件：SELECT_JYOUKEN_KIND
	
	IPAD_CAMERA_WINDOW_VIEW		_windowView;		// 遷移する画面
	
	NSMutableDictionary		*_headPictureList;		// 代表写真リストのキャッシュ
	
	NSInteger				_lastUserRegistNum4Search;		// お客様番号による検索での前回検索数値
    
    BOOL					_isThumbnailDeleted;	// 写真一覧で削除されたか
//    ReferenceWeb            *wv;                    // 参考資料表示
    NSMutableDictionary     *userMailStatusList;    // ユーザの未読情報などを保持
	BlockMailStatus*		blockMailStatus;		// 受信拒否設定
	CreateWebMailUser*		createUser;				// WebMail用ユーザー作成
    
    NSArray                 *titles;
    NSMutableArray          *source;
    UIView                  *zeroSizeView_;
    // 2015/12/22 TMS 初回起動時ログイン必須対応
    UIImageView             *backImgView;           //ログイン画面背景
    UIButton                *dmyBtn;                //ダミーボタン
    UserInfoEditViewController *vcEditUser;         // ユーザ情報編集画面ポップアップ
    UIView                  *privacyView;
    
    BOOL                    firstWebMailBlockCheck; // 起動時の１回目は受信拒否状態を確認するように
    float                   iOSVersion;             // iOSバージョン
    BOOL                    isSyncActive;           // クラウド同期中フラグ
    BOOL                    isJapanese;             // 言語設定が日本語か？
    BOOL                    isSyncNomal;             // 通常の同期かログアウトの同期か？
    NSInteger               applicationIconBadgeNumber;//バッジ表示件数
    
    float                   selectedCellCoordinate;
    BOOL                    onReverseSort;
}

@property (nonatomic, retain) UIActionSheet*  userEditerSheet;

// ツールバーItem
- (IBAction) OnNewUer:(id)sender;					// 新規お客様
- (IBAction) OnSerach:(id)sender;					// 検索解除
- (IBAction) OnUserInfoUpadte:(id)sender;			// お客様情報更新
- (IBAction) OnUserInfoDelete:(id)sender;			// お客様情報削除
- (IBAction) OnHistWorkView:(id)sender;				// 履歴一覧の表示へ
- (IBAction) OnCameraView:(id)sender;				// カメラ画面へ
- (IBAction) OnMaintenace:(id)sender;				// メンテナンス

- (IBAction) OnGojyuonSearch:(id)sender;			// 五十音検索

- (IBAction)OnJumpSanshouPage:(id)sender;           // 特定のブラウザページへ遷移

- (IBAction) OnAccountLogin:(id)sender;				// アカウントログインボタン

- (IBAction) OnUserInfoOprButton:(id)sender;        // 

#ifdef CLOUD_SYNC
- (IBAction) OnBtnShopSelect:(id)sender;            // 店舗の選択 (for iPad)
#endif
- (IBAction) OnBtnMnuEditer:(id)sender;             // 編集 (for iPad)
- (IBAction) OnBtnMnuCloud:(id)sender;              // Cloudと同期ボタン
// #ifdef AIKI_CUSTOM
- (IBAction) OnBtnReferenceShow:(id)sender;         // 参考画像の表示ボタン
// #endif
- (IBAction)OnCustomerInfo:(id)sender;              // 顧客情報表示ボタン
- (IBAction)OnBroadcastMail:(id)sender;				// Webメール一斉送信
- (IBAction)OnBoradcastMailingList:(id)sender;		// 一斉送信
- (IBAction)OnTemplateManager:(id)sender;			// テンプレート管理画面

// 現在選択ユーザの初期化
- (void) initSelectedUser;
// 現在選択ユーザの表示
- (void) dispSelectedUser:(mstUser*) userinfo userWorkItem:(fcUserWorkItem*)workItem;
// 現在選択ユーザのユーザ情報を更新
- (void) updateSelectedUserByUserInfo:(mstUser*) userinfo;
// 現在選択ユーザの施術内容で更新
- (void) updateSelectedUserByWorkItem:(fcUserWorkItem*)workItem;
// 現在選択ユーザ情報一覧の更新
- (void) updateSelectedUserList:(mstUser*)updateUser lastDate:(NSDate*)date;
// 現在選択ユーザの画像ファイル更新：他画面遷移時（viewDidAppear）に実行
//		isUserInfoRefresh:ユーザ情報の更新フラグ
- (void) updateUserPictureAtviewDidAppear:(BOOL)isUserInfoRefresh;

// ツールバーボタンのEnable設定
- (void) setToolButtonEnable:(BOOL)enable;

// 写真の表示
- (UIImage*) makeImagePictureWithUID:(NSString*) pictUrl userID:(USERID_INT)userID;
// サイズを指定して写真の表示
- (UIImage*) makeImagePictureWithUIDSize:(NSString*) pictUrl userID:(USERID_INT)userID fitSize:(CGSize)size;
// 写真の表示
- (UIImage*) makeImagePicture:(NSString*) pictUrl pictSize:(CGSize)size;
// 画像ファイルをフォルダ以下全てを削除する
- (void) allDeletePictureFiles:(USERID_INT)userID;

// alertViewダイアログの初期化
- (void) initAlertView;

// alert表示
- (void) alertDisp:(NSString*) message alertTitle:(NSString*) altTitle;

// メンテナンスボタンの有効／無効設定
- (void) maitenaceButtonEnable;

// viewのrefresh:初期化
- (void) refreshUserInfoListView;

// ログイン完了後の処理
- (void) loginedProc;

#ifdef CLOUD_SYNC
// 同期が未完了の場合は再度、同期を行う
-(void) doSyncAtRunnigTime;

// 端末固有ユーザIDの取得（取得できていない場合）
-(void) getUserIdBase4NoGet;

// メール状態を取得する
- (NSDictionary*) getMailStatusList;

#endif

// 一件のユーザWebMailステータスを即時更新する
- (void)setWebMailUserStatus:(WebMailUserStatus *)statusObj UserID:(NSInteger)userId;

@end
