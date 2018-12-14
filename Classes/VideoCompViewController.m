//
//  VideoCompViewController.m
//  iPadCamera
//
//  Created by 管理者 on 11/06/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "iPadCameraAppDelegate.h"

#import "VideoCompViewController.h"
#import "PicturePaintViewController.h"
#import "Common.h"
#import "SelectVideoViewController.h"
#import "AnimationElement.h"
#import "SVProgressHUD.h"
#import "UIAlertView+Blocks.h"

#import "AccountManager.h"

@implementation VideoCompViewController

@synthesize IsSetLayout;
@synthesize IsNavigationCall;
@synthesize IsRotated;
@synthesize IsOverlap;
@synthesize IsUpdown;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
        player1 = [[CompPlayerView alloc] init];
        player2 = [[CompPlayerView alloc] init];
        slider1 = [[SyncSlider alloc] init];
        slider2 = [[SyncSlider alloc] init];
        rangeSlider = [[RangeSlider alloc] init];
        rangeSliderRight = [[RangeSlider alloc] init];
        volumeSlider1 = [[UISlider alloc] init];
        volumeSlider2 = [[UISlider alloc] init];
        currentTimeLabel1 = [[UILabel alloc] init];
        currentTimeLabel2 = [[UILabel alloc] init];
        underCurrentTimeView1 = [[UIView alloc] init];
        underCurrentTimeView2 = [[UIView alloc] init];
        
        slider1.frame = CGRectMake(72, 768, 304, 30);
        slider2.frame = CGRectMake(392, 768, 304, 30);
        
        [self.view addSubview:player1];
        [self.view addSubview:player2];
        [self.view addSubview:slider1];
        [self.view sendSubviewToBack:slider1];
        [self.view addSubview:slider2];
        [self.view sendSubviewToBack:slider2];
        [self.view addSubview:currentTimeLabel1];
        [self.view addSubview:currentTimeLabel2];
        [self.view addSubview:rangeSlider];
        [self.view addSubview:rangeSliderRight];
#ifndef VIDEO_SIMPLE_EDIT
        [self.view addSubview:volumeSlider1];
        [self.view addSubview:volumeSlider2];
#endif
        [self.view addSubview:underCurrentTimeView1];
        [self.view addSubview:underCurrentTimeView2];
        
        [self.view sendSubviewToBack:player2];
        [self.view sendSubviewToBack:player1];
        player1.backgroundColor = [UIColor blackColor];
        player2.backgroundColor = [UIColor blackColor];
        
        isPlaySynth = NO;
        isPlay = NO;
        
        player1.playerDelegate = slider1;
        player2.playerDelegate = slider2;
        player1.playDelegate = self;
        player2.playDelegate = self;
        slider1.delegate = self;
        slider2.delegate = self;
        rangeSlider.delegate = self;
        rangeSliderRight.delegate = self;
        playRateArray = [[NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:1.0f],
                          [NSNumber numberWithFloat:0.75f],
                          [NSNumber numberWithFloat:0.5f],
                          [NSNumber numberWithFloat:0.25f],
                          [NSNumber numberWithFloat:0.10f], nil
                          ] retain];
        
        animations = [[[NSMutableArray alloc] init] retain];
        int opt = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
        [vwPaintManager addObserver:self forKeyPath:@"IsDirty" options:opt context:NULL];
        
        volumeSlider1.minimumValue = 0;
        volumeSlider1.maximumValue = 1;
        volumeSlider1.value = 1;
        volumeSlider2.minimumValue = 0;
        volumeSlider2.maximumValue = 1;
        volumeSlider2.value = 1;
        
        [volumeSlider1 addTarget:self action:@selector(volumeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [volumeSlider2 addTarget:self action:@selector(volumeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        isSaving = NO;
        shoudSave = NO;
        videoCompVCfromThumb = nil;
	}
	
	return (self);
}
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
        playRateArray = [[NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:1.0f],
                          [NSNumber numberWithFloat:0.75f],
                          [NSNumber numberWithFloat:0.5f],
                          [NSNumber numberWithFloat:0.25f],
                          [NSNumber numberWithFloat:0.10f], nil
                          ] retain];
        
        animations = [[[NSMutableArray alloc] init] retain];
        int opt = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
        [vwPaintManager addObserver:self forKeyPath:@"IsDirty" options:opt context:NULL];
        isSaving = NO;
        shoudSave = NO;
        videoCompVCfromThumb = nil;
	}
	
	return (self);
}
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    btnAnimeAdd.enabled = vwPaintManager.IsDirty;
    if (vwPaintManager.IsDirty) {
        shoudSave = YES;
    } else {
        shoudSave = NO;
    }
}
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
	if (_isModeLock) 
	{
		vwCtrlPallet.alpha = (_isToolBar)? 1.0f : 0.2f;
	}
	else 
	{
		vwCtrlPallet.alpha = (_isToolBar)? 1.0f : 0.2f;
	}
	
	[btnToolBarShow setImage:(_isToolBar)? 
	 [UIImage imageNamed:@"toolbar_on.png"] : [UIImage imageNamed:@"toolbar_off.png"]
					forState:UIControlStateNormal];
    vwSynthesisCtrlPallet.alpha = vwCtrlPallet.alpha;
    playPallet.alpha = vwCtrlPallet.alpha;
    rotator1.alpha = vwCtrlPallet.alpha;
    rotator2.alpha = vwCtrlPallet.alpha;
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
	NSLog(@"VideoCompViewController - changeToPortrait - isPortrait:%@ initMode:%@",
		  (isPortrait) ? @"YES" : @"NO", (mode) ? @"YES" : @"NO");
#endif
	
	// 編集フラグを保存
	BOOL dirty  = _isDirty;
	
#ifdef CALULU_IPHONE
	CGFloat scrWidth  = (isPortrait)? 320.0f : 480.0f;
	CGFloat scrHeigth = (isPortrait)? 460.0f : 300.0f;
#else
    CGFloat scrWidth  = (isPortrait)? 768.0f : 1024.0f;
	CGFloat scrHeigth = (isPortrait)? 1004.0f : 748.0f;
#endif
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = 0.0f;
    // iOS7かつNavigationCallでの画面遷移の場合
    if (iOSVersion>=7.0f && IsNavigationCall)
        uiOffset = 20.0f;
    
	// 本体のサイズ変更
    if (IsNavigationCall) {
        [self.view setFrame:CGRectMake(0.0f, 0.0f, scrWidth, scrHeigth + uiOffset)];
    }

	// 現在の表示設定を保存
	float zoomScale1 = player1.zoomScale;
	float zoomScale2 = player2.zoomScale;
	CGPoint contentOffset1 = player1.contentOffset;
	CGPoint contentOffset2 = player2.contentOffset;

#ifdef DEBUG
	if (! mode)
	{
		NSLog(@"VideoCompViewController - player1 - X:%f Y:%f Width:%f Height:%f zoomScale:%f contentOffset.x:%f contentOffset.y:%f", 
			  player1.frame.origin.x, player1.frame.origin.y, player1.frame.size.width, player1.frame.size.height, zoomScale1, contentOffset1.x, contentOffset1.y);
		NSLog(@"VideoCompViewController - player2 - X:%f Y:%f Width:%f Height:%f zoomScale:%f contentOffset.x:%f contentOffset.y:%f", 
			  player2.frame.origin.x, player2.frame.origin.y, player2.frame.size.width, player2.frame.size.height, zoomScale2, contentOffset2.x, contentOffset2.y);
	}
#endif
	
	// 縦横の切り替え時に表示がおかしくなるので、一旦１倍に戻す
	player1.zoomScale = 1.0f;
	player2.zoomScale = 1.0f;
    
    [self uiLayout:isPortrait];
	
	// スクロールViewの位置設定
    CGFloat posX1 = (isPortrait)? 20.0f : 148.0f;
	CGFloat posX2 = (isPortrait)? 384.0f : 512.0f;
	CGFloat posY = ((isPortrait)? 254.0f : 70.0f) + uiOffset;
//	CGFloat posY = (isPortrait)? 254.0f : ((_isDrawMode) ? 130.0f : 50.0f);
//	CGFloat width = (isPortrait)? 364.0f : 423.0f;
//	CGFloat height = (isPortrait)? 546.0f : 634.0f;
    CGFloat width = 364.0f;
    CGFloat height = 546.0f;
    if (self.IsOverlap) {
        [player1 setFrame:CGRectMake(posX1, posY, width * 2, height)];
        [player2 setFrame:CGRectMake(posX1, posY, width * 2, height)];
        [vwPaintManager setFrame:player1.frame];
//        player1.alpha = 1 - sldRatio.value;
        player2.alpha = sldRatio.value;
    }else{
        if(self.IsUpdown){
            if (!isPortrait) {
                posY -= 20;
            }
            [player1 setFrame2:CGRectMake(posX1, posY, width * 2, height / 2)];
            [player2 setFrame2:CGRectMake(posX1, posY+(height / 2), width * 2, height / 2)];
            [vwPaintManager setFrame:CGRectMake(posX1, posY, width * 2, height)];
            /*
            [player1 setCompViewWithParentRect:CGRectMake(posX1, posY, width * 2, height / 2)
                                    contentOfs:CGPointZero];
            [player2 setCompViewWithParentRect:CGRectMake(posX1, posY * 2, width * 2, height / 2)
                                    contentOfs:CGPointMake(0.0f, posY * 2)];
            [vwPaintManager setFrame:CGRectMake(posX1, posY, width * 2, height)];
             */
            player1.alpha = 1;
            player2.alpha = 1;
        }else{
            [player1 setCompViewWithParentRect:CGRectMake(posX1, posY, width, height)
                                    contentOfs:CGPointZero];
            [player2 setCompViewWithParentRect:CGRectMake(posX2, posY, width, height)
                                    contentOfs:CGPointMake(width, 0.0f)];
            [vwPaintManager setFrame:CGRectMake(posX1, posY, width * 2, height)];
            player1.alpha = 1;
            player2.alpha = 1;
        }

    }
    for (AnimationElement *anime in animations) {
        anime.frame = vwPaintManager.frame;
    }

    if (self.IsUpdown){
        currentTimeLabel1.frame = CGRectMake(player1.frame.origin.x,
                                            CGRectGetMaxY(player2.frame),
                                             60,
                                             30);
        slider1.frame = CGRectMake(CGRectGetMaxX(currentTimeLabel1.frame),
                                   CGRectGetMaxY(player2.frame),
                                   width*2 - 60,
                                   30);
        slider2.frame = CGRectMake((self.IsOverlap)? (player1.frame.origin.x + width) : player2.frame.origin.x,
                                   CGRectGetMaxY(player2.frame)+30,
                                   width*2 - 60 ,
                                   30);
        currentTimeLabel2.frame = CGRectMake(CGRectGetMaxX(slider2.frame),
                                             CGRectGetMaxY(player2.frame)+30,
                                             60,
                                             30);
    }else{
        currentTimeLabel1.frame = CGRectMake(player1.frame.origin.x,
                                             CGRectGetMaxY(player1.frame),
                                             60,
                                             30);
        slider1.frame = CGRectMake(CGRectGetMaxX(currentTimeLabel1.frame),
                                   CGRectGetMaxY(player1.frame),
                                   width - 60,
                                   30);
        slider2.frame = CGRectMake((self.IsOverlap)? (player1.frame.origin.x + width) : player2.frame.origin.x,
                                   CGRectGetMaxY(player2.frame),
                                   width - 60 ,
                                   30);
        currentTimeLabel2.frame = CGRectMake(CGRectGetMaxX(slider2.frame),
                                             CGRectGetMaxY(player2.frame),
                                             60,
                                             30);
    }
