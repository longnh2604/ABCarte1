//
//  camaraViewController.h
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

#import "libAirMicro.h"
#import "UICameraViewPicker.h"
#import "VideoSaveViewController.h"
#import "CamSelectView.h"
#import "CamSelectDotView.h"
#import "SonyCameraRemoteViewController.h"
#import "def64bit_common.h"
#import "SilhouetteGuidePopupViewController.h"
#import "CameraModePopup.h"
#import "UIViewGridLine.h"

#import "MjpegStreamView.h"
#import "MjpegStreamSetting.h"
#import "Camera3RSettingPopup.h"

@class UIImageView4Camera;

@class WebCameraDeamon;

#define WAIT_IMG1	@"wait1a.png"
#define WAIT_IMG2	@"wait2a.png"

// server:iPodへの送信コマンド定義
typedef NS_ENUM(NSInteger, IPOD_SEND_COMMAND) {
	IPOD_SEND_COMMAND_FILE_SEND_REQUEST = 1,	// ファイル送信要求
	IPOD_SEND_COMMAND_BUSY_SET			= 0x10,	//　iPodのbusy状態設定
	IPOD_SEND_COMMAND_BUSY_RESET		= 0x20,	//　iPodのbusy状態解除
    IPOD_SEND_COMMAND_PREV_RETRY_RESET	= 0x21,	//　iPodのプレビューbusy状態解除
    IPOD_SEND_COMMAND_FOCUS_REQUEST		= 0x40,	//　フォーカスの要求
} ;

// popupViewのID定義
typedef enum
{
	POPUP_IPAD2_CAM_SET		= 0x0001,		// iPad2内蔵カメラの設定用popup
    POPUP_CAMERA_MODE       = 0x0010,        // カメラモード切り替え用popup
} CM_VC_POPUP_VIEW_ID;

#define		CM_VC_CAMERA_DISABLE		0x8000		// カメラ使用不可
#define		CM_VC_CAMERA_SELECTED		0x0001		// カメラ選択
#define		CM_VC_CAMERA_NOT_SELECTED	0x0000		// カメラ非選択

#define		CM_VC_BOTTOM_PANEL_LAND_ALPHA	0.2f	// 下部のボタン類のコンテナView横向きのalapa値

#define IMPORT_PICT_ENABLE_NUMS_KEY	@"import_picture_enable_nums"       // お試し期間での写真アルバム取り込み規定枚数の設定ファイル用キー

