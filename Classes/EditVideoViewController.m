//
//  SelectVideoViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <QuartzCore/CALayer.h>

#import "Common.h"

#import "iPadCameraAppDelegate.h"
#import "EditVideoViewController.h"

#import "HistDetailViewController.h"
#import "HistListViewController.h"

#import "ThumbnailViewController.h"

#import "PicturePaintCommon.h"
#import "PicturePaintViewController.h"
#import "camaraViewController.h"

#import "UtilHardCopySupport.h"

#import "userDbManager.h"

#import <Social/Social.h>   // facebook投稿のサポート
//#import <MailCore.h>  // Mail送信のサポート

#import "AccountManager.h"
#import "model/OKDImageFileManager.h"
#import "SVProgressHUD.h"
#import "AnimationElement.h"
#import "UIAlertView+Blocks.h"
#import "MicUtil.h"

ThumbnailViewController *thumbnailVC;
// PicturePaintViewController *picturePaintVC;

@implementation EditVideoViewController

//@synthesize videoPreviewVC1,videoPreviewVC2;
@synthesize isNavigationCall = _isNavigationCall;
@synthesize isFlickEnable = _isFlickEnable;
@synthesize workDate = _workDate;
#pragma mark - 画面の設定
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		// メンバの初期化
		pictImageItems = nil;
		_scrollView = nil;
		_drawView = nil;
		
		_isFlickEnable = NO;
        isPlaySynth = NO;
        playRateArray = [[NSArray arrayWithObjects:
                         [NSNumber numberWithFloat:1.0f],
                         [NSNumber numberWithFloat:0.75f],
                         [NSNumber numberWithFloat:0.5f],
                         [NSNumber numberWithFloat:0.25f],
                         [NSNumber numberWithFloat:0.10f], nil
                          ] retain];
        
        self.videoPreviewVC1 = nil;
        self.videoPreviewVC2 = nil;
        vwPaintManager = [[PicturePaintManagerView alloc] init];
        vwStampE = [[UIView alloc] init];
        currentTimeLabel = [[UILabel alloc] init];
        underCurrentTimeView = [[UIView alloc] init];
        animations1 = [[[NSMutableArray alloc] init] retain];
        
        [self.view addSubview:currentTimeLabel];
        [self.view addSubview:underCurrentTimeView];
        
        int opt = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
        [vwPaintManager addObserver:self forKeyPath:@"IsDirty" options:opt context:NULL];
        remainSavingVideo = NO;
        isSaving = NO;
        shouldSave = NO;
    }
	
	return (self);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    btnAnimeAdd1.enabled = vwPaintManager.IsDirty;
    
    if (vwPaintManager.IsDirty || animations1.count > 0) {
        shouldSave = YES;
    } else {
        shouldSave = NO;
    }
}
// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName isSexMen:(BOOL)isMen
{
	lblUserName.text = [userName mutableCopy];
    lblUserName.textColor = [Common getNameColorWithSex:isMen];
}
// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName nameColor:(UIColor*)color
{
	lblUserName.text = [userName mutableCopy];
    lblUserName.textColor = color;
}

// 施術日の設定：設定により表示される
- (void)setWorkDateWithString:(NSString*)workDate
{
	lblWorkDate.text = [workDate mutableCopy];
	
	lblWorkDate.hidden = NO;
	lblWorkDateTitle.hidden = NO;
	viewWorkDateBack.hidden = NO;
}

// 施術情報の設定（画像合成ビューで必要）
- (void)setWorkItemInfo:(USERID_INT)userID workItemHistID:(HISTID_INT)histID
			   workDate:(NSDate*)date
{
	_userID = userID;
	_histID = histID;
	self.workDate = date;
}
#pragma mark - 動画の設定
#define LS_SINGLE_VIDEO_HEIGHT   620.0f   // DELC SASAGE edit 01/12
#define LS_DOUBLE_VIDEO_WIDTH    456.0f
//動画のリストの設定。MovieResourceのリスト
- (void)setMovie:(MovieResource *)_movie
{
    isDrawMode = YES;
    
    UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
    BOOL isPortrait = (screen.applicationFrame.size.width == 320.0f);
#else
    BOOL isPortrait = (screen.applicationFrame.size.width == 768.0f);
#endif
    movie = _movie;
    [movie retain];
    movieDuration = movie.movieDuration;
    
    currentTimeLabel.text = [NSString stringWithFormat:@"00.0/%04.1f", movieDuration];
    BOOL ok = YES;
#ifdef DEBUG
        NSLog(@"%@",movie.movieURL);
#endif
    
        if (!movie.movieIsExists && !movie.movieIsExistsInCash &&
            ![movie syncDL : ^(NSUInteger totalBytes){
                // 動画のトータルバイト数を10秒で1[MB]換算→1秒で100[KB]=100*1024 = 102400[byte]            
                [SVProgressHUD setStatus:
                    [NSString stringWithFormat: @"しばらくお待ちください\n\n(%ld[KB]受信済み)",
                                                 (long)(totalBytes/1024)]];
        }])
        {
            ok = NO;
            NSLog(@"movie does't exist and cannot download movie");
        }
        if (movie.movieDuration <= 0){
            ok = NO;
        }
        if (ok) {
#ifdef DEBUG
            NSLog(@"    %@",movie.movieURL);
#endif
            if(movie.movieIsExistsInCash) {
                [player1 setVideoUrl:[[NSURL alloc] initFileURLWithPath:movie.movieCashPath]];
            } else {
                [player1 setVideoUrl:movie.movieURL];
            }
            rotator1.player = player1.player;
            player1.syncPlayer = nil;
            // 01/12 CGSizeMake(656, 540);  CGSizeMake(640, 480);
            CGSize naturalSize1 = [MovieResource naturalSizeOfAVPlayer:player1.player];
            if (naturalSize1.width <= 0) {
                naturalSize1 = CGSizeMake(656, 540);
            }
            if (naturalSize1.width <= naturalSize1.height) {
                // １動画縦動画
                //player1.frame = CGRectMake(0, 0, 470, 470 * naturalSize1.height / naturalSize1.width);
                player1.frame = CGRectMake(0, 0, 627 * naturalSize1.width / naturalSize1.height, 627);
                
            } else {
                // １動画横動画
                //player1.frame = CGRectMake(0, 0, 490 * naturalSize1.width / naturalSize1.height, 490);
                player1.frame = CGRectMake(0, 0, 654, 654 * naturalSize1.height / naturalSize1.width);
            }
            [self moviesLayout:isPortrait];
            [vwPaintManager initAfterFrameSet];
            // paint系
            [vwPaintPallet setLockState:YES];
            // 写真描画の管理クラスに通知
            [vwPaintManager changeLockMode:YES];
            // 管理Viewとフリックボタンのhidden設定
            vwPaintManager.userInteractionEnabled = YES;
            vwPaintManager.hidden = NO;
            rangeSlider1.minimumValue = 0;
            rangeSlider1.maximumValue = movie.movieDuration;
            //rangeSlider1.maximumValue = CMTimeGetSeconds(player1.player.currentItem.duration);
        } else {
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:@"動画"
									  message:@"動画が取得できません"
									  delegate:nil
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil
									  ];
			[alertView show];
			[alertView release];
        }
    [SVProgressHUD dismiss];
#ifdef FULLSIZE_PREVIEW
    UITapGestureRecognizer* doubleTapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
    doubleTapGesture1.numberOfTapsRequired = 2;
    [player1 addGestureRecognizer:doubleTapGesture1];
    [doubleTapGesture1 release];