//    rangeSlider.frame =  CGRectMake(player1.frame.origin.x,
//                                    player1.frame.origin.y + player1.frame.size.height + 30,
//                                    width, 40);
//    rangeSliderRight.frame = CGRectMake((self.IsOverlap)? (player1.frame.origin.x + width) : player2.frame.origin.x, player1.frame.origin.y + player2.frame.size.height + 30, width , 40);
    
    underCurrentTimeView1.frame = CGRectMake(currentTimeLabel1.frame.origin.x,
                                         CGRectGetMaxY(currentTimeLabel1.frame),
                                         60,
                                         40);
    rangeSlider.frame =  CGRectMake(CGRectGetMaxX(underCurrentTimeView1.frame),
                                    player1.frame.origin.y + player1.frame.size.height + 30,
                                    width - 60, 40);
    rangeSliderRight.frame = CGRectMake((self.IsOverlap)? (player1.frame.origin.x + width) : player2.frame.origin.x, player1.frame.origin.y + player2.frame.size.height + 30, width - 60 , 40);
    underCurrentTimeView2.frame = CGRectMake(CGRectGetMinX(currentTimeLabel2.frame),
                                         CGRectGetMaxY(currentTimeLabel2.frame),
                                         60,
                                         40);
    vwPaintManager.backgroundColor = [UIColor clearColor];
    [self.view addSubview:vwPaintManager];
    if (isPortrait) {
        CGFloat palletWidth = MAX(playPallet.frame.size.width, playPallet.frame.size.height);
        CGFloat palletHeight = MIN(playPallet.frame.size.width, playPallet.frame.size.height);
        playPallet.frame = CGRectMake(player1.frame.origin.x + width - palletWidth * 0.5f,
                                      (isPortrait)? player1.frame.origin.y - palletHeight - 20 : 75.0f,
                                      palletWidth,palletHeight);
        btnPlay.center = CGPointMake(playPallet.frame.size.width * 0.5f, playPallet.frame.size.height * 0.5f);
        btnPlaySync.center = CGPointMake(btnPlay.center.x - btnPlay.frame.size.width - 5, btnPlay.center.y);
        btnPlaySpeed.center = CGPointMake(btnPlay.center.x + btnPlaySync.frame.size.width + 5, btnPlay.center.y);
        //CGRect ppf = playPallet.frame;
        
        rotator1.frame = CGRectMake(playPallet.frame.origin.x - rotator1.frame.size.width - 40,
                                    playPallet.frame.origin.y + playPallet.frame.size.height * 0.5f - rotator1.frame.size.height * 0.5f,
                                    rotator1.frame.size.width,
                                    rotator1.frame.size.height);
        rotator2.frame = CGRectMake(playPallet.frame.origin.x + playPallet.frame.size.width + 40,
                                    playPallet.frame.origin.y + playPallet.frame.size.height * 0.5f - rotator2.frame.size.height * 0.5f,
                                    rotator2.frame.size.width,
                                    rotator2.frame.size.height);
        btnAnimeAdd.frame = CGRectMake(CGRectGetMaxX(player2.frame) - btnAnimeAdd.frame.size.width,
                                       CGRectGetMaxY(viewUserNameBack.frame) + 16,
                                       btnAnimeAdd.frame.size.width,
                                       btnAnimeAdd.frame.size.height);
        
        if (self.IsUpdown){
            [vwPaintPallet setVideoEditPositionWithRotate: CGPointMake(player2.frame.origin.x, CGRectGetMaxY(player2.frame) + 120)
                                           isPortrate: YES];
        }else{
            [vwPaintPallet setVideoEditPositionWithRotate: CGPointMake(player1.frame.origin.x, CGRectGetMaxY(player1.frame) + 120)
                                               isPortrate: YES];
        }
        [vwPaintPallet setStampSelectViewPoint:CGPointMake(player1.frame.origin.x,
                                                           vwPaintPallet.frame.origin.y - (vwPaintPallet.frame.size.height + 5))];
        vwVideoEditMode.frame = CGRectMake(CGRectGetMaxX(player2.frame) - 126 - btnAnimeAdd.frame.size.width - 10,
                                           CGRectGetMaxY(viewUserNameBack.frame) + 10,
                                           126, palletHeight);
        btnWindowDraw.frame = CGRectMake(3,(vwVideoEditMode.frame.size.height - btnWindowDraw.frame.size.height) * 0.5f,
                                         57, 57);
        btnFrameDraw.frame = CGRectMake(63,(vwVideoEditMode.frame.size.height - btnWindowDraw.frame.size.height) * 0.5f,
                                    57, 57);
        
        volumeSlider1.frame = CGRectMake(CGRectGetMinX(player1.frame),
                                         playPallet.frame.origin.y,
                                         30,
                                         80);
        volumeSlider1.transform = CGAffineTransformMakeRotation(-0.5 * M_PI);
        volumeSlider1.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
        volumeSlider2.frame = CGRectMake(CGRectGetMaxX(player2.frame) - 30,
                                         playPallet.frame.origin.y,
                                         30,
                                         80);
        volumeSlider2.transform = CGAffineTransformMakeRotation(-0.5 * M_PI);
        volumeSlider2.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    } else {
        CGFloat palletWidth = MIN(playPallet.frame.size.width, playPallet.frame.size.height);
        CGFloat palletHeight = MAX(playPallet.frame.size.width, playPallet.frame.size.height);
        playPallet.frame = CGRectMake(1024 - palletWidth - 40,
                                      (768 - palletHeight) * 0.5f + uiOffset,
                                      palletWidth, palletHeight);
        btnPlay.center = CGPointMake(playPallet.frame.size.width * 0.5f, playPallet.frame.size.height * 0.5f);
        btnPlaySync.center = CGPointMake(btnPlay.center.x, btnPlay.center.y - btnPlay.frame.size.height - 5);
        btnPlaySpeed.center = CGPointMake(btnPlay.center.x, btnPlay.center.y + btnPlaySync.frame.size.height + 5);
        CGRect ppf = playPallet.frame;
        rotator1.frame = CGRectMake(ppf.origin.x -13 , ppf.origin.y - 120, 100, 100);
        rotator2.frame = CGRectMake(ppf.origin.x -13 , ppf.origin.y + ppf.size.height + 20, 100, 100);
        btnAnimeAdd.frame = CGRectMake(rotator1.frame.origin.x + (rotator1.frame.size.width - btnAnimeAdd.frame.size.width) * 0.5f,
                                        rotator1.frame.origin.y - rotator1.frame.size.height + 25,
                                        btnAnimeAdd.frame.size.width, btnAnimeAdd.frame.size.height);
        [vwPaintPallet setVideoEditPositionWithRotate: CGPointMake(12, 150 + uiOffset)
                                           isPortrate: NO];

        // スタンプ選択Viewの表示位置調整
        [vwPaintPallet setStampSelectViewPoint:CGPointMake(148, 674 + uiOffset)];
        CGRect plrr = vwPaintPallet.frame;
        vwVideoEditMode.frame = CGRectMake(plrr.origin.x,
                                           plrr.origin.y + plrr.size.height + 10,
                                           126, plrr.size.width);
        btnWindowDraw.frame = CGRectMake(3,(vwVideoEditMode.frame.size.height - btnWindowDraw.frame.size.height) * 0.5f,
                                         57, 57);
        btnFrameDraw.frame = CGRectMake(63,(vwVideoEditMode.frame.size.height - btnWindowDraw.frame.size.height) * 0.5f,
                                        57, 57);
        volumeSlider1.frame = CGRectMake(CGRectGetMinX(player1.frame) - 40,
                                         player1.frame.origin.y,
                                         30,
                                         80);
        volumeSlider1.transform = CGAffineTransformMakeRotation(-0.5 * M_PI);
        volumeSlider1.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
        volumeSlider2.frame = CGRectMake(CGRectGetMaxX(player2.frame) + 10,
                                         player2.frame.origin.y,
                                         30,
                                         80);
        volumeSlider2.transform = CGAffineTransformMakeRotation(-0.5 * M_PI);
        volumeSlider2.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    }
    lblPlaySpeed.center = CGPointMake(btnPlaySpeed.center.x, btnPlaySpeed.center.y + 9);
	// 境界線Viewの位置設定
	// CGFloat posXSeparator = (isPortrait)? 382.0f : 510.0f;
    CGFloat posXSeparator = posX2 - 2.0f;
	[vwSaparete setFrame:CGRectMake(posXSeparator, posY, 4.0f, height)];

    // 突き合わせのときは、透過しないようにする。
    // 突き合わせ時のタップで暗くなるのはimgvwPictureの透過で制御している。
    // 透過のときはplayerで透過を制御するため、imgvwPictureは透過しないようにする。
    if(!self.IsOverlap) {
        vwSaparete.hidden = self.IsvwSaparate;
//        player1.alpha = 1.0f;
//        player2.alpha = 1.0f;
        if(self.IsvwSaparate == NO && _isModeLock == NO) {
//            imgvwPicture1.userInteractionEnabled = YES;
//            imgvwPicture2.userInteractionEnabled = YES;
//            player1.userInteractionEnabled = YES;
//            player2.userInteractionEnabled = YES;
        } else {
//            player1.userInteractionEnabled = NO;
//            player2.userInteractionEnabled = NO;
        }
    } else {
        vwSaparete.hidden = YES;
//        imgvwPicture1.userInteractionEnabled = NO;
//        imgvwPicture2.userInteractionEnabled = NO;
//        imgvwPicture1.alpha = 1.0f;
//        imgvwPicture2.alpha = 1.0f;
//        player1.userInteractionEnabled = NO;
//        player2.userInteractionEnabled = NO;
    }
    
	// スクロール範囲の設定（これがないとスクロールしない）		
	/////[player1 setContentSize:imgvwPicture1.frame.size];
	/////[player2 setContentSize:imgvwPicture2.frame.size];
	player1.scrollEnabled = _isModeLock;
	player2.scrollEnabled = _isModeLock;

	//　制御パレットの位置調整
    CGFloat ofs = (IsOverlap)? (vwSynthesisCtrlPallet.frame.size.width - vwCtrlPallet.frame.size.width) / 2.0f : 0.0f;
#ifdef CALULU_IPHONE
	CGPoint origin = (isPortrait) ? CGPointMake(66.0f - ofs, 414.0f) : CGPointMake(146.0f - ofs, 254.0f);
#else
    CGPoint origin = (isPortrait) ? CGPointMake(304.0f - ofs, 924.0f + uiOffset) : CGPointMake(432.0f - ofs, 668.0f + uiOffset);
#endif
    if (_isDrawMode) {
        //描画のみのモード
        vwSynthesisCtrlPallet.hidden = YES;
        vwCtrlPallet.hidden = YES;
        volumeSlider1.hidden = NO;
        volumeSlider2.hidden = NO;
    } else {
        if (IsOverlap) {
            // 動画移動モード
            vwSynthesisCtrlPallet.hidden = NO;
            vwCtrlPallet.hidden = YES;
            btnSeparateOn.hidden = YES;
            btnSeparateOff.hidden = YES;
            /* BtnPlayerMoveDelete0304
             btnPlayerMove.frame = CGRectMake(CGRectGetMaxX(btnRightTurn2.frame) + 3,
             CGRectGetMinY(btnRightTurn2.frame),
             60, 60);
             [vwSynthesisCtrlPallet addSubview:btnPlayerMove];
             */
        }else{
            vwSynthesisCtrlPallet.hidden = YES;
            vwCtrlPallet.hidden = NO;
            btnSeparateOn.hidden = NO;
            btnSeparateOff.hidden = NO;
            /* BtnPlayerMoveDelete0304
             btnPlayerMove.frame = CGRectMake(CGRectGetMaxX(btnRightTurn.frame) + 3,
             CGRectGetMinY(btnRightTurn.frame),
             60, 60);
             [vwCtrlPallet addSubview:btnPlayerMove];
             BtnPlayerMoveDelete0304 */
        }
        volumeSlider1.hidden = YES;
        volumeSlider2.hidden = YES;
    }
	[vwCtrlPallet setFrame:CGRectMake(origin.x, origin.y, vwCtrlPallet.frame.size.width, vwCtrlPallet.frame.size.height)];
	[vwSynthesisCtrlPallet setFrame:CGRectMake(origin.x, origin.y,
                                               vwSynthesisCtrlPallet.frame.size.width, vwSynthesisCtrlPallet.frame.size.height)];	
	// 制御パレット表示ボタン
//	btnToolBarShow.hidden = (isPortrait)? YES : NO;
    btnToolBarShow.hidden = YES;

	// 制御パレット
	if (isPortrait) 
	{
		vwCtrlPallet.alpha = 1.0f;
        playPallet.alpha = 1.0f;
        rotator1.alpha = 1.0f;
        rotator2.alpha = 1.0f;
	}
	else
	{
		_isToolBar = YES;
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
    
    
    playPallet.layer.cornerRadius = 6.0f;
    playPallet.layer.borderWidth = 1.0f;
    playPallet.layer.borderColor = [UIColor whiteColor].CGColor;
    // ズーミングを再度適用
    player1.zoomScale = zoomScale1;
    player2.zoomScale = zoomScale2;
    player1.contentOffset = contentOffset1;
    player2.contentOffset = contentOffset2;
    // スタンプ
    vwStampE.frame = CGRectMake(0, 0, vwPaintManager.frame.size.width, vwPaintManager.frame.size.height);
    [vwPaintManager addSubview:vwStampE];
}

// ボタン類の位置調整
- (void)uiLayout:(BOOL)isPortrait
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    // iOS7かつNavigationCallでの画面遷移の場合
    if (iOSVersion<7.0f || !IsNavigationCall) return;
    
    float uiOffset = 20.0f;
    
    // ユーザ名
    [viewUserNameBack setFrame: (isPortrait)?
     CGRectMake(461.0f, 12.0f + uiOffset, 287.0f, 30.0f) :
     CGRectMake(461.0f + 256.0f, 12.0f + uiOffset, 287.0f, 30.0f) ];
    
    // 施術日
    [viewWorkDateBack setFrame: (isPortrait)?
     CGRectMake(124.0f, 12.0f + uiOffset, 310.0f, 30.0f) :
     CGRectMake(124.0f + 256.0f, 12.0f + uiOffset, 310.0f, 30.0f) ];
    
    // Lockボタン
    [btnLockMode setFrame: (isPortrait)?
     CGRectMake(20.0f, 10.0f + uiOffset, 54.0f, 54.0f) :
     CGRectMake(20.0f, 10.0f + uiOffset, 54.0f, 54.0f) ];
    
    // Saveボタン
    [btnSave setFrame: (isPortrait)?
     CGRectMake(20.0f, 75.0f + uiOffset, 57.0f, 57.0f) :
     CGRectMake(20.0f, 75.0f + uiOffset, 57.0f, 57.0f) ];
    
    // プリントボタン
    //    [btnHardCopyPrint setFrame: (isPortrait)?
    //     CGRectMake(8.0f, 136.0f + uiOffset, 54.0f, 54.0f) :
    //     CGRectMake(8.0f, 136.0f + uiOffset, 54.0f, 54.0f) ];
    
    // カメラボタン
    //    [btnOverlayCamera setFrame: (isPortrait)?
    //     CGRectMake(8.0f, 12.0f + uiOffset, 54.0f, 54.0f) :
    //     CGRectMake(8.0f, 12.0f + uiOffset, 54.0f, 54.0f) ];
    
    // メール送信ボタン
    //    [btnMailSend setFrame: (isPortrait)?
    //     CGRectMake(64.0f, 136.0f + uiOffset, 54.0f, 54.0f) :
    //     CGRectMake(64.0f, 136.0f + uiOffset, 54.0f, 54.0f) ];
    
}

// デバイスの向きがポートレートかどうかを取得
- (bool)getPortrait
{
	UIDeviceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    return (orientation == UIDeviceOrientationPortrait) ||
           (orientation == UIDeviceOrientationPortraitUpsideDown);
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
	
}

- (UIImage*)setPictureSizeToVGA:(UIImage*)picture
{
	
	// 画像の拡大／縮小
	CGRect rect = CGRectMake(0.0, 0.0, 640, 480);
	UIGraphicsBeginImageContext(rect.size);	
	[picture drawInRect:rect];
	UIImage* imgResize = UIGraphicsGetImageFromCurrentImageContext();	
	UIGraphicsEndImageContext();
	
	// (VGA * INIT_VIMAGE_SCALE)の大きさの黒塗り画像を作成し、その中央にVGAサイズに変更した元画像を貼付ける
	CGRect rect2 = CGRectMake(0.0, 0.0, imgResize.size.width * INIT_VIMAGE_SCALE, imgResize.size.height * INIT_VIMAGE_SCALE);
	UIGraphicsBeginImageContext(rect2.size);
	CGContextRef context = UIGraphicsGetCurrentContext();  // コンテキストを取得
	//CGContextStrokeRect(context, rect2);  // 四角形の描画
    if (IsOverlap) {
        CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.0);  // 塗りつぶしの色を指定
    }else {
        CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);  // 塗りつぶしの色を指定
    }
	CGContextFillRect(context, rect2);  // 四角形を塗りつぶす
	rect = CGRectMake((rect2.size.width / 2) - (imgResize.size.width / 2), 
					  (rect2.size.height / 2) - (imgResize.size.height / 2), imgResize.size.width, imgResize.size.height);
	[imgResize drawInRect:rect];
	UIImage* imgReturn = UIGraphicsGetImageFromCurrentImageContext();	
	UIGraphicsEndImageContext();

	//[imgResize release];
	
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
    swipeGestue.delegate = self;
	[self.view addGestureRecognizer:swipeGestue];
	[swipeGestue release];
	// 左方向スワイプ
    UISwipeGestureRecognizer *swipeGestueLeft = [[UISwipeGestureRecognizer alloc]
												 initWithTarget:self action:@selector(OnSwipeLeftView:)];
	swipeGestueLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	swipeGestueLeft.numberOfTouchesRequired = 1;
    swipeGestueLeft.delegate = self;
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
	player1.scrollEnabled = player2.scrollEnabled = isLock;
	// player1.pagingEnabled = player2.pagingEnabled = ! isLock;
	
	player1.userInteractionEnabled = player2.userInteractionEnabled = isLock;
}

#pragma mark life_cycle

