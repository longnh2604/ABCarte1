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

#import "AccountManager.h"

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
@synthesize uiOffset;

#pragma mark private_methods

// ボタン類の生成
- (void) makeButtons
{
	btnSapareteDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnSapareteDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSapareteDraw.tag = PALLET_SEPARATE_DRAW;
	[btnSapareteDraw addTarget:self action:@selector(onBtnSeparete:) 
			  forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnSapareteDraw];
	
	btnSaparete = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnSaparete setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSaparete.tag = PALLET_SEPARATE;
	btnSaparete.hidden = YES;
	[btnSaparete addTarget:self action:@selector(onBtnSeparete:) 
			  forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnSaparete];
	
	btnSapareteDelete = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnSapareteDelete setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSapareteDelete.tag = PALLET_SEPARATE_DELETE;
	[btnSapareteDelete addTarget:self action:@selector(onBtnSeparete:) 
		  forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnSapareteDelete];
	
	btnLineDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnLineDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnLineDraw.tag = PALLET_LINE;
	[btnLineDraw addTarget:self action:@selector(onBtnDraw:) 
				forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnLineDraw];
	
	btnCircleDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnCircleDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnCircleDraw.tag = PALLET_CIRCLE;
	[btnCircleDraw addTarget:self action:@selector(onBtnDraw:)
          forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnCircleDraw];
    
	btnSplineDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnSplineDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnSplineDraw.tag = PALLET_SPLINE;
	[btnSplineDraw addTarget:self action:@selector(onBtnDraw:) 
		  forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnSplineDraw];
	
	btnEraseDraw = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnEraseDraw setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnEraseDraw.tag = PALLET_ERASE;
	[btnEraseDraw addTarget:self action:@selector(onBtnErasePopup:)       // onBtnDraw
			forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnEraseDraw];
    
    btnAllClear = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnAllClear setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnAllClear.tag = PALLET_ALL_CLEAR;
	[btnAllClear addTarget:self action:@selector(onBtnErasePopup:) 
           forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnAllClear];
	
    /*    btnInChara = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnInChara setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnInChara.tag = (PALLET_CHARA);
	[btnInChara addTarget:self action:@selector(onBtnDraw:) 
         forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnInChara];*/
    
    btnDrawColor = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawColor setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawColor.tag = (PALLET_DRAW_COLOR + 1);
#ifdef PICTURE_PAINT_PALLET_POPUP
	[btnDrawColor addTarget:self action:@selector(onBtnColor4Popup:)
           forControlEvents:UIControlEventTouchUpInside];
#else
   	[btnDrawColor addTarget:self action:@selector(onBtnColor:)
           forControlEvents:UIControlEventTouchUpInside];
#endif
	[self addSubview:btnDrawColor];
    
#ifdef PICTURE_PAINT_PALLET_POPUP
	btnDrawColorRed = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawColorRed setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawColorRed.tag = (PALLET_DRAW_COLOR + 1);
	[btnDrawColorRed addTarget:self action:@selector(onBtnColor4Popup:)
              forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnDrawColorRed];
	
	btnDrawColorGreen = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawColorGreen setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawColorGreen.tag = (PALLET_DRAW_COLOR + 2);
    [btnDrawColorGreen addTarget:self action:@selector(onBtnColor4Popup:)
                forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnDrawColorGreen];
	
	btnDrawColorBlue = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawColorBlue setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawColorBlue.tag = (PALLET_DRAW_COLOR + 3);
    [btnDrawColorBlue addTarget:self action:@selector(onBtnColor4Popup:)
               forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnDrawColorBlue];
    
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    btnDrawColorWhite = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnDrawColorWhite setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    btnDrawColorWhite.tag = (PALLET_DRAW_COLOR + 4);
    [btnDrawColorWhite addTarget:self action:@selector(onBtnColor4Popup:)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnDrawColorWhite];
    
    btnDrawColorBeige = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnDrawColorBeige setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    btnDrawColorBeige.tag = (PALLET_DRAW_COLOR + 5);
    [btnDrawColorBeige addTarget:self action:@selector(onBtnColor4Popup:)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnDrawColorBeige];
    
    btnDrawColorBlack = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnDrawColorBlack setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    btnDrawColorBlack.tag = (PALLET_DRAW_COLOR + 6);
    [btnDrawColorBlack addTarget:self action:@selector(onBtnColor4Popup:)
                forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnDrawColorBlack];
#endif
	
	btnDrawWidth = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawWidth setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawWidth.tag = (PALLET_DRAW_WIDTH + 1);
#ifdef PICTURE_PAINT_PALLET_POPUP
    [btnDrawWidth addTarget:self action:@selector(onBtnLineWidth4Popup:)
           forControlEvents:UIControlEventTouchUpInside];
#else
    [btnDrawWidth addTarget:self action:@selector(onBtnWidth:)
           forControlEvents:UIControlEventTouchUpInside];
#endif
	[self addSubview:btnDrawWidth];
    
#ifdef PICTURE_PAINT_PALLET_POPUP
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    btnDrawWidthSLight = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnDrawWidthSLight setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    btnDrawWidthSLight.tag = (PALLET_DRAW_WIDTH + 1);
    [btnDrawWidthSLight addTarget:self action:@selector(onBtnLineWidth4Popup:)
                 forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnDrawWidthSLight];

	btnDrawWidthLight = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawWidthLight setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawWidthLight.tag = (PALLET_DRAW_WIDTH + 2);
    [btnDrawWidthLight addTarget:self action:@selector(onBtnLineWidth4Popup:)
                forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnDrawWidthLight];
	
	btnDrawWidthMiddle = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawWidthMiddle setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawWidthMiddle.tag = (PALLET_DRAW_WIDTH + 3);
    [btnDrawWidthMiddle addTarget:self action:@selector(onBtnLineWidth4Popup:)
                 forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnDrawWidthMiddle];
	
	btnDrawWidthHeavy = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnDrawWidthHeavy setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnDrawWidthHeavy.tag = (PALLET_DRAW_WIDTH + 4);
    [btnDrawWidthHeavy addTarget:self action:@selector(onBtnLineWidth4Popup:)
                forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnDrawWidthHeavy];
#endif
    
#ifdef STAMP_FUNC
	btnStamp = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnStamp setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	btnStamp.tag = (PALLET_STAMP);
//#ifdef PICTURE_PAINT_PALLET_POPUP
//    [btnStamp addTarget:self action:@selector(onBtnLineStamp4Popup:)
//       forControlEvents:UIControlEventTouchUpInside];
//#else
    [btnStamp addTarget:self action:@selector(onBtnStamp:)
       forControlEvents:UIControlEventTouchUpInside];
//#endif
	[self addSubview:btnStamp];
#endif
    btnRotation = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnRotation setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
    btnRotation.tag = (MODE_ROTATION);
    [btnRotation addTarget:self action:@selector(onBtnRotation:)
      forControlEvents:UIControlEventTouchUpInside];
    btnRotation.hidden = YES;
    [self addSubview:btnRotation];
    	
	btnUndo = [UIButton buttonWithType:UIButtonTypeCustom];
	[btnUndo setFrame:CGRectMake(0.0f, 0.0f, ICON_SIZE, ICON_SIZE)];
	btnUndo.tag = (MODE_REDO);
	[btnUndo addTarget:self action:@selector(onBtnUndo:) 
				forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btnUndo];							   
}

