//
//  UITableViewItemButton.m
//  iPadCamera
//
//  Created by MacBook on 11/03/01.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UITableViewItemButton.h"

@implementation UITableViewItemButton

@synthesize section = _section;
@synthesize rowIndex = _rowIndex;

#pragma mark private_methods


#pragma mark life_cycle

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    [super dealloc];
}

#pragma mark control_events

// Single Touchイベント
-(void) onTouchDown:(id)sender
{
	// baseクラスにて長押し判定タイマを起動
	[super onTouchDown:sender];
	
	if (_ownerTableView)
	{
		// このセルを選択する
		NSIndexPath *indexPath 
		= [NSIndexPath indexPathForRow:self.rowIndex inSection:self.section];
		
		// セル本体をまずは選択
		[_ownerTableView selectRowAtIndexPath:indexPath 
									 animated:NO 
							   scrollPosition:UITableViewScrollPositionNone];
		
		if (_ownerTableView.delegate)
		{
			// 選択イベントを発生
			[_ownerTableView.delegate tableView:_ownerTableView didSelectRowAtIndexPath:indexPath];
		}
	}
}

// ドラッグの開始
-(void)onFlickStart:(id)sender forEvent:(UIEvent*)event
{
	if( (_flickState !=  FLICK_NONE) && (_ownerTableView))
	{
		// フリッカ中はTableViewのScrollはしないようにする
		_ownerTableView.scrollEnabled = NO;
	}
	
	[super onFlickStart:sender forEvent:event];
}

// ドラッグの終了またはTouchUp
-(void)onFlickEnd:(id)sender forEvent:(UIEvent*)event
{
	[super onFlickEnd:sender forEvent:event];
	
	if(_ownerTableView)
	{
		// TableViewのScroll禁止を解除する
		_ownerTableView.scrollEnabled = YES;
	}
}

#pragma mark public_methods

// 初期化処理
- (void) initialize:(id)ownerView tableView:(UITableView*)tableView
{
	[super initialize:ownerView];
	
	// オーナーのTableViewの保存
	_ownerTableView = tableView;
	
}

@end
