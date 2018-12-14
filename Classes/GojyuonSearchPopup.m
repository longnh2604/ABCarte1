//
//  GojyuonSearchPopup.m
//  iPadCamera
//
//  Created by MacBook on 10/11/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GojyuonSearchPopup.h"


@implementation GojyuonSearchPopup

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
	
	// 個別文字ボタンの押されている状態の初期化
	for (NSInteger i = 0; i < GOJYUON_ROW_NUM; i++)
	{
		for (NSInteger j = 0; j < GOJYUON_COL_NUM; j++)
		{	btnState[i][j] = nil; }
	}

    NSArray *arr = @[btnSearch, btnCancel,
                     btnAAline, btnKAline, btnSAline, btnTAline, btnNAline,     // あ、か、さ、た、な行
                     btnHAline, btnMAline, btnYAline, btnRAline, btnWAline];    // は、ま、や、ら、わ行
    for (id parts in arr) {
        [parts setBackgroundColor:[UIColor whiteColor]];
        [[parts layer] setCornerRadius:6.0];
        [parts setClipsToBounds:YES];
        [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[parts layer] setBorderWidth:1.0];
    }
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [btnSearch release];
    btnSearch = nil;
    [btnCancel release];
    btnCancel = nil;
    [btnAAline release];
    btnAAline = nil;
    [btnKAline release];
    btnKAline = nil;
    [btnSAline release];
    btnSAline = nil;
    [btnTAline release];
    btnTAline = nil;
    [btnNAline release];
    btnNAline = nil;
    [btnHAline release];
    btnHAline = nil;
    [btnMAline release];
    btnMAline = nil;
    [btnYAline release];
    btnYAline = nil;
    [btnRAline release];
    btnRAline = nil;
    [btnWAline release];
    btnWAline = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [btnSearch release];
    [btnCancel release];
    [btnAAline release];
    [btnKAline release];
    [btnSAline release];
    [btnTAline release];
    [btnNAline release];
    [btnHAline release];
    [btnMAline release];
    [btnYAline release];
    [btnRAline release];
    [btnWAline release];
    [super dealloc];
}

// 個別文字に濁音を付与する
- (NSString*) addDakuonOneString:(NSString*) oneString 
{
	NSString *retString;
	
	// 文字コード取り出し
	unichar unic = [oneString characterAtIndex:0];
	
	// 付与する濁音
	unichar addUnic[2];
	
	// か行〜た行
	if ( (0x304b <= unic) && (unic <= 0x3068) )
	{
		// 「が」など濁点の付与
		addUnic[0] = unic + 1;
		
		retString 
			= [ NSString stringWithFormat:@"%@_%@",
					oneString,
					[NSString stringWithCharacters:addUnic length:1] ];
	}
	// は行
	else if ( (0x306f <= unic) && (unic <= 0x307b) )
	{
		// 「ば」および「ぱ」など濁点と半濁点の付与
		addUnic[0] = unic + 1;
		addUnic[1] = unic + 2;
		retString
			= [ NSString stringWithFormat:@"%@_%@_%@",
					 oneString,
					 [NSString stringWithCharacters:addUnic length:1],
					 [NSString stringWithCharacters:&(addUnic[1]) length:1]];
	}
	else {
		retString = [NSString stringWithString:oneString];
	}
	
	return (retString);
}

// 個別文字ボタンのクリック
- (IBAction) OnOneStringButton:(id)sender
{
	UIButton *button = (UIButton*)sender;
	
	// 押されたボタンの行と列を取得
	NSInteger row = (button.tag & 0x00f0) >> 4;
	NSInteger col = (button.tag & 0x000f);
	row--; col--;	// 配列のindexのため-1する
	
	if ( (row >= GOJYUON_ROW_NUM) || (col >= GOJYUON_COL_NUM) )
	{
#ifdef DEBUG
		NSLog(@"out of range to btnstate => row=%ld / col=%ld", (long)row, (long)col);
#endif
		return;
	}
	
	if (button.tag & BUTTON_STATE_PUSH)
	{
		// 選択ー＞非選択
		button.tag &= ~BUTTON_STATE_PUSH;
		[button setBackgroundImage:
			[UIImage imageNamed:@"button_normal_w32Xh32.png"] 
						  forState:UIControlStateNormal];
		
		btnState[row][col] = nil;
	}
	else
	{
		// 非選択ー＞選択
		button.tag |= BUTTON_STATE_PUSH;
		[button setBackgroundImage:
			[UIImage imageNamed:@"button_push_w32Xh32.png"] 
						  forState:UIControlStateNormal];
		
		// か行〜た行と,は行の場合のみ濁音を付与
		btnState[row][col] 
			= [[self addDakuonOneString : button.currentTitle] mutableCopy];
		NSLog(@" button title = %@  %@", 
			button.currentTitle, btnState[row][col]);
	}
}

