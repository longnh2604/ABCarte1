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

#import "UIFlickerButton.h"
#import "MailSendPopUp.h"
#import "SetUpSmtpPopUp.h"

#import "ClickVideoView.h"
#import "VideoCompViewController.h"
#import "EditVideoViewController.h"
#import "def64bit_common.h"

// @protocol MainViewControllerDelegate;

@interface SelectVideoViewController : UIViewController
	<UIScrollViewDelegate, ClickVideoViewDelegate, UIFlickerButtonDelegate, MainViewControllerDelegate,UIGestureRecognizerDelegate>
{

	bool	_isBackCameraView;							// 画面遷移でカメラ画面へ戻るか？
	
	NSMutableArray *movies;     						// 画像Imageのリスト：UIImage*のリスト
	
	UIScrollView *_scrollView;							// スクロールビュー
	UIView	*_drawView;									// 描画View
	
	OKDFullScreenImageView *_fullView;					// 全画面表示view;
    NSMutableArray *errorTags;                          // 読み込みエラーの起きた動画のtagID
	
	IBOutlet UILabel		*lblUserName;				// ユーザ名
	IBOutlet UILabel		*lblWorkDate;				// 施術日
	IBOutlet UILabel		*lblWorkDateTitle;			// 施術日タイトル
	IBOutlet UIView			*viewUserNameBack;			// ユーザ名背景
	IBOutlet UIView			*viewWorkDateBack;			// 施術日背景
	
	IBOutlet UIButton		*btnOverlayCamera;			// 重ね合わせカメラボタン
	IBOutlet UIButton		*btnHardCopyPrint;			// ハードコピーボタン
    IBOutlet UIButton		*btnFacebookUp;             // facebook投稿ボタン
    IBOutlet UIButton		*btnMailSend;               // mail送信ボタン
	
    // 2012 7/13 写真を重ねて表示
    IBOutlet UIButton		*btnAbreast;                // 写真の並列表示（デフォルト）
	IBOutlet UIButton		*btnOverlap;                // 写真を重ねる
    IBOutlet UIButton		*btnUpdown;                 // 写真を上下に表示

	BOOL	_isPicturePaintDisplaied;					// 写真描画に遷移したか
		
	BOOL	_isNavigationCall;							// 本画面がnavigationControllerよりコールされたか
	
	BOOL	_isFlickEnable;								// Flickを有効にするか？
	
	NSUInteger				_selectedTagID;				// 選択されたTagID:OKDClickImageView
	
	USERID_INT				_userID;					// ユーザID（画像合成ビューで必要）
	HISTID_INT				_histID;					// 履歴ID（画像合成ビューで必要）
	NSDate					*_workDate;					// 施術日
	
	NSUInteger				_selectedCount;				// 選択された画像数
	NSInteger				_selectedImageIndex1;		// 選択された動画Index1
	NSInteger				_selectedImageIndex2;		// 選択された動画Index2
	NSInteger               _compVideoIndex1;           // 突き合わせ画面に適用された動画id
    NSInteger               _compVideoIndex2;           // 突き合わせ画面に適用された動画id
    
    IBOutlet UIView *viewFunction;
    
	UIPopoverController		*popoverCntlMailSend;		// Mail送信用ポップアップコントローラ

	IPAD_CAMERA_WINDOW_VIEW		_windowView;			// 遷移する画面
    UIImage                 *Ovimage;                   // 透過カメラ撮影イメージ
    
    VideoCompViewController *videoCompVCfromThumb;      // サムネイル一覧画面からの遷移のときのみVideoCompViewをサブビューとして扱う
    EditVideoViewController *editVideoVCfromThumb;      // サムネイル一覧画面からの遷移のときのみVideoCompViewをサブビューとして扱う
    UIInterfaceOrientation  orientationAtWillRotate;    // willRotateToInterfaceOrientationが呼ばれたときのOrientation
}

// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName isSexMen:(BOOL)isMen;
// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName nameColor:(UIColor*)color;
// 施術日の設定：設定により表示される
- (void)setWorkDateWithString:(NSString*)workDate;
// 施術情報の設定（画像合成ビューで必要）
- (void)setWorkItemInfo:(USERID_INT)userID workItemHistID:(HISTID_INT)histID workDate:(NSDate*)date;

// パス情報なども含めた画像リストの設定 DELC SASAGE                 <= // 画像Imageリストの設定
//- (void)setPictImageItems:(NSMutableArray*)images;

// ScrollViewと描画Viewの作成
- (void) makeScrDrawView;

// 画像Itemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
- (void) pictImagesLayout:(BOOL)isPortrait;

- (IBAction)OnCameraView;								// カメラ画面へ戻る
- (IBAction)OnSelectPictView;							// 画像ファイル選択

- (IBAction)OnOverlayCamera;							// 重ね合わせカメラ
- (IBAction)OnHardCopyPrint;							// ハードコピー

//- (IBAction)OnFacebookUp;                               // facebook投稿
//- (IBAction)OnMailSend;                                 // Mail送信

// 動画の設定
- (void)setMovieItems:(NSMutableArray*)movies;

@property(nonatomic) BOOL isNavigationCall;
@property(nonatomic) BOOL isFlickEnable;
@property(nonatomic, retain)		NSDate		*workDate;

@end
