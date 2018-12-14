//
//  SelectPictureViewController.h
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "iPadCameraAppDelegate.h"

#import "MainViewController.h"

#import "OKDFullScreenImageView.h"
#import "OKDClickImageView.h"

#import "UIFlickerButton.h"
#import "MailSendPopUp.h"
#import "SetUpSmtpPopUp.h"
#import "SwimmyPopUp.h"

#import "GetWebMailUserStatus.h"
#import "def64bit_common.h"

// @protocol MainViewControllerDelegate;

@interface SelectPictureViewController : UIViewController 
<
UIScrollViewDelegate,
OKDClickImageViewDelegate,
UIFlickerButtonDelegate,
MainViewControllerDelegate,
GetWebMailUserStatusDelegate,
PopUpViewContollerBaseDelegate
>
{

	bool	_isBackCameraView;							// 画面遷移でカメラ画面へ戻るか？
	
	NSMutableArray *pictImageItems;						// 画像Imageのリスト：UIImage*のリスト
	
	UIScrollView *_scrollView;							// スクロールビュー
	UIView	*_drawView;									// 描画View
	UIFlickerButton			*_btnPrevView;				// 前画面に戻るボタン
	
	OKDFullScreenImageView *_fullView;					// 全画面表示view;
    NSMutableArray *errorTags;                          // 読み込みエラーの起きた画像のtagID
	
	IBOutlet UILabel		*lblUserName;				// ユーザ名
	IBOutlet UILabel		*lblWorkDate;				// 施術日
	IBOutlet UILabel		*lblWorkDateTitle;			// 施術日タイトル
	IBOutlet UIView			*viewUserNameBack;			// ユーザ名背景
	IBOutlet UIView			*viewWorkDateBack;			// 施術日背景
	
	IBOutlet UIButton		*btnOverlayCamera;			// 重ね合わせカメラボタン
	IBOutlet UIButton		*btnHardCopyPrint;			// ハードコピーボタン
    IBOutlet UIButton		*btnFacebookUp;             // facebook投稿ボタン
    IBOutlet UIButton		*btnMailSend;               // mail送信ボタン
    IBOutlet UIButton       *btnSwimmy;                 // Swimmyボタン
	
    // 2012 7/13 写真を重ねて表示
    IBOutlet UIButton		*btnAbreast;                // 写真の並列表示（デフォルト）
	IBOutlet UIButton		*btnOverlap;                // 写真を重ねる
    IBOutlet UIButton		*btnUpdown;                 // 写真を上下に表示
    IBOutlet UIButton       *btnMorphing;                // モーフィング

	BOOL	_isPicturePaintDisplaied;					// 写真描画に遷移したか
		
	BOOL	_isNavigationCall;							// 本画面がnavigationControllerよりコールされたか
	
	BOOL	_isFlickEnable;								// Flickを有効にするか？
	
	NSUInteger				_selectedTagID;				// 選択されたTagID:OKDClickImageView
	
	USERID_INT				_userID;					// ユーザID（画像合成ビューで必要）
	HISTID_INT				_histID;					// 履歴ID（画像合成ビューで必要）
	NSDate					*_workDate;					// 施術日
	
	NSUInteger				_selectedCount;				// 選択された画像数
	NSInteger				_selectedImageIndex1;		// 選択された画像Index1
	NSInteger				_selectedImageIndex2;		// 選択された画像Index2
    NSInteger				_selectedImageIndex3;		// 選択された画像Index3
	NSInteger				_selectedImageIndex4;		// 選択された画像Index4
    NSInteger               _selectedImageIndex5;        // 選択された画像Index5
    NSInteger               _selectedImageIndex6;        // 選択された画像Index6
    NSInteger               _selectedImageIndex7;        // 選択された画像Index7
    NSInteger               _selectedImageIndex8;        // 選択された画像Index8
    NSInteger               _selectedImageIndex9;        // 選択された画像Index9
    NSInteger               _selectedImageIndex10;        // 選択された画像Index10
    NSInteger               _selectedImageIndex11;        // 選択された画像Index11
    NSInteger               _selectedImageIndex12;        // 選択された画像Index12
	
	UIPopoverController		*popoverCntlMailSend;		// Mail送信用ポップアップコントローラ
    MailSendPopUp           *vcMailSend;                // Mail送信ポップアップ
    SwimmyPopUp             *vcSwimmy;                  // Swimmy送信ポップアップ

	IPAD_CAMERA_WINDOW_VIEW		_windowView;			// 遷移する画面
    UIImage                 *Ovimage;                   // 透過カメラ撮影イメージ
    
    BOOL                    isiPad2;                    // iPad2か？
    BOOL                    memWarning;                 // メモリワーニングが出ているか？
    IBOutlet  UIView        *viewFunction;
}

// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName isSexMen:(BOOL)isMen;
// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName nameColor:(UIColor*)color;
// 施術日の設定：設定により表示される
- (void)setWorkDateWithString:(NSString*)workDate;
// 施術情報の設定（画像合成ビューで必要）
- (void)setWorkItemInfo:(USERID_INT)userID
         workItemHistID:(HISTID_INT)histID
               workDate:(NSDate*)date;

// パス情報なども含めた画像リストの設定 DELC SASAGE                 <= // 画像Imageリストの設定
- (void)setPictImageItems:(NSMutableArray*)images;

// ScrollViewと描画Viewの作成
- (void) makeScrDrawView;

// 画像Itemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
- (void) pictImagesLayout:(BOOL)isPortrait;

// mail機能の有効
- (void) setMailEnableIsFlag:(BOOL)isEnable;

- (IBAction)OnCameraView;								// カメラ画面へ戻る
- (IBAction)OnSelectPictView;							// 画像ファイル選択

- (IBAction)OnOverlayCamera;							// 重ね合わせカメラ
- (IBAction)OnHardCopyPrint;							// ハードコピー

- (IBAction)OnFacebookUp;                               // facebook投稿
- (IBAction)OnMailSend;                                 // Mail送信
- (IBAction)OnSwimmy:(id)sender;                        // Swimmyデータ送信

// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive;

// 画像Image選択イベント
// - (void)OnSelected:(NSUInteger)tagID image:(UIImage*)image;

@property(nonatomic) BOOL isNavigationCall;
@property(nonatomic) BOOL isFlickEnable;
@property(nonatomic, retain)		NSDate		*workDate;

@end
