//
//  PicturePaintManagerView.h
//  iPadCamera
//
//  Created by MacBook on 11/03/04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PicturePaintCommon.h"
#import "PictureDrawParts.h"
#import "PopUpViewContollerBase.h"
#import "Stamp.h" //DELC SASAGE
#import "DoublePicturePaintPalletView.h"
#import "PicturePaintViewController.h"
#import "TouchManager.h"
#define GRAY_OUT_VIEW_SHOW_APLHA		0.65f			// グレーアウトViewの選択時のAlpha値

#define ERASE_COLOR_NO					NSIntegerMax	// 消しゴムの色番号

@class PicturePaintPalletView;

///
/// 写真描画の管理クラス
///
@interface PicturePaintManagerView : UIView <PicturePaintPalletDelegate,PopUpViewContollerBaseDelegate>
{

	UIScrollView	*scrollViewParent;			// 親スクロールビュー
	UIView			*vwSaparete;				// 区分線				
	UIView			*vwGrayOut1;				// グレイアウトView-1	
	UIView			*vwGrayOut2;				// グレイアウトView-2
    UIView          *vwStampE;
    UIImageView     *vwStampEdit;               // エディット中スタンプ
    UIImageView     *imgvwStamp;
	
	CGContextRef	canvasContext;	//	絵を書き込む仮想キャンバス
	CGPoint			lineStartPos;	//	タッチイベントで更新される次の線を引くためのcanvasContext上の開始位置。
	CGPoint			pickPos;		//	touchesBeganで保存する起点座標。
	CGPoint			_sparatePos;	//	区分線の座標
	UITouch*		pickTouch;		//	touchesBeganで保存する起点座標を持つUITouchインスタンス。
	UIColor*		penColor;		//	ペンの色
	double			penWidth;		//	ペンの幅
	BOOL			eraseMode;		//	消しゴムにする場合YES
	
	CGImageRef		lastImage;
	CGImageRef		lastImageForLine;			// 直線描画時に使用する
	CGImageRef		lastImageForCircle;			// 円描画時に使用する
    CGImageRef      lastImageForStamp;          // スタンプ描画時に使用する //DELC SASAGE
    
	NSInteger		_drawColorNo;				// 描画色番号
	
	PICTURE_PAINT_DRAW_MODE		_drawMode;		// 描画モード
	PICTURE_PAINT_DRAW_MODE		_touchMode;		// touchイベント管理用モード
	
	BOOL _isLineFirstTouch;						// 区分線描画または直線モードで最初にタッチされたことを示す
	BOOL _isSparatePortraite;					// 区分線は縦方向か
	
	NSInteger		_touchMoveCount4Line;
    
    CGFloat         _lineWidth;                 // 描画太さ（デフォルト1）
    
    NSMutableArray*  pictObjects;               // 描画レイヤーセット
    
    BOOL            setUndo;                    // 次はUndoかRedoか
    PictureDrawParts* lastDrawAction;           // アンドゥー時のオブジェクトを保存
    BOOL _isStampSelect;                        // スタンプ選択画面が表示されているか否か //DELC SASAGE
    BOOL _determinStamp;                        //スタンプが確定しているか否か
                                                //選択画面のスタンプをタップしてから、ボタンまたはもう一度選択が面のスタンプを押すまで、未確定
    BOOL _twiceStampTouch;                      //2回以上スタンプをタッチしたか
    BOOL hasStamp;                              //スタンプが一つでも乗っているかどうか
    BOOL preHasStamp;                           // 全消去時にスタンプが有るかどうかを保存する
    Stamp *stamp;                               //現在編集状態のスタンプ
    Stamp *movestamp;                           //現在編集状態のスタンプ
    Stamp *preStamp;                            //スタンプの拡大縮小などをする前の状態
    BOOL stampMoveFirst;

#if 1 // 不具合対応 kikuta - start - 2014/01/30 -
    PictureDrawParts* prevClearPictObj;         // クリアする前のオブジェクト
#endif // 不具合対応 kikuta - end - 2014/01/30 -

#if STAMP_MODE == 1
    TouchManager *touchM;                       //タッチを管理する
#else
    STAMP_DRAW_MODE stampMode;
    CGPoint resize;
    CGPoint offset;
#endif
    
    UIPopoverController* PopupCharacterInsert;
    NSInteger drawAllDispFlg;

#ifdef PICTURE_ALL_CLEAR_ALERT
    UIAlertView *modifyCheckAlert;						// 修正確認Alertダイアログ
	NSUInteger	_modifyCheckAlertWait;					// 修正確認Alertダイアログ終了待機
#endif
    PicturePaintViewController *ppvController;          //　親のコントローラ
}

@property(nonatomic, retain) UIScrollView	        *scrollViewParent;
@property(nonatomic, retain) UIView			        *vwSaparete;
@property(nonatomic, retain) UIView			        *vwGrayOut1;
@property(nonatomic, retain) UIView		        	*vwGrayOut2;
@property(nonatomic, retain) PicturePaintPalletView	*vwPallet;
@property(nonatomic, retain) NSMutableArray         *pictObjects;                // 描画レイヤーセット
@property(nonatomic, retain) PictureDrawParts       *lastDrawAction;
@property(nonatomic, retain) UIView*                vwStampE;
@property(nonatomic, retain) UIImageView            *imgvwStamp;
@property(nonatomic, assign) CGFloat                brightness;
@property(nonatomic, assign) PicturePaintViewController *ppvController;

#if 1 // 不具合対応 kikuta - start - 2014/01/30 -
@property(nonatomic, retain) PictureDrawParts*  prevClearPictObj;
#endif // 不具合対応 kikuta - end - 2014/01/30 -

@property					 BOOL			IsDirty;			// 編集を行ったかを示すフラグ
@property					 BOOL			IsDrawenable;       // 編集可能か

// lockモードの変更
- (void) changeLockMode:(BOOL)isLock;
// メール送信時の画像固定
- (void) sendMailMode;

// 描画領域のAll Clear
- (void) allClearCanvas;
- (void) allClearCanvas:(BOOL)stat; // undo履歴などの完全消去用

// 区分線の削除
- (void) deleteSeparate;

// 描画Imageを取得
- (UIImage*)getCanvasImage;

- (void)drawObjects:(BOOL)reWrite;

// 描画オブジェクトの初期化
-(void) initDrawObject;
// 上下比較の際、キャンパスをリサイズする
- (void)resizeFrame : (BOOL)isUpdown;
- (void) initLocal;
- (void)initAfterFrameSet;
//選択中のスタンプを設定 //DELC SASAGE
- (void)setSelectedStamp:(Stamp *)_stamp;
// Viewに２つのPicturePaintManagerViewがあるとき
- (BOOL) allClear;

@end