#endif
    if (ok) {
        // 正常に動画が表示された場合にのみ各viewを表示する
        playPallet.hidden = NO;
        slider1.hidden = NO;
        rotator1.hidden = NO;
#ifndef NO_VIDEO_EDIT
        if([AccountManager isMovie]) {
            btnSave.hidden = NO;
            vwPaintPallet.hidden = NO;
        }
#ifndef VIDEO_SIMPLE_EDIT
        vwVideoEditMode.hidden = NO;
#endif
#endif
        //SelectVideoView時代の残滓
            btnAbreast.hidden = YES;
            btnOverlap.hidden = YES;
        [self setAbreastOverlapButonEnable:NO];
    }
    
    
    
    [vwPaintPallet setLockState:NO];
    [vwPaintManager changeLockMode:NO];
    _isModeLock = YES; // 下記メソッドですぐに_isModeLock = NO;に
    [self OnBtnLockMode:nil];
    [self setDrawMode:isDrawMode];
}
- (void)setDrawMode:(BOOL)_isDrawMode {
#ifndef NO_VIDEO_EDIT
    if([AccountManager isMovie]) {
        btnSave.hidden = !_isDrawMode;
        vwPaintPallet.hidden = !_isDrawMode;
    }
#ifndef VIDEO_SIMPLE_EDIT
    vwVideoEditMode.hidden = !_isDrawMode;
#endif
#endif
    btnLockMode.hidden = !_isDrawMode;
}
- (UIImage *)makeCombinedImage:(UIImageView *)imgvw paintManager:(PicturePaintManagerView *)paintManager player:(AVPlayer *)player
{
	UIImage* imgOrigin = imgvw.image;
	UIImage* imgCanvas = [self canvasImage:paintManager player:player];
	CGRect rect = CGRectMake(0.0, 0.0, imgOrigin.size.width, imgOrigin.size.height);
	UIGraphicsBeginImageContext(rect.size);
	[imgOrigin drawInRect:rect];
	[imgCanvas drawInRect:rect];
	UIImage *pictImageMixed = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    return pictImageMixed;
}
- (UIImage *)canvasImage:(PicturePaintManagerView *)paintManager player:(AVPlayer *)player {
	UIImage* imgCanvas = [paintManager getCanvasImage];
    CGSize resized_size = [MovieResource naturalSizeOfAVPlayer:player];
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

// 画像Itemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
- (void) moviesLayout:(BOOL)isPortrait
{
    //CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGSize appSize = [[UIScreen mainScreen] bounds].size;
    btnPlaySync.hidden = YES;
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = 0;
    // iOS7かつNavigationCallでの画面遷移の場合
    if (iOSVersion>=7.0f && self.isNavigationCall)
        uiOffset = 20.0f;
    
    player1.hidden =   NO;
    slider1.hidden =   NO;
    rotator1.hidden =  NO;

    CGFloat width = 728.0f;
    CGFloat height = 546.0f;
    BOOL isWidthLong;
    CGFloat scView = width / height;
    CGFloat scMovie = player1.frame.size.width / player1.frame.size.height;
    isWidthLong = (scView < scMovie)? YES : NO;
    CGFloat scale = (isWidthLong)? width / player1.frame.size.width : height / player1.frame.size.height;

    btnLockMode.frame = CGRectMake(20.0f, 10.0f + uiOffset, 54.0f, 54.0f);
    
    // 動画のレイアウト
    if (isPortrait) {
        // 縦画面
        NSLog(@"app frame width %f", appSize.width);
        viewWorkDateBack.frame = CGRectMake(380 - (1024 - 768), 12 + uiOffset, viewWorkDateBack.frame.size.width, viewWorkDateBack.frame.size.height);
        viewUserNameBack.frame = CGRectMake(717 - (1024 - 768), 12 + uiOffset, viewUserNameBack.frame.size.width, viewUserNameBack.frame.size.height);
        
//        playPallet.frame = CGRectMake(appSize.width - playPallet.frame.size.width - 20,
//                                      (appSize.height - playPallet.frame.size.height) * 0.5f + uiOffset,
//                                      playPallet.frame.size.width, playPallet.frame.size.height);
//        CGRect ppf = playPallet.frame;
//        rotator1.frame = CGRectMake(ppf.origin.x -13 , ppf.origin.y - 120, 100, 100);
//        btnAnimeAdd1.frame = CGRectMake(rotator1.frame.origin.x + (rotator1.frame.size.width - btnAnimeAdd1.frame.size.width) * 0.5f,
//                                        rotator1.frame.origin.y - rotator1.frame.size.height,
//                                        btnAnimeAdd1.frame.size.width, btnAnimeAdd1.frame.size.height);
        // 縦画面１動画
        CGSize naturalSize1 = [MovieResource naturalSizeOfAVPlayer:player1.player];
        if (naturalSize1.width <= 0) {
            naturalSize1 = CGSizeMake(656, 540);
        }
//        BOOL isWidthLong =(naturalSize1.width > naturalSize1.height);

        player1.frame = CGRectMake(0, 0, player1.frame.size.width * scale, player1.frame.size.height * scale);
        player1.center = CGPointMake(768 / 2, (1004 + uiOffset) / 2);
        
        CGFloat palletWidth = MAX(playPallet.frame.size.width, playPallet.frame.size.height);
        CGFloat palletHeight = MIN(playPallet.frame.size.width, playPallet.frame.size.height);
        playPallet.frame = CGRectMake((768 - palletWidth) / 2,
                                      (isPortrait)? player1.frame.origin.y - palletHeight - 20 : 75.0f,
                                      palletWidth,palletHeight);

        btnPlay.center = CGPointMake(playPallet.frame.size.width * 0.5f, playPallet.frame.size.height * 0.5f);
//        btnPlaySync.center = CGPointMake(btnPlay.center.x - btnPlay.frame.size.width - 5, btnPlay.center.y);
        btnPlaySpeed.center = CGPointMake(btnPlay.center.x + btnPlaySpeed.frame.size.width + 5, btnPlay.center.y);
        
        rotator1.frame = CGRectMake(playPallet.frame.origin.x - rotator1.frame.size.width - 40,
                                    playPallet.frame.origin.y + playPallet.frame.size.height * 0.5f - rotator1.frame.size.height * 0.5f,
                                    rotator1.frame.size.width,
                                    rotator1.frame.size.height);
        btnAnimeAdd1.frame = CGRectMake(CGRectGetMaxX(player1.frame) - btnAnimeAdd1.frame.size.width,
                                       CGRectGetMaxY(viewUserNameBack.frame) + 16,
                                       btnAnimeAdd1.frame.size.width,
                                       btnAnimeAdd1.frame.size.height);
        
        [vwPaintPallet setVideoEditPositionWithRotate: CGPointMake(8, 190)
                                            isPortrate: NO];
        CGRect plr = vwPaintPallet.frame;
        vwVideoEditMode.frame = CGRectMake(plr.origin.x,
                                           plr.origin.y + plr.size.height + 20,
                                           plr.size.width, 126);
        btnWindowDraw.frame = CGRectMake((vwVideoEditMode.frame.size.width - btnWindowDraw.frame.size.width) * 0.5f,
                                         3, 57, 57);
        btnFrameDraw.frame = CGRectMake((vwVideoEditMode.frame.size.width - btnWindowDraw.frame.size.width) * 0.5f,
                                        63, 57, 57);
        
        // 縦画面１動画
        [vwPaintPallet setVideoEditPositionWithRotate: CGPointMake(20, 1004 - 80 + uiOffset)
                                           isPortrate: YES];
        CGRect plrr = vwPaintPallet.frame;
        vwVideoEditMode.frame = CGRectMake(CGRectGetMaxX(viewUserNameBack.frame) - 126,
                                           CGRectGetMaxY(viewUserNameBack.frame) + 10,
                                           126, plrr.size.height);

        btnWindowDraw.frame = CGRectMake(3,(vwVideoEditMode.frame.size.height - btnWindowDraw.frame.size.height) * 0.5f,
                                         57, 57);
        btnFrameDraw.frame = CGRectMake(63,(vwVideoEditMode.frame.size.height - btnWindowDraw.frame.size.height) * 0.5f,
                                        57, 57);
        // スタンプパレット表示位置設定
        [vwPaintPallet setStampSelectViewPoint:CGPointMake(20, 1004 - 80 - 75 + uiOffset)];

    } else {
        // 横画面
        viewWorkDateBack.frame = CGRectMake(380, 12 + uiOffset, viewWorkDateBack.frame.size.width, viewWorkDateBack.frame.size.height);
        viewUserNameBack.frame = CGRectMake(717, 12 + uiOffset, viewUserNameBack.frame.size.width, viewUserNameBack.frame.size.height);
        
        CGFloat palletWidth = MIN(playPallet.frame.size.width, playPallet.frame.size.height);
        CGFloat palletHeight = MAX(playPallet.frame.size.width, playPallet.frame.size.height);
        playPallet.frame = CGRectMake(1024 - palletWidth - 40,
                                      (768 - palletHeight) * 0.5f + uiOffset,
                                      palletWidth, palletHeight);
        btnPlay.center = CGPointMake(playPallet.frame.size.width * 0.5f, playPallet.frame.size.height * 0.5f);
//        btnPlaySync.center = CGPointMake(btnPlay.center.x, btnPlay.center.y - btnPlay.frame.size.height - 5);
        btnPlaySpeed.center = CGPointMake(btnPlay.center.x, btnPlay.center.y + btnPlaySpeed.frame.size.height + 5);
        
        //横画面１動画
        [vwPaintPallet setVideoEditPositionWithRotate: CGPointMake(12, 150 + uiOffset)
                                            isPortrate: NO];
        // パレット
        CGRect ppf = playPallet.frame;
        rotator1.frame = CGRectMake(ppf.origin.x -13 , ppf.origin.y - 120, 100, 100);
        btnAnimeAdd1.frame = CGRectMake(rotator1.frame.origin.x + (rotator1.frame.size.width - btnAnimeAdd1.frame.size.width) * 0.5f,
                                        rotator1.frame.origin.y - rotator1.frame.size.height,
                                        btnAnimeAdd1.frame.size.width, btnAnimeAdd1.frame.size.height);
        
        CGRect plr = vwPaintPallet.frame;
        vwVideoEditMode.frame = CGRectMake(plr.origin.x,
                                           plr.origin.y + plr.size.height + 40,
                                           126, plr.size.width);
        btnWindowDraw.frame = CGRectMake(3,(vwVideoEditMode.frame.size.height - btnWindowDraw.frame.size.height) * 0.5f,
                                         57, 57);
        btnFrameDraw.frame = CGRectMake(63,(vwVideoEditMode.frame.size.height - btnWindowDraw.frame.size.height) * 0.5f,
                                        57, 57);

        player1.frame = CGRectMake(0, 0, player1.frame.size.width * scale, player1.frame.size.height * scale);
        player1.center = CGPointMake(148 + (728 / 2), 70 + (546 / 2) + uiOffset);
        
        // スタンプ選択Viewの表示位置調整
        [vwPaintPallet setStampSelectViewPoint:CGPointMake(148, 674 + uiOffset)];
    }
    lblPlaySpeed.center = CGPointMake(btnPlaySpeed.center.x, btnPlaySpeed.center.y + 9);
    btnSave.frame = CGRectMake(20.0f,
                               75.0f + uiOffset,
                               57.0f, 57.0f);

    currentTimeLabel.frame = CGRectMake(player1.frame.origin.x,
                                        CGRectGetMaxY(player1.frame),
                                        60,
                                        30);
    slider1.frame = CGRectMake(CGRectGetMaxX(currentTimeLabel.frame),
                               CGRectGetMaxY(player1.frame),
                               player1.frame.size.width - 60, 30);
    underCurrentTimeView.frame = CGRectMake(player1.frame.origin.x,
                                           CGRectGetMaxY(player1.frame) + 30,
                                           60, 35);
    rangeSlider1.frame =  CGRectMake(CGRectGetMaxX(underCurrentTimeView.frame),
                                     CGRectGetMaxY(player1.frame) + 30,
                                     player1.frame.size.width - 60, 35);
    
    imgvwOverlay1.frame = CGRectMake(0, 0, player1.frame.size.width, player1.frame.size.height);
    
    UIImage *overlayImage = movie.overlayImage;
    if (!overlayImage) {
        NSLog(@"オーバーレイ画像未ダウンロード");
    }
    imgvwOverlay1.image = overlayImage;
    imgvwOverlay1.userInteractionEnabled = YES;
    [player1 addSubview:imgvwOverlay1];
    //[imgvwOverlay1 release];
    vwPaintManager.frame = CGRectMake(0, 0, player1.frame.size.width, player1.frame.size.height);
    vwPaintManager.backgroundColor = [UIColor clearColor];
    //[vwPaintManager1 initAfterFrameSet];
    [imgvwOverlay1 addSubview:vwPaintManager];
#ifndef CALULU_IPHONE
    // 重ね合わせ・透過ボタンの位置調整
#ifdef LOCK_MODE_BUTTON_UNSUPPORT
    [self _buttonLayout:isPortrait];
#endif
#endif
    
    player1.minimumZoomScale = 1;
    player1.maximumZoomScale = 1; //0313 ズーミングできない
    
    playPallet.layer.cornerRadius = 6.0f;
    playPallet.layer.borderWidth = 1.0f;
    playPallet.layer.borderColor = [UIColor whiteColor].CGColor;
    
    slider1.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    rangeSlider1.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.8f];
    
    
	rotator1.continuous = YES;
    rotator1.wrapAround = YES;
	rotator1.style = NDRotatorStyleRotate;
    rotator1.thumbTint = (enum NDThumbTint)NDThumbTintBlue;
    
    [rotator1 setNeedsDisplay];
    vwStampE.frame = CGRectMake(0, 0, vwPaintManager.frame.size.width, vwPaintManager.frame.size.height);
    [vwPaintManager addSubview:vwStampE];
}

