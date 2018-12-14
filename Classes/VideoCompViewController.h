//
//  VideoCompViewController.h
//  iPadCamera
//
//  Created by 管理者 on 11/06/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MainViewController.h"
#import "GrayOutImageView.h"

#import "MovieResource.h"
#import "CompPlayerView.h"
#import "SyncSlider.h"
#import "RangeSlider.h"
#import "SyncRotator.h"
#import "PicturePaintManagerViewTwoParent.h"
#import "VideoSaveViewController.h"
#import "def64bit_common.h"

// 2012 6/26 伊藤 余白サイズの拡大
#define INIT_VIMAGE_SCALE       3.0f				// 画像初期倍率(背景の黒色が余白となる)

// 制御パレットボタンのコマンド（ボタン種別）
typedef enum
{
	PALLET_SEPARATE_ON	= 0,		// 区分線あり
	PALLET_SEPARATE_OFF,			// 区分線なし
	PALLET_LEFT_TURN	= 0x101,	// 左側画像反転
	PALLET_RIGHT_TURN,				// 右側画像反転
	PALLET_SAVE			= 0x201,	// 保存
} PALLET_CTRL_BUTTON;

@class VideoPaintPalletView;

@interface VideoCompViewController : UIViewController 
	<MainViewControllerDelegate, PlayerViewPlayDelegate,RangeSliderDelegate,SyncSliderDelegate,VideoSaveViewControllerDelegate,UIGestureRecognizerDelegate>
{

	// タイトル関連
	IBOutlet UILabel		*lblUserName;				// ユーザ名
	IBOutlet UILabel		*lblWorkDate;				// 施術日
	IBOutlet UILabel		*lblWorkDateTitle;			// 施術日タイトル
	IBOutlet UIView			*viewUserNameBack;			// ユーザ名背景
	IBOutlet UIView			*viewWorkDateBack;			// 施術日背景
	
	// ボタン
	IBOutlet UIButton		*btnLockMode;				// ロックモード切り替えボタン
	IBOutlet UIButton		*btnToolBarShow;			// コンテナView表示カスタムボタン

	// 以下はスクロールするView群となる：この順が構成順序となる
	IBOutlet CompPlayerView	*player1;				// スクロールビュー1
	IBOutlet CompPlayerView	*player2;				// スクロールビュー2
    IBOutlet SyncSlider *slider1;
    IBOutlet SyncSlider *slider2;
    IBOutlet SyncRotator *rotator1;
    IBOutlet SyncRotator *rotator2;
    UISlider *volumeSlider1;                        // 音量バー
    UISlider *volumeSlider2;                        //
    UILabel  *currentTimeLabel1;                    // 再生時間の表示。再生バーの横
    UILabel  *currentTimeLabel2;                    //
    UIView   *underCurrentTimeView1;                // 再生時間表示バーの下。範囲指定バーの横。デザイン上のもの。
    UIView   *underCurrentTimeView2;                //
    RangeSlider *rangeSlider;
    RangeSlider *rangeSliderRight;                      // 右プレイヤーの下に配置。rangeSliderと同期させる。
	IBOutlet UIView			*vwSaparete;				// 区分線				:lockモードのみ表示
	// GrayOutImageView		*imgvwPicture1;				// 写真ImageView1		:常に表示
	// GrayOutImageView		*imgvwPicture2;				// 写真ImageView2		:常に表示
	
    PicturePaintManagerViewTwoParent *vwPaintManager;
	//IBOutlet UIImageView	  *imgvwOverlay1;			// オーバーレイImageView		:常に表示
    //IBOutlet UIImageView	  *imgvwOverlay2;			// オーバーレイImageView		:常に表示
	PicturePaintPalletView	*vwPaintPallet;             // パレット:InterfaceBuilderを使用しない
	// 制御パレット
	IBOutlet UIView			*vwCtrlPallet;				// 制御パレットビュー
	IBOutlet UIButton		*btnSeparateOn;				// 区分線ありボタン
	IBOutlet UIButton		*btnSeparateOff;			// 区分線なしボタン
	IBOutlet UIButton		*btnLeftTurn;				// 左側画像反転ボタン
	IBOutlet UIButton		*btnRightTurn;				// 右側画像反転ボタン
    IBOutlet UIButton		*btnLeftTurn2;				// 左側画像反転ボタン : 透過画像用
	IBOutlet UIButton		*btnRightTurn2;				// 右側画像反転ボタン : 透過画像用
    
    IBOutlet UIButton       *btnSave;                   // 動画保存ボタン
    IBOutlet UIButton       *btnAnimeAdd;               // アニメ追加ボタン

    // 2012 7/12 透過レイヤーコントローラー
	IBOutlet UIView			*vwSynthesisCtrlPallet;		// 制御パレットビュー
	IBOutlet UIButton		*btnBackOn;                 // 背後ビュー操作
	IBOutlet UIButton		*btnFrontOn;                // 全面ビュー操作
    // IBOutlet UIButton       *btnPlayerMove;          // 動画をタッチ可能に（書き込みを不能に）
	IBOutlet UISlider		*sldRatio;                  // 透過度スライダー
    
    IBOutlet UIView         *playPallet;                // 再生ボタンなどを配置するパレット
    IBOutlet UIButton       *btnPlay;                   // 再生ボタン
    IBOutlet UIButton       *btnPlaySync;               // 再生同期ボタン
    IBOutlet UIButton       *btnPlaySpeed;              // 再生スピードボタン
    IBOutlet UILabel        *lblPlaySpeed;
    
    IBOutlet UIView         *vwVideoEditMode;           // 描画モード切り替え
    IBOutlet UIButton       *btnWindowDraw;             // 画面描画モード
    IBOutlet UIButton       *btnFrameDraw;              // フレーム描画モード
	
    UIView           *vwStampE;
    
	BOOL	_isModeLock;								// ロックモード：YES
	BOOL	_isPicturePaintDisplaied;					// 写真描画に遷移したか
	BOOL	_isToolBar;									// 制御パレットビューとお客様情報を表示中か
	BOOL	_isSkipThisView;							// 本ViewControllerをスキップするか
    BOOL    _isDrawMode;                                // 描画モードか、動画移動モードか

	USERID_INT		_userID;							// ユーザID
	HISTID_INT		_histID;							// 履歴ID
	IBOutlet UIImageView	*imgvwTest;					// TEST
	UIView	*skippedBackgroundView;						// 背景View(画面スキップ時に表示される)
	
	UIInterfaceOrientation	_toInterfaceOrientation;	// 回転する予定のデバイスの向き
	
	BOOL	_isDirty;									// 編集（ズームまたはスクロール）を行ったフラグ
    
    MovieResource               *movie1;                // 選択動画１
    MovieResource               *movie2;                // 選択動画２
    float                       movieDuration1;         // 動画再生時刻１
    float                       movieDuration2;         // 動画再生時刻２
    const NSArray               *playRateArray;         // 動画再生レート
    BOOL                        isPlaySynth;            // 動画の同期再生フラグ
    BOOL                        isPlay;
    BOOL                        isSaving;               // 動画作成処理中
    BOOL                        shoudSave;              //（最終編集から）動画が編集されたか
    
    NSMutableArray *animations;                         // アニメをプレビューする用
    
    AVAsset *asset1;
    AVAsset *asset2;
	UIAlertView *modifyCheckAlert;						// 修正確認Alertダイアログ
	NSUInteger	_modifyCheckAlertWait;					// 修正確認Alertダイアログ終了待機
    
    VideoCompViewController *videoCompVCfromThumb;      // サムネイル一覧画面からの遷移のときのみVideoCompViewをサブビューとして扱う
}