- (void)initWithVideo:(MovieResource *)_movie1 video:(MovieResource *)_movie2 userName:(NSString*)name nameColor:(UIColor*)color workDate:(NSString*)date isDrawMode:(BOOL)isDrawMode{
    
    movie1 = _movie1;
    [movie1 retain];
    movie2 = _movie2;
    [movie2 retain];
    movieDuration1 = movie1.movieDuration; //このプロパティは内部で重い処理を行っているため
    movieDuration2 = movie2.movieDuration;
    if (movie1.movieIsExistsInCash) {
        [player1 setVideoUrl:[[NSURL alloc] initFileURLWithPath:movie1.movieCashPath]];
    } else {
        [player1 setVideoUrl:movie1.movieURL];
    }
    if (movie2.movieIsExistsInCash) {
        [player2 setVideoUrl:[[NSURL alloc] initFileURLWithPath:movie2.movieCashPath]];
    } else {
        [player2 setVideoUrl:movie2.movieURL];
    }
//    [player1 setVideoUrl:movie1.movieURL];
    slider1.otherSlider = slider2;
    slider2.otherSlider = slider1;
    player1.syncPlayer = player2;
    player2.syncPlayer = player1;
//    slider1.syncPlayer = player2.player;
//    slider2.syncPlayer = player1.player;
    
    rotator1.player = player1.player;
    rotator2.player = player2.player;
    rotator1.other = rotator2;
    rotator2.other = rotator1;
    
    player1.userInteractionEnabled = NO;
    player2.userInteractionEnabled = NO;
    
    currentTimeLabel1.text = [NSString stringWithFormat:@"00.0/%04.1f", movieDuration1];
    currentTimeLabel2.text = [NSString stringWithFormat:@"00.0/%04.1f", movieDuration2];
//    currentTimeLabel1.text = [NSString stringWithFormat:@"0:00/%d:%02d", ((int)(movieDuration1 / 60)), ((int)movieDuration1) % 60];
//    currentTimeLabel2.text = [NSString stringWithFormat:@"0:00/%d:%02d", ((int)(movieDuration2 / 60)), ((int)movieDuration2) % 60];
    rangeSlider.minimumValue = 0;
    rangeSlider.maximumValue = movieDuration1;
    rangeSliderRight.minimumValue = 0;
    rangeSliderRight.maximumValue = movieDuration2;
    
    [btnPlay setSelected:NO];
    [btnLockMode setSelected:NO];
    lblPlaySpeed.text = @"100%";
    // NavigationCallによる画面遷移の場合
	if (self.IsNavigationCall)
	{
		// スワイプをセットアップする
		[self setupSwipSupport];
	}
    [self changeToPortrait:(UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
                  initMode:YES];
    
    [vwPaintManager initAfterFrameSet];
#ifndef NO_VIDEO_EDIT
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=6.0f && [AccountManager isMovie]) {
        vwPaintPallet.hidden = NO;
    } else {
        vwPaintPallet.hidden = YES;
        vwVideoEditMode.hidden = YES;
        btnSave.hidden = YES;
    }
#else
    vwPaintPallet.hidden = YES;
    vwVideoEditMode.hidden = YES;
    btnSave.hidden = YES;
//    btnPlayerMove.hidden = YES;
#endif
    // paint系
    // 色選択ボタンの初期化
    UIButton* btn = [[UIButton alloc] init];
    btn.tag = PALLET_DRAW_COLOR+1;
    [vwPaintPallet onBtnColor:btn];
    [btn release];
    [vwPaintPallet setLockState:NO]; //0226
    //vwPaintPallet.userInteractionEnabled = NO;
    //vwPaintPallet.alpha = 0.3f;
    vwPaintManager.userInteractionEnabled = NO;
    // 写真描画の管理クラスに通知
    [vwPaintManager changeLockMode:NO];
    // 管理Viewとフリックボタンのhidden設定
    vwPaintManager.userInteractionEnabled = NO; //0226   YES;
    vwPaintManager.hidden = NO;
	// ユーザ名など
	lblUserName.text = [name mutableCopy];
	lblUserName.textColor = color;
	if (date)
	{
		lblWorkDate.text = [date mutableCopy];
		
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

    // ズーミングを初期化
    player1.zoomScale = 1.0f;
    player2.zoomScale = 1.0f;
    // 表示位置、透過の初期化など
    if (!self.IsOverlap) {
        if (self.IsUpdown) {
            player1.alpha = 1.0f;
            player2.alpha = 1.0f;
            //player1.contentOffset = CGPointMake(player1.contentSize.width/3.88, 0);
            //player1.contentOffset = CGPointMake(-300, 0);
            //player2.contentOffset = CGPointMake(player2.contentSize.width/2, 0);
            player1.contentOffset = CGPointMake(player1.contentSize.width/3,
                                                0);
            player2.contentOffset = CGPointMake(player2.contentSize.width/3,
                                                0);
        }else{
            player1.alpha = 1.0f;
            player2.alpha = 1.0f;
            //player1.contentOffset = CGPointMake(0, 0);
            //player2.contentOffset = CGPointMake(player2.contentSize.width/2, 0);
            player1.contentOffset = CGPointMake(0, 0);
            player2.contentOffset = CGPointMake(player2.contentSize.width/2, 0);
        }
    } else {
        player1.contentOffset = CGPointMake(player1.contentSize.width/3,
                                            player1.contentSize.height/3);
        player2.contentOffset = CGPointMake(player2.contentSize.width/3,
                                            player2.contentSize.height/3);
    }
    _isDrawMode = isDrawMode;
    [self setPaintMode:_isDrawMode];
    [self statusManage];
}
// 動画の位置情報の設定
- (void)setZoom1:(float)zoom1 offset1:(CGPoint)offset1 reverse1:(BOOL)reverse1 zoom2:(float)zoom2 offset2:(CGPoint)offset2 reverse2:(BOOL)reverse2 {
    player1.zoomScale = zoom1;
    player1.contentOffset = offset1;
    if ((player1.isReversed && !reverse1) || (!player1.isReversed && reverse1)) {
        [player1 reverseHorizon];
    }
    player2.zoomScale = zoom2;
    player2.contentOffset = offset2;
    if ((player2.isReversed && !reverse2) || (!player2.isReversed && reverse2)) {
        [player2 reverseHorizon];
    }
}
- (void)setCurrentTime1:(CMTime)time1 currentTime2:(CMTime)time2 {
    [player1.player seekToTime:time1 toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [player2.player seekToTime:time2 toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
- (void)viewDidLoad {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [super viewDidLoad];
    // 背景色の変更 RGB:D8BFD8
//    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:204/255.0f green:149/255.0f blue:187/255.0f alpha:1.0f];
	// ロックモードの初期設定
	_isModeLock = NO;
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
    // BtnPlayerMoveDelete0304 [btnPlayerMove setEnabled:NO];
	//[btnSave setEnabled:NO];
    btnAnimeAdd.enabled = NO;
    
    // 2012 7/13 透過合成パレットの初期化
    [self setCornerRadius:vwSynthesisCtrlPallet];
    vwSynthesisCtrlPallet.hidden = YES;
    vwSynthesisCtrlPallet.backgroundColor = viewUserNameBack.backgroundColor;
	vwSynthesisCtrlPallet.alpha = 0.45f;
    [btnBackOn setEnabled:NO];
	[btnFrontOn setEnabled:NO];
	[sldRatio setEnabled:NO];
    
	// スクロールViewの最大ズーム倍率
	// 2012 6/27 伊藤 余白追加のため最大拡大サイズ変更
	[player1 setMaximumZoomScale:10.0];
	[player2 setMaximumZoomScale:10.0];
    [player1 setMinimumZoomScale:0.3];
    [player2 setMinimumZoomScale:0.3];
    
    // 突き合わせ画像処理時の分割線を隠す
    self.IsvwSaparate = YES;
	// 縦横切り替え
	// この時点でレイアウトを設定しても、横画面で遷移した時はなぜかplayer1のY位置が-256になる。原因は不明。
	// よって、前画面のOnTransitionNewViewDidLoadデリゲートでレイアウト調整関数をコールする。
	//[self changeToPortrait:([[UIScreen mainScreen] applicationFrame].size.height == 768.0f)];
    currentTimeLabel1.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    currentTimeLabel2.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    slider1.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    slider2.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    underCurrentTimeView1.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.8f];
    underCurrentTimeView2.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.8f];
    rangeSlider.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.8f];
    rangeSliderRight.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.8f];
    
    currentTimeLabel1.font = [UIFont systemFontOfSize:11.0f];
    currentTimeLabel1.textColor = [UIColor colorWithWhite:0.3f alpha:1.0f];
    currentTimeLabel1.textAlignment = NSTextAlignmentCenter;
    currentTimeLabel1.adjustsFontSizeToFitWidth = YES;
    
    currentTimeLabel2.font = [UIFont systemFontOfSize:11.0f];
    currentTimeLabel2.textColor = [UIColor colorWithWhite:0.3f alpha:1.0f];
    currentTimeLabel2.textAlignment = NSTextAlignmentCenter;
    currentTimeLabel2.adjustsFontSizeToFitWidth = YES;
    
    rotator1.continuous = YES;
    rotator1.wrapAround = YES;
	rotator1.style = NDRotatorStyleRotate;
    rotator1.thumbTint = (enum NDThumbTint)NDThumbTintBlue;
	rotator2.continuous = YES;
    rotator2.wrapAround = YES;
	rotator2.style = NDRotatorStyleRotate;
    rotator2.thumbTint = (enum NDThumbTint)NDThumbTintBlue;
    
    vwVideoEditMode.backgroundColor = [UIColor colorWithRed:0.38 green:0.45 blue:0.21 alpha:1.0f];
    vwVideoEditMode.layer.cornerRadius = 12.0f;
    vwVideoEditMode.layer.shadowColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
    vwVideoEditMode.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    vwVideoEditMode.layer.shadowOpacity = 1.0f;
    
    // パレットの初期化
    vwPaintManager = [[PicturePaintManagerViewTwoParent alloc] init];
    vwPaintManager.backgroundColor = [UIColor redColor];
	vwPaintPallet = [[PicturePaintPalletView alloc] initWithEventListner:vwPaintManager];
	[self.view addSubview:vwPaintPallet];
	vwPaintPallet.backgroundColor = [UIColor blackColor];
    // 動画編集モードボタンの初期化
    [self setVideoEditButtonEnable:NO];
#ifdef VARIABLE_PICTURE_PAINT_PALLET
    // 動的パレットの初期化
    [vwPaintPallet initVariablePallet:self.view];
#endif
    [vwPaintPallet setupPalletPopup];
	// 写真描画の管理クラスの初期設定
	vwPaintManager.scrollViewParent = player1;
    vwPaintManager.scrollViewParent2 = player2;
	vwPaintManager.vwSaparete = vwSaparete;
    //	vwPaintManager.vwGrayOut1 = vwGrayOut1;
    //	vwPaintManager.vwGrayOut2 = vwGrayOut2;
	vwPaintManager.vwPallet = vwPaintPallet;
    
    //スタンプ
    
    vwStampE = [[UIView alloc] init];
    vwPaintManager.vwStampE = vwStampE;
    
    [vwPaintManager initLocal];
    // 動画ロードまではhidden
#ifndef NO_VIDEO_EDIT
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=6.0f && [AccountManager isMovie]) {
        vwPaintPallet.hidden = NO;
    } else {
        vwPaintPallet.hidden = YES;
        vwVideoEditMode.hidden = YES;
        btnSave.hidden = YES;
    }
#else
    vwPaintPallet.hidden = YES;
    vwVideoEditMode.hidden = YES;
    btnSave.hidden = YES;
//    btnPlayerMove.hidden = YES;
    btnAnimeAdd.hidden = YES;
#endif
    
    rangeSlider.hidden = YES;
    rangeSliderRight.hidden = YES;
    underCurrentTimeView1.hidden = YES;
    underCurrentTimeView2.hidden = YES;
    
    _isModeLock = YES;
    [self OnBtnLockMode:nil];    
    
	// Alertダイアログの初期化
	modifyCheckAlert = [[UIAlertView alloc] init];
	modifyCheckAlert.title = @"画像描画";
	modifyCheckAlert.message = @"編集した画像を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集内容は\n破棄されます）";
	modifyCheckAlert.delegate = self;
	[modifyCheckAlert addButtonWithTitle:@"は　い"];
	[modifyCheckAlert addButtonWithTitle:@"いいえ"];
    
    // view did appear より
    // ズーミングを初期化
    player1.zoomScale = 1.0f;
    player2.zoomScale = 1.0f;
    // 表示位置、透過の初期化など
    if (!self.IsOverlap) {
        if(self.IsUpdown){
            player1.alpha = 1.0f;
            player2.alpha = 1.0f;
            player1.contentOffset = CGPointMake(player1.contentSize.width/3, 0);
            player2.contentOffset = CGPointMake(player2.contentSize.width/1, 0);
        }else{
            player1.alpha = 1.0f;
            player2.alpha = 1.0f;
            player1.contentOffset = CGPointMake(0, 0);
            player2.contentOffset = CGPointMake(player2.contentSize.width/2, 0);
        }
    } else {
        player1.contentOffset = CGPointMake(player1.contentSize.width/3,
                                            player1.contentSize.height/3);
        player2.contentOffset = CGPointMake(player2.contentSize.width/3,
                                            player2.contentSize.height/3);
    }
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
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	[super viewDidAppear : animated];
    
#ifdef CALULU_IPHONE
    CGFloat portrateWith = 320.0f;
#else
    CGFloat portrateWith = 768.0f;
#endif
	
    player1.playDelegate = self;
    player2.playDelegate = self;
    slider1.delegate = self;
    slider2.delegate = self;
    rangeSlider.delegate = self;

	if (self.IsSetLayout)
	{
		// 縦横切り替え
		[self changeToPortrait:([[UIScreen mainScreen] applicationFrame].size.width == portrateWith) initMode:YES];
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

    
	[vwPaintManager allClearCanvas];
	//[vwPaintManager deleteSeparate];
	// [vwPaintPallet1 initBtnSeparate];    // 区分線は使わない
    [vwPaintManager initDrawObject];
    
    _modifyCheckAlertWait = -1;
    
    for (AnimationElement *anime in animations) {
        [anime removeFromSuperview];
    }
    [animations removeAllObjects];
    
    btnAnimeAdd.hidden = YES;
    
    //2012 6/22 伊藤 連続してページ遷移できないよう修正
    //mainVCのスクロールビューの幅設定
    MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC setScrollViewWidth:YES];
    
    [self separateBtnCtrl:NO];

    UIButton* btn = [[UIButton alloc] init];
    btn.tag = PALLET_DRAW_COLOR+1;
    [vwPaintPallet onBtnColor:btn];
    [btn release];
    [vwPaintPallet setLockState:_isModeLock];

    // 各Viewの順番調整
    // vwPaintManagerがplayer1,2の上位にないと、ペン色、太さなどの変更時に
    // playerにかぶったときに操作できないポイントができてしまう
    [self.view sendSubviewToBack:vwPaintManager];
    [self.view sendSubviewToBack:player2];
    [self.view sendSubviewToBack:player1];
}
	
// 縦横切り替え前のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{			
	_toInterfaceOrientation = toInterfaceOrientation;
	
    //[self didRotateFromInterfaceOrientation:toInterfaceOrientation];
	// MainViewController経由で遷移してきた時は、didRotateFromInterfaceOrientationが呼び出されない。理由は未調査。
//	if (! self.IsNavigationCall)
//	{
//		[self didRotateFromInterfaceOrientation:toInterfaceOrientation];
//	}
//	else 
//	{
//		player1.hidden = player2.hidden = YES;
//	}
	BOOL isPortrait;
	
	//switch (_toInterfaceOrientation)
	switch (toInterfaceOrientation)
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
	
	self.IsRotated = YES;
	[self changeToPortrait:isPortrait initMode:NO];
	
	if (self.IsNavigationCall)
	{
		player1.hidden = player2.hidden = NO;
	}
    if (videoCompVCfromThumb && (videoCompVCfromThumb.view.frame.origin.x == 0)) {
        videoCompVCfromThumb.view.frame = self.view.frame;
        [videoCompVCfromThumb willRotateToInterfaceOrientation:toInterfaceOrientation
                                                      duration:0];
    }
}	

// 縦横切り替え後のイベント
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation 
{

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [vwStampE release];
    vwStampE = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    player1.playDelegate = nil;
    player2.playDelegate = nil;
    slider1.delegate = nil;
    slider2.delegate = nil;
    rangeSlider.delegate = nil;
    rangeSliderRight.delegate = nil;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    [vwPaintManager removeObserver:self forKeyPath:@"IsDirty"];
    for (UIView *sv in self.view.subviews) {
        [sv removeFromSuperview];
    }
    rotator1.player = nil;
    rotator2.player = nil;
    rotator1.other = nil;
    rotator2.other = nil;
    vwPaintManager.scrollViewParent = nil;
    vwPaintManager.scrollViewParent2 = nil;
	vwPaintManager.vwSaparete = nil;
	vwPaintManager.vwPallet = nil;

#ifdef DEBUG
    NSLog(@"[%lu, %lu, %lu, %lu, %lu, %lu, %lu,  %lu, %lu]",
          (unsigned long)[player1 retainCount],
          (unsigned long)[player2 retainCount],
          (unsigned long)[slider1 retainCount],
          (unsigned long)[slider2 retainCount],
          (unsigned long)[rotator1 retainCount],
          (unsigned long)[rotator2 retainCount],
          (unsigned long)[rangeSlider retainCount],
          (unsigned long)[movie1 retainCount],
          (unsigned long)[movie2 retainCount]
          );
#endif

    [animations release];
    [lblUserName release];
    [lblWorkDate release];
    [lblWorkDateTitle release];
    [lblPlaySpeed release];
    [viewUserNameBack release];
    [viewWorkDateBack release];
    [btnLockMode release];
    [btnBackOn release];
    [btnFrontOn release];
    [btnLeftTurn release];
    [btnLeftTurn2 release];
    [btnPlay release];
    [btnPlaySpeed release];
    [btnPlaySync release];
    [rotator1 release];
    [rotator2 release];
    [rangeSlider release];
    [rangeSliderRight release];
    [volumeSlider1 release];
    [volumeSlider2 release];
    [currentTimeLabel1 release];
    [currentTimeLabel2 release];
    [underCurrentTimeView1 release];
    [underCurrentTimeView2 release];
    [vwPaintManager release];
//    player2.syncPlayer = nil;
//    player1.syncPlayer = nil;

    // PlayerView のdeallocで [self.playDelegate release] されているため
    // [slider1 release]は実行しない
    [player1 release];
    [player2 release];
    player1.playerDelegate = nil;
    player2.playerDelegate = nil;
    player1.delegate = nil;
    player2.delegate = nil;
    player1.syncPlayer = nil;
    player2.syncPlayer = nil;
    player1.player = nil;
    player2.player = nil;

//    [slider1 asyncStop];
//    [slider2 asyncStop];
//    [slider1 release];
//    [slider2 release];
//    slider1.otherSlider = nil;
//    slider2.otherSlider = nil;
    
    [playPallet release];
    [playRateArray release];
    [vwCtrlPallet release];
    [vwSaparete release];
    [vwSynthesisCtrlPallet release];
    [sldRatio release];
    [movie1 release];
    [movie2 release];
    [vwStampE release];
    if (videoCompVCfromThumb) {
        [videoCompVCfromThumb release];
    }
    [super dealloc];
	
	if (skippedBackgroundView) 
	{
		[skippedBackgroundView release];
	}
}

#pragma mark MainViewControllerDelegate

