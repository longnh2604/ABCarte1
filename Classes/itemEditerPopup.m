//
//  itemEditerPopup.m
//  iPadCamera
//
//  Created by MacBook on 11/06/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Common.h"
#import "itemEditerPopup.h"

#import "itemTableManager.h"
#import "itemTableField.h"

#ifdef CALULU_IPHONE
#import "MainViewController.h"
#endif

#ifdef CALULU_IPHONE
//---------------------------------------

// Itemの横の数
#define ITEM_WIDTH_NUMS	(NSInteger)3
// TextFiledのサイズ
#define ITEM_SIZE_WIDTH		100
#define ITEM_SIZE_HEIGHT	24
// マージン(XとYで共通)
#define MARGIN_X_Y			5

//---------------------------------------
#else
//---------------------------------------
// Itemの横の数
#define ITEM_WIDTH_NUMS	(NSInteger)3
// TextFiledのサイズ
#define ITEM_SIZE_WIDTH		160
#define ITEM_SIZE_HEIGHT	32
// マージン(XとYで共通)
#define MARGIN_X_Y			20

//---------------------------------------
#endif

// 設定されていない場合の文字列
#define WORK_ITEM_NO_DIFINE_STR		@"(設定されていません)"

#define BUTTON_STATE_PUSH	(NSInteger)0x8000

// editモードのinsert時のtag値
#define EDIT_INSERT_TAG_VALUE		-1

enum E_ALERT_TAG{
    E_ALERT_TAG_ALL_DELETE = 0x0010,
};

@interface itemEditerPopup()
	// 項目ボタンの選択
	- (void) OnItemButtonSelect:(id)sender;

    - (void) chancel;
@end

///
/// 項目編集ポップアップViewControllerクラス
///
@implementation itemEditerPopup

@synthesize lblTitle;
@synthesize delegate;
@synthesize popoverController;

#pragma mark local_Methods

