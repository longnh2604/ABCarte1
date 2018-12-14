//
//  DoublePicturePaintPalletView.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2014/01/06.
//
//

#import "DoublePicturePaintPalletView.h"
#import "Common.h"

@implementation DoublePicturePaintPalletView

- (id)initWithEventListner:(id<PicturePaintPalletDelegate>)listner otherListner:(id<PicturePaintPalletDelegate>)otherListner {
    self = [super initWithEventListner:listner];
    if (self) {
        self.delegate2 = otherListner;
        lastModifiedPaintManager = nil;
    }
    return self;
}

- (void) onBtnSeparete:(id)sender
{
	UIButton* btn = (UIButton*)sender;
    [super onBtnSeparete:sender];
	// リスナークラスに通知
	if ( (self.delegate2) &&
		([self.delegate2 respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{	[self.delegate2 OnDrawModeChange:self changedCommand:btn.tag args:nil]; }
}
// 描画系のボタンイベント
- (void) onBtnDraw:(id)sender
{
	UIButton* btn = (UIButton*)sender;
    if (btn.tag == PALLET_ALL_CLEAR) {
        [self allClearForDouble];
    } else {
        [super onBtnDraw:sender];
        // リスナークラスに通知
        if ( (self.delegate2) &&
            ([self.delegate2 respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
        {	[self.delegate2 OnDrawModeChange:self changedCommand:btn.tag args:nil]; }
    }
}
- (void)allClearForDouble {
    // パレットの状態の更新
    // 最初にポップアップを閉じる
    [self _closeAllPalletPopup];
    
    // 区分線系を通常状態にする
    if (! btnSapareteDraw.hidden)
    {	[self setButtonState:btnSapareteDraw forState:STATE_NORMAL]; }
    else
    {	[self setButtonState:btnSaparete forState:STATE_NORMAL]; }
    
    [self setButtonState:btnLineDraw		forState:STATE_NORMAL];
    [self setButtonState:btnCircleDraw      forState:STATE_NORMAL];
    [self setButtonState:btnSplineDraw		forState:STATE_NORMAL];
    [self setButtonState:btnUndo			forState:STATE_NORMAL];
    
    [self setButtonState:btnEraseDraw   forState:STATE_NORMAL];
    [self setButtonState:btnAllClear    forState:STATE_SELECT];
    [self setColorButtonState:btnDrawColor forState:STATE_DISABLE];
#ifdef PICTURE_PAINT_PALLET_POPUP
    [self setButtonState:btnDrawColorRed forState:STATE_DISABLE];
    [self setButtonState:btnDrawColorGreen forState:STATE_DISABLE];
    [self setButtonState:btnDrawColorBlue forState:STATE_DISABLE];
#endif
    // スタンプ・ボタンを通常状態にする //DELC SASAGE
    [self setNormalBtnStamp];
    
    
    BOOL doClear = NO;  // １つでも全消去を行ったか
    if ( (self.delegate) &&
        ([self.delegate respondsToSelector:@selector(allClear)]))
    {
        if([self.delegate allClear]){
            doClear = YES;
        }
    }
    if ( (self.delegate2) &&
        ([self.delegate2 respondsToSelector:@selector(allClear)]))
    {
        if([self.delegate2 allClear]){
            doClear = YES;
        }
    }
    if (doClear == NO) {
        [Common showDialogWithTitle:@""
                            message:@"描画していないので\n全消去はできません。"];
    }
    lastModifiedPaintManager = nil;
}
// 描画色系のボタンイベント
//ボタンを押すと色が赤(1)->黄(2)->青(3)->赤(1)->...と変化する。//DELC SASAGE
- (void) onBtnColor:(id)sender
{
    NSLog(@"1/6       @@");
    [super onBtnColor:sender];
	// リスナークラスに通知	// リスナークラスに通知
	if ( (self.delegate2) &&
		([self.delegate2 respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{
        NSLog(@"1/6      @@1");
		[self.delegate2 OnDrawModeChange:self
						 changedCommand:PALLET_DRAW_COLOR
								   args:[NSNumber numberWithInt:_selectColorNo]];
	} 
	
}

// 描画線幅系のボタンイベント //DELC SASAGE
// ボタンを押すと線幅が細(1)->中(2)->太(3)->細(1)->...と変化する
- (void) onBtnWidth:(id)sender
{
    [super onBtnWidth:sender];
	// リスナークラスに通知
	if ( (self.delegate2) &&
		([self.delegate2 respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
	{
		[self.delegate2 OnDrawModeChange:self
						 changedCommand:PALLET_DRAW_WIDTH //DELC SASAGE
								   args:[NSNumber numberWithInt:_selectWidthNo]];
	}
	
}
//スタンプ・ボタンを押下
- (void) onBtnStamp:(id)sender
{
    [super onBtnStamp:sender];
    PALLET_BUTTON_COMMAND command = stampSelectView.hidden ? PALLET_VOID : PALLET_STAMP;
    // リスナークラスに通知
    if ( (self.delegate2) &&
        ([self.delegate2 respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
    {
        [self.delegate2 OnDrawModeChange: self
                         changedCommand: command
                                   args: nil];
    }
}
// 元に戻す
-(void) onBtnUndo:(id)sender
{
    // 最初にポップアップを閉じる
    [self _closeAllPalletPopup];
	UIButton* btn = (UIButton*)sender;
    // リスナークラスに通知
    if ( (lastModifiedPaintManager) &&
		([lastModifiedPaintManager respondsToSelector:@selector(OnDrawModeChange:changedCommand:args:)]))
    {
        [lastModifiedPaintManager OnDrawModeChange:self changedCommand:btn.tag args:nil];
    }
	
}
- (void)setLastModifiedPaintManager:(id<PicturePaintPalletDelegate>)_lastModifiedPaintManager {
    lastModifiedPaintManager = _lastModifiedPaintManager;
}
@end