// 新規View画面への遷移
//		return: 次に表示する画面のViewController  nilで遷移をキャンセル
- (UIViewController*) OnTransitionNewView:(id)sender
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
	
	MainViewController* mainVC = (MainViewController*)sender;
	
	// 画面ロック状態であれば、次に遷移しない:_selectedCount <= 0 と同様
	if ([mainVC isWindowLockState] )
	{	return (nil); }
	// 動画移動画面ならば遷移
	if (_isDrawMode == NO)
	{
		[mainVC skipNextPage:NO];
	}
	else
	{
		// 遷移をキャンセル
		return (nil);
	}
	
	VideoCompViewController  *videoCompVC
    = [[VideoCompViewController alloc]
#ifdef CALULU_IPHONE
       initWithNibName:@"ip_PictureCompViewController" bundle:nil];
#else
initWithNibName:@"VideoCompViewController" bundle:nil];
#endif
	return (videoCompVC);
}
// 新規View画面への遷移でViewがLoadされた後にコールされる
- (void) OnTransitionNewViewDidLoad:(id)sender transitionVC:(UIViewController*)tVC
{
    // tovideocomp
	VideoCompViewController *videoCompVC = (VideoCompViewController*)tVC;
	if (_isDrawMode == NO)
	{
		[videoCompVC setSkip:NO];
        
        videoCompVC.IsOverlap = self.IsOverlap;
        videoCompVC.IsUpdown = self.IsUpdown;
		// 写真の初期化
		[videoCompVC initWithVideo:movie1
                             video:movie2
                          userName:lblUserName.text nameColor:lblUserName.textColor
                          workDate:lblWorkDate.text
                        isDrawMode:YES];
        [videoCompVC setZoom1:player1.zoomScale
                      offset1:player1.contentOffset
                     reverse1:player1.isReversed
                        zoom2:player2.zoomScale
                      offset2:player2.contentOffset
                     reverse2:player2.isReversed];
        [self performSelector:@selector(setCurrentTime:) withObject:videoCompVC afterDelay:0.1f]; // 再生準備ができるまで待つ必要があるから
        //[videoCompVC setCurrentTime1:player1.player.currentTime currentTime2:player2.player.currentTime];
        videoCompVC.IsvwSaparate = self.IsvwSaparate;
        [player1 pause];
        [player2 pause];
        [btnPlay setSelected:NO];
	}
    
	// 施術情報の設定
	[videoCompVC setWorkItemInfo:_userID workItemHistID:_histID];
	
	videoCompVC.IsSetLayout = TRUE;
}
- (void)setCurrentTime:(VideoCompViewController *)videoCompVC {
    [videoCompVC setCurrentTime1:player1.player.currentTime currentTime2:player2.player.currentTime];
}
// 既存View画面への遷移
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC
{
	// NSLog(@"OnTransitionExsitView at SelectVideoViewController");
	// tovideocomp
	VideoCompViewController *videoCompVC = (VideoCompViewController*)tVC;
	MainViewController* mainVC = (MainViewController*)sender;
    
	if (_isDrawMode == NO)
	{
		[mainVC skipNextPage:NO];
		[videoCompVC setSkip:NO];
        
        videoCompVC.IsOverlap = self.IsOverlap;
        videoCompVC.IsUpdown = self.IsUpdown;
        /*
         // 写真の初期化
         [videoCompVC initWithVideo:videoResources[0]
         video:videoResources[1]
         userName:lblUserName.text nameColor:lblUserName.textColor
         workDate:lblWorkDate.text];
         */
        [videoCompVC setZoom1:player1.zoomScale
                      offset1:player1.contentOffset
                     reverse1:player1.isReversed
                        zoom2:player2.zoomScale
                      offset2:player2.contentOffset
                     reverse2:player2.isReversed];
        [videoCompVC setCurrentTime1:player1.player.currentTime currentTime2:player2.player.currentTime];
        videoCompVC.IsvwSaparate = self.IsvwSaparate;
        videoCompVC.view.hidden = NO;
        [player1 pause];
        [player2 pause];
        [btnPlay setSelected:NO];
	}
	else
	{
		[mainVC skipNextPage:NO];
		[videoCompVC setSkip:NO];
        
		// 遷移をキャンセル
		return (NO);
	}
	
	videoCompVC.IsSetLayout = TRUE;
    
	return (YES);				// 画面遷移する
}