// alertの表示
- (void)alertViewSwow:(NSString*)message
{
	UIAlertView *alertView 
	= [[UIAlertView alloc] initWithTitle:@"ご確認願います"
								 message:message
								delegate:nil
					   cancelButtonTitle:@"OK"
					   otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

// 項目位置の算出
- (CGRect) calcItemLocation:(NSInteger)index
{
	CGFloat x 
		= (CGFloat)( (index % ITEM_WIDTH_NUMS) * (ITEM_SIZE_WIDTH + MARGIN_X_Y));
	CGFloat y 
		= (CGFloat)( (index / ITEM_WIDTH_NUMS) * (ITEM_SIZE_HEIGHT + MARGIN_X_Y));
	
	CGRect rect =
		CGRectMake(x, y, (CGFloat)ITEM_SIZE_WIDTH, (CGFloat)ITEM_SIZE_HEIGHT);
	
	return (rect);
}
// ダミーテキストFieldの作成（レイアウトは編集または追加時に行う)
-(UITextField*) makeDummyTextField
{
	// インスタンス作成:(レイアウトを後で行うので、位置は仮算出)
	UITextField *txtEdit 
		= [[UITextField alloc] initWithFrame:[self calcItemLocation:0]];
	
	// text設定：空文字
	txtEdit.text = @"";
		
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
	
	txtEdit.hidden			 = YES;		// 初期状態は非表示
    
#ifdef CALULU_IPHONE
    [txtEdit setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0f]];
#endif
	
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

// itemのレイアウト
- (void) layoutItem:(NSUInteger)tableNum
{
		
	// 施術マスタテーブルのサイズにてボタンの縦の数を求める（横は固定で３）
	NSInteger btnHeightNum 
		= (tableNum / ITEM_WIDTH_NUMS) 
			+ ( (tableNum % ITEM_WIDTH_NUMS != 0)? 1: 0);
	btnHeightNum++;		// スクロールさせるため１個多く設定する
	
	// ボタンの数にてコンテナの大きさを設定
	float sW = (float)( (ITEM_SIZE_WIDTH * ITEM_WIDTH_NUMS) 
					   + (MARGIN_X_Y * (ITEM_WIDTH_NUMS - 1) ) );
	float sH = (float)( (ITEM_SIZE_HEIGHT * btnHeightNum )
					   + (MARGIN_X_Y * (btnHeightNum - 1)) );
	[conteinerView setFrame:CGRectMake
	 ((float)MARGIN_X_Y, (float)MARGIN_X_Y, sW, sH)];
	
	// Scrollの設定
	[scrollView setContentSize: conteinerView.frame.size];
	
}

// ボタンの作成とレイアウト
-(UIButton*) makeCustomButton:(NSInteger)index itemField:(itemTableField*)field
{
	// ボタンの生成	
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	
	// 項目位置の算出
	btn.frame = [self calcItemLocation:index];
	
	[btn setTitle:field.name forState:UIControlStateNormal];
	[btn addTarget:self action:@selector(OnItemButtonSelect:) 
				forControlEvents:UIControlEventTouchDown];
	btn.tag = field.index;		// indexではdelete時に食い違いが起きる
	[btn setBackgroundImage:
		[UIImage imageNamed:@"button_normal_w160Xh32.png"] 
				   forState:UIControlStateNormal];
#ifdef CALULU_IPHONE
    [[btn titleLabel] setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0f]];
#endif
    
	return(btn);
}

// Itemの生成とレイアウトを行う
-(void) make2LayoutItem
{
	// 項目テーブル管理より有効な項目のリスト（一覧リスト）の取得
	NSArray *list = [_itemTableManager getValidList];
	// 一覧リストより項目の個数を取得
	NSUInteger tableNum = [list count];

	// itemのレイアウト
	[self layoutItem:tableNum];
	
	// ボタンの作成とレイアウト
	for (NSInteger index = 0; index < tableNum; index++)
	{	
		UIButton *btn 
			= [self makeCustomButton:index itemField:(itemTableField*)[list objectAtIndex:index]];
		[conteinerView addSubview:btn];
		
		// [btn release];
	}
	
	// list = nil;
	
	// ダミーテキストFieldの作成（レイアウトは編集または追加時に行う)
	_dummyTextField = [self makeDummyTextField];
	[conteinerView addSubview:_dummyTextField];	
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

// 指定indexよりボタンを検索
- (UIButton*) searchButtonWithIndex:(NSInteger)index
{
	UIButton* findBtn = nil;
	
	for (id btn in conteinerView.subviews)
	{
		// ボタンクラスのみ適用
		if (! [btn isKindOfClass:[UIButton class]])
		{	continue; }
		
		// ボタンのtagを取り出す
		int tg = ((UIButton*)btn).tag & ~BUTTON_STATE_PUSH;
		
		// indexが一致したか？
		if (tg == index)
		{
			findBtn = btn;			
			break;
		}
	}
	
	return (findBtn);
}

// itemボタンの設定種別
typedef enum
{
	ITEM_BUTTON_SET_SELECTED		= 0x0001,		// 選択状態による
	ITEM_BUTTON_SET_EDIT_SELECTED	= 0x0010,		// 編集用選択状態による
	ITEM_BUTTON_SET_CLEAR			= 0x0100,		// 状態によらずクリア
} ITEM_BUTTON_SET_KIND;

// 選択状態の設定
-(void) setSelectedStatesWithSetKind:(ITEM_BUTTON_SET_KIND)kind
{
	// 項目テーブル管理より選択されている項目のindexのリストを取得
	// NSArray *selecteds = [_itemTableManager getSelectedIndexList];
	
	for (itemTableField *field in _itemTableManager.itemTable)
	{
		// 削除しているfieldは除外
		if (field.isDeleted)
		{	continue; }
		
		UIButton *btn = [self searchButtonWithIndex:field.index];
		
		if (!btn)
		{	continue; }
		
		BOOL select = YES;
		switch (kind) {
			case ITEM_BUTTON_SET_SELECTED:
				select = (! field.isSelected);
				break;
			case ITEM_BUTTON_SET_EDIT_SELECTED:
				select = (! field.isEditSelected);
				break;
			case ITEM_BUTTON_SET_CLEAR:
			default:
				select = YES;
				break;
		}
		
		// ボタンの選択状態の設定
		[self setButtonState:btn isSelect:select];
		
	}
}

// 選択状態の設定
-(void) setSelectedStates
{	[self setSelectedStatesWithSetKind:ITEM_BUTTON_SET_SELECTED]; }

// ボタンレイアウトの変更
-(void) layoutButtonChange:(BOOL)isAnimate
{
	BOOL hdSel, hdEdit;
	
	switch (_nowMode) {
		case ITEM_EDITER_SELECT:
			hdSel = NO;
			hdEdit = YES;
			break;
		case ITEM_EDITER_EDIT:
			hdSel = YES;
			hdEdit = NO;
			break;
		default:
			hdSel = NO;
			hdEdit = YES;
			break;
	}
	
	if (isAnimate)
	{
		// アニメーションの開始
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:2.5];
	}
	
	btnClose.hidden = btnAllReset.hidden = hdSel;
	btnUpdateData.hidden = btnChancel.hidden = hdEdit;
	btnInsert.hidden = btnDelete.hidden = btnItemEdit.hidden = hdEdit;
    [self btnTitleClear];
	
	if (isAnimate)
	{
		// アニメーションの完了と実行
		[UIView commitAnimations];
	}
}

// ScrollViewのスクロール
- (void) scrollWithYpos:(CGFloat)yPos
{
	CGRect frame = scrollView.frame;
	
	frame.origin.x = 0.0f;
    frame.origin.y = yPos;
	
    // scrollViewを移動して表示する 
	[scrollView scrollRectToVisible:frame animated:YES];
	
}

// 編集または追加済みの文字色
- (UIColor*) editedOrInsertedTextColor
{
	return ([UIColor colorWithRed:0.7f green:0.1f blue:0.0f alpha:1.0f]);
}

// 削除・項目編集のボタンと挿入ボタンの有効／無効設定
- (void) delEditInsertButtonControl:(BOOL)isDelEditEnable
{
	btnDelete.enabled = btnItemEdit.enabled = isDelEditEnable;
	btnInsert.enabled = ! isDelEditEnable;
    [self btnTitleClear];
}

// ダミーTextFiledの表示／非表示
- (void) dummyTextFieldHide:(BOOL)isHide
{
	_dummyTextField.hidden = isHide;
	btnModeChange.enabled  = isHide;		// モード切り替えボタンも反映
}

// 編集モード時の名前の編集
- (BOOL) editName4EditMode:(BOOL)isEnterTouch
{
	// 編集完了されたことを示す為に背景を元に戻す
	/*_dummyTextField.background 
	 = [UIImage imageNamed:@"button_normal_w160Xh32.png"];*/
	
	// ダミーTextFieldを非表示にする
	[self dummyTextFieldHide:YES];
	
	
	// 追加または編集か？
	BOOL isInsert 
		= (_dummyTextField.tag == EDIT_INSERT_TAG_VALUE);
	
	// 空文字は無効とする:キャンセル扱い
	if ([_dummyTextField.text length] <= 0)
	{
		if (isEnterTouch)
		{
			[self alertViewSwow:
				[NSString stringWithFormat:@"%@する内容は\n必ず入力してください",
					(isInsert)? @"追加" : @"編集"]];
		}
		if (! isInsert)
		{
			// ボタンの選択を解除
			UIButton *btn = [self searchButtonWithIndex:_editSelectedIndex];
			if (btn)
			{	[self OnItemButtonSelect:btn];}
		}
		
		return (YES);
	}
	
	// 同じ名前がないかを確認
	NSInteger sameIndex;
	if ((sameIndex = [_itemTableManager isExistName:_dummyTextField.text 
								 index:_dummyTextField.tag]) != INDEX_INVALID)
	{
		if ( sameIndex == _dummyTextField.tag)
		{
			// 自身と同じならばキャンセル扱い
			if (! isInsert)
			{
				// ボタンの選択を解除
				UIButton *btn = [self searchButtonWithIndex:sameIndex];
				if (btn)
				{	[self OnItemButtonSelect:btn];}
			}
			
			return (YES);
		}
		else 
		{
			if (isEnterTouch)
			{
				[self alertViewSwow:
				 [NSString stringWithFormat:@"%@した[%@]は\nすでに登録されています",
				  (isInsert)? @"追加" : @"編集",  _dummyTextField.text]];
			}
			
			return (NO);
		}
	}
	
	BOOL isUpdate = YES;
	BOOL isNotify = NO;
	
	if (isInsert)
	{
	// itemのinsert
		// 項目テーブル管理クラスに項目追加を通知
		itemTableField *field = [_itemTableManager insertItemWithName:_dummyTextField.text];
		
		// 有効な項目のリスト（一覧リスト）よりボタンの挿入位置を算出
		NSArray *list = [_itemTableManager getValidList];
		NSUInteger validCnt = [list count];
		// list = nil;
		
		// itemのレイアウト
		[self layoutItem:validCnt];
		
		// ボタンを追加
		UIButton *btn 
			= [self makeCustomButton:(validCnt - 1) itemField:field];
		[conteinerView addSubview:btn];
		
		// 追加されたことを示すためボタンの文字色を変更
		[btn setTitleColor:[self editedOrInsertedTextColor] 
				  forState:UIControlStateNormal];
	}
	else 
	{
	// itemの名前編集
		UIButton *btn = [self searchButtonWithIndex:_editSelectedIndex];
		
		if (! btn)
		{	return (NO); }
		
		// ボタン文字の変更
		[btn setTitle:_dummyTextField.text forState:UIControlStateNormal];
		
		// ボタンの選択を解除
		[self setButtonState:btn isSelect:YES];
		
		// 編集されたことを示すためボタンの文字色を変更
		[btn setTitleColor:[self editedOrInsertedTextColor] 
				  forState:UIControlStateNormal];
		
		// 項目テーブル管理クラスに項目編集を通知
		itemTableField* field = [_itemTableManager editItemWithIndex:btn.tag  
											   editName:_dummyTextField.text];
		if (! field)
		{ return (NO); }
		
		// ユーザ固有領域では更新しない
		// isUpdate = ! [field isUserArea];
		
		// コンテナクラスに通知するか
		// isNotify = ((!isUpdate) && field.isSelected);
	}
	
	// 削除・項目編集のボタンを無効にする:(挿入ボタンは有効)
	[self delEditInsertButtonControl:NO];
		
	_editSelectedIndex = EDIT_SELECTED_INDEX_INVALID;
	
	if (isUpdate)
	{
		// 更新と取消ボタンを有効にする
		btnUpdateData.enabled = btnChancel.enabled = YES;
        [self btnTitleClear];

		// モード切り替えボタンを無効にする
		btnModeChange.enabled = NO;
	}
	else if ((isNotify) && (self.delegate != nil) )
	{
		// ユーザ固有領域の場合はコンテナクラスへcallback
		[self.delegate OnItemSetWithSelecteds:_itemTableManager.orderNumTable 
								 itemEditKind:_itemEditKind];
		
	}
				
	return (YES);
}

-(void) showDateAddDaysPopup:(UIView*)view
{
    if (_popCtlDatePicker)
    {
        // Popupoverが表示されていたら閉じる
        if ( [_popCtlDatePicker isPopoverVisible] )
        {
            [_popCtlDatePicker dismissPopoverAnimated:YES];
        }
        [_popCtlDatePicker release];
        _popCtlDatePicker = nil;
    }
    
    //日付の設定ポップアップViewControllerのインスタンス生成
    DateAddDaysPopup *vcDatePicker
    = [[DateAddDaysPopup alloc]initWithDateAddDaysPopUpViewContoller:0x7100
                                                            callBack:self];
    
#ifndef CALULU_IPHONE    
    // ポップアップViewの表示
    _popCtlDatePicker = [[UIPopoverController alloc] initWithContentViewController:vcDatePicker];
    _popCtlDatePicker.delegate = vcDatePicker;
    vcDatePicker.popoverController = _popCtlDatePicker;
    
    [_popCtlDatePicker presentPopoverFromRect:view.bounds
                                       inView:view
                     permittedArrowDirections:UIPopoverArrowDirectionDown
                                     animated:YES];
    [_popCtlDatePicker setPopoverContentSize:CGSizeMake(332.0f, 364.0f)];
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:vcDatePicker];
#endif
    [vcDatePicker release];
}

