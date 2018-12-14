//
//  HistDetailViewController.h
//  iPadCamera
//
//  Created by MacBook on 10/12/09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iPadCameraAppDelegate.h"
#import "OKDThumbnailItemView.h"
#import "WorkItemSetPopup.h"
#import "itemEditerPopup.h"
#import "UIFlickerButton.h"
#import "PhotoCommentPopup.h"
#import "VideoThumbnailItemView.h"
#import "VideoPreviewViewController.h"
#import "def64bit_common.h"
#import "UserInfoDispViewSupport.h"
#import "MainViewController.h"
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
#import "BodyCheckViewController.h"
#endif
//----------------------------------------------------
//  サムネイルのレイアウト関連の定義
//----------------------------------------------------
#ifdef CALULU_IPHONE
// サムネイルの横方向の数(デバイス縦向き)
#define ITEM_X_NUMS	4.0f
// サムネイルの横方向の数(デバイス横向き)
#define ITEM_X_NUMS_LS	6.0f

// サムネイルの縦方向の数(通常)
#define ITEM_Y_NUMS				3.0f
// サムネイルの縦方向の数(画面ロック)
#define ITEM_Y_NUMS_WIN_LOCK	6.0f
#else
// サムネイルitemの幅
// #define ITEM_WITH	128.0f
// サムネイルitemの高さ -> サムネイル=96 ＋　タイトル高さ=10
// #define ITEM_HEIGHT	106.0f
// サムネイルの横方向の数(デバイス縦向き)
#define ITEM_X_NUMS	4.0f
// サムネイルの横方向の数(デバイス横向き)
#define ITEM_X_NUMS_LS	6.0f

// サムネイルの縦方向の数(通常)
#define ITEM_Y_NUMS				2.0f
// サムネイルの縦方向の数(画面ロック)
#define ITEM_Y_NUMS_WIN_LOCK	5.0f
#endif

//----------------------------------------------------
//  コンテナView関連の定義
//----------------------------------------------------

#ifdef CALULU_IPHONE

// basePanelの高さ（PortraitとOrientationで固定）
#define HIST_DTL_BASE_PANEL_HEIGHT      416.0f
// basePanelの幅（Portrait時）
#define HIST_DTL_BASE_PANEL_WIDTH_PRT   320.0f
// basePanelの幅（Orientation時）
#define HIST_DTL_BASE_PANEL_WIDTH_ORT   480.0f

// サムネイルコンテナの横サイズ
#define THUBNAIL_CONTEINER_WIDTH        268.0f
// サムネイルコンテナの縦サイズ（通常）
#define THUBNAIL_CONTEINER_HEIGHT        180.0f
// サムネイルコンテナの縦サイズ（画面ロック）
#define THUBNAIL_CONTEINER_HEIGHT_LOCK   390.0f

#else

// basePanelの高さ（PortraitとOrientationで固定）
#define HIST_DTL_BASE_PANEL_HEIGHT      760.0f
// basePanelの幅（Portrait時）
#define HIST_DTL_BASE_PANEL_WIDTH_PRT   728.0f
// basePanelの幅（Orientation時）
#define HIST_DTL_BASE_PANEL_WIDTH_ORT   984.0f

// サムネイルコンテナの横サイズ
#define THUBNAIL_CONTEINER_WIDTH        595.0f
// サムネイルコンテナの縦サイズ（通常）
#define THUBNAIL_CONTEINER_HEIGHT        227.0f
// サムネイルコンテナの縦サイズ（画面ロック）
#define THUBNAIL_CONTEINER_HEIGHT_LOCK   616.0f

#endif

// 写真フォルダのパス
#define PICTURE_FOLDER		@"%@/Documents/User%08d"

// ユーザ情報編集
#define POPUP_EDIT_USR          0x0010

// 施術内容のマスタ編集
#define POPUP_WORK_ITEM_EDIT	0x0020

// 2012 6/29 伊藤 選択画像のタイトル、コメント編集
#define POPUP_EDIT_IMAGE_PROFILE	0x0100

@class fcUserWorkItem;
@class UserInfoDispViewSupport;
@class HistListTableViewCell;
@class takePicture4PhotoLibrary;

@protocol MainViewControllerDelegate;