@interface camaraViewController : UIViewController
<
AMImageViewDelegate,            GKSessionDelegate,
GKPeerPickerControllerDelegate, UICameraViewPickerDelegate,
UIScrollViewDelegate,           UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UIAlertViewDelegate,
UIPopoverControllerDelegate,    VideoSaveViewControllerDelegate,
CamSelectKindDelegate,          CamSelectDotViewDelegate,
takePicDelegate,        // Sonyカメラ撮影
statusPicDelegate,      // Sonyカメラステータス処理
SilhouetteGuidePopupDelegate
>
{
	
	AMImageView					*airmicro;				// カメラSDKライブラリ
	IBOutlet UIButton			*airMicroButton;		// カメラ画面タッチ用ボタン
	
	IBOutlet UILabel			*capField;				// キャプチャー時の表示ラベル
	IBOutlet UILabel			*frzField;				// フリーズ時の表示ラベル
	IBOutlet UIActivityIndicatorView	*indField;		// 待機表示（砂時計ICON）
	IBOutlet UIBarButtonItem	*camShutter;			// カメラシャッターボタン
	IBOutlet UIBarButtonItem	*camFreeze;				// カメラフリーズボタン
	
//	IBOutlet UISegmentedControl	*segCtrlSwicthCamera;	//  AirMicro <-/->iPodTouchカメラ切り替え
	IBOutlet UIImageView		*iPadTouchView;			// iPodTouchカメラ用View
	IBOutlet UIImageView		*iPad2InnerCameraView;	// iPad2内蔵カメラ用View
	IBOutlet UILabel			*lblBlueToothState;		// blootooth接続状況表示
	IBOutlet UILabel			*lblMessage;			// ファイル保存などメッセージ表示
	IBOutlet UIProgressView		*progreBar;				// ファイル保存進行状況
	IBOutlet UIButton			*ReConnectBluetooth;	// bluetooth再接続ボタン
	IBOutlet UILabel			*lblHandVibProc;		// 手ぶれ補正中ラベル
	
//	IBOutlet UIToolbar			*toolBar;				// ツールバー
	
	IBOutlet UIView				*vwBottomPanel;			// 下部のボタン類のコンテナView
	IBOutlet UIButton			*btnPrevView;			// 前画面に戻るカスタムボタン
	IBOutlet UIButton			*btnCamShutter;			// カメラシャッターカスタムボタン
	IBOutlet UIButton			*btnCamFreeze;			// カメラフリーズカスタムボタン
	IBOutlet UIButton			*btnFrontRearChg;		// FrontRear切替(iPad2用)カスタムボタン
	IBOutlet UIButton			*btnAirMicro;			// AirMicroカスタムボタン
	IBOutlet UIButton			*btniPadCamera;			// iPhone／iPodカメラカスタムボタン
	IBOutlet UIButton			*btniPad2InnerCamera;	// iPad2内蔵カメラカスタムボタン
	IBOutlet UIButton			*btnOverlayViewSetting;	// 重ね合わせ透過画像カスタムボタン
	IBOutlet UIButton			*btnToolBarShow;		// コンテナView表示カスタムボタン
    IBOutlet UIButton           *btnSilhouetteGuide;   // シルエットガイドボタン
    IBOutlet UIButton           *btnCameraMode;        // カメラモードボタン
// #ifdef AIKI_CUSTOM
    IBOutlet UIButton           *btnWebCamera;          // Webカメラカスタムボタン
    UIButton                    *btnSonyCamera;         // Sonyカメラボタン(実態なし)
    IBOutlet UIButton *btn3RCamera;  //3R Camera
    
    // #endif
	IBOutlet UIButton           *btnVideo;              // ビデオ撮影（手動停止）
    IBOutlet UIButton           *btnVideoAuto;          // ビデオ撮影（自動停止）
    IBOutlet UIButton           *btnVideoRecord;
    //2012 6/27 伊藤 フォトライブラリから取り込み
//    IBOutlet UIButton           *btnOpenPhotoLibrary;      //フォトライブラリを開くボタン
    UIPopoverController         *imagePopController;    //フォトライブラリ用ポップアップ
    UIAlertView                 *saveCheckAlert;         //保存確認アラート
    
	IBOutlet UILabel			*lblUserNameTitle;			// お客様名のタイトルラベル
	IBOutlet UILabel			*lblUserName;				// ユーザ名
	IBOutlet UILabel			*lblUserNameDim;			// 様のタイトルラベル
	IBOutlet UILabel			*lblWorkDateTitle;			// 施術日のタイトルラベル
	IBOutlet UILabel			*lblWorkDate;				// 施術日
	IBOutlet UILabel            *lblCount;                  // 動画撮影時間
	IBOutlet UIImageView4Camera	*img4CameraView;			// 重ね合わせ透過画像
    IBOutlet UIViewGridLine     *gridLineView;
    IBOutlet UIView             *CamControll;           // カメラ種別制御View
    CamSelectView               *CamSelect;             // カメラ種別選択
    NSInteger                   CamSelNumber;           // カメラ選択番号
    CamSelectDotView            *CamSelectDot;          // カメラ種別選択ボタン
    BOOL                        CamSelSlide;            // スライドボタンによるカメラ選択処理を表すフラグ
    BOOL                        CurOrientation;
    IBOutlet UIImageView        *redDot;                // 選択カメラの位置表示目印
    BOOL                        shutterLock;            // 撮影禁止ロック(スライドボタン変更直後に撮影されるのを防ぐため）
    BOOL                        rapidFireLock;          // 連続撮影を抑制する為のフラグ
    BOOL                        lock3R;
    
    IBOutlet UIView             *CamZoomView;           // ズーム操作View
    IBOutlet UISlider           *CamZoomSlider;         // ズームスライダー
    IBOutlet UIButton           *btnZoomWide;           // 広角ズームボタン
    IBOutlet UIButton           *btnZoomTele;           // 望遠ズームボタン

    IBOutlet UIView             *CamExposureView;       // 露出制御View
    IBOutlet UISlider           *CamExposureSlider;     // 露出スライダー
    IBOutlet UIButton           *btnDark;               // 露出マイナス補正
    IBOutlet UIButton           *btnBright;             // 露出プラス補正
    IBOutlet UIButton           *btnCamRotate;          // カメラ画像回転
    IBOutlet UILabel           *lblAttitude;            // 端末の傾き
    
    IBOutlet UIButton           *btn3RCameraSetting;
    float                       ipadExposure;           // iPadの露出補正値
    float                       sonyExposure;           // Sonyカメラの露出補正値
    float                       camera3RExposure;
    
    
    IBOutlet UISlider *camera3RSlider;
    IBOutlet UIView *camera3RView;
    //2012 6/19 伊藤 カメラフォーカス、露出のタッチ設定
	UIImageView                 *cameraFocusCursor;     //カメラフォーカスカーソル
    // BOOL                        *FocusCursorAnimated;   //フォーカスアニメが終了したか
    IBOutlet UIView             *CursorBaseView;        //カーソル表示用ビュー
    BOOL                        _isFocus4iPodCamera;    // 外部カメラ用フォーカス中フラグ
    
	bool						_isToolBarTop;
	
	bool						_freezeStat;			// フリーズ状態
    
	
	// Game Kit 関連
	GKPeerPickerController* picker;						// 接続先選択ピッカー
	GKSession       *_gkSession;						// blutoohのsession
	NSString        *_peerId;							// 接続先のID(peerID)
	NSString		*_sessionName;						// bluetoothのセッション名（設定ファイルより取得）
	
	// 分割パケット受信用バッファ
	NSMutableData	* _buffer4DivedPacks;
	
	// 選択されたユーザのID
	USERID_INT		_selectedUserID;
	// 施術日
	NSDate			*_workDate;
	// 履歴ID(histID)
	HISTID_INT		_histID;
	
	// iPad2内蔵カメラ用CameraViewPickerクラス
	UICameraViewPicker		*_cameraViewPicker;
	BOOL					_camViewIsHandVib;				// 手ぶれ補正を行うか：iPad2内蔵カメラ用
	NSInteger				_camViewDelayTime;				// 手ぶれ防止の判定時間[sec]
	u_int                   _camViewCaptureSpeed;			// キャプチャー速度（IPAD2_CAM_SET_CAPTURE_SPEED）
	BOOL					_isRearCameraUse;				// Rearカメラ使用中フラグ（デフォルト：Rear）
	UIPopoverController		*popoverCntlCamViewSetting;		// iPad2内蔵カメラ設定用ポップアップコントローラ
	
	// 重ね合わせ画像設定ポップアップViewController
	UIPopoverController		*popoverCntlOverlayViewSetting;	// 重ね合わせ画像設定用ポップアップコントローラ
	BOOL					_isWithOverlaySave;				// 重ね合わせ画像も一緒に保存するか？
	BOOL					_isWithGuideSave;				// ガイド線も一緒に保存するか？
    float                   maxDuration;                    // 自動停止モードの規定時
	BOOL                    _isNavigationCall;				// 本画面がnavigationControllerよりコールされたか
    NSInteger               camResolution;                  // カメラ画像保存解像度 0:Low 1:Mid 2:High
    NSInteger               webCamExposure;                 // SonyWebカメラ露出補正
    NSInteger               webCamZoom;                     // SonyWebカメラズームポジション
    NSInteger               webCamRotate;                   // SonyWebカメラ画像回転ポジション
    NSInteger               webCamResolution;               // SonyWebカメラ画像解像度
    BOOL                    isInitCamExposure;              // カメラ起動後、初期設定完了フラグ
    BOOL                    isInitCamZoom;
    NSInteger               CamRotate[4];                   // カメラ画像回転角の配列
    
#ifdef CALULU_IPHONE
    BOOL    _isShowModalPopup;                              // ModalPopが表示されているか？
#endif
    
    UIAlertView             *sentHomePageAlert;             //Caluluホームページ遷移確認

    WebCameraDeamon         *_webCameraDaemon;              //Webカメラ操作クラス
    
    SonyCameraRemoteViewController  *_SonyCameraDaemon;     // SonyCamera操作クラス
    
    long long lastCameraModeChange;
    
    BOOL                    videoRecLock;                   // ビデオ録画ボタン連打回避用
    NSMutableArray          *CameraButtons;                 // 有効なカメラボタンを格納した配列
    NSMutableArray          *CameraSelFunc;                 //
    NSString                *lastImageFileName;             // 最終保存画像ファイル名

    UIBackgroundTaskIdentifier  backgroundTaskIdentifer;    // バックグラウンド処理ハンドル
    BOOL                    isBackGround;                   // バックグラウンド中か？
    BOOL                    isSonyConnected;                // Sonyカメラへの接続完了フラグ
    BOOL                    isBlueToothStateAnimating;      // bluetooth状況表示のアニメーション中フラグ
    NSInteger               selectedsilhouetteGuide;       // 選択中のシルエットガイド
    NSInteger               cameraMode;                     // カメラモード
//    BOOL                    isSaved;
}
//3R Camera
@property (retain,nonatomic) MjpegStreamView *mjpegStreamView;
@property (retain,nonatomic) MjpegStreamSetting *mjpegStreamSetting;

