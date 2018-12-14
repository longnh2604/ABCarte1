//
//  PicturePaintPalletPopupView.m
//  iPadCamera
//
//  Created by  on 11/11/13.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "PicturePaintPalletPopupView.h"

#import "PicturePaintCommon.h"

///
/// 写真描画のパレットPopupView
///
@implementation PicturePaintPalletPopupView

#pragma mark private_methods

// popupするボタンの作成
- (UIButton*) _makePopupButton:(UIButton*)popBtn Pos:(CGFloat)Pos isPortrait:(BOOL)isPortrait
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    if(isPortrait) {
        [btn setFrame:CGRectMake(PALLET_POPUP_BUTTON_MARGIN, Pos,
                                 popBtn.frame.size.width, popBtn.frame.size.height)];
    } else {
        [btn setFrame:CGRectMake(Pos, PALLET_POPUP_BUTTON_MARGIN,
                                 popBtn.frame.size.width, popBtn.frame.size.height)];
    }
    btn.tag = popBtn.tag;
    [btn addTarget:self 
            action:@selector(onPopupBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [btn setImage:[popBtn imageForState:UIControlStateNormal] 
         forState:UIControlStateNormal];

    return (btn);
}

// このViewのframe算出
- (CGRect) _calcSelfFrame:(NSArray*)buttons isPortrait:(BOOL)isPortrait
{
    CGRect palletRect = ((UIButton *)(buttons[0])).superview.frame;
    CGSize appSize = [UIScreen mainScreen].applicationFrame.size;
    if (!UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        appSize = CGSizeMake(appSize.height, appSize.width);
    }
    // ボタンの個数
    NSUInteger btnNum = [buttons count];
    
    // ボタンのインスタンス
    UIButton* btn = [buttons objectAtIndex:(btnNum - 1)];
    // ボタンの親viewからの位置
    CGRect frame = btn.frame;
    if(isPortrait) { // 縦画面の時
        frame.origin.x += btn.superview.frame.origin.x;
        frame.origin.y += btn.superview.frame.origin.y;
        // このViewの位置
        frame.origin.x -= PALLET_POPUP_BUTTON_MARGIN;
        if (palletRect.origin.y > appSize.height * 0.5f) {
            frame.origin.y -= ((btn.frame.size.height * (btnNum - 1)) + PALLET_POPUP_BUTTON_MARGIN);
        } else {
            frame.origin.y -= PALLET_POPUP_BUTTON_MARGIN;
        }
        // このViewのサイズ
        frame.size.width = btn.frame.size.width + PALLET_POPUP_BUTTON_MARGIN * 2;
        frame.size.height = btn.frame.size.height * btnNum + PALLET_POPUP_BUTTON_MARGIN * 2;
    } else { // 横画面の時
        frame.origin.x += btn.superview.frame.origin.x;
        frame.origin.y += btn.superview.frame.origin.y;
        
        // このViewの位置
        if (palletRect.origin.x > appSize.width * 0.5f) {
            frame.origin.x -= ((btn.frame.size.width * (btnNum - 1)) + PALLET_POPUP_BUTTON_MARGIN);
        } else {
            frame.origin.x -=  PALLET_POPUP_BUTTON_MARGIN;
        }
        frame.origin.y -= PALLET_POPUP_BUTTON_MARGIN;
        // このViewのサイズ
        frame.size.width = btn.frame.size.width * btnNum + PALLET_POPUP_BUTTON_MARGIN * 2;
        frame.size.height = btn.frame.size.height + PALLET_POPUP_BUTTON_MARGIN * 2;

    }
    
    return (frame);
}

// 子Viewのボタンを削除
- (void) _removePopButtons
{
    for (UIView *btn in self.subviews)
    {
        [btn removeFromSuperview];
        
        // [btn release];
    }
}

#pragma mark life_cycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// 初期化
- (id) initWithParentView:(UIView*)parent popupEvent:(onPalletPopupEvent)hEvent
{    
    if ( (self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 0.0f)]) )
    {
        _hEvent = Block_copy(hEvent);
        
        _isShown = NO;
        
        // 背景色：黒
        self.backgroundColor = [UIColor blackColor];
        
        self.hidden = YES;
        
        // 角を丸める
        [Common cornerRadius4Control:self];
        
        [parent addSubview: self]; 
    }
    
    return (self);
}

