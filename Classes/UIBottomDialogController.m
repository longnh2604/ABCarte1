//
//  UIBottomDialogController.m
//  iPadCamera
//
//  Created by  on 11/11/06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIBottomDialogController.h"

@interface UIBottomDialogController(override_methods)

// コンテナViewのサイズを求める
- (CGSize) _getContinerViewSize:(CGRect)parentViewFrame;

// x位置を求める
- (CGFloat) _getXPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame;

// 初期位置を求める
- (CGFloat) _getInitPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame;

// animate後の位置を求める
- (CGFloat) _getAnimatedPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame;

@end

///
/// 下から表示されるダイアログのコントローラクラス
///
@implementation UIBottomDialogController

#pragma mark -
#pragma mark private_methods

- (BOOL)isExistSubView:(UIView*)view
{
    BOOL is_exist = NO;
    for (UIView* subview in _continerView.subviews) {
        if (view == subview) {
            is_exist = YES;
            break;
        }
    }
    return is_exist;
}

- (void) removesSuperView
{
    // 先に表示していたViewをコンテナViewより取り除く
    [_displayViewController.view removeFromSuperview];
    
    // 次にコンテナViewを親Viewより取り除く
    [_continerView removeFromSuperview];
}

#pragma mark -
#pragma mark life_cycle

// 初期化
- (id) initWithParentView:(UIView*)parentView
{
    if ( (self = [super init]) )
    {
        // コンテナViewのサイズを求める
        CGSize sz = [self _getContinerViewSize:parentView.frame];
        
        _continerView = [[UIView alloc] initWithFrame:
                         CGRectMake(0.0f, 0.0f, sz.width, sz.height)];
        // コンテナViewの背景をモーダルライクにするため、暗い灰色の透明にする
        _continerView.backgroundColor 
            = [UIColor colorWithRed:0.15f green:0.15f blue:0.15f alpha:0.75f];
        
        // コンテナとなるViewを親Viewに加える
        [parentView addSubview:_continerView];
    }
    
    return (self);
}

- (void) dealloc
{
    [_displayViewController release];
    [_continerView release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark override_methods

// コンテナViewのサイズを求める
- (CGSize) _getContinerViewSize:(CGRect)parentViewFrame
{
    // コンテナとなるViewをLandscapeに固定する
#ifdef CALULU_IPHONE
    CGSize sz = CGSizeMake(320.0f, 460.0f);
#else
    CGSize sz = CGSizeMake(768.0f, 1004.0f);;
#endif
    
    return (sz);
}

// x位置を求める
- (CGFloat) _getXPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame
{
    return (0.0f);
}

// 初期位置を求める
- (CGFloat) _getInitPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame
{
    CGFloat pos = (_isDispBottom)? continerVwFrame.size.height : -1 * (dispVwFrame.size.height);
    return (pos);
}

// animate後の位置を求める
- (CGFloat) _getAnimatedPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame
{
    CGFloat pos = (_isDispBottom)? (continerVwFrame.size.height - dispVwFrame.size.height) : 0.0f;
    return (pos);
}

#pragma mark -
#pragma mark public_methods

// ダイアログの表示(下側表示)
- (void)presentDialogViewController:(UIViewController*)controller animated:(BOOL)animated
{
    [self presentDialogViewController:controller animated:animated isDispBottom:YES];
}

// ダイアログの表示
- (void)presentDialogViewController:(UIViewController*)controller animated:(BOOL)animated isDispBottom:(BOOL)isBottom
{
    // 表示するVCの保持
    _displayViewController = controller;
    [_displayViewController retain];
    
    CGRect frame1 = _continerView.frame;
    CGRect frame2 = controller.view.frame;
    
    // 表示位置の保存
    _isDispBottom = isBottom;
    
    // (1) init position
        // frame2.origin.y = (_isDispBottom)? frame1.size.height : -1 * (frame2.size.height);
    frame2.origin.y = [self _getInitPosition:frame1 displayVwFrame:frame2];
    controller.view.frame = frame2;
    
    if ([self isExistSubView:controller.view]) {
        [_continerView bringSubviewToFront:controller.view];
    } else {
        [_continerView addSubview:controller.view];
    }
    
    // (2) animate
        //frame2.origin.y = (_isDispBottom)? (frame1.size.height - frame2.size.height) : 0.0f;
    frame2.origin.x = [self _getXPosition:frame1 displayVwFrame:frame2];
    frame2.origin.y = [self _getAnimatedPosition:frame1 displayVwFrame:frame2];
    if (frame2.origin.y < 0)
    {   frame2.origin.y = 0; }
    
    if (animated) {
        [UIView animateWithDuration:0.5
                         animations:^{controller.view.frame = frame2;}];
    } else {
        controller.view.frame = frame2;
    }
}

// ダイアログを閉じる
- (void)dismissDialogViewControllerAnimated:(BOOL)animated
{
    if (![self isExistSubView:_displayViewController.view]) {
        return;
        // do nothing
    }
    
    CGRect frame1 = _continerView.frame;
    CGRect frame2 = _displayViewController.view.frame;
    
    // (1) animate
        // frame2.origin.y = (_isDispBottom)? frame1.size.height :  -1 * (frame2.size.height);
    frame2.origin.y = [self _getInitPosition:frame1 displayVwFrame:frame2];
    if (animated) {
        [UIView animateWithDuration:0.5
                         animations:^{_displayViewController.view.frame = frame2;}
                         completion:^(BOOL finished){[self removesSuperView];}
         ];
    } else {
        [self removesSuperView];
    }
}

// 画面の回転
-(void)rotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{   return; }       // デフォルトは何もしない

@end

///
/// 画面をLockするControllerクラス
///
@implementation UILockWindowController

#pragma mark -
#pragma mark override_methods

// 初期化
- (id) initWithParentView:(UIView*)parentView
{
    if ( (self = [super initWithParentView:parentView]) )
    {
        _continerView.autoresizingMask = 
            UIViewAutoresizingFlexibleWidth
                | UIViewAutoresizingFlexibleHeight
                | UIViewAutoresizingFlexibleLeftMargin
                | UIViewAutoresizingFlexibleRightMargin
                | UIViewAutoresizingFlexibleTopMargin
                | UIViewAutoresizingFlexibleBottomMargin;
    }
    
    return (self);
}

// コンテナViewのサイズを求める
- (CGSize) _getContinerViewSize:(CGRect)parentViewFrame
{
    // コンテナとなるViewを親Viewと同じサイズにする
    CGSize size = parentViewFrame.size;
    return (size);
}

// x位置を求める
- (CGFloat) _getXPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame
{
    CGFloat xPos = (continerVwFrame.size.width - dispVwFrame.size.width) / 2.0f;
    return (xPos);
}

// 初期位置を求める
- (CGFloat) _getInitPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame
{
    CGFloat pos =  (-1 * (dispVwFrame.size.height));
    return (pos);
}

// animate後の位置を求める
- (CGFloat) _getAnimatedPosition:(CGRect)continerVwFrame displayVwFrame:(CGRect)dispVwFrame
{
    // 高さ方向で中央に表示する
    CGFloat pos = (continerVwFrame.size.height - dispVwFrame.size.height) / 2.0f;
    return (pos);
}

@end
