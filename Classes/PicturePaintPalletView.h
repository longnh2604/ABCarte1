//
//  PicturePaintPalletView.h
//  iPadCamera
//
//  Created by MacBook on 11/03/04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PicturePaintCommon.h"
#import "PopUpViewContollerBase.h"
#import "StampSelectView.h"
#ifdef CALULU_IPHONE
#define VARIABLE_PICTURE_PAINT_PALLET
#define PICTURE_PAINT_PALLET_POPUP
//---------------------------------------------------------------------
#define ICON_SIZE					38.0f		// アイコンサイズ
#define ICON_SIZE_MINI				38.0f		// アイコンサイズ(小)

#define PORTRAIT_VIEW_WIDTH			312.0f		// 縦画面のView幅サイズ
#define PORTRAIT_VIEW_HEIGHT		42.0f		// 縦画面のView縦サイズ
#define LANDSCAPE_VIEW_WIDTH		344.0f		// 横画面のView幅サイズ
#define LANDSCAPE_VIEW_HEIGHT		42.0f		// 横画面のView縦サイズ
//---------------------------------------------------------------------
#else
//---------------------------------------------------------------------
#define ICON_SIZE					60.0f		// アイコンサイズ
#define ICON_SIZE_MINI				50.0f		// アイコンサイズ(小)

#define PORTRAIT_VIEW_WIDTH			728.0f		// 縦画面のView幅サイズ
#define PORTRAIT_VIEW_HEIGHT		70.0f		// 縦画面のView縦サイズ
#define LANDSCAPE_VIEW_WIDTH		70.0f		// 横画面のView幅サイズ
#define LANDSCAPE_VIEW_HEIGHT		570.0f		// 横画面のView縦サイズ
#define LANDSCAPE_STAMP_SELECT_X    148.0f       // 横画面のときのスタンプ選択画面のx位置 //DELC SASAGE
#define LANDSCAPE_STAMP_SELECT_Y    674.0f      // 横画面のときのスタンプ選択が面のy位置 //DELC SASAGE
//---------------------------------------------------------------------
#endif

// ボタン状態
typedef enum
{
	STATE_DISABLE,
	STATE_NORMAL,
	STATE_SELECT,
	STATE_INVALID,
} PALLET_BUTTON_STATE;

#ifdef VARIABLE_PICTURE_PAINT_PALLET
// パレットの表示状態
typedef enum 
{
    VARIABLE_PALLET_DISP_SHOW    = 0x0001,    // 表示
    VARIABLE_PALLET_DISP_HIDE    = 0x0008,    // 非表示
    VARIABLE_PALLET_PORTRAITE    = 0x1000,    // Portraite位置
    VARIABLE_PALLET_RANDSCAPE    = 0x8000,    // Randscape位置
} VARIABLE_PALLET_DISP_STATE;
#endif

// #ifdef PICTURE_PAINT_PALLET_POPUP
@class PicturePaintPalletPopupView;
// #endif

///
/// 写真描画のパレット管理View
///
@interface PicturePaintPalletView : UIView<StampSelectViewDelegate> {
	
	
	NSDictionary	*_listBtnNibName;			// ボタンのimageのnib名のリスト（状態を除く）
	
	UIButton		*btnSapareteDraw;			// 区分線描画ボタン
	UIButton		*btnSaparete;				// 区分線（グレーアウト）ボタン
	UIButton		*btnSapareteDelete;			// 区分線削除ボタン
	UIButton		*btnLineDraw;				// 直線ボタン
    UIButton        *btnCircleDraw;             // 円ボタン
	UIButton		*btnSplineDraw;				// スプラインボタン
	UIButton		*btnEraseDraw;				// 消しゴムボタン
    UIButton		*btnAllClear;				// 全消去ボタン
	UIButton		*btnDrawColor;			    // 描画色ボタン 赤ー＞緑->青の順で変わる。//DELC SASAGE
#ifdef PICTURE_PAINT_PALLET_POPUP
    UIButton		*btnDrawColorRed;
    UIButton		*btnDrawColorGreen;
    UIButton		*btnDrawColorBlue;
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    UIButton		*btnDrawColorWhite;
    UIButton		*btnDrawColorBeige;
    UIButton		*btnDrawColorBlack;
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    UIButton		*btnDrawWidthSLight;
    