- (void) dealloc
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    Block_release(_hEvent);
    
    [super dealloc];
}

#pragma mark control_event

// popupボタンクリックイベント
- (void) onPopupBtnClick:(id)sender
{
    if (_hEvent)
    {
        _hEvent(sender);
    }
    
    // popupを閉じる
    [self closePopupWithAnimate:YES];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark public_methods

// 表示する
- (void) dispPopupWithButtons:(NSArray*)buttons
{
    if (_isShown)
    {   return; }   // 既に開いている
    CGRect palletRect = ((UIButton *)(buttons[0])).superview.frame;
    CGSize appSize = [UIScreen mainScreen].applicationFrame.size;
    if (!UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        appSize = CGSizeMake(appSize.height, appSize.width);
    }
    // 縦横判別
    BOOL isPortrait = palletRect.size.height < palletRect.size.width;
    // popupするボタンを追加する
    CGFloat Pos = PALLET_POPUP_BUTTON_MARGIN;
    for (UIButton *popBtn in buttons)
    {
        UIButton *btn = [self _makePopupButton:popBtn Pos:Pos isPortrait:isPortrait];
        [self addSubview:btn];
        //[btn release];
        if(isPortrait) {
            Pos += popBtn.frame.size.height;
        } else {
            Pos += popBtn.frame.size.width;
        }
    }
    // このViewのpopup後のframe算出
    CGRect aFrame = [self _calcSelfFrame:buttons isPortrait:isPortrait];
    
    // このViewの初期位置
    if(isPortrait) {
        if (palletRect.origin.y > appSize.height * 0.5f) {
            self.frame = CGRectMake(aFrame.origin.x, aFrame.origin.y + aFrame.size.height,
                                    aFrame.size.width, 0.0f);
        } else {
            self.frame = CGRectMake(aFrame.origin.x, aFrame.origin.y,
                                    aFrame.size.width, 0.0f);
        }
    } else {
        if (palletRect.origin.x > appSize.width * 0.5f) {
            self.frame = CGRectMake(aFrame.origin.x + aFrame.size.width, aFrame.origin.y,
                                    0.0f, aFrame.size.height);
        } else {
            self.frame = CGRectMake(aFrame.origin.x, aFrame.origin.y,
                                    0.0f, aFrame.size.height);
        }
    }
    self.hidden = NO;
    
    // アニメーション
    [UIView animateWithDuration:0.3
                     animations:^{self.frame = aFrame;}];
    
    _isShown = YES;
}
// popupを閉じる
- (void) closePopupWithAnimate:(BOOL)isAnimate
{
    if (! _isShown)
    {   return; }   // 既に閉じている
    
    _isShown = NO;
    
    // 縦横判別
    //BOOL isDevicePortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
    BOOL isDevicePortrait = self.frame.size.height > self.frame.size.width;
    CGSize appSize = [UIScreen mainScreen].applicationFrame.size;
    if (!UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        appSize = CGSizeMake(appSize.height, appSize.width);
    }

    // 閉じた後のFrame
    CGRect aFrame;
    if(isDevicePortrait) {
        if (self.frame.origin.y > appSize.height * 0.5f) {
            aFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y + self.frame.size.height,
                                self.frame.size.width, 0.0f);
        } else {
            aFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                                self.frame.size.width, 0.0f);
        }
    } else {
        if (self.frame.origin.x > appSize.width * 0.5f) {
            aFrame = CGRectMake(self.frame.origin.x + self.frame.size.width, self.frame.origin.y,
                                0.0f, self.frame.size.height);
        } else {
            aFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                                0.0f, self.frame.size.height);
        }
    }
    
    // アニメーションがない場合は即時に閉じる
    if (! isAnimate)
    {
        // 子Viewのボタンを削除
        [self _removePopButtons];
        // Frameを変更
        self.frame = aFrame;
        self.hidden = NO;
        return;
    }
    
    // パレットとボタンのアニメーション
    [UIView animateWithDuration:0.3
                     animations:^{self.frame = aFrame;}
                     completion:^(BOOL finished){
                         // 子Viewのボタンを削除
                         [self _removePopButtons];
                         self.hidden = NO;
                     }];
    
}
@end
