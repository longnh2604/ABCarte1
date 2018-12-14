//
//  WorkItemSetPopup.m
//  iPadCamera
//
//  Created by MacBook on 10/12/21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "WorkItemSetPopup.h"

#define BUTTON_STATE_PUSH	(NSInteger)0x8000

// ボタンの横の数
#define BUTTON_WIDTH_NUMS	(NSInteger)3
// ボタンサイズ
#define BUTTON_SIZE_WIDTH	160
#define BUTTON_SIZE_HEIGHT	32
// マージン(XとYで共通)
#define MARGIN_X_Y			20

@implementation WorkItemSetPopup

@synthesize masterTable;
@synthesize popoverController;
@synthesize delegate;


#pragma mark local_Methods

-(UIButton*) makeCustomButton:(NSInteger)index
{
	// indexに該当する施術マスタのID
	NSString *mstIDStr 
		= [NSString stringWithFormat:@"%ld", (long)(index + 1)];
		// = (NSString*)[ [self.masterTable allKeys] objectAtIndex:index];
		// NSString *mstIDStr = [NSString stringWithFormat:@"%d", index];
	
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	
	CGFloat x 
		= (CGFloat)( (index % BUTTON_WIDTH_NUMS) * (BUTTON_SIZE_WIDTH + MARGIN_X_Y));
	CGFloat y 
		= (CGFloat)( (index / BUTTON_WIDTH_NUMS) * (BUTTON_SIZE_HEIGHT + MARGIN_X_Y));
	btn.frame 
		= CGRectMake(x, y, (CGFloat)BUTTON_SIZE_WIDTH, (CGFloat)BUTTON_SIZE_HEIGHT);
	
	[btn setTitle:[masterTable objectForKey:mstIDStr] forState:UIControlStateNormal];
	// [btn setTitle:[NSString stringWithFormat:@"button-%@", mstIDStr] forState:UIControlStateNormal];
	[btn addTarget:self action:@selector(OnImageButtonSelect:) 
					forControlEvents:UIControlEventTouchDown];
	btn.tag = [mstIDStr intValue];
	[btn setBackgroundImage:
		[UIImage imageNamed:@"button_normal_w160Xh32.png"] 
				   forState:UIControlStateNormal];
	return(btn);
}

// ボタンの生成とレイアウトを行う
-(void) make2LayoutButton
{
	NSInteger tableNum = [self.masterTable count];
	
	// 施術マスタテーブルのサイズにてボタンの縦の数を求める（横は固定で３）
	NSInteger btnHeightNum 
		= (tableNum / BUTTON_WIDTH_NUMS) 
			+ ( (tableNum % BUTTON_WIDTH_NUMS != 0)? 1: 0);
	btnHeightNum++;		// スクロールさせるため１個多く設定する
	
	// ボタンの数にてコンテナの大きさを設定
	float sW = (float)( (BUTTON_SIZE_WIDTH * BUTTON_WIDTH_NUMS) 
					   + (MARGIN_X_Y * (BUTTON_WIDTH_NUMS - 1) ) );
	float sH = (float)( (BUTTON_SIZE_HEIGHT * btnHeightNum )
					   + (MARGIN_X_Y * (btnHeightNum - 1)) );
	[conteinerView setFrame:CGRectMake
		((float)MARGIN_X_Y, (float)MARGIN_X_Y, sW, sH)];
	
	// Scrollの設定
	[scrollView setContentSize: conteinerView.frame.size];
	
	// ボタンの作成とレイアウト
	for (NSInteger index = 0; index < tableNum; index++)
	{
		
		UIButton *btn = [self makeCustomButton:index];
		[conteinerView addSubview:btn];
		
		// [btn release];
		
	}
}

// ボタンの選択状態の設定
-(void) setButtonState:(UIButton*)button isSelect:(BOOL)state
{
	if (state)
	{
	// ボタンを非選択状態にする
		button.tag &= ~BUTTON_STATE_PUSH;
		[button setBackgroundImage:
			[UIImage imageNamed:@"button_normal_w160Xh32.png"] 
						  forState:UIControlStateNormal];
	}
	else
	{
	// ボタンを選択状態にする
		button.tag |= BUTTON_STATE_PUSH;
		[button setBackgroundImage:
			[UIImage imageNamed:@"button_push_w160Xh32.png"] 
						  forState:UIControlStateNormal];
	}
}

#pragma mark public_Methods

// 選択状態の設定
-(void) setSelectedState:(NSMutableArray*)workItemNumberList
{
	for (id itemID in workItemNumberList)
	{
		NSInteger iID = [((NSString*)itemID) intValue];
	
		for (id btn in conteinerView.subviews)
		{
			// ボタンのtagを取り出す
			int tg = ((UIButton*)btn).tag & ~BUTTON_STATE_PUSH;
			
			// 現在設定中の施術内容か？
			if (tg == iID)
			{
				// ボタンの選択状態の設定
				[self setButtonState:(UIButton*)btn isSelect:NO];
				
				break;
			}
		}
	}
}

// ポップアップタイトルの設定
-(void) setPopupTitleWithUserName:(NSString*)userName
{
	lblTitle.text 
		= [NSString stringWithFormat:@"%@様の施術内容を設定します",userName];
}

#pragma mark iOS_Frmaework

// 初期化
-(id) initWithMasterTable:(NSMutableDictionary*)mstTable 
		popOverController:(UIPopoverController*)controller 
				 callBack:(id)callBackDelegate
{
	if (self = [super init])
	{
		self.masterTable = mstTable;
		popoverController = controller;
		self.delegate = callBackDelegate;
	}
	
	return (self);
}


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// ボタンの生成とレイアウトを行う
	[self make2LayoutButton];
	
	// titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark Button_Click_Event

// ボタンのクリック
- (void) OnImageButtonSelect:(id)sender
{
	UIButton *button = (UIButton*)sender;
	
	BOOL select = ((button.tag & BUTTON_STATE_PUSH) != 0);
	
	// ボタンの選択状態の設定
	[self setButtonState:button isSelect:select];
	
	// コンテナクラスへイベント通知
	if (self.delegate != nil) 
	{
		// ボタンのtagを取り出す
		int workItemID = button.tag & ~BUTTON_STATE_PUSH;
		
		// クライアントクラスへcallback
		[self.delegate OnWorkItemSet:workItemID isSelect:! select];
	}	
	
}

// 全てを解除
-(IBAction) onAllReset:(id)sender
{
	// 先にボタン全てを非選択にする
	for (id btn in conteinerView.subviews)
	{
		// 選択中のみ非選択にする
		if ( (((UIButton*)btn).tag & BUTTON_STATE_PUSH) != 0)
		{	[self setButtonState:(UIButton*)btn isSelect:YES]; }
	}
	
	// コンテナクラスへイベント通知
	if (self.delegate != nil) 
	{
		// クライアントクラスへcallback
		[self.delegate OnAllWorkItemReset];
	}	
}

// 閉じるボタン
-(IBAction) onClose:(id)sender
{
	if (popoverController)
	{
		[popoverController dismissPopoverAnimated:YES];
	}
}

@end