// ボタンのimageのnib名のリスト作成
- (void) makeListBtnNibName
{
	_listBtnNibName = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"separate_write", [NSNumber numberWithInt:PALLET_SEPARATE_DRAW],
					   @"separate", [NSNumber numberWithInt:PALLET_SEPARATE],
					   @"separate_delete", [NSNumber numberWithInt:PALLET_SEPARATE_DELETE],
					   @"line_write", [NSNumber numberWithInt:PALLET_LINE],
					   @"ellipse", [NSNumber numberWithInt:PALLET_CIRCLE], // 変更
					   @"spline_write", [NSNumber numberWithInt:PALLET_SPLINE],
					   @"eraser", [NSNumber numberWithInt:PALLET_ERASE],
                       @"all_clear", [NSNumber numberWithInt:PALLET_ALL_CLEAR],
					   @"color_red", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 1)],
					   @"color_Yellow", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 2)],
					   @"color_blue", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 3)],
                       //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
                       @"color_white", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 4)],
                       @"color_beige", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 5)],
                       @"color_black", [NSNumber numberWithInt:(PALLET_DRAW_COLOR + 6)],
                       //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
                       @"width_slight", [NSNumber numberWithInt:(PALLET_DRAW_WIDTH + 1)],
					   @"width_light", [NSNumber numberWithInt:(PALLET_DRAW_WIDTH + 2)],
					   @"width_middle", [NSNumber numberWithInt:(PALLET_DRAW_WIDTH + 3)],
					   @"width_heavy", [NSNumber numberWithInt:(PALLET_DRAW_WIDTH + 4)],
					   @"rotation", [NSNumber numberWithInt:PALLET_ROTATION],
                       @"undo", [NSNumber numberWithInt:PALLET_UNDO],
                       @"stamp", [NSNumber numberWithInt:PALLET_STAMP], //仮で黄色 //DELC SASAGE
                       
                       @"kari_button_inString", [NSNumber numberWithInt:PALLET_CHARA],

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