// 画面終了の通知
- (BOOL) OnUnloadView:(id)sender
{
	BOOL stat = YES;
    
//    // 前画面に戻る前にImageをクリア
//    self._pictImage1 = nil;
//    self._pictImage2 = nil;
//    ///////[imgvwPicture1 setImage:nil];
//    ///////[imgvwPicture2 setImage:nil];
    
    // ユーザ名と施術日もクリア
    //lblUserName.text = @"";
    //lblWorkDate.text = @"";
     
    if (!player1.hidden) {
            [player1 pause];
    }
    if (!player2.hidden) {
            [player2 pause];
    }
    [btnPlay setSelected:NO];
    
//	if (vwPaintManager.IsDirty || animations.count > 0)
    if (shoudSave)
	{
		// 合成画像が保存されていなければ、alertを表示して画面遷移しない
		[modifyCheckAlert show];
		
		// NavigationCallによるもの
		if (sender == self)
		{
			_modifyCheckAlertWait = -1;
            
			// ダイアログの応答待機
			NSInteger wait;
			while ((wait = _modifyCheckAlertWait) < 0)
			{
				[[NSRunLoop currentRunLoop]
				 runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
			}
			
			// いいえが押された
			if (wait == 1)
			{
                return (NO);
            }
            VideoCompViewController *prevCompVC = [self UpperVideoCompViewController];
            if (prevCompVC) {
                [self setCurrentTime:prevCompVC];
            }
		}
		// MainVCによるもの
		else {
			_modifyCheckAlertWait = 0;
			return (NO);
		}
	} else {
        if (sender == self) {
            // NavigationCallによるもの
            VideoCompViewController *prevCompVC = [self UpperVideoCompViewController];
            if (prevCompVC) {
                [self setCurrentTime:prevCompVC];
            }
        } else {
            // MainVCによるもの
            MainViewController *mainVC
			= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
            UIViewController *prevCompVC = [mainVC getPrevControlWithSelf:self];
            if ([prevCompVC isKindOfClass:[VideoCompViewController class]]) {
                [self setCurrentTime:((VideoCompViewController *)prevCompVC)];
            }
        }
    }
	return (stat);
}

// ロック画面への遷移確認:実装しない場合は遷移可とみなす
- (BOOL) OnDisplayChangeEnable:(id)sender disableReason:(NSMutableString*) message
{
	BOOL stat;
	
	// 編集中の場合は、遷移不可とする
	if (_isDirty || animations.count > 0)
	{
		stat = NO;
		[message appendString:@"(先に保存をしてください)"];
	}
	else 
	{
		stat = YES;
        //		MainViewController* mainVC = (MainViewController*)sender;
        //		// 前ページへ戻る：選択画像一覧画面
        //		[mainVC backBeforePage];
	}
	return (stat);
}

// スクロール実施の確認 : NOを返すとスクロールをキャンセル
// - (BOOL) OnCheckTouchDeleverd:(id)sender touchPoint:(CGPoint)pt touchView:(UIView*)view
- (BOOL) OnCheckScrollPerformed:(id)sender touchView:(UIView*)view
{
    BOOL isPerformed = ! _isModeLock;
    
    // NSLog(@"%s touchPoint x=>%f y=>%f", __func__, pt.x, pt.y);
    
    // ローテータおよびスライダーの場合は、スクロールをキャンセルする
    if ( (slider1 == view) || (slider2 == view) || (rotator1 == view) || (rotator2 == view)) {
        isPerformed = NO;
    }
    
    return (isPerformed);
}
// 画面ロックモード変更
- (void) OnWindowLockModeChange:(BOOL)isLock
{
}
#pragma mark player Delegate
- (void)finishPlayBack {
    // NSLog(@"%s %d %d",__func__, player1.isPlay, player2.isPlay);
    if (isPlaySynth){
        [btnPlay setSelected:NO];
    } else {
        [btnPlay setSelected:player1.isPlay || player2.isPlay];
    }
}

- (void)syncSliderValueChanged:(SyncSlider *)slider {
    if (btnFrameDraw.isSelected) {
        if (slider == slider1) {
            [self rangeSliderValueChanged:rangeSlider changedSliderNum:0];
            [self sliderValueChanged:1];
        
        } else if (slider == slider2) {
            //[self rangeSliderValueChanged:rangeSliderRight changedSliderNum:0];
            if (player1.isFinished == NO) {
                [self rangeSliderValueChanged:rangeSlider changedSliderNum:0];
            }
            [self sliderValueChanged:2];
        }
    }
    if (slider == slider1) {
        float current = CMTimeGetSeconds(player1.player.currentTime);
        currentTimeLabel1.text = [NSString stringWithFormat:@"%04.1f/%04.1f",current,movieDuration1];
    } else if (slider == slider2) {
        float current = CMTimeGetSeconds(player2.player.currentTime);
        currentTimeLabel2.text = [NSString stringWithFormat:@"%04.1f/%04.1f",current,movieDuration2];
    }
}
- (void)rangeSliderValueChanged:(RangeSlider *)slider changedSliderNum:(NSInteger)changedSliderNum{
    [self syncRangeSliders:slider changedSliderNum:changedSliderNum];
    [self sliderValueChanged:0];
}
- (void)sliderValueChanged:(NSInteger)number {
    CGFloat second = slider1.value / TIMESCALE;
    BOOL drawenable = (rangeSlider.selectedMinimumValue <= second &&
                       second <= rangeSlider.selectedMaximumValue);
    // 動画1の上限に達した場合
    if (drawenable && player1.isFinished){
        CGFloat second2 = slider2.value / TIMESCALE;
        drawenable = (rangeSliderRight.selectedMinimumValue <= second2 &&
                           second2 <= rangeSliderRight.selectedMaximumValue);
    }
    vwPaintManager.layer.opacity = (drawenable ? 1.0f: 0.05f); // 描画内容の表示／非表示。 opacity=0にするとタッチが感知されない。
    vwPaintManager.IsDrawenable = drawenable; // 再生位置が描画可能範囲外だと描画できないー＞アラートがでる。
    for (AnimationElement *anime in animations) {
        anime.hidden = !(anime.begin <= second && second <= anime.end);
    }
}
- (void)syncRangeSliders:(RangeSlider *)changeSlider changedSliderNum:(NSInteger)changedSliderNum{
    // 差分
    CGFloat subtract1_2 = CMTimeGetSeconds(CMTimeSubtract(player1.player.currentTime,
                                    player2.player.currentTime));
    if (changeSlider == rangeSlider) {
        if (changedSliderNum == 1) {
            CGFloat v1 = rangeSlider.selectedValue1 - subtract1_2;
            v1 = MIN(v1, rangeSliderRight.maximumValue);
            v1 = MAX(v1, rangeSliderRight.minimumValue);
            rangeSliderRight.selectedValue1 = v1;
        } else if (changedSliderNum == 2){
            CGFloat v2 = rangeSlider.selectedValue2 - subtract1_2;
            v2 = MIN(v2, rangeSliderRight.maximumValue);
            v2 = MAX(v2, rangeSliderRight.minimumValue);
            rangeSliderRight.selectedValue2 = v2;
        } else {
            CGFloat v1 = rangeSlider.selectedValue1 - subtract1_2;
            v1 = MIN(v1, rangeSliderRight.maximumValue);
            v1 = MAX(v1, rangeSliderRight.minimumValue);
            rangeSliderRight.selectedValue1 = v1;
            
            CGFloat v2 = rangeSlider.selectedValue2 - subtract1_2;
            v2 = MIN(v2, rangeSliderRight.maximumValue);
            v2 = MAX(v2, rangeSliderRight.minimumValue);
            rangeSliderRight.selectedValue2 = v2;
        }
    } else if (changeSlider == rangeSliderRight) {
        if (changedSliderNum == 1) {
            CGFloat v1 = rangeSliderRight.selectedValue1 + subtract1_2;
            v1 = MIN(v1, rangeSlider.maximumValue);
            v1 = MAX(v1, rangeSlider.minimumValue);
            rangeSlider.selectedValue1 = v1;
        } else if (changedSliderNum == 2){
            CGFloat v2 = rangeSliderRight.selectedValue2 + subtract1_2;
            v2 = MIN(v2, rangeSlider.maximumValue);
            v2 = MAX(v2, rangeSlider.minimumValue);
            rangeSlider.selectedValue2 = v2;
        } else {
            CGFloat v1 = rangeSliderRight.selectedValue1 + subtract1_2;
            v1 = MIN(v1, rangeSlider.maximumValue);
            v1 = MAX(v1, rangeSlider.minimumValue);
            rangeSlider.selectedValue1 = v1;
            
            CGFloat v2 = rangeSliderRight.selectedValue2 + subtract1_2;
            v2 = MIN(v2, rangeSlider.maximumValue);
            v2 = MAX(v2, rangeSlider.minimumValue);
            rangeSlider.selectedValue2 = v2;
        }
    }
}
- (void)volumeSliderValueChanged:(id)sender {
    if (sender == volumeSlider1) {
        player1.volume = volumeSlider1.value;
    } else if (sender == volumeSlider2){
        player2.volume = volumeSlider2.value;
    }
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
    [vwPaintPallet setLockState:_isModeLock];

    // デフォルトは画像移動可能状態とする
//    btnPlayerMove.selected = _isModeLock;
    
//    [self separateBtnCtrl:btnPlayerMove.isSelected];
    self.IsvwSaparate = YES;
    vwSaparete.hidden = YES;
    player1.grayOutEnable = NO;
    player2.grayOutEnable = NO;

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

	/*
	[btnSave setImage:(_isModeLock)? 
	 [UIImage imageNamed:@"save_normal.png"] : [UIImage imageNamed:@"save_disable.png"]
				 forState:UIControlStateNormal];
	[btnSave setEnabled:_isModeLock];
	*/
    
    // 動画描画モード
    [self setVideoEditButtonEnable:_isModeLock];
    //2012 7/13 透過合成関係
    [btnFrontOn setEnabled:_isModeLock];
    [btnBackOn setEnabled:_isModeLock];
    [sldRatio setEnabled:_isModeLock];
    vwSynthesisCtrlPallet.alpha = vwCtrlPallet.alpha;

    // 突き合わせの分割線が表示されているときに、タップによるグレイアウトを有効にする
    if(!self.IsOverlap) {
        if(self.IsvwSaparate == NO && _isModeLock == YES) {
            player1.userInteractionEnabled = YES;
            player2.userInteractionEnabled = YES;
        }
    } else {
        [self OnSetControllView:btnFrontOn];
    }
    
    // 写真描画の管理クラスに通知
    //[vwPaintManager changeLockMode:_isModeLock];
    [self statusManage];
}
- (IBAction)OnBtnVideoEditModeChange:(id)sender {
    UIButton *videoEditButton = sender;
    if (videoEditButton == btnWindowDraw) {
        if (btnFrameDraw.isSelected && vwPaintManager.IsDirty) {
            
            [UIAlertView displayAlertWithTitle:@"動画編集モードの変更"
                                       message:@"モードを変更すると、編集した内容が失われます。よろしいですか？"
                               leftButtonTitle:@"はい"
                              leftButtonAction:^(void){
                                  [self clearCanvas];
                                  [self setFrameDrawMode:NO];
                              }
                              rightButtonTitle:@"いいえ"
                             rightButtonAction:^(void){
                                 return;
                             }];
        } else {
            
            [self setFrameDrawMode:NO];
        }
    } else if(videoEditButton == btnFrameDraw) {
        if (btnWindowDraw.isSelected && vwPaintManager.IsDirty) {
            
            [UIAlertView displayAlertWithTitle:@"動画編集モードの変更"
                                       message:@"モードを変更すると、編集した内容が失われます。よろしいですか？"
                               leftButtonTitle:@"はい"
                              leftButtonAction:^(void){
                                  [self clearCanvas];
                                  [self setFrameDrawMode:YES];
                              }
                              rightButtonTitle:@"いいえ"
                             rightButtonAction:^(void){
                                 return;
                             }];
        } else {
            [self setFrameDrawMode:YES];
        }
    }
    [self statusManage];
}
- (void)clearCanvas {
    
	[vwPaintManager allClearCanvas];
	//[vwPaintManager1 deleteSeparate];
    [vwPaintManager initDrawObject];
    vwPaintManager.IsDirty = NO;
    for (AnimationElement *anime in animations) {
        [anime removeFromSuperview];
    }
    [animations removeAllObjects];
}
- (void)setFrameDrawMode:(BOOL)isFrameDraw {
    [btnWindowDraw setSelected:!isFrameDraw];
    [btnFrameDraw setSelected:isFrameDraw];
    rangeSlider.hidden = !isFrameDraw;
    rangeSliderRight.hidden = !isFrameDraw;
    underCurrentTimeView1.hidden = !isFrameDraw;
    underCurrentTimeView2.hidden = !isFrameDraw;
    btnAnimeAdd.hidden = !isFrameDraw;
    //vwPaintManager.brightness = isFrameDraw ? 0.1f : 0.0f;
    vwPaintManager.alpha = isFrameDraw ? 0.5f : 1.0f;
}
// 動画編集ボタンを使えるように
- (void) setVideoEditButtonEnable:(BOOL)isEnable {
    btnWindowDraw.enabled = isEnable;
    btnFrameDraw.enabled = isEnable;
    if (isEnable) {
        if (btnFrameDraw.isSelected) {
            [btnWindowDraw setSelected:NO];
            [btnFrameDraw setSelected:YES];
        } else {
            [btnWindowDraw setSelected:YES];
            [btnFrameDraw setSelected:NO];
        }
    }
}
// 制御パレットボタン
- (IBAction) OnBtnCtrlPallet:(id)sender
{
	UIButton* btn = (UIButton*)sender;
	
	if (btn.tag == PALLET_SEPARATE_ON)
	{
        self.IsvwSaparate = NO;
		vwSaparete.hidden = NO;
//        vwPaintManager.userInteractionEnabled = NO;
//		player1.userInteractionEnabled = YES;
//		player2.userInteractionEnabled = YES;
        player1.grayOutEnable = YES;
        player2.grayOutEnable = YES;
		[btn setImage:[UIImage imageNamed:@"separate_normal.png"] forState:UIControlStateNormal];
		[btnSeparateOff setImage:[UIImage imageNamed:@"separate_delete_normal.png"] forState:UIControlStateNormal];
		[btnSeparateOff setEnabled:YES];
        [self.view addSubview:vwSaparete];
	}
	else if (btn.tag == PALLET_SEPARATE_OFF)
	{
        self.IsvwSaparate = YES;
		vwSaparete.hidden = YES;
//		player1.userInteractionEnabled = NO;
//		player2.userInteractionEnabled = NO;
        player1.grayOutEnable = NO;
        player2.grayOutEnable = NO;
		player1.alpha = 1.0f;
		player2.alpha = 1.0f;
		[btnSeparateOn setImage:[UIImage imageNamed:@"separate_write_normal.png"] forState:UIControlStateNormal];
		[btn setImage:[UIImage imageNamed:@"separate_delete_disable.png"] forState:UIControlStateNormal];
		[btn setEnabled:NO];
	}
	else if (btn.tag == PALLET_LEFT_TURN)
	{
        [player1 reverseHorizon];
		//[self reverseImage:imgvwPicture1];
	}
	else if (btn.tag == PALLET_RIGHT_TURN)
	{
        [player2 reverseHorizon];
		//[self reverseImage:imgvwPicture2];
	}
	else if (btn.tag == PALLET_SAVE)
	{
		// 合成画像作成
		///////[self makeCombinedImage];
		
		// 合成画像のファイル保存とDB更新
		//[self saveImageFile:self._pictImageMixed];
	}
    
//    [self scrollControl:vwPaintManager.scrollViewParent enable:btnPlayerMove.isSelected];
//    [self scrollControl:vwPaintManager.scrollViewParent2 enable:btnPlayerMove.isSelected];
}

// 動画のスクロール制御
-(void) scrollControl:(UIScrollView*)scview enable:(BOOL)enable
{
    scview.scrollEnabled = enable;
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
    player2.alpha = slider.value;
}

- (IBAction)OnSetControllView:(id)sender{
    UIButton* selectBtn = sender;
    if (selectBtn == btnBackOn) {
        player1.userInteractionEnabled = YES;
        player2.userInteractionEnabled = NO;
        [btnBackOn setImage:[UIImage imageNamed:@"kari_button_BackOn_select"] forState:UIControlStateNormal];
        [btnFrontOn setImage:[UIImage imageNamed:@"kari_button_BackOn"] forState:UIControlStateNormal];
    }else if(selectBtn == btnFrontOn){
        player1.userInteractionEnabled = NO;
        player2.userInteractionEnabled = YES;
        [btnBackOn setImage:[UIImage imageNamed:@"kari_button_BackOn"] forState:UIControlStateNormal];
        [btnFrontOn setImage:[UIImage imageNamed:@"kari_button_FrontOn_select"] forState:UIControlStateNormal];
    }
}

- (void)statusManage {
    if (_isModeLock) {
        /* BtnPlayerMoveDelete0304
        [btnPlayerMove setEnabled:YES];
         */
        if (_isDrawMode) {
#ifndef NO_VIDEO_EDIT
            if ([AccountManager isMovie]) {
                // 描画
                vwPaintPallet.alpha = 1.0f;
                vwPaintPallet.userInteractionEnabled = YES;
                vwPaintPallet.hidden = NO;
                vwPaintManager.userInteractionEnabled = YES;
            }
#endif
        } else {
            // プレイヤーの移動
            vwCtrlPallet.alpha = 1.0f;
            vwSynthesisCtrlPallet.alpha = 1.0f;
            vwCtrlPallet.userInteractionEnabled = YES;
            vwSynthesisCtrlPallet.userInteractionEnabled = YES;
        }
        if (btnFrameDraw.isSelected) {
            rangeSlider.hidden = NO;
            rangeSliderRight.hidden = NO;
            underCurrentTimeView1.hidden = NO;
            underCurrentTimeView2.hidden = NO;
            btnAnimeAdd.hidden = NO;
        } else {
            rangeSlider.hidden = YES;
            rangeSliderRight.hidden = YES;
            underCurrentTimeView1.hidden = YES;
            underCurrentTimeView2.hidden = YES;
            btnAnimeAdd.hidden = YES;
        }
    } else {
        // ロック解除
        // [self setPaintMode:NO];
        //[btnPlayerMove setEnabled:NO];  BtnPlayerMoveDelete0304
        // アニメ系
        btnAnimeAdd.hidden = YES;
        rangeSlider.hidden = YES;
        rangeSliderRight.hidden = YES;
        underCurrentTimeView1.hidden = YES;
        underCurrentTimeView2.hidden = YES;
        
        if (_isDrawMode) {
#ifndef NO_VIDEO_EDIT
            if ([AccountManager isMovie]) {
                // 描画
                vwPaintPallet.alpha = 0.3f;
                vwPaintPallet.userInteractionEnabled = NO;
                vwPaintPallet.hidden = NO;
                [vwPaintPallet unselectStampIfSelected];
                vwPaintManager.userInteractionEnabled = NO;
            }
#endif
        } else {
            // プレイヤーの移動
            vwCtrlPallet.alpha = 0.3f;
            vwSynthesisCtrlPallet.alpha = 0.3f;
            vwCtrlPallet.userInteractionEnabled = NO;
            vwSynthesisCtrlPallet.userInteractionEnabled = NO;
        }
    }
}
// 描画の可否
- (void)setPaintMode:(BOOL)_paintMode {
    //if (vwPaintManager.userInteractionEnabled != _paintMode) {
    //[vwPaintPallet setLockState:NO];
    //vwPaintPallet.userInteractionEnabled = _paintMode;
    //vwPaintPallet.alpha = _paintMode ? 1.0f : 0.3f;
#ifndef NO_VIDEO_EDIT
    if([AccountManager isMovie]) {
        vwPaintPallet.userInteractionEnabled = _paintMode;
        vwPaintPallet.hidden = !_paintMode;
        btnSave.hidden = !_paintMode;
        if (!_paintMode) {
            [vwPaintPallet _closeAllPalletPopup];
        }
    }
#endif
    vwPaintManager.userInteractionEnabled = _paintMode;
#ifdef VIDEO_SIMPLE_EDIT
    vwVideoEditMode.hidden = YES;
#else
    vwVideoEditMode.hidden = !_paintMode;
#endif
    
    //vwCtrlPallet
    //}
}

-(void) separateBtnCtrl:(BOOL)enable
{
	if (vwSaparete.hidden) {
		[btnSeparateOn setImage:(enable)?
         [UIImage imageNamed:@"separate_write_normal.png"] : [UIImage imageNamed:@"separate_write_disable.png"]
                       forState:UIControlStateNormal];
		[btnSeparateOn setEnabled:enable];
		[btnSeparateOff setImage:[UIImage imageNamed:@"separate_delete_disable.png"] forState:UIControlStateNormal];
	}else {
		[btnSeparateOn setImage:(enable)?
		 [UIImage imageNamed:@"separate_normal.png"] : [UIImage imageNamed:@"separate_disable.png"]
					   forState:UIControlStateNormal];
		[btnSeparateOn setEnabled:enable];
		[btnSeparateOff setImage:(enable)?
		 [UIImage imageNamed:@"separate_delete_normal.png"] : [UIImage imageNamed:@"separate_delete_disable.png"]
						forState:UIControlStateNormal];
		[btnSeparateOff setEnabled:enable];
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
		// 現時点で最上位のViewController(=self)を削除する
		//[self.navigationController popViewControllerAnimated:YES];
        //self.view.hidden = YES;
        if ([self OnUnloadView:self]) {
            CGRect vf = self.view.frame;
            [UIView animateWithDuration:0.4 animations:^(void){
                self.view.frame = CGRectMake(vf.size.width, vf.origin.y, vf.size.width, vf.size.height);
            } completion:^(BOOL flg){
                self.view.hidden = YES;
            }];
        }
	}
}

// 左方向のスワイプイベント
- (void)OnSwipeLeftView:(id)sender
{
	// ロックモードの時は何もしない
	if (_isModeLock)
	{	return; }
    // 突き合わせ画面描画モードのときは何もしない
    if (_isDrawMode) {
        return;
    }
    [self OnVideoCompView:nil];
    /*
    if (vwPaintManager.IsDirty) {
		// 合成動画が保存されていなければ、alertを表示して画面遷移しない
		[modifyCheckAlert show];
		
		// ダイアログの応答待機
		NSInteger wait;
		while ((wait = _modifyCheckAlertWait) < 0)
		{
			[[NSRunLoop currentRunLoop]
             runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
		}
		
		// はいが押された
		if (wait == 1)
		{ return; }
    }
     */
}
// 動画合成画面へ遷移
- (void)OnVideoCompView:(id)sender
{
    //tovideocomp
	MainViewController* mainVC = (MainViewController*)sender;
	
	// 画面ロック状態であれば、次に遷移しない:_selectedCount <= 0 と同様
	if ([mainVC isWindowLockState] )
	{	return; }

    BOOL needToCreateNewCompVC = YES;
    if (videoCompVCfromThumb) {
        needToCreateNewCompVC = NO;
        videoCompVCfromThumb.view.hidden = NO;
    } else {
        videoCompVCfromThumb = [[VideoCompViewController alloc]
                                initWithNibName:@"VideoCompViewController" bundle:nil];
    }
    
    
    
    if (!needToCreateNewCompVC) {
        if (videoCompVCfromThumb.IsOverlap && !self.IsOverlap){
            //透過ー＞突き合わせ
            [videoCompVCfromThumb setZoom1:1.0f
                                   offset1:CGPointZero
                                  reverse1:NO
                                     zoom2:1.0f
                                   offset2:CGPointMake(364, 0)
                                  reverse2:NO];
        } else if (!videoCompVCfromThumb.IsOverlap && self.IsOverlap){
            //突き合わせー＞透過
            [videoCompVCfromThumb setZoom1:1.0f
                                   offset1:CGPointMake(728, 546)
                                  reverse1:NO
                                     zoom2:1.0f
                                   offset2:CGPointMake(728, 546)
                                  reverse2:NO];
        }
    }
    videoCompVCfromThumb.IsOverlap = self.IsOverlap;
    videoCompVCfromThumb.IsUpdown = self.IsUpdown;
    
	videoCompVCfromThumb.IsNavigationCall = YES;
    [videoCompVCfromThumb setSkip:NO];
    if (needToCreateNewCompVC) {
        // 動画の初期化
        [videoCompVCfromThumb initWithVideo:movie1
                                      video:movie2
                                   userName:lblUserName.text
                                  nameColor:lblUserName.textColor
                                   workDate:lblWorkDate.text
                                 isDrawMode:YES];
        // 施術情報の設定
        [videoCompVCfromThumb setWorkItemInfo:_userID workItemHistID:_histID];
        
    }
    
    videoCompVCfromThumb.IsSetLayout = TRUE;
    videoCompVCfromThumb.IsvwSaparate = self.IsvwSaparate;
    [player1 pause];
    [player2 pause];
    [btnPlay setSelected:NO];
    
	// 動画合成画面の表示
	//[self.navigationController pushViewController:videoCompVC animated:YES];
    [self.view addSubview:videoCompVCfromThumb.view];
    CGRect vf = videoCompVCfromThumb.view.frame;
    videoCompVCfromThumb.view.frame = CGRectMake(vf.size.width, vf.origin.y, vf.size.width, vf.size.height);
    [videoCompVCfromThumb clearCanvas]; // 描画内容をクリア
    
    
    [videoCompVCfromThumb setZoom1:player1.zoomScale
                  offset1:player1.contentOffset
                 reverse1:player1.isReversed
                    zoom2:player2.zoomScale
                  offset2:player2.contentOffset
                          reverse2:player2.isReversed];
    [self performSelector:@selector(setCurrentTime:) withObject:videoCompVCfromThumb afterDelay:0.1f]; // 再生準備ができるまで待つ必要があるから
    //[videoCompVCfromThumb setCurrentTime1:player1.player.currentTime currentTime2:player2.player.currentTime];
    [UIView animateWithDuration:0.4 animations:^(void){
        videoCompVCfromThumb.view.frame = CGRectMake(0, vf.origin.y, vf.size.width, vf.size.height);
        if (!needToCreateNewCompVC) {
            [videoCompVCfromThumb willRotateToInterfaceOrientation:
             [UIApplication sharedApplication].statusBarOrientation
                                                          duration:0];
        }
    }];
    
	[videoCompVCfromThumb setSkip:NO];
}
- (VideoCompViewController *)UpperVideoCompViewController {
    for (UIView* next = [self.view superview]; next; next = next.superview)
    {
        UIResponder* nextResponder = [next nextResponder];
        
        if ([nextResponder isKindOfClass:[VideoCompViewController class]])
        {
            return (VideoCompViewController*)nextResponder;
        }
    }
    return nil;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (_isModeLock) {
        return NO;
    }
    // 動画合成画面が上に乗っているときはスワイプ不可
    if (videoCompVCfromThumb && (videoCompVCfromThumb.view.frame.origin.x == 0))
    {
        return NO;
    }
    return YES;
}
#pragma mark UIAlertViewDelegate

// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// 合成画像保存確認の場合
	if (alertView == modifyCheckAlert)
	{
		// MainVCによる場合で「はい」がタップされた場合
		if ( (_modifyCheckAlertWait == 0) && (buttonIndex == 0))
		{
			// MainViewControllerの取得
			MainViewController *mainVC
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
            // 動画の再生位置を調整
            UIViewController *prevCompVC = [mainVC getPrevControlWithSelf:self];
            if ([prevCompVC isKindOfClass:[VideoCompViewController class]]) {
                [self setCurrentTime:((VideoCompViewController *)prevCompVC)];
            }
			// 前画面に戻る
			[mainVC backBeforePage];
		}
		
		// 押されたボタンを保存
		_modifyCheckAlertWait = buttonIndex;
        
		// 合成と画像編集の編集フラグをクリア
        if(buttonIndex == 0) {
            [self clearCanvas]; // キャンバスをクリア
            vwPaintManager.IsDirty = NO;
            shoudSave = NO;     //
        }
	}
	
	// alertの表示を消す
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
	
	// 描画領域のクリアなど終了処理
	// [self onDestoryView];
	
}

#pragma mark UIScrollViewDelegate

// ピンチ（ズーム）機能：これがないとピンチしない
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	// このviewがscroll対象のviewとなる
	UIView *view = nil;
	
