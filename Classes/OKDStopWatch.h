//
//  OKDStopWatch.h
//  iPadCamera
//
//  Created by MacBook on 11/04/15.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

///
/// ストップウォッチクラス
///
@interface OKDStopWatch : NSObject 
{
	NSUInteger			_interval;				// ストップウォッチ時限
	NSDate				*_intervalAfterTime;	// 時限後の時刻
  
	BOOL				_isRunning;				// ストップウォッチは開始しているか？
}

@property (nonatomic) BOOL isRunning;

// 初期化
- (id) initWithInterval:(NSUInteger)interval;

// ストップウォッチの開始
- (void) startStopWatch;

// ストップウォッチの開始
- (void) startStopWatch:(NSUInteger)interval;

// ストップウォッチの完了確認
- (BOOL) isCompliteStopWatch;

// ストップウォッチの停止
- (void) stopStopWatch;

@end

@protocol LongTotchDelegate;

#define		LONG_TOUCH_TIMER2				2			// 長押しの判定時間 [sec]

///
/// 長押しイベントサポートクラス
///
@interface OKDLongTouchSuport : OKDStopWatch
{
	BOOL			_isLongTouchRunning;				// 長押しイベントの実行中フラグ
	id				_eventSender;						// イベントの発行者
}

// 初期化
- (id) initWithEventHandler:(id<LongTotchDelegate>)handler sender:(id)sender;

// 長押し判定の開始
- (void) beginLongTouchEvent;

// 長押し判定の中断
- (void) chancelLongTouchEvent;

@property(nonatomic,assign)    id <LongTotchDelegate> delegate;

@end

