//
//  UIFlickerButton.m
//  iPadCamera
//
//  Created by MacBook on 11/02/28.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIFlickerButton.h"


@implementation UIFlickerButton

@synthesize delegate;
@synthesize requestFlickType = _requestFlickType;

#pragma mark private_methods

// UIEventよりpoint座標を取得
-(CGPoint) pointWithEvent:(UIView*)sender andEvent:(UIEvent*)event
{
	NSSet *touches = [event touchesForView:sender];
	UITouch *touch = [touches anyObject];
	return ([touch locationInView:sender]);
}


#pragma mark life_cycle

// 作成
+(id)initWithFrameOwner:(CGRect)frame ownerView:(id)ownerView{
    
    // self = [super initWithFrame:frame];
	UIFlickerButton *btn = [UIFlickerButton buttonWithType:UIButtonTypeCustom];
    if (btn) {
        // Initialization code.
		[btn setFrame:frame];
		
		// 初期化処理
		[btn initialize:ownerView];
		
		NSLog(@"UIFlickerButton : initWithFrameOwner");
    }
    return btn;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    
	// [_longTouchTimer release];
	
	[super dealloc];
}

#pragma mark control_events

// ダブルタップ
-(void)_onDoubleTap:(id)sender
{
	//長押し判定タイマを停止
	[NSObject cancelPreviousPerformRequestsWithTarget:self 
											 selector:@selector(onLongTouchTimer:) object:sender];
	
	if (self.delegate)
	{
		[self.delegate OnDoubleTap:self];
	}
}

// フリックのシュミレート
////////////////////////////////////////

// ドラッグの開始
-(void)onFlickStart:(id)sender forEvent:(UIEvent*)event
{
	// フリック機能を使用しない
	if (_requestFlickType == FLICK_INVALID)
	{	return; }
	
	// 現在のpoint座標を取得
	CGPoint pt = [self pointWithEvent:sender andEvent:event];
	
	// 初回は何もしない
	if ((_xBeforeAxis == BEFORE_AXIS_INVALID) ||
		(_yBeforeAxis == BEFORE_AXIS_INVALID) )
	{
		// 今回座標を保存
		_xBeforeAxis = pt.x;
		_yBeforeAxis = pt.y;
		
		return;
	}
	
	// 各成分の速度
	CGFloat vx = pt.x - _xBeforeAxis;
	CGFloat vy = pt.y - _yBeforeAxis;
	
	// フリック状況をまず初期化する
	_flickState = FLICK_NONE;
	
	// フリック状況を速度で判定
	if (vx <= FLICK_JUDEG_BK_VEC)
	{	_flickState = FLICK_LEFT; }		// フリック左方向:右から左
	else if (vx >= FLICK_JUDEG_FW_VEC)
	{	_flickState = FLICK_RIGHT; }	// フリック右方向:左から右
	else if (vy <= FLICK_JUDEG_BK_VEC)
	{	_flickState = FLICK_UP; }	// フリック上方向:下から上
	else if (vy >= FLICK_JUDEG_FW_VEC)
	{	_flickState = FLICK_DOWN; }	// フリック下方向:上から下
	
	// 今回座標を保存
	_xBeforeAxis = pt.x;
	_yBeforeAxis = pt.y;
#ifdef DEBUG
	NSLog(@"onFlickStart at x／y:%f／%f speed-x／y:%f／%f -> state:%d",
		  pt.x, pt.y, vx, vy, _flickState);
#endif
}
// ドラッグの終了またはTouchUp
-(void)onFlickEnd:(id)sender forEvent:(UIEvent*)event
{
	// フリック有効の場合にのみ画面遷移
	if (_flickState != FLICK_NONE)
	{
		// NSLog(@"flick ok -> state:%d", _flickState);
		
		// 要求するフリック種別に合致しない場合は通知しない
		if ((_requestFlickType == FLICK_NONE) ||
			((_requestFlickType != FLICK_NONE) &&
			 (_requestFlickType == _flickState)) )
		{
			// クライアントクラスにフリックを通知
			if (self.delegate)
			{
				[self.delegate OnFlicked:self flickState:_flickState];
			}
		}
	}
	
	// フリック判定関連のメンバの初期化
	_flickState = FLICK_NONE;
	_xBeforeAxis  = _yBeforeAxis = BEFORE_AXIS_INVALID;
	
	//長押し判定タイマを停止
	// [_longTouchTimer invalidate];
	[NSObject cancelPreviousPerformRequestsWithTarget:self 
											 selector:@selector(onLongTouchTimer:) object:sender];
}

// 長押し
-(void) onTouchDown:(id)sender
{
	//長押し判定タイマを起動
	// [_longTouchTimer fire];
	
	[self performSelector:@selector(onLongTouchTimer:) 
			   withObject:sender afterDelay:(LONG_TOUCH_TIMER / 1000.0f)];
}

// 長押し判定タイマevent
// -(void) onLongTouchTimer:(NSTimer*)timer
-(void) onLongTouchTimer:(id)sender
{
#ifdef DEBUG
	NSLog (@"fire onLongTouchTimer");
#endif
	@try {

		if ((self.delegate) 
				&& ([self.delegate respondsToSelector:@selector(OnLongTouchDown:)]))
		{
			[self.delegate OnLongTouchDown:self];
		}
	}
	@catch (NSException *exception) 
	{
		NSLog(@"onLongTouchTimer: Caught %@: %@", [exception name], [exception reason]);
	}
}
	  
#pragma mark public_methods

// 初期化処理
- (void) initialize:(id)ownerView
{
	// メンバの初期化
	_xBeforeAxis = _yBeforeAxis = BEFORE_AXIS_INVALID;
	_flickState = FLICK_NONE;
	
	// 要求するフリック種別の初期化
	_requestFlickType = FLICK_NONE;
	
	// オーナーViewの保存
	self.delegate = ownerView;
	
	// [self sizeToFit];
	
	// ダブルタップ
	[self addTarget:self action:@selector(_onDoubleTap:) 
		forControlEvents:UIControlEventTouchDownRepeat];
	
	// フリックのシュミレート
	[self addTarget:self action:@selector(onFlickStart:forEvent:) 
		  forControlEvents:UIControlEventTouchDragInside];	
	[self addTarget:self action:@selector(onFlickEnd:forEvent:) 
		  forControlEvents:UIControlEventTouchUpInside];
	[self addTarget:self action:@selector(onFlickEnd:forEvent:) 
		  forControlEvents:UIControlEventTouchDragExit];
	
	// 長押し
	[self addTarget:self action:@selector(onTouchDown:) 
			forControlEvents:UIControlEventTouchDown];
	
	// 長押し判定タイマの初期化
	/*
	_longTouchTimer = [NSTimer scheduledTimerWithTimeInterval:LONG_TOUCH_TIMER
													   target:self
													 selector:@selector(onLongTouchTimer:)
													 userInfo:nil repeats:NO];
	[_longTouchTimer retain];
	[_longTouchTimer invalidate];
	*/
}

@end