//	if (scrollView == player1) {
//		view = imgvwPicture1; ////
//	}else if (scrollView == player2) {
//		view = imgvwPicture2; ////
//	}
	
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
- (void)setSync:(BOOL)sync {
    player1.isSync = player2.isSync = slider1.isSync = slider2.isSync = rotator1.isSync = rotator2.isSync = sync;
    [btnPlaySync setSelected:sync];
    
    if (sync) {
        slider1.syncMin = kCMTimeZero;
        slider2.syncMin = kCMTimeZero;
        slider1.syncMax = player1.player.currentItem.duration;
        slider2.syncMax = player2.player.currentItem.duration;
        if (CMTimeCompare(player1.player.currentTime, player2.player.currentTime) > 0) {
            // 再生済み時間が長いのはPlayer1
            slider1.syncMin = CMTimeSubtract(player1.player.currentTime, player2.player.currentTime);
        } else {
            slider2.syncMin = CMTimeSubtract(player2.player.currentTime, player1.player.currentTime);
        }
        if (CMTimeCompare(CMTimeSubtract(player1.player.currentItem.duration, player1.player.currentTime),
                          CMTimeSubtract(player2.player.currentItem.duration, player2.player.currentTime)) > 0) {
            // 残り時間が長いのはPlayer1
            slider1.syncMax = CMTimeAdd(player1.player.currentTime,
                                        CMTimeSubtract(player2.player.currentItem.duration, player2.player.currentTime));
        } else {
            slider2.syncMax = CMTimeAdd(player2.player.currentTime,
                                        CMTimeSubtract(player1.player.currentItem.duration, player1.player.currentTime));
        }
    }
    
    if (sync) {
        rangeSlider.selectedValue1 = 0;
        rangeSlider.selectedValue2 = CMTimeGetSeconds(player1.player.currentItem.duration);
        rangeSlider.minimumLimitValue = MAX(rangeSlider.minimumValue,
                                            CMTimeGetSeconds(CMTimeSubtract(player1.player.currentTime,
                                                                            player2.player.currentTime)));
        rangeSlider.maximumLimitValue = MIN(rangeSlider.maximumValue,
                                            CMTimeGetSeconds(CMTimeAdd(player1.player.currentTime,
                                                                       CMTimeSubtract(player2.player.currentItem.duration,
                                                                                      player2.player.currentTime))));
        
        rangeSliderRight.minimumLimitValue = MAX(rangeSliderRight.minimumValue,
                                            CMTimeGetSeconds(CMTimeSubtract(player2.player.currentTime,
                                                                            player1.player.currentTime)));
        rangeSliderRight.maximumLimitValue = MIN(rangeSliderRight.maximumValue,
                                            CMTimeGetSeconds(CMTimeAdd(player2.player.currentTime,
                                                                       CMTimeSubtract(player1.player.currentItem.duration,
                                                                                      player1.player.currentTime))));
    } else {
        rangeSlider.minimumLimitValue = 0;
        rangeSlider.maximumLimitValue = CMTimeGetSeconds(player1.player.currentItem.duration);
        rangeSliderRight.minimumLimitValue = 0;
        rangeSliderRight.maximumLimitValue = CMTimeGetSeconds(player2.player.currentItem.duration);
    }
    [self statusManage];
}
#pragma mark 動画関連のボタン
- (IBAction)OnPlay {
    if ((!player1.hidden) && (!player2.hidden)) {
        // プレイヤーが２つの場合
        if (btnPlaySync.selected) {
            // 同期
            if ((!player1.isPlay) && (!player2.isPlay)) {
                if (player1.isFinished || player2.isFinished){
#ifdef SYNC_PLAY_RESTRAT_PLATBACK
                    // 巻き戻し時間
                    CMTime back;
                    if (CMTimeCompare(player1.player.currentTime, player2.player.currentTime) < 0) {
                        back = player1.player.currentTime;
                    } else {
                        back = player2.player.currentTime;
                    }
                    // どちらかが再生終了
                    [player1.player seekToTime:CMTimeSubtract(player1.player.currentTime, back) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
                    [player2.player seekToTime:CMTimeSubtract(player2.player.currentTime, back) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
                    sleep(1); // 間を空けないとplayer.currentTimeに反映されない
#else
                    // 同期再生で、どちらかが終了している場合は、いかなる場合も先頭から再生
                    [player1.player seekToTime:kCMTimeZero];
                    [player2.player seekToTime:kCMTimeZero];
#endif
                }
                [player1 play];
                [player2 play];
            } else {
                [player1 pause];
                [player2 pause];
            }
        } else {
            // 同期ではない
            if ((!player1.isPlay) && (!player2.isPlay)) {
                if ((!player1.isFinished) && player2.isFinished) {
                    //片方が再生終了
                    [player1 play];
                } else if(player1.isFinished && (!player2.isFinished)){
                    //片方が再生終了
                    [player2 play];
                } else {
                    //両方が再生終了か再生終了前
                    [player1 play];
                    [player2 play];
                }
            } else {
                [player1 pause];
                [player2 pause];
            }
        }
    } else {
        if (!player1.hidden) {
            if(!player1.isPlay){
                [player1 play];
            } else {
                [player1 pause];
            }
        }
        if (!player2.hidden) {
            if (!player2.isPlay) {
                [player2 play];
            } else {
                [player2 pause];
            }
        }
    }
    [btnPlay setSelected:player1.isPlay || player2.isPlay];
}
- (IBAction)OnPlaySynth {
    isPlaySynth = !isPlaySynth;
    [self setSync:isPlaySynth];
}
- (IBAction)OnPlaySpeed {
    CGFloat speed = player1.playRate;
    for (int i = 0; i < playRateArray.count; i++) {
        if ([(NSNumber *)playRateArray[i] floatValue] == speed) {
            player1.playRate = [(NSNumber *)playRateArray[(i + 1) % playRateArray.count] floatValue];
            player2.playRate = player1.playRate;
            
            lblPlaySpeed.text = [NSString stringWithFormat:@"%d%%",(int)(player1.playRate * 100)];
            return;
        }
    }
}
- (IBAction)OnSave {

    // ２度押し禁止
    if (isSaving) {
        return;
    }
    isSaving = YES;
    // 写真描画の管理クラスに通知
    // 未確定スタンプを確定させるために一旦ロックモードを外す
    [vwPaintManager changeLockMode:!_isModeLock];
    [vwPaintManager changeLockMode:_isModeLock];
    
    if (btnFrameDraw.selected) {
        if (vwPaintManager.IsDirty) {
            [self OnAnimeAdd];
        }
    } else if (btnWindowDraw.selected){
        [animations removeAllObjects]; // 本来０のはず
        AnimationElement *anime = [[AnimationElement alloc] initWithFrame:CGRectMake(0, 0,
                                                                                     vwPaintManager.frame.size.width,
                                                                                     vwPaintManager.frame.size.height)];
        anime.image = [self canvasImage:vwPaintManager];
        anime.begin = 0.0f;
        anime.end = CMTimeGetSeconds(player1.player.currentItem.duration);
        [animations addObject:anime];
        [anime release];
    }
    if (!self.IsvwSaparate) {
        CGRect canvasRect = vwPaintManager.frame;
        CGSize saparateSize = CGSizeMake(4.0f, canvasRect.size.height);
        AnimationElement *anime =
        [[AnimationElement alloc] initWithFrame:CGRectMake((canvasRect.size.width - saparateSize.width) * 0.5f,
                                                           0 ,
                                                           saparateSize.width,
                                                           canvasRect.size.height)];
        anime.image = [VideoCompViewController blackImage:saparateSize];
        anime.begin = 0.0f;
        anime.end = CMTimeGetSeconds(player1.player.currentItem.duration);
        [animations addObject:anime];
        [anime release];
    }
    asset1 = nil;
    
    [SVProgressHUD showWithStatus:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
    [self setNoPreferdVideo];
    //asset1 = movie1.videoAsset;
    //asset2 = movie2.videoAsset;
    //[self hoge];
}

- (void)willResignActive {
    [btnPlay setSelected:NO];
    [player1 pause];
    [player2 pause];
}
+ (UIImage *)blackImage:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage*)resizedImage:(UIImage*)img size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* resized_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized_image;
}
- (void)dismissProgress {
    [SVProgressHUD dismiss];
    
    [Common showDialogWithTitle:@"動画" message:@"動画の合成に失敗しました。"];
}
- (void)videoSave {
    //*******************
    //* アセットを２つ用意
    //*******************
    //AVAsset *asset1 = movie1.videoAsset;
    //AVAsset *asset2 = movie2.videoAsset;
    AVAssetTrack *assetTrack1 = [[asset1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *assetTrack2 = [[asset2 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    // NSLog(@"%f  %f",CMTimeGetSeconds(asset1.duration), CMTimeGetSeconds(asset2.duration));
    //*******************
    // 作成動画のどの点から、素材動画のs秒目からe秒目の部分を挿入するか
    //*******************
    CGFloat current1 = CMTimeGetSeconds(player1.player.currentTime);
    CGFloat current2 = CMTimeGetSeconds(player2.player.currentTime);
    CGFloat remain1 = CMTimeGetSeconds(player1.player.currentItem.duration) - current1;
    CGFloat remain2 = CMTimeGetSeconds(player2.player.currentItem.duration) - current2;
    
    CGFloat before = MIN(current1, current2); //現在の再生位置から何秒戻れるか
    CGFloat after = MIN(remain1, remain2);    //現在の再生位置から何秒進めるか
    CGFloat start1 = current1 - before;
    CMTimeRange range1 = CMTimeRangeMake(CMTimeMake((current1 - before) * TIMESCALE, TIMESCALE),
                                         CMTimeMake((before + after) * TIMESCALE, TIMESCALE));
    CMTimeRange range2 = CMTimeRangeMake(CMTimeMake((current2 - before) * TIMESCALE, TIMESCALE),
                                         CMTimeMake((before + after) * TIMESCALE, TIMESCALE));
    CMTimeRange allRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake((before + after) * TIMESCALE, TIMESCALE));
    //Affine変換系
    CGSize naturalSize1 = [VideoCompViewController naturalSizeOfAVAsset:asset1];
    //[MovieResource naturalSizeOfAVPlayer:player1.player];
    CGSize naturalSize2 = [VideoCompViewController naturalSizeOfAVAsset:asset2];
    //[MovieResource naturalSizeOfAVPlayer:player2.player];
    BOOL isHeightLong1 = naturalSize1.width <= naturalSize1.height; // 縦動画
    BOOL isHeightLong2 = naturalSize2.width <= naturalSize2.height; // 縦動画

    CGFloat scale1 = 640 / naturalSize1.width * player1.zoomScale;
    if (isHeightLong1) {
        scale1 = 480 / naturalSize1.height * player1.zoomScale;
    }
    CGFloat scale2 = 640 / naturalSize2.width * player2.zoomScale;
    if (isHeightLong2) {
        scale2 = 480 / naturalSize2.height * player2.zoomScale;
    }
    CGPoint offset1 = player1.contentOffset;
    CGPoint offset2 = player2.contentOffset;
    BOOL reverse1 = player1.isReversed;
    BOOL reverse2 = player2.isReversed;
#ifdef DEBUG
    CGSize  size1 = player1.contentSize;
#endif
    //CGSize  size2 = player2.contentSize;
    if (IsOverlap) {
        offset1 = CGPointMake((player1.frame.size.width * player1.zoomScale - offset1.x) * 480 / player1.frame.size.height,
                              (player1.frame.size.height* player1.zoomScale - offset1.y) * 480 / player1.frame.size.height);
        offset2 = CGPointMake((player2.frame.size.width * player2.zoomScale - offset2.x) * 480 / player2.frame.size.height,
                              (player2.frame.size.height * player2.zoomScale- offset2.y) * 480 / player2.frame.size.height);
    } else {
        if(IsUpdown){
            offset1 = CGPointMake((player1.frame.size.width * player1.zoomScale - offset1.x) * 480 / player1.frame.size.height,
                                  (player1.frame.size.height* player1.zoomScale - offset1.y) * 480 / player1.frame.size.height);
            offset2 = CGPointMake((player2.frame.size.width * player2.zoomScale - offset2.x) * 480 / player2.frame.size.height,
                                  (player2.frame.size.height * player2.zoomScale- offset2.y) * 480 / player2.frame.size.height);
        }else{

//        offset1 = CGPointMake(-1 * offset1.x * naturalSize1.height / player1.frame.size.height,
//                              -1 * offset1.y * naturalSize1.height / player1.frame.size.height);
//        offset2 = CGPointMake((player1.frame.size.width - offset2.x) * naturalSize2.height / player2.frame.size.height,
//                              -1 * offset2.y * naturalSize2.height / player2.frame.size.height);
            offset1 = CGPointMake(-1 * offset1.x * 480 / player1.frame.size.height,
                              -1 * offset1.y * 480 / player1.frame.size.height);
            offset2 = CGPointMake((player1.frame.size.width - offset2.x) * naturalSize2.height / player2.frame.size.height,
                              -1 * offset2.y * naturalSize2.height / player2.frame.size.height);
        }
    }
#ifdef DEBUG
    NSLog(@"pW1:%f  off2:%f  nH2:%f pH:%f Z:%f",player2.frame.size.width, offset2.x, naturalSize2.height, player2.frame.size.height,player2.zoomScale);
    NSLog(@"pW1:%f  off2:%f  nH2:%f pH:%f Z:%f",player2.frame.size.width, offset2.x, naturalSize2.height, player2.frame.size.height,player2.zoomScale);
#endif
    // 左右反転
    if (reverse1) {
        offset1 = CGPointMake(offset1.x + naturalSize1.width * scale1, offset1.y);
    }
    if (reverse2) {
        offset2 = CGPointMake(offset2.x + naturalSize2.width * scale2, offset2.y);
    }
    
    // 縦動画
    if (isHeightLong1) {
        if (self.IsUpdown) {
        offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / naturalSize1.height) * 0.5f * player1.zoomScale, offset1.y);
        }else{
        //offset1 = CGPointMake(offset1.x + 140 * player1.zoomScale, offset1.y);
        offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / naturalSize1.height) * 0.5f * player1.zoomScale, offset1.y);
        }
    } else {
        if (self.IsUpdown) {
            offset1 = CGPointMake(200, 200);
        }else{
            offset1 = CGPointMake(offset1.x , offset1.y + (480 - 640 * naturalSize1.height / naturalSize1.width) * 0.5f * player1.zoomScale);
        }
    }
    if (isHeightLong2) {
        //offset2 = CGPointMake(offset2.x + 140 * player2.zoomScale, offset2.y);
        offset2 = CGPointMake(offset2.x + (640 - 480 * naturalSize2.width / naturalSize2.height) * 0.5f * player2.zoomScale, offset2.y);
    } else {
        offset2 = CGPointMake(offset2.x , offset2.y + (480 - 640 * naturalSize2.height / naturalSize2.width) * 0.5f * player2.zoomScale);
    }
    CGFloat opacity = sldRatio.value;
    //scale1 = 0.5;
    //scale2 = 2.0;
    NSLog(@"scale: %f offset: Point(%f,%f)",scale1, offset1.x, offset1.y);
#ifdef DEBUG
    UIEdgeInsets ins = player1.contentInset;
    CGPoint point = player1.contentOffset;
    CGSize siz = player1.contentSize;
    NSLog(@"scale: n1: %f p1: %f s1:%f n2: %f p2: %f s2: %f",naturalSize1.height, player1.zoomScale, scale1, naturalSize2.height, player2.zoomScale, scale2);
    NSLog(@"insets: %f %f %f %f",ins.top, ins.left, ins.bottom, ins.right);
    NSLog(@"point: %f %f", point.x, point.y);
    NSLog(@"size: %f %f", siz.width - point.x, siz.height - point.y);
    NSLog(@"offset1: %f %f        %f  %f  %f %f",offset1.x, offset1.y,  size1.width, size1.height, player1.frame.size.width, player1.frame.size.height);
#endif
    
    // ミックスした結果はここに
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    
    //*******************
    // 作成動画のどの点から、素材動画のs秒目からe秒目の部分を挿入するか
    //*******************
    //Here we are creating the first AVMutableCompositionTrack.See how we are adding a new track to our AVMutableComposition.
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
    [firstTrack insertTimeRange:range1 ofTrack:assetTrack1 atTime:kCMTimeZero error:nil];
    //>>>>> 音声ファイルも別で付け足す 参考３
    BOOL hasAudio1 = [[asset1 tracksWithMediaType:AVMediaTypeAudio] count] > 0;
    if (hasAudio1) {
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack insertTimeRange:range1 ofTrack:[[asset1 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }
    //<<<<<
    //Now we repeat the same process for the 2nd track as we did above for the first track.Note that the new track also starts at kCMTimeZero meaning both tracks will play simultaneously.
    AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [secondTrack insertTimeRange:range2 ofTrack:assetTrack2 atTime:kCMTimeZero error:nil];
    //>>>>> 音声ファイルも別で付け足す 参考３
    BOOL hasAudio2 = [[asset2 tracksWithMediaType:AVMediaTypeAudio] count] > 0;
    if (hasAudio2) {
        AVMutableCompositionTrack *audioTrack2 = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack2 insertTimeRange:range2 ofTrack:[[asset2 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }
    //<<<<<
    //See how we are creating AVMutableVideoCompositionInstruction object.This object will contain the array of our AVMutableVideoCompositionLayerInstruction objects.You set the duration of the layer.You should add the lenght equal to the lingth of the longer asset in terms of duration.
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    [MainInstruction retain];
    MainInstruction.timeRange = allRange;
//    if (assetTrack1.preferredTransform.b * assetTrack1.preferredTransform.c < 0) {
//        // offset1 = CGPointMake(offset1.x + (player1.frame.size.width - player1.frame.size.height * naturalSize1.width / naturalSize1.height) * 0.5f * naturalSize1.height / player1.frame.size.height, offset1.y);
//        offset1 = CGPointMake(offset1.x + 140, offset1.y);
    //    }
    // 縦動画
//    if (assetTrack1.preferredTransform.b * assetTrack1.preferredTransform.c < 0) {
//        //offset1 = CGPointMake(offset1.x + (640 - naturalSize1.width * scale1) * 0.5f, offset1.y);
//        offset1 = CGPointMake(offset1.x + (640 * player1.zoomScale - naturalSize1.width * scale1) * 0.5f, offset1.y);
//    }
//    if (assetTrack2.preferredTransform.b * assetTrack2.preferredTransform.c < 0) {
//        offset2 = CGPointMake(offset2.x + (640 * player2.zoomScale - naturalSize2.width * scale2) * 0.5f, offset2.y);
//    }
    CGAffineTransform pref1 = assetTrack1.preferredTransform;
    CGAffineTransform pref2 = assetTrack2.preferredTransform;
    CGAffineTransform Scale = CGAffineTransformMakeScale( reverse1 ? -1 * scale1 : scale1,scale1);
    CGAffineTransform SecondScale = CGAffineTransformMakeScale( reverse2 ? -1 * scale2 : scale2,scale2);
    CGAffineTransform Move = CGAffineTransformMakeTranslation(offset1.x,offset1.y);
    CGAffineTransform SecondMove = CGAffineTransformMakeTranslation(offset2.x,offset2.y);
    CGAffineTransform affine1 = CGAffineTransformConcat(CGAffineTransformConcat(pref1, Scale), Move);
    CGAffineTransform affine2 = CGAffineTransformConcat(CGAffineTransformConcat(pref2, SecondScale),SecondMove);
    
    //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects.Each for our 2 AVMutableCompositionTrack.here we are creating AVMutableVideoCompositionLayerInstruction for out first track.see how we make use of Affinetransform to move and scale our First Track.so it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
//    [FirstlayerInstruction setTransform:affine1 atTime:kCMTimeZero]; //01/29
    if (IsOverlap) {
        [FirstlayerInstruction setTransform:affine1 atTime:kCMTimeZero];
        [FirstlayerInstruction setOpacity:(1 - opacity) atTime:kCMTimeZero]; // add by sasage
    } else {
//        CGRect finRect = CGRectMake(0, 0, 320, 480);
//        [FirstlayerInstruction setCropRectangle:CGRectApplyAffineTransform(finRect, CGAffineTransformInvert(affine1))
//                                         atTime:kCMTimeZero];
    }
    //Here we are creating AVMutableVideoCompositionLayerInstruction for out second track.see how we make use of Affinetransform to move and scale our second Track.
    AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
    
    
    
//    [SecondlayerInstruction setTransform:affine2 atTime:kCMTimeZero];// 01/29
    if (IsOverlap) {
        [SecondlayerInstruction setTransform:affine2 atTime:kCMTimeZero];
        [SecondlayerInstruction setOpacity:opacity atTime:kCMTimeZero]; // add by sasage
    } else {
        if (self.IsUpdown) {
            [SecondlayerInstruction setTransform:CGAffineTransformMakeTranslation(0,240) atTime:kCMTimeZero];
        }else{
            [SecondlayerInstruction setTransform:CGAffineTransformMakeTranslation(320,0) atTime:kCMTimeZero];
        }
//        CGAffineTransform af = assetTrack2.preferredTransform;
//        NSLog(@"af: a:%f b:%f c:%f d:%f tx:%f ty:%f",af.a, af.b,af.c,af.d,af.tx,af.ty);
//        CGRect finRect = CGRectMake(320, 0, 320, 480);
//        [SecondlayerInstruction setCropRectangle:CGRectApplyAffineTransform(finRect, CGAffineTransformInvert(affine2))
//                                         atTime:kCMTimeZero];
    }
#ifdef DEBUG
    NSLog(@"sss %f  %f   %f",offset2.x, offset2.y, offset2.x / scale2);
#endif
    // アニメーション
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, 640, 480);// videoSize
    videoLayer.frame = CGRectMake(0, 0, 640, 480);// videoSize
    [parentLayer addSublayer:videoLayer];
#ifdef DEBUG
    NSLog(@"PLAYER SIZE = (%f,%f)",player1.frame.size.width,player1.frame.size.height);
#endif
    for (AnimationElement *anime in animations) {
        CALayer *logoLayer = [CALayer layer];
        UIImage *image = [self resizedImage:anime.image size:CGSizeMake(640, 480)]; //anime.image;
        
        logoLayer.contents = (id)image.CGImage;
        // logoLayer.contents = (id)[UIImage imageNamed:@"calulu.jpg"].CGImage;
        //logoLayer.frame = CGRectMake(0, 0, anime.frame.size.width, anime.frame.size.height);
        logoLayer.frame = CGRectMake(0, 0, 640, 480);
#ifdef DEBUG
        NSLog(@"LOGO LAYER FRAME = (%f, %f, %f, %f)",logoLayer.frame.origin.x,logoLayer.frame.origin.y,
              logoLayer.frame.size.width,logoLayer.frame.size.height);
#endif
        //logoLayer.frame = anime.frame;//CGRectMake(0, 0, image.size.width, image.size.height);
        // NSLog(@"%f %f",image.size.width, image.size.height);
        logoLayer.opacity = 0.0f;
        
        //>>>>>>>> アニメの追加　参考２
        CGFloat duration = anime.end - anime.begin;
        CGFloat transitionTime = 0.1f;
        logoLayer.masksToBounds = YES;
        
        CABasicAnimation *animation;
        if (anime.begin > transitionTime) {
            animation =[CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.duration= transitionTime;
            animation.removedOnCompletion = NO; // by Pechkin
            // animate from fully visible to invisible
            animation.fromValue=[NSNumber numberWithFloat:0.0];
            animation.toValue=[NSNumber numberWithFloat:1.0];
            animation.beginTime = anime.begin - transitionTime - start1;
            [logoLayer addAnimation:animation forKey:@"animateOpacity1"];
            
            animation
            =[CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.duration= duration;
            animation.removedOnCompletion = NO; // by Pechkin
            // animate from fully visible to invisible
            animation.fromValue=[NSNumber numberWithFloat:1.0];
            animation.toValue=[NSNumber numberWithFloat:1.0];
            animation.beginTime = anime.begin - start1;
            NSLog(@"begin: %f",anime.begin);
            [logoLayer addAnimation:animation forKey:@"animateOpacity2"];
        } else {
            logoLayer.opacity = 1.0f;
        }
        
        animation
        =[CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.duration = transitionTime;
        animation.removedOnCompletion = NO; // by Pechkin
        // animate from fully visible to invisible
        animation.fromValue=[NSNumber numberWithFloat:1.0];
        animation.toValue=[NSNumber numberWithFloat:0.0];
        animation.beginTime = anime.begin + duration - start1;
        [logoLayer addAnimation:animation forKey:@"animateOpacity3"];
        
        if (logoLayer.opacity >= 1.0f) {
            animation
            =[CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.duration = CMTimeGetSeconds(mixComposition.duration) - (anime.end + transitionTime - start1);
            animation.removedOnCompletion = NO; // by Pechkin
            // animate from fully visible to invisible
            animation.fromValue=[NSNumber numberWithFloat:0.0];
            animation.toValue=[NSNumber numberWithFloat:0.0];
            animation.beginTime = anime.end + transitionTime - start1;
            [logoLayer addAnimation:animation forKey:@"animateOpacity4"];
        }
        [parentLayer addSublayer:logoLayer];
    }
    
    // end // アニメーション
    //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];
    
    //Now we create AVMutableVideoComposition object.We can add mutiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    [MainCompositionInst retain];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.animationTool =  [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = CGSizeMake(640, 480);
    
    // ここから mixのstage3以降とおんなじ

    //****** 3. AVAssetExportSessionを使用して1と2のコンポジションを合成。 *****//
#ifdef DEBUG
    NSLog(@"stage 3");
#endif
    // 1のコンポジションをベースにAVAssetExportを生成
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset: mixComposition presetName:AVAssetExportPresetHighestQuality];
    // 2の合成用コンポジションを設定
    assetExport.videoComposition = MainCompositionInst;
    
    
    // エクスポートファイルの設定
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mp4"];
    NSURL *exportURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error = nil;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
        {
            NSLog(@"%@",error.localizedDescription);
        }
    }
    [outputPath release];
    assetExport.outputFileType = AVFileTypeMPEG4;
    assetExport.outputURL = exportURL;
    assetExport.shouldOptimizeForNetworkUse = YES;
#ifdef DEBUG
    NSLog(@"before export");
#endif
    //エクスポート実行
    [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
        if (assetExport.status == AVAssetExportSessionStatusCompleted) {
#ifdef DEBUG
            NSLog(@"合成/保存完了");
#endif
            [self performSelectorOnMainThread:@selector(saveFrameEditVideo) withObject:nil waitUntilDone:NO];
        } else {
            NSLog(@"合成/保存失敗 Error: %@", [assetExport.error description]);
            [self performSelectorOnMainThread:@selector(dismissProgress) withObject:nil waitUntilDone:NO];
        }
        [asset1 release];
        [asset2 release];
        isSaving = NO; // 動画保存画面ではどちらにせよ押せない。
    }];
    
    [mixComposition release];
    [MainCompositionInst release];
    [exportURL release];
}
- (void)setNoPreferdVideo{
    __block int count = 0;
    asset1 = movie1.videoAsset;
    AVAssetTrack *assetTrack1 = [[asset1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    asset2 = movie2.videoAsset;
    AVAssetTrack *assetTrack2 = [[asset2 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    if (IsOverlap) {
        [self performSelectorOnMainThread:@selector(videoSave) withObject:nil waitUntilDone:NO];
        return;
    }
    
    {
        CGSize naturalSize1 = [VideoCompViewController naturalSizeOfAVAsset:asset2];
        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:assetTrack2 atTime:kCMTimeZero error:nil];
        AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        [MainInstruction retain];
        MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset2.duration);
        
        //>>>>> 音声ファイルも別で付け足す 参考３
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        BOOL hasAudio = [[asset2 tracksWithMediaType:AVMediaTypeAudio] count] > 0;
        if (hasAudio) {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(asset2.duration, kCMTimeZero)) ofTrack:[[asset2 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            // 音量調節
            AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
            [audioInputParams setVolume:player2.volume atTime:kCMTimeZero];
            [audioInputParams setTrackID:[[[asset2 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]  trackID]];
            audioMix.inputParameters = [NSArray arrayWithObject:audioInputParams];
        }
        //<<<<<<<<<<<
        BOOL isHeightLong = naturalSize1.width <= naturalSize1.height;
//        BOOL isHeightLong = assetTrack2.preferredTransform.b * assetTrack2.preferredTransform.c < 0; // 縦動画
        CGFloat scale1 = 640 / naturalSize1.width * player2.zoomScale;
        if (isHeightLong) {
            if (self.IsUpdown){
               scale1 = 240 / naturalSize1.height * player2.zoomScale;
            }else{
                scale1 = 480 / naturalSize1.height * player2.zoomScale;
            }
        }else{
            if (self.IsUpdown){
                scale1 = 320 / naturalSize1.width * player2.zoomScale;
            }
        }
        CGPoint offset1 = player2.contentOffset;
        BOOL reverse1 = player2.isReversed;
        if (self.IsUpdown) {
            offset1 = CGPointMake((player2.frame.size.width * player2.zoomScale - offset1.x) * 480 / (player2.frame.size.height*2),-1 * offset1.y * 480 / (player2.frame.size.height*2));
        }else {
            offset1 = CGPointMake(-1 * offset1.x * 480 / player1.frame.size.height,
                                  -1 * offset1.y * 480 / player1.frame.size.height);
        }
        if (reverse1) {
            offset1 = CGPointMake(offset1.x + naturalSize1.width * scale1, offset1.y);
        }
#ifdef DEBUG
        NSLog(@"scale: %f offset: Point(%f,%f)",scale1, offset1.x, offset1.y);
#endif
        // 縦動画
        if (isHeightLong) {
//            offset1 = CGPointMake(offset1.x + 140 * player2.zoomScale, offset1.y);
            if (self.IsUpdown) {
                offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / (naturalSize1.height*2)) * 0.5f * player2.zoomScale, offset1.y);
                //offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / naturalSize1.height) * 0.5f * player1.zoomScale, offset1.y);
            }else {
                offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / naturalSize1.height) * 0.5f * player2.zoomScale, offset1.y);
            }
        } else {
            if (self.IsUpdown) {
                offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / (naturalSize1.height*2)) * 0.5f * player2.zoomScale , offset1.y + (480 - 640 * naturalSize1.height / naturalSize1.width) * 0.5f * player2.zoomScale);
            }else{
                offset1 = CGPointMake(offset1.x , offset1.y + (480 - 640 * naturalSize1.height / naturalSize1.width) * 0.5f * player2.zoomScale);
            }
        }
        //float shortMember = MIN(naturalSize1.height, naturalSize1.width);
        //float scaleRate = 0.5;
        //CGAffineTransform shrinkTransform = CGAffineTransformMakeScale(scaleRate, -scaleRate);
        CGAffineTransform pref1 = assetTrack2.preferredTransform;
        CGAffineTransform Scale = CGAffineTransformMakeScale( reverse1 ? -1 * scale1 : scale1,scale1);
        CGAffineTransform Move = CGAffineTransformMakeTranslation(offset1.x ,offset1.y);
        //CGAffineTransform affine1 = CGAffineTransformConcat(shrinkTransform, Move);
        CGAffineTransform affine1 = CGAffineTransformConcat(CGAffineTransformConcat(pref1, Scale), Move);
        
        
        AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        [FirstlayerInstruction setTransform:affine1 atTime:kCMTimeZero];
        
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];
        
        AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
        [MainCompositionInst retain];
        MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        MainCompositionInst.frameDuration = CMTimeMake(1, 30);
        //MainCompositionInst.renderSize = CGSizeMake(640, 480);
        if (self.IsUpdown) {
            MainCompositionInst.renderSize = CGSizeMake(640, 240);
        }else {
            MainCompositionInst.renderSize = CGSizeMake(320, 480);
        }
        
        //****** 3. AVAssetExportSessionを使用して1と2のコンポジションを合成。 *****//
#ifdef DEBUG
        NSLog(@"stage 3");
#endif
        // 1のコンポジションをベースにAVAssetExportを生成
        AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset: mixComposition presetName:AVAssetExportPresetHighestQuality];
        // 2の合成用コンポジションを設定
        assetExport.videoComposition = MainCompositionInst;
        assetExport.audioMix = audioMix;
        // エクスポートファイルの設定
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output2.mp4"];
        NSURL *exportURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath])
        {
            NSError *error = nil;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            {
                NSLog(@"%@",error.localizedDescription);
            }
        }
        [outputPath release];
        assetExport.outputFileType = AVFileTypeMPEG4;
        assetExport.outputURL = exportURL;
        assetExport.shouldOptimizeForNetworkUse = YES;
