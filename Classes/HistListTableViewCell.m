//
//  HistListTableViewCell.m
//  iPadCamera
//
//  Created by MacBook on 10/12/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "HistListTableViewCell.h"

#import "UITableViewItemButton.h"

#import "OKDStopWatch.h"

@implementation HistListTableViewCell

@synthesize picture;
@synthesize workDate, workItem, workItem2, memo;
@synthesize cellRow;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}

// UITableViewCellの横幅を調整する
- (void)setFrame:(CGRect)frame
{
    frame.origin.x += self.inset;
    frame.size.width -= 2 * self.inset;
    [super setFrame:frame];
}

- (void)dealloc {
    [super dealloc];
}

// 施術内容とメモのタイトル設定
- (void) setworkItemMemoTitle
{
	NSDictionary *lables = [Common getMemoLabelsFromDefault];
	
	workItemTitle.text  = [lables objectForKey:@"memo1Label"];
	workItemTitle2.text  = [lables objectForKey:@"memo2Label"];
	memoTitle.text  = [lables objectForKey:@"memoFreeLabel"];
}

#pragma mark public_methods

// 初期化処理
- (void) initialize:(id)ownerView tableView:(UITableView*)tableView
{
	// TableViewItemButtonの初期化
	[btnFlicker initialize:ownerView tableView:tableView];
//    [btnCameraView initialize:ownerView];
	
	// 長押しイベントサポートクラスの初期化
	_longTouchSuport 
		= [[OKDLongTouchSuport alloc]initWithEventHandler:ownerView sender:self];
	
	// 施術内容とメモのタイトル設定
	[self setworkItemMemoTitle];
}

// sectionとindexの設定
- (void) setSectionIndex:(NSUInteger)section index:(NSUInteger)idx
{
	// TableViewItemButtonにsectionとindexを設定する
	btnFlicker.section = section;
	btnFlicker.rowIndex = idx;
	
	self.cellRow = idx;
}

#pragma mark touches_events

// タッチ開始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
	
	[super touchesBegan:touches withEvent:event];
	
	// 長押し判定の開始
	[_longTouchSuport beginLongTouchEvent];
}

// タッチ終了
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
	NSLog(@"UserTableView touchesEnded");
#endif
	
	[super touchesEnded:touches withEvent:event];
	
	// 長押し判定の中断
	[_longTouchSuport chancelLongTouchEvent];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
	NSLog(@"UserTableView touchesCancelled");
#endif
	
	[super touchesCancelled:touches withEvent:event];
	
	// 長押し判定の中断
	[_longTouchSuport chancelLongTouchEvent];
}

@end