#pragma mark life_cycle

// 初期化
- (id) initWithHistID:(HISTID_INT)histID
		 itemEditKind:(ITEM_EDIT_KIND)editKind
		itemListString:(NSString*)strings
	popOverController:(UIPopoverController*)controller 
			 callBack:(id)callBackDelegate
{
#ifndef CALULU_IPHONE
	if ((self = [super initWithNibName:@"itemEditerPopup" bundle:nil])) 
#else
   	if ((self = [super initWithNibName:@"ip_itemEditerPopup" bundle:nil])) 
#endif
	{
		// 項目テーブル管理のインスタンス作成
		_itemTableManager = [[itemTableManager alloc] initTableWithHistID:histID 
														   itemListString:strings
															 itemEditKind:editKind];
		
		// 項目編集種別とdelegateとpopOverControllerを保存
		_itemEditKind = editKind;
		delegate = callBackDelegate;
		popoverController = controller;
		
		// 現在モードを選択モードに設定
		_nowMode = ITEM_EDITER_SELECT;
		
		self.contentSizeForViewInPopover = CGSizeMake(560.0f, 280.0f);
	}
	
	return (self);
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Itemの生成とレイアウトを行う
	[self make2LayoutItem];
	
	// 選択状態の設定
	[self setSelectedStates];
	
	// titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
    
    // iOS8の場合、イメージを貼付けたボタンのタイトルが見えてしまうので削除する
    [self btnTitleClear];
}

