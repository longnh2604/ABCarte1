//
//  UIImageView4Camera.h
//  iPadCamera
//
//  Created by MacBook on 11/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>

@class UIImage;

// ガイド線の数の初期値
#ifndef AIKI_CUSTOM
#define GUIDE_LINE_NUMS_INIT    0
#define GUIDE_LINE_NUMS_INIT_MANIPULATIVE    11
#else
#define GUIDE_LINE_NUMS_INIT    11
#endif

///
/// カメラ画面用UIImageView
///
@interface UIImageView4Camera : UIView {
	
	UIImage			*_backgroundImage;							// 背景画像
	NSUInteger		_guideLineNum;								// ガイド線の数（縦横同数）
    UIImage         *tempImage;                                 // 透過画像の一時保存用
    CGRect          imgRect;                                    // 透過画像のフレームサイズ
}

@property(nonatomic,retain) UIImage		*backgroundImage;		// 背景画像
@property(nonatomic)		NSUInteger	guideLineNum;			// ガイド線の数（縦横同数）

// 初期化
- (id)initWithImage:(UIImage *)image;

// 背景画像の設定
- (void) setBackgroundImage:(UIImage*)img;

// 背景透過画像を一時的に非表示制御を行う
- (void) setBackgroundImageHidden:(BOOL)status;

// ガイド線の数の設定
- (void) setGuideLineNums:(NSUInteger)nums;

// 背景画像とガイド線の数の設定
- (void) setBackgroundImageWithGuideLineNums:(UIImage*)img guideLineNums:(NSUInteger)nums;

// 背景画像とガイド線のリセット
- (void) resetBackgroundImage;

// 背景透過画像のフレームサイズ
- (void)setBackgroundImageRect:(CGRect)rect;

// 背景画像とガイド線のImage取得（コントロールのalphaによる透過）
- (UIImage*) getOverlayImageWithbackgroud:(BOOL)isImage isWithGuideLine:(BOOL)isGuide;

@end
