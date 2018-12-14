//
//  SelectPictureViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "Common.h"

#import "iPadCameraAppDelegate.h"
#import "SelectVideoViewController.h"

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

ThumbnailViewController *thumbnailVC;
// PicturePaintViewController *picturePaintVC;

@implementation SelectVideoViewController

@synthesize isNavigationCall = _isNavigationCall;
@synthesize isFlickEnable = _isFlickEnable;
@synthesize workDate = _workDate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		// メンバの初期化
		movies = nil;
		_scrollView = nil;
		_drawView = nil;
		
		_isFlickEnable = NO;
        
        _selectedImageIndex1 = -1;
        _selectedImageIndex2 = -1;
        videoCompVCfromThumb = nil;
        editVideoVCfromThumb = nil;
	}
	
	return (self);				
}

// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName isSexMen:(BOOL)isMen
{
	lblUserName.text = userName;
    lblUserName.textColor = [Common getNameColorWithSex:isMen];
}
// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName nameColor:(UIColor*)color
{
	lblUserName.text = userName;
    lblUserName.textColor = color;
}


// 施術日の設定：設定により表示される
- (void)setWorkDateWithString:(NSString*)workDate
{
	lblWorkDate.text = workDate;
	
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

#pragma mark- 動画の設定
#define LS_SINGLE_VIDEO_HEIGHT   620.0f   // DELC SASAGE edit 01/12
#define LS_DOUBLE_VIDEO_WIDTH    456.0f
//動画のリストの設定。MovieResourceのリスト
- (void)setMovieItems:(NSMutableArray*)_movies
{
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
	if (movies != nil)
	{
		[movies removeAllObjects];
	}
	else 
	{
		movies = [ [NSMutableArray alloc] init];
	}
    if (errorTags != nil) {
        [errorTags removeAllObjects];
    } else {
        errorTags = [[NSMutableArray alloc] init];
    }

	for (id item in _movies)
	{
		[movies addObject:item];
	}
    
	// 選択画像情報クリア
	_selectedCount = 0;
	_selectedImageIndex1 = -1;
	_selectedImageIndex2 = -1;
    [self makeScrDrawView];
}

// ScrollViewと描画Viewの作成
// HistDetailViewー＞setmoviesー＞makeScrDrawViewの流れで呼ばれて、画像をスクロールビューに貼付ける
// 但し、レイアウトは行わず、全てDLされた後に行われる。
- (void) makeScrDrawView
{
	// 画面サイズの取得
	UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
	CGFloat scrWidth
    = (screen.applicationFrame.size.width == 320.0f)? 320.0f : 460.0f;
	CGFloat scrHeigth
    = (screen.applicationFrame.size.height == 460.0f)? 460.0f : 300.0f;
#else
	CGFloat scrWidth
    = (screen.applicationFrame.size.width == 768.0f)? 768.0f : 1024.0f;
	CGFloat scrHeigth
    = (screen.applicationFrame.size.height == 1004.0f)? 1004.0f : 748.0f;
#endif
	
	// scroll viewの作成
	if (! _scrollView)
	{
        // 上部のタイトル表示高さ
#ifdef CALULU_IPHONE
        CGFloat yOfs = 30.0f;
#else
        CGFloat yOfs = 44.0f;
#endif
		// scroll viewを下方向に44pixel下げて、タイトル表示を確保
		_scrollView = [[UIScrollView alloc]
                       initWithFrame:CGRectMake(0.0f, yOfs, scrWidth, (scrHeigth - yOfs))];
		// 本（base）viewにスクロールビューを追加
		[self.view addSubview:_scrollView];
	}
	else {
		/*
         _scrollView .frame
         = CGRectMake(0.0f, 0.0f, scrWidth, (scrHeigth -44.0f));
         */
		[_scrollView setZoomScale:1.0f];
	}
    
	// 描画Viewの作成 : 高さは横向きでの値（自動伸縮しないので仮の値）
	if(! _drawView)
	{
		_drawView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, scrWidth, 704.0f)];
		// スクロールビューに対象viewを追加
		[_scrollView addSubview:_drawView];
	}
	else {
		// _drawView.frame = CGRectMake(0.0f, 0.0f, scrWidth, 704.0f);
		
		// 一旦、subViewとなるImageViewを全て削除する
		for ( id vw in _drawView.subviews)
		{
			[((UIView*)vw) removeFromSuperview];
			// vw = nil;
		}
	}
	
	// スクロール範囲の設定（これがないとスクロールしない）
	[_scrollView setContentSize:_drawView.frame.size];
	
	// ピンチ（ズーム）機能の追加:delegate指定
	[_scrollView setDelegate:self];
	
	// スクロールビューの拡大と縮小の範囲設定（これがないとズームしない）
	[_scrollView setMinimumZoomScale:1.0];
	[_scrollView setMaximumZoomScale:1.0];		// 10.0 -> 1.0:ズーム機能をなくす
	
	// 画像Itemを描画Viewに加える
    for (int i = 0; i < movies.count; i++) {
		// ImageViewの作成
        //		OKDClickImageView *imgView
        //        = [[[OKDClickImageView alloc]
        //            init:[self pictImage:i]
        //            selectedNumber: i + 1
        //            ownerView:self] autorelease];
        ClickVideoView *videoView = [[[ClickVideoView alloc] init:movies[i] selectedNumber:i + 1] autorelease];
		videoView.delegate = self;
		videoView.tag = i;
        videoView.hidden = YES;
		
		// レイアウトはpictImagesLayoutで行う
		[_drawView addSubview:videoView];
    }
    // ダウンロード中に一時的にレイアウトが崩れるのを防ぐため、あとでまとめて表示
    for (UIView *subv in _drawView.subviews) {
        if ([subv isKindOfClass:[ClickVideoView class]]){
            subv.hidden = NO;
        }
    }
	// 全画面表示Viewの作成
	if (! _fullView)
	{
		_fullView = [[OKDFullScreenImageView alloc]
					 initWithFrame:CGRectMake(0.0f, 0.0f, scrWidth, 704.0f)];
		// 背景色を渡す
		[_fullView setBackgroundColor:self.view.backgroundColor];
		
		[self.view addSubview:_fullView];
	}
	else {
		// _fullView.frame = CGRectMake(0.0f, 0.0f, scrWidth, 704.0f)];
	}
    
	
}