// iOS8の場合、イメージを貼付けたボタンのタイトルが見えてしまうので削除する
- (void) btnTitleClear
{
    [btnAllReset setTitle:@"" forState:btnAllReset.state];
    [btnClose setTitle:@"" forState:btnClose.state];
    [btnUpdateData setTitle:@"" forState:btnUpdateData.state];
    [btnChancel setTitle:@"" forState:btnChancel.state];
    [btnInsert setTitle:@"" forState:btnInsert.state];
    [btnDelete setTitle:@"" forState:btnDelete.state];
    [btnItemEdit setTitle:@"" forState:btnItemEdit.state];
    [btnModeChange setTitle:@"" forState:btnModeChange.state];
}

- (void)viewDidAppear:(BOOL)animated
{
	
	// 遅延させる
	[self performSelector:@selector(onInitRunDelayDone:) 
			   withObject:self afterDelay:0.1f];		// 0.05秒後に起動
}

- (void) onInitRunDelayDone:(id)sender
{	
    /*
	// scrollViewを最下部に
	CGFloat bottom = scrollView.contentSize.height - scrollView.frame.size.height;
	[self scrollWithYpos:bottom];*/
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (_dummyTextField)
	{
		// キーボードを閉じる
		[ _dummyTextField resignFirstResponder];
	}

	// NSLog (@"itemEditerPopup viewWillDisappear");
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)dealloc {
    
	if (_itemTableManager)
	{
		[_itemTableManager release];
		_itemTableManager = nil;
	}
	
	[super dealloc];
}

