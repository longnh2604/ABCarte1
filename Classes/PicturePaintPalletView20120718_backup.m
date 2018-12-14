//
//  PicturePaintPalletView.m
//  iPadCamera
//
//  Created by MacBook on 11/03/04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "PicturePaintPalletView.h"

#import "PicturePaintPalletPopupView.h"

@interface PicturePaintPalletView(private_method) 
#ifdef VARIABLE_PICTURE_PAINT_PALLET
// パレットの表示／非表示
- (void) onBtnPalleteShowHide:(id)sender;
#endif

#ifdef PICTURE_PAINT_PALLET_POPUP
// 描画色系のボタンイベント
- (void) onBtnColor:(id)sender;
// 描画線幅系のボタンイベント
- (void) onBtnWidth:(id)sender;
#endif

@end


@implementation PicturePaintPalletView

@synthesize delegate;

#pragma mark private_methods

// ボタン類の生成
- (void) makeButtons
{
#ifndef CALULU_IPHONE    
    btnSapareteView = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSapareteView setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSapareteView.tag = PALLET_SEPARATE_VIEW;
	[btnSapareteView addTarget:self action:@selector(onBtnSepareteView:) 
			  forControlEvents:UIControlEventTouchUpInside];
#endif
	btnSapareteDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnSapareteDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSapareteDraw.tag = PALLET_SEPARATE_DRAW;
	[btnSapareteDraw addTarget:self action:@selector(onBtnSeparete:) 
			  forControlEvents:UIControlEventTouchUpInside];

	btnSaparete = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnSaparete setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSaparete.tag = PALLET_SEPARATE;
	btnSaparete.hidden = YES;
	[btnSaparete addTarget:self action:@selector(onBtnSeparete:) 
			  forControlEvents:UIControlEventTouchUpInside];

	btnSapareteDelete = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnSapareteDelete setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSapareteDelete.tag = PALLET_SEPARATE_DELETE;
	[btnSapareteDelete addTarget:self action:@selector(onBtnSeparete:) 
		  forControlEvents:UIControlEventTouchUpInside];
	
	btnLineDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnLineDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnLineDraw.tag = PALLET_LINE;
	[btnLineDraw addTarget:self action:@selector(onBtnDraw:) 
				forControlEvents:UIControlEventTouchUpInside];
	
	btnSplineDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnSplineDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSplineDraw.tag = PALLET_SPLINE;
	[btnSplineDraw addTarget:self action:@selector(onBtnDraw:) 
		  forControlEvents:UIControlEventTouchUpInside];
	
	btnEraseDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnEraseDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnEraseDraw.tag = PALLET_ERASE;
#ifndef CALULU_IPHONE 
	[btnEraseDraw addTarget:self action:@selector(onBtnColor:) 
#else
     [btnEraseDraw addTarget:self action:@selector(onBtnDraw:) 
#endif
			forControlEvents:UIControlEventTouchUpInside];
#ifndef CALULU_IPHONE 
    btnDrawString = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawString setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnDrawString.tag = (PALLET_STRING_VIEW);
	[btnDrawString addTarget:self action:@selector(onBtnStringView:) 
         forControlEvents:UIControlEventTouchUpInside];
    
    btnInChara = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnInChara setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnInChara.tag = (PALLET_CHARA);
	[btnInChara addTarget:self action:@selector(onBtnDraw:) 
         forControlEvents:UIControlEventTouchUpInside];
    
    btnMoveString = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnMoveString setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnMoveString.tag = (PALLET_CHARA_MOVE);
	[btnMoveString addTarget:self action:@selector(onBtnDraw:) 
         forControlEvents:UIControlEventTouchUpInside];
#endif
	
	btnDrawColorRed = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawColorRed setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawColorRed.tag = (PALLET_DRAW_COLOR + 1);
#ifdef PICTURE_PAINT_PALLET_POPUP
	[btnDrawColorRed addTarget:self action:@selector(onBtnColor4Popup:) 
              forControlEvents:UIControlEventTouchUpInside];
#else
   	[btnDrawColorRed addTarget:self action:@selector(onBtnColor:) 
              forControlEvents:UIControlEventTouchUpInside];
#endif
	
	btnDrawColorGreen = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawColorGreen setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawColorGreen.tag = (PALLET_DRAW_COLOR + 2);
#ifdef PICTURE_PAINT_PALLET_POPUP
     [btnDrawColorGreen addTarget:self action:@selector(onBtnColor4Popup:)
                 forControlEvents:UIControlEventTouchUpInside];
#else
     [btnDrawColorGreen addTarget:self action:@selector(onBtnColor:)
                 forControlEvents:UIControlEventTouchUpInside];
#endif
	
	btnDrawColorBlue = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawColorBlue setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawColorBlue.tag = (PALLET_DRAW_COLOR + 3);
#ifdef PICTURE_PAINT_PALLET_POPUP
     [btnDrawColorBlue addTarget:self action:@selector(onBtnColor4Popup:) 
                forControlEvents:UIControlEventTouchUpInside];
#else
     [btnDrawColorBlue addTarget:self action:@selector(onBtnColor:) 
                forControlEvents:UIControlEventTouchUpInside];
#endif
	
	btnDrawWidthLight = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawWidthLight setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawWidthLight.tag = (PALLET_DRAW_WIDTH + 1);
#ifdef PICTURE_PAINT_PALLET_POPUP
    [btnDrawWidthLight addTarget:self action:@selector(onBtnLineWidth4Popup:) 
                forControlEvents:UIControlEventTouchUpInside];
#else
    [btnDrawWidthLight addTarget:self action:@selector(onBtnWidth:) 
                forControlEvents:UIControlEventTouchUpInside];  
#endif
	
	btnDrawWidthMiddle = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawWidthMiddle setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawWidthMiddle.tag = (PALLET_DRAW_WIDTH + 2);
#ifdef PICTURE_PAINT_PALLET_POPUP
    [btnDrawWidthMiddle addTarget:self action:@selector(onBtnLineWidth4Popup:) 
                 forControlEvents:UIControlEventTouchUpInside];
#else
    [btnDrawWidthMiddle addTarget:self action:@selector(onBtnWidth:) 
                 forControlEvents:UIControlEventTouchUpInside];
#endif
	
	btnDrawWidthHeavy = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawWidthHeavy setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawWidthHeavy.tag = (PALLET_DRAW_WIDTH + 3);
#ifdef PICTURE_PAINT_PALLET_POPUP
    [btnDrawWidthHeavy addTarget:self action:@selector(onBtnLineWidth4Popup:) 
                forControlEvents:UIControlEventTouchUpInside];
#else
    [btnDrawWidthHeavy addTarget:self action:@selector(onBtnWidth:) 
                forControlEvents:UIControlEventTouchUpInside];
#endif
#ifndef CALULU_IPHONE
    btnUndoView = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnUndoView setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnUndoView.tag = (PALLET_UNDOBOX);
	[btnUndoView addTarget:self action:@selector(onBtnUndoView:) 
      forControlEvents:UIControlEventTouchUpInside];
#endif
	btnUndo = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnUndo setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnUndo.tag = (MODE_UNDO);
	[btnUndo addTarget:self action:@selector(onBtnUndo:) 
				forControlEvents:UIControlEventTouchUpInside];

#ifndef CALULU_IPHONE
    btnRedo = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnRedo setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnRedo.tag = (MODE_REDO);
	[btnRedo addTarget:self action:@selector(onBtnUndo:) 
      forControlEvents:UIControlEventTouchUpInside];
    
    btnAllDelete = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnAllDelete setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnAllDelete.tag = (MODE_ALLDELETE);
	[btnAllDelete addTarget:self action:@selector(onBtnUndo:) 
      forControlEvents:UIControlEventTouchUpInside];
#endif

#ifndef CALULU_IPHONE    
    [self addSubview:btnSapareteView];
    [sapaView.view addSubview:btnSapareteDraw];
	[sapaView.view addSubview:btnSaparete];
    [sapaView.view addSubview:btnSapareteDelete];
    [self addSubview:btnLineDraw];
    [self addSubview:btnSplineDraw];
    [lineView.view addSubview:btnEraseDraw];
    [self addSubview:btnDrawString];
    [drawStringView.view addSubview:btnInChara];
    [drawStringView.view addSubview:btnMoveString];
    [lineView.view addSubview:btnDrawColorRed];
    [lineView.view addSubview:btnDrawColorGreen];
    [lineView.view addSubview:btnDrawColorBlue];
	[lineView.view addSubview:btnDrawWidthLight];
    [lineView.view addSubview:btnDrawWidthMiddle];
    [lineView.view addSubview:btnDrawWidthHeavy];
    [self addSubview:btnUndoView];
	[undoView.view addSubview:btnUndo];
    [undoView.view addSubview:btnRedo];
    [undoView.view addSubview:btnAllDelete];

#else
    [self addSubview:btnSapareteDraw];
	[self addSubview:btnSaparete];
    [self addSubview:btnSapareteDelete];
    [self addSubview:btnLineDraw];
    [self addSubview:btnSplineDraw];
    [self addSubview:btnEraseDraw];
    [self addSubview:btnDrawColorRed];
    [self addSubview:btnDrawColorGreen];
    [self addSubview:btnDrawColorBlue];
	[self addSubview:btnDrawWidthLight];
    [self addSubview:btnDrawWidthMiddle];
    [self addSubview:btnDrawWidthHeavy];
	[self addSubview:btnUndo];
#endif
							   
}

// ボタンのimageのnib名のリスト作成
- (void) makeListBtnNibName
{
	_listBtnNibName = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"separate_write", [NSNumber numberWithInt:PALLET_SEPARATE_DRAW],
					   @"separate", [NSNumber numberWithInt:PALLET_SEPARATE],
					   @"separate_delete", [NSNumber numberWithInt:PALLET_SEPARATE_DELETE],
					   @"line_write", [NSNumber numberWithInt:PALLET_LINE],
					   @"spline_write", [NSNumber numberWithInt:PALLET_SPLINE],
					   @"eraser", [NSNumber numberWithInt:PALLET_ERASE],
					   @"color_red", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 1)],
					   @"color_Yellow", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 2)],
					   @"color_blue", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 3)],
					   @"width_light", [NSNumber numberWithInt:(PALLET_DRAW_WIDTH + 1)],
					   @"width_middle", [NSNumber numberWithInt:(PALLET_DRAW_WIDTH + 2)],
					   @"width_heavy", [NSNumber numberWithInt:(PALLET_DRAW_WIDTH + 3)],
					   @"undo", [NSNumber numberWithInt:PALLET_UNDO],
                       @"undo", [NSNumber numberWithInt:PALLET_UNDOBOX],
                       @"redo", [NSNumber numberWithInt:PALLET_REDO],
                       @"kari_button_allDelete", [NSNumber numberWithInt:PALLET_ALLDELETE],

                       @"kari_button_stringdraw", [NSNumber numberWithInt:PALLET_CHARA],
                       @"kari_button_inString", [NSNumber numberWithInt:PALLET_STRING_VIEW],
                       @"kari_button_stringmove", [NSNumber numberWithInt:PALLET_CHARA_MOVE],
                       
                       @"separate", [NSNumber numberWithInt:PALLET_SEPARATE_VIEW],

					   nil];
	[_listBtnNibName retain];
}