@interface HistDetailViewController : UIViewController
<
OKDThumbnailItemViewDelegate,
UserInfoDispViewSupportDelegate,
VideoThumbnailItemViewDelegate,
WorkItemSetPopupDelegate,
UIScrollViewDelegate,
UIFlickerButtonDelegate,
MainViewControllerDelegate,
UIActionSheetDelegate,
itemEditerPopupDelegate,
UIPopoverControllerDelegate
>
{
	IBOutlet UILabel		*lblWorkDate;					// 施術日
	IBOutlet UITextView		*tvWorkItem;					// 施術内容
	IBOutlet UITextView		*tvMemo;						// メモ
	BOOL					isTvMemoFocus;					// メモのフォーカスありフラグ
	IBOutlet UIScrollView	*scrollViewPictureConteiner;	// 写真用ScrollView
	IBOutlet UIView			*viewPictureConteiner;			// 写真
	IBOutlet UIActivityIndicatorView	*actIndView;		// 待機アイコン
	
	// 内部表示ボタン
	IBOutlet UIButton		*btnHeadPicture;				// 選択を代表写真に
	IBOutlet UIButton		*btnDeletePicture;				// 選択画像を削除
	
    // 2012 6/29 伊藤 選択画像のタイトル、コメント編集
    IBOutlet UIButton       *btnEditImageProfile;
    
	// ツールバーItem
	IBOutlet UIBarButtonItem	*btnSelectPictView;			// 選択画像の表示
	IBOutlet UIBarButtonItem	*btnUpdateWorkItem;			// 更新（施術内容とメモ）
	IBOutlet UIBarButtonItem	*btnChancelWorkItem;		// 取消（施術内容とメモ）
	
	IBOutlet UIToolbar			*tlbSecurity;				// セキュリティ表示用ツールバー
	
	IBOutlet UILabel			*lblPicture;				// 写真ラベル
	IBOutlet UIButton			*btnCamera;					// カメラ画面へ
    IBOutlet UIButton           *btnPictureAlbum;           // 写真アルバム取り込みボタン
	IBOutlet UIFlickerButton	*btnFlicker;				// フリックボタン
	
	IBOutlet UIScrollView		*scrollViewBasePanel;		// baseパネル用ScrollView
	IBOutlet UIView				*vwBasePanel;				// baseパネル
	
	//START, 2011.06.18, chen, ADD
	IBOutlet UILabel		*lblMemo1;						// Memo1 lable
	IBOutlet UILabel		*lblMemo2;						// Memo2 lable
	IBOutlet UILabel		*lblFreeMemo;					// Free Memo lable
	IBOutlet UITextView		*tvWorkItem2;					// 施術内容2
	IBOutlet UIButton			*btnMemo1;					// Memo1 button
	IBOutlet UIButton			*btnMemo2;					// Memo2 button
    //END
    
    IBOutlet UIButton			*btnFreeMemoKbHider;		// フリーメモのキーボードを隠す
    
    IBOutlet UIButton           *btnSelectedImgRelease;     // 選択画像を解除
    IBOutlet UIImageView        *vwPictureAlbumPrev;        // 写真アルバム取り込みのプレビュー

    // 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
    // ボディチェックシート画面へ
    IBOutlet UIButton			*btnBodyCheckBtn;			// ボディチェックシート画面へ遷移
#endif
	UserInfoDispViewSupport *userView;						// 最新施術ViewController
	fcUserWorkItem			*_selectedWorkItem;				// 選択中の施術履歴
	
	
	UIPopoverController		*popoverCntlWorkItemSet;		// 施術内容の設定ポップアップコントローラ
	UIPopoverController		*popoverCntlEditUser;			// ユーザ編集用ポップアップコントローラ
	UIPopoverController		*popoverCntlWorkMasterEdit;		// 施術マスタ編集用ポップアップコントローラ
	
    // 2012 6/29 伊藤 選択画像のタイトル、コメント編集
    UIPopoverController		*popoverCntlEditImageProfile;

	// サムネイル関連
	NSMutableArray *tumbnailItems;						// サムネイルItemのリスト
	
	UIScrollView *_scrollView;							// スクロールビュー
	UIView	*_drawView;									// 描画View

	NSMutableArray *selectItemOrder;					// 選択サムネイルItemの順序Table
	
	UIAlertView *deleteNoAlert;							// 削除なしAlertダイアログ
	UIAlertView *deleteCheckAlert;						// 削除確認Alertダイアログ
	UIAlertView *modifyCheckAlert;						// 修正確認Alertダイアログ
	UIAlertView *headPictrueCheckAlert;					// 代表写真確認Alertダイアログ
	
	BOOL						_isThumbnailRedraw;		// サムネイルの再描画を行うかを判定する
	
	USERID_INT					_selectedUserID;		// 選択されたユーザのID
	NSString					*_selectedUserName;		// 選択されたユーザ名
	HISTID_INT					_selectedHistID;		// 選択された履歴ID
	HistListTableViewCell		*_selectedViewCell;		// 選択されたTableCell
	
	// 施術内容関連
	NSMutableArray				*_workItemIDs;			// 作業用の施術内容ID一覧
	NSMutableDictionary			*_workItemMasterTable;	// 施術マスタのテーブル
	// NSMutableString				*_workItemStrings;		// 作業用の施術内容文字（・区切り）
		
	IPAD_CAMERA_WINDOW_VIEW		_windowView;			// 遷移する画面
	
	//START, 2011.06.18, chen, ADD
	NSMutableArray				*_workItemIDs2;			// 作業用の施術内容ID一覧
	NSMutableDictionary			*_workItemMasterTable2;	// 施術マスタのテーブル
	
	NSMutableArray				*_itemEdits;			// 項目編集のリスト

	NSInteger					_currentMemo;			//current memo number	
	
    takePicture4PhotoLibrary    *_takePictureAlbum;     // 写真アルバムからの取り込み
    
    BOOL                        memWarning;             // メモリワーニングが出ているか
    BOOL                        isJapanese;             // 言語環境設定フラグ
}