#pragma mark control_events_item_select

// 項目ボタンの選択
- (void) OnItemButtonSelect:(id)sender
{
	// 編集中（追加または項目編集）は、項目ボタンを機能させない
	if (_dummyTextField.hidden == NO)
	{	return; }
	
	UIButton *button = (UIButton*)sender;
	
    switch (_itemEditKind) {
        case ITEM_EDIT_USER_WORK1:;
        case ITEM_EDIT_USER_WORK2:;
        case ITEM_EDIT_PICTUE_NAME:;
            [self memoOnItemButtonSelect:button];
            break;
        
        case ITEM_EDIT_DATE:;
        case ITEM_EDIT_GENERAL1:;
        case ITEM_EDIT_GENERAL2:;
        case ITEM_EDIT_GENERAL3:;
            [self templateOnItemButtonSelect:button];
            break;
            
        default:
            break;
    }
    return;
 }

/**
 メモ設定時の処理
 */
- (void) memoOnItemButtonSelect:(UIButton*)button
{
    // touch前の選択状態
	BOOL select = ((button.tag & BUTTON_STATE_PUSH) != 0);
	
	// ボタンの選択状態の設定
	[self setButtonState:button isSelect:select];
	
	// 選択状態をここで反転
	select = ! select;
	
	// ボタンのtag=indexを取り出す
	int index = button.tag & ~BUTTON_STATE_PUSH;
	
	// 現在モードが選択モードの場合
	if (_nowMode == ITEM_EDITER_SELECT)
	{
		// 項目テーブルに選択を通知(選択状態を切り替え)
		NSArray *selectedList
        = [ _itemTableManager swicthSelectedState:index];
		
		// コンテナクラスへイベント通知
		if (self.delegate != nil)
		{
			// クライアントクラスへcallback
			[self.delegate OnItemSetWithSelecteds:selectedList
									 itemEditKind:_itemEditKind];
		}
		
		// selectedList = nil;
	}
	// 現在モードが編集モードの場合
	else if (_nowMode == ITEM_EDITER_EDIT)
	{
		// 項目テーブルに編集用選択を通知
		NSInteger beforeIndex = [ _itemTableManager setEditSelectedState:index];
		
		// 編集モードの場合は、常に一つだけ選択
		UIButton *btn = [self searchButtonWithIndex:beforeIndex];
		if (btn)
		{
			[self setButtonState:btn isSelect:YES];	// 選択を解除
		}
		
		// 削除・項目編集のボタンを有効／無効にする
		// BOOL isEnable = (beforeIndex >= 0)? YES : NO;
		[self delEditInsertButtonControl:select];

		// 編集用選択のindexの設定
		_editSelectedIndex = (select)? index : EDIT_SELECTED_INDEX_INVALID;
		// NSLog (@"_editSelectedIndex: %04d", _editSelectedIndex);
	}
}

/**
 テンプレート作成時の処理
 */
- (void) templateOnItemButtonSelect:(UIButton*)button
{
	NSInteger index = button.tag;
	
	// 現在モードが選択モードの場合
	if (_nowMode == ITEM_EDITER_SELECT)
	{
		// 項目テーブルに選択を通知(選択状態を切り替え)
		NSMutableArray *selectedList = [NSMutableArray array];
        [selectedList addObject:[_itemTableManager getItemNameIndex:index]];
		
		// コンテナクラスへイベント通知
		if (self.delegate != nil)
		{
			// クライアントクラスへcallback
			[self.delegate OnItemSetWithSelecteds:selectedList
									 itemEditKind:_itemEditKind];
		}
		
		// selectedList = nil;
	}
	// 現在モードが編集モードの場合
	else if (_nowMode == ITEM_EDITER_EDIT)
	{
        if (![_itemTableManager enabledEdit:(index & ~BUTTON_STATE_PUSH)])
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"このボタンは編集編集できません"
                                                                message:@""
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            [alertView release];
            return;
        }
        
        // touch前の選択状態
        BOOL select = ((button.tag & BUTTON_STATE_PUSH) != 0);
        
        // ボタンの選択状態の設定
        [self setButtonState:button isSelect:select];
        
        // 選択状態をここで反転
        select = ! select;	// ボタンのtag=indexを取り出す
        
		// 項目テーブルに編集用選択を通知
		NSInteger beforeIndex = [_itemTableManager setEditSelectedState:index];
		
		// 編集モードの場合は、常に一つだけ選択
		UIButton *btn = [self searchButtonWithIndex:beforeIndex];
		if (btn)
		{
			[self setButtonState:btn isSelect:YES];	// 選択を解除
		}
		
		// 削除・項目編集のボタンを有効／無効にする
		// BOOL isEnable = (beforeIndex >= 0)? YES : NO;
		[self delEditInsertButtonControl:select];
        
		// 編集用選択のindexの設定
		_editSelectedIndex = index;
	}
}

