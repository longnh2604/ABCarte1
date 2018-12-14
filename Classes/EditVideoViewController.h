//
//  SelectVideoViewController.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/11/18.
//
// 元SelectVideoViewController
// どんづまり。右に遷移しない。
#import <UIKit/UIKit.h>

#import "iPadCameraAppDelegate.h"

#import "MainViewController.h"

#import "OKDFullScreenImageView.h"
#import "OKDClickImageView.h"

#import "UIFlickerButton.h"
#import "MailSendPopUp.h"
#import "SetUpSmtpPopUp.h"
//DELC SASAGE
#import "VideoPreviewWideViewController.h"
#import "VideoSaveViewController.h"
#import "VideoCompViewController.h"
#import "PicturePaintManagerView.h"
#import "DoublePicturePaintPalletView.h"
#import "MovieResource.h"
#import "SyncPlayerView.h"
#import "SyncSlider.h"
#import "SyncRotator.h"
#import "RangeSlider.h"
#import "def64bit_common.h"

typedef enum {
    SelectVideoTypeNone,
    SelectVideoTypeOne,
    SelectVideoTypeTwo
} SelectVideoType;

@interface EditVideoViewController : UIViewController <UIScrollViewDelegate, OKDClickImageViewDelegate, UIFlickerButtonDelegate, MainViewControllerDelegate,PlayerViewPlayDelegate,SyncSliderDelegate,RangeSliderDelegate,VideoSaveViewControllerDelegate,UIGestureRecognizerDelegate> {
    IBOutlet UILabel		*lblUserName;				// ユーザ名
	IBOutlet UILabel		*lblWorkDate;				// 施術日
	IBOutlet UILabel		*lblWorkDateTitle;			// 施術日タイトル
	IBOutlet UIView			*viewUserNameBack;			// ユーザ名背景
	IBOutlet UIView			*viewWorkDateBack;			// 施術日背景
	
	IBOutlet UIButton		*btnOverlayCamera;			// 重ね合わせカメラボタン
    IBOutlet UIButton       *btnSave;                   // 動画保存ボタン
	IBOutlet UIButton		*btnHardCopyPrint;			// ハードコピーボタン
    IBOutlet UIButton		*btnFacebookUp;             // facebook投稿ボタン
    IBOutlet UIButton		*btnMailSend;               // mail送信ボタン
	
    // 2012 7/13 写真を重ねて表示
    IBOutlet UIButton		*btnAbreast;                // 写真の並列表示（デフォルト）
	IBOutlet UIButton		*btnOverlap;                // 写真を重ねる
    // DELC SASAGE
    IBOutlet UIView         *playPallet;                // 再生ボタンなどを配置するパレット
    IBOutlet UIButton       *btnPlay;                   // 再生ボタン
    IBOutlet UIButton       *btnPlaySync;               // 再生同期ボタン
    IBOutlet UIButton       *btnPlaySpeed;              // 再生スピードボタン
    IBOutlet UILabel        *lblPlaySpeed;
    
    IBOutlet UIButton       *btnLockMode;				// ロックモード切り替えボタン
    
    IBOutlet UIView         *vwVideoEditMode;
    IBOutlet UIButton       *btnWindowDraw;
    IBOutlet UIButton       *btnFrameDraw;
    
    IBOutlet PicturePaintManagerView *vwPaintManager;
	//IBOutlet UIImageView	  *imgvwOverlay1;			// オーバーレイImageView		:常に表示
	//IBOutlet UIImageView	  *imgvwOverlay2;			// オーバーレイImageView		:常に表示
	UIImageView	  *imgvwOverlay1;			// オーバーレイImageView		:常に表示
	UIImageView	  *imgvwOverlay2;			// オーバーレイImageView		:常に表示
	IBOutlet UIView			*vwSaparete1;				// 区分線				:lockモードのみ表示
	IBOutlet UIView			*vwGrayOut11;				// グレイアウトView-1	:lockモードのみ表示
	IBOutlet UIView			*vwGrayOut12;				// グレイアウトView-2	:lockモードのみ表示
	IBOutlet UIView			*vwSaparete2;				// 区分線				:lockモードのみ表示
	IBOutlet UIView			*vwGrayOut21;				// グレイアウトView-1	:lockモードのみ表示
	IBOutlet UIView			*vwGrayOut22;				// グレイアウトView-2	:lockモードのみ表示
	PicturePaintPalletView	*vwPaintPallet;    // パレット:InterfaceBuilderを使用しない
    
    UIView           *vwStampE;
	// PicturePaintPalletView	*vwPaintPallet2;				// パレット:InterfaceBuilderを使用しない
    
    UILabel  *currentTimeLabel;                         // 再生時間の表示。再生バーの横
    UIView   *underCurrentTimeView;                // 再生時間表示バーの下。範囲指定バーの横。デザイン上のもの。
    BOOL	_isModeLock;								// ロックモード：YES
    