// ロックモード切り替えボタン
- (IBAction) OnBtnLockMode:(id)sender;
// 動画の初期化
- (void)initWithVideo:(MovieResource *)movie1 video:(MovieResource *)movie2 userName:(NSString*)name nameColor:(UIColor*)color workDate:(NSString*)date isDrawMode:(BOOL)isDrawMode;
// 動画の位置情報の設定
- (void)setZoom1:(float)zoom1 offset1:(CGPoint)offset1 reverse1:(BOOL)reverse1 zoom2:(float)zoom2 offset2:(CGPoint)offset2 reverse2:(BOOL)reverse2;
// 動画の再生位置情報の設定
- (void)setCurrentTime1:(CMTime)time1 currentTime2:(CMTime)time2;
// 施術情報の設定
- (void)setWorkItemInfo:(USERID_INT)userID workItemHistID:(HISTID_INT)histID;

// 制御パレットボタン
- (IBAction)OnBtnCtrlPallet:(id)sender;
// 動画を移動可能に
//BtnPlayerMoveDelete0304 - (IBAction)OnBtnPlayerMove:(id)sender;

// コンテナViewとユーザ名の表示ボタン（横表示のみ）
- (IBAction)onShowToolBar;

// レイアウトを設定する
//- (void)setLayout;

// スキップ設定
- (void)setSkip:(BOOL)skip;

- (IBAction)OnPlaySynth;
- (IBAction)OnPlay;
- (IBAction)OnPlaySpeed;

- (IBAction)OnSave;                                     // 動画保存
- (IBAction)OnBtnVideoEditModeChange:(id)sender;
- (IBAction)OnAnimeAdd;
- (void)clearCanvas;                                    // 描画内容をクリア
- (void)willResignActive;

@property		BOOL	IsSetLayout;						// レイアウト調整を行うか
@property		BOOL	IsNavigationCall;					// 本画面がnavigationControllerよりコールされたか
@property		BOOL	IsRotated;							// 回転されたかどうか

//
@property		BOOL	IsOverlap;							// 透過オーバーラップモードかどうか
@property       BOOL    IsvwSaparate;                       // 突き合わせ時の分割線のON/OFF
@property		BOOL	IsUpdown;							// 上下比較かどうか

@end
