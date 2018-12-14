    //
//  PictureCompViewController.m
//  iPadCamera
//
//  Created by 管理者 on 11/06/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "iPadCameraAppDelegate.h"

#import "PictureCompViewController.h"
#import "PicturePaintViewController.h"
#import "SelectPictureViewController.h"
#import "DevStatusCheck.h"
#import "model/OKDImageFileManager.h"

// 制御パレットボタンのコマンド（ボタン種別）
typedef enum
{
	PALLET_SEPARATE_ON	= 0,		// 区分線あり
	PALLET_SEPARATE_OFF,			// 区分線なし
	PALLET_LEFT_TURN	= 0x101,	// 左側画像反転
	PALLET_RIGHT_TURN,				// 右側画像反転
	PALLET_SAVE			= 0x201,	// 保存
} PALLET_CTRL_BUTTON;

#define SEL_1ST     YES
#define SEL_2ND     NO

@implementation PictureCompViewController

@synthesize IsSetLayout;
@synthesize IsNavigationCall;
@synthesize IsRotated;
@synthesize _pictImage1;
@synthesize _pictImage2;
@synthesize _pictImageMixed;
@synthesize IsOverlap;
@synthesize IsUpdown;

#pragma mark local_methods

// Viewの角を丸くする
- (void) setCornerRadius:(UIView*)radView
{
	CALayer *layer = [radView layer];
	[layer setMasksToBounds:YES];
	[layer setCornerRadius:12.0f];
}

- (void)showToolbar
{
    vwCtrlPallet.alpha = 1.0f;
	
	[btnToolBarShow setImage:(_isToolBar)? 
	 [UIImage imageNamed:@"toolbar_on.png"] : [UIImage imageNamed:@"toolbar_off.png"]
					forState:UIControlStateNormal];
    vwSynthesisCtrlPallet.alpha = vwCtrlPallet.alpha;
}

#ifdef CALULU_IPHONE

// タイトル、ボタンの位置調整
- (void) _titelButtonLayout:(BOOL)isPortrait
{
    // 縦表示：タイトルとボタン２段表示
    if (isPortrait)
    {
        // 施術日：横サイズを縮小
        viewWorkDateBack.frame = CGRectMake(  5.0f,  4.0f, 135.0f, 24.0f);
        btnLockMode.frame = CGRectMake(  5.0f, 30.0f,  38.0f, 38.0f);
    }
    // 横表示：タイトルとボタン１段表示
    else
    {
        // 施術日：横サイズを大きくして「施術日」のDimを表示
        viewWorkDateBack.frame = CGRectMake(125.0f,  4.0f, 175.0f, 24.0f);
        btnLockMode.frame = CGRectMake(  5.0f,  4.0f,  38.0f, 38.0f);
    }
}

#endif