    UIButton		*btnDrawWidthLight;
    UIButton		*btnDrawWidthMiddle;
    UIButton		*btnDrawWidthHeavy;
#endif
    UIButton        *btnDrawWidth;              //描画太さボタン //DELC
    UIButton        *btnStamp;                  //スタンプボタン //DELC SASAGE
	UIButton		*btnUndo;					// 元に戻すボタン
    UIButton		*btnRotation;				// 回転ボタン
	
    UIButton		*btnInChara;				// 文字挿入ボタン

	u_int           _selectColorNo;				// 描画色の選択番号：1〜3
	u_int           _selectWidthNo;				// 描画太さの選択番号：1〜3
    StampSelectView *stampSelectView;           //スタンプを選択する画面
    BOOL            _hiddenStampSelect;         //スタンプ選択画面が表示されているか否か
#ifdef VARIABLE_PICTURE_PAINT_PALLET    
    UIButton        *btnPalleteShowHide;        // パレットの表示と非表示ボタン
#endif
    UIPopoverController *popupSapareteView;     //区分線設定ウィンドウ
    UIPopoverController *popupLineDraw;         //線分描画設定ウィンドウ
    UIPopoverController *popupUndo;             //アンドゥ設定ウィンドウ

#ifdef PICTURE_PAINT_PALLET_POPUP
    PicturePaintPalletPopupView     *_vwColorPoupup;         // 描画色のポップアップView
    PicturePaintPalletPopupView     *_vwLineWidthPoupup;     // 描画太さのポップアップView    
#endif
    PicturePaintPalletPopupView     *_vwErasePoupup;         // 消しゴムと全消去の切り替えポップアップView
}

// パレットイベントのリスナー
@property(nonatomic,assign)    id <PicturePaintPalletDelegate> delegate;

@property float uiOffset;   // iOS7用にUIの位置調整用offset

// 初期化
- (id) initWithEventListner :(id<PicturePaintPalletDelegate>)listner;
// 回転ボタンを表示
- (void)displayRotationBtn;
// パレットの位置の設定
- (void) setPositionWithRotate:(CGPoint)origin isPortrate:(BOOL)isPortrate;
// 動画編集用のパレットの一の設定
- (void) setVideoEditPositionWithRotate:(CGPoint)origin isPortrate:(BOOL)isPortrate;

// Lock状態の設定
- (void) setLockState:(BOOL)isLock;

// 区分線（グレーアウト）への移行通知
- (void) notifySeparateGrayOut;

// 区分線系のボタンの初期化
- (void) initBtnSeparate;

#ifdef VARIABLE_PICTURE_PAINT_PALLET  
// 動的パレットの初期化
- (void) initVariablePallet:(UIView*)parentView;
#endif

// #ifdef PICTURE_PAINT_PALLET_POPUP
// Popupのセットアップ
- (void) setupPalletPopup;
// #endif
//スタンプ選択画面のスタンプを全て未選択状態に
- (void)setStampsUnselected;
// protected
// 継承クラス用
- (void) _closeAllPalletPopup;
- (void) onBtnSeparete:(id)sender;
- (void) onBtnDraw:(id)sender;
- (void) onBtnColor:(id)sender;
- (void) onBtnWidth:(id)sender;
- (void) onBtnStamp:(id)sender;
- (void) onBtnUndo:(id)sender;
- (void) setButtonState:(UIButton*)button forState:(PALLET_BUTTON_STATE)state;
- (void) setColorButtonState:(UIButton*)button forState:(PALLET_BUTTON_STATE)state;
- (void) setNormalBtnStamp;
- (void) unselectStampIfSelected;
- (void) setStampSelectViewPoint:(CGPoint)point;
@end
