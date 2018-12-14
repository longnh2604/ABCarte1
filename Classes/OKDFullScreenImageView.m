//
//  OKDFullScreenImageView.m
//  iPadCamera
//
//  Created by MacBook on 10/09/08.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OKDFullScreenImageView.h"
#import "Common.h"

@implementation OKDFullScreenImageView

// 本画面を消去する
-(void) hideImageViewWithAnimeSet:(BOOL)isAnimation
{
	if (isAnimation)
	{
		// アニメーションの開始
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25];
	}
	
	// [self setFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
	// アニメーションのため、透明にする
	[self setAlpha:0.0f];
	
	if (isAnimation)
	{
		// アニメーションの完了と実行
		[UIView commitAnimations];
	}
	
	// 本体を非表示にする
	self.hidden = YES;
	
	// 本体を最背面へ
	[self sendSubviewToBack:self];
	
	// ステータスバーを表示する
	// [UIApplication sharedApplication].statusBarHidden = NO;
}

// 親Viewを指定して初期化
- (id) initWithParent:(UIView*)parent
{
    if ((self = [self initWithFrame:parent.frame]))
    {
        [parent addSubview:self];
    }
    
    return (self);
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		
		// Image表示の作成
		imgView = [[[UIImageView alloc] initWithFrame:
					CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)] autorelease];
		[imgView setBackgroundColor:[UIColor clearColor]];	// 背景を透明に
		[self addSubview:imgView];
		
		// 選択ボタンの作成
		btnSelected = [UIButton buttonWithType:UIButtonTypeCustom];
		[btnSelected sizeToFit];
		// [btnSelected setFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)];
		[btnSelected addTarget:self action:@selector(onSelectButton) forControlEvents:UIControlEventTouchDown];
		[self addSubview:btnSelected];
		
		// 背景色は黒色
		// [self setBackgroundColor:[UIColor darkTextColor]];
		
		// 初期状態で本体は非表示
		self.hidden = YES;
		[self setAlpha:0.0f];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

// 選択ボタンのClick
-(void)onSelectButton
{
	// 本画面を消去する
	[self hideImageViewWithAnimeSet:YES];
}

// ImageのContenModeの設定
-(void)setImageContentMode:(UIViewContentMode)mode
{
    // [self setContentMode:mode];
    [imgView setContentMode:mode];
}

// Imageの設定
-(void) setImage:(UIImage*)img
{
	imgView.image = img;
	/*NSLog (@ "FullScreenImageView set image image size %f / %f" ,
			imgView.image.size.width, imgView.image.size.height);*/
	
	// 設定されたImageが縦型かを判定
	isImagePortrait = [Common isImagePortrait:img];
	
	// Imageの設定と同時に表示する
	self.hidden = NO;
	
	// 表示更新
	UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
	BOOL isPortrait= (screen.applicationFrame.size.width == 320.0f);
#else
   	BOOL isPortrait= (screen.applicationFrame.size.width == 768.0f);
#endif
	
	[self refresh:isPortrait];
	
	// アニメーションの開始
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.35];
	
	[self setAlpha:1.0f];
	
	// アニメーションの完了と実行
	[UIView commitAnimations];
	
	// 本体を最前面へ
	[self.superview bringSubviewToFront:self];
	
	// ステータスバーを消す
	// [UIApplication sharedApplication].statusBarHidden = YES;
	// [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
}

// 表示更新（画面回転時）
-(void) refresh:(BOOL)isPortrait
{
	// 非表示の場合は更新しない
	if (self.hidden == YES)
	{	return; }
    
#ifdef CALULU_IPHONE
	CGFloat scrWidth  = (isPortrait)? 320.0f : 480.0f;
	CGFloat scrHeigth = (isPortrait)? 460.0f : 300.0f;
#else
    CGFloat scrWidth  = (isPortrait)? 768.0f : 1024.0f;
	CGFloat scrHeigth = (isPortrait)? 1004.0f : 748.0f;
#endif
    
	// 本体のサイズ変更
	[self setFrame:CGRectMake(0.0f, 0.0f, scrWidth, scrHeigth)];
	  
	// ImageViewとボタンのサイズ変更
	CGFloat imgWidth;
	CGFloat imgHeight;
	if (isImagePortrait)
	{
#ifdef CALULU_IPHONE
		// Image縦長： 614 -> 960×(460 / 720)   画像の元サイズ(960×720)
		imgWidth  = (isPortrait)? 614.0f : 480.0f;
		imgHeight = (isPortrait)? 460.0f : 320.0f;
#else
        // Image縦長： 1365 -> 960×(1024 / 720)   画像の元サイズ(960×720)
		imgWidth  = (isPortrait)? 1365.0f : 1024.0f;
		imgHeight = (isPortrait)? 1004.0f : 768.0f;
#endif
	}
	else 
	{
		// Image横長：
#ifdef CALULU_IPHONE
		imgWidth  = (isPortrait)? 320.0f : 480.0f;
		imgHeight = (isPortrait)? 240.0f : 320.0f;
#else
        imgWidth  = (isPortrait)? 640.0f : 1024.0f;
		imgHeight = (isPortrait)? 480.0f : 768.0f;
#endif
	}

	
	CGFloat wm = (scrWidth - imgWidth) / 2.0f;
	CGFloat hm = (scrHeigth - imgHeight) / 2.0f;
	CGRect rect = CGRectMake(wm, hm, imgWidth, imgHeight);
	[btnSelected setFrame:rect];
	[imgView setFrame:rect];
	
	/*NSLog (@ "FullScreenImageView refresh image size %f / %f" ,
		   imgView.image.size.width, imgView.image.size.height);*/
}

// 本画面を消去する
-(void) hideFullScreenImageView
{
	// アニメーションなしで本画面を消去する
	[self hideImageViewWithAnimeSet:NO];
}

- (void)dealloc {
    
	// [btnSelected release];
	
	[super dealloc];
}


@end

@implementation OKDFullScreenFitImageView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // 背景を黒色の透過に
        UIColor *color = [UIColor blackColor];
        UIColor *backColor = [color colorWithAlphaComponent:0.75f];
        [self setBackgroundColor:backColor];
        [imgView setContentMode:UIViewContentModeScaleAspectFit];
    }
    
    return (self);
}

@end
