//
//  UIViewGridLine.m
//  iPadCamera
//
//  Created by MacBook on 11/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIViewGridLine.h"

#import "AccountManager.h"

///
/// カメラ画面用UIImageView
///
@implementation UIViewGridLine

@synthesize backgroundImage = _backgroundImage;
@synthesize guideLineNum = _guideLineNum;

#pragma mark local_methods

// ImageをX軸ににて鏡像反転する
- (UIImage*) reverseXAxisImage:(UIImage*)imgOrigin
{
	if (! imgOrigin)
	{	return (nil); }
	
	// グラフィックコンテキストを作成
	CGRect rect = CGRectMake(0.0, 0.0, imgOrigin.size.width, imgOrigin.size.height);
	UIGraphicsBeginImageContext(rect.size);	
	
	// contextを取得
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// X軸にて鏡像
	CGContextTranslateCTM(context, 0.0f, rect.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	// ImageRefの取得
	// CGImageRef imgRef = imgOrigin.CGImage;
	// CGContextへの描画
	// CGContextDrawImage(context, rect, imgRef);
	
	[imgOrigin drawInRect:rect];
	
	// 鏡像後のImageを取得
	UIImage* img = UIGraphicsGetImageFromCurrentImageContext();	
	
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
	
	return (img);
}

#ifdef CALULU_IPHONE
#define IMG_VW_CAM_GUIDE_LINE_WIDTH     0.75f       // ガイドライン線幅
#else
#define IMG_VW_CAM_GUIDE_LINE_WIDTH     1.5f        // ガイドライン線幅
#endif

// 背景画像とガイド線の描画
- (void) drawBackGroundWithContext:(CGContextRef)context drawRect:(CGRect)r alpha:(CGFloat)alpha 
					   isWithImage:(BOOL)isImage isWithGuideLine:(BOOL)isGuide
{
	// 背景画像の描画
	if ( (_backgroundImage) && (isImage) )
	{
		/*CGImageRef imgRef = _backgroundImage.CGImage;
		 CGContextDrawImage(context, 
		 CGRectMake(0, 0, r.size.width, r.size.height), 
		 imgRef);*/
//		[_backgroundImage drawInRect:CGRectMake(0, 0, r.size.width, r.size.height)
//						   blendMode:kCGBlendModeNormal
//							   alpha:alpha];
        [_backgroundImage drawInRect:imgRect
                           blendMode:kCGBlendModeNormal
                               alpha:alpha];
	}
	else 
	{
		// Canvasを白の透明で塗りつぶす
		CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 0.0f);
		CGContextFillRect(context, 
						  CGRectMake(0, 0, r.size.width, r.size.height));
	}
	
	
	// ガイド線の描画
	if ( (self.guideLineNum > 0) && (isGuide) )
	{
		// 線色の設定:赤色
		CGContextSetRGBStrokeColor(context,1.0f, 0.0f, 0.0f, alpha);
		// 線幅の設定:細い線
		CGContextSetLineWidth(context,IMG_VW_CAM_GUIDE_LINE_WIDTH);
		
		// 内蔵カメラの縦の場合を考慮して描画幅を決定
		CGFloat validWd
#ifdef CALULU_IPHONE
			= (r.size.width == 570.0f)? 320.0f : r.size.width;
#else
#ifdef VER150_LATER
			= (r.size.width == 854.0f)? 480.0f : r.size.width;
#else
            = (r.size.width == 1365.0f)? 768.0f : r.size.width;
#endif
#endif
		
		// 線の数＋１が間隔となる
		CGFloat xSpace = validWd / (CGFloat)(_guideLineNum + 1);
		CGFloat ySpace = r.size.height / (CGFloat)(_guideLineNum + 1);
		
		// 内蔵カメラの縦の場合を考慮して描画開始位置を決定
		CGFloat xOri 
#ifdef CALULU_IPHONE
			= (r.size.width == 570.0f)? 125.0f : 0.0f;
#else
#ifdef VER150_LATER
            = (r.size.width == 854.0f)? ((43.0f + 144.0f)) : 0.0f;
#else
            = (r.size.width == 1365.0f)? 298.5f : 0.0f;
#endif
#endif
				
		for (NSUInteger idx = 1; idx <= _guideLineNum; idx++)
		{
			// X方向の線
			CGFloat yAxis = ySpace * (CGFloat)idx;
			CGContextMoveToPoint(context, xOri, yAxis);
			CGContextAddLineToPoint(context, (xOri + validWd), yAxis);
			CGContextStrokePath(context);
			
			// Y方向の線
			CGFloat xAxis = (xSpace * (CGFloat)idx) + xOri;
			CGContextMoveToPoint(context, xAxis, 0);
			CGContextAddLineToPoint(context,xAxis, r.size.height);
			CGContextStrokePath(context);
		}
	}
}