// 画像Itemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
- (void) pictImagesLayout:(BOOL)isPortrait
{
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
	// 画面が縦向き(portrait)かを横サイズより設定
	// UIScreen *screen = [UIScreen mainScreen];
	// BOOL isPortrait= (screen.applicationFrame.size.width == 768.0f);
	
	NSUInteger	wn, hn;			// 横、縦の個数
	CGFloat		ws, hs;			// 横、縦のサイズ
	CGFloat		wm, hm;			// 横、縦のマージン
	
	// 画像Imageリストの個数により画像の数、サイズなどを設定
	NSUInteger imgConunt = [movies count];
	switch (imgConunt) 
	{
		case 0:
		// 念のため
			wn = hn = 0;
			return;
			// break;

		case 1:
			wn = 1;
			// if ([Common isImagePortrait:[movies objectAtIndex:0]] )
			{
#ifdef CALULU_IPHONE
				ws = (isPortrait)? VIEW_WIDTH : 352.0f;
				hs = (isPortrait)? VIEW_HEIGHT : 264.0f;
#else
//				ws = (isPortrait)? VIEW_WIDTH : 939.0f;
//				hs = (isPortrait)? VIEW_HEIGHT : 704.0f;
				ws = (isPortrait)? VIEW_WIDTH : 728.0f;
				hs = (isPortrait)? VIEW_HEIGHT : 546.0f;
#endif
			}
			/*else 
			{
				ws = (isPortrait)? 728.0f : 939.0f;
				hs = (isPortrait)? 546.0f : 704.0f;
			}*/

			break;
		case 2:
			wn = (isPortrait)? 1 : 2;
#ifdef CALULU_IPHONE
			ws = (isPortrait)? 272.0f : 232.0f;
			hs = (isPortrait)? 204.0f : 174.0f;
#else
			ws = (isPortrait)? 535.0f : 448.0f;
			hs = (isPortrait)? 400.0f : 336.0f;
#endif
			break;
		case 3:
		case 4:
			wn = (isPortrait)? 2 : 2;
#ifdef CALULU_IPHONE
			ws = (isPortrait)? 156.0f : 176.0f;
			hs = (isPortrait)? 117.0f : 132.0f;
#else
            ws = (isPortrait)? 360.0f : 420.0f;
            hs = (isPortrait)? 270.0f : 316.0f;
#endif
			break;
		case 5:
		case 6:
		default:
			// 6個以上は同様
			if (isPortrait)
			{ wn = 2;}
			else 
			{ hn = 2;}

#ifdef CALULU_IPHONE
			ws = (isPortrait)? 156.0f : 152.0f;
			hs = (isPortrait)? 117.0f : 114.0f;
#else
			ws = (isPortrait)? 360.0f : 320.0f;
			hs = (isPortrait)? 270.0f : 240.0f;
#endif            
			break;
	}
	
	// 縦の個数を算出
	if ( (!isPortrait) && (imgConunt > 4) )
	{
		wn = ((imgConunt % hn) == 0)? (imgConunt / hn) : (imgConunt /hn ) + 1;
	}
	else 
	{
		hn = ((imgConunt % wn) == 0)? (imgConunt / wn) : (imgConunt /wn ) + 1;
	}
	
    // 上部のタイトル表示高さ
#ifdef CALULU_IPHONE
    CGFloat yOfs = 30.0f;
#else
    CGFloat yOfs = 20.0f;
#endif
    
	// マージンは画面と個数により等分割とする
#ifdef CALULU_IPHONE
	CGFloat scrWidth  = (isPortrait)? 320.0f : 480.0f;
	CGFloat scrHeight = (isPortrait)? 460.0f : 300.0f;
#else
    CGFloat scrWidth  = (isPortrait)?  768.0f : 1024.0f;
	CGFloat scrHeight = (isPortrait)? 1004.0f :  748.0f;
#endif
    scrHeight -= yOfs;		// タイトル表示高さ
	NSUInteger wn2, hn2;
	if (isPortrait)
	{
		wn2 = (wn <= 2)? wn : 2;
		hn2 = (hn <= 3)? hn : 3;
	}
	else 
	{
		wn2 = (wn <= 3)? wn : 3;
		hn2 = (hn <= 2)? hn : 2;		
	}

	wm = ( scrWidth	 - (ws * wn2)) / ((CGFloat)(wn2 + 1));
	hm = ( scrHeight - (hs * hn2)) / ((CGFloat)(hn2 + 1));
	
	CGFloat sW;
	CGFloat sH;
	// 描画ViewとScrollViewもリサイズする
	if (isPortrait)
	{
#ifdef CALULU_IPHONE
		sW = 320.0f;
#else
		sW = 768.0f - viewFunction.frame.size.width;
#endif
		// 縦の場合は高さを調節
		sH = ( (hs * hn) + (hm * (hn + 1) ));
	}
	else 
	{
		// 横の場合は幅を調節
		sW = ( (ws * wn) + (wm * (wn + 1) ) - viewFunction.frame.size.width );
#ifdef CALULU_IPHONE        
		sH = 320.0f - yOfs;
#else
		sH = 748.0f - yOfs;
#endif
	}
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = 0;
    // iOS7かつNavigationCallでの画面遷移の場合
    if (iOSVersion>=7.0f && _isNavigationCall) {
        uiOffset = 20.f;
    }
    
	// [_btnPrevView setFrame:CGRectMake(0.0f, 0.0f, sW, sH)];
//    [_drawView setFrame:CGRectMake(0.0f, 0.0f, sW, sH)];
//    [_scrollView setFrame:CGRectMake(0.0f, yOfs + uiOffset, scrWidth, scrHeight)];
//    // if ( (wn != wn2) || (hn != hn2) )
//    {
//        [_scrollView setContentSize:_drawView.frame.size];
//    }
    
    [_drawView setFrame:CGRectMake(0.0f, 0.0f, sW, sH)];
    if (isPortrait && (imgConunt == 1)) {
        [_scrollView setFrame:CGRectMake(40.0f, yOfs + uiOffset, scrWidth - 60, scrHeight)];
    } else if (isPortrait && (imgConunt > 2)) {
        [_scrollView setFrame:CGRectMake(45.0f, yOfs + uiOffset, scrWidth - 40, scrHeight)];
    } else {
        if (imgConunt > 4) {
            [_scrollView setFrame:CGRectMake(45.0f, yOfs + uiOffset, scrWidth - 60, scrHeight)];
        } else {
            [_scrollView setFrame:CGRectMake(10.0f, yOfs + uiOffset, scrWidth - 60, scrHeight)];
        }
    }
    
    [_scrollView setContentSize:_drawView.frame.size];
    
	// 描画viewの子View(= OKDClickImageView)の位置設定
	NSArray *childViews = _drawView.subviews;
	NSUInteger count = [childViews count];
	if (isPortrait)
	{
		for (NSUInteger x = 0; x < wn; x++) 
		{
			for (NSInteger y = 0; y < hn; y++) 
			{
				NSUInteger idx = y + (x * hn);
				
				if (idx >=count)
				{ break; }
				
				ClickVideoView *videoView = (ClickVideoView *)childViews[idx];
                
//                // x位置：横マージン＋（横マージン＋横サイズ）× x
//                CGFloat xp = wm + (wm + ws) * (CGFloat)x;
//                // y位置：縦マージン＋（縦マージン＋縦サイズ）× y
//                CGFloat yp = hm + (hm + hs) * (CGFloat)y;
//                // [imgView setFrame:CGRectMake(xp, yp, ws, hs)];
//                [videoView setSize:CGRectMake(xp, yp, ws, hs + 30)]; //スライダーの分 +30
                
                // x位置：横マージン＋（横マージン＋横サイズ）× x
                CGFloat xp = wm + (wm + ws) * (CGFloat)x;
                // y位置：縦マージン＋（縦マージン＋縦サイズ）× y
                CGFloat yp = hm + (hm + hs) * (CGFloat)y;
                // [imgView setFrame:CGRectMake(xp, yp, ws, hs)];
                if (isPortrait && (imgConunt > 2)) {
                    [videoView setSize:CGRectMake(xp, yp, 320, 240)];
                } else {
                    [videoView setSize:CGRectMake(xp, yp, ws, hs)];
                }
                
#ifndef CALULU_IPHONE
				// 横向きで１枚のみ表示の場合は選択番号を非表示にしていたのを表示する
				if (imgConunt == 1)
				{	[videoView setSelectNumberHidden:NO]; }
#endif
			}
		}
	}
	else 
	{
		for (NSInteger y = 0; y < hn; y++) 
		{
			for (NSUInteger x = 0; x < wn; x++) 
			{
				NSUInteger idx = x + (y * wn);
			
				if (idx >=count)
				{ break; }
                
				ClickVideoView *videoView = (ClickVideoView *)childViews[idx];
			
//                // x位置：横マージン＋（横マージン＋横サイズ）× x
//                CGFloat xp = wm + (wm + ws) * (CGFloat)x;
//                // y位置：縦マージン＋（縦マージン＋縦サイズ）× y
//                CGFloat yp = hm + (hm + hs) * (CGFloat)y;
//                // [imgView setFrame:CGRectMake(xp, yp, ws, hs)];
//                [videoView setSize:CGRectMake(xp, yp, ws, hs + 30)]; //スライダーの分 +30
                
                // x位置：横マージン＋（横マージン＋横サイズ）× x
                CGFloat xp = wm + (wm + ws) * (CGFloat)x;
                // y位置：縦マージン＋（縦マージン＋縦サイズ）× y
                CGFloat yp = hm + (hm + hs) * (CGFloat)y;
                // [imgView setFrame:CGRectMake(xp, yp, ws, hs)];
                [videoView setSize:CGRectMake(xp, yp, ws, hs)];
				
				// 横向きで１枚のみ表示の場合は選択番号を非表示にする
//                if (imgConunt == 1)
//                {
//                    [videoView setSelectNumberHidden:YES];
//                    videoView.center = CGPointMake(148 + (728 / 2), 30 + (546 / 2) + uiOffset);
//                }
			}
		}
	}
}
#pragma mark - 各種コントロールの設定
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