#pragma mark control_events_text_filed

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
	
}

// 編集終了
- (void) onTextDidEnd:(id)sender
{
	/*
	NSLog (@"view size %f : %f", self.view.bounds.size.width, self.view.bounds.size.height);
	NSLog (@"is view load %d", self.view.isHidden);
	*/
	// 編集モード時の名前の編集
    
    [self editName4EditMode:YES];
}

// リターンキー
- (void) onTextDidEndOnExit:(id)sender
{	
	// 編集モード時の名前の編集
	// if ([self editName4EditMode:YES])
	{
		// キーボードを閉じる
		[ ((UITextField*)sender) resignFirstResponder];
	}
	/*
	else {
		// ダミーTextFiledを表示する
		[self dummyTextFieldHide : NO];
	}
	*/
}

#pragma mark control_events_select_mode

// 全てを解除
-(IBAction) onAllReset:(id)sender
{
    switch (_itemEditKind) {
        case ITEM_EDIT_USER_WORK1:;
        case ITEM_EDIT_USER_WORK2:;
        case ITEM_EDIT_PICTUE_NAME:;
            // 項目テーブルに選択状態を全解除を通知
            [_itemTableManager allResetSelectedState];
            
            // コンテナクラスへイベント通知
            if (self.delegate != nil)
            {
                // クライアントクラスへcallback
                [self.delegate OnAllItemReset:_itemEditKind];
            }
            
            // ボタンの選択状態を設定:クリアする
            [self setSelectedStatesWithSetKind:ITEM_BUTTON_SET_CLEAR];
            break;
            
        case ITEM_EDIT_DATE:;
            [self showAlertView:@"デフォルトボタン（一年後・当日）を除くボタンを全て削除します"];
            break;
        case ITEM_EDIT_GENERAL1:;
        case ITEM_EDIT_GENERAL2:;
        case ITEM_EDIT_GENERAL3:;
			[self showAlertView:@"ボタンを全て削除します"];
            break;
            
        default:
            break;
    }
}

// アラートビューの設定
-(void)showAlertView:(NSString*)message{
    UIAlertView* alert = nil;
    alert = [[UIAlertView alloc] initWithTitle:@"全て削除"
                                       message:message
                                      delegate:self
                             cancelButtonTitle:@"削除"
                             otherButtonTitles:@"取消", nil ];
    alert.tag = E_ALERT_TAG_ALL_DELETE;
    [alert show];
}

// 閉じるボタン
-(IBAction) onClose:(id)sender
{
#ifndef CALULU_IPHONE
	if (popoverController)
	{
		[popoverController dismissPopoverAnimated:YES];
        // ポップアップ画面を閉じる時の後処理関数を呼ぶ
        if ([self.delegate respondsToSelector:@selector(afterPopupClose)]) {
            [self.delegate afterPopupClose];
        }
	}
#else
    // 下表示modalDialogを閉じる
    [MainViewController closeBottomModalDialog];
#endif
}

#pragma mark control_events_edit_mode

// ダミーtextFieldの表示
- (void) dispDummyTextFieldWithIndex:(UIButton*)baseBtn dispName:(NSString*)name
{
	// ダミーテキストFieldの位置設定
	if (! baseBtn)
	{
		NSArray *list = [_itemTableManager getValidList];
		NSUInteger tableNum = [list count];
		
		// itemのレイアウト
		[self layoutItem:tableNum + 1];
		
		_dummyTextField.frame = [self calcItemLocation:tableNum];
		// list = nil;
		
	}
	else 
	{
		_dummyTextField.frame 
			=  CGRectMake(baseBtn.frame.origin.x, baseBtn.frame.origin.y, 
							baseBtn.frame.size.width, baseBtn.frame.size.height);
	}
	// ダミーテキストFieldの表示
	[self dummyTextFieldHide : NO];
	
	// insertまたはeditであることをTagに設定
	_dummyTextField.tag = (baseBtn)? (baseBtn.tag) &~ BUTTON_STATE_PUSH : EDIT_INSERT_TAG_VALUE;
	
	// Textを設定
	_dummyTextField.text = name;
    
    if( _itemEditKind == ITEM_EDIT_DATE )
    {
        [self onTextEditBegin:_dummyTextField];
        [self showDateAddDaysPopup:_dummyTextField];
    }
    else
    {
        // ダミーテキストFieldにフォーカスする（キーボード表示）
        [_dummyTextField becomeFirstResponder];
        [conteinerView bringSubviewToFront:_dummyTextField];
	}
    
	// scrollViewを最下部に
	[self scrollWithYpos:scrollView.contentSize.height];
}