// 縦横の切り替え
- (void)changeToPortrait:(BOOL)isPortrait initMode:(BOOL)mode
{
#ifdef DEBUG
	NSLog(@"PictureCompViewController - changeToPortrait - isPortrait:%@ initMode:%@",
		  (isPortrait) ? @"YES" : @"NO", (mode) ? @"YES" : @"NO");
#endif
	
	// 編集フラグを保存
	BOOL dirty  = _isDirty;
	
	// 現在の表示設定を保存
	float zoomScale1 = myScrollView1.zoomScale;
	float zoomScale2 = myScrollView2.zoomScale;
	CGPoint contentOffset1 = myScrollView1.contentOffset;
	CGPoint contentOffset2 = myScrollView2.contentOffset;
#ifdef DEBUG
	if (! mode) 
	{
		NSLog(@"- myScrollView1 - X:%.01f Y:%.01f W:H [%.01f :%.01f] zoom:%.01f contentOffset [%.01f:%.01f]",
			  myScrollView1.frame.origin.x, myScrollView1.frame.origin.y, myScrollView1.frame.size.width, myScrollView1.frame.size.height, zoomScale1, contentOffset1.x, contentOffset1.y);
		NSLog(@"- myScrollView2 - X:%.01f Y:%.01f W:H [%.01f :%.01f] zoom:%.01f contentOffset [%.01f:%.01f]",
			  myScrollView2.frame.origin.x, myScrollView2.frame.origin.y, myScrollView2.frame.size.width, myScrollView2.frame.size.height, zoomScale2, contentOffset2.x, contentOffset2.y);
	}
#endif
	// 縦横の切り替え時に表示がおかしくなるので、一旦１倍に戻す
	myScrollView1.zoomScale = 1.0f;
	myScrollView2.zoomScale = 1.0f;
	
	// スクロールViewの位置設定
#ifdef CALULU_IPHONE
	CGFloat posX1 = (isPortrait)?    0.0f :  40.0f;
	CGFloat posX2 = (isPortrait)?  160.0f : 240.0f;
	CGFloat posY = (isPortrait)?   100.0f :   0.0f;
	CGFloat width = (isPortrait)?  160.0f : 200.0f;
	CGFloat height = (isPortrait)? 240.0f : 300.0f;
  	float ratio = (isPortrait)? (240.0f / 300.0f) : (300.0f / 240.0f);
#else
    CGFloat posX1;
	CGFloat posX2 = (isPortrait)? 384.0f : 512.0f;
    CGFloat posY;
    if(self.IsUpdown){
        posX1 = (isPortrait)? 20.0f : 178.0f;
        posY = (isPortrait)? 204.0f : 50.0f;
    }else if(self.IsMorphing){
        posX1 = (isPortrait)? 20.0f : 148.0f;
        posY = (isPortrait)? 254.0f : 110.0f;
    }else{
        posX1 = (isPortrait)? 20.0f : 148.0f;
        posY = (isPortrait)? 254.0f : 70.0f;
    }
	CGFloat width = (isPortrait)? 364.0f : 364.0f;
    CGFloat height;
    CGFloat height2;
    if(self.IsUpdown){
        height = (isPortrait)? 546.0f : 546.0f;
        height2 = (isPortrait)? 696.0f : 696.0f;
    }else{
        height = (isPortrait)? 546.0f : 546.0f;
    }
    float ratio = 1.0f;

#endif
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = (iOSVersion<7.0f || !IsNavigationCall)? 0.0f : 20.0f;
    if (self.IsOverlap) {
        [myScrollView1 setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
        [myScrollView2 setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
        //set default slider value to half
        sldRatio.value = 0.5;
        myScrollView2.alpha = sldRatio.value;
        myScrollView1.alpha = 1.0f - sldRatio.value;
        [backGroundView setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
    }else if(self.IsMorphing){
        if(isPortrait){
            [myScrollView1 setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
            [myScrollView2 setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
            [backGroundView setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
        }else{
            [myScrollView1 setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
            [myScrollView2 setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
            [backGroundView setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
        }
        
        for(UIView* view in self.view.subviews)
        {
            if([view isKindOfClass:[OKDClickImageView class]]){
                OKDClickImageView *imgView = (OKDClickImageView*)view;
                if(isPortrait){
                    if(imgView.frame.origin.y == 70){
                        imgView.frame = CGRectMake(imgView.frame.origin.x - 128.0f, 180, ITEM_WITH_COMP, ITEM_HEIGHT_COMP);
                    }
                }else{
                    if(imgView.frame.origin.y == 180){
                        imgView.frame = CGRectMake(imgView.frame.origin.x + 128.0f, 70, ITEM_WITH_COMP, ITEM_HEIGHT_COMP);
                    }
                }
            }
        }
        
    }else{
        if(self.IsUpdown){
            [myScrollView1 setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height2 / 2 )];
            [myScrollView2 setFrame:CGRectMake(posX1, posY+uiOffset+(height2 / 2), width * 2, height2 / 2 )];
            myScrollView2.alpha = 1;
            [backGroundView setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height2)];
        }else{
            [myScrollView1 setFrame:CGRectMake(posX1, posY+uiOffset, width, height)];
            [myScrollView2 setFrame:CGRectMake(posX2, posY+uiOffset, width, height)];
            myScrollView2.alpha = 1;
            [backGroundView setFrame:CGRectMake(posX1, posY+uiOffset, width * 2, height)];
        }
    }
    
	
	// ImageViewのサイズ設定
	[imgvwPicture1 setFrame:CGRectMake(0.0f, 0.0f, (CGFloat)(width * 2),height)];
	[imgvwPicture2 setFrame:CGRectMake(0.0f, 0.0f, (CGFloat)(width * 2),height)];
	
	// 境界線Viewの位置設定
	// CGFloat posXSeparator = (isPortrait)? 382.0f : 510.0f;
    CGFloat posXSeparator = posX2 - 2.0f;
	[vwSaparete setFrame:CGRectMake(posXSeparator, posY+uiOffset, 4.0f, height)];

    // 突き合わせのときは、透過しないようにする。
    // 突き合わせ時のタップで暗くなるのはimgvwPictureの透過で制御している。
    // 透過のときはmyScrollViewで透過を制御するため、imgvwPictureは透過しないようにする。
    if(!self.IsOverlap) {
        vwSaparete.hidden = self.IsvwSaparate;
//        if(self.IsvwSaparate == NO && _isModeLock == NO) {
//            imgvwPicture1.userInteractionEnabled = YES;
//            imgvwPicture2.userInteractionEnabled = YES;
//        }
        if(self.IsMorphing){
            //myScrollView1.alpha = 0.7f;
            //imgvwPicture1.userInteractionEnabled = YES;
            //imgvwPicture2.userInteractionEnabled = YES;
        }else{
            myScrollView1.alpha = 1.0f;
            myScrollView2.alpha = 1.0f;
        }
    } else {
        vwSaparete.hidden = YES;
        imgvwPicture1.userInteractionEnabled = NO;
        imgvwPicture2.userInteractionEnabled = NO;
        imgvwPicture1.alpha = 1.0f;
        imgvwPicture2.alpha = 1.0f;
    }
    
	// スクロール範囲の設定（これがないとスクロールしない）
	[myScrollView1 setContentSize:imgvwPicture1.frame.size];
	[myScrollView2 setContentSize:imgvwPicture2.frame.size];
	myScrollView1.scrollEnabled = _isModeLock;
	myScrollView2.scrollEnabled = _isModeLock;
	
	if (mode)
	{
		// 最初の表示位置
		myScrollView1.zoomScale = INIT_IMAGE_SCALE;
		myScrollView2.zoomScale = INIT_IMAGE_SCALE;
		myScrollView1.contentOffset = CGPointMake((320.0f * INIT_IMAGE_SCALE - 320.0f) * (width / 320.0f), 
												  (240.0f * INIT_IMAGE_SCALE - 240.0f) * (height / 480.0f));
        if (!IsOverlap && !self.IsMorphing) {
            if(self.IsUpdown){
                myScrollView2.contentOffset = myScrollView1.contentOffset;
            }else{
                myScrollView2.contentOffset = CGPointMake(myScrollView1.contentOffset.x + width, myScrollView1.contentOffset.y);
            }
        }else {
            myScrollView2.contentOffset = myScrollView1.contentOffset;
            if(self.IsMorphing){
                [self OnSetControllView:btnBackOn];
            }else{
                [self OnSetControllView:btnFrontOn];
            }
        }
	}
	else 
	{
		myScrollView1.zoomScale = zoomScale1;
		myScrollView2.zoomScale = zoomScale2;
		
		if (self.IsRotated)
		{
			myScrollView1.contentOffset = CGPointMake(contentOffset1.x * ratio, contentOffset1.y * ratio);
			myScrollView2.contentOffset = CGPointMake(contentOffset2.x * ratio, contentOffset2.y * ratio);
			self.IsRotated = NO;
		}
		else 
		{
			myScrollView1.contentOffset = CGPointMake(contentOffset1.x, contentOffset1.y);
			myScrollView2.contentOffset = CGPointMake(contentOffset2.x, contentOffset2.y);
		}
	}
#ifdef DEBUG
    NSLog(@"- myScrollView1 - X:%.01f Y:%.01f W:H [%.01f :%.01f] zoom:%.01f contentOffset [%.01f:%.01f]",
          myScrollView1.frame.origin.x, myScrollView1.frame.origin.y, myScrollView1.frame.size.width, myScrollView1.frame.size.height, zoomScale1, contentOffset1.x, contentOffset1.y);
    NSLog(@"- myScrollView2 - X:%.01f Y:%.01f W:H [%.01f :%.01f] zoom:%.01f contentOffset [%.01f:%.01f]",
          myScrollView2.frame.origin.x, myScrollView2.frame.origin.y, myScrollView2.frame.size.width, myScrollView2.frame.size.height, zoomScale2, contentOffset2.x, contentOffset2.y);
#endif


	//　制御パレットの位置調整
    CGFloat ofs = (IsOverlap || self.IsMorphing)? (vwSynthesisCtrlPallet.frame.size.width - vwCtrlPallet.frame.size.width) / 2.0f : 0.0f;
#ifdef CALULU_IPHONE
	CGPoint origin = (isPortrait) ? CGPointMake(66.0f - ofs, 414.0f) : CGPointMake(146.0f - ofs, 254.0f);
#else
    CGPoint origin;
    if (IsUpdown){
        origin = (isPortrait) ? CGPointMake(304.0f - ofs, 924.0f + uiOffset) : CGPointMake(10.0f - ofs, self.view.frame.size.height/2 + uiOffset);
    }else{
        origin = (isPortrait) ? CGPointMake(304.0f - ofs, 924.0f + uiOffset) : CGPointMake(432.0f - ofs, 668.0f + uiOffset);
    }
#endif
    if (IsOverlap) {
        vwSynthesisCtrlPallet.hidden = NO;
        vwCtrlPallet.hidden = YES;
        btnSeparateOn.hidden = YES;
        btnSeparateOff.hidden = YES;
        btnBackOn.hidden = NO;
        btnFrontOn.hidden = NO;
        btnBackOn.enabled = NO;
        btnFrontOn.enabled = NO;
        btnLeftTurn2.hidden = NO;
        btnRightTurn2.hidden = NO;
        btnLeftTurn2.enabled = NO;
        btnRightTurn2.enabled = NO;
    }else if(self.IsMorphing){
        vwSynthesisCtrlPallet.hidden = NO;
        vwCtrlPallet.hidden = YES;
        btnSeparateOn.hidden = YES;
        btnSeparateOff.hidden = YES;
        btnBackOn.hidden = YES;
        btnFrontOn.hidden = YES;
        btnBackOn.enabled = NO;
        btnFrontOn.enabled = NO;
        btnLeftTurn2.hidden = YES;
        btnRightTurn2.hidden = YES;
        btnLeftTurn2.enabled = NO;
        btnRightTurn2.enabled = NO;
    }else{
        vwSynthesisCtrlPallet.hidden = YES;
        vwCtrlPallet.hidden = NO;
        btnSeparateOn.hidden = NO;
        btnSeparateOff.hidden = NO;
    }
	[vwCtrlPallet setFrame:CGRectMake(origin.x, origin.y, vwCtrlPallet.frame.size.width, vwCtrlPallet.frame.size.height)];
    
//    MainViewController *mainVC
//    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    if(self.IsMorphing){
        [vwSynthesisCtrlPallet setFrame:CGRectMake(backGroundView.frame.origin.x, origin.y,
                                                   backGroundView.frame.size.width, vwSynthesisCtrlPallet.frame.size.height)];
        //[sldRatio setFrame:CGRectMake((vwSynthesisCtrlPallet.frame.size.width/2)-(sldRatio.frame.size.width/2), sldRatio.frame.origin.y,
         //                            sldRatio.frame.size.width, sldRatio.frame.size.height)];
        [sldRatio setFrame:CGRectMake(0, sldRatio.frame.origin.y-35,
                                      backGroundView.frame.size.width, sldRatio.frame.size.height+60)];
        
        
//        mainVC->preventScroll = YES;
        
    }else{
        [vwSynthesisCtrlPallet setFrame:CGRectMake(origin.x, origin.y,
                                               vwSynthesisCtrlPallet.frame.size.width, vwSynthesisCtrlPallet.frame.size.height)];
        
        [sldRatio setFrame:CGRectMake(135, 28, 457, 29)];
        sldRatio.enabled = NO;
        
//        mainVC->preventScroll = NO;
    }
    
    [btnLockMode setFrame: (isPortrait)?
     CGRectMake(20, 10+uiOffset, 54, 54) :
     CGRectMake(20, 10+uiOffset, 54, 54)];
    [viewWorkDateBack setFrame: (isPortrait)?
     CGRectMake(126, 12+uiOffset, 310, 30) :
     CGRectMake(126 + 256, 12+uiOffset, 310, 30) ];
    [viewUserNameBack setFrame: (isPortrait)?
     CGRectMake(461, 12+uiOffset, 287, 30) :
     CGRectMake(461 + 256, 12+uiOffset, 287, 30)];
    
	// 制御パレット表示ボタン
//	btnToolBarShow.hidden = (isPortrait)? YES : NO;
    btnToolBarShow.hidden = YES;

	// 制御パレット
	if (isPortrait) 
	{
		vwCtrlPallet.alpha = 1.0f;
	}
	else
	{
		_isToolBar = NO;
		[self showToolbar];
	}
	
    vwSynthesisCtrlPallet.alpha = vwCtrlPallet.alpha;
    
	// 画面遷移及び回転時はお客様名関連を最前面へ
	[self.view bringSubviewToFront:viewUserNameBack];
	[self.view bringSubviewToFront:viewWorkDateBack];
	
	// 編集フラグを戻す
	_isDirty = dirty;
    
#ifdef CALULU_IPHONE
    // タイトル、ボタンの位置調整
    [self _titelButtonLayout:isPortrait];
#endif
}

// デバイスの向きがポートレートかどうかを取得
- (bool)getPortrait
{
	bool ret = YES;
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch (orientation) 	
	{
			// 横
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
			ret = NO;
			break;
			// 縦
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        default:
			break;
    }
	
	return (ret);
}

// 画像カット区域の計算
// TODO:ソース整理を行う
- (CGRect)calcCutRect:(CGFloat)zoom Offset:(CGPoint)offset scrViewSize:(CGSize)scrSize imgSize:(CGSize)imgSize
{
    CGRect rect;
    
    BOOL isPortlate = (imgSize.height*4 > imgSize.width*3)? YES : NO;
    float wBase = (IsOverlap)? 1.0f : 2.0f;
    float scale = scrSize.height / imgSize.height;
#ifdef DEBUG
    NSLog(@"of % 4.2f :% 4.2f (% 4.2f:% 4.2f)[% 4.2f:% 4.2f]",
          offset.x, offset.y, offset.x/zoom, offset.y/zoom, scrSize.width, scrSize.height);
    NSLog(@"pic [% 4.2f:% 4.2f]", imgSize.width, imgSize.height);
#endif
    
    // ------------------------------
    // 画像の切り抜き
    CGFloat vWidth = (imgSize.width / wBase) * 728 / (imgSize.height * 4 / 3);  // 初期状態で表示されている幅

    CGFloat cutW1 = scrSize.width / zoom;       // ズーム後のview幅
    // 画像のクリップ幅の決定 (offset1.xが画像の左余白サイズを超えていないか or 超えているか)
    // 超えている=左側クリップとなり、クリップ幅はズーム後のview幅となる
    cutW1 = (offset.x/zoom<(728/wBase-vWidth))?
    cutW1 - ((728/wBase-vWidth) - offset.x/zoom) : cutW1;
    
    // クリップ開始位置の計算
    CGFloat posH1;
    if (((728/wBase)-vWidth-(offset.x/zoom))<0) {
        // 左側クリップされる場合
        posH1 = (728/wBase-vWidth)-((728/wBase)-vWidth-(offset.x/zoom));
    } else {
        posH1 = 728/wBase-vWidth;
    }
    if (isPortlate)
    {   // 合成画像がポートレートサイズの場合
        CGFloat tw = 546 * imgSize.width / imgSize.height;  // View内での幅
        CGFloat tx = (728 - tw) / 2;                        // 片側の余白部分の幅
//        offset.x = (offset.x > 0)? offset.x - tx : 0;      // 左側への移動が余白内に収まっていれば、オフセットは0
        cutW1    = ((tx + offset.x) < 0)? tw + (tx + offset.x) :    // 右側への移動が余白を超えていれば超えた分をカット
                    (offset.x > tx)?      tw - (offset.x - tx) : tw;// 左側への移動が余白を超えていても超えた分をカット
        offset.x += tx;
        posH1 = ((imgSize.height*4/3)-imgSize.width)/2;
    } else {
        posH1 = 0;
    }

    if (!IsOverlap) {
        rect = CGRectMake((CGFloat)(posH1 / INIT_IMAGE_SCALE / scale),
                          (CGFloat)(offset.y / zoom / scale),
                          cutW1 / INIT_IMAGE_SCALE / scale,
                          scrSize.height / zoom / scale);
    } else {
        rect = CGRectMake((CGFloat)(offset.x / zoom / scale),
                          (CGFloat)(offset.y / zoom / scale),
                          cutW1 / zoom / scale,
                          scrSize.height / zoom / scale);
    }

    return rect;
}

#ifndef OLD_COMBINED
// Imageの合成
- (void)makeCombinedImage
{
    UIImage* imgOrigin1 = imgvwPicture1.image;
    UIImage* imgOrigin2 = imgvwPicture2.image;
    // 元画像がPortrait or Landscape
    //    BOOL portRait1 = (imgOrigin1.size.height*4 > imgOrigin1.size.width*3)? YES : NO;
    //    BOOL portRait2 = (imgOrigin2.size.height*4 > imgOrigin2.size.width*3)? YES : NO;
    float wBase = (IsOverlap)? 1.0f : 2.0f;
    if (IsUpdown)wBase = 1.0f;
    float hBase = (IsUpdown)? 2.0f : 1.0f;
    float updownHscale = 546.0f / 696.0f;
    //float scale1h = myScrollView1.frame.size.height * hBase / imgOrigin1.size.height+(150/myScrollView1.frame.size.height * hBase / imgOrigin1.size.height);
    float scale1h = myScrollView1.frame.size.height * hBase / (imgOrigin1.size.height);
    float scale1w = myScrollView1.frame.size.width * wBase / imgOrigin1.size.width;
    float scale2h = myScrollView2.frame.size.height * hBase / (imgOrigin2.size.height);
    float scale2w = myScrollView2.frame.size.width * wBase / imgOrigin2.size.width;
    CGPoint offset1 = myScrollView1.contentOffset;
    CGPoint offset2 = myScrollView2.contentOffset;
#ifdef DEBUG
    NSLog(@"of1 % 4.2f :% 4.2f (% 4.2f:% 4.2f)[% 4.2f:% 4.2f]",
          offset1.x, offset1.y, offset1.x/myScrollView1.zoomScale, offset1.y/myScrollView1.zoomScale, myScrollView1.frame.size.width, myScrollView1.frame.size.height);
    NSLog(@"of2 % 4.2f :% 4.2f", offset2.x, offset2.y);
    NSLog(@"pic1 [% 4.2f:% 4.2f]", picOrgSize1.width, picOrgSize1.height);
#endif
    // ------------------------------
    // 画像1の切り抜き
    CGFloat vWidth = (picOrgSize1.width / wBase) * 728 / (picOrgSize1.height * 4 / 3);  // 初期状態で表示されている幅
    CGFloat cutW1 = myScrollView1.frame.size.width / myScrollView1.zoomScale;       // ズーム後のview幅
    // 画像のクリップ幅の決定 (offset1.xが画像の左余白サイズを超えていないか or 超えているか)
    // 超えている=左側クリップとなり、クリップ幅はズーム後のview幅となる
    if (!IsOverlap)
    {
        //        cutW1 = (offset1.x/myScrollView1.zoomScale<(728*0.5-vWidth))?
        //                cutW1 - ((728*0.5-vWidth) - offset1.x/myScrollView1.zoomScale) : cutW1;
    }
    
    // クリップ開始位置の計算
    CGFloat posH1;
    if (((728/wBase)-vWidth-(offset1.x/myScrollView1.zoomScale))<0) {
        // 左側クリップされる場合
        posH1 = (728/wBase-vWidth)-((728/wBase)-vWidth-(offset1.x/myScrollView1.zoomScale));
    } else {
        posH1 = 728/wBase-vWidth;
        posH1 = offset1.x/myScrollView1.zoomScale;
    }
    CGRect rect;
    if (!IsOverlap) {
        if (self.IsUpdown){
            rect = CGRectMake((CGFloat)(posH1 / INIT_IMAGE_SCALE / scale1w),
                              (CGFloat)(offset1.y / updownHscale / myScrollView1.zoomScale / scale1h),
                              cutW1 / INIT_IMAGE_SCALE / scale1w,
                              myScrollView1.frame.size.height / updownHscale / myScrollView1.zoomScale / scale1h);
        }else{
            rect = CGRectMake((CGFloat)(posH1 / INIT_IMAGE_SCALE / scale1w),
                              (CGFloat)(offset1.y / myScrollView1.zoomScale / scale1h),
                              cutW1 / INIT_IMAGE_SCALE / scale1w,
                              myScrollView1.frame.size.height / myScrollView1.zoomScale / scale1h);
        }

        //}
    } else {
        rect = CGRectMake((CGFloat)(offset1.x / myScrollView1.zoomScale / scale1w),
                          (CGFloat)(offset1.y / myScrollView1.zoomScale / scale1h),
                          cutW1 / INIT_IMAGE_SCALE / scale1w,
                          myScrollView1.frame.size.height / myScrollView1.zoomScale / scale1h);
    }
    CGImageRef cgImage1 = CGImageCreateWithImageInRect(imgOrigin1.CGImage, rect);
    UIImage* img1 = [UIImage imageWithCGImage:cgImage1];
    CGImageRelease(cgImage1);
    //[imgResize1 release];
//#ifdef DEBUG
    NSLog(@"im1 (% 5.2f:% 5.2f / % 5.2f:% 5.2f)",
          (CGFloat)(offset1.x / myScrollView1.zoomScale / scale1w),
          (CGFloat)(offset1.y / myScrollView1.zoomScale / scale1h),
          myScrollView1.frame.size.width / myScrollView1.zoomScale / scale1w,
          myScrollView1.frame.size.height / myScrollView1.zoomScale / scale1h);
    NSLog(@"im1-clip z(%.04f :%.04f : %.02f) [%.02f : %.02f / %.02f : %.02f]",
          scale1h, scale1w, myScrollView1.zoomScale, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    NSLog(@"%.02f : %.02f", img1.size.width, img1.size.height);
//#endif
    
    // 画像2の切り抜き
    CGFloat cutW2;
    if (!IsOverlap) {
        if (self.IsUpdown){
            cutW2 = ((picOrgSize2.width / wBase) * 728) / (picOrgSize2.height * 4 / 3.38) +
            (728*0.5 - offset2.x*INIT_IMAGE_SCALE/myScrollView2.zoomScale);
            cutW2 = (cutW2*myScrollView2.zoomScale/INIT_IMAGE_SCALE>(728/wBase))? (728/wBase*INIT_IMAGE_SCALE/myScrollView2.zoomScale) : cutW2;
        }else{
            cutW2 = ((picOrgSize2.width / wBase) * 728) / (picOrgSize2.height * 4 / 3) +
            (728*0.5 - offset2.x*INIT_IMAGE_SCALE/myScrollView2.zoomScale);
            cutW2 = (cutW2*myScrollView2.zoomScale/INIT_IMAGE_SCALE>(728/wBase))? (728/wBase*INIT_IMAGE_SCALE/myScrollView2.zoomScale) : cutW2;
        }
    } else {
        cutW2 = ((picOrgSize2.width / 1) * 728) / (picOrgSize2.height * 4 / 3) +
        (728*0.5 - offset2.x*INIT_IMAGE_SCALE/myScrollView2.zoomScale);
        cutW2 = (cutW2*myScrollView2.zoomScale/INIT_IMAGE_SCALE>(728/1))? (728/1*INIT_IMAGE_SCALE/myScrollView2.zoomScale) : cutW2;
    }
    //    CGFloat posH2 = offset2.x;
    CGRect rect2;
    if (self.IsUpdown){
        rect2 = CGRectMake((CGFloat)(offset2.x / myScrollView2.zoomScale / scale2w),
                           (CGFloat)(offset2.y / updownHscale / myScrollView2.zoomScale / scale2h),
                           cutW2 / updownHscale / INIT_IMAGE_SCALE /scale2h,
                           myScrollView2.frame.size.height / updownHscale / myScrollView2.zoomScale / scale2h);
    }else{
        rect2 = CGRectMake((CGFloat)(offset2.x / myScrollView2.zoomScale / scale2w),
                           (CGFloat)(offset2.y / myScrollView2.zoomScale / scale2h),
                           cutW2 / INIT_IMAGE_SCALE /scale2h,
                           myScrollView2.frame.size.height / myScrollView2.zoomScale / scale2h);
    }
    //}
    CGImageRef cgImage2 = CGImageCreateWithImageInRect(imgOrigin2.CGImage, rect2);
    UIImage* img2 = [UIImage imageWithCGImage:cgImage2];
    CGImageRelease(cgImage2);
    //[imgResize2 release];
//#ifdef DEBUG
    NSLog(@"im2-clip z(%.04f :%.04f : %.02f) [%.01f : %.01f / %.01f : %.01f]",
          scale2h, scale2w, myScrollView2.zoomScale, rect2.origin.x, rect2.origin.y, rect2.size.width, rect2.size.height);
//#endif
    
    // 合成後に大きいサイズの画像がどちらか？ (縮小されていた場合、オリジナルサイズで比較する。)
    CGFloat t1h = (myScrollView1.zoomScale<1.0)? imgOrigin1.size.height : rect.size.height;
    CGFloat t2h = (myScrollView2.zoomScale<1.0)? imgOrigin2.size.height : rect2.size.height;
    BOOL bigImg = (t1h >= t2h)? YES : NO;
    CGFloat hdHeight;
    if(self.IsUpdown){
        hdHeight = ((bigImg)? (imgOrigin1.size.height / updownHscale) : (imgOrigin2.size.height / updownHscale))/INIT_IMAGE_SCALE;
    }else{
        hdHeight = ((bigImg)? imgOrigin1.size.height : imgOrigin2.size.height)/INIT_IMAGE_SCALE;
    }
    if (IsUpdown) {
        hdHeight = hdHeight / 2;
    }
    CGFloat hdWidth  = ((bigImg)? (imgOrigin1.size.height * 4 / 3)  : (imgOrigin2.size.height * 4 / 3))/INIT_IMAGE_SCALE;
    CGFloat height;
    CGFloat width, combHpos, r2width, comX, comY, com2X, com2Y, comHeight, com2Height;
    CGFloat comXt;  // 透過合成時の +方向への移動距離
    CGFloat com2Xt;  // 透過合成時の +方向への移動距離
    
    if (IsOverlap)
    {   // ===== 透過合成の場合 =====
        
        if (bigImg) {   // image1側が大きい場合
            CGFloat tmpScale = myScrollView1.zoomScale;
            // 透過合成用
            comX = (rect.origin.x<0)? rect.origin.x*-1 : 0; // 右側にスクロールされて画像範囲外が見えているか
            comX = (myScrollView1.zoomScale<1.0f)? comX * myScrollView1.zoomScale : comX;
            // ----------
            
            comY = (rect.origin.y<0)? rect.origin.y*-1 : 0; // 下側にスクロールされて画像範囲外が見えているか
            comY = (myScrollView1.zoomScale<1.0f)? comY * myScrollView1.zoomScale : comY;
            if (rect.size.height > hdHeight) {  // 画像が縮小されていた場合
                height = hdHeight;
                width = hdWidth;
                if(rect.origin.y>0) {
                    // 上側がクリップされ、下側に余白がつく場合
                    comHeight = height - ((rect.origin.y + (rect.size.height-height)))*myScrollView1.zoomScale;
                } else if ((rect.size.height-fabs(rect.origin.y))<imgOrigin1.size.height) {
                    // 下側がクリップされ、上側に余白がつく場合
                    comHeight = height - comY;
                } else {
                    // 上下に余白がつく場合
                    comHeight = hdHeight * (hdHeight / rect.size.height);
                }
                if(rect.origin.x>0) {
                    // 左側がクリップされ、右側に余白がつく場合
                    combHpos = width - ((rect.origin.x + (rect.size.width-width)))*myScrollView1.zoomScale;
                } else if ((rect.size.width-fabs(rect.origin.x))<imgOrigin1.size.width) {
                    // 右側がクリップされ、左側に余白がつく場合
                    combHpos = width - comX;
                } else {
                    // 左右に余白がつく場合
                    combHpos = hdWidth * (hdWidth / rect.size.width);
                }
                //                combHpos = rect.size.width * myScrollView1.zoomScale;
                tmpScale = INIT_IMAGE_SCALE;
            } else {
                height = rect.size.height;
                width = rect.size.width;
                comHeight = img1.size.height;
                combHpos  = img1.size.width;
                
                comXt = 0;
            }
            // 透過合成用
            com2X = (rect2.origin.x<0)? rect2.origin.x*-1 : 0;  // 右側にスクロールされて画像範囲外が見えているか
            com2X = com2X * scale2w / scale1w * myScrollView2.zoomScale / tmpScale;
            com2Xt = (rect2.origin.x<0)? 0 : (offset2.x / myScrollView2.zoomScale / scale2w) * scale2w / scale1w * myScrollView2.zoomScale / tmpScale;
            com2Xt = 0;
            // ----------
            com2Y = (rect2.origin.y<0)? rect2.origin.y*-1 : 0;  // 下側にスクロールされて画像範囲外が見えているか
            com2Y = com2Y * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
            if ((rect2.size.height+rect2.origin.y)<imgOrigin2.size.height) {
                if (myScrollView2.zoomScale<1) {
                    com2Height = (rect2.size.height+rect2.origin.y) * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                } else {
                    com2Height = height-com2Y;
                }
            } else if (rect2.origin.y>0) {
                com2Height = (imgOrigin2.size.height-rect2.origin.y) * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
            } else {
                com2Height = (imgOrigin2.size.height) * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
            }
            
            if ((rect2.size.width+rect2.origin.x)<imgOrigin2.size.width) {
                if (myScrollView2.zoomScale<1) {
                    r2width = (rect2.size.width+rect2.origin.x) * scale2w / scale1w * myScrollView2.zoomScale / tmpScale;
                } else {
                    r2width = width-com2X;
                }
            }
            else if (rect2.origin.x>0) {
                r2width = (imgOrigin2.size.width-rect2.origin.x) * scale2w / scale1w * myScrollView2.zoomScale / tmpScale;
            } else {
                // クリップされていない場合の高さ
                CGFloat tmpH = (imgOrigin2.size.height) * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                r2width = rect2.size.width * tmpH / rect2.size.height;
            }
            
        } else {        // image2側が大きい場合
            CGFloat tmpScale = myScrollView2.zoomScale;
            // 透過合成用
            com2X = (rect2.origin.x<0)? rect2.origin.x*-1 : 0;
            com2X = (myScrollView2.zoomScale<1.0f)? com2X * myScrollView2.zoomScale : com2X;
            // ----------
            com2Y = (rect2.origin.y<0)? rect2.origin.y*-1 : 0;
            com2Y = (myScrollView2.zoomScale<1.0f)? com2Y * myScrollView2.zoomScale : com2Y;
            
            if (rect2.size.height > hdHeight) { // 画像が縮小されていた場合
                height = hdHeight;
                width = hdWidth;
                if(rect2.origin.y>0) {
                    // 上側がクリップされ、下側に余白がつく場合
                    com2Height = height - ((rect2.origin.y + (rect2.size.height-height)))*myScrollView2.zoomScale;
                } else if ((rect2.size.height-fabs(rect2.origin.y))<imgOrigin2.size.height) {
                    // 下側がクリップされ、上側に余白がつく場合
                    com2Height = height - com2Y;
                } else {
                    // 上下に余白がつく場合
                    com2Height = height * (height / rect2.size.height);
                }
                if(rect2.origin.x>0) {
                    // 左側がクリップされ、右側に余白がつく場合
                    r2width = width - ((rect2.origin.x + (rect2.size.width-width)))*myScrollView2.zoomScale;
                } else if ((rect2.size.width-fabs(rect2.origin.x))<imgOrigin2.size.width) {
                    // 右側がクリップされ、左側に余白がつく場合
                    r2width = width - com2X;
                } else {
                    // 左右に余白がつく場合
                    r2width = hdWidth * (hdWidth / rect2.size.width);
                }
                tmpScale = INIT_IMAGE_SCALE;
            } else {                            // 画像が等倍 or 拡大されていた場合
                height = rect2.size.height;
                width = rect2.size.width;
                com2Height = img2.size.height;
                r2width  = img2.size.width;
                
            }
            // 透過合成用
            comX = (rect.origin.x<0)? rect.origin.x*-1 : 0;  // 下側にスクロールされて画像範囲外が見えているか
            comX = comX * scale1w / scale2w * myScrollView1.zoomScale / tmpScale;
            comXt = 0;
            // ----------
            comY = (rect.origin.y<0)? rect.origin.y*-1 : 0;
            comY = comY * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
            
            if ((rect.size.height+rect.origin.y)<imgOrigin1.size.height) {
                if (myScrollView1.zoomScale<1) {
                    comHeight = (rect.size.height+rect.origin.y) * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
                } else {
                    comHeight = height-comY;
                }
            } else if (rect.origin.y>0) {
                comHeight = (imgOrigin1.size.height-rect.origin.y) * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
            } else {
                comHeight = (imgOrigin1.size.height) * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
            }
            
            if ((rect.size.width+rect.origin.x)<imgOrigin1.size.width) {
                if (myScrollView1.zoomScale<1) {
                    combHpos = (rect.size.width+rect.origin.x) * scale1w / scale2w * myScrollView1.zoomScale / tmpScale;
                } else {
                    combHpos = width-comX;
                }
            }
            else if (rect.origin.x>0) {
                combHpos = (imgOrigin1.size.width-rect.origin.x) * scale1w / scale2w * myScrollView1.zoomScale / tmpScale;
            } else {
                // クリップされていない場合の高さ
                CGFloat tmpH = (imgOrigin1.size.height) * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
                combHpos = rect.size.width * tmpH / rect.size.height;
            }
        }
    }
    else
    {   // ===== 突き合わせ合成の場合 =====
            if (bigImg) {   // image1側が大きい場合
                CGFloat tmpScale = myScrollView1.zoomScale;
                comX = (offset1.x<0)? (offset1.x / myScrollView1.zoomScale / scale1w)*-1 : 0;
                comX = (offset1.x<0)? fabs(offset1.x)  / scale1w: 0;
                comX = comX * myScrollView1.zoomScale;
                comY = (rect.origin.y<0)? rect.origin.y*-1 : 0; // 下側にスクロールされて画像範囲外が見えているか
                comY = comY * myScrollView1.zoomScale;
                // 透過合成用
                comX = (rect.origin.x<0)? rect.origin.x*-1 : 0; // 右側にスクロールされて画像範囲外が見えているか
                comX = (myScrollView1.zoomScale<1.0f)? comX * myScrollView1.zoomScale : comX;
                // ----------
                
                comY = (rect.origin.y<0)? rect.origin.y*-1 : 0; // 下側にスクロールされて画像範囲外が見えているか
                comY = (myScrollView1.zoomScale<1.0f)? comY * myScrollView1.zoomScale : comY;
                if (rect.size.height > hdHeight) {  // 画像が縮小されていた場合
                    height = hdHeight;
                    width = hdWidth;
                    if(rect.origin.y>0) {
                        // 上側がクリップされ、下側に余白がつく場合
                        
                        if (IsUpdown){
//                            NSLog(@"vaoo cai nay");
//                            NSLog(@"height = %f rect.origin.y = %f recsize height = %f updown = %f scrollzom = %f",height,rect.origin.y,rect.size.height,updownHscale,myScrollView1.zoomScale);
//                            NSLog(@"doan 2 = %f",(rect.size.height-height*2 * updownHscale));
//                            if ((rect.origin.x + rect.origin.y)*-1 > height) {
//                                comHeight = height - comY;
//                            } else {
                                comHeight = (height - ((rect.origin.y + (rect.size.height-height*2 * updownHscale)))*myScrollView1.zoomScale)*scale1h;
//                            }
                        }else{
                            comHeight = height - ((rect.origin.y + (rect.size.height-height)))*myScrollView1.zoomScale;
                        }
                    } else if ((rect.size.height-fabs(rect.origin.y))<imgOrigin1.size.height) {
                        // 下側がクリップされ、上側に余白がつく場合
                        comHeight = height - comY;
                        /*
                        if (IsUpdown){
                            comHeight = height / 2 - comY;
                        }else{
                            comHeight = height - comY;
                        }*/
                    } else {
                        // 上下に余白がつく場合
                        if (IsUpdown){
                            comHeight = (hdHeight * ((hdHeight * 2 * updownHscale) / rect.size.height));
                        }else{
                            comHeight = hdHeight * (hdHeight / rect.size.height);
                        }
                    }
                    
                    if (rect.origin.x>0) {
                        // 左側がクリップされ、右側に余白がつく場合
                        combHpos = img1.size.width * myScrollView1.zoomScale;
                    } else if ((rect.size.width-fabs(rect.origin.x))<imgOrigin1.size.width) {
                        // 右側がクリップされ、左側に余白がつく場合
                        if (IsUpdown){
                            combHpos = width - comX;
                        }else{
                            combHpos = width/2 - comX;
                        }
                    } else {
                        // 左右に余白がつく場合
                        if (IsUpdown){
                            combHpos = hdWidth * ((hdWidth) / rect.size.width);
                        }else{
                            combHpos = (hdWidth/2) * ((hdWidth) / rect.size.width);
                        }
                    }
                    tmpScale = INIT_IMAGE_SCALE;
                } else {
                    if (IsUpdown){
                        //height = rect.size.height;
                        height = rect.size.height;
                        width = rect.size.width;
                    }else{
                        height = rect.size.height;
                        width = rect.size.width*2;
                    }
                    if (myScrollView1.zoomScale>1.0) {  // 拡大表示時
                        // スクロールの結果下側の画像範囲外が見えている場合
                        if ((rect.size.height+rect.origin.y)>imgOrigin1.size.height) {
                            comHeight = height - ((rect.size.height+rect.origin.y)-imgOrigin1.size.height);
                        } else{
                            comHeight = height - comY;  // 上側の画像範囲外が見えている場合の補正
                                  }
                    } else {                            // 等倍or縮小表示時
                        if (IsUpdown){
                            if ((rect.size.height+rect.origin.y)>imgOrigin1.size.height) {
                                comHeight = ((myScrollView1.frame.size.height / updownHscale / myScrollView1.zoomScale) / scale1h) - ((rect.size.height+rect.origin.y)-imgOrigin1.size.height);
                            }else{
                                if (offset1.y < 0) {
                                    comHeight = (myScrollView1.frame.size.height / updownHscale - (fabs(offset1.y)) / updownHscale) / myScrollView1.zoomScale / scale1h;
                                }else{
                                    comHeight = myScrollView1.frame.size.height / updownHscale / myScrollView1.zoomScale / scale1h;
                                }
                            }
                        }else{
                            comHeight = (myScrollView1.frame.size.height - fabs(offset1.y)) / myScrollView1.zoomScale / scale1h;
                        }
                    }
                    combHpos = width;
                    combHpos = img1.size.width;
                }

                com2Y = (rect2.origin.y<0)? rect2.origin.y*-1 : 0;  // 下側にスクロールされて画像範囲外が見えているか
                com2Y = com2Y * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                if (IsUpdown){
                    com2Y += height;
                }
                com2X = (rect2.origin.x<0)? rect2.origin.x*-1 : 0;
                com2X = com2X * scale2w / scale1w * myScrollView2.zoomScale / tmpScale;
                if (!IsUpdown){
                    com2X += width/2;
                }
                if ((rect2.size.height+rect2.origin.y)<imgOrigin2.size.height)
                {   // 下側に移動して、クリップされている
                    if (myScrollView2.zoomScale<1)
                    {   // 縮小されている場合
                        NSLog(@"vao cai nay");
                        com2Height = (rect2.size.height+rect2.origin.y) * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                    } else {
                        if (IsUpdown){
                            com2Height = height*2-com2Y;
                        }else{
                            com2Height = height-com2Y;
                        }
                    }
                } else if (rect2.origin.y>0) {
                    com2Height = (imgOrigin2.size.height-rect2.origin.y) * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                } else {
                    if (IsUpdown){
                        com2Height = imgOrigin2.size.height * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                    }else{
                        com2Height = (imgOrigin2.size.height) * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                    }
                }
                
                if (IsUpdown) {
                    r2width = img2.size.width * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                }else{
                    r2width = rect2.size.width * scale2h / scale1h * myScrollView2.zoomScale / tmpScale;
                    r2width -= (com2X - width/2);
                }
                
                if (IsUpdown) {
                    height = height * 2;
                }
                //            width += r2width;
            } else {        // image2側が大きい場合
                CGFloat tmpScale = myScrollView2.zoomScale;
                com2Y = (rect2.origin.y<0)? rect2.origin.y*-1 : 0;
                com2Y = com2Y * myScrollView2.zoomScale;
                if (rect2.size.height > hdHeight) { // 画像が縮小されていた場合
                    height = hdHeight;
                    width = hdWidth;
                    if(rect2.origin.y>0) {
                        // 上側がクリップされ、下側に余白がつく場合
                        if (IsUpdown){
                            NSLog(@"vao cai nay duoi");
                            NSLog(@"height = %f",height);
                            NSLog(@"rect2 y = %f",rect2.origin.y);
                            NSLog(@"rect2 h = %f",rect2.size.height);
                            NSLog(@"updown = %f",updownHscale);
                            NSLog(@"zoomscale = %f",myScrollView2.zoomScale);
//                            if (rect2.origin.x < 0) {
//                                com2Height = height - com2Y;
//                            } else {
                                com2Height = (height - ((rect2.origin.y + (rect2.size.height-(height * 2 * updownHscale))))*myScrollView2.zoomScale)*scale2h;
//                            }
                        }else{
                            com2Height = height - ((rect2.origin.y + (rect2.size.height-height)))*myScrollView2.zoomScale;
                        }
                    } else if ((rect2.size.height-fabs(rect2.origin.y))<imgOrigin2.size.height) {
                        // 下側がクリップされ、上側に余白がつく場合
                        com2Height = height - com2Y;
                    } else {
                        // 上下に余白がつく場合

                        if (IsUpdown){
                            com2Height = height * ((height * 2 * updownHscale) / rect2.size.height);
                        }else{
                            com2Height = height * (height / rect2.size.height);
                        }
                    }
                    if (rect2.origin.x>0) {
                        // 左側がクリップされ、右側に余白がつく場合
                        r2width = img2.size.width*myScrollView2.zoomScale;
                    } else if ((rect2.size.width-fabs(rect2.origin.x))<imgOrigin2.size.width) {
                        // 右側がクリップされ、左側に余白がつく場合
                        r2width = img2.size.width * myScrollView2.zoomScale;
                    } else {
                        // 左右に余白がつく場合
                        if (IsUpdown){
                            r2width = width * hdHeight / rect2.size.height;
                        }else{
                            r2width = rect2.size.width * hdHeight / rect2.size.height;
                        }
                    }
                    if (IsUpdown){
                        com2Y += height;
                    }
                    tmpScale = INIT_IMAGE_SCALE;
                } else {                            // 画像が等倍 or 拡大されていた場合
                    height = rect2.size.height;
                    if (IsUpdown){
                        com2Y += height;
                        width = rect2.size.width;
                    }else{
                        width = rect2.size.width*2;
                    }
                    width = imgOrigin2.size.width/myScrollView2.zoomScale;
                    if ((rect2.size.height+rect2.origin.y)>imgOrigin2.size.height) {
                        // 上側がクリップされ、下側に余白がつく場合
                        com2Height = height - ((rect2.size.height+rect2.origin.y)-imgOrigin2.size.height);
                    } else if (rect2.origin.y>0) {
                        // 上下がクリップされる場合
                        com2Height = height;
                    } else {
                        // 等倍 or 上下に余白がつく場合
                        if (IsUpdown){
                            com2Height = (myScrollView2.frame.size.height / updownHscale - (fabs(offset2.y)) / updownHscale ) / myScrollView2.zoomScale / scale2h;
                        }else{
                            com2Height = (myScrollView2.frame.size.height - fabs(offset2.y)) / myScrollView2.zoomScale / scale2h;
                        }
                    }
                    r2width = img2.size.width;
                }
                if (IsUpdown){
                    com2X = 0;
                }else{
                    com2X = width/2;
                }
                com2X += (rect2.origin.x<0)? fabs(rect2.origin.x)*myScrollView2.zoomScale : 0;
                comX = (rect.origin.x<0)? rect.origin.x*-1 : 0;
                comX = comX * scale1w / scale2w * myScrollView1.zoomScale / tmpScale;
                comY = (rect.origin.y<0)? rect.origin.y*-1 : 0;
                comY = comY * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
                if ((rect.size.height+rect.origin.y)<imgOrigin1.size.height) {
                    if (myScrollView1.zoomScale<1) {
                        comHeight = (rect.size.height+rect.origin.y) * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
                    } else {
                        comHeight = height-comY;
                    }
                } else if (rect.origin.y>0) {
                    comHeight = (imgOrigin1.size.height-rect.origin.y) * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
                } else {
                    comHeight = (imgOrigin1.size.height) * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
                }
                
                combHpos = img1.size.width * scale1h / scale2h * myScrollView1.zoomScale / tmpScale;
                //            width += combHpos;
                if (IsUpdown) {
                    height = height * 2;
                }
            }
        //}
    }
    
    // 合成画像の作成
    if (!IsOverlap) {
        rect = CGRectMake(0.0, 0.0, width, height);
    }else {
        //        width = ((combHpos)>(r2width-com2X))? (combHpos) : (r2width-com2X);
        rect = CGRectMake(0.0, 0.0, width, height);
    }
    UIGraphicsBeginImageContext(rect.size);     // 合成後画像の枠生成
    
    if (!IsOverlap) {
#ifdef DEBUG
        NSLog(@"comsize(%d) [%.01f :%.01f]", bigImg, rect.size.width, rect.size.height);
#endif
        rect = CGRectMake(comX, comY, combHpos, comHeight);
#ifdef DEBUG
        NSLog(@"im-combined [%.01f : %.01f / %.01f : %.01f]", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
#endif
        [img1 drawInRect:rect];
        rect = CGRectMake(com2X, com2Y, r2width, com2Height);
#ifdef DEBUG
        NSLog(@"im-combined [%.01f : %.01f / %.01f : %.01f]", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
#endif
        [img2 drawInRect:rect];
    }else {
#ifdef DEBUG
        NSLog(@"comsize(%d) [%.01f :%.01f]", bigImg, rect.size.width, rect.size.height);
#endif
        rect = CGRectMake(comX, comY, combHpos-comXt, comHeight);
#ifdef DEBUG
        NSLog(@"im-combined [%.01f : %.01f / %.01f : %.01f]", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
#endif
        [img1 drawInRect:rect blendMode:kCGBlendModeNormal alpha:(1 - sldRatio.value)];
        rect = CGRectMake(com2X, com2Y, r2width-com2Xt, com2Height);
#ifdef DEBUG
        NSLog(@"im-combined [%.01f : %.01f / %.01f : %.01f]", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
#endif
        [img2 drawInRect:rect blendMode:kCGBlendModeNormal alpha:sldRatio.value];
        //        [img1 drawInRect:rect blendMode:kCGBlendModeNormal alpha:(1 - sldRatio.value)];
        //        [img2 drawInRect:rect blendMode:kCGBlendModeNormal alpha:sldRatio.value];
    }
    if (self._pictImageMixed) self._pictImageMixed = nil;
    self._pictImageMixed = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //    [self._pictImageMixed retain];
}

#else
// Imageの合成
- (void)makeCombinedImage
{
    UIImage* imgOrigin1 = imgvwPicture1.image;
    UIImage* imgOrigin2 = imgvwPicture2.image;
    //CGFloat width = 320 * INIT_IMAGE_SCALE;
    //CGFloat height = 480 * INIT_IMAGE_SCALE;
    CGFloat width;
    if (IsOverlap) {
        width = imgOrigin1.size.width;
    }else{
        if(IsUpdown){
            width = imgOrigin1.size.width;
        }else{
            width = imgOrigin1.size.width / 2;
        }
    }
    CGFloat height = imgOrigin1.size.height;
    float scale1 = myScrollView1.frame.size.height / height;
    float scale2 = myScrollView2.frame.size.height / height;
    CGPoint offset1 = myScrollView1.contentOffset;
    CGPoint offset2 = myScrollView2.contentOffset;
    CGRect rect;
    
    // 画像1の切り抜き
    ///rect = CGRectMake((CGFloat)(offset1.x / scale1), (CGFloat)(offset1.y / scale1), width, height);
    ///CGImageRef cgImage1 = CGImageCreateWithImageInRect(imgResize1.CGImage, rect);
    rect = CGRectMake((CGFloat)(offset1.x / myScrollView1.zoomScale / scale1),
                      (CGFloat)(offset1.y / myScrollView1.zoomScale / scale1),
                      myScrollView1.frame.size.width / myScrollView1.zoomScale / scale1,
                      myScrollView1.frame.size.height / myScrollView1.zoomScale / scale1);
    CGImageRef cgImage1 = CGImageCreateWithImageInRect(imgOrigin1.CGImage, rect);
    UIImage* img1 = [UIImage imageWithCGImage:cgImage1];
    CGImageRelease(cgImage1);
    //[imgResize1 release];
    
    // 画像2の切り抜き
    ///rect = CGRectMake((CGFloat)(offset2.x / scale2), (CGFloat)(offset2.y / scale2), width, height);
    ///CGImageRef cgImage2 = CGImageCreateWithImageInRect(imgResize2.CGImage, rect);
    rect = CGRectMake((CGFloat)(offset2.x / myScrollView2.zoomScale / scale2),
                      (CGFloat)(offset2.y / myScrollView2.zoomScale / scale2),
                      myScrollView2.frame.size.width / myScrollView2.zoomScale / scale2,
                      myScrollView2.frame.size.height / myScrollView2.zoomScale / scale2);
    CGImageRef cgImage2 = CGImageCreateWithImageInRect(imgOrigin2.CGImage, rect);
    UIImage* img2 = [UIImage imageWithCGImage:cgImage2];
    CGImageRelease(cgImage2);
    //[imgResize2 release];
    
    // 合成画像の作成
    if (!IsOverlap) {
        if(IsUpdown){
            rect = CGRectMake(0.0, 0.0, width / INIT_IMAGE_SCALE, height / INIT_IMAGE_SCALE  * 2);
        }else{
            rect = CGRectMake(0.0, 0.0, width / INIT_IMAGE_SCALE * 2, height / INIT_IMAGE_SCALE);
        }
    }else {
        rect = CGRectMake(0.0, 0.0, width / INIT_IMAGE_SCALE, height / INIT_IMAGE_SCALE);
    }
    UIGraphicsBeginImageContext(rect.size);
    rect = CGRectMake(0.0, 0.0, width / INIT_IMAGE_SCALE, height / INIT_IMAGE_SCALE);
    
    //	[img1 drawInRect:rect];
    if (!IsOverlap) {
        if(IsUpdown){
            [img1 drawInRect:rect];
            rect = CGRectMake(0,0, height / INIT_IMAGE_SCALE, width / INIT_IMAGE_SCALE, height / INIT_IMAGE_SCALE);
            [img2 drawInRect:rect];
        }else{
            [img1 drawInRect:rect];
            rect = CGRectMake(width / INIT_IMAGE_SCALE, 0.0, width / INIT_IMAGE_SCALE, height / INIT_IMAGE_SCALE);
            [img2 drawInRect:rect];
        }
    }else {
        [img1 drawInRect:rect blendMode:kCGBlendModeNormal alpha:(1 - sldRatio.value)];
        [img2 drawInRect:rect blendMode:kCGBlendModeNormal alpha:sldRatio.value];
    }
    self._pictImageMixed = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //[img1 release];
    //[img2 release];
    
    /*
     [imgvwTest setFrame:CGRectMake(imgvwTest.frame.origin.x, imgvwTest.frame.origin.y, _pictImageMixed.size.width, _pictImageMixed.size.height)];
     imgvwTest.hidden = NO;
     */
    // 何かのImageViewに表示してからでないと次の画面へ遷移するときに例外が発生する。
    // まだ解決できていない。
    [imgvwTest setImage:self._pictImageMixed];
}
#endif  // OLD_COMBINED

// iPad2の場合に画像を縮小する
- (UIImage *)resizeImage:(UIImage *)orgImg maxSize:(NSInteger)maxSize
{
    UIImage *resultImg = orgImg;
    BOOL doResize = NO;
    CGRect rect;
    CGSize orgSize = orgImg.size;
    
    BOOL   isPortlate = (orgSize.width<orgSize.height)? YES : NO;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    if (isPortlate && (orgSize.height>maxSize)) {
        doResize = YES;
        rect.size.height = maxSize;
        rect.size.width  = maxSize * orgSize.width / orgSize.height;
    }
    else if (!isPortlate && (orgSize.width>maxSize)) {
        doResize = YES;
        rect.size.height = maxSize * orgSize.height / orgSize.width;
        rect.size.width  = maxSize;
    }
    
    if (doResize) { // リサイズ処理
#ifdef DEBUG
        NSLog(@"[DoResize] [%.01f:%.01f -> %.01f:%.01f]",
              orgSize.width, orgSize.height,
              rect.size.width, rect.size.height);
#endif
        UIGraphicsBeginImageContext(rect.size);     // 合成後画像の枠生成
        [orgImg drawInRect:rect];
        resultImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        //        [resultImg retain];
    }
    
    return resultImg;
}


- (UIImage *)pictImage:(NSInteger)idx{
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID: _userID];
    UIImage *timg = [((OKDThumbnailItemView*)pictImageItems[idx]) getRealSizeImage:imgFileMng];
    if(imgFileMng.readError) {
        [self readErrorImage:idx];
    }
    [imgFileMng release];
    if (isiPad2) {
        return [self cutAlphaArea:[self resizeImage:timg maxSize:IPAD2_MAX_SIZE]];
    } else {
        return [self cutAlphaArea:timg];
    }
}

// 読み込みエラー画像tagセット
- (void)readErrorImage:(NSUInteger)tagID;
{
    [errorTags addObject:[NSNumber numberWithInteger:tagID]];
}

/**
 * 画像のアルファ領域をカットする
 */

- (UIImage *)cutAlphaArea:(UIImage *)image
{
    NSInteger x1 = -1, x2 = -1, y1 = -1, y2 = -1;   // 左端、右端、上端、下端
    NSInteger tx1 = -1, tx2 = -1;
    
    // CGImageを取得する
    CGImageRef  imageRef = image.CGImage;
    // データプロバイダを取得する
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    
    // ビットマップデータを取得する
    CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
    UInt8* buffer = (UInt8*)CFDataGetBytePtr(dataRef);
    
    size_t bytesPerRow                = CGImageGetBytesPerRow(imageRef);
    
    // 上端検索
    for (int y=0; y<image.size.height; y++) {
        for (int x=0; x<image.size.width; x++) {
            UInt8*  pixelPtr = buffer + (int)(y) * bytesPerRow + (int)(x) * 4;
            
            // 色情報を取得する
            UInt8 a = *(pixelPtr + 3);  // Alpha
            UInt8 r = *(pixelPtr + 2);  // 赤
            UInt8 g = *(pixelPtr + 1);  // 緑
            UInt8 b = *(pixelPtr + 0);  // 青
            
            if (y1 == -1 && !(r==0 && g==0 && b==0 && (a==0 || a==255))) {
                y1 = y;     // 上端設定
                tx1 = x;    // 仮左端
            }
            // 上端発見後、初めて出てきた透明部分を仮右端とする
            if (y1!=-1 && r==0 && g==0 && b==0 && (a==0 || a==255)) {
                tx2 = x;    // 仮右端
            }
            if (tx1!=-1 && tx2!=-1) {
                break;
            }
        }
        if (y1!=-1) {
            if (tx2==-1) {
                tx2=image.size.width - 1;
            }
            break;
        }
    }
    
    // 下端検索
    for (int y=image.size.height-1; y>0; y--) {
        for (int x=0; x<image.size.width; x++) {
            UInt8*  pixelPtr = buffer + (int)(y) * bytesPerRow + (int)(x) * 4;
            
            // 色情報を取得する
            UInt8 a = *(pixelPtr + 3);  // Alpha
            UInt8 r = *(pixelPtr + 2);  // 赤
            UInt8 g = *(pixelPtr + 1);  // 緑
            UInt8 b = *(pixelPtr + 0);  // 青
            
            if (y2 == -1 && !(r==0 && g==0 && b==0 && (a==0 || a==255))) {
                y2 = y;                 // 下端設定
                if(tx1 > x) tx1 = x;    // 仮左端更新
            }
            // 下端上で、透明以外があれば仮右端を更新する
            if (y2!=-1 && !(r==0 && g==0 && b==0 && (a==0 || a==255))) {
                if (tx2 < x) tx2 = x;   // 仮右端更新
            }
        }
        if (y2!=-1) {
            break;
        }
    }
    
    // 左端検索
    BOOL contFlag;
    for (NSInteger x=tx1; x>0; x--) {
        contFlag = NO;
        for (NSInteger y=y1; y<y2; y++) {
            UInt8*  pixelPtr = buffer + (int)(y) * bytesPerRow + (int)(x) * 4;
            
            // 色情報を取得する
            UInt8 a = *(pixelPtr + 3);  // Alpha
            UInt8 r = *(pixelPtr + 2);  // 赤
            UInt8 g = *(pixelPtr + 1);  // 緑
            UInt8 b = *(pixelPtr + 0);  // 青
            
            // 左端検索が初回または前回発見ポイントよりもさらに左の点が有った場合
            if (((x1 == -1) || (x1 > x)) &&
                !(r==0 && g==0 && b==0 && (a==0 || a==255))) {
                x1 = x;                 // 左端設定
                contFlag = YES;
                break;              // 無色以外の点が有った場合に、立て検索を中断する
            }
        }
    }
    if (x1==-1) {
        x1 = 0;
    }
    
    // 右端検索
    for (int x=image.size.width-1; x>=tx2; x--) {
        contFlag = YES;
        for (NSInteger y=y1; y<y2; y++) {
            UInt8*  pixelPtr = buffer + (int)(y) * bytesPerRow + (int)(x) * 4;
            
            // 色情報を取得する
            UInt8 a = *(pixelPtr + 3);  // Alpha
            UInt8 r = *(pixelPtr + 2);  // 赤
            UInt8 g = *(pixelPtr + 1);  // 緑
            UInt8 b = *(pixelPtr + 0);  // 青
            
            if (x2 == -1 && !(r==0 && g==0 && b==0 && (a==0 || a==255))) {
                x2 = x;
                contFlag = NO;
                break;
            }
        }
        if (contFlag==NO) {
            if (x2==-1) {
                x2 = tx2;
            }
            break;
        }
    }
    x2 = (x2==-1)? tx2 : x2;
#ifdef DEBUG
    NSLog(@"cut % 4ld : % 4ld : % 4ld : % 4ld", (long)x1, (long)y1, (long)x2, (long)y2);
#endif
    CGImageRef cliped = CGImageCreateWithImageInRect(imageRef, CGRectMake(x1, y1, (x2-x1+1), (y2-y1+1)));
    
    UIImage *clipImg = [UIImage imageWithCGImage:cliped];
#ifdef DEBUG
    NSLog(@"size: [% 4.2f :% 4.2f]", clipImg.size.width, clipImg.size.height);
#endif
    CGImageRelease(cliped);
    CFRelease(dataRef);
    
    return clipImg;
}

// UIImageViewの画像の左右反転
- (void)reverseImage:(UIImageView*)imgView
{
	UIImage* imgOrigin = imgView.image;
	CGRect rect = CGRectMake(0.0, 0.0, imgOrigin.size.width, imgOrigin.size.height);
	UIGraphicsBeginImageContext(rect.size);	
	CGContextTranslateCTM(UIGraphicsGetCurrentContext(), rect.size.width, 0.0);
	CGContextScaleCTM(UIGraphicsGetCurrentContext(), -1.0, 1.0);
	[imgOrigin drawInRect:rect];
	UIImage* img = UIGraphicsGetImageFromCurrentImageContext();	
	UIGraphicsEndImageContext();
	[imgView setImage:img];
	
	/*
	[imgvwTest setFrame:CGRectMake(imgvwTest.frame.origin.x, imgvwTest.frame.origin.y, img.size.width, img.size.height)];
	[imgvwTest setImage:img];
	imgvwTest.hidden = NO;
	 */
	
	//[imgOrigin release];
	//[img release];
}

/**
 * スクロールさせる為に周囲に空白領域を付加する
 * (合成方法の変更により、VGAへの縮小をやめる)
 */
- (UIImage*)setPictureSizeToScroll:(UIImage*)picture
{
	// 画像の拡大／縮小
//	CGRect rect = CGRectMake(0.0, 0.0, 640, 480);
//	UIGraphicsBeginImageContext(rect.size);	
//	[picture drawInRect:rect];
//	UIImage* imgResize = UIGraphicsGetImageFromCurrentImageContext();	
//	UIGraphicsEndImageContext();
	
    CGFloat tmpWidth, tmpHeight;
    if (picture.size.width*3 < picture.size.height*4) {
        tmpHeight = picture.size.height;
        tmpWidth  = picture.size.height*4/3;
    } else if (picture.size.width*3 < picture.size.height*4) {
        tmpHeight = picture.size.width*3/4;
        tmpWidth  = picture.size.width;
    } else {
        tmpHeight = picture.size.height;
        tmpWidth  = picture.size.width;
    }
	// (VGA * INIT_IMAGE_SCALE)の大きさの黒塗り画像を作成し、その中央にVGAサイズに変更した元画像を貼付ける
	CGRect rect2 = CGRectMake(0.0, 0.0,tmpWidth * INIT_IMAGE_SCALE,tmpHeight * INIT_IMAGE_SCALE);
	UIGraphicsBeginImageContext(rect2.size);
//	CGContextRef context = UIGraphicsGetCurrentContext();  // コンテキストを取得
	//CGContextStrokeRect(context, rect2);  // 四角形の描画
//    if (IsOverlap) {
//        CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.0);  // 塗りつぶしの色を指定
//    }else {
//        CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);  // 塗りつぶしの色を指定
//    }
//	CGContextFillRect(context, rect2);  // 四角形を塗りつぶす
	CGRect rect = CGRectMake((rect2.size.width / 2) - (picture.size.width / 2),
					  (rect2.size.height / 2) - (picture.size.height / 2), picture.size.width, picture.size.height);
	[picture drawInRect:rect];
	UIImage* imgReturn = UIGraphicsGetImageFromCurrentImageContext();	
	UIGraphicsEndImageContext();

	//[imgResize release];
	
	return (imgReturn);
}

- (UIImage*)setPictureCompareSizeToScroll:(UIImage*)picture withNoPic:(NSInteger)picNo
{
    CGFloat tmpWidth, tmpHeight;
    if (picture.size.width*3 < picture.size.height*4) {
        tmpHeight = picture.size.height;
        tmpWidth  = picture.size.height*4/3;
    } else if (picture.size.width*3 < picture.size.height*4) {
        tmpHeight = picture.size.width*3/4;
        tmpWidth  = picture.size.width;
    } else {
        tmpHeight = picture.size.height;
        tmpWidth  = picture.size.width;
    }
    // (VGA * INIT_IMAGE_SCALE)の大きさの黒塗り画像を作成し、その中央にVGAサイズに変更した元画像を貼付ける
    CGRect rect2 = CGRectMake(0.0, 0.0,tmpWidth * INIT_IMAGE_SCALE,tmpHeight * INIT_IMAGE_SCALE);
    UIGraphicsBeginImageContext(rect2.size);
    
    CGRect rect;
    if (picNo == 1) {
        rect = CGRectMake(0, 0 , picture.size.width, picture.size.height);
    } else {
        rect = CGRectMake(480, 0 , picture.size.width, picture.size.height);
    }
   
    [picture drawInRect:rect];
    UIImage* imgReturn = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return (imgReturn);
}

// スワイプのセットアップ
- (void) setupSwipSupport
{
	// 右方向スワイプ
	UISwipeGestureRecognizer *swipeGestue = [[UISwipeGestureRecognizer alloc]
											 initWithTarget:self action:@selector(OnSwipeRightView:)];
	swipeGestue.direction = UISwipeGestureRecognizerDirectionRight;
	swipeGestue.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeGestue];
	[swipeGestue release];
	
	// 左方向スワイプ
	UISwipeGestureRecognizer *swipeGestueLeft = [[UISwipeGestureRecognizer alloc]
												 initWithTarget:self action:@selector(OnSwipeLeftView:)];
	swipeGestueLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	swipeGestueLeft.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeGestueLeft];
	[swipeGestueLeft release];
}

#pragma mark public_methods

// 施術情報の設定
- (void)setWorkItemInfo:(USERID_INT)userID workItemHistID:(HISTID_INT)histID
{
	_userID = userID;
	_histID = histID;
}

// スキップ設定
- (void)setSkip:(BOOL)skip
{
	_isSkipThisView = skip;
	if (_isSkipThisView) 
	{
		[skippedBackgroundView setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
		[self.view bringSubviewToFront:skippedBackgroundView];
		skippedBackgroundView.hidden = NO;
	}
	else 
	{
		[self.view sendSubviewToBack:skippedBackgroundView];
		skippedBackgroundView.hidden = YES;
	}

}

// 画像描画画面からの戻りを通知
- (void)backFromPicturePaintView
{
#ifdef DEBUG
//    NSLog(@"return _pictImageMixed[%d]", [_pictImageMixed retainCount]);
#endif
//	// 合成画像破棄
//	if (self._pictImageMixed)
//	{
//		self._pictImageMixed = nil;
//	}
}

/*
// レイアウトを設定する
- (void)setLayout
{
	// 縦横切り替え
	[self changeToPortrait:([[UIScreen mainScreen] applicationFrame].size.width == 768.0f)];
}
*/

// スクロールViewのズームとスワイプのロック
- (void)scrollViewZoomLockControllWithFlag:(BOOL)isLock
{
    myScrollView1.scrollEnabled = myScrollView2.scrollEnabled = isLock;
    myScrollView1.userInteractionEnabled = myScrollView2.userInteractionEnabled = isLock;
}

// 画像Imageリストの設定
- (void)setPictImageItems:(NSMutableArray*)images
{
    if (pictImageItems != nil)
    {
        [pictImageItems removeAllObjects];
    }
    else
    {
        // リストを空で作成
        pictImageItems = [ [NSMutableArray alloc] init];
    }
    if (errorTags != nil) {
        [errorTags removeAllObjects];
    } else {
        errorTags = [[NSMutableArray alloc] init];
    }
    
    for (id item in images)
    {
        [pictImageItems addObject:item];
    }
    
    [self dispThumbnailList];
    
    [sldRatio setEnabled:YES];
}

// サムネイルの表示
- (void)dispThumbnailList{
    //float xp = 148.0f;
    //float yp = 180.0f;
    
    if (realImageList != nil)
    {
        [realImageList removeAllObjects];
    }
    else
    {
        // リストを空で作成
        realImageList = [ [NSMutableArray alloc] init];
    }
    
    if (imagePointList != nil)
    {
        [imagePointList removeAllObjects];
    }else{
        // リストを空で作成
        imagePointList = [ [NSMutableArray alloc] init];
    }
    
    if (imageScaleList != nil)
    {
        [imageScaleList removeAllObjects];
    }else{
        // リストを空で作成
        imageScaleList = [ [NSMutableArray alloc] init];
    }
    
    myScrollView2.alpha = sldRatio.value;
    myScrollView1.alpha = 1.0f - sldRatio.value;
    
    selectedImageID = 0;
    activeImgView = 0;
    
    //UIImage *img0;
    // サムネイル表示の圧縮サイズ(３個以上の場合VGA相当、２個までの場合IPAD2_MAX_SIZE
    NSInteger max = ([pictImageItems count]>2)? 640 : IPAD2_MAX_SIZE;
    
    for (int i = 0; (i < pictImageItems.count) && !memWarning; i++) {
        UIImage *img = [self resizeImage:[self pictImage:i] maxSize:max];
        
        OKDClickImageView *imgView
        = [[[OKDClickImageView alloc]
            init:img
            selectedNumber: i + 1
            ownerView:self] autorelease];
        
        imgView.delegate = self;
        imgView.tag = i;
        [imgView setSelectNumberHidden:YES];
        imgView.hidden = YES;
        imgView.userInteractionEnabled = NO;
        imgView.alpha = 0.3;
        [imgView setSizeMorphing:CGRectMake(0, 0, ITEM_WITH_COMP, ITEM_HEIGHT_COMP)];
        if(i == 0){
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
        
        [realImageList addObject:img];
        
        [self.view addSubview:imgView];
        
        imgView.frame = CGRectMake(0, 0, ITEM_WITH_COMP, ITEM_HEIGHT_COMP);
        
        //xp = xp + ITEM_WITH_COMP + 10;
        
        
        CGFloat width = ([self getPortrait])? 364.0f : 364.0f;
        CGFloat height = ([self getPortrait])? 546.0f : 546.0f;
        
        [imagePointList addObject:[NSValue valueWithCGPoint:CGPointMake((320.0f * INIT_IMAGE_SCALE - 320.0f) * (width / 320.0f),
                                                                        (240.0f * INIT_IMAGE_SCALE - 240.0f) * (height / 480.0f))]];
        CGPoint cgPoint = [[imagePointList objectAtIndex:i] CGPointValue];
        
        [imageScaleList addObject:[NSNumber numberWithFloat:myScrollView1.zoomScale]];
    }
}


// サムネイルの位置調整
- (void)setCoordinateThumbnailList{
    float xp = 20.0f;
    float yp = 180.0f;
    CGFloat portrateWith = 768.0f;
    
    BOOL isPortrait = ([[UIScreen mainScreen] applicationFrame].size.width == 768.0f);
    
    if(isPortrait){
        xp = 20.0f;
        yp = 180.0f;
    }else{
        xp = 148.0f;
        yp = 70.0f;
    }
    for ( id sv in self.view.subviews)
    {
        if([sv isKindOfClass:[OKDClickImageView class]]){
            OKDClickImageView *imgView = (OKDClickImageView*)sv;
            imgView.frame = CGRectMake(xp, yp, ITEM_WITH_COMP, ITEM_HEIGHT_COMP);
            xp = xp + ITEM_WITH_COMP + 7;
            imgView.hidden = NO;
        }
    }
    
    CGFloat posX = (isPortrait)? 20.0f : 148.0f;
    CGFloat posY = (isPortrait)? 254.0f : 70.0f;
    CGFloat width = (isPortrait)? 364.0f : 364.0f;
    CGFloat height = (isPortrait)? 546.0f : 546.0f;
    float uiOffset = (!IsNavigationCall)? 0.0f : 20.0f;

    [myScrollView1 setFrame:CGRectMake(posX, posY+uiOffset, width * 2, height)];
    [myScrollView2 setFrame:CGRectMake(posX, posY+uiOffset, width * 2, height)];
}
// 画像Image選択イベント
- (void)OnOKDClickImageViewSelected:(NSUInteger)tagID image:(UIImage*)image
{
}

// Touchイベント
- (void)OnOKDClickImageViewTouched:(id)sender{
    OKDThumbnailItemView *iv = (OKDThumbnailItemView*)sender;
    
    for(UIView* view in self.view.subviews)
    {
        if([view isKindOfClass:[OKDClickImageView class]]){
                OKDClickImageView *imgView = (OKDClickImageView*)view;
                [imgView setSelected:NO frameColor:nil numberSelected:0];
        }
    }
    
    OKDClickImageView *imgView = (OKDClickImageView*)sender;
    [imgView setSelected:YES frameColor:[UIColor blueColor]numberSelected:0];
    
    if(iv.tag == 0){
         [imgvwPicture1 setImage:[self setPictureSizeToScroll:[realImageList objectAtIndex:iv.tag]]];
         myScrollView1.alpha = 0.7f;
         myScrollView2.alpha = 0.5f;
        selectedImageIndex = imgView.tag;
        
        CGPoint cgPoint = [[imagePointList objectAtIndex:iv.tag] CGPointValue];
        myScrollView1.zoomScale = [[imageScaleList objectAtIndex:iv.tag] floatValue];
        myScrollView1.contentOffset = cgPoint;
        
        myScrollView1.userInteractionEnabled = YES;
        myScrollView2.userInteractionEnabled = NO;
        
    }else{
        [imgvwPicture2 setImage:[self setPictureSizeToScroll:[realImageList objectAtIndex:iv.tag]]];
        myScrollView1.alpha = 0.5f;
        myScrollView2.alpha = 0.7f;
        //sldRatio.value = 0.0f;
    
        selectedImageIndex = imgView.tag;
    
        CGPoint cgPoint = [[imagePointList objectAtIndex:iv.tag] CGPointValue];
        myScrollView2.zoomScale = [[imageScaleList objectAtIndex:iv.tag] floatValue];
        myScrollView2.contentOffset = cgPoint;
        
        myScrollView1.userInteractionEnabled = NO;
        myScrollView2.userInteractionEnabled = YES;
    }
}

#pragma mark life_cycle

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

// 初期化
//	picture1:写真Image1  pictureImage2:写真Image2  userName:対象ユーザ名  nameColor:ユーザ名の色 workDate:施術日（nil可：その場合は表示されない）
- (void)initWithPicture:(UIImage*)picture1 pictureImage2:(UIImage*)picture2 userName:(NSString*)name nameColor:(UIColor*)color workDate:(NSString*)date
{
	// 画像用ImageViewの生成
	if (! imgvwPicture1) 
	{

        imgvwPicture1 = [[GrayOutImageView alloc] initWithFrame:CGRectMake(0, 0, myScrollView1.frame.size.width, myScrollView1.frame.size.height)];

		[imgvwPicture1 setBackgroundColor:[UIColor blackColor]];
//        [imgvwPicture1 setContentMode:UIViewContentModeScaleAspectFit];
		myScrollView1.contentSize = imgvwPicture1.frame.size;
		[myScrollView1 addSubview:imgvwPicture1];
		[imgvwPicture1 release];
	}
	if (! imgvwPicture2) 
	{
        imgvwPicture2 = [[GrayOutImageView alloc] initWithFrame:CGRectMake(0, 0, myScrollView2.frame.size.width, myScrollView2.frame.size.height)];
        if (IsOverlap) {
            [imgvwPicture2 setBackgroundColor:[UIColor clearColor]];
        }else {
            [imgvwPicture2 setBackgroundColor:[UIColor blackColor]];
        }
//        [imgvwPicture2 setContentMode:UIViewContentModeScaleAspectFit];
		myScrollView2.contentSize = imgvwPicture2.frame.size;
		[myScrollView2 addSubview:imgvwPicture2];
		[imgvwPicture2 release];
	}
    
    if(!self.IsMorphing){
        imgvwPicture1.hidden = YES;
        imgvwPicture2.hidden = YES;
    }
    
	if (self._pictImage1) { self._pictImage1 = nil; }
	if (self._pictImage2) { self._pictImage2 = nil; }
	if (self._pictImageMixed) { self._pictImageMixed = nil; }
	if (_isSkipThisView) {
		self._pictImage1 = picture1;
		self._pictImage2 = picture2;
	}else {
        // 画像サイズを4:3に変更する
        self._pictImage1 = [self setPictureSizeToScroll:picture1];
        self._pictImage2 = [self setPictureSizeToScroll:picture2];
	}
    // 変更後のサイズをオリジナルサイズとする
    picOrgSize1 = self._pictImage1.size;
    picOrgSize2 = self._pictImage2.size;
	[imgvwPicture1 setFrame:CGRectMake(imgvwPicture1.frame.origin.x, imgvwPicture1.frame.origin.y, self._pictImage1.size.width, self._pictImage1.size.height)];
	[imgvwPicture1 setImage:self._pictImage1];
	[imgvwPicture2 setFrame:CGRectMake(imgvwPicture2.frame.origin.x, imgvwPicture2.frame.origin.y, self._pictImage2.size.width, self._pictImage2.size.height)];
	[imgvwPicture2 setImage:self._pictImage2];
	// スクロール範囲の設定（これがないとスクロールしない）
	[myScrollView1 setContentSize:imgvwPicture1.frame.size];
	[myScrollView2 setContentSize:imgvwPicture2.frame.size];
    // スクロールViewの余白設定（オリジナル画像の周囲に透明余白をつける必要がなくなる）
    myScrollView1.contentInset = UIEdgeInsetsMake(myScrollView1.frame.size.height,
                                                  myScrollView1.frame.size.width,
                                                  myScrollView1.frame.size.height,
                                                  myScrollView1.frame.size.width);
    myScrollView2.contentInset = UIEdgeInsetsMake(myScrollView2.frame.size.height,
                                                  myScrollView2.frame.size.width,
                                                  myScrollView2.frame.size.height,
                                                  myScrollView2.frame.size.width);
	
	lblUserName.text = name;
	lblUserName.textColor = color;
	if (date)
	{
		lblWorkDate.text = date;
		
		lblWorkDate.hidden = NO;
		lblWorkDateTitle.hidden = NO;
		viewWorkDateBack.hidden = NO;
	}
	
	// 背景View(画面スキップ時に表示される)の生成
	if (! skippedBackgroundView) 
	{
		skippedBackgroundView = [[UIView alloc] initWithFrame:
								CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
		[skippedBackgroundView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
		[self.view addSubview:skippedBackgroundView];
		skippedBackgroundView.hidden = YES;
	}
    
    [self btnDispCtrl];
    
    if(self.IsMorphing){
        BOOL isPortrait = ([[UIScreen mainScreen] applicationFrame].size.width == 768.0f);
        
        CGFloat posX = (isPortrait)? 20.0f : 148.0f;
        CGFloat posY = (isPortrait)? 254.0f : 110;
        CGFloat width = (isPortrait)? 364.0f : 364.0f;
        CGFloat height = (isPortrait)? 546.0f : 546.0f;
        float uiOffset = (!IsNavigationCall)? 0.0f : 20.0f;
        
        [myScrollView1 setFrame:CGRectMake(posX, posY+uiOffset, width * 2, height)];
        [myScrollView2 setFrame:CGRectMake(posX, posY+uiOffset, width * 2, height)];
        
        [imgvwPicture1 setFrame:CGRectMake(0.0f, 0.0f, (CGFloat)(width * 2),height)];
        [imgvwPicture2 setFrame:CGRectMake(0.0f, 0.0f, (CGFloat)(width * 2),height)];
        
        _isModeLock = NO;
        btnLockMode.enabled = YES;
        [self scrollViewZoomLockControllWithFlag:_isModeLock];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
    isiPad2 = ([UIScreen mainScreen].scale > 1.0f)? NO : YES;
    
    self.view.userInteractionEnabled = YES;
    // 背景色の変更 RGB:D8BFD8
//    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:204/255.0f green:149/255.0f blue:187/255.0f alpha:1.0f];
    
	// ロックモードの初期設定
    if(self.IsMorphing){
        _isModeLock = YES;
        btnLockMode.enabled = NO;
    }else{
        _isModeLock = NO;
    }
	// スクロールViewのズームとスワイプのロック
	[self scrollViewZoomLockControllWithFlag:_isModeLock];
	
	// 背景Viewの角を丸くする
	[self setCornerRadius:viewUserNameBack];
	[self setCornerRadius:viewWorkDateBack];
	[self setCornerRadius:vwCtrlPallet];
	
	// 制御パレットの初期化
	vwCtrlPallet.backgroundColor = viewUserNameBack.backgroundColor;
	vwCtrlPallet.alpha = 0.45f;
	
	// 制御パレットボタン初期化
	btnSeparateOn.tag = PALLET_SEPARATE_ON;
	btnSeparateOff.tag = PALLET_SEPARATE_OFF;
	btnLeftTurn.tag = PALLET_LEFT_TURN;
	btnRightTurn.tag = PALLET_RIGHT_TURN;
    btnLeftTurn2.tag = PALLET_LEFT_TURN;
	btnRightTurn2.tag = PALLET_RIGHT_TURN;
	//btnSave.tag = PALLET_SAVE;
	[btnSeparateOn setEnabled:NO];
	[btnSeparateOff setEnabled:NO];
	[btnLeftTurn setEnabled:NO];
	[btnRightTurn setEnabled:NO];
    [btnLeftTurn2 setEnabled:NO];
	[btnRightTurn2 setEnabled:NO];
	//[btnSave setEnabled:NO];

    // 2012 7/13 透過合成パレットの初期化
    [self setCornerRadius:vwSynthesisCtrlPallet];
    vwSynthesisCtrlPallet.hidden = YES;
    vwSynthesisCtrlPallet.backgroundColor = viewUserNameBack.backgroundColor;
	vwSynthesisCtrlPallet.alpha = 0.45f;
    [btnBackOn setEnabled:NO];
	[btnFrontOn setEnabled:NO];
    if(self.IsMorphing){
        [sldRatio setEnabled:YES];
    }else{
        [sldRatio setEnabled:NO];
    }
    
	// スクロールViewの最大ズーム倍率
	// 2012 6/27 伊藤 余白追加のため最大拡大サイズ変更
	[myScrollView1 setMaximumZoomScale:20.0];
	[myScrollView2 setMaximumZoomScale:20.0];
    [myScrollView1 setMinimumZoomScale:0.3];
    [myScrollView2 setMinimumZoomScale:0.3];
    
    sel1st_2nd = SEL_2ND;
	
	// NavigationCallによる画面遷移の場合
	if (self.IsNavigationCall)
	{	
		// スワイプをセットアップする
		[self setupSwipSupport]; 
	}

    // 突き合わせ画像処理時の分割線を隠す
    self.IsvwSaparate = YES;

	// 縦横切り替え
	// この時点でレイアウトを設定しても、横画面で遷移した時はなぜかmyScrollView1のY位置が-256になる。原因は不明。
	// よって、前画面のOnTransitionNewViewDidLoadデリゲートでレイアウト調整関数をコールする。
	//[self changeToPortrait:([[UIScreen mainScreen] applicationFrame].size.height == 768.0f)];
    
    skippedBackgroundView = nil;
    [backGroundView setBackgroundColor:[UIColor blackColor]];
}

/*
// 画面が表示される都度callされる:viewWillAppear
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear : animated];
	
	// 縦横切り替え
	[self changeToPortrait:[self getPortrait] initMode:YES];
}	
*/

// 画面が表示される都度callされる:viewDidAppear
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear : animated];
    
    memWarning = NO;
    
#ifdef CALULU_IPHONE
    CGFloat portrateWith = 320.0f;
#else
    CGFloat portrateWith = 768.0f;
#endif
	
	if (self.IsSetLayout)
	{
		// 縦横切り替え
		[self changeToPortrait:([[UIScreen mainScreen] applicationFrame].size.width == portrateWith) initMode:YES];
        LastRotated = ([[UIScreen mainScreen] applicationFrame].size.width == portrateWith)? YES : NO;
	}
	else 
	{
		if (self.IsNavigationCall)
		{
			// 縦横切り替え
			[self changeToPortrait:([[UIScreen mainScreen] applicationFrame].size.width == portrateWith) initMode:self.IsSetLayout];
		}
		else if (! self.IsNavigationCall && self.IsRotated) 
		{
			// 縦横切り替え
			[self changeToPortrait:([[UIScreen mainScreen] applicationFrame].size.width == portrateWith) initMode:NO];
		}
	}
	
	// 編集フラグをリセット
	_isDirty = NO;
    if(self.IsMorphing){
        isModify = NO;
        selectedImageIndex = 0;
    }


	/*
	// 縦横切り替え
	[self changeToPortrait:([[UIScreen mainScreen] applicationFrame].size.width == 768.0f) initMode:self.IsSetLayout];
	*/
	
	/*
	NSLog(@"PictureCompViewController - viewDidAppear - myScrollView2.contentOffset - X:%f Y:%f", 
		  myScrollView2.contentOffset.x, myScrollView2.contentOffset.y);
	*/
    
    imgvwPicture1.hidden = NO;
    imgvwPicture2.hidden = NO;
    
    //2012 6/22 伊藤 連続してページ遷移できないよう修正
    //mainVCのスクロールビューの幅設定
    MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC setScrollViewWidth:YES];
    
    [self scrollViewZoomLockControllWithFlag:_isModeLock];
    [self setControllViewActive:sel1st_2nd];

    if (_pictImageMixed) {
        [_pictImageMixed release];
        _pictImageMixed = nil;
    }
    
    [self setControllViewActive:sel1st_2nd];
    
    if(self.IsOverlap || self.IsMorphing) {
        myScrollView1.userInteractionEnabled = NO;
        myScrollView2.userInteractionEnabled = NO;
    }
    
    if (self.IsMorphing) {
        [mainVC setScrollViewWidth:NO];
        [mainVC setScrollViewBounce:NO];
    }
}
	
// 縦横切り替え前のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{			
	_toInterfaceOrientation = toInterfaceOrientation;
	
	// MainViewController経由で遷移してきた時は、didRotateFromInterfaceOrientationが呼び出されない。理由は未調査。
	if (! self.IsNavigationCall)
	{
		[self didRotateFromInterfaceOrientation:toInterfaceOrientation];
	}
	else 
	{
		myScrollView1.hidden = myScrollView2.hidden = YES;
	}

}	

// 縦横切り替え後のイベント
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation 
{
	BOOL isPortrait;
	
	switch (_toInterfaceOrientation) 
	{
		case UIInterfaceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			isPortrait = YES;
			break;
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			isPortrait = NO;
			break;
		default:
			isPortrait = NO;
			break;
	}
	
    if(LastRotated==isPortrait)
        self.IsRotated = NO;
    else
        self.IsRotated = YES;
    LastRotated = isPortrait;
	
	[self changeToPortrait:isPortrait initMode:NO];
	
	if (self.IsNavigationCall)
	{
		myScrollView1.hidden = myScrollView2.hidden = NO;
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
    if (!memWarning) {
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        if ([[mainVC getNowCurrentViewController] isKindOfClass:[PictureCompViewController class]]) {
#ifdef DEBUG
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"ご注意"
                                       message:[NSString stringWithFormat:@"空きメモリ容量が少ない為、\niPad内の不要なアプリケーションを\n終了して下さい\n[%d]",
                                                [DevStatusCheck getFreeMemory]]
                                      delegate:nil
                             cancelButtonTitle:nil
                             otherButtonTitles:@"OK", nil];
#else
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"ご注意"
                                       message:@"空きメモリ容量が少ない為、\niPad内の不要なアプリケーションを\n終了して下さい"
                                      delegate:nil
                             cancelButtonTitle:nil
                             otherButtonTitles:@"OK", nil];
#endif
            [alert show];
            [alert release];
        }
    }
    memWarning = YES;
}

// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive {
    memWarning = NO;
}

- (void)viewDidUnload {
    [backGroundView release];
    backGroundView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [imgvwPicture1 removeFromSuperview];
//    [imgvwPicture1 release];
    [imgvwPicture2 removeFromSuperview];
//    [imgvwPicture2 release];
    
    _pictImage1 = nil;
    _pictImage2 = nil;
    _pictImageMixed = nil;
    
	if (skippedBackgroundView)
	{
		[skippedBackgroundView release];
	}

    [lblUserName release];				// ユーザ名
    [lblWorkDate release];				// 施術日
    [lblWorkDateTitle release];			// 施術日タイトル
    [viewUserNameBack release];			// ユーザ名背景
    [viewWorkDateBack release];			// 施術日背景
    [btnLockMode release];				// ロックモード切り替えボタン
    [btnToolBarShow release];			// コンテナView表示カスタムボタン
    [backGroundView release];            // 透過合成時の黒背景
    [myScrollView1 release];				// スクロールビュー1
    [myScrollView2 release];				// スクロールビュー2
    [vwSaparete release];				// 区分線				:lockモードのみ表示
    [vwCtrlPallet release];				// 制御パレットビュー
    [btnSeparateOn release];				// 区分線ありボタン
    [btnSeparateOff release];			// 区分線なしボタン
    [btnLeftTurn release];				// 左側画像反転ボタン
    [btnRightTurn release];				// 右側画像反転ボタン
    [btnLeftTurn2 release];				// 左側画像反転ボタン : 透過画像用
    [btnRightTurn2 release];				// 右側画像反転ボタン : 透過画像用
    [vwSynthesisCtrlPallet release];		// 制御パレットビュー
    [btnBackOn release];                 // 背後ビュー操作
    [btnFrontOn release];                // 全面ビュー操作
    [sldRatio release];                  // 透過度スライダー
    [imgvwTest release];					// TEST
    [pictImageItems removeAllObjects];
    [pictImageItems release];
    [realImageList removeAllObjects];
    [realImageList release];
    
    [super dealloc];
	
	/*
	if (self._pictImage1) { self._pictImage1 = nil; }
	if (self._pictImage2) { self._pictImage2 = nil; }
	if (self._pictImageMixed) { self._pictImageMixed = nil; }
	*/
//    if (self._pictImageMixed) { [self._pictImageMixed release]; }
}

// メモリワーニングが出ている場合に、次画面への遷移を抑制する
- (BOOL)checkEnableTransition
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    BOOL enable = NO;

    if (memWarning) {
#ifdef DEBUG
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"ご注意"
                                   message:[NSString stringWithFormat:@"空きメモリ容量が少ない為、\n処理を中断しました\niPad内の不要なアプリケーションを\n終了して下さい\n[%d]",
                                            [DevStatusCheck getFreeMemory]]
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];
#else
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"ご注意"
                                   message:@"空きメモリ容量が少ない為、\n処理を中断しました\niPad内の不要なアプリケーションを\n終了して下さい"
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];
#endif
        [alert show];
        [alert release];
    }
    else {
        enable = YES;
    }
    
    return enable;
}

#pragma mark MainViewControllerDelegate

// 新規View画面への遷移
//		return: 次に表示する画面のViewController  nilで遷移をキャンセル
- (UIViewController*) OnTransitionNewView:(id)sender
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
    if (![self checkEnableTransition]) {
        return nil;
    }
	
    // モーフィングの時は何もしない
    if(self.IsMorphing){
        return nil;
    }
    
	if (! _isSkipThisView)
	{
		if (! self._pictImageMixed) 
		{
			//return (nil);
			// 合成画像が保存されていない場合はテンポラリ合成画像を作成する
			[self makeCombinedImage];
		}
	}

	PicturePaintViewController *picturePaintVC
	= [[PicturePaintViewController alloc]
       
#ifdef CALULU_IPHONE
	   initWithNibName:@"ip_PicturePaintViewController" bundle:nil];
#else
	   initWithNibName:@"PicturePaintViewController" bundle:nil];
#endif
    
    picturePaintVC.IsUpdown = self.IsUpdown;
//    [picturePaintVC release];
	
	return (picturePaintVC);
}

// 新規View画面への遷移でViewがLoadされた後にコールされる
- (void) OnTransitionNewViewDidLoad:(id)sender transitionVC:(UIViewController*)tVC
{
	PicturePaintViewController *picturePaintVC = (PicturePaintViewController*)tVC;
	
    picturePaintVC.IsUpdown = self.IsUpdown;
	UIImage* pict;
	if (_isSkipThisView)
	{
	// 写真一覧より直接、画像描画へ遷移
		pict = imgvwPicture1.image;
	}
	else 
	// 写真一覧より合成画像経由で画像描画へ
	{
		pict = self._pictImageMixed;
		//pict = imgvwTest.image;
	}

	// 写真描画の初期化
	[picturePaintVC initWithPicture:pict
						   userName:lblUserName.text nameColor:lblUserName.textColor
						   workDate:lblWorkDate.text];
	[picturePaintVC setUser:_userID];
	
	// 合成画像の編集フラグを設定
	picturePaintVC.IsCompViewDirty = (! _isSkipThisView)? _isDirty : NO;
}

// 既存View画面への遷移
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
    
    if (![self checkEnableTransition]) {
        return nil;
    }
	
	PicturePaintViewController *picturePaintVC = (PicturePaintViewController*)tVC;

    picturePaintVC.IsUpdown = self.IsUpdown;
	UIImage* pict;
	if (_isSkipThisView)
	// 写真一覧より直接、画像描画へ遷移
	{
		pict = imgvwPicture1.image;
	}
	else
	// 写真一覧より合成画像経由で画像描画へ
	{
		if (!self._pictImageMixed || _isDirty)
		{
			//return (NO);
			// 合成画像が保存されていない場合はテンポラリ合成画像を作成する
			[self makeCombinedImage];
		}

		pict = self._pictImageMixed;
		//pict = imgvwTest.image;
	}

    picturePaintVC.IsUpdown = self.IsUpdown;
    
    UIScreen *screen = [UIScreen mainScreen];
    [picturePaintVC changeToPortrait:(screen.applicationFrame.size.width == 768.0f)];
	// 写真描画の初期化
	[picturePaintVC initWithPicture:pict
						   userName:lblUserName.text nameColor:lblUserName.textColor
						   workDate:lblWorkDate.text];
	[picturePaintVC setUser:_userID];
	pict = nil;
	
	// 合成画像の編集フラグを設定
	picturePaintVC.IsCompViewDirty = (! _isSkipThisView)? _isDirty : NO;
#ifdef DEBUG
	NSLog(@"OnTransitionExsitView DONE at PictureCompViewController");
#endif
	return (YES);				// 画面遷移する	
}

// 画面終了の通知
- (BOOL) OnUnloadView:(id)sender
{
    if(_IsMorphing){
        if(isModify){
            [UIAlertView displayAlertWithTitle:@"画像状態の破棄"
                                       message:@"画面の状態（画像の位置調整・拡大縮小）を破棄します\nよろしいですか？"
                               leftButtonTitle:@"はい"
                              leftButtonAction:^(void){
                                  // MainViewControllerの取得
                                  MainViewController *mainVC
                                  = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
                                  // 前画面に戻る
                                  [mainVC backBeforePage];
                                  
                                  // 前画面に戻る前にImageをクリア
                                  self._pictImage1 = nil;
                                  self._pictImage2 = nil;
                                  [imgvwPicture1 setImage:nil];
                                  [imgvwPicture2 setImage:nil];
                                  
                                  // ユーザ名と施術日もクリア
                                  lblUserName.text = @"";
                                  lblWorkDate.text = @"";
                                  
                                  // Viewを非表示にする
                                  self.view.hidden = YES;
                                  
                                  for ( id sv in self.view.subviews)
                                  {
                                      if([sv isKindOfClass:[OKDClickImageView class]]){
                                          [sv removeFromSuperview];
                                      }
                                  }
                              }
                              rightButtonTitle:@"いいえ"
                             rightButtonAction:^(void){
                             }];
            return (NO);
        }
    }
    
    BOOL stat = YES;
    
    // 前画面に戻る前にImageをクリア
    self._pictImage1 = nil;
    self._pictImage2 = nil;
    [imgvwPicture1 setImage:nil];
    [imgvwPicture2 setImage:nil];
    
    // ユーザ名と施術日もクリア
    lblUserName.text = @"";
    lblWorkDate.text = @"";
    
    // Viewを非表示にする
    self.view.hidden = YES;
    
    for ( id sv in self.view.subviews)
    {
        if([sv isKindOfClass:[OKDClickImageView class]]){
            [sv removeFromSuperview];
        }
    }

    return (stat);
}

// ロック画面への遷移確認:実装しない場合は遷移可とみなす
- (BOOL) OnDisplayChangeEnable:(id)sender disableReason:(NSMutableString*) message
{
	BOOL stat;
	
	// 編集中の場合は、遷移不可とする
	if (! _isDirty)
	{	
		stat = YES;
		
		MainViewController* mainVC = (MainViewController*)sender;
		// 前ページへ戻る：選択画像一覧画面
		[mainVC backBeforePage];
	}
	else 
	{
		stat = NO;
		[message appendString:@"(先に保存をしてください)"];
	}
	
	return (stat);
}

// スクロール実施の確認 : NOを返すとスクロールをキャンセル
- (BOOL) OnCheckScrollPerformed:(id)sender touchView:(UIView*)view
{
    BOOL isPerformed = ! _isModeLock;
    
    return (isPerformed);
}

#pragma mark control_events

// ロックモード切り替えボタン
- (IBAction) OnBtnLockMode:(id)sender
{
	// 最初にロックモードを切り替える
	_isModeLock = ! _isModeLock;
	
	// ボタンのimage変更
	[((UIButton*)sender) setImage:(_isModeLock)? 
	 [UIImage imageNamed:@"lockIcon.png"] : [UIImage imageNamed:@"unlockIcon.png"]
						 forState: UIControlStateNormal];
	
	// MainViewにスクロールロックを依頼
	if (! self.IsNavigationCall)
	{
		MainViewController *mainVC 
			= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		[mainVC viewScrollLock:_isModeLock];
	}
	
	// スクロールViewのズームとスワイプのロック
	[self scrollViewZoomLockControllWithFlag:_isModeLock];
	
	// 制御パレット
	if ([self getPortrait]) 
	{
		vwCtrlPallet.alpha = (_isModeLock)? 1.0f : 1.0f;
	}
	else 
	{
		[self showToolbar];
	}

    [self btnDispCtrl];
	/*
	[btnSave setImage:(_isModeLock)? 
	 [UIImage imageNamed:@"save_normal.png"] : [UIImage imageNamed:@"save_disable.png"]
				 forState:UIControlStateNormal];
	[btnSave setEnabled:_isModeLock];
	*/
    
    //2012 7/13 透過合成関係
    [btnFrontOn setEnabled:_isModeLock];
    [btnBackOn setEnabled:_isModeLock];
    if(self.IsMorphing){
        [sldRatio setEnabled:!_isModeLock];
    }else{
        [sldRatio setEnabled:_isModeLock];
    }
    vwSynthesisCtrlPallet.alpha = vwCtrlPallet.alpha;

    // 突き合わせの分割線が表示されているときに、タップによるグレイアウトを有効にする
    if(!self.IsOverlap) {
        if(self.IsvwSaparate == NO && _isModeLock == YES) {
            imgvwPicture1.userInteractionEnabled = YES;
            imgvwPicture2.userInteractionEnabled = YES;
        }
        
        if(self.IsMorphing){
            
            isModify = YES;
            
            if(!_isModeLock){
                
                imgvwPicture1.userInteractionEnabled = NO;
                imgvwPicture2.userInteractionEnabled = NO;
                
                selectedImageID = 0;
                sldRatio.value = 0.001;
                activeImgView = 0;
                
                imgvwPicture1.image = [self setPictureSizeToScroll:[realImageList objectAtIndex:0]];
                CGPoint cgPoint = [[imagePointList objectAtIndex:0] CGPointValue];
                myScrollView1.zoomScale = [[imageScaleList objectAtIndex:0] floatValue];
                myScrollView1.contentOffset = cgPoint;
                
                imgvwPicture2.image = [self setPictureSizeToScroll:[realImageList objectAtIndex:1]];
                CGPoint cgPoint2 = [[imagePointList objectAtIndex:1] CGPointValue];
                myScrollView2.zoomScale = [[imageScaleList objectAtIndex:1] floatValue];
                myScrollView2.contentOffset = cgPoint2;
                
                for ( id sv in self.view.subviews)
                {
                    if([sv isKindOfClass:[OKDClickImageView class]]){
                        OKDClickImageView *imgView = (OKDClickImageView*)sv;
                        imgView.userInteractionEnabled = NO;
                        imgView.alpha = 0.3;
                    }
                }
                
                myScrollView1.alpha = 1.0f;
                myScrollView2.alpha = 0.0f;
                
            }else{
                
                if(selectedImageIndex == 0){
                    [imgvwPicture1 setImage:[self setPictureSizeToScroll:[realImageList objectAtIndex:selectedImageIndex]]];
                    myScrollView1.alpha = 0.7f;
                    myScrollView2.alpha = 0.5f;
                    
                    CGPoint cgPoint = [[imagePointList objectAtIndex:selectedImageIndex] CGPointValue];
                    myScrollView1.zoomScale = [[imageScaleList objectAtIndex:selectedImageIndex] floatValue];
                    myScrollView1.contentOffset = cgPoint;
                    
                    myScrollView1.userInteractionEnabled = YES;
                    myScrollView2.userInteractionEnabled = NO;
                    
                }else{
                    [imgvwPicture1 setImage:[self setPictureSizeToScroll:[realImageList objectAtIndex:0]]];
                    [imgvwPicture2 setImage:[self setPictureSizeToScroll:[realImageList objectAtIndex:selectedImageIndex]]];
                    myScrollView1.alpha = 0.5f;
                    myScrollView2.alpha = 0.7f;
                    
                    CGPoint cgPoint = [[imagePointList objectAtIndex:0] CGPointValue];
                    myScrollView1.zoomScale = [[imageScaleList objectAtIndex:0] floatValue];
                    myScrollView1.contentOffset = cgPoint;
                    
                    CGPoint cgPoint2 = [[imagePointList objectAtIndex:selectedImageIndex] CGPointValue];
                    myScrollView2.zoomScale = [[imageScaleList objectAtIndex:selectedImageIndex] floatValue];
                    myScrollView2.contentOffset = cgPoint2;
                    
                    myScrollView1.userInteractionEnabled = NO;
                    myScrollView2.userInteractionEnabled = YES;
                }
                
                for ( id sv in self.view.subviews)
                {
                    if([sv isKindOfClass:[OKDClickImageView class]]){
                        OKDClickImageView *imgView = (OKDClickImageView*)sv;
                        imgView.userInteractionEnabled = YES;
                        imgView.alpha = 1.0;
                    }
                }
            }
        }
    }
}

// 突き合わせ・透過合成画面の制御ボタン表示
- (void) btnDispCtrl
{
    if (vwSaparete.hidden) {
		[btnSeparateOn setImage:(_isModeLock)?
         [UIImage imageNamed:@"separate_write_normal.png"] : [UIImage imageNamed:@"separate_write_disable.png"]
                       forState:UIControlStateNormal];
		[btnSeparateOn setEnabled:_isModeLock];
		[btnSeparateOff setImage:[UIImage imageNamed:@"separate_delete_disable.png"] forState:UIControlStateNormal];
	}else {
		[btnSeparateOn setImage:(_isModeLock)?
		 [UIImage imageNamed:@"separate_normal.png"] : [UIImage imageNamed:@"separate_disable.png"]
					   forState:UIControlStateNormal];
		[btnSeparateOn setEnabled:_isModeLock];
		[btnSeparateOff setImage:(_isModeLock)?
		 [UIImage imageNamed:@"separate_delete_normal.png"] : [UIImage imageNamed:@"separate_delete_disable.png"]
						forState:UIControlStateNormal];
		[btnSeparateOff setEnabled:_isModeLock];
	}
    [btnLeftTurn setImage:(_isModeLock)?
     [UIImage imageNamed:@"1pic_enable.png"] : [UIImage imageNamed:@"1pic_disable.png"]
                 forState:UIControlStateNormal];
    [btnLeftTurn setEnabled:_isModeLock];
    [btnRightTurn setImage:(_isModeLock)?
     [UIImage imageNamed:@"2pic_enable.png"] : [UIImage imageNamed:@"2pic_disable.png"]
                  forState:UIControlStateNormal];
    [btnRightTurn setEnabled:_isModeLock];
    
    [btnLeftTurn2 setImage:(_isModeLock)?
     [UIImage imageNamed:@"1pic_enable.png"] : [UIImage imageNamed:@"1pic_disable.png"]
                  forState:UIControlStateNormal];
    [btnLeftTurn2 setEnabled:_isModeLock];
    [btnRightTurn2 setImage:(_isModeLock)?
     [UIImage imageNamed:@"2pic_enable.png"] : [UIImage imageNamed:@"2pic_disable.png"]
                   forState:UIControlStateNormal];
    [btnRightTurn2 setEnabled:_isModeLock];
}

// 制御パレットボタン
- (IBAction) OnBtnCtrlPallet:(id)sender
{
	UIButton* btn = (UIButton*)sender;
	
	if (btn.tag == PALLET_SEPARATE_ON)
	{
        self.IsvwSaparate = NO;
		vwSaparete.hidden = NO;
		imgvwPicture1.userInteractionEnabled = YES;
		imgvwPicture2.userInteractionEnabled = YES;
		[btn setImage:[UIImage imageNamed:@"separate_normal.png"] forState:UIControlStateNormal];
		[btnSeparateOff setImage:[UIImage imageNamed:@"separate_delete_normal.png"] forState:UIControlStateNormal];
		[btnSeparateOff setEnabled:YES];
	}
	else if (btn.tag == PALLET_SEPARATE_OFF)
	{
        self.IsvwSaparate = YES;
		vwSaparete.hidden = YES;
		imgvwPicture1.userInteractionEnabled = NO;
		imgvwPicture2.userInteractionEnabled = NO;
		imgvwPicture1.alpha = 1.0f;
		imgvwPicture2.alpha = 1.0f;
		[btnSeparateOn setImage:[UIImage imageNamed:@"separate_write_normal.png"] forState:UIControlStateNormal];
		[btn setImage:[UIImage imageNamed:@"separate_delete_disable.png"] forState:UIControlStateNormal];
		[btn setEnabled:NO];
	}
	else if (btn.tag == PALLET_LEFT_TURN)
	{
		[self reverseImage:imgvwPicture1];
	}
	else if (btn.tag == PALLET_RIGHT_TURN)
	{
		[self reverseImage:imgvwPicture2];
	}
	else if (btn.tag == PALLET_SAVE)
	{
		// 合成画像作成
		[self makeCombinedImage];
		
		// 合成画像のファイル保存とDB更新
		//[self saveImageFile:self._pictImageMixed];
	}
	
}

// コンテナViewとユーザ名の表示ボタン（横表示のみ）
- (IBAction)onShowToolBar
{
	_isToolBar = ! _isToolBar;
	[self showToolbar];
	
	if (_isToolBar)
	{
		// お客様名関連を最前面へ
		[self.view bringSubviewToFront:viewUserNameBack];
		[self.view bringSubviewToFront:viewWorkDateBack];
	}
	else 
	{
		// お客様名関連を最背面へ
		[self.view sendSubviewToBack:viewUserNameBack];
		[self.view sendSubviewToBack:viewWorkDateBack];
	}
}

// 透過率変更スライドバー
- (IBAction)OnSliderSet:(id)sender{
    UISlider* slider = sender;
    if(self.IsMorphing == YES){

        float ratio = slider.value * (pictImageItems.count-1);
        int index = floorl(ratio);
        
        float beginP = (float)index / (pictImageItems.count-1);
        
        float unit = slider.maximumValue / (pictImageItems.count-1);
        
        float chAlpha = (beginP + unit - slider.value) / unit;
        

        if(activeImgView == 0 && beginP < 1.0){
            myScrollView1.alpha = chAlpha;
            myScrollView2.alpha = 1.0f - chAlpha;
        }else if(activeImgView == 1 && beginP < 1.0){
            myScrollView1.alpha = 1.0f - chAlpha;
            myScrollView2.alpha = chAlpha;
        }
        
        if(selectedImageID != index && index < pictImageItems.count-1){
            if(activeImgView == 0){
                if(selectedImageID < index){
                    if(index < pictImageItems.count-1){
                        myScrollView1.alpha = 0.01;
                        myScrollView2.alpha = 0.99;
                        imgvwPicture1.image = [self setPictureSizeToScroll:[realImageList objectAtIndex:index+1]];
                    }
                    CGPoint cgPoint = [[imagePointList objectAtIndex:index+1] CGPointValue];
                    myScrollView1.zoomScale = [[imageScaleList objectAtIndex:index+1] floatValue];
                    myScrollView1.contentOffset = cgPoint;
                }else{
                    myScrollView1.alpha = 0.99;
                    myScrollView2.alpha = 0.01;
                    imgvwPicture2.image = [self setPictureSizeToScroll:[realImageList objectAtIndex:index]];
                    CGPoint cgPoint = [[imagePointList objectAtIndex:index] CGPointValue];
                    myScrollView2.zoomScale = [[imageScaleList objectAtIndex:index] floatValue];
                    myScrollView2.contentOffset = cgPoint;
                }
                activeImgView = 1;
            }else if(activeImgView == 1){
                if(selectedImageID < index){
                    if(index < pictImageItems.count-1){
                        myScrollView1.alpha = 0.99;
                        myScrollView2.alpha = 0.01;
                        imgvwPicture2.image = [self setPictureSizeToScroll:[realImageList objectAtIndex:index+1]];
                    }
                    CGPoint cgPoint = [[imagePointList objectAtIndex:index+1] CGPointValue];
                    myScrollView2.zoomScale = [[imageScaleList objectAtIndex:index+1] floatValue];
                    myScrollView2.contentOffset = cgPoint;
                }else{
                    myScrollView1.alpha = 0.01;
                    myScrollView2.alpha = 0.99;
                    imgvwPicture1.image = [self setPictureSizeToScroll:[realImageList objectAtIndex:index]];
                    CGPoint cgPoint = [[imagePointList objectAtIndex:index] CGPointValue];
                    myScrollView1.zoomScale = [[imageScaleList objectAtIndex:index] floatValue];
                    myScrollView1.contentOffset = cgPoint;
                }
                activeImgView = 0;
            }
            
            selectedImageID = index;
        }
        beforeValue = slider.value;
    }else{
        myScrollView2.alpha = slider.value;
        myScrollView1.alpha = 1.0f - slider.value;
    }
}

- (IBAction)OnSetControllView:(id)sender{
    UIButton* selectBtn = sender;
    if (selectBtn == btnBackOn) {
        sel1st_2nd = SEL_1ST;
    }else if(selectBtn == btnFrontOn){
        sel1st_2nd = SEL_2ND;
    }
    
    [self setControllViewActive:sel1st_2nd];
}

- (void)setControllViewActive:(BOOL)side
{
    if (!IsOverlap && !_IsMorphing) {
        return;
    }
    if (side == SEL_1ST) {
        myScrollView1.userInteractionEnabled = YES;
        myScrollView2.userInteractionEnabled = NO;
        [btnBackOn setImage:[UIImage imageNamed:@"kari_button_BackOn_select"] forState:UIControlStateNormal];
        [btnFrontOn setImage:[UIImage imageNamed:@"kari_button_BackOn"] forState:UIControlStateNormal];
    }
    else if(side == SEL_2ND) {
        myScrollView1.userInteractionEnabled = NO;
        myScrollView2.userInteractionEnabled = YES;
        [btnBackOn setImage:[UIImage imageNamed:@"kari_button_BackOn"] forState:UIControlStateNormal];
        [btnFrontOn setImage:[UIImage imageNamed:@"kari_button_FrontOn_select"] forState:UIControlStateNormal];
    }
}

#pragma mark swipe_events

// 右方向のスワイプイベント
- (void)OnSwipeRightView:(id)sender
{
	// ロックモードの時は何もしない
	if (_isModeLock)
	{	return; }
	
	// 前画面に戻る
	if (self.IsNavigationCall)
	{
        if(_IsMorphing){
            if(isModify){
                [UIAlertView displayAlertWithTitle:@"画像状態の破棄"
                                           message:@"画面の状態（画像の位置調整・拡大縮小）を破棄します\nよろしいですか？"
                                   leftButtonTitle:@"はい"
                                  leftButtonAction:^(void){
                                      [self.navigationController popViewControllerAnimated:YES];
                                  }
                                  rightButtonTitle:@"いいえ"
                                 rightButtonAction:^(void){
                                     return;
                                 }];
            }else{
                // 現時点で最上位のViewController(=self)を削除する
                [self.navigationController popViewControllerAnimated:YES];
            }
        }else{
            // 現時点で最上位のViewController(=self)を削除する
            [self.navigationController popViewControllerAnimated:YES];
        }
	}
}

// 左方向のスワイプイベント
- (void)OnSwipeLeftView:(id)sender
{
	// ロックモードの時は何もしない
	if (_isModeLock)
	{	return; }
    
    if (![self checkEnableTransition]) {
        return;
    }
    // モーフィングの時は何もしない
    if(self.IsMorphing){
        return;
    }
	
	// 左方向のフリック；写真描画画面に遷移
	PicturePaintViewController *picturePaintVC
		= [[PicturePaintViewController alloc] 
#ifdef CALULU_IPHONE
		   initWithNibName:@"ip_PicturePaintViewController" bundle:nil];
#else
		   initWithNibName:@"PicturePaintViewController" bundle:nil];
#endif
    
	picturePaintVC.IsUpdown = self.IsUpdown;
	picturePaintVC.IsNavigationCall = YES;
	
	// 写真描画画面の表示
	[self.navigationController pushViewController:picturePaintVC animated:YES];
		
	// 合成画像が保存されていない場合はテンポラリ合成画像を作成する
	if (! self._pictImageMixed) 
	{
		[self makeCombinedImage];
	}
		
    // iOS7で時間を置かずに initWithPicture を呼ぶと、ViewDidLoadが終了していないため
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
	// 写真描画の初期化
    picturePaintVC.IsUpdown = self.IsUpdown;
	[picturePaintVC initWithPicture:self._pictImageMixed
						   userName:lblUserName.text nameColor:lblUserName.textColor
						   workDate:(lblWorkDate.hidden) ? nil : lblWorkDate.text];
	[picturePaintVC setUser:_userID];
	[picturePaintVC release];
    });
	// 合成画像の編集フラグを設定
	picturePaintVC.IsCompViewDirty = _isDirty;
}