#ifdef DEBUG
        NSLog(@"before export");
#endif
        //エクスポート実行
        [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
            if (assetExport.status == AVAssetExportSessionStatusCompleted) {
#ifdef DEBUG
                NSLog(@"合成/保存完了");
#endif
                //          [self performSelectorOnMainThread:@selector(saveFrameEditVideo) withObject:nil waitUntilDone:NO];
                asset2 = nil;
                asset2 = [AVURLAsset assetWithURL:exportURL];
                [asset2 retain];
                count++;
                if (count >= 2) {
                    [self performSelectorOnMainThread:@selector(videoSave) withObject:nil waitUntilDone:NO];
                }
            } else {
                NSLog(@"合成/保存失敗 Error: %@", [assetExport.error description]);
                [self performSelectorOnMainThread:@selector(dismissProgress) withObject:nil waitUntilDone:NO];
            }
            //[asset release];
            isSaving = NO; // 動画保存画面ではどちらにせよ押せない。
        }];
    }
//    if (assetTrack1.preferredTransform.a == 0 && player1) {
    {
        CGSize naturalSize1 = [VideoCompViewController naturalSizeOfAVAsset:asset1];
        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset1.duration) ofTrack:assetTrack1 atTime:kCMTimeZero error:nil];
        AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        [MainInstruction retain];
        MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset1.duration);
        //>>>>> 音声ファイルも別で付け足す 参考３
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        BOOL hasAudio = [[asset1 tracksWithMediaType:AVMediaTypeAudio] count] > 0;
        if (hasAudio) {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(asset1.duration, kCMTimeZero)) ofTrack:[[asset1 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            // 音量調節
            AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
            //[audioInputParams setVolume:1.0f atTime:kCMTimeZero];
            [audioInputParams setVolume:player1.volume atTime:kCMTimeZero];
            [audioInputParams setTrackID:[[[asset1 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]  trackID]];
            audioMix.inputParameters = [NSArray arrayWithObject:audioInputParams];
        }
        //<<<<<<<<<<<
        
        BOOL isHeightLong = naturalSize1.width <= naturalSize1.height;
//        BOOL isHeightLong = assetTrack1.preferredTransform.b * assetTrack1.preferredTransform.c < 0; // 縦動画
        CGFloat scale1 = 640 / naturalSize1.width * player1.zoomScale;
        if (isHeightLong) {
            if (self.IsUpdown){
                scale1 = 240 / naturalSize1.height * player1.zoomScale;
            }else{
                scale1 = 480 / naturalSize1.height * player1.zoomScale;
            }
        }else{
            if (self.IsUpdown){
                scale1 = 320 / naturalSize1.width * player1.zoomScale;
            }
        }
        CGPoint offset1 = player1.contentOffset;
        BOOL reverse1 = player1.isReversed;
        ;
        
        if (self.IsUpdown) {
            offset1 = CGPointMake((player1.frame.size.width * player1.zoomScale - offset1.x) * 480 / (player1.frame.size.height*2),-1 * offset1.y * 480 / (player1.frame.size.height*2));
        }else{
            offset1 = CGPointMake(-1 * offset1.x * 480 / player1.frame.size.height,
                                  -1 * offset1.y * 480 / player1.frame.size.height);
        }
        if (reverse1) {
            offset1 = CGPointMake(offset1.x + naturalSize1.width * scale1, offset1.y);
        }
        
        // 縦動画
        if (isHeightLong) {
            if (self.IsUpdown) {
                offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / (naturalSize1.height*2)) * 0.5f * player1.zoomScale, offset1.y);
            }else {
                //offset1 = CGPointMake(offset1.x + 140 * player1.zoomScale, offset1.y);
                offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / naturalSize1.height) * 0.5f * player1.zoomScale, offset1.y);
            }
        } else {
            if (self.IsUpdown) {
                offset1 = CGPointMake(offset1.x + (640 - 480 * naturalSize1.width / (naturalSize1.height*2)) * 0.5f * player1.zoomScale , offset1.y + (480 - 640 * naturalSize1.height / naturalSize1.width) * 0.5f * player1.zoomScale);
            }else{
                offset1 = CGPointMake(offset1.x , offset1.y + (480 - 640 * naturalSize1.height / naturalSize1.width) * 0.5f * player1.zoomScale);
            }
        }
        CGAffineTransform pref1 = assetTrack1.preferredTransform;
        CGAffineTransform Scale = CGAffineTransformMakeScale( reverse1 ? -1 * scale1 : scale1,scale1);
        CGAffineTransform Move = CGAffineTransformMakeTranslation(offset1.x,offset1.y);
        CGAffineTransform affine1 = CGAffineTransformConcat(CGAffineTransformConcat(pref1, Scale), Move);
        
        
        
        
        AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        [FirstlayerInstruction setTransform:affine1 atTime:kCMTimeZero];
        
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];
        
        AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
        [MainCompositionInst retain];
        MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        MainCompositionInst.frameDuration = CMTimeMake(1, 30);
        //MainCompositionInst.renderSize = CGSizeMake(640, 480);
        if (self.IsUpdown) {
            MainCompositionInst.renderSize = CGSizeMake(640, 240);
        }else{
            MainCompositionInst.renderSize = CGSizeMake(320, 480);
        }
        
        //****** 3. AVAssetExportSessionを使用して1と2のコンポジションを合成。 *****//