// Viewの角を丸くする
- (void) setCornerRadius:(UIView*)radView
{
	CALayer *layer = [radView layer];
	[layer setMasksToBounds:YES];
#ifdef CALULU_IPHONE
	[layer setCornerRadius:6.0f];
#else
	[layer setCornerRadius:12.0f];
#endif
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
// 印刷の設定確認
- (void) priterSetting
{
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	// 印刷の有効／無効を設定ファイルから取得
	BOOL stat = NO;
	if (! [defaluts objectForKey:@"printer_enable"])
	{
        // 初回取得
		// ここで書き込みを行う
		[defaluts setBool:stat forKey:@"printer_enable"];
	}
	else {
		stat = [defaluts boolForKey:@"printer_enable"];
	}
	
	// 印刷ボタンの有効／無効を行う
	btnHardCopyPrint.hidden = ! stat;
	btnHardCopyPrint.tag = (stat)? 1 : 0;
}

// 写真タグIDから画像Viewを取得する
-(OKDClickImageView*)getClickImageViewByTag:(NSInteger)tag
{
	for (OKDClickImageView* imgView in _drawView.subviews)
	{
		if (imgView.tag == tag)
		{
			return (imgView);
		}
	}
	
	return nil;
}

// 重ね合わせカメラボタンの有効／無効設定
- (void) setOverlayCameraButonEnable:(BOOL)isEnable
{
	if (isEnable)
	{
		btnOverlayCamera.enabled = YES;
		[btnOverlayCamera setBackgroundImage: [UIImage imageNamed:@"camera_overlay.png"]
									forState:UIControlStateNormal];
	}
	else
	{
		btnOverlayCamera.enabled = NO;
		[btnOverlayCamera setBackgroundImage: [UIImage imageNamed:@"camera_overlay_disable.png"]
									forState:UIControlStateNormal];
	}
    
}

//2016/4/22 TMS facebook投稿ボタン対応
// facebook投稿ボタンの有効／無効設定
- (void) setFacebookUpButonEnable:(BOOL)isEnable
{
    if (isEnable)
	{
		btnFacebookUp.enabled = NO;
        [btnFacebookUp setBackgroundImage: [UIImage imageNamed:@"facebook_disable.png"]
                                 forState:UIControlStateNormal];
	}
	else
	{
		btnFacebookUp.enabled = NO;
        [btnFacebookUp setBackgroundImage:nil forState:UIControlStateNormal];
		//[btnFacebookUp setBackgroundImage: [UIImage imageNamed:@"facebook_disable.png"]
        //                         forState:UIControlStateNormal];
        
	}
    
    btnMailSend.enabled = YES;
}

// mail送信ボタンの有効／無効設定
- (void) setMailSendButonEnable:(BOOL)isEnable
{
    if (isEnable)
	{
		btnMailSend.enabled = YES;
		[btnMailSend setBackgroundImage: [UIImage imageNamed:@"mailIcon_selected.png"]
                               forState:UIControlStateNormal];
	}
	else
	{
		btnMailSend.enabled = NO;
		[btnMailSend setBackgroundImage: [UIImage imageNamed:@"mailIcon_selected.png"]
                               forState:UIControlStateNormal];
	}
}

// 透過・重ね合わせボタンの有効／無効設定
- (void) setAbreastOverlapButonEnable:(BOOL)isEnable
{
    btnAbreast.enabled = isEnable;
    btnOverlap.enabled = isEnable;
    
	if (isEnable)
	{
		if (btnAbreast.tag == 1)
        {
            [btnAbreast setBackgroundImage: [UIImage imageNamed:@"kari_button_Sideer_select.png"]
                                  forState:UIControlStateNormal];
            [btnOverlap setBackgroundImage: [UIImage imageNamed:@"kari_button_Transmission.png"]
                                  forState:UIControlStateNormal];
        }
        else
        {
            [btnAbreast setBackgroundImage: [UIImage imageNamed:@"kari_button_Sideer.png"]
                                  forState:UIControlStateNormal];
            [btnOverlap setBackgroundImage: [UIImage imageNamed:@"kari_button_Transmission_select.png"]
                                  forState:UIControlStateNormal];
        }
	}
	else
	{
		[btnAbreast setBackgroundImage: [UIImage imageNamed:@"kari_button_Sideer_disable.png"]
                              forState:UIControlStateNormal];
        [btnOverlap setBackgroundImage: [UIImage imageNamed:@"kari_button_Transmission_disable.png"]
                              forState:UIControlStateNormal];
	}
    
}
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
// 遷移元のVCに対して更新処理を行う
- (void) refresh2OwnerTransitionVC
{
	// MainViewControllerの取得
	MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// サムネイル画面からの遷移
	if (self.isNavigationCall)
	{
		// 写真一覧（サムネイル）画面へ通知
		
		// NavigationControllerよりthumbNailクラスのVCを取得
		UIViewController *vc
        = [ mainVC getVC4NaviCtrlWithClass:[ThumbnailViewController class]];
		if (vc)
		{
			// サムネイルの更新
			[(ThumbnailViewController*)vc refreshThumbNail];
		}
		
		// ViewContllerのリストより履歴一覧クラスのVCを取得
		vc = [ mainVC getVC4ViewControllersWithClass:[HistListViewController class] ];
		if (vc)
		{
			// Viewの日付による更新
			[ (HistListViewController*)vc refrshViewWithDate:[NSDate date]];
		}
		
	}
	// 履歴詳細からの遷移
	else
	{
		// 履歴詳細を取得して、サムネイルを更新
		UIViewController *vc
        = [mainVC getVC4ViewControllersWithClass:[HistDetailViewController class]];
		if (vc)
		{
			// サムネイルと選択セルを更新する
			[(HistDetailViewController*)vc thumbnailSelectedCellRefresh];
			
			// ユーザ情報Viewの更新
			[(HistDetailViewController*)vc refreshUserInfoView];
		}
		
		// 履歴一覧VCを取得して、一覧を更新
		vc = [mainVC getVC4ViewControllersWithClass:[HistListViewController class]];
		if (vc)
		{
			// Viewの日付による更新
			[ (HistListViewController*)vc refrshViewWithDate:_workDate];
		}
	}
    
}

// 有効な履歴IDを取得する
- (HISTID_INT) getValidHistID
{
	// 0以上で有効と見なす
	if (_histID >= 0)
	{	return (_histID); }
	
	// 履歴IDをデータベースよりユーザIDと当日で取得する:当日の履歴がない場合は作成する
	HISTID_INT histID;
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	if ( (histID = [usrDbMng getHistIDWithDateUserID:_userID
											workDate:[NSDate date]
									  isMakeNoRecord:YES] ) < 0)
	{
		NSLog(@"getHistIDWithDateUserID error on SelectVideoViewController!");
	}
	
	[usrDbMng release];
	
	return (histID);
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
        btnOverlayCamera.frame = CGRectMake(  5.0f, 30.0f,  38.0f, 38.0f);
        btnHardCopyPrint.frame = CGRectMake(277.0f, 30.0f,  38.0f, 38.0f);
        // 重ね合わせと透過ボタン：縦並び
        // btnAbreast.frame = CGRectMake(5.0f,  76.0f, 38.0f, 38.0f);
        // btnOverlap.frame = CGRectMake(5.0f, 115.0f, 38.0f, 38.0f);
    }
    // 横表示：タイトルとボタン１段表示
    else
    {
        // 施術日：横サイズを大きくして「施術日」のDimを表示
        viewWorkDateBack.frame = CGRectMake(125.0f,  4.0f, 175.0f, 24.0f);
        btnOverlayCamera.frame = CGRectMake(  5.0f,  4.0f,  38.0f, 38.0f);
        btnHardCopyPrint.frame = CGRectMake( 48.0f,  4.0f,  38.0f, 38.0f);
        // 重ね合わせと透過ボタン：横並び
        // btnAbreast.frame = CGRectMake( 5.0f, 44.0f, 38.0f, 38.0f);
        // btnOverlap.frame = CGRectMake(48.0f, 44.0f, 38.0f, 38.0f);
    }
}
#else
// 重ね合わせ・透過ボタンの位置調整
- (void) _buttonLayout:(BOOL)isPortrait
{
    // 縦表示：
    if (isPortrait)
    {
        // 重ね合わせと透過ボタン：縦並び
        btnAbreast.frame = CGRectMake(5.0f,  5.0f, 54.0f, 54.0f);
        btnOverlap.frame = CGRectMake(5.0f, 64.0f, 54.0f, 54.0f);
    }
    // 横表示：タイトルとボタン１段表示
    else
    {
        // 重ね合わせと透過ボタン：横並び
        btnAbreast.frame = CGRectMake( 5.0f, 5.0f, 54.0f, 54.0f);
        btnOverlap.frame = CGRectMake(64.0f, 5.0f, 54.0f, 54.0f);
    }
}