#pragma mark UIScrollViewDelegate

// ピンチ（ズーム）機能：これがないとピンチしない
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	// このviewがscroll対象のviewとなる
	UIView *view = nil;
	
	if (scrollView == myScrollView1) {
		view = imgvwPicture1;
	}else if (scrollView == myScrollView2) {
		view = imgvwPicture2;
	}
	
	return (view);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	// 編集フラグをセット
	_isDirty = YES;
	// NSLog(@"scrollViewDidScroll");
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	// NSLog(@"scrollViewDidZoom");
	// 編集フラグをセット
	_isDirty = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if(decelerate == YES){
        return;
    }else{
        [imagePointList replaceObjectAtIndex:selectedImageIndex withObject:[NSValue valueWithCGPoint:CGPointMake(scrollView.contentOffset.x,
                                                                                                                 scrollView.contentOffset.y)]];
        NSLog(@"%dの画像　x=%f y=%f",(int)selectedImageIndex,scrollView.contentOffset.x,scrollView.contentOffset.y);
        
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [imagePointList replaceObjectAtIndex:selectedImageIndex withObject:[NSValue valueWithCGPoint:CGPointMake(scrollView.contentOffset.x,
                                                                                                             scrollView.contentOffset.y)]];
    NSLog(@"%dの画像　x=%f y=%f",(int)selectedImageIndex,scrollView.contentOffset.x,scrollView.contentOffset.y);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(CGFloat)scale
{
    [imageScaleList replaceObjectAtIndex:selectedImageIndex withObject:[NSNumber numberWithFloat:scrollView.zoomScale]];
    NSLog(@"%dの画像の倍率　%f",(int)selectedImageIndex,scrollView.zoomScale);
}
@end