//@property(nonatomic, retain) GKSession   *_gkSession;
@property(nonatomic, copy)		NSString    *_peerId;
@property(nonatomic)			USERID_INT  _selectedUserID;
@property(nonatomic)			HISTID_INT	histID;
@property(nonatomic, retain)	NSDate		*workDate;
@property(nonatomic)            BOOL        isSonySelect;   // Sonyカメラ選択中

@property(nonatomic)            BOOL        isNavigationCall;
@property(nonatomic)            BOOL        reInit;         // 再初期化フラグ（ログイン後、同期後に契約情報が変わっている可能性があるため、表示ボタンの更新を行うため）
@property(assign, nonatomic)            BOOL        isSaved;

// 選択されたユーザ
- (void)setSelectedUser:(USERID_INT)userID
               userName:(NSString*)name
              nameColor:(UIColor*)color;

- (IBAction)OnUserSelect;								// お客様選択画面表示イベント
// - (IBAction)OnCamShutControl;							// シャッター切替イベント
- (IBAction)OnCamShutter;								// カメラシャッターボタンイベント
- (IBAction)OnCamFreeze;								// カメラフリーズボタンイベント
- (IBAction)OniPad2FrontRearChange;						// FrontRear切替(iPad2用)ボタンイベント
//- (IBAction)OnSelectedWindowShow;						// 選択画面ボタン表示イベント