// 個別文字ボタンの検索文字列作成
- (void)  searchStringMake4OneString: (NSMutableArray*)searchStrings
{
	// 個別文字ボタンの押されている状態を取得
	for (NSInteger i = 0; i < GOJYUON_ROW_NUM; i++)
	{
		NSMutableString *searchString = nil;
		for (NSInteger j = 0; j < GOJYUON_COL_NUM; j++)
		{	
			if (btnState[i][j])
			{
				// ボタンが押されている
				if (! searchString)
				{	searchString = [NSMutableString string]; }
				
				if ([searchString length] > 0)
				{  [searchString appendString:@"_"]; }
				
				[searchString appendString: btnState[i][j]];
			}
		}
		if (searchString)
		{	[searchStrings replaceObjectAtIndex:i withObject:searchString]; }
	}
}

#pragma mark PopUpViewContollerBase

// 設定ボタンクリック
// あ行などの行ボタンのClickで即実行とするためoverrideする
- (IBAction) OnSetButton:(id)sender
{
	// 検索ボタンも含み、ここで、tagIDを保存する
	clickedID = ((UIButton*)sender).tag;
	
	// baseのOnsetButtonをコールして、基本処理を委譲
	[super OnSetButton:sender];
}

// delegate objectの設定:設定ボタンおよびあ行など行ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	// 先に空の検索文字列を作成しておく
	NSMutableArray	*searchStrings = [NSMutableArray array];
	for (NSInteger i = 0; i < GOJYUON_ROW_NUM; i++) 
	{
		[searchStrings addObject:[NSMutableString string]];
	}
	
	// [searchStrings autorelease];
	
	// 検索文字列を返すものとする
	// [0]:あ行、 [1]:か行、 [2]:さ行、 ..... [9]:わ行 の各行に
	//					ひらがなを設定する。（例：あ行=あ_い_う_え_お）
	//					必ず10個の要素とし、該当行のない箇所は空文字を設定する
	////////////////////////////////////////////////////////////////////
	
	NSMutableString *searchString = (clickedID > 0)?
		[NSMutableString string] : nil;
	
	switch (clickedID) 
	{
		case 1:
			// あ行をクリックした
			[searchString appendString:@"あ_い_う_え_お"];
			break;
		case 2:
			// か行をクリックした
			[searchString appendString:@"か_き_く_け_こ_が_ぎ_ぐ_げ_ご"];
			break;
		case 3:
			// さ行をクリックした
			[searchString appendString:@"さ_し_す_せ_そ_ざ_じ_ず_ぜ_ぞ"];
			break;
		case 4:
			// た行をクリックした
			[searchString appendString:@"た_ち_つ_て_と_だ_ぢ_づ_で_ど"];
			break;
		case 5:
			// な行をクリックした
			[searchString appendString:@"な_に_ぬ_ね_の"];
			break;
		case 6:
			// は行をクリックした
			[searchString appendString:@"は_ひ_ふ_へ_ほ_ば_び_ぶ_べ_ぼ_ぱ_ぴ_ぷ_ぺ_ぽ"];
			break;
		case 7:
			// ま行をクリックした
			[searchString appendString:@"ま_み_む_め_も"];
			break;
		case 8:
			// や行をクリックした
			[searchString appendString:@"や_ゆ_よ"];
			break;
		case 9:
			// ら行をクリックした
			[searchString appendString:@"ら_り_る_れ_ろ"];
			break;
		case 10:
			// わ行をクリックした
			[searchString appendString:@"わ_を_ん"];
			break;

		case 0:
		default:
			// 文字を個別にクリックした
			// 検索文字列作成
			[self searchStringMake4OneString:searchStrings];
			break;
	}
	
	if (clickedID > 0)
	{ [searchStrings replaceObjectAtIndex:(NSUInteger)(clickedID - 1) withObject:searchString]; }
	
	return (searchStrings);
}

@end
