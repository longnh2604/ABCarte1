//
//  PicturePaintCommon.h
//  iPadCamera
//
//  Created by MacBook on 11/03/04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stamp.h"

#ifdef CALULU_IPHONE
#define VIEW_WIDTH			320.0f		// 画面のView幅サイズ
#define VIEW_HEIGHT			240.0f		// 画面のView縦サイズ
#else
#define VIEW_WIDTH			728.0f		// 画面のView幅サイズ
#define VIEW_HEIGHT			546.0f		// 画面のView縦サイズ
#endif

#define SPARATE_LINE_WIDTH	6.0f		// 区分線VIEWの幅

// 描画モード
typedef enum
{
	MODE_RELEASED		= 0,		// 指が放された
	MODE_WAITING_JUDGE,				// 判定待ち
	MODE_VOID,						// 機能しない
	MODE_SPARATE_DRAW	= 0x11,		// 区分線の描画
	MODE_SPARATE,					// 区分線（グレーアウト）
	MODE_LINE			= 0x101,	// 直線
	MODE_SPLINE,					// スプライン
	MODE_ERASE,						// 消しゴム
    MODE_CHARA,						// 文字挿入
    MODE_CIRCLE,
	MODE_REDO			= 0x201,	// 元に戻す
    MODE_ROTATION		= 0x301,	// 回転
	MODE_LOCK			= 0x800,	// ロック状態（編集不可）
    MODE_SELECT_STAMP,              // スタンプが選択されている状態
    MODE_STAMP,                     // スタンプ //DELC SASAGE
}  PICTURE_PAINT_DRAW_MODE;

// パレットボタンのコマンド（ボタン種別）
typedef NS_ENUM(NSInteger, PALLET_BUTTON_COMMAND)
{
	PALLET_SEPARATE_DRAW = 0x11,	// 区分線描画			：a
	PALLET_SEPARATE,				// 区分線（グレーアウト）：b
	PALLET_SEPARATE_DELETE,			// 区分線削除			：c
	PALLET_LINE			= 0x101,	// 直線				：d
	PALLET_SPLINE,					// スプライン			：e
	PALLET_ERASE,					// 消しゴム			：f
    PALLET_CHARA,                   // 文字挿入           ：m
    PALLET_CIRCLE,

	PALLET_DRAW_COLOR	= 0x140,	// 描画色				：g〜i
	PALLET_DRAW_WIDTH	= 0x180,	// 描画太さ			：j〜l
	PALLET_UNDO			= 0x201,	// 元に戻す
    PALLET_ROTATION		= 0x301,	// 回転
    PALLET_ALL_CLEAR    = 0x800,    // 全消去
    PALLET_STAMP,                   // スタンプ //DELC SASAGE
    PALLET_VOID,                    // 何もしない
} ;

// パレットのイベント
@protocol PicturePaintPalletDelegate<NSObject>

@optional

// 描画モード変更
// args: command=PALLET_DRAW_COLOR->UIColor command=PALLET_DRAW_WIDTH->NSNumber(float)
-(void) OnDrawModeChange:(id)sender changedCommand:(PALLET_BUTTON_COMMAND)command args:(id)args;

// Viewに２つのPicturePaintManagerViewがあるとき
- (BOOL) allClear;

- (void)setSelectedStamp:(Stamp *)stamp;
@end


///
/// 写真描画の共通項目
///
@interface PicturePaintCommon : NSObject {

}

@end