// コンテナViewのRefresh
- (void) refreshContierView
{
	// continerViewから一旦すべてのコントロールを削除
	NSArray *subViews = conteinerView.subviews;
	for (UIView *ctrl in subViews)
	{
		[ctrl removeFromSuperview];
	}
	// subViews = nil; 
	
	// Itemの生成とレイアウトを行う
	[self make2LayoutItem];
	
	// 選択状態の設定
	[self setSelectedStates];
	
}

// 更新ボタン
-(IBAction) onUpdateData:(id)sender
{
	// キーボードを閉じる
	[ _dummyTextField resignFirstResponder];
	
	// 更新と取消のボタンを無効にする
	btnUpdateData.enabled = btnChancel.enabled = NO;
    [self btnTitleClear];
	// モード切り替えボタンを有効にする
	btnModeChange.enabled = YES;
	 
	// 項目テーブル管理クラスに更新を通知
	BOOL isClientNotify = [_itemTableManager updateAllItem];
	
	// コンテナViewのRefresh
	[self refreshContierView];
	
	if ( (isClientNotify) && (self.delegate != nil) )
	{
		// クライアントクラスへcallback
		[self.delegate OnItemSetWithSelecteds:_itemTableManager.orderNumTable 
								 itemEditKind:_itemEditKind];		
	}
	
	// 編集用選択状態にボタンを設定
	[self setSelectedStatesWithSetKind:ITEM_BUTTON_SET_EDIT_SELECTED];

}

// 取消ボタン
-(IBAction) onChancel:(id)sender
{
	// キーボードを閉じる
	[ _dummyTextField resignFirstResponder];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"キャンセル"
                                                    message:@"編集内容を取り消しますか？"
                                                   delegate:self
                                          cancelButtonTitle:@"はい"
                                          otherButtonTitles:@"いいえ" ,nil ];
    [alert show];
}

-(void) chancel
{
	// 更新と取消のボタンを無効にする
	btnUpdateData.enabled = btnChancel.enabled = NO;
    [self btnTitleClear];
	// モード切り替えボタンを有効にする
	btnModeChange.enabled = YES;
	
	// 項目テーブル管理クラスに取消を通知
	[_itemTableManager chancelAllItem];
	
	// コンテナViewのRefresh
	[self refreshContierView];
	
	// 編集用選択状態にボタンを設定
	[self setSelectedStatesWithSetKind:ITEM_BUTTON_SET_EDIT_SELECTED];
}

// 追加ボタン
-(IBAction) onInsert:(id)sender
{
	// 最下部にダミーテキストFieldの表示
	[self dispDummyTextFieldWithIndex:nil dispName:@""];
}

// 削除ボタン
-(IBAction) onDelete:(id)sender
{
	// 削除・項目編集のボタンを無効にする
	[self delEditInsertButtonControl:NO];
	
	if (_editSelectedIndex == EDIT_SELECTED_INDEX_INVALID)
	{	return; }		// 念のため
	
	// 更新・取消のボタンを有効にする
	btnUpdateData.enabled = btnChancel.enabled = YES;
    [self btnTitleClear];
	// モード切り替えボタンを無効にする
	btnModeChange.enabled = NO;
	
	// 項目テーブル管理クラスに削除を通知
	[_itemTableManager deleteItemWithIndex:_editSelectedIndex];
	
	// コンテナViewのRefresh
	[self refreshContierView];
	
	// 編集用選択状態にボタンを設定
	[self setSelectedStatesWithSetKind:ITEM_BUTTON_SET_EDIT_SELECTED];
	
	_editSelectedIndex = EDIT_SELECTED_INDEX_INVALID;
}

// 項目編集
-(IBAction) onItemEdit:(id)sender
{
	if (_editSelectedIndex == EDIT_SELECTED_INDEX_INVALID)
	{	return; }		// 念のため
	
    UIButton *btn =  [self searchButtonWithIndex:_editSelectedIndex];
    
    // 該当indexにダミーテキストFieldの表示
    [self dispDummyTextFieldWithIndex:btn
                             dispName:[btn titleForState:UIControlStateNormal] ];
    
    btnDelete.enabled = NO;
}

