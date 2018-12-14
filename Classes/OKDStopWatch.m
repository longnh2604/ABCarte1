//
//  OKDStopWatch.m
//  iPadCamera
//
//  Created by MacBook on 11/04/15.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Common.h"
#import "OKDStopWatch.h"

@implementation OKDStopWatch

@synthesize isRunning = _isRunning;

#pragma mark private_methods

#pragma mark life_cycle

// 初期化
- (id) initWithInterval:(NSUInteger)interval
{
	if (self = [super init])
	{
		_interval = interval;
		_isRunning = NO;
		_intervalAfterTime = nil;
	}
	
	return (self);
}


#pragma mark public_methods

// ストップウォッチの開始
- (void) startStopWatch
{
	[self startStopWatch:_interval];
}

// ストップウォッチの開始
- (void) startStopWatch:(NSUInteger)interval
{
	// interval後の日時を設定する
	_intervalAfterTime 
		= [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)interval];
	[_intervalAfterTime retain];
	
	_isRunning = YES;
}

// ストップウォッチの完了確認
- (BOOL) isCompliteStopWatch
{
	// ストップウォッチは開始していない
	if (! _isRunning)
	{	return (NO);}
	
	// 現在日時の取得
	NSDate *now = [NSDate date];
	
	// interval経過後の日時と比較
	NSComparisonResult result = [now compare:_intervalAfterTime];
	
	// 現在日時＞interval経過後の日時の場合のみ経過とする
	BOOL complite = (result == NSOrderedDescending);
	
	if (complite)
	{	[self stopStopWatch]; }
	
	return (complite);
}

// ストップウォッチの停止
- (void) stopStopWatch
{
	_isRunning = NO;
	
	if (_intervalAfterTime)	
	{	
		[_intervalAfterTime release];
		_intervalAfterTime = nil;
	}
}

@end

///
/// 長押しイベントサポートクラス
///
@implementation OKDLongTouchSuport

@synthesize delegate;

#pragma mark life_cycle

// 初期化
- (id) initWithEventHandler:(id<LongTotchDelegate>)handler sender:(id)sender
{
	if ( (self = [super initWithInterval:LONG_TOUCH_TIMER2]) )
	{
		self.delegate = handler;
		_eventSender = sender;
	}
	
	return (self);
}

#pragma mark public_methods

// 長押し判定タイマevent
- (void) onLongTouchTimer:(id)sender
{
	if (self.delegate)
	{
		[self.delegate OnLongTotch:_eventSender];
	}
}

// 長押し判定の開始
- (void) beginLongTouchEvent
{
	if(self.isRunning)
	{	return; }		// 二重起動は禁止する
	
	// performSelectorを起動
	[self performSelector:@selector(onLongTouchTimer:) 
			   withObject:self afterDelay:(NSTimeInterval)LONG_TOUCH_TIMER2];
	
	// ストップウォッチの開始
	[self startStopWatch];
}

// 長押し判定の中断
- (void) chancelLongTouchEvent
{
	// 既に終了している
	if ( (! self.isRunning) || [self isCompliteStopWatch] )
	{	return; }
	
	// performSelectorを停止
	[NSObject cancelPreviousPerformRequestsWithTarget:self 
											 selector:@selector(onLongTouchTimer:) object:self];
	
	// ストップウォッチの停止
	[self stopStopWatch];
}

@end