#endif
- (void)saveFrameEditVideo {
    [SVProgressHUD dismiss];
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mp4"];
    NSURL *exportURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    [outputPath release];
    VideoSaveViewController *saveView = [[VideoSaveViewController alloc]
                                         initWithNibName:@"VideoSaveViewController" bundle:nil];
    saveView.saveDelegate = self;
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
	} else {
#ifdef DEBUG
        NSLog(@"exportURL: %@", exportURL);
#endif
        [saveView setVideoUrl:exportURL movie:movieResource histId:histID];
    }
    [usrDbMng release];
    [movieResource release];
    [exportURL release];
}
- (void)dismissProgress {
    [SVProgressHUD dismiss];
    
    [Common showDialogWithTitle:@"動画" message:@"動画の合成に失敗しました。"];
}
- (void)finishVideoSave:(BOOL)isSaved {
    shouldSave = !isSaved;
    remainSavingVideo = NO;
}

#pragma mark life_cycle

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */

// Implement loadView to create a view hierarchy programmatically, without using a nib.
/*
 - (void)loadView
 {
 [super loadView];
 
 // ScrollViewと描画Viewの作成
 [self makeScrDrawView];
 
 }
 */

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
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
	
	// 背景Viewの角を丸くする
	[self setCornerRadius:viewUserNameBack];
	[self setCornerRadius:viewWorkDateBack];
	
	// NavigationCallによる画面遷移の場合はスワイプをセットアップする
	if (self.isNavigationCall)
	{	[self setupSwipSupport]; }
	
	_isPicturePaintDisplaied = NO;
	
	// 印刷の設定確認
	[self priterSetting];
	
	// 遷移画面の初期化:選択画像一覧画面
	_windowView = WIN_VIEW_SELECT_PICTURE;
	
	// 画面ロックモードを確認する
	MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	if ([mainVC isWindowLockState])
	{	[self OnWindowLockModeChange:YES]; }
    
    // ２枚選択時の初期は画像重ね合わせ
    btnAbreast.tag = 1;
    btnOverlap.tag = 0;
    // 動画編集モードボタンの初期化
    [self setVideoEditButtonEnable:NO];
#ifndef AIKI_CUSTOM
    // facebookの利用が可能なアカウントで有るかを確認する
    [self setFacebookEnableIsFlag:[AccountManager isAccountCanUseFacebook]];
#endif
    // mailの利用が可能かを確認する
    [self setMailEnableIsFlag:[AccountManager isLogined]];
    
    //>>>>>>>>>>>> edit DELC SASAGE
    [SVProgressHUD showWithStatus:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
    btnFacebookUp.hidden = btnHardCopyPrint.hidden = btnMailSend.hidden = btnOverlayCamera.hidden = YES;
    slider1 = [[SyncSlider alloc] init];
    player1 = [[SyncPlayerView alloc] init];
    rangeSlider1 = [[RangeSlider alloc] init];
    
    currentTimeLabel.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    currentTimeLabel.font = [UIFont systemFontOfSize:11.0f];
    currentTimeLabel.textColor = [UIColor colorWithWhite:0.3f alpha:1.0f];
    currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    currentTimeLabel.adjustsFontSizeToFitWidth = YES;
    
    underCurrentTimeView.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.8f];
    
    imgvwOverlay1 = [[UIImageView alloc] init];
    imgvwOverlay2 = [[UIImageView alloc] init];
    
    angle1 = rotator1.angle;
    
    player1.playerDelegate = slider1;
    player1.playDelegate = self;
    slider1.delegate = self;
    rangeSlider1.delegate = self;
    
    player1.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:player1];
    [self.view addSubview:slider1];
    [self.view addSubview:rangeSlider1];
    // パレットの初期化
	vwPaintPallet = [[PicturePaintPalletView alloc] initWithEventListner:vwPaintManager];
	[self.view addSubview:vwPaintPallet];
	vwPaintPallet.backgroundColor = [UIColor blackColor];
#ifdef VARIABLE_PICTURE_PAINT_PALLET
    // 動的パレットの初期化
    [vwPaintPallet initVariablePallet:self.view];
