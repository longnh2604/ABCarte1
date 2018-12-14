//
//  userWorkItemEditPopup.m
//  iPadCamera
//
//  Created by MacBook on 11/05/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Common.h"
#import "userWorkItemEditPopup.h"

// TextFiledの横の数
#define TEXT_WIDTH_NUMS	(NSInteger)3
// TextFiledのサイズ
#define TEXT_SIZE_WIDTH		160
#define TEXT_SIZE_HEIGHT	32
// マージン(XとYで共通)
#define MARGIN_X_Y			20

// 設定されていない場合の文字列
#define WORK_ITEM_NO_DIFINE_STR		@"(設定されていません)"

@implementation userWorkItemEditPopup

@synthesize masterTable;
@synthesize lblTitle;

#pragma mark local_Methods

// 名称編集用textFieldの作成:buttonのsubViewとして生成
-(void) makeEditNameTextFiled:(UIButton*)btnSuper
{
	// インスタンス作成
	CGFloat xPos = ((TEXT_SIZE_WIDTH - TEXT_SIZE_WIDTH) / 2);
	UITextField *txtEdit 
		= [[UITextField alloc] initWithFrame:
			CGRectMake(xPos, 0.0f, TEXT_SIZE_WIDTH, TEXT_SIZE_HEIGHT)];
	
	// 各プロパティ設定
	NSString *title = [btnSuper titleForState:UIControlStateNormal];
	txtEdit.text		= (! [title isEqualToString:WORK_ITEM_NO_DIFINE_STR]) ?
							title : @"";
	txtEdit.placeholder     = @"入力してください";
	txtEdit.textAlignment   = NSTextAlignmentCenter;
	txtEdit.borderStyle     = UITextBorderStyleNone;
	txtEdit.adjustsFontSizeToFitWidth = NO;
	txtEdit.clearButtonMode = UITextFieldViewModeNever;
	
	txtEdit.keyboardType	= UIKeyboardTypeDefault;
	txtEdit.returnKeyType	= UIReturnKeyDone;
	
	// Tagはボタンに合わせる
	txtEdit.tag = btnSuper.tag;
	// 初期状態は非表示
	txtEdit.hidden = YES;
	
	// 各イベント登録
	/*self addTarget:self action:@selector(onTextEditBegin:) 
						forControlEvents:UIControlEventEditingDidBegin];*/
	[txtEdit addTarget:self action:@selector(onChangeText:) 
						forControlEvents:UIControlEventEditingChanged];			// 文字列変更
	[txtEdit addTarget:self action:@selector(onDidEndOnExit:) 
						forControlEvents:UIControlEventEditingDidEndOnExit];	// リターンキー
	// 親View(ボタン)に加える
	[btnSuper addSubview:txtEdit];
							
}

-(UITextField*) makeTextField:(NSInteger)index
{
	// indexに該当する施術マスタのID
	NSString *mstIDStr 
		// = (NSString*)[ [self.masterTable allKeys] objectAtIndex:index];
		= [NSString stringWithFormat:@"%ld", (long)(index + 1)];
	
	// 位置を算出
	CGFloat x 
		= (CGFloat)( (index % TEXT_WIDTH_NUMS) * (TEXT_SIZE_WIDTH + MARGIN_X_Y));
	CGFloat y 
		= (CGFloat)( (index / TEXT_WIDTH_NUMS) * (TEXT_SIZE_HEIGHT + MARGIN_X_Y));
	// インスタンス作成
	UITextField *txtEdit 
		= [[UITextField alloc] initWithFrame:
			CGRectMake(x, y, (CGFloat)TEXT_SIZE_WIDTH, (CGFloat)TEXT_SIZE_HEIGHT)];
	
	// text設定
	txtEdit.text = (NSString*)[masterTable objectForKey:mstIDStr];
	/*[btn addTarget:self action:@selector(OnMasterButtonSelect:) 
						forControlEvents:UIControlEventTouchDown];*/
	// tag設定：TableのKey
	txtEdit.tag = [mstIDStr intValue];
	
	// 各プロパティ設定
	txtEdit.background		 = [UIImage imageNamed:@"button_normal_w160Xh32.png"];
	txtEdit.placeholder		 = @"未設定";
	txtEdit.textColor		 = [UIColor whiteColor];			// 文字色：白
	txtEdit.textAlignment	 = NSTextAlignmentCenter;
	txtEdit.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	txtEdit.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	txtEdit.borderStyle		 = UITextBorderStyleNone;
	txtEdit.adjustsFontSizeToFitWidth = NO;
	txtEdit.clearButtonMode	 = UITextFieldViewModeWhileEditing;
	
	txtEdit.keyboardType	 = UIKeyboardTypeDefault;
	txtEdit.returnKeyType	 = UIReturnKeyDone;
	
	// 各イベント登録
	[txtEdit addTarget:self action:@selector(onTextEditBegin:) 
	  forControlEvents:UIControlEventEditingDidBegin];		// 編集開始
	[txtEdit addTarget:self action:@selector(onChangeText:) 
	  forControlEvents:UIControlEventEditingChanged];		// 文字列変更
	[txtEdit addTarget:self action:@selector(onTextDidEnd:) 
	  forControlEvents:UIControlEventEditingDidEnd];		// 編集終了
	[txtEdit addTarget:self action:@selector(onTextDidEndOnExit:) 
	  forControlEvents:UIControlEventEditingDidEndOnExit];	// リターンキー
	
	return(txtEdit);
}