// 透過・重ね合わせボタンの有効／無効設定
- (void) setAbreastOverlapButonEnable:(BOOL)isEnable
{
    btnAbreast.enabled = isEnable;
    btnOverlap.enabled = isEnable;
    btnUpdown.enabled = isEnable;
    
	if (isEnable)
	{
		if (btnAbreast.tag == 1)
        {
            [btnAbreast setBackgroundImage: [UIImage imageNamed:@"compareIcon_selected.png"]
                                  forState:UIControlStateNormal];
            [btnOverlap setBackgroundImage: [UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                                  forState:UIControlStateNormal];
            [btnUpdown setBackgroundImage: [UIImage imageNamed:@"updownIcon_unselected.png"]
                                 forState:UIControlStateNormal];
        }
        else if (btnOverlap.tag == 1)
        {
            [btnAbreast setBackgroundImage: [UIImage imageNamed:@"compareIcon_unselected.png"]
                                  forState:UIControlStateNormal];
            [btnOverlap setBackgroundImage: [UIImage imageNamed:@"tranmissionIcon_selected.png"]
                                  forState:UIControlStateNormal];
            [btnUpdown setBackgroundImage: [UIImage imageNamed:@"updownIcon_unselected.png"]
                                 forState:UIControlStateNormal];
        }else if (btnUpdown.tag == 1)
        {
            [btnUpdown setBackgroundImage:[UIImage imageNamed:@"updownIcon_selected.png"]
                                 forState:UIControlStateNormal];
            
            [btnAbreast setBackgroundImage: [UIImage imageNamed:@"compareIcon_unselected.png"]
                                  forState:UIControlStateNormal];
            [btnOverlap setBackgroundImage: [UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                                  forState:UIControlStateNormal];
        }
	}
	else 
	{
		[btnAbreast setBackgroundImage: [UIImage imageNamed:@"compareIcon_unselected.png"]
                              forState:UIControlStateNormal];
        [btnOverlap setBackgroundImage: [UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                              forState:UIControlStateNormal];
        [btnUpdown setBackgroundImage: [UIImage imageNamed:@"updownIcon_unselected.png"]
                             forState:UIControlStateNormal];
	}
    
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
        /*btnAbreast.frame = CGRectMake(5.0f,  76.0f, 38.0f, 38.0f);
        btnOverlap.frame = CGRectMake(5.0f, 115.0f, 38.0f, 38.0f);*/
    }
    // 横表示：タイトルとボタン１段表示
    else
    {
        // 施術日：横サイズを大きくして「施術日」のDimを表示
        viewWorkDateBack.frame = CGRectMake(125.0f,  4.0f, 175.0f, 24.0f);
        btnOverlayCamera.frame = CGRectMake(  5.0f,  4.0f,  38.0f, 38.0f);
        btnHardCopyPrint.frame = CGRectMake( 48.0f,  4.0f,  38.0f, 38.0f);
        // 重ね合わせと透過ボタン：横並び
        /*btnAbreast.frame = CGRectMake( 5.0f, 44.0f, 38.0f, 38.0f);
        btnOverlap.frame = CGRectMake(48.0f, 44.0f, 38.0f, 38.0f);*/
    }
}

#endif

#pragma mark - control_events

// カメラ画面へ戻る
- (IBAction)OnCameraView
{
	// 現時点で最上位のViewController(=self)を削除する
	_isBackCameraView = YES;
    [ [self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

// 画像ファイル選択
- (IBAction)OnSelectPictView
{

    // 現時点で最上位のViewController(=self)を削除する
	_isBackCameraView = NO;
	
	if (! self.isNavigationCall)
	{
		// [ [self parentViewController] dismissModalViewControllerAnimated:YES];
	}
	else
	{
		[self.navigationController popViewControllerAnimated:YES];
        // サムネイル画面に戻る時に、editVideo または videoComp が残っていた場合に解除する
        if (editVideoVCfromThumb) {
            [editVideoVCfromThumb.view removeFromSuperview];
            [editVideoVCfromThumb release];
            editVideoVCfromThumb = nil;
        }
        if (videoCompVCfromThumb) {
            [videoCompVCfromThumb.view removeFromSuperview];
            [videoCompVCfromThumb release];
            videoCompVCfromThumb = nil;
        }
	}
}

// 重ね合わせカメラ
- (IBAction)OnOverlayCamera
{
	// MainViewControllerの取得
	MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// camaraViewControllerの取得
	camaraViewController *cameraView
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView;
	
	if (!cameraView)
	{
		cameraView = [[camaraViewController alloc]
#ifdef CALULU_IPHONE
                      initWithNibName:@"ip_camaraViewController" bundle:nil];
#else
    initWithNibName:@"camaraViewController" bundle:nil];
#endif
		((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView
        = cameraView;
	}
    
	// 取得した履歴IDと施術日を渡す
	cameraView.histID = [self getValidHistID];
	cameraView.workDate = _workDate;
	
	// カメラ画面の表示
	if (! self.isNavigationCall)
	{
		[mainVC showPopupWindow:cameraView];
	}
	else
	{
		[self.navigationController pushViewController:cameraView animated:YES];
		cameraView.isNavigationCall = YES;
	}
	
	// 現在選択中のユーザIDを渡す
	[cameraView setSelectedUser:_userID
					   userName:lblUserName.text
					  nameColor:lblUserName.textColor];
	
	// 重ね合わせの画像を渡す
	UIImage *image = ([movies count ] > 0)?
    [self pictImage: _selectedImageIndex1] : nil;
    if(Ovimage != nil) [Ovimage release];
    Ovimage = [[UIImage alloc]initWithCGImage:image.CGImage];
	[cameraView setOverlayImage:Ovimage];
	
	// 現在のデバイスの向きを取得
	UIInterfaceOrientation orient = [mainVC getNowDeviceOrientation];
	// デバイスの向きを設定する
	[cameraView willRotateToInterfaceOrientation:orient duration:(NSTimeInterval)0];
	
	// 遷移画面の設定:カメラ画面
	_windowView = WIN_VIEW_CAMERA;
    
    [Ovimage release];
    [cameraView release];
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
    // facebook機能が利用できるかをSocial Frameworkが使えるかで判断する
    BOOL isFb = (NSClassFromString(@"SLComposeViewController"));
    if (!isFb)
    {
        [Common showDialogWithTitle:@"facebook投稿について"
                            message:@"お使いのiPadでは\nご利用いただけません\n\n(最新のiOSにアップデート\nするとご利用になれます)"];
        return;
    }
    
    
    // 選択中の画像を取得
    UIImage *image = ([movies count ] > 0)?
    [self pictImage: _selectedImageIndex1] : nil;
    
    // タイトルの生成
    NSMutableString *title = [NSMutableString string];
    [title appendFormat:@"%@　", lblWorkDate.text];
    [title appendFormat:@"%@様の写真です。", lblUserName.text];
    
    SLComposeViewController *facebookPostVC
    = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [facebookPostVC setInitialText:title];
    [facebookPostVC addImage:image];
    [self presentViewController:facebookPostVC animated:YES completion:nil];
    
    // 処理終了後のコールバック
    [facebookPostVC setCompletionHandler:^(SLComposeViewControllerResult result)
     {
         NSString *msg = nil;
         switch (result) {
             case SLComposeViewControllerResultDone:
                 msg =@"投稿しました";
                 break;
             case SLComposeViewControllerResultCancelled:
                 msg = @"投稿をキャンセルしました";
                 break;
             default:
                 break;
         }
         
         if (msg)
         {
             [Common showDialogWithTitle:@"facebookへの投稿" message:msg];
         }
     }];
    
    
}

- (IBAction)OnBtnSynthesisModeChange:(id)sender{
    UIButton* selectBtn = sender;
    if (selectBtn == btnAbreast) {
        btnAbreast.tag = 1;
        [btnAbreast setBackgroundImage:[UIImage imageNamed:@"compareIcon_selected.png"]
                              forState:UIControlStateNormal];
        
        btnOverlap.tag = 0;
        [btnOverlap setBackgroundImage:[UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                              forState:UIControlStateNormal];
        btnUpdown.tag = 0;
        [btnUpdown setBackgroundImage:[UIImage imageNamed:@"updownIcon_unselected.png"]
                             forState:UIControlStateNormal];
    }else if(selectBtn == btnOverlap){
        btnAbreast.tag = 0;
        [btnAbreast setBackgroundImage:[UIImage imageNamed:@"compareIcon_unselected.png"]
                              forState:UIControlStateNormal];
        
        btnOverlap.tag = 1;
        [btnOverlap setBackgroundImage:[UIImage imageNamed:@"tranmissionIcon_selected.png"]
                              forState:UIControlStateNormal];
        btnUpdown.tag = 0;
        [btnUpdown setBackgroundImage:[UIImage imageNamed:@"updownIcon_unselected.png"]
                             forState:UIControlStateNormal];
    }else if(selectBtn == btnUpdown){
        btnAbreast.tag = 0;
        [btnAbreast setBackgroundImage:[UIImage imageNamed:@"compareIcon_unselected.png"]
                              forState:UIControlStateNormal];
        
        btnOverlap.tag = 0;
        [btnOverlap setBackgroundImage:[UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                              forState:UIControlStateNormal];
        btnUpdown.tag = 1;
        [btnUpdown setBackgroundImage:[UIImage imageNamed:@"updownIcon_selected.png"]
                             forState:UIControlStateNormal];
    }
}

#pragma mark- life_cycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    viewFunction.layer.cornerRadius = 10;
    viewFunction.clipsToBounds = true;
    
    // 背景色の変更 RGB:D8BFD8
//    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:204/255.0f green:149/255.0f blue:187/255.0f alpha:1.0f];
    
    // ロックモードの初期設定
//	_isModeLock = NO;
	
	// 背景Viewの角を丸くする
	[self setCornerRadius:viewUserNameBack];
	[self setCornerRadius:viewWorkDateBack];
	
	// NavigationCallによる画面遷移の場合はスワイプをセットアップする
	if (self.isNavigationCall)
	{	[self setupSwipSupport]; }
	
	_isPicturePaintDisplaied = NO;
	_selectedCount = 0;
	_selectedImageIndex1 = -1;
	_selectedImageIndex2 = -1;
	
	// 印刷の設定確認
	// [self priterSetting];
	
	// 遷移画面の初期化:選択画像一覧画面
	_windowView = WIN_VIEW_SELECT_VIDEO;
	
	// 画面ロックモードを確認する
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	if ([mainVC isWindowLockState])
	{	[self OnWindowLockModeChange:YES]; }
    
    // ２枚選択時の初期は画像重ね合わせ
    btnAbreast.tag = 1;
    btnOverlap.tag = 0;
    btnUpdown.tag = 0;
    
#ifndef AIKI_CUSTOM
    // facebookの利用が可能なアカウントで有るかを確認する
    //[self setFacebookEnableIsFlag:[AccountManager isAccountCanUseFacebook]];
#endif
    // mailの利用が可能かを確認する
    //[self setMailEnableIsFlag:[AccountManager isLogined]];

    // facebook機能はiOS6以上で対応 : ボタンのタップでアナウンスする
//  NSString *systemVersion = [UIDevice currentDevice].systemVersion;
//  if([[systemVersion substringToIndex:1] intValue] < 6) {
//      // facebookのボタンを非表示にして動作（/Social.frameworkのロード）しようにする
//      btnFacebookUp.hidden = YES;
    // }

    Ovimage = nil;
    
    //[SVProgressHUD showWithStatus:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
}

// 画面が表示される都度callされる:viewWillAppear
- (void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	[super viewWillAppear : animated];
	
	// カメラ画面からの遷移の場合
	if ( _windowView == WIN_VIEW_CAMERA)
	{
		// 遷移元のVCに対して更新処理を行う
		[self refresh2OwnerTransitionVC];
		
		// 遷移画面を元に戻しておく:選択画像一覧画面
		_windowView = WIN_VIEW_SELECT_VIDEO;
		
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
	[self pictImagesLayout : isPortrait];
	
	// 全画面表示viewの更新
	[_fullView refresh : isPortrait];
    
    [self uiLayout:isPortrait];
	
	// 印刷ボタンと重ね合わせカメラボタンを最前面にする
	if (! btnHardCopyPrint.hidden)
	{	[self.view bringSubviewToFront:btnHardCopyPrint]; }
//    [self.view bringSubviewToFront:btnOverlayCamera];
//    [self.view bringSubviewToFront:btnFacebookUp];      // facebook投稿ボタンも最前面にする
//    [self.view bringSubviewToFront:btnMailSend];
    
    // 2012 7/13 写真を重ねて表示
//    if ([movies count] >= 2) {
////        [self.view bringSubviewToFront:btnAbreast];
////        [self.view bringSubviewToFront:btnOverlap];
////        [self.view bringSubviewToFront:btnUpdown];
//        // [self OnBtnSynthesisModeChange:btnAbreast];
//        /*btnAbreast.tag = 1;
//        btnOverlap.tag = 0;*/
//        btnAbreast.hidden = NO;
//        btnOverlap.hidden = NO;
//        btnUpdown.hidden = NO;
//    }else {
//        btnAbreast.hidden = YES;
//        btnOverlap.hidden = YES;
//        btnUpdown.hidden = YES;
//    }
    
    [self.view bringSubviewToFront:viewFunction];
	
	// 重ね合わせカメラの初期状態は無効
	[self setOverlayCameraButonEnable: (_selectedCount == 1)];
    
    // facebook投稿ボタンの初期状態は無効
    // [self setFacebookUpButonEnable: (_selectedCount == 1)];
    
    // 透過・重ね合わせボタンの初期状態は無効
    [self setAbreastOverlapButonEnable:(_selectedCount == 2)];
}	

// 画面が表示される都度callされる:viewDidAppear
- (void)viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	[super viewDidAppear : animated];
	
    // VideoCompView or EditVideoViewから戻ってきた場合に処理を行う
    // 素早くスワイプさせた場合に、viewDidAppearが呼ばれない場合が有るので
    // ここで deleteViewControllersFromNextIndex を呼ぶことをやめた
//	if ((_windowView == WIN_VIEW_EDIT_VIDEO) || (_windowView == WIN_VIEW_COMP_VIDEO)) {
//        MainViewController *mainVC
//        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
//        [mainVC deleteViewControllersFromNextIndex];
//    }
	ClickVideoView* videoView = nil;
	
	if (_selectedImageIndex1 >= 0)
	{
		videoView = [self getClickVideoViewByTag:_selectedImageIndex1];
		if (videoView)
		{
			[videoView setSelected:YES frameColor:[UIColor blueColor]];
		}
	}
	if (_selectedImageIndex2 >= 0)
	{
		videoView = [self getClickVideoViewByTag:_selectedImageIndex2];
		if (videoView)
		{
			[videoView setSelected:YES frameColor:[UIColor redColor]];
		}
	}
    // 色選択ボタンの初期化
    UIButton* btn = [[UIButton alloc] init];
    btn.tag = PALLET_DRAW_COLOR+1;
    [btn release];
    
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

// ボタン類の位置調整
- (void)uiLayout:(BOOL)isPortrait
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    // iOS7かつNavigationCallでの画面遷移の場合
    float uiOffset = ((iOSVersion<7.0f || !_isNavigationCall))? 0.0f : 20.0f;
    
    // ユーザ名
    [viewUserNameBack setFrame: (isPortrait)?
     CGRectMake(461.0f, 12.0f + uiOffset, 287.0f, 30.0f) :
     CGRectMake(461.0f + 256.0f, 12.0f + uiOffset, 287.0f, 30.0f) ];
    
    // 施術日
    [viewWorkDateBack setFrame: (isPortrait)?
     CGRectMake(124.0f, 12.0f + uiOffset, 310.0f, 30.0f) :
     CGRectMake(124.0f + 256.0f, 12.0f + uiOffset, 310.0f, 30.0f) ];
    
    // Lockボタン
//    [btnLockMode setFrame: (isPortrait)?
//     CGRectMake(8.0f, 0.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(8.0f, 0.0f + uiOffset, 54.0f, 54.0f) ];

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
    
    // 突き合わせ
//    [btnAbreast setFrame: (isPortrait)?
//     CGRectMake(8.0f, 74.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(8.0f, 74.0f + uiOffset, 54.0f, 54.0f) ];
//    
//    // 透過
//    [btnOverlap setFrame: (isPortrait)?
//     CGRectMake(64.0f, 74.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(64.0f, 74.0f + uiOffset, 54.0f, 54.0f) ];
//    
//    // 上下
//    [btnUpdown setFrame: (isPortrait)?
//     CGRectMake(8.0f, 136.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(8.0f, 136.0f + uiOffset, 54.0f, 54.0f) ];
    
    // Facebook投稿
//    [btnFacebookUp setFrame: (isPortrait)?
//     CGRectMake(67.0f, 12.0f + uiOffset, 48.0f, 48.0f) :
//     CGRectMake(67.0f, 12.0f + uiOffset, 48.0f, 48.0f) ];
}

// 縦横切り替え後のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    orientationAtWillRotate = toInterfaceOrientation; // didRotate時に使うため保存
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
    
    if(_isNavigationCall)   [self uiLayout:!isPortrait];
    else                    [self uiLayout:isPortrait];
	
	// 画像Itemのレイアウト
	if ((_drawView) && (_scrollView) )
	{
		[self pictImagesLayout : isPortrait];
	}
	
	// 全画面表示viewの更新
	if (_fullView)
	{
		[_fullView refresh : isPortrait];
	}
#ifdef CALULU_IPHONE
    // タイトル、ボタンの位置調整
    [self _titelButtonLayout:isPortrait];
#endif
    //
    // サムネイル一覧からの遷移の場合はサブビューであるVideoCompViewに伝える必要
    if (self.isFlickEnable && videoCompVCfromThumb && (videoCompVCfromThumb.view.frame.origin.x == 0)) {
        videoCompVCfromThumb.view.frame = self.view.frame;
        [videoCompVCfromThumb willRotateToInterfaceOrientation:toInterfaceOrientation
                                                      duration:0];
        //[videoCompVCfromThumb didRotateFromInterfaceOrientation:[self getNowDeviceOrientation]];
    }
    if (self.isFlickEnable && editVideoVCfromThumb && (editVideoVCfromThumb.view.frame.origin.x == 0)) {
        editVideoVCfromThumb.view.frame = self.view.frame;
        // 毎回設定しないと初期値に戻る？
        editVideoVCfromThumb.isNavigationCall = self.isNavigationCall;
        [editVideoVCfromThumb willRotateToInterfaceOrientation:toInterfaceOrientation
                                                      duration:0];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

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
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
	[movies release];
    
    [lblUserName release];
    [lblWorkDate release];
    [lblWorkDateTitle release];
    [viewUserNameBack release];
    [viewWorkDateBack release];
    [btnAbreast release];
    [btnFacebookUp release];
    [btnHardCopyPrint release];
    [btnMailSend release];
    [btnOverlap release];
    [btnOverlayCamera release];
    [btnUpdown release];

	[_fullView release];
	[_scrollView release];
	
	[_workDate release];
    if(Ovimage!=nil)[Ovimage release];
	for (ClickVideoView *videoView in _drawView.subviews)
	{
        [videoView removeFromSuperview];
	}
    [_drawView release];
    [viewFunction release];
	[super dealloc];
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
#pragma mark - MainViewControllerDelegate

// 新規View画面への遷移
//		return: 次に表示する画面のViewController  nilで遷移をキャンセル
// TransitionControllによる画面遷移の場合はこちらを通る
// サムネイルviewからの遷移の場合は OnSwipeLeftView / OnSwipeRightView を通る
- (UIViewController*) OnTransitionNewView:(id)sender
{
#ifdef DEBUG
	NSLog(@"OnTransitionNewView at SelectVideoViewController");
#endif
    // 読み込み失敗画像が選択されている場合、次の画面に遷移しない
    if ([self checkReadError:(_selectedCount==1)]) {
        [self pageMoveAlert];
        return nil;
    }
	
	MainViewController* mainVC = (MainViewController*)sender;
	
	// 画面ロック状態であれば、次に遷移しない:_selectedCount <= 0 と同様
	if ([mainVC isWindowLockState] )
	{	return (nil); }
	
	if (_selectedCount >= 2)
	{
		[mainVC skipNextPage:NO];
        VideoCompViewController  *videoCompVC
        = [[VideoCompViewController alloc]
           initWithNibName:@"VideoCompViewController" bundle:nil];
        return (videoCompVC);
	}
	else if (_selectedCount == 1)
	{
		[mainVC skipNextPage:NO];
        EditVideoViewController  *editVideoVC
        = [[EditVideoViewController alloc]
           initWithNibName:@"EditVideoViewController" bundle:nil];
        return (editVideoVC);
	}
	else
	{
		// 遷移をキャンセル
		return (nil);
	}
}

// 新規View画面への遷移でViewがLoadされた後にコールされる
- (void) OnTransitionNewViewDidLoad:(id)sender transitionVC:(UIViewController*)tVC
{
    if ([tVC isKindOfClass:[VideoCompViewController class]]) {
        VideoCompViewController *videoCompVC = (VideoCompViewController*)tVC;
        if (_selectedCount >= 2)
        {
            [videoCompVC setSkip:NO];
            // 2012 7/13 写真の透過合成
            videoCompVC.IsOverlap = NO;
            videoCompVC.IsUpdown = NO;
            if (btnOverlap.tag == 1) {
                videoCompVC.IsOverlap = YES;
            }
            if (btnUpdown.tag == 1) {
                videoCompVC.IsUpdown = YES;
            }
            // 写真の初期化
            [videoCompVC initWithVideo:movies[_selectedImageIndex1]
                                 video:movies[_selectedImageIndex2]
                              userName:lblUserName.text
                             nameColor:lblUserName.textColor
                              workDate:lblWorkDate.text
                            isDrawMode:NO];
            _compVideoIndex1 = _selectedImageIndex1;
            _compVideoIndex2 = _selectedImageIndex2;
        }
        
        // 施術情報の設定
        [videoCompVC setWorkItemInfo:_userID workItemHistID:_histID];
        
        videoCompVC.IsSetLayout = TRUE;
        _windowView = WIN_VIEW_COMP_VIDEO;
	} else if ([tVC isKindOfClass:[EditVideoViewController class]]){
        
        EditVideoViewController *editVideoVC = (EditVideoViewController*)tVC;
        // 選択ユーザと施術日の設定
        [editVideoVC setSelectedUserName:lblUserName.text nameColor:lblUserName.textColor];
        [editVideoVC setWorkDateWithString:lblWorkDate.text];
        
        // 施術情報の設定（画像合成ビューで必要）
        [editVideoVC setWorkItemInfo:_userID
                        workItemHistID:_histID
                              workDate:self.workDate];
        // 遅延して選択動画を表示する
        [self performSelector:@selector(transitionVideoView:)
                   withObject:editVideoVC afterDelay:0.05f];		// 0.05秒後に起動
        _windowView = WIN_VIEW_EDIT_VIDEO;
    }
	//_isPicturePaintDisplaied = YES;
}

// 既存View画面への遷移
// TransitionControllによる画面遷移の場合はこちらを通る
// サムネイルviewからの遷移の場合は OnSwipeLeftView / OnSwipeRightView を通る
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC
{
    // 読み込み失敗画像が選択されている場合、次の画面に遷移しない
    if ([self checkReadError:(_selectedCount==1)]) {
        [self pageMoveAlert];
        return nil;
    }

    if ([tVC isKindOfClass:[VideoCompViewController class]]) {
        // tovideocomp
        VideoCompViewController *videoCompVC = (VideoCompViewController*)tVC;
        MainViewController* mainVC = (MainViewController*)sender;
        
        if (_selectedCount >= 2)
        {
            [mainVC skipNextPage:NO];
            [videoCompVC setSkip:NO];
            if (btnAbreast.tag == 1){
                //突き合わせー＞透過
                [videoCompVC setZoom1:1.0f
                              offset1:CGPointZero
                             reverse1:NO
                                zoom2:1.0f
                              offset2:CGPointMake(364, 0)
                             reverse2:NO];
            } else if (btnOverlap.tag ==1){
                //透過ー＞突き合わせ
                [videoCompVC setZoom1:1.0f
                              offset1:CGPointMake(728, 546)
                             reverse1:NO
                                zoom2:1.0f
                              offset2:CGPointMake(728, 546)
                             reverse2:NO];
            } else if (btnUpdown.tag ==1){
                //上下比較
                [videoCompVC setZoom1:1.0f
                              offset1:CGPointMake(728, 0)
                             reverse1:NO
                                zoom2:1.0f
                              offset2:CGPointMake(728, 0)
                             reverse2:NO];
            }
            videoCompVC.IsOverlap = NO;
            videoCompVC.IsUpdown = NO;
            if (btnOverlap.tag == 1) {
                videoCompVC.IsOverlap = YES;
            }
            if (btnUpdown.tag == 1) {
                videoCompVC.IsUpdown = YES;
            }
            if ((_compVideoIndex1 != _selectedImageIndex1) || (_compVideoIndex2 != _selectedImageIndex2)) {
                // 既存の突き合わせ画面は消してしまう
                MainViewController *mainVC
                = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
                [mainVC deleteViewControllersFromNextIndex];
                // 動画の初期化
                VideoCompViewController  *videoCompVC
                = [[VideoCompViewController alloc]
                   initWithNibName:@"VideoCompViewController" bundle:nil];
                [videoCompVC setSkip:NO];
                // 2012 7/13 写真の透過合成
                videoCompVC.IsOverlap = NO;
                videoCompVC.IsUpdown = NO;
                if (btnOverlap.tag == 1) {
                    videoCompVC.IsOverlap = YES;
                }
                if (btnUpdown.tag == 1) {
                    videoCompVC.IsUpdown = YES;
                }
                // 写真の初期化
                [videoCompVC initWithVideo:movies[_selectedImageIndex1]
                                     video:movies[_selectedImageIndex2]
                                  userName:lblUserName.text
                                 nameColor:lblUserName.textColor
                                  workDate:lblWorkDate.text
                                isDrawMode:NO];
                _compVideoIndex1 = _selectedImageIndex1;
                _compVideoIndex2 = _selectedImageIndex2;
            }
            /*
             // 写真の初期化
             [videoCompVC initWithVideo:videoResources[0]
             video:videoResources[1]
             userName:lblUserName.text nameColor:lblUserName.textColor
             workDate:lblWorkDate.text];
             */
            videoCompVC.view.hidden = NO;
        }
        else
        {
            [mainVC skipNextPage:NO];
            [videoCompVC setSkip:NO];
            
            // 遷移をキャンセル
            return (NO);
        }
        
        // 施術情報の設定
        // [videoCompVC setWorkItemInfo:_userID workItemHistID:_histID];
        
        videoCompVC.IsSetLayout = TRUE;
    } else if([tVC isKindOfClass:[EditVideoViewController class]]){
        
        EditVideoViewController *editVideoVC = (EditVideoViewController*)tVC;
        // 選択ユーザと施術日の設定
        [editVideoVC setSelectedUserName:lblUserName.text nameColor:lblUserName.textColor];
        [editVideoVC setWorkDateWithString:lblWorkDate.text];
        
        // 施術情報の設定（画像合成ビューで必要）
        [editVideoVC setWorkItemInfo:_userID
                        workItemHistID:_histID
                              workDate:self.workDate];
    }
    
	return (YES);				// 画面遷移する
}
- (void) transitionVideoView:(EditVideoViewController*)editMovieVC
{
    // Indicatorの表示
    // [MainViewController showIndicator];
    [editMovieVC setMovie:movies[_selectedImageIndex1]];
    // Indicatorを閉じる
    // [MainViewController closeIndicator];
	// 履歴詳細画面からのコールでは、NavigationControlでは遷移しない
	editMovieVC.isNavigationCall = NO;
	// 遷移画面を動画一覧にする
	_windowView = WIN_VIEW_EDIT_VIDEO;
	[editMovieVC viewWillAppear:NO];
}


// 画面終了の通知
- (BOOL) OnUnloadView:(id)sender
{
	// 全画面表示viewを消去する
//0312	if (_fullView)
//0312	{	[_fullView hideFullScreenImageView]; }
    
    // 前画面に戻る前にsubViewとなるImageViewを全て削除する
    if (_drawView)
    {
        for ( UIView *vw in _drawView.subviews)
        {   [vw removeFromSuperview]; }
    }
	
	return (YES);		// 画面遷移する
}

// 画面ロックモード変更
- (void) OnWindowLockModeChange:(BOOL)isLock
{
	// 画面ロックにより、重ね合わせカメラボタンを非表示にする
	btnOverlayCamera.hidden = isLock;
	// 一旦、重ね合わせカメラボタンと透過・重ね合わせボタンを無効にする
	if (! isLock)
	{	
        [self setOverlayCameraButonEnable:NO]; 
        [self setAbreastOverlapButonEnable:NO];
        //[self setFacebookUpButonEnable:NO];         // facebook投稿ボタンも無効に
    }
	
	// 画面ロックにより、印刷ボタンを非表示にする(有効である場合のみ)
	if (btnHardCopyPrint.tag > 0)
	{	btnHardCopyPrint.hidden = isLock; }
	
	// 画面ロックにより、選択を解除する
	for (ClickVideoView *videoVw in _drawView.subviews)
	{	
		// imgVw.delegate = (! isLock)? self : nil; 
		if (isLock)
		{	[videoVw setSelected:NO frameColor:nil]; }
	}
	if (isLock)
	{
		_selectedImageIndex1 = _selectedImageIndex2 = -1;
		_selectedCount = 0;
	}
}
- (BOOL) OnCheckScrollPerformed:(id)sender touchView:(UIView*)view
{
    BOOL isPerformed = YES;
    //BOOL isPerformed = ! _isModeLock;
    
    // NSLog(@"%s touchPoint x=>%f y=>%f", __func__, pt.x, pt.y);
    
    // スライダーの場合は、スクロールをキャンセルする
    if ( [view isKindOfClass:[UISlider class]]) {
        isPerformed = NO;
    }
    return (isPerformed);
}
#pragma mark - 次の画面への遷移
// 動画描画画面
- (void)OnEditVideoView:(id)sender
{
    //tovideocomp
	MainViewController* mainVC = (MainViewController*)sender;
	
	// 画面ロック状態であれば、次に遷移しない:_selectedCount <= 0 と同様
	if ([mainVC isWindowLockState] )
	{	return; }
	
	if (_selectedCount == 1)
	{
		[mainVC skipNextPage:NO];
	}
	else {
        return;
    }
    if (editVideoVCfromThumb) {
        [editVideoVCfromThumb.view removeFromSuperview];
        [editVideoVCfromThumb release];
        editVideoVCfromThumb = nil;
    }
    if (videoCompVCfromThumb) {
        [videoCompVCfromThumb.view removeFromSuperview];
        [videoCompVCfromThumb release];
        videoCompVCfromThumb = nil;
    }
    
    editVideoVCfromThumb = [[EditVideoViewController alloc]
                            initWithNibName:@"EditVideoViewController" bundle:nil];
	editVideoVCfromThumb.isNavigationCall = YES;
    editVideoVCfromThumb.isFlickEnable = YES;
    
    [self.view addSubview:editVideoVCfromThumb.view];

    // 選択ユーザと施術日の設定
    [editVideoVCfromThumb setSelectedUserName:lblUserName.text nameColor:lblUserName.textColor];
    [editVideoVCfromThumb setWorkDateWithString:lblWorkDate.text];
    
    // 施術情報の設定（画像合成ビューで必要）
    [editVideoVCfromThumb setWorkItemInfo:_userID
                             workItemHistID:_histID
                                   workDate:self.workDate];
    // 遅延して選択動画を表示する
    [self performSelector:@selector(transitionVideoView:)
               withObject:editVideoVCfromThumb afterDelay:0.05f];		// 0.05秒後に起動
    
    CGRect vf = self.view.frame;//editVideoVCfromThumb.view.frame;
    editVideoVCfromThumb.view.frame = CGRectMake(vf.size.width, vf.origin.y, vf.size.width, vf.size.height);
    [editVideoVCfromThumb clearCanvas]; // 描画内容をクリア
    [UIView animateWithDuration:0.8 animations:^(void){
        editVideoVCfromThumb.view.frame = CGRectMake(0, vf.origin.y, vf.size.width, vf.size.height);
    }];
    _windowView = WIN_VIEW_EDIT_VIDEO;
}

// 動画合成画面へ遷移
- (void)OnVideoCompView:(id)sender
{
    //tovideocomp
	MainViewController* mainVC = (MainViewController*)sender;
	
	// 画面ロック状態であれば、次に遷移しない:_selectedCount <= 0 と同様
	if ([mainVC isWindowLockState] )
	{	return; }
	
	if (_selectedCount >= 2)
	{
		[mainVC skipNextPage:NO];
	}
	else {
        return;
    }
    
    if (editVideoVCfromThumb) {
        [editVideoVCfromThumb.view removeFromSuperview];
        [editVideoVCfromThumb release];
        editVideoVCfromThumb = nil;
    }
    if (videoCompVCfromThumb) {
        [videoCompVCfromThumb.view removeFromSuperview];
        [videoCompVCfromThumb release];
        videoCompVCfromThumb = nil;
    }
    
        videoCompVCfromThumb = [[VideoCompViewController alloc]
                                initWithNibName:@"VideoCompViewController" bundle:nil];
    videoCompVCfromThumb.IsOverlap = NO;
    videoCompVCfromThumb.IsUpdown = NO;
    if (btnOverlap.tag == 1) {
        videoCompVCfromThumb.IsOverlap = YES;
    }
    if (btnUpdown.tag == 1) {
        videoCompVCfromThumb.IsUpdown = YES;
    }
    
	videoCompVCfromThumb.IsNavigationCall = YES;
    [videoCompVCfromThumb setSkip:NO];
    //if (needToCreateNewCompVC || (_compVideoIndex1 != _selectedImageIndex2) || (_compVideoIndex2 != _selectedImageIndex2)) {
        // 動画の初期化
        [videoCompVCfromThumb initWithVideo:movies[_selectedImageIndex1]
                                      video:movies[_selectedImageIndex2]
                                   userName:lblUserName.text nameColor:lblUserName.textColor
                                   workDate:lblWorkDate.text
                                 isDrawMode:NO];
        _compVideoIndex1 = _selectedImageIndex1;
        _compVideoIndex2 = _selectedImageIndex2;
        
        // 施術情報の設定
        [videoCompVCfromThumb setWorkItemInfo:_userID workItemHistID:_histID];
        
    //}
    
    videoCompVCfromThumb.IsSetLayout = TRUE;
    
	// 動画合成画面の表示
	//[self.navigationController pushViewController:videoCompVC animated:YES];
    [self.view addSubview:videoCompVCfromThumb.view];
    CGRect vf = videoCompVCfromThumb.view.frame;
    videoCompVCfromThumb.view.frame = CGRectMake(vf.size.width, vf.origin.y, vf.size.width, vf.size.height);
    [videoCompVCfromThumb clearCanvas]; // 描画内容をクリア
    
    
    [UIView animateWithDuration:0.4 animations:^(void){
        videoCompVCfromThumb.view.frame = CGRectMake(0, vf.origin.y, vf.size.width, vf.size.height);
        //if (!needToCreateNewCompVC) {
            [videoCompVCfromThumb willRotateToInterfaceOrientation:
             [UIApplication sharedApplication].statusBarOrientation
                                                          duration:0];
        //}
    }];
    
	[videoCompVCfromThumb setSkip:NO];
    videoCompVCfromThumb.IsOverlap = NO;
    videoCompVCfromThumb.IsUpdown = NO;
    if (btnOverlap.tag == 1) {
        videoCompVCfromThumb.IsOverlap = YES;
    }
    if (btnUpdown.tag == 1) {
        videoCompVCfromThumb.IsUpdown = YES;
    }
	//[videoCompVCfromThumb release];
    _windowView = WIN_VIEW_COMP_VIDEO;
}

#pragma mark-
#pragma mark public_methods
/*
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
*/
#pragma mark - ClickVideoViewDelegate

// 動画選択イベント
- (void)OnClickVideoViewSelected:(NSUInteger)tagID
{
	/*
	// 写真描画に遷移していれば何もしない
	if (_isPicturePaintDisplaied)
	{
		_isPicturePaintDisplaied = NO;
		return;
	}
	
	// 選択されたTagIDをここで保存
	_selectedTagID = tagID + 1;
		// NSLog (@"OnOKDClickImageViewSelected at tagID:%d", _selectedTagID);
	 */
	
	// 画像Imageが１つの場合は、全画面表示Viewは表示しない:但し画像が縦長を除く
    if (_drawView.subviews.count <= 1){
        ClickVideoView *videoView = (ClickVideoView *)_drawView.subviews[0];
        if (videoView.isPortrait) {
            return;
        }
    }
	
	// 全画面表示Viewに画像を設定 -> この操作で全画面表示Viewが表示される
	//[_fullView setImage:image];
    
    // 重ね合わせ画像ボタンを非表示
    // btnOverlayCamera.hidden = YES;
}

// Touchイベント
- (void)OnClickVideoViewTouched:(id)sender
{
	// 画面ロックモードの場合はTouchイベントを無効にする
	MainViewController *mainVC
	= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	if ([mainVC isWindowLockState])
	{	return; }
	
	ClickVideoView* clickVideoView = (ClickVideoView*)sender;
	
    BOOL selectFlag = FALSE;
    //画像が既に選択されているかチェック
    if (clickVideoView.tag == _selectedImageIndex1) {
        selectFlag = TRUE;
    }else if (clickVideoView.tag == _selectedImageIndex2) {
        selectFlag = TRUE;
    }
    
    ClickVideoView *videoView;
    if (selectFlag) {
        //選択されている画像を非選択にする
        [clickVideoView setSelected:NO frameColor:nil];
        //非選択状態にする
        if (clickVideoView.tag == _selectedImageIndex1) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex2 != -1) {
                //自分以外も選択状態
                _selectedImageIndex1 = _selectedImageIndex2;
                _selectedImageIndex2 = -1;
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //非選択状態にする
                _selectedImageIndex1 = -1;
                _selectedCount--;
            }
        }else if (clickVideoView.tag == _selectedImageIndex2) {
            //他に選択状態の画像のTagを再設定
            //自分が赤枠の場合
            //一つ前の画像を赤枠状態にする
            videoView = [self getClickVideoViewByTag:_selectedImageIndex1];
            if (videoView)
            {
                [videoView setSelected:YES frameColor:[UIColor redColor]];
            }
            //非選択状態にする
            _selectedImageIndex2 = -1;
            _selectedCount--;
        }
    }else{
        //選択されている画像カウントチェック
        switch (_selectedCount) {
            case 0:
                // 新たな画像を選択された場合
                _selectedImageIndex1 = clickVideoView.tag;
                _selectedCount++;
                [clickVideoView setSelected:YES frameColor:[UIColor redColor]];
                if (clickVideoView.readError) {
                    [self readErrorMovie:clickVideoView.tag];
                }
                break;
            case 1:
                //二枚目選択
                _selectedImageIndex2 = clickVideoView.tag;
                //一つ前の画像を青枠状態にする
                videoView = [self getClickVideoViewByTag:_selectedImageIndex1];
                if (videoView)
                {
                    [videoView setSelected:YES frameColor:[UIColor blueColor]];
                }
                _selectedCount++;
                [clickVideoView setSelected:YES frameColor:[UIColor redColor]];
                if (clickVideoView.readError) {
                    [self readErrorMovie:clickVideoView.tag];
                }
                break;
            default:
                [Common showDialogWithTitle:@"" message:@"選択できる動画は2枚までです"];
                break;
        }
    }
	// １枚選択時のみ重ね合わせカメラを有効にする
	[self setOverlayCameraButonEnable: (_selectedCount == 1)];
    // facebook投稿ボタンを有効にする
    //[self setFacebookUpButonEnable: (_selectedCount == 1)];
    
    // 2枚選択時のみ透過・重ね合わせボタンを有効にする
    [self setAbreastOverlapButonEnable:(_selectedCount == 2)];
    
	/*
     // 選択されたTagIDをここで保存:_selectedTagID=1始まり
     _selectedTagID = clickVideoView.tag + 1;
     */
    //2012 /6/22 伊藤 連続しての画面遷移を防ぐための処理
    //画像の選択がない場合は右ページに遷移できない
    if (_selectedCount > 0) {
        [mainVC setScrollViewWidth:YES];
        // VideoCompViewController または EditVideoViewControllerが既に読み込み済みであれば
        // 削除する(異なる動画を読み込ませるため)
        if ([[mainVC getLastViewController] isKindOfClass:[VideoCompViewController class]] ||
            [[mainVC getLastViewController] isKindOfClass:[EditVideoViewController class]]) {
            [mainVC deleteViewControllersFromNextIndex];
        }
    }else {
        [mainVC setScrollViewWidth:NO];
    }
}

// 読み込みエラー動画tagセット
- (void)readErrorMovie:(NSUInteger)tagID;
{
    [errorTags addObject:[NSNumber numberWithInteger:tagID]];
}

// エラー動画が含まれているかをチェック
- (BOOL)checkReadError:(BOOL)isSingle
{
    BOOL result = NO;
    
    for (NSNumber *tag in errorTags) {
        if (isSingle) {
            if (tag.integerValue==_selectedImageIndex1) {
#ifdef DEBUG
                NSLog(@"read error image tag [%ld]", (long)tag.integerValue);
#endif
                result = YES;
            }
        } else {
            if (tag.integerValue==_selectedImageIndex1 || tag.integerValue==_selectedImageIndex2) {
#ifdef DEBUG
                NSLog(@"read error image tag [%ld]", (long)tag.integerValue);
#endif
                result = YES;
            }
        }
    }
    
    return result;
}

#pragma mark - スワイプ
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

// 右方向のスワイプイベント
// サムネイルViewからの遷移の場合のみこのメソッドを通る
// (NavigationControllerを使用の場合)
// 履歴詳細からの遷移の場合、OnTransitionNewView / OnTransitionExsitView を通る
- (void)OnSwipeRightView:(id)sender
{
	// 前画面に戻る
	if (self.isFlickEnable)
	{	[self OnSelectPictView]; }
}

// 左方向のスワイプイベント
// サムネイルViewからの遷移の場合のみこのメソッドを通る
// (NavigationControllerを使用の場合)
// 履歴詳細からの遷移の場合、OnTransitionNewView / OnTransitionExsitView を通る
- (void)OnSwipeLeftView:(id)sender
{
	// 左方向のフリック；写真描画画面に遷移
	if (self.isFlickEnable)
	{
        // 読み込み失敗画像が選択されている場合、次の画面に遷移しない
        if ([self checkReadError:(_selectedCount==1)]) {
            [self pageMoveAlert];
            return;
        }

		if (_selectedCount == 2) 
		{
			[self OnVideoCompView:nil];
		}
		else if (_selectedCount == 1)
		{
			[self OnEditVideoView:nil];
		}
	}
}

// 動画がない場合の画面遷移アラート表示
- (void) pageMoveAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"画面移動エラー"
                                                    message:@"動画が無いため、\n画面移動ができません。\nネットワーク環境の確認などを\n行ってください。"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];
}

#pragma mark - UIGestureRecognizerDelegate
// スワイプ可能か　ー＞描画中はオフにしないとタッチがキャンセルされてしまう。
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 動画合成画面が上に乗っているときはスワイプ不可
    if (videoCompVCfromThumb && (videoCompVCfromThumb.view.frame.origin.x == 0))
    {
        return NO;
    }
    // 動画描画画面が上に乗っているときはスワイプ不可
    if (editVideoVCfromThumb && (editVideoVCfromThumb.view.frame.origin.x == 0))
    {
        return NO;
    }
    return YES;
}
#pragma mark - UIScrollView Delegate
// ピンチ（ズーム）機能のdelegate:hファイルにUIScrollViewDelegateが必要
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	// このviewがscroll対象のviewとなる
	UIView *view = nil;
	if (_scrollView == scrollView)
	{
		view = _drawView;
	}
	
	return (view);
}

// ScrollView delegate 横画面時のスワイプ用
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if(scrollView.contentOffset.x < (0 - 30)) {
        //        NSLog(@"right [%f]", scrollView.contentOffset.x);
        [self OnSwipeRightView:nil];
    } else if (scrollView.contentOffset.x > (320 + 40)) {
        //        NSLog(@"left [%f]", scrollView.contentOffset.x);
        [self OnSwipeLeftView:nil];
    }
}

#pragma mark -  PopUpViewContollerBaseDelegate
- (void) OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    self.view.userInteractionEnabled = YES;
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:NO];
}
#pragma mark- 補佐的メソッド
// DELC SASAGE moviesと添字からUIImage取得
- (UIImage *)pictImage:(NSInteger)idx{
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID: _userID];
    return [((OKDThumbnailItemView*)movies[idx]) getRealSizeImage:imgFileMng];
}
// 写真タグIDから画像Viewを取得する
-(ClickVideoView *)getClickVideoViewByTag:(NSInteger)tag
{
	for (ClickVideoView* videoView in _drawView.subviews)
	{
		if (videoView.tag == tag)
		{
			return (videoView);
		}
	}
	
	return nil;
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
		NSLog(@"getHistIDWithDateUserID error on SelectPictureViewController!");
	}
	
	[usrDbMng release];
	
	return (histID);
}
@end
