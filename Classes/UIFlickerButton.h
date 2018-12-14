//
//  UIFlickerButton.h
//  iPadCamera
//
//  Created by MacBook on 11/02/28.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@protocol UIFlickerButtonDelegate;

#import <UIKit/UIKit.h>

#define	FLICK_JUDEG_FW_VEC			20.0f		// フリック判定速度（正方向）
#define	FLICK_JUDEG_BK_VEC			-20.0f		// フリック判定速度（逆方向）
#define BEFORE_AXIS_INVALID			CGFLOAT_MAX	// 座標値無効値

#define LONG_TOUCH_TIMER			3000.0f		// 長押し判定タイマの時限

// フリック状況定義
typedef enum
{
	FLICK_NONE	= 0x00,		// フリックしていない（初期状態）
	FLICK_LEFT	= 0x11,		// フリック左方向:右から左
	FLICK_RIGHT	= 0x12,		// フリック右方向:左から右
	FLICK_UP	= 0x21,		// フリック上方向:下から上
	FLICK_DOWN	= 0x22,		// フリック下方向:上から下
	FLICK_INVALID = 0xffff,	// フリック無効値（フリック機能を使用しない）
} FLICK_STATE;

///
/// フリッカするボタン
///
@interface UIFlickerButton : UIButton 
{
  @package
	CGFloat		_xBeforeAxis;						// 直前のX座標
	CGFloat		_yBeforeAxis;						// 直前のY座標
	FLICK_STATE _flickState;						// フリック状況
	FLICK_STATE _requestFlickType;					// 要求するフリックの種別:デフォルト=FLICK_NONE
	
	// NSDate*		_touchDownTime;						// TouchDownした時間
	NSTimer*	_longTouchTimer;					// 長押し判定タイマ
}

@property(nonatomic,assign)    id <UIFlickerButtonDelegate> delegate;
@property(nonatomic) FLICK_STATE requestFlickType;

// 作成
+ (id)initWithFrameOwner:(CGRect)frame ownerView:(id)view;

// 初期化処理
- (void) initialize:(id)ownerView;

// Single Touchイベント
-(void) onTouchDown:(id)sender;

// ドラッグの開始
-(void)onFlickStart:(id)sender forEvent:(UIEvent*)event;
// ドラッグの終了またはTouchUp
-(void)onFlickEnd:(id)sender forEvent:(UIEvent*)event;


 
@end


@protocol UIFlickerButtonDelegate<NSObject>
@optional

// フリックイベント
- (void)OnFlicked:(id)sender flickState:(FLICK_STATE)state;

// ダブルタップイベント
- (void)OnDoubleTap:(id)sender;

// 長押しイベント
- (void)OnLongTouchDown:(id)sender;

@end