//- (IBAction)OnCameraSelector:(id)sender;				// AirMicro <-/->iPodTouchカメラ切り替え
//- (IBAction)OnReConnectBluetooth;						// bluetooth再接続ボタン

- (IBAction)On3RCameraSelect:(id)sender;            // 3Rカメラ切り替え(カスタムボタン)

- (IBAction)OnAirMicroCameraSelect:(id)sender;			// AirMicroカメラ切り替え(カスタムボタン)
- (IBAction)OniPadCameraSelect:(id)sender;				// iPodTouchカメラ切り替え(カスタムボタン)
- (IBAction)OniPad2InnerCameraSelect:(id)sender;		// iPad2内蔵カメラ切り替え(カスタムボタン)

- (IBAction)OnOverlayViewSetting:(id)sender;			// 重ね合わせ透過画像(カスタムボタン)

//2012 6/27 伊藤 フォトライブラリから取り込み
//- (IBAction)OnOpenPhotoLibrary:(id)sender;              //iOSのフォトライブラリを開く

// コンテナViewとユーザ名の表示ボタン（横表示のみ）
- (IBAction)onShowToolBarUserName;
// - (IBAction)onAirMicroButton;

//#ifdef AIKI_CUSTOM
- (IBAction)OnWebCameraSelect:(id)sender;               // Webカメラ選択ボタンイベント
//#endif
- (IBAction)OnZoomWide:(id)sender;
- (IBAction)OnZoomTele:(id)sender;
- (IBAction)OnExposureChange:(id)sender;
- (IBAction)OnExposureDark:(id)sender;
- (IBAction)OnExposureBright:(id)sender;
- (IBAction)OnCamRotate:(id)sender;

// Video機能 DELC SASAGE
- (IBAction)OnVideoRecord;

//3R Camera
- (IBAction)on3RCameraPressed:(id)sender;
- (IBAction)on3RSliderChange:(UISlider *)sender;
@property (readwrite) int brightnessID;

// Imageの保存
- (bool)saveImageFile:(UIImage*)cameraImage;

// 施術日を和暦で取得
-(NSString*) getWorkDateByLocalTime;

- (void)initAirMicro:(CGRect)setRect;					// カメラSDKの初期化
- (void)destroyAirMicro;								// カメラSDKの終了
- (void)captureDone:(UIImage*)image;					// キャプチャー時のCallback
- (void)freezeDone:(bool)isFreeze;						// フリーズ時のcallback

// ピッカーの初期化
- (void) pickerInit;

#ifdef BLUETOOTH_WIFI_NOT_ENABLE
// bluetooth状況表示
- (void) bluetoothStateDisp:(bool) isDisplay;
#else
// bluetooth状況表示
- (void) bluetoothStateDisp:(bool) isDisplay message:(NSString*)msg;
#endif

// ファイル保存進行状況表示
- (void) fileSaveStateDisp:(bool) isDisplay;

// iPad Touchへのコマンド送信
- (void) sendIpodTouchCommand:(IPOD_SEND_COMMAND)command sendData:(NSArray*)sData;

// cameraViewのActive
// viewDidAppearまたはForegroundActiveに遷移
- (void) didBecomeActive;

// cameraViewのInActive
// viewWillDisappearまたはForegroundInActiveに遷移
- (void) willResignActive;

// 重ね合わせ画像の設定:camera画面を閉じるたびに自動でリセットされる
- (void) setOverlayImage:(UIImage*)img;

// Webカメラの有効化
- (void) setWebCameraEnableWithIsFlag:(BOOL)isEnable;

//3R Camera
- (void)dismiss3RCamera;

@end

#pragma mark -
#pragma mark SonyCameraSDK
@protocol DeviceListDelegate

- (void)didReceiveDeviceList:(BOOL)isReceived;

@end