#endif
    [vwPaintPallet setupPalletPopup];
	// 写真描画の管理クラスの初期設定
	vwPaintManager.scrollViewParent = player1;
	vwPaintManager.vwSaparete = vwSaparete1;
	vwPaintManager.vwGrayOut1 = vwGrayOut11;
	vwPaintManager.vwGrayOut2 = vwGrayOut12;
	vwPaintManager.vwPallet = vwPaintPallet;
    //スタンプ
    vwPaintManager.vwStampE = vwStampE;
    
    [vwPaintManager initLocal];
//    // パレットの初期化
//	vwPaintPallet2 = [[PicturePaintPalletView alloc] initWithEventListner:vwPaintManager2];
//	// [self.view addSubview:vwPaintPallet2];
//	vwPaintPallet2.backgroundColor = [UIColor blackColor];
//#ifdef VARIABLE_PICTURE_PAINT_PALLET
//    // 動的パレットの初期化
//    [vwPaintPallet initVariablePallet:self.view];
//#endif
//    [vwPaintPallet2 setupPalletPopup];
	// 写真描画の管理クラスの初期設定
    
    //    vwPaintManager.vwStampE = vwStampE;
    //    vwPaintManager.imgvwStamp = imgvwStamp;
    
    player1.scrollEnabled = NO;
    player1.userInteractionEnabled = YES;
    
    vwVideoEditMode.backgroundColor = [UIColor colorWithRed:0.38 green:0.45 blue:0.21 alpha:1.0f];
    vwVideoEditMode.layer.cornerRadius = 12.0f;
    vwVideoEditMode.layer.shadowColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
    vwVideoEditMode.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    vwVideoEditMode.layer.shadowOpacity = 1.0f;
    
	// Alertダイアログの初期化
	modifyCheckAlert = [[UIAlertView alloc] init];
	modifyCheckAlert.title = @"画像描画";
	modifyCheckAlert.message = @"編集した画像を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集内容は\n破棄されます）";
	modifyCheckAlert.delegate = self;
	[modifyCheckAlert addButtonWithTitle:@"は　い"];
	[modifyCheckAlert addButtonWithTitle:@"いいえ"];
    
    // 動画読み込みまで、関連viewを非表示にする
    playPallet.hidden = YES;
    slider1.hidden = YES;
    rangeSlider1.hidden = YES;
    underCurrentTimeView.hidden = YES;
    rotator1.hidden = YES;
    ivErrorDisp.hidden = YES;
    btnAnimeAdd1.hidden = YES;
    btnAnimeAdd1.enabled = NO;
    btnSave.hidden = YES;
    vwPaintPallet.hidden = YES;
    vwVideoEditMode.hidden = YES;
}

// 画面が表示される都度callされる:viewWillAppear
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear : animated];
	// カメラ画面からの遷移の場合
	if ( _windowView == WIN_VIEW_CAMERA)
	{
		// 遷移元のVCに対して更新処理を行う
		[self refresh2OwnerTransitionVC];
		
		// 遷移画面を元に戻しておく:選択画像一覧画面
		_windowView = WIN_VIEW_SELECT_PICTURE;
		
		// return;
	}else{
        //右画面への遷移を無効
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC setScrollViewWidth:YES];
	}
	// ScrollViewと描画Viewの作成
	// [self makeScrDrawView];
	
	UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
	BOOL isPortrait = (screen.applicationFrame.size.width == 320.0f);
#else
  	BOOL isPortrait = (screen.applicationFrame.size.width == 768.0f);
#endif
	
	// 画像Itemのレイアウト
	//[self moviesLayout : isPortrait];
	
	// 全画面表示viewの更新
	[_fullView refresh : isPortrait];
	
	// 印刷ボタンと重ね合わせカメラボタンを最前面にする
	if (! btnHardCopyPrint.hidden)
	{	[self.view bringSubviewToFront:btnHardCopyPrint]; }
	[self.view bringSubviewToFront:btnOverlayCamera];
    [self.view bringSubviewToFront:btnFacebookUp];      // facebook投稿ボタンも最前面にする
    [self.view bringSubviewToFront:btnMailSend];

	// 重ね合わせカメラの初期状態は無効
	[self setOverlayCameraButonEnable: NO];
    
    // facebook投稿ボタンの初期状態は無効
    [self setFacebookUpButonEnable:[AccountManager isFaceBook]];
    
    
    player1.playDelegate = self;
    slider1.delegate = self;
    rangeSlider1.delegate = self;
    
    // DELC SASAGE
    // PaintManagerViewの設定
    // 管理Viewのtouchを無効にする
	vwPaintManager.userInteractionEnabled = YES;
    //vwGrayOut11.userInteractionEnabled = NO;
    //vwGrayOut12.userInteractionEnabled = NO;
	[vwPaintManager allClearCanvas];
	//[vwPaintManager1 deleteSeparate];
	// [vwPaintPallet1 initBtnSeparate];    // 区分線は使わない
    [vwPaintManager initDrawObject];
    
	vwPaintManager.userInteractionEnabled = YES;
	[vwPaintManager allClearCanvas];
	//[vwPaintManager2 deleteSeparate];
	// [vwPaintPallet2 initBtnSeparate];    // 区分線は使わない
    [vwPaintManager initDrawObject];
	// NavigationCallによる画面遷移の場合はスワイプをセットアップする
	if (self.isNavigationCall)
	{	[self setupSwipSupport]; }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

// 縦横切り替え後のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	BOOL isPortrait;
	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			// 縦向け
			isPortrait = YES;
			break;
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			isPortrait = NO;
			break;
		default:
			isPortrait = NO;	// 念のため
			break;
	}
	
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
    if (iOSVersion>=7.0f && self.isNavigationCall) {
        uiOffset = 20.0f;
    }
    if(self.isNavigationCall) {
        // 本体のサイズ変更
        [self.view setFrame:CGRectMake(0.0f, 0.0f, scrWidth, scrHeigth + uiOffset)];
    }

    [self moviesLayout : isPortrait];
	// 画像Itemのレイアウト
////>>>>>>>>>>>>>>>
//	if ((_drawView) && (_scrollView) )
//	{
//		[self moviesLayout : isPortrait];
//	}
////<<<<<<<<<<<<<<<
	// 全画面表示viewの更新
	if (_fullView)
	{
		[_fullView refresh : isPortrait];
	}
#ifdef CALULU_IPHONE
    // タイトル、ボタンの位置調整
    [self _titelButtonLayout:isPortrait];
#endif
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

}
// 現在のデバイスの向きを取得
- (UIInterfaceOrientation) getNowDeviceOrientation
{
	UIInterfaceOrientation orient;
	
	switch ([UIDevice currentDevice].orientation)
	{
		case UIDeviceOrientationPortrait:
			orient = UIInterfaceOrientationPortrait;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			orient = UIInterfaceOrientationPortraitUpsideDown;
			break;
		case UIDeviceOrientationLandscapeLeft:
			orient = UIInterfaceOrientationLandscapeLeft;
			break;
		case UIDeviceOrientationLandscapeRight:
			orient = UIInterfaceOrientationLandscapeRight;
			break;
		default:
			// デバイスより取得できなかった場合はUIScreenオブジェクトより取得
			orient = [self getNowDeviceOrientationWithScreen];
			break;
	}
	
	return (orient);
}

// 現在のデバイスの向きを取得(UIScreenオブジェクトより取得)
- (UIInterfaceOrientation) getNowDeviceOrientationWithScreen
{
	// 画面サイズの取得
	UIScreen *screen = [UIScreen mainScreen];
	
	UIInterfaceOrientation orient
#ifdef CALULU_IPHONE
    = (screen.applicationFrame.size.width == 320.0f)?
#else
    = (screen.applicationFrame.size.width == 768.0f)?
#endif
    UIInterfaceOrientationPortrait :
    UIInterfaceOrientationLandscapeLeft;
	
	return (orient);
}
// 画面が表示される都度callされる:viewDidAppear
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear : animated];
	_modifyCheckAlertWait = -1;
    // 動画がロードされているときは表示を確実に行うのみ
    if (self.isFlickEnable) {
        if (player1.ready) {
            
            [player1.player seekToTime:player1.player.currentTime
                       toleranceBefore:kCMTimeZero
                        toleranceAfter:kCMTimeZero];
        }
    }
    
    // 各Viewの順番調整
    // vwPaintManagerがplayer1,2の上位にないと、ペン色、太さなどの変更時に
    // playerにかぶったときに操作できないポイントができてしまう
    [self.view sendSubviewToBack:vwPaintManager];
    [self.view sendSubviewToBack:player1];
}