- (NSString*) getButtonStateSufix:(PALLET_BUTTON_STATE)state
{
	NSString *stateStr = nil;
	
	switch (state) {
		case STATE_DISABLE:
			stateStr = @"disable";
			break;
		case STATE_NORMAL:
			stateStr = @"normal";
			break;
		case STATE_SELECT:
			stateStr = @"select";
			break;
		default:
			stateStr = @"";
			break;
	}
	
	return (stateStr);
}

// ボタン状態の設定
- (void) setButtonState:(UIButton*)button forState:(PALLET_BUTTON_STATE)state
{
	NSString *nibName = [NSString stringWithFormat:@"%@_%@",
						 [_listBtnNibName objectForKey:[NSNumber numberWithInt:button.tag]],
						 [self getButtonStateSufix:state]];
	
	[button setImage:[UIImage imageNamed:nibName] forState:UIControlStateNormal];
	// [button setImage:[UIImage imageNamed:nibName] forState:UIControlStateHighlighted];
	
	[button setEnabled:(state != STATE_DISABLE)];

}
// ボタン状態の一括設定
- (void) setAllButtonState:(PICTURE_PAINT_DRAW_MODE)mode
{
	PALLET_BUTTON_STATE state1, state2;
	switch (mode) {
		case MODE_LOCK :
			state1 = state2 = STATE_DISABLE;
			break;
		default:
			state1 = STATE_NORMAL;
			state2 = STATE_DISABLE;
			break;
	}
	
	[self setButtonState:btnSapareteDraw	forState:state1];
	[self setButtonState:btnSaparete		forState:state1];
	[self setButtonState:btnSapareteDelete	forState:(btnSapareteDraw.hidden)? state1 : state2];
	[self setButtonState:btnLineDraw		forState:state1];
	[self setButtonState:btnSplineDraw		forState:state1];
	[self setButtonState:btnEraseDraw		forState:state1];
	[self setButtonState:btnDrawColorRed	forState:state2];
	[self setButtonState:btnDrawColorGreen	forState:state2];
	[self setButtonState:btnDrawColorBlue	forState:state2];
	[self setButtonState:btnDrawWidthLight	forState:state2];
	[self setButtonState:btnDrawWidthMiddle forState:state2];
	[self setButtonState:btnDrawWidthHeavy	forState:state2];
	[self setButtonState:btnUndo			forState:state1];
#ifndef CALULU_IPHONE
    [self setButtonState:btnUndoView		forState:state1];
	[self setButtonState:btnRedo			forState:state1];
    [self setButtonState:btnSapareteView	forState:state1];
	[self setButtonState:btnAllDelete		forState:state1];
    [self setButtonState:btnDrawString      forState:state1];
    [self setButtonState:btnInChara         forState:state1];
    [self setButtonState:btnMoveString      forState:state1];
#endif
}