#ifdef DEBUG
        NSLog(@"stage 3");
#endif
        // 1のコンポジションをベースにAVAssetExportを生成
        AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset: mixComposition presetName:AVAssetExportPresetHighestQuality];
        // 2の合成用コンポジションを設定
        assetExport.videoComposition = MainCompositionInst;
        assetExport.audioMix = audioMix;
        // エクスポートファイルの設定
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output1.mp4"];
        NSURL *exportURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath])
        {
            NSError *error = nil;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            {
                NSLog(@"%@",error.localizedDescription);
            }
        }
        [outputPath release];
        assetExport.outputFileType = AVFileTypeMPEG4;
        assetExport.outputURL = exportURL;
        assetExport.shouldOptimizeForNetworkUse = YES;
#ifdef DEBUG
        NSLog(@"before export");
#endif
        //エクスポート実行
        [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
            if (assetExport.status == AVAssetExportSessionStatusCompleted) {
#ifdef DEBUG
                NSLog(@"合成/保存完了");
#endif
                //          [self performSelectorOnMainThread:@selector(saveFrameEditVideo) withObject:nil waitUntilDone:NO];
                asset1 = nil;
                asset1 = [AVURLAsset assetWithURL:exportURL];
                [asset1 retain];
                count++;
                if (count >= 2) {
                    [self performSelectorOnMainThread:@selector(videoSave) withObject:nil waitUntilDone:NO];
                }
            } else {
                NSLog(@"合成/保存失敗 Error: %@", [assetExport.error description]);
                [self performSelectorOnMainThread:@selector(dismissProgress) withObject:nil waitUntilDone:NO];
            }
            //[asset release];
            isSaving = NO; // 動画保存画面ではどちらにせよ押せない。
        }];
    }
}
- (void)setNoPreferdVideo__{
    __block int count = 0;
    asset1 = movie1.videoAsset;
    AVAssetTrack *assetTrack1 = [[asset1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    asset2 = movie2.videoAsset;
    AVAssetTrack *assetTrack2 = [[asset2 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    if (IsOverlap) {
        [self performSelectorOnMainThread:@selector(videoSave) withObject:nil waitUntilDone:NO];
        return;
    }
    if (assetTrack1.preferredTransform.a == 0 && player1) {
        CGSize naturalSize1 = [VideoCompViewController naturalSizeOfAVAsset:asset1];
        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset1.duration) ofTrack:assetTrack1 atTime:kCMTimeZero error:nil];
        AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        [MainInstruction retain];
        MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset1.duration);
        
        CGFloat scale1 = 480 / naturalSize1.height;
        CGPoint offset = CGPointZero;
        if (assetTrack1.preferredTransform.b * assetTrack1.preferredTransform.c < 0) {
            offset = CGPointMake((640 - naturalSize1.width * scale1) * 0.5f, 0);
        }
#ifdef DEBUG
        NSLog(@"scale1: %f", scale1);
#endif
        CGAffineTransform pref1 = assetTrack1.preferredTransform;
        CGAffineTransform Scale = CGAffineTransformMakeScale(scale1,scale1);
        CGAffineTransform Move = CGAffineTransformMakeTranslation(offset.x,offset.y);
        CGAffineTransform affine1 = CGAffineTransformConcat(CGAffineTransformConcat(pref1, Scale), Move);
        AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        [FirstlayerInstruction setTransform:affine1 atTime:kCMTimeZero];
        
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];
        
        AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
        [MainCompositionInst retain];
        MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        MainCompositionInst.frameDuration = CMTimeMake(1, 30);
        MainCompositionInst.renderSize = CGSizeMake(640, 480);
        
        //****** 3. AVAssetExportSessionを使用して1と2のコンポジションを合成。 *****//
#ifdef DEBUG
        NSLog(@"stage 3");
#endif
        // 1のコンポジションをベースにAVAssetExportを生成
        AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset: mixComposition presetName:AVAssetExportPresetHighestQuality];
        // 2の合成用コンポジションを設定
        assetExport.videoComposition = MainCompositionInst;
        
        // エクスポートファイルの設定
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output1.mp4"];
        NSURL *exportURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath])
        {
            NSError *error = nil;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            {
                NSLog(@"%@",error.localizedDescription);
            }
        }
        [outputPath release];
        assetExport.outputFileType = AVFileTypeMPEG4;
        assetExport.outputURL = exportURL;
        assetExport.shouldOptimizeForNetworkUse = YES;
#ifdef DEBUG
        NSLog(@"before export");
#endif
        //エクスポート実行
        [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
            if (assetExport.status == AVAssetExportSessionStatusCompleted) {
#ifdef DEBUG
                NSLog(@"合成/保存完了");
#endif
                //          [self performSelectorOnMainThread:@selector(saveFrameEditVideo) withObject:nil waitUntilDone:NO];
                asset1 = nil;
                asset1 = [AVURLAsset assetWithURL:exportURL];
                [asset1 retain];
                count++;
                if (count >= 2) {
                    [self performSelectorOnMainThread:@selector(videoSave) withObject:nil waitUntilDone:NO];
                }
            } else {
                NSLog(@"合成/保存失敗 Error: %@", [assetExport.error description]);
                [self performSelectorOnMainThread:@selector(dismissProgress) withObject:nil waitUntilDone:NO];
            }
            //[asset release];
            isSaving = NO; // 動画保存画面ではどちらにせよ押せない。
        }];
    } else {
        count++;
        if (count >= 2) {
            [self performSelectorOnMainThread:@selector(videoSave) withObject:nil waitUntilDone:NO];
        }
    }
    
    
    if (assetTrack2.preferredTransform.a == 0) {
        CGSize naturalSize = [VideoCompViewController naturalSizeOfAVAsset:asset2];
        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:assetTrack2 atTime:kCMTimeZero error:nil];
        AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        [MainInstruction retain];
        MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset2.duration);
        
        CGFloat scale = 480 / naturalSize.height;
        CGPoint offset = CGPointZero;
        if (assetTrack2.preferredTransform.b * assetTrack2.preferredTransform.c < 0) {
            offset = CGPointMake((640 - naturalSize.width * scale) * 0.5f, 0);
        }
        
        CGAffineTransform pref2 = assetTrack2.preferredTransform;
        CGAffineTransform Scale = CGAffineTransformMakeScale(scale,scale);
        CGAffineTransform Move = CGAffineTransformMakeTranslation(offset.x,offset.y);
        CGAffineTransform affine = CGAffineTransformConcat(CGAffineTransformConcat(pref2, Scale), Move);
        AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        [FirstlayerInstruction setTransform:affine atTime:kCMTimeZero];
        
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];
        
        AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
        [MainCompositionInst retain];
        MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        MainCompositionInst.frameDuration = CMTimeMake(1, 30);
        MainCompositionInst.renderSize = CGSizeMake(640, 480);
        
        //****** 3. AVAssetExportSessionを使用して1と2のコンポジションを合成。 *****//
#ifdef DEBUG
        NSLog(@"stage 3");
#endif
        // 1のコンポジションをベースにAVAssetExportを生成
        AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset: mixComposition presetName:AVAssetExportPresetHighestQuality];
        // 2の合成用コンポジションを設定
        assetExport.videoComposition = MainCompositionInst;
        
        // エクスポートファイルの設定
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output2.mp4"];
        NSURL *exportURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath])
        {
            NSError *error = nil;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            {
                NSLog(@"%@",error.localizedDescription);
            }
        }
        [outputPath release];
        assetExport.outputFileType = AVFileTypeMPEG4;
        assetExport.outputURL = exportURL;
        assetExport.shouldOptimizeForNetworkUse = YES;
#ifdef DEBUG
        NSLog(@"before export");
#endif
        //エクスポート実行
        [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
            if (assetExport.status == AVAssetExportSessionStatusCompleted) {
#ifdef DEBUG
                NSLog(@"合成/保存完了");
#endif
                //          [self performSelectorOnMainThread:@selector(saveFrameEditVideo) withObject:nil waitUntilDone:NO];
                asset2 = nil;
                asset2 = [AVURLAsset assetWithURL:exportURL];
                [asset2 retain];
                count++;
                if (count >= 2) {
                    [self performSelectorOnMainThread:@selector(videoSave) withObject:nil waitUntilDone:NO];
                }
            } else {
                NSLog(@"合成/保存失敗 Error: %@", [assetExport.error description]);
                [self performSelectorOnMainThread:@selector(dismissProgress) withObject:nil waitUntilDone:NO];
            }
            //[asset release];
            isSaving = NO; // 動画保存画面ではどちらにせよ押せない。
        }];
    } else {
        count++;
        if (count >= 2) {
            [self performSelectorOnMainThread:@selector(videoSave) withObject:nil waitUntilDone:NO];
        }
    }
}

+ (CGSize)naturalSizeOfAVAsset:(AVAsset *)asset{
    CGSize naturalSize = [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (tracks.count <= 0) {
        return CGSizeZero;
    }
    if (((AVAssetTrack *)tracks[0]).preferredTransform.a == 0) {
        naturalSize = CGSizeMake(naturalSize.height, naturalSize.width);
    }
    return naturalSize;
}
- (IBAction)OnAnimeAdd {
    AnimationElement *anime = [[AnimationElement alloc] initWithFrame:CGRectMake(vwPaintManager.frame.origin.x,
                                                                                 vwPaintManager.frame.origin.y,
                                                                                 vwPaintManager.frame.size.width,
                                                                                 vwPaintManager.frame.size.height)];
        anime.image = [self canvasImage:vwPaintManager];
        anime.begin = rangeSlider.selectedMinimumValue;
        anime.end = rangeSlider.selectedMaximumValue;
        anime.hidden = vwPaintManager.hidden;
        [self.view insertSubview:anime belowSubview:vwPaintManager];
        [animations addObject:anime];
        [vwPaintManager allClearCanvas];
        [vwPaintManager initDrawObject];
        vwPaintManager.IsDirty = NO;
        vwPaintManager.hidden = NO;
}
- (UIImage *)canvasImage:(PicturePaintManagerView *)paintManager {
	UIImage* imgCanvas = [paintManager getCanvasImage];
    CGSize resized_size = CGSizeMake(640, 480);
    UIGraphicsBeginImageContext(resized_size);
    [imgCanvas drawInRect:CGRectMake(0, 0, resized_size.width, resized_size.height)];
    imgCanvas = UIGraphicsGetImageFromCurrentImageContext();
    
	// 描画画像を上下反転
	CGRect rect = CGRectMake(0.0, 0.0, imgCanvas.size.width, imgCanvas.size.height);
	UIGraphicsBeginImageContext(rect.size);
	CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, rect.size.height);
	CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
	[imgCanvas drawInRect:rect];
	UIImage* imgCanvasReversed = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    return imgCanvasReversed;
}
- (void)saveFrameEditVideo {
    [SVProgressHUD dismiss];
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mp4"];//@@@@
    NSURL *exportURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    [outputPath release];
    VideoSaveViewController *saveView = [[VideoSaveViewController alloc]
                                         initWithNibName:@"VideoSaveViewController" bundle:nil];
    saveView.saveDelegate = self; // ２つの動画を同時に保存することはないのでコールバックは必要ない
    [saveView show];
    MovieResource *movieResource = [[MovieResource alloc] initNewMovieWithUserId:_userID];
    // 履歴IDをデータベースよりユーザIDと当日で取得する:当日の履歴がない場合は作成する
	HISTID_INT histID;
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	if ( (histID = [usrDbMng getHistIDWithDateUserID:_userID
                                            workDate:[NSDate date]
                                      isMakeNoRecord:YES] ) < 0)
	{
		NSLog(@"getHistIDWithDateUserID error on PicturePaintViewController!");
        return;
	}
    [usrDbMng release];
    [saveView setVideoUrl:exportURL movie:movieResource histId:histID];
}

- (void)finishVideoSave:(BOOL)isSaved {
    if (isSaved) {
        shoudSave = NO;
    }
}
@end