- (void)viewDidDisappear:(BOOL)animated
{
	if (_isBackCameraView != YES)
	{
		// 現時点で最上位のViewController(=self)を削除する
        [self dismissViewControllerAnimated:animated completion:nil];
	}
	
	/*
	 if (_isBackCameraView)
	 {
	 // 画像選択画面Viewを非表示する
	 [self.view removeFromSuperview];
	 
	 }
	 */
    player1.playDelegate = nil;
    slider1.delegate = nil;
    rangeSlider1.delegate = nil;
	modifyCheckAlert.delegate = nil;
#ifdef DEBUG
    NSLog(@"%s [%lu]", __func__, (unsigned long)[self retainCount]);
#endif
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [vwStampE release];
    vwStampE = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {

    [vwPaintManager removeObserver:self forKeyPath:@"IsDirty"];
    vwPaintManager.vwPallet = nil;
	vwPaintManager.scrollViewParent = nil;
    
    for (UIView *sv in imgvwOverlay1.subviews) {
        [sv removeFromSuperview];
    }
    for (UIView *sv in imgvwOverlay2.subviews) {
        [sv removeFromSuperview];
    }
    for (UIView *sv in self.view.subviews) {
        [sv removeFromSuperview];
    }
    [vwPaintManager removeFromSuperview];
    
    [vwPaintPallet removeFromSuperview];
    
    [imgvwOverlay1 removeFromSuperview];
    [imgvwOverlay2 removeFromSuperview];

#ifdef DEBUG
    NSLog(@"%s [%lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu]", __func__,
          (unsigned long)[player1 retainCount],
          (unsigned long)[player1.player retainCount],
          (unsigned long)[slider1 retainCount],
          (unsigned long)[rangeSlider1 retainCount],
          (unsigned long)[imgvwOverlay1 retainCount],
          (unsigned long)[imgvwOverlay2 retainCount],
          (unsigned long)[vwPaintManager retainCount],
          (unsigned long)[vwPaintPallet retainCount]
          );
    NSLog(@"[%lu, %lu, %lu]",
          (unsigned long)[self.videoPreviewVC1 retainCount],
          (unsigned long)[animations1 retainCount],
          (unsigned long)[playRateArray retainCount]
          );
#endif
    
    [imgvwOverlay1 release];
    [imgvwOverlay2 release];
    
    imgvwOverlay1 = nil;
    imgvwOverlay2 = nil;
    [playRateArray release];
    [animations1 release];
    
    [lblPlaySpeed release];
    [lblUserName release];
    [lblWorkDate release];
    [lblWorkDateTitle release];
    [viewUserNameBack release];
    [viewWorkDateBack release];
    [btnAbreast release];
    [btnFacebookUp release];
    [btnHardCopyPrint release];
    [btnLockMode release];
    [btnMailSend release];
    [btnOverlap release];
    [btnOverlayCamera release];
    [btnPlay release];
    [playPallet release];
    
    [rotator1 release];

    [vwPaintManager release];
     
    [rangeSlider1 release];
	[vwSaparete1 release];
	[vwGrayOut11 release];
	[vwGrayOut12 release];
	[vwSaparete2 release];
	[vwGrayOut21 release];
	[vwGrayOut22 release];
	[vwPaintPallet release];
	// [vwPaintPallet2 release];
	[pictImageItems release];
    
    // PlayerView のdeallocで [self.playDelegate release] されているため
    // [slider1 release]は実行しない
    [player1 release];
    player1.playerDelegate = nil;
    player1.delegate = nil;
    player1.syncPlayer = nil;
    player1.player = nil;

//    [slider1 asyncStop];
//    [slider1 release];
//    slider1.otherSlider = nil;

    [videoPreviewVC release];
    [currentTimeLabel release];
    
    [_btnPrevView release];
	[_fullView release];
	[_drawView release];
	[_scrollView release];
	[_workDate release];
    [movie release];
    [vwStampE release];
    if (popoverCntlMailSend) {
        [popoverCntlMailSend release];
    }
    
    [self.videoPreviewVC1 release];
    [self.videoPreviewVC2 release];
    
    [ivErrorDisp release];
	[super dealloc];
}

#pragma mark MainViewControllerDelegate

// 新規View画面への遷移
//		return: 次に表示する画面のViewController  nilで遷移をキャンセル
- (UIViewController*) OnTransitionNewView:(id)sender
{
    //0313 どんづまり
    return nil;

}

// 新規View画面への遷移でViewがLoadされた後にコールされる
- (void) OnTransitionNewViewDidLoad:(id)sender transitionVC:(UIViewController*)tVC
{
    //0313 遷移しない

}

// 既存View画面への遷移
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC
{
    //0313 遷移しない
    return NO;
}
// 画面終了の通知
- (BOOL) OnUnloadView:(id)sender
{
    if (!player1.hidden) {
        [player1 pause];
    }
    
    if (shouldSave)
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
			
			// はいが押された
			if (wait == 1)
			{
                // Viewを非表示にする
                self.view.hidden = YES;
                return (NO);
            }
		}
		// MainVCによるもの
		else {
			_modifyCheckAlertWait = 0;
			return (NO);
		}
	}
//    if (![self checkSholdSave]) {
//        return  NO;
//    }
    //
    slider1.delegate = nil;
    rangeSlider1.delegate = nil;
    
	// 全画面表示viewを消去する
	if (_fullView)
	{	[_fullView hideFullScreenImageView]; }
    
    // 前画面に戻る前にsubViewとなるImageViewを全て削除する
    if (_drawView)
    {
        for ( UIView *vw in _drawView.subviews)
        {   [vw removeFromSuperview]; }
    }
	return (YES);		// 画面遷移する
}
- (BOOL)checkSholdSave {
    if (shouldSave)
	{
		// 合成画像が保存されていなければ、alertを表示して画面遷移しない
		[modifyCheckAlert show];
        _modifyCheckAlertWait = 1;
        return NO;
	} else {
        return YES;
    }
}
// 画面ロックモード変更
- (void) OnWindowLockModeChange:(BOOL)isLock
{
}

// スクロール実施の確認 : NOを返すとスクロールをキャンセル
// - (BOOL) OnCheckTouchDeleverd:(id)sender touchPoint:(CGPoint)pt touchView:(UIView*)view
- (BOOL) OnCheckScrollPerformed:(id)sender touchView:(UIView*)view
{
    BOOL isPerformed = ! _isModeLock;
    
    // NSLog(@"%s touchPoint x=>%f y=>%f", __func__, pt.x, pt.y);
    
    // ローテータおよびスライダーの場合は、スクロールをキャンセルする
    if ( (slider1 == view) || (rotator1 == view)) {
        isPerformed = NO;
    }
    
    return (isPerformed);
}