#ifdef VARIABLE_PICTURE_PAINT_PALLET

// Lock状態によりパレットの表示／非表示をコントロール
- (void) _setPalletShowHide:(BOOL)isLock
{
    //  Lock：パレット表示  UnLock：パレット非表示
    
    // ボタンのタグの表示状態を設定
    btnPalleteShowHide.tag &= ~(VARIABLE_PALLET_DISP_SHOW | VARIABLE_PALLET_DISP_HIDE);
    btnPalleteShowHide.tag |= (isLock)? VARIABLE_PALLET_DISP_HIDE : VARIABLE_PALLET_DISP_SHOW;
    
    // パレットの表示／非表示
    [self onBtnPalleteShowHide:btnPalleteShowHide];
    
    btnPalleteShowHide.hidden = ! isLock;
}

#endif

#pragma mark life_cycle
- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}

// 初期化
- (id) initWithEventListner :(id<PicturePaintPalletDelegate>)listner
{
	// 縦画面で原点位置で仮作成：setPositionWithRotateメソッドで確定
	self = [super initWithFrame:CGRectMake
				(0.0f, 0.0f, PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
	if (self)
	{
		self.delegate = listner;
#ifndef CALULU_IPHONE
        
        //2012 7/10 伊藤 パレットの階層化　ポップアップの作成、
        // ポップアップViewの作成
        lineView 
        = [[palletViewPopup alloc] initPalletPopuWithPopupID:POPUP_SAPARETE_VIEW size:CGSizeMake(164, 192) callBack:self];
        
        sapaView 
        = [[palletViewPopup alloc] initPalletPopuWithPopupID:POPUP_UNDO_ACTION size:CGSizeMake(132,72) callBack:self];
        
        undoView 
        = [[palletViewPopup alloc] initPalletPopuWithPopupID:POPUP_DRAW_LINE size:CGSizeMake(204, 72) callBack:self];
        
        drawStringView 
        = [[palletViewPopup alloc] initPalletPopuWithPopupID:POPUP_DRAW_STRING size:CGSizeMake(132, 72) callBack:self];
        arrowLocate = UIPopoverArrowDirectionDown;
#endif        
		
		// ボタン類の生成
		[self makeButtons];
		
		// ボタンのimageのnib名のリスト作成
		[self makeListBtnNibName];
		
		// ボタン状態の一括設定
		[self setAllButtonState:MODE_LOCK];
		
		// 角を丸める
		CALayer *layer = [self layer];
		[layer setMasksToBounds:YES];
		[layer setCornerRadius:12.0f];
		
		self.alpha = 0.45f;
		
		// 選択中の描画色と太さをそれぞれ１に初期化
		_selectColorNo = 1;
		_selectWidthNo = 1;
        
#ifdef PICTURE_PAINT_PALLET_POPUP
        // 描画色と太さで初期設定されている以外のボタンを非表示
        btnDrawColorGreen.hidden = YES;
        btnDrawColorBlue.hidden = YES;
        btnDrawWidthMiddle.hidden = YES;
        btnDrawWidthHeavy.hidden = YES;
#endif
    }
	
	return (self);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    
	[_listBtnNibName release];
#ifndef CALULU_IPHONE
    if (popupLineDraw) {
        [popupLineDraw release];
    }
    [lineView release];
    if(popupSapareteView){
        [popupSapareteView release];
    }
    [sapaView release];
    if (popupUndo) {
        [popupUndo release];
    }
    [undoView release];
    if (popupDrawString) {
        [popupDrawString release];
    }
    [drawStringView release];
#endif
	
	[super dealloc];
}

#pragma mark control_events
//区分ツールポップアップ
#ifndef CALULU_IPHONE
-(void) onBtnSepareteView:(id)sender
{
	UIButton* btn = (UIButton*)sender;
	if(btn.tag == PALLET_SEPARATE_VIEW){
        if (popupSapareteView) {
            [popupSapareteView release];
            popupSapareteView = nil;
        }
        popupSapareteView = 
        [[UIPopoverController alloc] initWithContentViewController:sapaView];
        sapaView.popoverController = popupSapareteView;
        [popupSapareteView presentPopoverFromRect:btn.bounds
                                           inView:btn
                        permittedArrowDirections:arrowLocate
                                         animated:YES];
    }
}

-(void) onBtnStringView:(id)sender
{
	UIButton* btn = (UIButton*)sender;
	if(btn.tag == PALLET_STRING_VIEW){
        if (popupDrawString) {
            [popupDrawString release];
            popupDrawString = nil;
        }
        popupDrawString = 
        [[UIPopoverController alloc] initWithContentViewController:drawStringView];
        drawStringView.popoverController = popupDrawString;
        [popupDrawString presentPopoverFromRect:btn.bounds
                                           inView:btn
                         permittedArrowDirections:arrowLocate
                                         animated:YES];
    }
}
#endif

// 区分線系のボタンイベント
- (void) onBtnSeparete:(id)sender
{
	UIButton* btn = (UIButton*)sender;
	
	// 描画関連ボタンを通常状態にする
	[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
	[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
	[self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
#ifndef CALULU_IPHONE
    [self setButtonState:btnInChara         forState:STATE_NORMAL];
#endif
	
	// 色と線幅・元に戻すを操作不可にする
	[self setButtonState:btnDrawColorRed	forState:STATE_DISABLE];
	[self setButtonState:btnDrawColorGreen	forState:STATE_DISABLE];
	[self setButtonState:btnDrawColorBlue	forState:STATE_DISABLE];
	[self setButtonState:btnDrawWidthLight	forState:STATE_DISABLE];
	[self setButtonState:btnDrawWidthMiddle forState:STATE_DISABLE];
	[self setButtonState:btnDrawWidthHeavy	forState:STATE_DISABLE];
	[self setButtonState:btnUndo			forState:STATE_DISABLE];
#ifndef CALULU_IPHONE
    [self setButtonState:btnRedo			forState:STATE_DISABLE];
#endif
	
	if (btn.tag == PALLET_SEPARATE_DELETE)
	{
		// 描画線削除は区分線描画：選択状態、区分線：非表示 区分線削除(自身)：操作不可にする
		[self setButtonState:btnSapareteDraw	forState:STATE_SELECT];
		[self setButtonState:btnSaparete		forState:STATE_DISABLE];
		[self setButtonState:btn				forState:STATE_DISABLE];
		
		btnSapareteDraw.hidden = NO;
		btnSaparete.hidden = YES;

	}
	else {
		// 自身を選択状態にする
		[self setButtonState:btn forState:STATE_SELECT];
	}

	// リスナークラスに通知
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{	[self.delegate OnDrawModeChange:self changedCommand:btn.tag args:nil]; } 
}

// 描画系のボタンイベント
- (void) onBtnDraw:(id)sender
{
	// 区分線系を通常状態にする
	if (! btnSapareteDraw.hidden)
	{	[self setButtonState:btnSapareteDraw forState:STATE_NORMAL]; }
	else 
	{	[self setButtonState:btnSaparete forState:STATE_NORMAL]; }

	UIButton* btn = (UIButton*)sender;
	
	// 描画系で自身のみを選択状態にする
	[self setButtonState:btn forState:STATE_SELECT];
	switch (btn.tag) {
		case PALLET_LINE:
			// [self setButtonState:btnLineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
#ifndef CALULU_IPHONE
            [self setButtonState:btnInChara         forState:STATE_NORMAL];
            [self setButtonState:btnMoveString      forState:STATE_NORMAL];
#else
			[self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
#endif
			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;
		case PALLET_SPLINE:
			[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
			// [self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
#ifndef CALULU_IPHONE
            [self setButtonState:btnInChara         forState:STATE_NORMAL];
            [self setButtonState:btnMoveString      forState:STATE_NORMAL];
#else
			[self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
#endif
			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;
		case PALLET_ERASE:
			[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
            //[self setButtonState:btnInChara         forState:STATE_NORMAL];
            //[self setButtonState:btnMoveString      forState:STATE_NORMAL];
			// [self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;
        case PALLET_CHARA:
			[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
#ifndef CALULU_IPHONE
            //[self setButtonState:btnInChara         forState:STATE_NORMAL];
            [self setButtonState:btnMoveString      forState:STATE_NORMAL];
#else
            [self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
#endif
			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;
        case PALLET_CHARA_MOVE:
			[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
            //            [self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
#ifndef CALULU_IPHONE
            [self setButtonState:btnInChara         forState:STATE_NORMAL];
            //[self setButtonState:btnMoveString      forState:STATE_NORMAL];
#else
            [self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
#endif
			break;
		default:
			break;
	}
#ifndef CALULU_IPHONE
    if (btn.tag == PALLET_LINE || btn.tag == PALLET_SPLINE) {
        if (popupLineDraw) {
            [popupLineDraw release];
            popupLineDraw = nil;
        }
        popupLineDraw = 
        [[UIPopoverController alloc] initWithContentViewController:lineView];
        lineView.popoverController = popupLineDraw;
        [popupLineDraw presentPopoverFromRect:btn.bounds
                                       inView:btn
                     permittedArrowDirections:arrowLocate
                                     animated:YES];
    }
#endif
	
	// 描画色：選択中のみ選択状態　以外は通常状態にする (但しERASEは除く)
    if (btn.tag != PALLET_ERASE)
    {
        [self setButtonState:btnDrawColorRed	
                    forState:(_selectColorNo == 1)? STATE_SELECT : STATE_NORMAL];
        [self setButtonState:btnDrawColorGreen
                    forState:(_selectColorNo == 2)? STATE_SELECT : STATE_NORMAL];
        [self setButtonState:btnDrawColorBlue
                    forState:(_selectColorNo == 3)? STATE_SELECT : STATE_NORMAL];
        [self setButtonState:btnEraseDraw
                    forState:(_selectColorNo == ERASE_COLOR_NO)? STATE_SELECT : STATE_NORMAL];
    }
    else
    {
        [self setButtonState:btnDrawColorRed    forState:STATE_DISABLE];
        [self setButtonState:btnDrawColorGreen  forState:STATE_DISABLE];
        [self setButtonState:btnDrawColorBlue   forState:STATE_DISABLE];
    }
        
	// 描画幅：選択中のみ選択状態　以外は通常状態にする
	[self setButtonState:btnDrawWidthLight
				forState:(_selectWidthNo == 1)? STATE_SELECT : STATE_NORMAL];
	[self setButtonState:btnDrawWidthMiddle
				forState:(_selectWidthNo == 2)? STATE_SELECT : STATE_NORMAL];
	[self setButtonState:btnDrawWidthHeavy
				forState:(_selectWidthNo == 3)? STATE_SELECT : STATE_NORMAL];
	
	// リスナークラスに通知
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{	[self.delegate OnDrawModeChange:self changedCommand:btn.tag args:nil]; } 
	
}

// 描画色系のボタンイベント
- (void) onBtnColor:(id)sender
{
	UIButton* btn = (UIButton*)sender;
	if (btn.tag != PALLET_ERASE) {
        // 描画色の選択番号の設定
        _selectColorNo = btn.tag - PALLET_DRAW_COLOR;
        
        // 描画色系で自身のみを選択状態にする
        switch (_selectColorNo) {
            case 1:
                [self setButtonState:btnDrawColorRed	forState:STATE_SELECT];
                [self setButtonState:btnDrawColorGreen	forState:STATE_NORMAL];
                [self setButtonState:btnDrawColorBlue	forState:STATE_NORMAL];
                [self setButtonState:btnEraseDraw       forState:STATE_NORMAL];
                break;
            case 2:
                [self setButtonState:btnDrawColorRed	forState:STATE_NORMAL];
                [self setButtonState:btnDrawColorGreen	forState:STATE_SELECT];
                [self setButtonState:btnDrawColorBlue	forState:STATE_NORMAL];
                [self setButtonState:btnEraseDraw       forState:STATE_NORMAL];
                break;
            case 3:
                [self setButtonState:btnDrawColorRed	forState:STATE_NORMAL];
                [self setButtonState:btnDrawColorGreen	forState:STATE_NORMAL];
                [self setButtonState:btnDrawColorBlue	forState:STATE_SELECT];
                [self setButtonState:btnEraseDraw       forState:STATE_NORMAL];
            default:
                break;
        }
    }else {
        //消しゴムを選択
        _selectColorNo = ERASE_COLOR_NO;
        [self setButtonState:btnDrawColorRed	forState:STATE_NORMAL];
        [self setButtonState:btnDrawColorGreen	forState:STATE_NORMAL];
        [self setButtonState:btnDrawColorBlue	forState:STATE_NORMAL];
        [self setButtonState:btnEraseDraw       forState:STATE_SELECT];
    }
    
#ifdef PICTURE_PAINT_PALLET_POPUP
    // 選択されているボタン以外は非表示にする
    switch (_selectColorNo) {
		case 1:
			btnDrawColorRed.hidden = NO;
			btnDrawColorGreen.hidden = YES;
			btnDrawColorBlue.hidden = YES;
			break;
		case 2:
			btnDrawColorRed.hidden = YES;
			btnDrawColorGreen.hidden = NO;
			btnDrawColorBlue.hidden = YES;
			break;
		case 3:
			btnDrawColorRed.hidden = YES;
			btnDrawColorGreen.hidden = YES;
			btnDrawColorBlue.hidden = NO;
		default:
			break;
	}
#endif
	
	// リスナークラスに通知
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{	
        PALLET_BUTTON_COMMAND setBtn;
        if (_selectColorNo != ERASE_COLOR_NO) {
            setBtn = (btn.tag - _selectColorNo);
        }else{
            setBtn = btnEraseDraw.tag;
        }
		[self.delegate OnDrawModeChange:self
						 changedCommand:setBtn 
								   args:[NSNumber numberWithInt:_selectColorNo]]; 
	} 
	
}

// 描画線幅系のボタンイベント
- (void) onBtnWidth:(id)sender
{
	UIButton* btn = (UIButton*)sender;
	
	// 描画線幅の選択番号の設定
	_selectWidthNo = btn.tag - PALLET_DRAW_WIDTH;
	
	// 描画色系で自身のみを選択状態にする
	switch (_selectWidthNo) {
		case 1:
			[self setButtonState:btnDrawWidthLight	forState:STATE_SELECT];
			[self setButtonState:btnDrawWidthMiddle	forState:STATE_NORMAL];
			[self setButtonState:btnDrawWidthHeavy	forState:STATE_NORMAL];
			break;
		case 2:
			[self setButtonState:btnDrawWidthLight	forState:STATE_NORMAL];
			[self setButtonState:btnDrawWidthMiddle	forState:STATE_SELECT];
			[self setButtonState:btnDrawWidthHeavy	forState:STATE_NORMAL];
			break;
		case 3:
			[self setButtonState:btnDrawWidthLight	forState:STATE_NORMAL];
			[self setButtonState:btnDrawWidthMiddle	forState:STATE_NORMAL];
			[self setButtonState:btnDrawWidthHeavy	forState:STATE_SELECT];
            break;
		default:
			break;
	}
    
#ifdef PICTURE_PAINT_PALLET_POPUP
    // 選択されているボタン以外は非表示にする
    switch (_selectWidthNo) {
		case 1:
			btnDrawWidthLight.hidden = NO;
			btnDrawWidthMiddle.hidden = YES;
			btnDrawWidthHeavy.hidden = YES;
            break;
        case 2:
			btnDrawWidthLight.hidden = YES;
			btnDrawWidthMiddle.hidden = NO;
			btnDrawWidthHeavy.hidden = YES;
            break;
        case 3:
			btnDrawWidthLight.hidden = YES;
			btnDrawWidthMiddle.hidden = YES;
			btnDrawWidthHeavy.hidden = NO;
            break;
        default:
            break;
    }
#endif
	
	// リスナークラスに通知
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{	
		[self.delegate OnDrawModeChange:self
						 changedCommand:(btn.tag - _selectWidthNo) 
								   args:[NSNumber numberWithInt:_selectWidthNo]]; 
	} 
	
}

// 元に戻すイベントボックス
#ifndef CALULU_IPHONE
-(void) onBtnUndoView:(id)sender
{
	UIButton* btn = (UIButton*)sender;
	if(btn.tag == PALLET_UNDOBOX){
        if (popupUndo) {
            [popupUndo release];
            popupUndo = nil;
        }
        popupUndo = 
        [[UIPopoverController alloc] initWithContentViewController:undoView];
        undoView.popoverController = popupUndo;
        [popupUndo presentPopoverFromRect:btn.bounds
                                       inView:btn
                     permittedArrowDirections:arrowLocate
                                     animated:YES];
    }

}
#endif
// 元に戻す
-(void) onBtnUndo:(id)sender
{
	UIButton* btn = (UIButton*)sender;
#ifndef CALULU_IPHONE
	if(btn.tag == PALLET_UNDO){
        [self setButtonState:btnRedo forState:STATE_NORMAL];
    }
#endif
	
	// リスナークラスに通知
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{	
		[self.delegate OnDrawModeChange:self changedCommand:btn.tag args:nil]; 
	} 
	
}

#ifdef VARIABLE_PICTURE_PAINT_PALLET
// パレットの表示／非表示
- (void) onBtnPalleteShowHide:(id)sender
{   
    // ボタンタグの値を保存
    NSUInteger tag = btnPalleteShowHide.tag;
  
    // ボタンのタグの表示状態をクリア
    btnPalleteShowHide.tag &= ~(VARIABLE_PALLET_DISP_SHOW | VARIABLE_PALLET_DISP_HIDE);
    
    // 移動後のパレット位置
    CGRect afterPal = self.frame;
    // 移動後のボタン位置：Portrateのみ
    CGRect afterBtn = btnPalleteShowHide.frame;
    // ボタンImage
    NSString *nib;
      
    switch (tag)
    {
        case (VARIABLE_PALLET_DISP_SHOW | VARIABLE_PALLET_PORTRAITE):
        // 表示でPortraite
            // 表示 -> 非表示
            btnPalleteShowHide.tag |= VARIABLE_PALLET_DISP_HIDE;
            // パレット位置
            afterPal.size.width = 0.0f;
            // ボタン位置
            afterBtn.origin.y = 416.0f;
            // ボタンイメージ
            nib = [NSString stringWithString:@"pallete_show"];
            break;
        case (VARIABLE_PALLET_DISP_HIDE | VARIABLE_PALLET_PORTRAITE):
        // 非表示でPortraite
            // 非表示 -> 表示
            btnPalleteShowHide.tag |= VARIABLE_PALLET_DISP_SHOW;
            // パレット位置
            afterPal.size.width = PORTRAIT_VIEW_WIDTH;
            afterPal.size.height = PORTRAIT_VIEW_HEIGHT;
            // ボタン位置
            afterBtn.origin.y = 372.0f;
            // ボタンイメージ
            nib = [NSString stringWithString:@"pallete_hide"];
            break;
        case (VARIABLE_PALLET_DISP_SHOW | VARIABLE_PALLET_RANDSCAPE):
        // 表示でRandscape
            // 表示 -> 非表示
            btnPalleteShowHide.tag |= VARIABLE_PALLET_DISP_HIDE;
            // パレット位置
            afterPal.size.width = 0.0f;
            // ボタン位置:変わらない
            // afterBtn.origin.y = 258.0f;
            // ボタンイメージ
            nib = [NSString stringWithString:@"pallete_show"];
            break;
        case (VARIABLE_PALLET_DISP_HIDE | VARIABLE_PALLET_RANDSCAPE):
        // 非表示でRandscape
            // 非表示 -> 表示
            btnPalleteShowHide.tag |= VARIABLE_PALLET_DISP_SHOW;
            // パレット位置
            afterPal.size.width = LANDSCAPE_VIEW_WIDTH;
            afterPal.size.height = LANDSCAPE_VIEW_HEIGHT;
            // ボタン位置:変わらない
            // afterBtn.origin.y = 258.0f;
            // ボタンイメージ
            nib = [NSString stringWithString:@"pallete_hide"];
            break;
    }
    
    // ボタンイメージ変更
    [btnPalleteShowHide setImage:[UIImage imageNamed:nib]
                        forState:UIControlStateNormal];
    
    // パレットとボタンのアニメーション
    [UIView animateWithDuration:0.3
                     animations:^{self.frame = afterPal;}
                     completion:^(BOOL finished){
                         if ((tag & VARIABLE_PALLET_PORTRAITE) != 0)
                         {  btnPalleteShowHide.frame = afterBtn; }      // Portraitのみボタン移動
                     }];

    
#ifdef PICTURE_PAINT_PALLET_POPUP
    // パレットを閉じるときにパレットpopupを閉じる
    if (btnPalleteShowHide.tag & VARIABLE_PALLET_DISP_HIDE)
    {
        [_vwColorPoupup closePopupWithAnimate:NO];
        [_vwLineWidthPoupup closePopupWithAnimate:NO];
    }
#endif
    
}
#endif

#ifdef PICTURE_PAINT_PALLET_POPUP

// 描画色系のボタンイベント（ポップアップ）
- (void) onBtnColor4Popup:(id)sender
{
    UIButton* btn = (UIButton*)sender;
    
    NSMutableArray *buttons = [NSMutableArray array];
    
    //設定されている描画色に応じてボタンリストを作成（設定されているボタンが一番末尾）
    switch (btn.tag - PALLET_DRAW_COLOR)
    {
        case 1:
            [buttons addObject:btnDrawColorGreen];
            [buttons addObject:btnDrawColorBlue];
            [buttons addObject:btnDrawColorRed];
            break;
        case 2:
            [buttons addObject:btnDrawColorRed];
            [buttons addObject:btnDrawColorBlue];
            [buttons addObject:btnDrawColorGreen];
            break;
        case 3:
            [buttons addObject:btnDrawColorBlue];
            [buttons addObject:btnDrawColorRed];
            [buttons addObject:btnDrawColorGreen];
            break;
        default:
            break;
    }
    
    // popupを表示する
    [_vwColorPoupup dispPopupWithButtons:buttons];
}

// 描画線幅系のボタンイベント（ポップアップ）
- (void) onBtnLineWidth4Popup:(id)sender
{
    UIButton* btn = (UIButton*)sender;
    
    NSMutableArray *buttons = [NSMutableArray array];
    
    //設定されている描画色に応じてボタンリストを作成（設定されているボタンが一番末尾）
    switch (btn.tag - PALLET_DRAW_WIDTH)
    {
        case 1:
            [buttons addObject:btnDrawWidthMiddle];
            [buttons addObject:btnDrawWidthHeavy];
            [buttons addObject:btnDrawWidthLight];
            break;
        case 2:
            [buttons addObject:btnDrawWidthLight];
            [buttons addObject:btnDrawWidthHeavy];
            [buttons addObject:btnDrawWidthMiddle];
            break;
        case 3:
            [buttons addObject:btnDrawWidthLight];
            [buttons addObject:btnDrawWidthMiddle];
            [buttons addObject:btnDrawWidthHeavy];
            break;
        default:
            break;
    }
    
    // popupを表示する
    [_vwLineWidthPoupup dispPopupWithButtons:buttons];
}


#endif

#pragma mark public_methods

// パレットの位置の設定
- (void) setPositionWithRotate:(CGPoint)origin isPortrate:(BOOL)isPortrate
{
	// 自分の位置設定
#ifndef VARIABLE_PICTURE_PAINT_PALLET
	if (isPortrate)
	{
		[self setFrame:CGRectMake
			(origin.x, origin.y, PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
        arrowLocate = UIPopoverArrowDirectionDown;
	}
	else 
	{
		[self setFrame:CGRectMake
			(origin.x, origin.y, LANDSCAPE_VIEW_WIDTH, LANDSCAPE_VIEW_HEIGHT)];
        arrowLocate = UIPopoverArrowDirectionRight;
	}
    lineView = [lineView setLocatePortrate:isPortrate];
    sapaView = [sapaView setLocatePortrate:isPortrate];
    undoView = [undoView setLocatePortrate:isPortrate];
    drawStringView = [drawStringView setLocatePortrate:isPortrate];

#else
    
    CGFloat palHeight;
    if (isPortrate)
    {
        palHeight = ((btnPalleteShowHide.tag & VARIABLE_PALLET_DISP_SHOW) != 0)?
            PORTRAIT_VIEW_HEIGHT : 0.0f;
        [self setFrame:CGRectMake
            (origin.x, origin.y, PORTRAIT_VIEW_WIDTH, palHeight)];
    }
    else 
    {
        palHeight = ((btnPalleteShowHide.tag & VARIABLE_PALLET_DISP_SHOW) != 0)?
            LANDSCAPE_VIEW_HEIGHT : 0.0f;
        [self setFrame:CGRectMake
            (origin.x, origin.y, LANDSCAPE_VIEW_WIDTH, palHeight)];
    }
    
    // ボタンのタグにデバイス向きを保存
    btnPalleteShowHide.tag &= ~(VARIABLE_PALLET_PORTRAITE | VARIABLE_PALLET_RANDSCAPE);
    btnPalleteShowHide.tag |= (isPortrate)? 
        VARIABLE_PALLET_PORTRAITE : VARIABLE_PALLET_RANDSCAPE;
    
#endif
	
	// ボタンのレイアウト
#ifdef CALULU_IPHONE
	CGFloat posConst = 2.0f;
	CGFloat posMove = 4.0f;
    CGFloat *posX = &posMove;
	CGFloat *posY = &posConst;
#else
    CGFloat posConst = (isPortrate)? 5.0f : 8.0f;
	CGFloat posMove = (isPortrate)? 8.0f : 4.0f;
    CGFloat *posX = (isPortrate)? &posMove : &posConst;
	CGFloat *posY = (isPortrate)? &posConst : &posMove;
#endif
		
	[btnSapareteDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	[btnSaparete setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	posMove += ICON_SIZE;
	[btnSapareteDelete setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
#ifdef CALULU_IPHONE
	posMove += (ICON_SIZE + ((isPortrate)? 0.0f : 8.0f));
#else
	posMove += (ICON_SIZE + ((isPortrate)? 8.0f : 5.0f));
#endif

#ifndef CALULU_IPHONE
    posConst = (isPortrate)? 5.0f : 20.0f;
    posMove = (isPortrate)? 8.0f : 4.0f;
	[btnSapareteView setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];

	posMove += ICON_SIZE;
#endif
	
	[btnLineDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	posMove += ICON_SIZE;
	[btnSplineDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	posMove += ICON_SIZE;
#ifndef CALULU_IPHONE
    posConst = (isPortrate)? 5.0f : 8.0f;
    posMove = (isPortrate)? 8.0f : 4.0f;
#endif
	[btnEraseDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
#ifndef CALULU_IPHONE
    posConst = (isPortrate)? 5.0f : 20.0f;
    posMove = (isPortrate)? 10.0f : 4.0f;
	posMove += ICON_SIZE * 3;
    [btnDrawString setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    posMove += ICON_SIZE;
    [btnUndoView setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    
    posConst = (isPortrate)? 5.0f : 8.0f;
    posMove = (isPortrate)? 8.0f : 4.0f;
    [btnInChara setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    posMove += ICON_SIZE;
    [btnMoveString setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];

#endif
#ifdef CALULU_IPHONE
	posMove += (ICON_SIZE + ((isPortrate)? 0.0f : 8.0f));
#else
    posConst = (isPortrate)? 5.0f : 8.0f;
    posMove = (isPortrate)? 8.0f : 5.0f;
    posConst += (ICON_SIZE * 2 - ICON_SIZE_MINI);
#endif
	
	[btnDrawColorRed setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#ifndef CALULU_IPHONE
	posMove += ICON_SIZE_MINI;
#endif
	[btnDrawColorBlue setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#ifndef CALULU_IPHONE
	posMove += ICON_SIZE_MINI;
#endif
	[btnDrawColorGreen setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#ifdef CALULU_IPHONE
	posMove += (ICON_SIZE_MINI + ((isPortrate)? 0.0f : 8.0f));
#else
    posConst = (isPortrate)? 5.0f : 8.0f;
    posMove = (isPortrate)? 8.0f : 4.0f;
	posConst += (ICON_SIZE * 3 - ICON_SIZE_MINI);
#endif
	
	[btnDrawWidthLight setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#ifndef CALULU_IPHONE
	posMove += ICON_SIZE_MINI;
#endif
	[btnDrawWidthMiddle setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#ifndef CALULU_IPHONE
	posMove += ICON_SIZE_MINI;
#endif
	[btnDrawWidthHeavy setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#ifdef CALULU_IPHONE
	posMove += (ICON_SIZE_MINI + ((isPortrate)? 0.0f : 8.0f));
#else
    posConst = (isPortrate)? 5.0f : 8.0f;
    posMove = (isPortrate)? 8.0f : 4.0f;
#endif
	[btnUndo setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	 posMove += (ICON_SIZE + 5.0f);
#ifndef CALULU_IPHONE
    [btnRedo setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    posMove += (ICON_SIZE + 5.0f);
    [btnAllDelete setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
#endif
#ifdef VARIABLE_PICTURE_PAINT_PALLET
    // パレット表示／非表示ボタン
    CGRect btnRect = btnPalleteShowHide.frame;
    switch (btnPalleteShowHide.tag)
    {
        case (VARIABLE_PALLET_DISP_SHOW | VARIABLE_PALLET_PORTRAITE):
            // 表示でPortraite
            btnRect.origin.x = 8.0f;
            btnRect.origin.y = 372.0f;
            break;
        case (VARIABLE_PALLET_DISP_HIDE | VARIABLE_PALLET_PORTRAITE):
            // 非表示でPortraite
            btnRect.origin.x = 8.0f;
            btnRect.origin.y = 416.0f;
            break;
        case (VARIABLE_PALLET_DISP_SHOW | VARIABLE_PALLET_RANDSCAPE):
            // 表示でRandscape
        case (VARIABLE_PALLET_DISP_HIDE | VARIABLE_PALLET_RANDSCAPE):
            // 非表示でRandscape
            btnRect.origin.x =  24.0f;
            btnRect.origin.y = 258.0f;
            break;
    }
    
    btnPalleteShowHide.frame = btnRect;
    
#endif
    
#ifdef PICTURE_PAINT_PALLET_POPUP
    // デバイスの回転がある場合はパレットpopupは閉じる
    [_vwColorPoupup closePopupWithAnimate:NO];
    [_vwLineWidthPoupup closePopupWithAnimate:NO];
#endif
    
    
}

// Lock状態の設定
- (void) setLockState:(BOOL)isLock
{
	[self setAllButtonState:(isLock)? MODE_VOID :MODE_LOCK];
	
	self.alpha = (isLock)? 1.0f : 0.45f;
    
#ifdef VARIABLE_PICTURE_PAINT_PALLET
    // Lock状態によりパレットの表示／非表示をコントロール
    [self _setPalletShowHide:isLock];
#endif
    
}

// 区分線（グレーアウト）への移行通知
- (void) notifySeparateGrayOut
{
	btnSapareteDraw.hidden = YES;
	btnSaparete.hidden = NO;
	
	// 区分線削除ボタンを通常状態にする
	[self setButtonState:btnSapareteDelete	forState:STATE_NORMAL];
	// 区分線ボタンを選択状態にする
	[self setButtonState:btnSaparete		forState:STATE_SELECT];
}

// 区分線系のボタンの初期化
- (void) initBtnSeparate
{
	// 描画線削除は区分線描画：選択状態、区分線：非表示 区分線削除(自身)：操作不可にする
	[self setButtonState:btnSapareteDraw	forState:STATE_DISABLE];
	[self setButtonState:btnSaparete		forState:STATE_DISABLE];
	[self setButtonState:btnSapareteDelete	forState:STATE_DISABLE];
	
	btnSapareteDraw.hidden = NO;
	btnSaparete.hidden = YES;
}

#ifdef VARIABLE_PICTURE_PAINT_PALLET
// 動的パレットの初期化
- (void) initVariablePallet:(UIView*)parentView
{
    // 初期状態でパレットは非表示
    
    // パレットの表示／非表示のボタン生成
    btnPalleteShowHide = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnPalleteShowHide setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnPalleteShowHide.tag = VARIABLE_PALLET_DISP_HIDE | VARIABLE_PALLET_PORTRAITE;
	[btnPalleteShowHide addTarget:self action:@selector(onBtnPalleteShowHide:) 
			  forControlEvents:UIControlEventTouchUpInside];
    [btnPalleteShowHide setImage:[UIImage imageNamed:@"pallete_show"]
                        forState:UIControlStateNormal];
	[parentView addSubview:btnPalleteShowHide];
    
    // ボタンも非表示
    btnPalleteShowHide.hidden = YES;
}

#endif

#ifdef PICTURE_PAINT_PALLET_POPUP

// Popupのセットアップ
- (void) setupPalletPopup
{
    // 描画色のポップアップViewのインスタンス作成
    _vwColorPoupup =[[PicturePaintPalletPopupView alloc]
                     initWithParentView:self.superview 
                     popupEvent:^(id sender)
                     {  [self onBtnColor:sender]; }];
    
    // 描画太さのポップアップView  のインスタンス作成
    _vwLineWidthPoupup =[[PicturePaintPalletPopupView alloc]
                         initWithParentView:self.superview 
                         popupEvent:^(id sender)
                         {  [self onBtnWidth:sender]; }];
}

#endif

@end