// TextFieldの生成とレイアウトを行う
-(void) make2LayoutTextField
{
	NSInteger tableNum = [self.masterTable count];
	
	// 施術マスタテーブルのサイズにてボタンの縦の数を求める（横は固定で３）
	NSInteger btnHeightNum 
		= (tableNum / TEXT_WIDTH_NUMS) 
			+ ( (tableNum % TEXT_WIDTH_NUMS != 0)? 1: 0);
	btnHeightNum++;		// スクロールさせるため１個多く設定する
	
	// ボタンの数にてコンテナの大きさを設定
	float sW = (float)( (TEXT_SIZE_WIDTH * TEXT_WIDTH_NUMS) 
					   + (MARGIN_X_Y * (TEXT_WIDTH_NUMS - 1) ) );
	float sH = (float)( (TEXT_SIZE_HEIGHT * btnHeightNum )
					   + (MARGIN_X_Y * (btnHeightNum - 1)) );
	[conteinerView setFrame:CGRectMake
		((float)MARGIN_X_Y, (float)MARGIN_X_Y, sW, sH)];
	
	// Scrollの設定
	[scrollView setContentSize: conteinerView.frame.size];
	
	// TextFieldの作成とレイアウト
	for (NSInteger index = 0; index < tableNum; index++)
	{
		
		UITextField *txtEdit = [self makeTextField:index];
		[conteinerView addSubview:txtEdit];
		
		// [txtEdit release];
	}
}

// 編集用マスタテーブルの更新
- (void) updateEditMasterTable:(UITextField*) txtEdit
{
	// Tagを文字列化
	NSString *mstID = [NSString stringWithFormat:@"%ld", (long)txtEdit.tag];
	
	// TagをKeyとして、編集用マスタテーブルに反映
	NSString *mstItem;
	if ( ! (mstItem = (NSString*)([_editMasterTable objectForKey:mstID]) ) )
	{
		// Key(:Tag)が存在しない場合は、作成する
		mstItem = [NSString stringWithString:txtEdit.text];
		[_editMasterTable setObject:mstItem forKey:mstID];
	}
	else 
	{
		// Tableの値を更新
		mstItem = txtEdit.text;
	}
	
	// 親Viewのボタンの文字列も変更する
	/*[ ((UIButton*)[txtEdit superview]) 
	 setTitle:(([mstItem length] > 0)? mstItem : WORK_ITEM_NO_DIFINE_STR)
	 forState:UIControlStateNormal];*/
	
	txtEdit.textColor 
		= [UIColor colorWithRed:0.7f green:0.1f blue:0.0f alpha:1.0f];
	
	// 更新ボタンを有効にする
	if (! btnUpdate.enabled)
	{ btnUpdate.enabled = YES; }	
}

#pragma mark life_cycle

// 初期化
- (id) initWithWorkItemMaster:(NSUInteger)popUpID 
			popOverController:(UIPopoverController*)controller 
					 callBack:(id)callBackDelegate
		  workItemMasterTable:(NSMutableDictionary*)mstTable
{
	if (self = [super initWithPopUpViewContoller:popUpID
							   popOverController:controller
										callBack:callBackDelegate] )
	{	
		self.masterTable = mstTable;
		
		// 編集用マスタテーブルのインスタンス作成
		_editMasterTable = [NSMutableDictionary dictionary];
		[_editMasterTable retain];
		
		self.contentSizeForViewInPopover = CGSizeMake(560.0f, 280.0f);
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
	
	// TextFieldの生成とレイアウトを行う
	[self make2LayoutTextField];
	
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
    
	if (_editMasterTable)
	{
		[_editMasterTable release];
		_editMasterTable = nil;
	}
	
	[super dealloc];
}

#pragma mark control_events

// マスタのボタンのタッチイベント
- (void) OnMasterButtonSelect : (id)sender
{
	// タッチされたボタン
	UIButton *toucedBtn = (UIButton*)sender;
	
	// subViewのTextFieldを取得
	for (UIView* vw in [toucedBtn subviews])
	{
		if ([vw isMemberOfClass:[UITextField class]])
		{
			// 表示する
			((UITextField*)vw).hidden = NO;
			// キーボードを開いてフォーカスを当てる
			[ ((UITextField*)vw) becomeFirstResponder];
		
			break;
		}
	}
}

// 編集開始
- (void) onTextEditBegin:(id)sender
{
	// 選択されたことを示す為に背景を変更
	((UITextField*)sender).background 
		= [UIImage imageNamed:@"button_push_w160Xh32.png"];
}

// 文字列変更 : リターンキーが必ず押されるとは限らないので、ここで文字列を設定する
- (void) onChangeText:(id)sender
{
	// 更新ボタンを有効にする
	/*
	if (! btnUpdate.enabled)
	{ btnUpdate.enabled = YES; }
	*/
	
	// 編集用マスタテーブルの更新
	// [self updateEditMasterTable:(UITextField*)sender];
}

// 編集終了
- (void) onTextDidEnd:(id)sender
{
	// 編集用マスタテーブルの更新
	[self updateEditMasterTable:(UITextField*)sender];
	
	// 編集完了されたことを示す為に背景を元に戻す
	((UITextField*)sender).background 
		= [UIImage imageNamed:@"button_normal_w160Xh32.png"];
}

// リターンキー
- (void) onTextDidEndOnExit:(id)sender
{
	// キーボードを閉じる
	[ ((UITextField*)sender) resignFirstResponder];
	
	// 編集用マスタテーブルの更新
	[self updateEditMasterTable:(UITextField*)sender];
	
	// 編集完了されたことを示す為に背景を元に戻す
	((UITextField*)sender).background 
		= [UIImage imageNamed:@"button_normal_w160Xh32.png"];
}

#pragma mark override

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	// 編集された内容のマスタテーブルを返す
	return (_editMasterTable);
}	

#pragma mark public_methods

@end