#pragma mark player Delegate
- (void)finishPlayBack {
    NSLog(@"%s",__func__);
    if (isPlaySynth){
        [btnPlay setSelected:NO];
    } else {
        [btnPlay setSelected:player1.isPlay];
    }
}
- (void)syncSliderValueChanged:(SyncSlider *)slider {
    if (!btnFrameDraw.hidden && btnFrameDraw.enabled && btnFrameDraw.selected) {
        if (slider == slider1) {
            [self sliderValueChanged:1];
        }
    }
    float current = CMTimeGetSeconds(player1.player.currentTime);
//    currentTimeLabel.text = [NSString stringWithFormat:@"%d:%02d/%d:%02d",
//                             ((int)current) / 60,((int)current) % 60,
//                             ((int)movieDuration) / 60,((int)movieDuration) % 60];
    currentTimeLabel.text = [NSString stringWithFormat:@"%04.1f/%04.1f",current,movieDuration];
}
- (void)rangeSliderValueChanged:(RangeSlider *)slider changedSliderNum:(NSInteger)changedSliderNum{
    if (!btnFrameDraw.hidden && btnFrameDraw.enabled && btnFrameDraw.selected) {
        if (slider == rangeSlider1 ) {
            [self sliderValueChanged:1];
        }
    }
}
- (void)sliderValueChanged:(NSInteger)number {
    if (number == 1) {
        CGFloat second = slider1.value / TIMESCALE;
        BOOL drawenable = (rangeSlider1.selectedMinimumValue <= second &&
                           second <= rangeSlider1.selectedMaximumValue);
        vwPaintManager.layer.opacity = (drawenable ? 1.0f: 0.05f); // 描画内容の表示／非表示。 opacity=0にするとタッチが感知されない。
        vwPaintManager.IsDrawenable = drawenable; // 再生位置が描画可能範囲外だと描画できないー＞アラートがでる。
        
        for (AnimationElement *anime in animations1) {
            anime.hidden = !(anime.begin <= second && second <= anime.end);
        }
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
	if (! self.isNavigationCall)
	{
		MainViewController *mainVC
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		[mainVC viewScrollLock:_isModeLock];
	}
    // paint系
    [vwPaintPallet setLockState:_isModeLock];
    // 写真描画の管理クラスに通知
    [vwPaintManager changeLockMode:_isModeLock];
    // 動画描画モード
    [self setVideoEditButtonEnable:_isModeLock];
    // フレーム描画用スライダー /　アニメ追加ボタン
    rangeSlider1.hidden = underCurrentTimeView.hidden = btnAnimeAdd1.hidden = YES;
    if (_isModeLock && btnFrameDraw.enabled && btnFrameDraw.selected) {
        rangeSlider1.hidden = NO;
        underCurrentTimeView.hidden = NO;
        btnAnimeAdd1.hidden = NO;
    }
}

// カメラ画面へ戻る
- (IBAction)OnCameraView
{
	// 現時点で最上位のViewController(=self)を削除する
	_isBackCameraView = YES;
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}
// 画像ファイル選択
- (IBAction)OnSelectVideoView
{
    // 動画描画画面から動画選択画面に
    if ([self OnUnloadView:self]) {
        CGRect vf = self.view.frame;
        [UIView animateWithDuration:0.4 animations:^(void){
            self.view.frame = CGRectMake(vf.size.width, vf.origin.y, vf.size.width, vf.size.height);
        } completion:^(BOOL flg){
            self.view.hidden = YES;
        }];
    }
}
// 重ね合わせカメラ
- (IBAction)OnOverlayCamera
{
}

// ハードコピー
- (IBAction)OnHardCopyPrint
{
	btnHardCopyPrint.enabled = NO;
	
	// 完了時のハンドラ
	UIPrintInteractionCompletionHandler completionHandler
    = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error)
	{
		btnHardCopyPrint.enabled = YES;
		
		if(completed)
		{	/*btnHardCopyPrint.enabled = YES;*/}
		
		if (error)
		{
			NSLog(@"FAILED! due to error in domain %@ with error code %ld",
				  error.domain, (long)error.code);
			
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:@"画面印刷"
									  message:@"印刷できませんでした"
									  delegate:nil
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil
									  ];
			[alertView show];
			[alertView release];
		}
	};
    
	
	[UtilHardCopySupport startHardCopy:btnHardCopyPrint.bounds inView:self.view
					 completionHandler:completionHandler];
}

// facebook投稿
- (IBAction)OnFacebookUp
{
}

- (IBAction)OnBtnSynthesisModeChange:(id)sender{
    UIButton* selectBtn = sender;
    if (selectBtn == btnAbreast) {
        btnAbreast.tag = 1;
        [btnAbreast setBackgroundImage:[UIImage imageNamed:@"kari_button_Sideer_select.png"]
                              forState:UIControlStateNormal];
        
        btnOverlap.tag = 0;
        [btnOverlap setBackgroundImage:[UIImage imageNamed:@"kari_button_Transmission.png"]
                              forState:UIControlStateNormal];
    }else if(selectBtn == btnOverlap){
        btnAbreast.tag = 0;
        [btnAbreast setBackgroundImage:[UIImage imageNamed:@"kari_button_Sideer.png"]
                              forState:UIControlStateNormal];
        
        btnOverlap.tag = 1;
        [btnOverlap setBackgroundImage:[UIImage imageNamed:@"kari_button_Transmission_select.png"]
                              forState:UIControlStateNormal];
    }
}
- (IBAction)OnSave {
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion<6.0f) {
        [Common showDialogWithTitle:@"動画について" message: @"動画保存はiOS6以降で可能です。"];
        return;
    }
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
            [self OnBtnAddAnime:btnAnimeAdd1];
        }
        NSMutableArray *animations = [NSMutableArray array];
        if (movie.hasOverlayImage) {
            AnimationElement *anime = [[AnimationElement alloc] initWithFrame:imgvwOverlay1.frame];
            anime.image = imgvwOverlay1.image;
            anime.begin = 0.0f;
            anime.end = CMTimeGetSeconds(player1.player.currentItem.duration);
            [animations addObject:anime];
            [anime release];
        }
        for (AnimationElement *anime in animations1) {
            [animations addObject:anime];
        }
        [self mix:movie animations:animations];
        // ２つ目の動画は１つ目の動画を保存し終えた時にfinishVideoSaveで保存する
    } else if (btnWindowDraw.selected){
        NSMutableArray *animations = [NSMutableArray array];
        AnimationElement *anime = [[AnimationElement alloc] initWithFrame:vwPaintManager.frame];
        anime.image = [self canvasImage:vwPaintManager player:player1.player];
        anime.begin = 0.0f;
        anime.end = CMTimeGetSeconds(player1.player.currentItem.duration);
        [animations addObject:anime];
        [self mix:movie animations:animations];
        [anime release];

    } else {
        [Common showDialogWithTitle:@"動画保存" message: @"動画は編集されていません。"];
        isSaving = NO;
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
- (void)mix:(MovieResource *)_movie animations:(NSMutableArray *)animations {
    //
    [SVProgressHUD showWithStatus:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
    //
    AVURLAsset *asset;
    if(_movie.movieIsExistsInCash) {
//        [player setVideoUrl:[[NSURL alloc] initFileURLWithPath:movie.movieCashPath]];
        asset = [[AVURLAsset alloc] initWithURL:[[NSURL alloc] initFileURLWithPath:_movie.movieCashPath] options:nil];
    } else {
//        [player setVideoUrl:movie.movieURL];
        asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:_movie.movieFullPath] options:nil];
    }

//    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:_movie.movieFullPath] options:nil];
    
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    CGSize naturalSize = [EditVideoViewController naturalSizeOfAVAsset:asset];
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    [MainInstruction retain];
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    //>>>>> 音声ファイルも別で付け足す （マイクの許可が無い場合、音声なしで記録する）
    [MicUtil isMicAccessEnableWithIsShowAlert:NO completion:^(BOOL isMicAccessEnable) {
        if(isMicAccessEnable) {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            NSInteger idx = [[asset tracksWithMediaType:AVMediaTypeAudio] count];
            if (idx > 0) {
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(asset.duration, kCMTimeZero)) ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            }
        }
    }];
    //<<<<<
    
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    [FirstlayerInstruction setTransform:assetTrack.preferredTransform atTime:kCMTimeZero];
    
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];
    
        // 親レイヤー
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);// videoSize
        videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);// videoSize
        [parentLayer addSublayer:videoLayer];
    
        for (AnimationElement *anime in animations) {
            CALayer *logoLayer = [CALayer layer];
            UIImage *image = anime.image;
            logoLayer.contents = (id)image.CGImage;
        // logoLayer.contents = (id)[UIImage imageNamed:@"calulu.jpg"].CGImage;
            logoLayer.frame = CGRectMake(0, 0, image.size.width, image.size.height);
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
                animation.beginTime = anime.begin - transitionTime;
                [logoLayer addAnimation:animation forKey:@"animateOpacity1"];
    
                animation
                =[CABasicAnimation animationWithKeyPath:@"opacity"];
                animation.duration= duration;;
                animation.removedOnCompletion = NO; // by Pechkin
                // animate from fully visible to invisible
                animation.fromValue=[NSNumber numberWithFloat:1.0];
                animation.toValue=[NSNumber numberWithFloat:1.0];
                animation.beginTime = anime.begin;
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
            animation.beginTime = anime.begin + duration;
            [logoLayer addAnimation:animation forKey:@"animateOpacity3"];
    
            if (logoLayer.opacity >= 1.0f) {
                animation
                =[CABasicAnimation animationWithKeyPath:@"opacity"];
                animation.duration = CMTimeGetSeconds(mixComposition.duration) - (anime.end + transitionTime);
                animation.removedOnCompletion = NO; // by Pechkin
                // animate from fully visible to invisible
                animation.fromValue=[NSNumber numberWithFloat:0.0];
                animation.toValue=[NSNumber numberWithFloat:0.0];
                animation.beginTime = anime.end + transitionTime;
                [logoLayer addAnimation:animation forKey:@"animateOpacity4"];
            }
            [parentLayer addSublayer:logoLayer];
        }
    
    
    
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    //[MainCompositionInst retain];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    MainCompositionInst.renderSize = naturalSize;
    //****** 3. AVAssetExportSessionを使用して1と2のコンポジションを合成。 *****

    // 1のコンポジションをベースにAVAssetExportを生成
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset: mixComposition presetName:AVAssetExportPresetHighestQuality];
    // 2の合成用コンポジションを設定
    assetExport.videoComposition = MainCompositionInst;
    //assetExport.audioMix = audioMix;
    
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

    //エクスポート実行
    [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
        if (assetExport.status == AVAssetExportSessionStatusCompleted) {
            [self performSelectorOnMainThread:@selector(saveFrameEditVideo) withObject:nil waitUntilDone:NO];
        } else {
            NSLog(@"合成/保存失敗 Error: %@", [assetExport.error description]);
            [self performSelectorOnMainThread:@selector(dismissProgress) withObject:nil waitUntilDone:NO];
        }
        [asset release];
        [MainInstruction retain];
        [MainCompositionInst retain];
        isSaving = NO; // 動画保存画面ではどちらにせよ押せない。
    }];
}