// 回転ボタンを表示
- (void)displayRotationBtn{
    btnRotation.hidden = NO;
}
// ボタン状態の設定 色と線幅以外のボタンはtagによりnibファイルの通番を管理//DELC SASAGE
- (void) setButtonState:(UIButton*)button forState:(PALLET_BUTTON_STATE)state
{
    int nib_number = (int)button.tag;
    [self setButtonState:button forNibNumber:nib_number forState:state]; //このメソッドにもともとメソッドの中身は移動
}
// 色ボタン状態の設定 //DELC SASAGE
- (void) setColorButtonState:(UIButton*)button forState:(PALLET_BUTTON_STATE)state
{
    int nib_number = PALLET_DRAW_COLOR + _selectColorNo;
    [self setButtonState:button forNibNumber:nib_number forState:state];
}
// 線幅ボタン状態の設定 //DELC SASAGE
- (void) setWidthButtonState:(UIButton*)button forState:(PALLET_BUTTON_STATE)state
{
    int nib_number = PALLET_DRAW_WIDTH + _selectWidthNo;
    [self setButtonState:button forNibNumber:nib_number forState:state];
}
//nibファイルの通番を指定したボタン状態の設定 //DELC SASAGE
- (void) setButtonState:(UIButton*)button forNibNumber:(int)nib_number forState:(PALLET_BUTTON_STATE)state
{
	NSString *nibName = [NSString stringWithFormat:@"%@_%@",
						 [_listBtnNibName objectForKey:[NSNumber numberWithInt:nib_number]],
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
    [self setButtonState:btnCircleDraw      forState:state1];
	[self setButtonState:btnSplineDraw		forState:state1];
	[self setButtonState:btnEraseDraw		forState:state1];
    [self setButtonState:btnAllClear		forState:state1];
	[self setButtonState:btnDrawColor    	forState:state2]; //DELC SASAGE
#ifdef PICTURE_PAINT_PALLET_POPUP
	[self setButtonState:btnDrawColorRed	forState:state2];
	[self setButtonState:btnDrawColorGreen	forState:state2];
	[self setButtonState:btnDrawColorBlue	forState:state2];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    [self setButtonState:btnDrawColorWhite	forState:state2];
    [self setButtonState:btnDrawColorBeige	forState:state2];
    [self setButtonState:btnDrawColorBlack	forState:state2];
    btnDrawColorRed.hidden = YES;
    btnDrawColorGreen.hidden = YES;
    btnDrawColorBlue.hidden = YES;
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    btnDrawColorWhite.hidden = YES;
    btnDrawColorBeige.hidden = YES;
    btnDrawColorBlack.hidden = YES;
#endif
	[self setButtonState:btnDrawWidth   	forState:state2]; //DELC SASAGE
#ifdef PICTURE_PAINT_PALLET_POPUP
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    [self setButtonState:btnDrawWidthSLight	forState:state2];
    [self setButtonState:btnDrawWidthLight	forState:state2];
	[self setButtonState:btnDrawWidthMiddle forState:state2];
	[self setButtonState:btnDrawWidthHeavy	forState:state2];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    btnDrawWidthSLight.hidden = YES;
    btnDrawWidthLight.hidden = YES;
    btnDrawWidthMiddle.hidden = YES;
    btnDrawWidthHeavy.hidden = YES;
#endif
#if DEF_ABCARTE || AIKI_CUSTOM
    if([AccountManager isStamp]!=0)
        [self setButtonState:btnStamp           forState:state1]; //DELC SASAGE
    else
        [self setButtonState:btnStamp           forState:STATE_DISABLE]; //DELC SASAGE
#else
    btnStamp.hidden = YES;
#endif

    [self setButtonState:btnRotation		forState:state1];
	[self setButtonState:btnUndo			forState:state1];

//    [self setButtonState:btnInChara         forState:state1];

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

// popupを閉じる
- (void) _closeAllPalletPopup
{
#ifdef PICTURE_PAINT_PALLET_POPUP
    [_vwColorPoupup closePopupWithAnimate:YES];
    [_vwLineWidthPoupup closePopupWithAnimate:YES];
#endif
    [_vwErasePoupup closePopupWithAnimate:YES];
}

#pragma mark life_cycle
- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}
- (void)setSelectedStamp:(Stamp *)stamp {
    [self.delegate setSelectedStamp:stamp];
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
		
		// ボタン類の生成
		[self makeButtons];
		
		// ボタンのimageのnib名のリスト作成
		[self makeListBtnNibName];
		
		// ボタン状態の一括設定
		[self setAllButtonState:MODE_LOCK];
		//スタンプ選択画面の作成 //DELC SASAGE
        stampSelectView = [[StampSelectView alloc] initWithFrame:
                           CGRectMake(0.0f, 0.0f, PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
		stampSelectView.stampDelegate = self;
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
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
        btnDrawColorWhite.hidden = YES;
        btnDrawColorBeige.hidden = YES;
        btnDrawColorBlack.hidden = YES;
        btnDrawWidthMiddle.hidden = YES;
        btnDrawWidthHeavy.hidden = YES;
#endif
        // 消しゴム／全消去の初期設定は消しゴム
        btnAllClear.hidden = YES;
    }
    
    uiOffset = 0.0f;
	
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
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
	[_listBtnNibName release];

    [btnSapareteDraw removeFromSuperview];
    btnSapareteDraw = nil;
    [btnSaparete removeFromSuperview];
    btnSaparete = nil;
    [btnSapareteDelete removeFromSuperview];
    btnSapareteDelete = nil;
    
    [btnLineDraw removeFromSuperview];
    btnLineDraw = nil;
    [btnCircleDraw removeFromSuperview];
    btnCircleDraw = nil;
    [btnSplineDraw removeFromSuperview];
    btnSplineDraw = nil;
    [btnEraseDraw removeFromSuperview];
    btnEraseDraw = nil;
    [btnAllClear removeFromSuperview];
    btnAllClear = nil;
    [btnDrawColor removeFromSuperview];
    btnDrawColor = nil;
#ifdef PICTURE_PAINT_PALLET_POPUP
    [btnDrawColorRed removeFromSuperview];
    btnDrawColorRed = nil;
    [btnDrawColorGreen removeFromSuperview];
    btnDrawColorGreen = nil;
    [btnDrawColorBlue removeFromSuperview];
    btnDrawColorBlue = nil;
    [btnDrawWidthLight removeFromSuperview];
    btnDrawWidthLight = nil;
    [btnDrawWidthMiddle removeFromSuperview];
    btnDrawWidthMiddle = nil;
    [btnDrawWidthHeavy removeFromSuperview];
    btnDrawWidthHeavy = nil;
#endif
    [btnDrawWidth removeFromSuperview];
    btnDrawWidth = nil;
    [btnStamp removeFromSuperview];
    btnStamp = nil;
    [btnRotation removeFromSuperview];
    btnRotation = nil;
    [btnUndo removeFromSuperview];
    btnUndo = nil;
    [btnInChara removeFromSuperview];
    btnInChara = nil;
    /*
	[btnSapareteDraw release];
    [btnSaparete release];
    [btnSapareteDelete release];
    
    [btnLineDraw release];
    [btnSplineDraw release];
    [btnEraseDraw release];
    [btnAllClear release];
    [btnDrawColor release];
#ifdef PICTURE_PAINT_PALLET_POPUP
    [btnDrawColorRed release];
    [btnDrawColorGreen release];
    [btnDrawColorBlue release];
    [btnDrawWidthLight release];
    [btnDrawWidthMiddle release];
    [btnDrawWidthHeavy release];
#endif
    [btnDrawWidth release];
    [btnStamp release];
	[btnUndo release];
	[btnInChara release];
     */
    [stampSelectView removeFromSuperview];
    stampSelectView.stampDelegate = nil;
//    stampSelectView = nil;
    [stampSelectView release];
#ifdef VARIABLE_PICTURE_PAINT_PALLET
    [btnPalleteShowHide release];
#endif
    [popupSapareteView release];
    [popupLineDraw release];
    [popupUndo release];
    
#ifdef PICTURE_PAINT_PALLET_POPUP
    [_vwColorPoupup removeFromSuperview];
    [_vwColorPoupup release];
    [_vwLineWidthPoupup removeFromSuperview];
    [_vwLineWidthPoupup release];
#endif
    [_vwErasePoupup removeFromSuperview];
    [_vwErasePoupup release];
    
    self.delegate = nil;
    
	[super dealloc];
}

#pragma mark control_events

// 区分線系のボタンイベント
- (void) onBtnSeparete:(id)sender
{
    // 最初にポップアップを閉じる
    [self _closeAllPalletPopup];
    
	UIButton* btn = (UIButton*)sender;
	
	// 描画関連ボタンを通常状態にする
	[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
	[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
	[self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
    if([AccountManager isStamp]!=0)
        [self setButtonState:btnStamp   		forState:STATE_NORMAL]; //DELC SASAGE
    else
        [self setButtonState:btnStamp   		forState:STATE_DISABLE]; //DELC SASAGE

    [self setButtonState:btnAllClear        forState:STATE_NORMAL];
//    [self setButtonState:btnInChara         forState:STATE_NORMAL];

	// 色と線幅・元に戻すを操作不可にする
	[self setButtonState:btnDrawColor	forState:STATE_DISABLE]; //DELC SASAGE
	[self setButtonState:btnDrawWidth	forState:STATE_DISABLE]; //DELC SASAGE
    [self setButtonState:btnRotation			forState:STATE_DISABLE];
	[self setButtonState:btnUndo			forState:STATE_DISABLE];
	
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
    // 最初にポップアップを閉じる
    [self _closeAllPalletPopup];
    
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
            [self setButtonState:btnCircleDraw      forState:STATE_NORMAL];
			[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
            [self setButtonState:btnAllClear		forState:STATE_NORMAL];
            //            [self setButtonState:btnInChara         forState:STATE_NORMAL];
            [self setButtonState:btnRotation		forState:STATE_NORMAL];
			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;
		case PALLET_CIRCLE:
			[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
            [self setButtonState:btnAllClear		forState:STATE_NORMAL];
            //            [self setButtonState:btnInChara         forState:STATE_NORMAL];
            [self setButtonState:btnRotation		forState:STATE_NORMAL];
			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;
		case PALLET_SPLINE:
			[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
            [self setButtonState:btnCircleDraw      forState:STATE_NORMAL];
			// [self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
            [self setButtonState:btnAllClear		forState:STATE_NORMAL];
//            [self setButtonState:btnInChara         forState:STATE_NORMAL];
            [self setButtonState:btnRotation		forState:STATE_NORMAL];
			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;
		case PALLET_ERASE:
        case PALLET_ALL_CLEAR:
			[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
            [self setButtonState:btnCircleDraw      forState:STATE_NORMAL];
			[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
			// [self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
//            [self setButtonState:btnInChara         forState:STATE_NORMAL];
            [self setButtonState:btnRotation		forState:STATE_NORMAL];
			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;
            
/*        case PALLET_CHARA:
			[self setButtonState:btnLineDraw		forState:STATE_NORMAL];
			[self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
            [self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
            // [self setButtonState:btnInChara         forState:STATE_NORMAL];

			[self setButtonState:btnUndo			forState:STATE_NORMAL];
			break;*/
		default:
			break;
	}
	// 描画色：選択中のみ選択状態　以外は通常状態にする (但しERASE/全消去は除く) //DELC SASAGE
    if ( (btn.tag != PALLET_ERASE) && (btn.tag != PALLET_ALL_CLEAR) )
    {
        [self setColorButtonState:btnDrawColor forState:STATE_NORMAL];
#ifdef PICTURE_PAINT_PALLET_POPUP
        [self setButtonState:btnDrawColorRed forState:STATE_NORMAL];
        [self setButtonState:btnDrawColorGreen forState:STATE_NORMAL];
        [self setButtonState:btnDrawColorBlue forState:STATE_NORMAL];
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
        [self setButtonState:btnDrawColorWhite forState:STATE_NORMAL];
        [self setButtonState:btnDrawColorBeige forState:STATE_NORMAL];
        [self setButtonState:btnDrawColorBlack forState:STATE_NORMAL];
#endif
    }
    else
    {
        [self setColorButtonState:btnDrawColor forState:STATE_DISABLE];
#ifdef PICTURE_PAINT_PALLET_POPUP
        [self setButtonState:btnDrawColorRed forState:STATE_DISABLE];
        [self setButtonState:btnDrawColorGreen forState:STATE_DISABLE];
        [self setButtonState:btnDrawColorBlue forState:STATE_DISABLE];
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
        [self setButtonState:btnDrawColorWhite forState:STATE_DISABLE];
        [self setButtonState:btnDrawColorBeige forState:STATE_DISABLE];
        [self setButtonState:btnDrawColorBlack forState:STATE_DISABLE];
#endif
    }
    // 描画幅：選択中のみ選択状態　以外は通常状態にする(但し全消去は除く) //DELC SASAGE
    if (btn.tag != PALLET_ALL_CLEAR)
    {
        [self setWidthButtonState:btnDrawWidth forState:STATE_NORMAL];	// リスナークラスに通知
#ifdef PICTURE_PAINT_PALLET_POPUP
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
        [self setButtonState:btnDrawWidthSLight	forState:STATE_NORMAL];
        [self setButtonState:btnDrawWidthLight	forState:STATE_NORMAL];
        [self setButtonState:btnDrawWidthMiddle forState:STATE_NORMAL];
        [self setButtonState:btnDrawWidthHeavy	forState:STATE_NORMAL];
#endif
    }
    
	// スタンプ・ボタンを通常状態にする //DELC SASAGE
    [self setNormalBtnStamp];

    // 消しゴム／全消去で選択されているボタン以外は非表示にする。また自身を選択状態にする
    if ((btn.tag == PALLET_ERASE) || (btn.tag == PALLET_ALL_CLEAR) )
    {
        switch (btn.tag) {
            case PALLET_ERASE:
//                btnEraseDraw.hidden = NO;
//                btnAllClear.hidden = YES;
                [self setButtonState:btnEraseDraw   forState:STATE_SELECT];
                [self setButtonState:btnAllClear    forState:STATE_NORMAL];
                break;
            case PALLET_ALL_CLEAR:
//                btnEraseDraw.hidden = YES;
//                btnAllClear.hidden = NO;
                [self setButtonState:btnEraseDraw   forState:STATE_NORMAL];
                [self setButtonState:btnAllClear    forState:STATE_SELECT];
                break;
            default:
                break;
        }
    }
	
	// リスナークラスに通知
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{	[self.delegate OnDrawModeChange:self changedCommand:btn.tag args:nil]; } 
	
}
// 描画色系のボタンイベント
//ボタンを押すと色が赤(1)->黄(2)->青(3)->赤(1)->...と変化する。//DELC SASAGE
- (void) onBtnColor:(id)sender
{
    // 最初にポップアップを閉じる
    [self _closeAllPalletPopup];

#ifdef PICTURE_PAINT_PALLET_POPUP
    UIButton* btn = (UIButton*)sender;
    switch (btn.tag) {
        case PALLET_DRAW_COLOR + 1:
            _selectColorNo = 1;
            break;
        case PALLET_DRAW_COLOR + 2:
            _selectColorNo = 2;
            break;
        case PALLET_DRAW_COLOR + 3:
            _selectColorNo = 3;
            break;
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
        case PALLET_DRAW_COLOR + 4:
            _selectColorNo = 4;
            break;
        case PALLET_DRAW_COLOR + 5:
            _selectColorNo = 5;
            break;
        case PALLET_DRAW_COLOR + 6:
            _selectColorNo = 6;
            break;

        default:
            _selectColorNo = 1;
    }
#else
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
	//描画色の選択番号に１を加える。3を超えると１に戻す。
    _selectColorNo++;
    if (_selectColorNo > 6 || _selectColorNo < 1) {
        _selectColorNo = 1;
    }
#endif
    //変更された色番号に表示するボタンの色も合わせる。
    [self setColorButtonState:btnDrawColor forState:STATE_NORMAL];

#ifdef PICTURE_PAINT_PALLET_POPUP
    // 選択されているボタン以外は非表示にする
    switch (_selectColorNo) {
		case 1:
			btnDrawColorRed.hidden = NO;
			btnDrawColorGreen.hidden = YES;
			btnDrawColorBlue.hidden = YES;
            //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
            btnDrawColorWhite.hidden = YES;
            btnDrawColorBeige.hidden = YES;
            btnDrawColorBlack.hidden = YES;
			break;
		case 2:
			btnDrawColorRed.hidden = YES;
			btnDrawColorGreen.hidden = NO;
			btnDrawColorBlue.hidden = YES;
            //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
            btnDrawColorWhite.hidden = YES;
            btnDrawColorBeige.hidden = YES;
            btnDrawColorBlack.hidden = YES;
			break;
		case 3:
			btnDrawColorRed.hidden = YES;
			btnDrawColorGreen.hidden = YES;
			btnDrawColorBlue.hidden = NO;
            //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
            btnDrawColorWhite.hidden = YES;
            btnDrawColorBeige.hidden = YES;
            btnDrawColorBlack.hidden = YES;
            break;
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
        case 4:
            btnDrawColorRed.hidden = YES;
            btnDrawColorGreen.hidden = YES;
            btnDrawColorBlue.hidden = YES;
            btnDrawColorWhite.hidden = NO;
            btnDrawColorBeige.hidden = YES;
            btnDrawColorBlack.hidden = YES;
            break;
        case 5:
            btnDrawColorRed.hidden = YES;
            btnDrawColorGreen.hidden = YES;
            btnDrawColorBlue.hidden = YES;
            btnDrawColorWhite.hidden = YES;
            btnDrawColorBeige.hidden = NO;
            btnDrawColorBlack.hidden = YES;
            break;
        case 6:
            btnDrawColorRed.hidden = YES;
            btnDrawColorGreen.hidden = YES;
            btnDrawColorBlue.hidden = YES;
            btnDrawColorWhite.hidden = YES;
            btnDrawColorBeige.hidden = YES;
            btnDrawColorBlack.hidden = NO;
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
						 changedCommand:PALLET_DRAW_COLOR //DELC SASAGE
								   args:[NSNumber numberWithInt:_selectColorNo]]; 
	} 
	
}

// 描画線幅系のボタンイベント //DELC SASAGE
// ボタンを押すと線幅が細(1)->中(2)->太(3)->細(1)->...と変化する
- (void) onBtnWidth:(id)sender
{
	// 最初にポップアップを閉じる
    [self _closeAllPalletPopup];

#ifdef PICTURE_PAINT_PALLET_POPUP
    UIButton* btn = (UIButton*)sender;
    switch (btn.tag) {
        case PALLET_DRAW_WIDTH + 1:
            _selectWidthNo = 1;
            break;
        case PALLET_DRAW_WIDTH + 2:
            _selectWidthNo = 2;
            break;
        case PALLET_DRAW_WIDTH + 3:
            _selectWidthNo = 3;
            break;
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
        case PALLET_DRAW_WIDTH + 4:
            _selectWidthNo = 4;
            break;
        default:
            _selectWidthNo = 1;
    }
#else
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    //線幅の選択番号に１を加える。3を超えると１に戻す。
    _selectWidthNo++;
    if (_selectWidthNo > 4 || _selectWidthNo < 1) {
        _selectWidthNo = 1;
    }
#endif
    //変更された線幅番号に表示するボタンの線幅も合わせる。
    [self setWidthButtonState:btnDrawWidth forState:STATE_SELECT];
        
#ifdef PICTURE_PAINT_PALLET_POPUP
    // 選択されているボタン以外は非表示にする
    switch (_selectWidthNo) {
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
        case 1:
            btnDrawWidthSLight.hidden = NO;
            btnDrawWidthLight.hidden = YES;
            btnDrawWidthMiddle.hidden = YES;
            btnDrawWidthHeavy.hidden = YES;
            break;
        case 2:
            btnDrawWidthSLight.hidden = YES;
            btnDrawWidthLight.hidden = NO;
            btnDrawWidthMiddle.hidden = YES;
            btnDrawWidthHeavy.hidden = YES;
            break;
        case 3:
            btnDrawWidthSLight.hidden = YES;
            btnDrawWidthLight.hidden = YES;
            btnDrawWidthMiddle.hidden = NO;
            btnDrawWidthHeavy.hidden = YES;
            break;
        case 4:
            btnDrawWidthSLight.hidden = YES;
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
						 changedCommand:PALLET_DRAW_WIDTH //DELC SASAGE
								   args:[NSNumber numberWithInt:_selectWidthNo]]; 
	} 
	
}
//スタンプ・ボタンを押下
- (void) onBtnStamp:(id)sender
{
    // 最初にポップアップを閉じる
    [self _closeAllPalletPopup];
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    [self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
    [self setButtonState:btnLineDraw		forState:STATE_NORMAL];
    [self setButtonState:btnCircleDraw		forState:STATE_NORMAL];
    [self setButtonState:btnEraseDraw		forState:STATE_NORMAL];
    [self setButtonState:btnRotation		forState:STATE_NORMAL];
    [self setButtonState:btnUndo			forState:STATE_NORMAL];
    [self setButtonState:btnAllClear		forState:STATE_NORMAL];
    [self setButtonState:btnDrawColor		forState:STATE_DISABLE];
    [self setButtonState:btnDrawWidth		forState:STATE_DISABLE];
#ifdef PICTURE_PAINT_PALLET_POPUP
    [self setButtonState:btnDrawColorRed forState:STATE_DISABLE];
    [self setButtonState:btnDrawColorGreen forState:STATE_DISABLE];
    [self setButtonState:btnDrawColorBlue forState:STATE_DISABLE];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    [self setButtonState:btnDrawColorWhite forState:STATE_DISABLE];
    [self setButtonState:btnDrawColorBeige forState:STATE_DISABLE];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    [self setButtonState:btnDrawColorBlack forState:STATE_DISABLE];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    [self setButtonState:btnDrawWidthSLight	forState:STATE_DISABLE];
    [self setButtonState:btnDrawWidthLight	forState:STATE_DISABLE];
    [self setButtonState:btnDrawWidthMiddle forState:STATE_DISABLE];
    [self setButtonState:btnDrawWidthHeavy	forState:STATE_DISABLE];
#endif
    stampSelectView.hidden = !stampSelectView.hidden;
    PALLET_BUTTON_STATE state = stampSelectView.hidden ? STATE_NORMAL : STATE_SELECT;
    PALLET_BUTTON_COMMAND command = stampSelectView.hidden ? PALLET_VOID : PALLET_STAMP;
    if (!stampSelectView.hidden) {
        [stampSelectView removeAndSetStamps];
    }
    if([AccountManager isStamp]!=0)
        [self setButtonState:btnStamp forState: state];
    else
        [self setButtonState:btnStamp forState:STATE_DISABLE];

    // リスナークラスに通知
    if ( (self.delegate) &&
        ([self.delegate respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
    {
        [self.delegate OnDrawModeChange: self
                         changedCommand: command
                                   args: nil];
    }
}
//スタンプ・ボタンをNormalにし、スタンプ・セレクト画面も隠す
- (void) setNormalBtnStamp{
    if([AccountManager isStamp]!=0)
        [self setButtonState:btnStamp   		forState:STATE_NORMAL]; //DELC SASAGE
    else
        [self setButtonState:btnStamp   		forState:STATE_DISABLE]; //DELC SASAGE
    stampSelectView.hidden = YES;
}
//スタンプを全て未選択状態に
- (void)setStampsUnselected{
    [stampSelectView setStampsUnselected];
}
// 画像を回転させる
-(void) onBtnRotation:(id)sender
{
    // 最初にポップアップを閉じる
    [self _closeAllPalletPopup];
    
    UIButton* btn = (UIButton*)sender;
    
    // リスナークラスに通知
    if ( (self.delegate) &&
        ([self.delegate respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
    {
        [self.delegate OnDrawModeChange:self changedCommand:btn.tag args:nil];
    } 
    
}
// 元に戻す
-(void) onBtnUndo:(id)sender
{
    // 最初にポップアップを閉じる
    [self _closeAllPalletPopup];
    
	UIButton* btn = (UIButton*)sender;
	
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
            nib = @"pallete_show";
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
            nib = @"pallete_hide";
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
            nib = @"pallete_show";
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
            nib = @"pallete_hide";
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
    // UIButton* btn = (UIButton*)sender;
    
    NSMutableArray *buttons = [NSMutableArray array];
    
    [self setButtonState:btnDrawColorRed	forState:STATE_NORMAL];
    [self setButtonState:btnDrawColorGreen	forState:STATE_NORMAL];
    [self setButtonState:btnDrawColorBlue	forState:STATE_NORMAL];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    [self setButtonState:btnDrawColorWhite	forState:STATE_NORMAL];
    [self setButtonState:btnDrawColorBeige	forState:STATE_NORMAL];
    [self setButtonState:btnDrawColorBlack	forState:STATE_NORMAL];
    [buttons addObject:btnDrawColorRed];
    [buttons addObject:btnDrawColorBlue];
    [buttons addObject:btnDrawColorGreen];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    [buttons addObject:btnDrawColorWhite];
    [buttons addObject:btnDrawColorBeige];
    [buttons addObject:btnDrawColorBlack];
/*    //設定されている描画色に応じてボタンリストを作成（設定されているボタンが一番末尾）
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
*/
    [self _closeAllPalletPopup];
    // popupを表示する
    [_vwColorPoupup dispPopupWithButtons:buttons];
}

// 描画線幅系のボタンイベント（ポップアップ）
- (void) onBtnLineWidth4Popup:(id)sender
{
    // UIButton* btn = (UIButton*)sender;
    
    NSMutableArray *buttons = [NSMutableArray array];
    
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    [self setButtonState:btnDrawWidthSLight	forState:STATE_NORMAL];
    [self setButtonState:btnDrawWidthLight	forState:STATE_NORMAL];
	[self setButtonState:btnDrawWidthMiddle forState:STATE_NORMAL];
	[self setButtonState:btnDrawWidthHeavy	forState:STATE_NORMAL];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    [buttons addObject:btnDrawWidthSLight];
    [buttons addObject:btnDrawWidthLight];
    [buttons addObject:btnDrawWidthMiddle];
    [buttons addObject:btnDrawWidthHeavy];
/*    //設定されている描画色に応じてボタンリストを作成（設定されているボタンが一番末尾）
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
    }*/

    [self _closeAllPalletPopup];
    // popupを表示する
    [_vwLineWidthPoupup dispPopupWithButtons:buttons];
}


#endif

// 消しゴム／全消去のボタンイベント（ポップアップ）
- (void) onBtnErasePopup:(id)sender
{
    // UIButton* btn = (UIButton*)sender;
    
    NSMutableArray *buttons = [NSMutableArray array];
/*
    //設定されている描画色に応じてボタンリストを作成（設定されているボタンが一番末尾）
    switch (btn.tag)
    {
        case PALLET_ERASE:
            [buttons addObject:btnEraseDraw];
            [buttons addObject:btnAllClear];
            break;
        case PALLET_ALL_CLEAR:
            [buttons addObject:btnAllClear];
            [buttons addObject:btnEraseDraw];
            break;
        default:
            break;
    }
 */
    [buttons addObject:btnAllClear];
    [buttons addObject:btnEraseDraw];
    
    // スタンプ選択ボタンが表示されていれば、隠す //DELC SASAGE
    stampSelectView.hidden = YES;

    [self _closeAllPalletPopup];
    // popupを表示する
    [_vwErasePoupup dispPopupWithButtons:buttons];
}

#pragma mark public_methods

// パレットの位置の設定
- (void) setPositionWithRotate:(CGPoint)origin isPortrate:(BOOL)isPortrate
{
    //スタンプ・セレクト画面を追加 //DELC SASAGE
    [self.superview addSubview:stampSelectView];
    [stampSelectView setPositionWithRotate:origin isPortrate:isPortrate];
	// 自分の位置設定
#ifndef VARIABLE_PICTURE_PAINT_PALLET
	if (isPortrate)
	{
		[self setFrame:CGRectMake
         (origin.x, origin.y, PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
        //スタンプの選択画面をパレットの上に表示 //DELC SASAGE
		[stampSelectView setFrame:CGRectMake
         (origin.x, origin.y - (self.frame.size.height + 5), PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
	}
	else 
	{
		[self setFrame:CGRectMake
         (origin.x, origin.y, LANDSCAPE_VIEW_WIDTH, LANDSCAPE_VIEW_HEIGHT)];
        //スタンプの選択画面を左下に表示 //DELC SASAGE
        [stampSelectView setFrame:CGRectMake
         (LANDSCAPE_STAMP_SELECT_X, LANDSCAPE_STAMP_SELECT_Y+uiOffset, PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
	}
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
    CGFloat posConst = (isPortrate)? 5.0f : 5.0f;
	CGFloat posMove = (isPortrate)? 20.0f : 4.0f;
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
	posMove += (ICON_SIZE + ((isPortrate)? 20.0f : 5.0f));
#endif
	
	[btnLineDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	posMove += ICON_SIZE;
	[btnSplineDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	
    posMove += ICON_SIZE;
	[btnEraseDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    [btnAllClear setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    
//	posMove += ICON_SIZE;

//    [btnInChara setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];

#ifdef CALULU_IPHONE
	posMove += (ICON_SIZE + ((isPortrate)? 0.0f : 8.0f));
#else
	posMove += (ICON_SIZE + 10.0f); posConst += (ICON_SIZE - ICON_SIZE_MINI);
#endif
	[btnDrawColor setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)]; //DELC SASAGE
#ifdef PICTURE_PAINT_PALLET_POPUP
	[btnDrawColorRed setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawColorBlue setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawColorGreen setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    [btnDrawColorWhite setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    [btnDrawColorBeige setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    [btnDrawColorBlack setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#endif
#ifndef CALULU_IPHONE
	posMove += ICON_SIZE_MINI;
#endif
	[btnDrawWidth setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)]; //DELC SASAGE
#ifdef PICTURE_PAINT_PALLET_POPUP
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    [btnDrawWidthSLight setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawWidthLight setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawWidthMiddle setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawWidthHeavy setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#endif
#ifndef CALULU_IPHONE
	posMove += ICON_SIZE;
    *posY = (isPortrate)? *posY-10 : *posY;
    *posX = (isPortrate)? *posX    : *posX-10;
#endif
	[btnStamp setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)]; //DELC SASAGE
#ifndef CALULU_IPHONE
    if (isPortrate) {
        posMove += ((3 * ICON_SIZE_MINI)-10.0f);//DELC SASAGE
    } else {
        posMove += 20;
    }
#endif
    
#ifdef CALULU_IPHONE
	posMove += (ICON_SIZE_MINI + ((isPortrate)? 0.0f : 8.0f));
#else
	posMove += (ICON_SIZE_MINI + 5.0f);
	posConst = (isPortrate)? 5.0f : 5.0f;
#endif
    [btnRotation setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	[btnUndo setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	 posMove += (ICON_SIZE + 5.0f);
    
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
    [_vwErasePoupup closePopupWithAnimate:NO];
    // 楕円描画は画像編集では隠す
    btnCircleDraw.hidden = YES;
}
// パレットの位置の設定(動画編集)
- (void) setVideoEditPositionWithRotate:(CGPoint)origin isPortrate:(BOOL)isPortrate
{
    //スタンプ・セレクト画面を追加 //DELC SASAGE
    [self.superview addSubview:stampSelectView];
    [stampSelectView setPositionWithRotate:origin isPortrate:isPortrate];
	// 自分の位置設定
#ifndef VARIABLE_PICTURE_PAINT_PALLET
	if (isPortrate)
	{
		[self setFrame:CGRectMake
         (origin.x, origin.y, 728, 70)];
        //スタンプの選択画面をパレットの上に表示 //DELC SASAGE
		[stampSelectView setFrame:CGRectMake
         (origin.x, origin.y - (self.frame.size.height + 5), PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
	}
	else
	{
		[self setFrame:CGRectMake
         (origin.x, origin.y, 70, 550)];
        //スタンプの選択画面を左下に表示 //DELC SASAGE
//        [stampSelectView setFrame:CGRectMake(
//                                             LANDSCAPE_STAMP_SELECT_X, LANDSCAPE_STAMP_SELECT_Y, PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
        [stampSelectView setFrame:CGRectMake(
                                             148,
                                             674 + uiOffset,
                                             PORTRAIT_VIEW_WIDTH,
                                             PORTRAIT_VIEW_HEIGHT)];
        
	}
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
//    CGFloat posConst = (isPortrate)? 5.0f : 20.0f;
//	CGFloat posMove = (isPortrate)? 20.0f : 4.0f;
    CGFloat posConst = (isPortrate)? 5.0f : 6.0f;
	CGFloat posMove = (isPortrate)? 6.0f : 4.0f;
    CGFloat *posX = (isPortrate)? &posMove : &posConst;
	CGFloat *posY = (isPortrate)? &posConst : &posMove;
#endif
    
//	[btnSapareteDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
//  [btnSaparete setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
//	posMove += ICON_SIZE;
//	[btnSapareteDelete setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
//#ifdef CALULU_IPHONE
//	posMove += (ICON_SIZE + ((isPortrate)? 0.0f : 8.0f));
//#else
//	posMove += (ICON_SIZE + ((isPortrate)? 20.0f : 5.0f));
    //#endif
    //0313 btnSaparete.hidden = btnSapareteDraw.hidden = btnSapareteDelete.hidden = btnStamp.hidden = YES;
    btnSaparete.hidden = btnSapareteDraw.hidden = btnSapareteDelete.hidden = YES;
	[btnLineDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	posMove += ICON_SIZE;
	[btnSplineDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	posMove += ICON_SIZE;
	[btnCircleDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
	
    posMove += ICON_SIZE;
	[btnEraseDraw setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    [btnAllClear setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    
    //	posMove += ICON_SIZE;
    
    //    [btnInChara setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    
#ifdef CALULU_IPHONE
	posMove += (ICON_SIZE + ((isPortrate)? 0.0f : 8.0f));
#else
	posMove += (ICON_SIZE + 10.0f); posConst += (ICON_SIZE - ICON_SIZE_MINI);
#endif
	[btnDrawColor setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)]; //DELC SASAGE
#ifdef PICTURE_PAINT_PALLET_POPUP
	[btnDrawColorRed setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawColorBlue setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawColorGreen setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    [btnDrawColorWhite setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    [btnDrawColorBeige setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
    [btnDrawColorBlack setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#endif
#ifndef CALULU_IPHONE
	posMove += ICON_SIZE_MINI;
#endif
	[btnDrawWidth setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)]; //DELC SASAGE
#ifdef PICTURE_PAINT_PALLET_POPUP
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの線の太さを追加
    [btnDrawWidthSLight setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawWidthLight setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawWidthMiddle setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
	[btnDrawWidthHeavy setFrame:CGRectMake(*posX, *posY, ICON_SIZE_MINI, ICON_SIZE_MINI)];
#endif
#ifndef CALULU_IPHONE
	posMove += ICON_SIZE;
    *posY = (isPortrate)? *posY - 10 : *posY; // DELC 01/24
    *posX = (isPortrate)? *posX    : *posX- 10; // DELC 01/24
#endif

	[btnStamp setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)]; //DELC SASAGE
#ifndef CALULU_IPHONE
    if (isPortrate) {
        posMove += ((6 * ICON_SIZE_MINI) - 10.0f);//DELC SASAGE
    } else {
        posMove += ICON_SIZE;//DELC SASAGE
    }
#endif
    
    
    
#ifdef CALULU_IPHONE
	posMove += (ICON_SIZE_MINI + ((isPortrate)? 0.0f : 8.0f));
#else
	// posMove += (ICON_SIZE_MINI + 5.0f);
//	posConst = (isPortrate)? 5.0f : 20.0f;
	posConst = (isPortrate)? 5.0f : 6.0f;
#endif
    if (isPortrate) {
        [btnRotation setFrame:CGRectMake(*posX-ICON_SIZE, *posY, ICON_SIZE, ICON_SIZE)];
        [btnUndo setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
    }else{
        [btnRotation setFrame:CGRectMake(*posX, *posY, ICON_SIZE, ICON_SIZE)];
        [btnUndo setFrame:CGRectMake(*posX, *posY+ICON_SIZE, ICON_SIZE, ICON_SIZE)];
    }
    posMove += (ICON_SIZE + 5.0f);
    
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
    [_vwErasePoupup closePopupWithAnimate:NO];
    
}
- (void)setStampSelectViewPoint:(CGPoint)point {
    [stampSelectView setFrame:CGRectMake (point.x, point.y, PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
}
// Lock状態の設定
- (void) setLockState:(BOOL)isLock
{
	[self setAllButtonState:(isLock)? MODE_VOID :MODE_LOCK];
	
	self.alpha = (isLock)? 1.0f : 0.45f;
    //DELC SASAGE
    if (!isLock) {
        stampSelectView.hidden = YES;
        [_vwColorPoupup closePopupWithAnimate:YES];         // 描画色のポップアップView
        [_vwLineWidthPoupup closePopupWithAnimate:YES];     // 描画太さのポップアップView
        [_vwErasePoupup closePopupWithAnimate:YES];         // 消しゴムと全消去の切り替えポップアップView
    }
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

// Popupのセットアップ
- (void) setupPalletPopup
{
    __block PicturePaintPalletView *bself = self;
#ifdef PICTURE_PAINT_PALLET_POPUP
    // 描画色のポップアップViewのインスタンス作成
    _vwColorPoupup =[[PicturePaintPalletPopupView alloc]
                     initWithParentView:self.superview 
                     popupEvent:^(id sender)
                     {  [bself onBtnColor:sender]; }];
    
    // 描画太さのポップアップView  のインスタンス作成
    _vwLineWidthPoupup =[[PicturePaintPalletPopupView alloc]
                         initWithParentView:self.superview 
                         popupEvent:^(id sender)
                         {  [bself onBtnWidth:sender]; }];
#endif
    // 消しゴムと全消去の切り替えポップアップViewのインスタンス作成
    _vwErasePoupup =[[PicturePaintPalletPopupView alloc]
                         initWithParentView:self.superview 
                         popupEvent:^(id sender)
                         {  [bself onBtnDraw:sender]; }];
}
- (void)unselectStampIfSelected {
    if (stampSelectView.hidden == NO) {
        [self onBtnStamp:nil];
    }
}
@end