	bool	_isBackCameraView;							// 画面遷移でカメラ画面へ戻るか？
	
	NSMutableArray *pictImageItems;						// 画像Imageのリスト：UIImage*のリスト
	
	UIScrollView *_scrollView;							// スクロールビュー
	UIView	*_drawView;									// 描画View
	UIFlickerButton			*_btnPrevView;				// 前画面に戻るボタン
	
	OKDFullScreenImageView *_fullView;					// 全画面表示view;
    
	BOOL	_isPicturePaintDisplaied;					// 写真描画に遷移したか
    
	BOOL	_isNavigationCall;							// 本画面がnavigationControllerよりコールされたか
	
	BOOL	_isFlickEnable;								// Flickを有効にするか？
	
	NSUInteger				_selectedTagID;				// 選択されたTagID:OKDClickImageView
	
	USERID_INT				_userID;					// ユーザID（画像合成ビューで必要）
	HISTID_INT				_histID;					// 履歴ID（画像合成ビューで必要）
	NSDate					*_workDate;					// 施術日
	
	UIPopoverController		*popoverCntlMailSend;		// Mail送信用ポップアップコントローラ
    
	IPAD_CAMERA_WINDOW_VIEW		_windowView;			// 遷移する画面
    
    MovieResource               *movie;                 // 選択動画
    float                       movieDuration;          // 動画再生時刻
    BOOL                        isPlaySynth;
    const NSArray               *playRateArray;         // 動画再生レート
    VideoPreviewWideViewController *videoPreviewVC;
    
    SyncPlayerView              *player1;
    SyncSlider                  *slider1;
    RangeSlider                 *rangeSlider1;
    IBOutlet SyncRotator        *rotator1;
    IBOutlet UIButton           *btnAnimeAdd1;
    NSMutableArray              *animations1;
    CGFloat                     angle1;
    IBOutlet UIImageView        *ivErrorDisp;
    BOOL                        remainSavingVideo;
    
    BOOL isSaving;        //動画作成中
    BOOL shouldSave;      //（最終編集から）動画が編集されたか
    BOOL isDrawMode;      // 動画編集が可能なモードなのか
    
    //0313VideoCompViewController *videoCompVCfromThumb;      // サムネイル一覧画面からの遷移のときのみVideoCompViewをサブビューとして扱う
    //0313SelectVideoViewController *selectVideoVCfromThumb;      // サムネイル一覧画面からの遷移のときのみVideoCompViewをサブビューとして扱う
    
	UIAlertView *modifyCheckAlert;						// 修正確認Alertダイアログ
	NSUInteger	_modifyCheckAlertWait;					// 修正確認Alertダイアログ終了待機
}
- (IBAction)OnCameraView;								// カメラ画面へ戻る
//0313- (IBAction)OnSelectPictView;							// 画像ファイル選択

- (IBAction)OnOverlayCamera;							// 重ね合わせカメラ
- (IBAction)OnSave;                                     // 動画保存
- (IBAction)OnHardCopyPrint;							// ハードコピー

- (IBAction)OnFacebookUp;                               // facebook投稿
- (IBAction)OnMailSend;                                 // Mail送信
- (IBAction)OnBtnSynthesisModeChange:(id)sender;
- (IBAction)OnBtnVideoEditModeChange:(id)sender;
//- (IBAction)OnPlaySynth;
- (IBAction)OnPlay;
- (IBAction)OnPlaySpeed;
- (IBAction)OnBtnAddAnime:(id)sender;

- (void)clearCanvas;
// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName isSexMen:(BOOL)isMen;
// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName nameColor:(UIColor*)color;
// 施術日の設定：設定により表示される
- (void)setWorkDateWithString:(NSString*)workDate;

- (void)setWorkItemInfo:(USERID_INT)userID workItemHistID:(HISTID_INT)histID
			   workDate:(NSDate*)date;
//0313- (void)setMovieItems:(NSMutableArray*)movies isDrawMode:(BOOL)isDrawMode;
- (void)setMovie:(MovieResource *)movie;
- (void)willResignActive;
// 必要かどうか
// ScrollViewと描画Viewの作成
//- (void) makeScrDrawView;

// 画像Itemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
//- (void) pictImagesLayout:(BOOL)isPortrait;

// facebook機能の有効
- (void) setFacebookEnableIsFlag:(BOOL)isEnable;
// mail機能の有効
- (void) setMailEnableIsFlag:(BOOL)isEnable;


@property(nonatomic) BOOL isNavigationCall;
@property(nonatomic) BOOL isFlickEnable;
@property(nonatomic, retain)		NSDate		*workDate;
@property(nonatomic, retain) VideoPreviewWideViewController *videoPreviewVC1;
@property(nonatomic, retain) VideoPreviewWideViewController *videoPreviewVC2;
@end