////////////////////////////////////////////////////////////////////////////
// ツールバーItem
////////////////////////////////////////////////////////////////////////////

// 更新
- (IBAction) OnUpdateData:(id)sender;
// 取り消し
- (IBAction) OnChancel:(id)sender;

// 履歴一覧に戻る
- (IBAction) OnHistListView:(id)sender;
// カメラ画面へ
- (IBAction) OnCameraView:(id)sender;
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
// ボディチェックシート画面へ
- (IBAction) OnBodyCheckSheetView:(id)sender;
#endif
// 写真アルバム取り込み
- (IBAction)OnPhotoAlbum:(id)sender;
// 選択画像の表示
- (IBAction) OnSelectPictureView:(id)sender;
// お客様一覧の表示
- (IBAction) OnUserListView:(id)sender;

////////////////////////////////////////////////////////////////////////////
// 内部表示ボタン
////////////////////////////////////////////////////////////////////////////

// 施術日の設定
- (IBAction) OnSetWorkDate:(id)sender;
// 施術内容の設定
- (IBAction) OnSetworkItem:(id)sender;
// 施術マスタの編集
- (IBAction) OnWorkItemMasterEdit:(id)sender;
// 選択を代表画像にする
- (IBAction) OnSetHeadPicture:(id)sender;
// 選択画像を削除
- (IBAction) OnDeletePicture:(id)sender;

// 選択画像を解除
- (IBAction) OnChancelPicture:(id)sender;

- (IBAction)onSave:(UIButton *)sender;
- (IBAction)onTurnBack:(UIButton *)sender;

// 2012 6/29 伊藤 選択画像のタイトル、コメント編集
- (IBAction)OnEditImageProfire:(id)sender;

//START, 2011.06.18, chen, ADD
// 施術内容の設定
- (IBAction) OnSetworkItem2:(id)sender;
// 施術マスタの編集
- (IBAction) OnWorkItemMasterEdit2:(id)sender;
//select memo
- (IBAction) OnWorkItemMasterSelect:(id)sender;
//END

// フリーメモのキーボードを隠す
- (IBAction) OnHideFreeMemoKeyBord:(id)sender;

////////////////////////////////////////////////////////////////////////////
// プロパティ
////////////////////////////////////////////////////////////////////////////

@property(nonatomic, retain) fcUserWorkItem			*selectedWorkItem;
@property(nonatomic)			USERID_INT	selectedUserID;
@property(nonatomic, copy)		NSString	*selectedUserName;
@property(nonatomic)			HISTID_INT	selectedHistID;
@property(nonatomic, assign) HistListTableViewCell	*selectedViewCell;
//START , 2011.06.18, ADD
@property(nonatomic, retain) UILabel			*lblMemo1;
@property(nonatomic, retain) UILabel		    *lblMemo2;
@property(nonatomic, retain) fcUserWorkItem		*selectedWorkItem2;
@property(nonatomic, retain) UIButton		    *btnMemo1;
@property(nonatomic, retain) UIButton		    *btnMemo2;
@property(nonatomic, strong) VideoPreviewViewController *videoPreviewVC;
//END
////////////////////////////////////////////////////////////////////////////
// メソッド
////////////////////////////////////////////////////////////////////////////

// Viewの更新
- (void) refreshViewWithWorkItem:(fcUserWorkItem *)workItem 
			   selectediViewCell:(HistListTableViewCell *)viewCell
						userName:(NSString*)userName;

// 履歴なし時のViewの更新
- (void) refreshViewWithNoWorkItem:(USERID_INT)userID userName:(NSString*)userName;

// 履歴日付が当日かを判定する
- (BOOL) isWorkDateToday;

// サムネイルと選択セルの更新
- (void) thumbnailSelectedCellRefresh;

// ユーザ情報Viewの更新
- (void) refreshUserInfoView;

// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive;

@end