#pragma mark control_events_mode_change
// モード切り替え
-(IBAction) onModeChange:(id)sender
{
	NSString *imgName;
	
	// 現在モードの設定
	switch (_nowMode) {
		case ITEM_EDITER_SELECT:
			_nowMode = ITEM_EDITER_EDIT;
			imgName = @"wkItem_mode_change_on.png";
			break;
		case ITEM_EDITER_EDIT:
			_nowMode = ITEM_EDITER_SELECT;
			imgName = @"wkItem_mode_change_off.png";
			break;
		default:
			_nowMode = ITEM_EDITER_EDIT;
			imgName = @"wkItem_mode_change_on.png";
			break;
	}
	
	// モード切り替えボタンのimage変更
	[btnModeChange setImage:[UIImage imageNamed:imgName]
				   forState: UIControlStateNormal];
	
	// ボタンレイアウトの変更
	[self layoutButtonChange:YES];
	
	// itemボタンの選択設定
	if (_nowMode == ITEM_EDITER_SELECT)
	{
		// 選択モードは選択中に応じて設定
		[self setSelectedStates];
	}
	else 
	{
		// 編集モードは編集中のみ設定
		[self setSelectedStatesWithSetKind:ITEM_BUTTON_SET_EDIT_SELECTED];
	}

}

#pragma mark public_methods

// ポップアップタイトルの設定
-(void) setPopupTitleWithUserName:(NSString*)userName memoTitle:(NSString*)memoTitle
{
	lblTitle.text 
		= [NSString stringWithFormat:@"%@様の%@を設定します",userName, memoTitle];
}

-(void) setPopupTitle:(NSString*)title
{
	lblTitle.text = title;
}

#pragma mark alert_delegate
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // cancel
    if ( buttonIndex != 0 )
        return;
    
    if( alertView.tag == E_ALERT_TAG_ALL_DELETE )
    {
        // 項目テーブル管理クラスに削除を通知
        [_itemTableManager deleteAllItem];
        
        // 項目テーブル管理クラスに更新を通知
        BOOL isClientNotify = [_itemTableManager updateAllItem];
        
        if ( (isClientNotify) && (self.delegate != nil) )
        {
            // クライアントクラスへcallback
            [self.delegate OnItemSetWithSelecteds:_itemTableManager.orderNumTable
                                     itemEditKind:_itemEditKind];		
        }
        
        // コンテナViewのRefresh
        [self refreshContierView];
        
        // 削除完了メッセージ
        NSString *btnName;
        switch (_itemEditKind) {
            case ITEM_EDIT_DATE:
                btnName = @"デフォルトボタン（一年後・当日）を除く日付フィールド";
                break;
            case ITEM_EDIT_GENERAL1:
                btnName = @"汎用１";
                break;
            case ITEM_EDIT_GENERAL2:
                btnName = @"汎用２";
                break;
            case ITEM_EDIT_GENERAL3:
                btnName = @"汎用３";
                break;
                
            default:
                break;
        }
        [Common showDialogWithTitle:@"汎用ボタンの削除" message:[NSString stringWithFormat:@"%@の全てのボタンが消去されました", btnName]];
    }
    
}

/*
 アラートが消えた後に呼び出される
 */
-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger) buttonIndex
{
    switch (alertView.tag) {
        case E_ALERT_TAG_ALL_DELETE:
            break;
            
        default:
            if( alertView.numberOfButtons == 2 && buttonIndex == 0 ){
                [self chancel];
            }
            break;
    }
    [alertView release];
}

#pragma mark DateAddDays_delegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    NSNumber *addDays = (NSNumber*)object;
    _dummyTextField.text = [NSString stringWithFormat:@"%d日後", [addDays intValue]];
    
    // 編集モード時の名前の編集
	if (! [self editName4EditMode:YES])
	{
		// ダミーTextFiledを表示する
		// [self dummyTextFieldHide : NO];
		
		// ダミーテキストFieldにフォーカスする（キーボード表示）
		[_dummyTextField becomeFirstResponder];
	}
}

-(void) onDateAddDaysChansel
{
    // ダミーTextFieldを非表示にする
	[self dummyTextFieldHide:YES];
	
	// 追加または編集か？
	BOOL isInsert = (_dummyTextField.tag == EDIT_INSERT_TAG_VALUE);
    if (! isInsert)
    {
        // ボタンの選択を解除
        UIButton *btn = [self searchButtonWithIndex:_editSelectedIndex];
        if (btn)
        {	[self OnItemButtonSelect:btn];}
    }
    return;
}

@end