// ガイド線の初期値の取得
- (NSInteger) _getGuideLineNumsInit
{
#ifdef AIKI_CUSTOM
    return (GUIDE_LINE_NUMS_INIT);
#else
    // 整体向けアカウントの場合は初期値はBMKと同じ
    return ( ([AccountManager isAccountManipulative]) ?
            GUIDE_LINE_NUMS_INIT_MANIPULATIVE :
            GUIDE_LINE_NUMS_INIT);
#endif
}

#pragma mark life_cycle

// 初期化
- (id) init
{
	
	if ((self = [super init]) )
	{
		_backgroundImage = nil;
		_guideLineNum = [self _getGuideLineNumsInit];
	}
	
	return (self);
}

// 初期化
- (id)initWithImage:(UIImage *)img
{
	if ((self = [super init]) )
	{
		_backgroundImage = img;
        tempImage = img;
		_guideLineNum = [self _getGuideLineNumsInit];
        imgRect = self.frame;
	}
	
	return (self);
}

// InterfaceBuilderからの初期化
- (void)awakeFromNib
{
	_backgroundImage = nil;
	_guideLineNum = [self _getGuideLineNumsInit];
    imgRect = self.frame;
    
    if ([AccountManager isAccountManipulative])
    {   self.alpha = 0.80f; }
}

- (void)drawRect:(CGRect)rect {
    // Drawing code.
#ifdef DEBUG
	NSLog (@"UIImageView4Camera drawRect");
#endif
	// Contextの取得
	CGContextRef context = UIGraphicsGetCurrentContext();
	// このViewのサイズ
	CGRect r = self.bounds;
	
	// 背景画像とガイド線の描画(透過なし)
	[self drawBackGroundWithContext:context drawRect:r alpha:1.0f
						isWithImage:YES isWithGuideLine:YES];
}

- (void)dealloc
{
	if (_backgroundImage)
	{	
		[_backgroundImage release]; 
		_backgroundImage = nil;
	}
    tempImage = nil;
	
	[super dealloc];
}

#pragma mark public_methods

// 背景画像の設定
- (void) setBackgroundImage:(UIImage*)img
{
	_backgroundImage = img;
    tempImage = img;
	
	// 再描画
	[self setNeedsDisplay];
}

// ガイド線の数の設定
- (void) setGuideLineNums:(NSUInteger)nums
{
	_guideLineNum = nums;
	
	// 再描画
	[self setNeedsDisplay];
}

// 背景画像とガイド線の数の設定
- (void) setBackgroundImageWithGuideLineNums:(UIImage*)img guideLineNums:(NSUInteger)nums
{
	_backgroundImage = img;
    tempImage = img;
	_guideLineNum = nums;
	
	// 再描画
	[self setNeedsDisplay];
}

// 背景画像のリセット
- (void) resetBackgroundImage
{
	if (! _backgroundImage)
	{	return; }
	
	_backgroundImage = nil;
    tempImage = nil;
	
	// 再描画
	[self setNeedsDisplay];
}

// 背景透過画像を一時的に非表示制御を行う
- (void) setBackgroundImageHidden:(BOOL)status
{
    if (status) {
        tempImage = _backgroundImage;
        _backgroundImage = nil;
    } else {
        _backgroundImage = tempImage;
    }
}

// 背景透過画像のフレームサイズ
// (格子線と、背景透過画像のサイズが違う場合も有る為)
- (void)setBackgroundImageRect:(CGRect)rect
{
    imgRect = rect;
}

// 背景画像とガイド線のImage取得（コントロールのalphaによる透過）
- (UIImage*) getOverlayImageWithbackgroud:(BOOL)isImage isWithGuideLine:(BOOL)isGuide
{
	// 本Viewの透過率が0%であれば何もしない
	if (self.alpha <= 0.0f)
	{	return (nil); }
	
	// 背景画像がnilで、ガイド線の本数が0であれば何もしない
	if ( (! _backgroundImage) &&
		 (self.guideLineNum <= 0) )
	{	return (nil); }
	
	// いずれも設定されていない
	if ( (! isImage) && (! isGuide) )
	{	return (nil); }
	
	// このViewのサイズ
	CGRect r = self.bounds;
	
	// グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(r.size);	
	
	// Contextの取得
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// 背景画像とガイド線の描画(コントロールのalphaによる透過)
	[self drawBackGroundWithContext:context drawRect:r alpha:self.alpha
						isWithImage:isImage isWithGuideLine:isGuide];
	
	// Imageを取得
	UIImage* img = UIGraphicsGetImageFromCurrentImageContext();	
	
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
	
	// 取得したUIImageを返す:img= autorelease
	return (img);
}

@end