- (IBAction)OnBtnVideoEditModeChange:(id)sender {
    UIButton *videoEditButton = sender;
    if (videoEditButton == btnWindowDraw) {
        if (btnFrameDraw.isSelected && (vwPaintManager.IsDirty)) {
            
            [UIAlertView displayAlertWithTitle:@"動画編集モードの変更"
                                       message:@"モードを変更すると、編集した内容が失われます。よろしいですか？"
                               leftButtonTitle:@"はい"
                              leftButtonAction:^(void){
                                  [self clearCanvas];
                                  [self setFrameDrawMode:NO];
                                  shouldSave = NO;
                              }
                              rightButtonTitle:@"いいえ"
                             rightButtonAction:^(void){
                                 return;
                             }];
        } else {
            
            [self setFrameDrawMode:NO];
        }
    } else if(videoEditButton == btnFrameDraw) {
        if (btnWindowDraw.isSelected && (vwPaintManager.IsDirty)) {
            
            [UIAlertView displayAlertWithTitle:@"動画編集モードの変更"
                                       message:@"モードを変更すると、編集した内容が失われます。よろしいですか？"
                               leftButtonTitle:@"はい"
                              leftButtonAction:^(void){
                                  [self clearCanvas];
                                  [self setFrameDrawMode:YES];
                                  shouldSave = NO;
                              }
                              rightButtonTitle:@"いいえ"
                             rightButtonAction:^(void){
                                 return;
                             }];
        } else {
            [self setFrameDrawMode:YES];
        }
    }
}
- (void)clearCanvas {
    
	[vwPaintManager allClearCanvas];
	//[vwPaintManager1 deleteSeparate];
    [vwPaintManager initDrawObject];
    vwPaintManager.IsDirty = NO;
    for (AnimationElement *anime in animations1) {
        [anime removeFromSuperview];
    }
    [animations1 removeAllObjects];
}
- (void)setFrameDrawMode:(BOOL)isFrameDraw {
    [btnWindowDraw setSelected:!isFrameDraw];
    [btnFrameDraw setSelected:isFrameDraw];
    rangeSlider1.hidden = !isFrameDraw;
    underCurrentTimeView.hidden = !isFrameDraw;
    btnAnimeAdd1.hidden = !isFrameDraw;
    vwPaintManager.alpha = isFrameDraw ? 0.5f : 1.0f;
}
- (IBAction)OnPlaySynth:(id)sender {
}
#pragma mark UIAlertViewDelegate

// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// 合成画像保存確認の場合
	if (alertView == modifyCheckAlert)
	{
		// MainVCによる場合で「はい」がタップされた場合
		if ( ((_modifyCheckAlertWait == 0) && (buttonIndex == 0)) ||
             ((_modifyCheckAlertWait == 1) && (buttonIndex == 1))
            )
		{
			// MainViewControllerの取得
			MainViewController *mainVC
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
			
			// 前画面に戻る
            [mainVC backBeforePage];
		}
        // サムネイル一覧経由の場合
		if (_isFlickEnable && (buttonIndex ==0)){
            //0313 [self OnVideoCompView:nil];
        }
		// 押されたボタンを保存
		_modifyCheckAlertWait = buttonIndex;
        
		// 合成と画像編集の編集フラグをクリア
        if(buttonIndex == 0) {
            vwPaintManager.IsDirty = NO;
            [self clearCanvas]; // 描画内容をクリア
        }
	}
	
	// alertの表示を消す
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
	
	// 描画領域のクリアなど終了処理
	// [self onDestoryView];
	
}

#pragma mark - スワイプ
// 右方向のスワイプイベント
- (void)OnSwipeRightView:(id)sender
{
    // ロックモードの時は何もしない
	if (_isModeLock)
	{	return; }
    
	// 前画面に戻る
	if (self.isFlickEnable)
	{
        //if (vwPaintManager1.IsDirty || animations1.count > 0 || vwPaintManager2.IsDirty || animations2.count > 0) {
        if (shouldSave) {
            // 合成動画が保存されていなければ、alertを表示して画面遷移しない
            _modifyCheckAlertWait = -1;
            [modifyCheckAlert show];
            
            // ダイアログの応答待機
            NSInteger wait;
            while ((wait = _modifyCheckAlertWait) < 0)
            {
                [[NSRunLoop currentRunLoop]
                 runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
            }
            
            // はいが押された
            if (wait == 0)
            {
                [self OnSelectVideoView];
            }
        } else
            [self OnSelectVideoView];

    }
}

// 左方向のスワイプイベント
- (void)OnSwipeLeftView:(id)sender
{
    // 次へは進めない。どんづまり。
    return;
}

#pragma mark-
#pragma mark public_methods

// facebook機能の有効
- (void) setFacebookEnableIsFlag:(BOOL)isEnable
{
    BOOL isHidden = ! isEnable;
    
    btnFacebookUp.hidden = isHidden;
}

// mail機能の有効
- (void) setMailEnableIsFlag:(BOOL)isEnable
{
    BOOL isHidden = ! isEnable;
    
    btnMailSend.hidden = isHidden;
    
    [self setMailSendButonEnable:isEnable];
}

// スワイプ可能か　ー＞描画中はオフにしないとタッチがキャンセルされてしまう。
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (_isModeLock) {
        return NO;
    }
    return YES;
}

- (IBAction)OnMailSend {
}

- (void) OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    self.view.userInteractionEnabled = YES;
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:NO];
}
// DELC SASAGE PictImageItemsと添字からUIImage取得
- (UIImage *)pictImage:(NSInteger)idx{
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID: _userID];
    return [((OKDThumbnailItemView*)pictImageItems[idx]) getRealSizeImage:imgFileMng];
}
- (void)willResignActive {
    [btnPlay setSelected:NO];
    [player1 pause];
}
#pragma mark 動画関連のボタン
// 両者が止まっているときのみ、再生可能
- (IBAction)OnPlay {
    if (!player1.hidden) {
        if(!player1.isPlay){
            [player1 play];
        } else {
            [player1 pause];
        }
    }
    [btnPlay setSelected:player1.isPlay];
}
- (IBAction)OnPlaySpeed {
    CGFloat speed = player1.playRate;
    for (int i = 0; i < playRateArray.count; i++) {
        if ([(NSNumber *)playRateArray[i] floatValue] == speed) {
            player1.playRate = [(NSNumber *)playRateArray[(i + 1) % playRateArray.count] floatValue];
            
            lblPlaySpeed.text = [NSString stringWithFormat:@"%d%%",(int)(player1.playRate * 100)];
            return;
        }
    }
}

- (IBAction)OnBtnAddAnime:(id)sender {
    if (!(btnFrameDraw.enabled && btnFrameDraw.enabled)) {
        return;
    }
    if (sender == btnAnimeAdd1) {
        AnimationElement *anime = [[AnimationElement alloc] initWithFrame:
                                   CGRectMake(0, 0, player1.frame.size.width, player1.frame.size.height)];
        anime.image = [self canvasImage:vwPaintManager player:player1.player];
        anime.begin = rangeSlider1.selectedMinimumValue;
        anime.end = rangeSlider1.selectedMaximumValue;
        anime.hidden = vwPaintManager.hidden;
        [imgvwOverlay1 insertSubview:anime belowSubview:vwPaintManager];
        [animations1 addObject:anime];
        [vwPaintManager allClearCanvas];
        [vwPaintManager initDrawObject];
        vwPaintManager.IsDirty = NO;
        vwPaintManager.hidden = NO;
        
        [anime release];
    }
}

#ifdef FULLSIZE_PREVIEW
/**
 * 選択動画が１つの時に画面いっぱいに動画のプレビューを行わせる
 */
- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)sender {
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    //MovieResource *movie = nil;
    if (sender.view == player1) {
        if (!self.videoPreviewVC1) {
            self.videoPreviewVC1 = [[VideoPreviewWideViewController alloc] init];
        }
//        {
//            self.videoPreviewVC1 = [[VideoPreviewWideViewController alloc] init];
//        }
        
        [self.videoPreviewVC1 setMovie:movie];
        [mainVC.view addSubview:self.videoPreviewVC1.view];
    }
}
#endif
@end
