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
#import "SelectPictureViewController.h"

#import "HistDetailViewController.h"
#import "HistListViewController.h"

#import "ThumbnailViewController.h"

#import "PicturePaintCommon.h"
#import "PicturePaintViewController.h"
#import "PictureCompViewController.h"
#import "camaraViewController.h"

#import "UtilHardCopySupport.h"

#import "userDbManager.h"

#import <Social/Social.h>   // facebook投稿のサポート
#import <MailCore.h>  // Mail送信のサポート

#import "AccountManager.h"
#import "model/OKDImageFileManager.h"

#import "UserInfoListViewController.h"
#import "DevStatusCheck.h"

ThumbnailViewController *thumbnailVC;
// PicturePaintViewController *picturePaintVC;

@implementation SelectPictureViewController

@synthesize isNavigationCall = _isNavigationCall;
@synthesize isFlickEnable = _isFlickEnable;
@synthesize workDate = _workDate;

#define WEB_CAM_MAX_SIZE    4896
#define WEB_CAM_MID_SIZE    2592
#define IPAD2_MAX_SIZE      1280

#if true
/*
 macro
 */
#define SYSTEM_VERSION_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define CURRENT_iOS 7
#endif

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		// メンバの初期化
		pictImageItems = nil;
		_scrollView = nil;
		_drawView = nil;
		
		_isFlickEnable = NO;
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
- (void)setWorkItemInfo:(USERID_INT)userID
         workItemHistID:(HISTID_INT)histID
			   workDate:(NSDate*)date
{
	_userID = userID;
	_histID = histID;
	self.workDate = date;
}

// 画像Imageリストの設定
- (void)setPictImageItems:(NSMutableArray*)images
{
	if (pictImageItems != nil)
	{	
		// 既に設定済み
		// return;
		
		/*
		for ( id img in pictImageItems)
		{
			[img release];
			img = nil;
		}
		*/
		
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
	
	// 選択画像情報クリア
	_selectedCount = 0;
	_selectedImageIndex1 = -1;
	_selectedImageIndex2 = -1;
    _selectedImageIndex3 = -1;
    _selectedImageIndex4 = -1;
    _selectedImageIndex5 = -1;
    _selectedImageIndex6 = -1;
    _selectedImageIndex7 = -1;
    _selectedImageIndex8 = -1;
    _selectedImageIndex9 = -1;
    _selectedImageIndex10 = -1;
    _selectedImageIndex11 = -1;
    _selectedImageIndex12 = -1;
    
    [self makeScrDrawView];
}

// ScrollViewと描画Viewの作成
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
		// 戻るボタンも描画Viewと同じサイズで作成
		/*
		_btnPrevView = [UIFlickerButton initWithFrameOwner:CGRectMake(0.0f, 0.0f, scrWidth, 704.0f)
												 ownerView:self]; 
		_btnPrevView.tag = FLICK_NEXT_PREV_VIEW;
		
		[_scrollView addSubview:_btnPrevView];
		*/
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
    
    // サムネイル表示の圧縮サイズ(３個以上の場合VGA相当、２個までの場合IPAD2_MAX_SIZE
    NSInteger max = ([pictImageItems count]>2)? 640 : IPAD2_MAX_SIZE;
	
	// 画像Itemを描画Viewに加える(メモリ不足の場合処理を中断する)
    for (int i = 0; (i < pictImageItems.count) && !memWarning; i++) {
		// ImageViewの作成(次ページ以降に移る時、オリジナルを読み直しているので、表示は縮小する)
		OKDClickImageView *imgView
        = [[[OKDClickImageView alloc]
            init:[self resizeImage:[self pictImage:i] maxSize:max]
            selectedNumber: i + 1
            ownerView:self] autorelease];
		imgView.delegate = self;
		imgView.tag = i;
        imgView.hidden = YES;
		
		// レイアウトはpictImagesLayoutで行う
		[_drawView addSubview:imgView];
    }
    // ダウンロード中に一時的にレイアウトが崩れるのを防ぐため、あとでまとめて表示
    for (UIView *subv in _drawView.subviews) {
        if ([subv isKindOfClass:[OKDClickImageView class]]){
            subv.hidden = NO;
        }
    }

	// 全画面表示Viewの作成
	if (! _fullView)
	{
		_fullView = [[OKDFullScreenFitImageView alloc]
					 initWithFrame:CGRectMake(0.0f, 0.0f, scrWidth, 704.0f)];
		// 背景色を渡す
		[_fullView setBackgroundColor:self.view.backgroundColor];
		
		[self.view addSubview:_fullView];
	}
	else {
		// _fullView.frame = CGRectMake(0.0f, 0.0f, scrWidth, 704.0f)];
	}

	
}

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

// 画像Itemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
- (void) pictImagesLayout:(BOOL)isPortrait
{
	// 画面が縦向き(portrait)かを横サイズより設定
	// UIScreen *screen = [UIScreen mainScreen];
	// BOOL isPortrait= (screen.applicationFrame.size.width == 768.0f);
	
	NSUInteger	wn, hn;			// 横、縦の個数
	CGFloat		ws, hs;			// 横、縦のサイズ
	CGFloat		wm, hm;			// 横、縦のマージン
	
	// 画像Imageリストの個数により画像の数、サイズなどを設定
	NSUInteger imgConunt = [pictImageItems count];
	switch (imgConunt) 
	{
		case 0:
		// 念のため
			wn = hn = 0;
			return;
			// break;

		case 1:
			wn = 1;
			// if ([Common isImagePortrait:[pictImageItems objectAtIndex:0]] )
			{
#ifdef CALULU_IPHONE
				ws = (isPortrait)? VIEW_WIDTH : 352.0f;
				hs = (isPortrait)? VIEW_HEIGHT : 264.0f;
#else
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
//            ws = (isPortrait)? 535.0f : 448.0f;
//            hs = (isPortrait)? 400.0f : 336.0f;
            ws = (isPortrait)? 485.0f : 400.0f;
            hs = (isPortrait)? 364.0f : 300.0f;
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

#if 1 // iOS7対応 kikuta - start - 2014/01/28
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = 0;
    // iOS7かつNavigationCallでの画面遷移の場合
    if (iOSVersion>=7.0f && _isNavigationCall) {
        uiOffset = 20;
    }
    
    // [_btnPrevView setFrame:CGRectMake(0.0f, 0.0f, sW, sH)];
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
#else
    // [_btnPrevView setFrame:CGRectMake(0.0f, 0.0f, sW, sH)];
	[_drawView setFrame:CGRectMake(0.0f, 0.0f, sW, sH)];
	[_scrollView setFrame:CGRectMake(10.0f, yOfs, scrWidth - 60, scrHeight)];
	// if ( (wn != wn2) || (hn != hn2) )
	{
		[_scrollView setContentSize:_drawView.frame.size];
	}
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = 0;
    // iOS7かつNavigationCallでの画面遷移の場合
    if (iOSVersion>=7.0f && _isNavigationCall) {
        uiOffset = 20;
    }
#endif // iOS7対応 kikuta - end - 2014/01/28
	
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
				
				OKDClickImageView *imgView 
					= (OKDClickImageView*)([childViews objectAtIndex:idx]);
				
				// x位置：横マージン＋（横マージン＋横サイズ）× x
				CGFloat xp = wm + (wm + ws) * (CGFloat)x;
				// y位置：縦マージン＋（縦マージン＋縦サイズ）× y
				CGFloat yp = hm + (hm + hs) * (CGFloat)y;
				// [imgView setFrame:CGRectMake(xp, yp, ws, hs)];
                if (isPortrait && (imgConunt > 2)) {
                    [imgView setSize:CGRectMake(xp, yp, 320, 240)];
                } else {
                    [imgView setSize:CGRectMake(xp, yp, ws, hs)];
                }
				
#ifndef CALULU_IPHONE	
				// 横向きで１枚のみ表示の場合は選択番号を非表示にしていたのを表示する
				if (imgConunt == 1)
				{
                    [imgView setSelectNumberHidden:NO];
                }
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
			
				OKDClickImageView *imgView 
					= (OKDClickImageView*)([childViews objectAtIndex:idx]);
			
				// x位置：横マージン＋（横マージン＋横サイズ）× x
				CGFloat xp = wm + (wm + ws) * (CGFloat)x;
				// y位置：縦マージン＋（縦マージン＋縦サイズ）× y
				CGFloat yp = hm + (hm + hs) * (CGFloat)y;
				// [imgView setFrame:CGRectMake(xp, yp, ws, hs)];
				[imgView setSize:CGRectMake(xp, yp, ws, hs)];
				
				// 横向きで１枚のみ表示の場合は選択番号を非表示にする
//                if (imgConunt == 1)
//                {
//                    [imgView setSelectNumberHidden:YES];
//                    imgView.center = CGPointMake(148 + (728 / 2), 20 + (546 / 2) + uiOffset);
//                }
			}
		}
	}
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
		[btnOverlayCamera setBackgroundImage: [UIImage imageNamed:@"cameraIcon_selected.png"]
									forState:UIControlStateNormal];
	}
	else 
	{
		btnOverlayCamera.enabled = NO;
		[btnOverlayCamera setBackgroundImage: [UIImage imageNamed:@"cameraIcon_unselected.png"]
									forState:UIControlStateNormal];
	}

}

//2016/4/22 TMS facebook投稿ボタン対応
// facebook投稿ボタンの有効／無効設定
- (void) setFacebookUpButonEnableInit:(BOOL)isEnable
{
#ifdef DEF_ABCARTE
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
	}
#else
    btnFacebookUp.hidden = YES;
#endif
}

//2016/4/22 TMS facebook投稿ボタン対応
// facebook投稿ボタンの有効／無効設定
- (void) setFacebookUpButonEnable:(BOOL)isEnable
{
#ifdef DEF_ABCARTE
    if (isEnable)
    {
        btnFacebookUp.enabled = YES;
        [btnFacebookUp setBackgroundImage: [UIImage imageNamed:@"facebook.png"]
                                 forState:UIControlStateNormal];
    }
    else
    {
        btnFacebookUp.enabled = NO;
        [btnFacebookUp setBackgroundImage: [UIImage imageNamed:@"facebook_disable.png"]
                                 forState:UIControlStateNormal];
    }
#else
    btnFacebookUp.hidden = YES;
#endif
}

// mail送信ボタンの有効／無効設定
- (void) 
setMailSendButonEnable:(BOOL)isEnable
{
#if WEB_MAIL_FUNC || MAIL_FUNC
    if (isEnable)
	{
		btnMailSend.enabled = YES;
		[btnMailSend setBackgroundImage: [UIImage imageNamed:@"mailIcon_selected.png"]
                               forState:UIControlStateNormal];
	}
	else
	{
		btnMailSend.enabled = NO;
		[btnMailSend setBackgroundImage: [UIImage imageNamed:@"mailIcon_unselected.png"]
                               forState:UIControlStateNormal];
	}
#else
    btnMailSend.hidden = YES;
#endif
}

// 透過・重ね合わせボタンの有効／無効設定
- (void) setAbreastOverlapButonEnable:(BOOL)isEnable
{
    btnAbreast.enabled = isEnable;
    btnOverlap.enabled = isEnable;
    btnUpdown.enabled = isEnable;

    if (![AccountManager isMorphing]) {

        btnMorphing.enabled = isEnable;
        btnMorphing.enabled = NO;
        [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_unselected.png"]
                               forState:UIControlStateNormal];
        btnMorphing.tag = 0;
        btnAbreast.tag = 1;
        btnOverlap.tag = 0;
        btnUpdown.tag = 0;

    }else{
        btnMorphing.enabled = isEnable;
        btnMorphing.enabled = NO;
        [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_unselected.png"]
                               forState:UIControlStateNormal];
        btnMorphing.tag = 0;
        btnAbreast.tag = 1;
        btnOverlap.tag = 0;
        btnUpdown.tag = 0;
    }

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
            [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_unselected.png"]
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
            [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_unselected.png"]
                                   forState:UIControlStateNormal];
        }
        else if (btnUpdown.tag == 1)
        {
            [btnUpdown setBackgroundImage:[UIImage imageNamed:@"updownIcon_selected.png"]
                                 forState:UIControlStateNormal];

            [btnAbreast setBackgroundImage: [UIImage imageNamed:@"compareIcon_unselected.png"]
                                  forState:UIControlStateNormal];
            [btnOverlap setBackgroundImage: [UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                                  forState:UIControlStateNormal];
            [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_unselected.png"]
                                   forState:UIControlStateNormal];
        }else if (btnMorphing.tag == 1)
        {
            [btnUpdown setBackgroundImage: [UIImage imageNamed:@"updownIcon_unselected.png"]
                                 forState:UIControlStateNormal];

            [btnAbreast setBackgroundImage: [UIImage imageNamed:@"compareIcon_unselected.png"]
                                  forState:UIControlStateNormal];
            [btnOverlap setBackgroundImage: [UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                                  forState:UIControlStateNormal];
            [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_selected.png"]
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
        [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_unselected.png"]
                               forState:UIControlStateNormal];
    }
    
}

// モーフィングボタンの有効／無効設定
- (void) setMorphingButonEnable:(BOOL)isEnable
{
    if (![AccountManager isMorphing]) {
        btnMorphing.enabled = isEnable;
        btnMorphing.hidden = YES;
        btnMorphing.enabled = NO;
        return;
    }else{
        btnMorphing.enabled = isEnable;
    }
    
    if (isEnable)
    {
        [self OnBtnSynthesisModeChange:btnMorphing];
        btnAbreast.enabled = NO;
        btnOverlap.enabled = NO;
        btnUpdown.enabled = NO;
        [btnUpdown setBackgroundImage: [UIImage imageNamed:@"updownIcon_unselected.png"]
                             forState:UIControlStateNormal];

        [btnAbreast setBackgroundImage: [UIImage imageNamed:@"compareIcon_unselected.png"]
                              forState:UIControlStateNormal];
        [btnOverlap setBackgroundImage: [UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                              forState:UIControlStateNormal];

        [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_selected.png"]
                               forState:UIControlStateNormal];
    }
    else
    {
        [btnMorphing setBackgroundImage: [UIImage imageNamed:@"morphingIcon_unselected.png"]
                               forState:UIControlStateNormal];
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
		NSLog(@"getHistIDWithDateUserID error on SelectPictureViewController!");
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
    [super viewDidLoad];
    
    //viewfunction
    viewFunction.layer.cornerRadius = 10;
    viewFunction.clipsToBounds = true;
    
    isiPad2 = ([UIScreen mainScreen].scale > 1.0f)? NO : YES;
	
    // 背景色の変更 RGB:D8BFD8
//    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:204/255.0f green:149/255.0f blue:187/255.0f alpha:1.0f];

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
    _selectedImageIndex3 = -1;
    _selectedImageIndex4 = -1;
    _selectedImageIndex5 = -1;
    _selectedImageIndex6 = -1;
    _selectedImageIndex7 = -1;
    _selectedImageIndex8 = -1;
    _selectedImageIndex9 = -1;
    _selectedImageIndex10 = -1;
    _selectedImageIndex11 = -1;
    _selectedImageIndex12 = -1;
    
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
    btnAbreast.tag = 0;
    btnOverlap.tag = 0;
    btnUpdown.tag = 0;
    btnMorphing.tag = 0;
    
    //2016/4/22 TMS facebook投稿ボタン対応
    // facebookの利用が可能なアカウントで有るかを確認する
    [self setFacebookUpButonEnableInit:[AccountManager isFaceBook]];

    // mailの利用が可能かを確認する
#ifdef AIKI_CUSTOM
    [self setMailEnableIsFlag:![mainVC isWindowLockState]];
#else
    [self setMailEnableIsFlag:[AccountManager isWebMail] && ![mainVC isWindowLockState]];
#endif

    Ovimage = nil;
    
    // リストを空で作成
    errorTags = [ [NSMutableArray alloc] init];

    vcMailSend = nil;
    vcSwimmy = nil;
    
    if (![AccountManager isMorphing]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL isMorphing = true;
        [defaults setObject:[NSString stringWithFormat:@"%d",isMorphing]forKey:@"optionMorphing"];
        
//        btnMorphing.hidden = YES;
//        btnMorphing.enabled = NO;

    }
}

// 画面が表示される都度callされる:viewWillAppear
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear : animated];
	
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;

	// カメラ画面からの遷移の場合
	if ( _windowView == WIN_VIEW_CAMERA)
	{
		// 遷移元のVCに対して更新処理を行う
		// [self refresh2OwnerTransitionVC];
		
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
	[self pictImagesLayout : isPortrait];
	
	// 全画面表示viewの更新
	[_fullView refresh : isPortrait];
	
    [self uiLayout:isPortrait];
    
	// 印刷ボタンと重ね合わせカメラボタンを最前面にする
	if (! btnHardCopyPrint.hidden)
	{	[self.view bringSubviewToFront:btnHardCopyPrint]; }
//    [self.view bringSubviewToFront:btnOverlayCamera];
    [self.view bringSubviewToFront:btnFacebookUp];      // facebook投稿ボタンも最前面にする
    [self.view bringSubviewToFront:btnMailSend];
    [self.view bringSubviewToFront:btnSwimmy];
    
    // 2012 7/13 写真を重ねて表示
//    [self.view bringSubviewToFront:btnAbreast];
//    [self.view bringSubviewToFront:btnOverlap];
//    [self.view bringSubviewToFront:btnUpdown];
//    [self.view bringSubviewToFront:btnMorphing];
    [self.view bringSubviewToFront:viewFunction];
    
	// 重ね合わせカメラの初期状態は無効
	[self setOverlayCameraButonEnable: (_selectedCount == 1)];
    
    //2016/4/22 TMS facebook投稿ボタン対応
    // facebook投稿ボタンの初期状態は無効
    [self setFacebookUpButonEnableInit: [AccountManager isFaceBook]];
    
    // Mailボタンの初期状態は無効
#ifdef AIKI_CUSTOM
    [self setMailSendButonEnable:![mainVC isWindowLockState]];
#else
    [self setMailSendButonEnable:[AccountManager isWebMail] && ![mainVC isWindowLockState]];
#endif
    btnSwimmy.hidden = ![AccountManager isSwimmy];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

// ボタン類の位置調整
- (void)uiLayout:(BOOL)isPortrait
{
//    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
//
//    // iOS7かつNavigationCallでの画面遷移の場合
//    if (iOSVersion<7.0f || !_isNavigationCall) return;
//
//    float uiOffset = 20.0f;
//
//    // ユーザ名
//    [viewUserNameBack setFrame: (isPortrait)?
//     CGRectMake(461.0f, 12.0f + uiOffset, 287.0f, 30.0f) :
//     CGRectMake(461.0f + 256.0f, 12.0f + uiOffset, 287.0f, 30.0f) ];
//
//    // 施術日
//    [viewWorkDateBack setFrame: (isPortrait)?
//     CGRectMake(124.0f, 12.0f + uiOffset, 310.0f, 30.0f) :
//     CGRectMake(124.0f + 256.0f, 12.0f + uiOffset, 310.0f, 30.0f) ];
//
//    // プリントボタン
//    [btnHardCopyPrint setFrame: (isPortrait)?
//     CGRectMake(8.0f, 260.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(8.0f, 260.0f + uiOffset, 54.0f, 54.0f) ];
//
//    // カメラボタン
//    [btnOverlayCamera setFrame: (isPortrait)?
//     CGRectMake(8.0f, 12.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(8.0f, 12.0f + uiOffset, 54.0f, 54.0f) ];
//
//    // メール送信ボタン
//    [btnMailSend setFrame: (isPortrait)?
//     CGRectMake(64.0f, 198.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(64.0f, 198.0f + uiOffset, 54.0f, 54.0f) ];
//
//    // 突き合わせ
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
//
//    // モーフィング
//    [btnMorphing setFrame: (isPortrait)?
//     CGRectMake(64.0f, 136.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(64.0f, 136.0f + uiOffset, 54.0f, 54.0f) ];
//
//    // Facebook投稿
//    [btnFacebookUp setFrame: (isPortrait)?
//     CGRectMake(67.0f, 12.0f + uiOffset, 48.0f, 48.0f) :
//     CGRectMake(67.0f, 12.0f + uiOffset, 48.0f, 48.0f) ];
//
//    // Facebook投稿
//    [btnSwimmy setFrame: (isPortrait)?
//     CGRectMake(8.0f, 198.0f + uiOffset, 54.0f, 54.0f) :
//     CGRectMake(8.0f, 198.0f + uiOffset, 54.0f, 54.0f) ];
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
    
    for (OKDClickImageView* imgVw in _drawView.subviews)
    {
        if (imgVw.subviews.count >= 6) {
            if ([[imgVw.subviews objectAtIndex:5] isKindOfClass:[UIImageView class]]) {
                UIImageView *imageView = [imgVw.subviews objectAtIndex:5];
                [imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ];
            }
        }
    }
    
    [self uiLayout:!isPortrait];
	
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
}

// 画面が表示される都度callされる:viewDidAppear
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear : animated];
    
    memWarning = NO;
	
	OKDClickImageView* imgView = nil;
    // 編集画面から戻ったとき（画像１つ選択）に前画面（編集画面）を解除する
	if (_windowView==WIN_VIEW_EDIT_PICTURE) {
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
//        id obj = [mainVC getLastViewController];
//        if([obj isKindOfClass:[PicturePaintViewController class]]) {
//            [(PicturePaintViewController *)obj viewDidUnload];
//            [(PicturePaintViewController *)obj release];
//        }
        [mainVC deleteViewControllersFromNextIndex];
    }
	if (_selectedImageIndex1 >= 0)
	{
		imgView = [self getClickImageViewByTag:_selectedImageIndex1];
		if (imgView) 
		{
			[imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
		}
	}
	if (_selectedImageIndex2 >= 0)
	{
		imgView = [self getClickImageViewByTag:_selectedImageIndex2];
		if (imgView) 
		{
			[imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
		}
	}
    if (_selectedImageIndex3 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex3];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex2];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex4 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex4];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex3];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex5 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex5];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex4];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex6 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex6];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex5];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex7 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex7];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex6];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex8 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex8];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex7];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex9 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex9];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex8];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex10 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex10];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex9];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex11 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex11];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex10];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    if (_selectedImageIndex12 >= 0)
    {
        imgView = [self getClickImageViewByTag:_selectedImageIndex12];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
        }
        imgView = [self getClickImageViewByTag:_selectedImageIndex11];
        if (imgView)
        {
            [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
        }
    }
    
    _windowView = WIN_VIEW_SELECT_PICTURE;
}

- (void)viewDidDisappear:(BOOL)animated
{
	if (_isBackCameraView != YES)
	{
		// 現時点で最上位のViewController(=self)を削除する
        [ self dismissViewControllerAnimated:animated completion:nil];
	}
	
	/*
	 if (_isBackCameraView)
	 {
	 // 画像選択画面Viewを非表示する
	 [self.view removeFromSuperview];
	 
	 }
	 */
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    if (!memWarning) {
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        if ([[mainVC getNowCurrentViewController] isKindOfClass:[SelectPictureViewController class]]) {
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
    [btnSwimmy release];
    btnSwimmy = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [lblUserName release];				// ユーザ名
    [lblWorkDate release];				// 施術日
    [lblWorkDateTitle release];			// 施術日タイトル
    [viewUserNameBack release];			// ユーザ名背景
    [viewWorkDateBack release];			// 施術日背景
    [btnOverlayCamera release];			// 重ね合わせカメラボタン
    [btnHardCopyPrint release];			// ハードコピーボタン
    [btnFacebookUp release];             // facebook投稿ボタン
    [btnMailSend release];               // mail送信ボタン
    [btnSwimmy release];                 // Swimmyボタン
    [btnAbreast release];                // 写真の並列表示（デフォルト）
    [btnOverlap release];                // 写真を重ねる
    [btnUpdown release];                 // 上下で表示
    [btnMorphing release];               // モーフィング

    for ( id vw in _drawView.subviews)
    {
        [((UIView*)vw) removeFromSuperview];
        ((OKDThumbnailItemView *)vw).delegate = nil;
    }

//    for (OKDThumbnailItemView *thumView in pictImageItems) {
//        [thumView removeFromSuperview];
//        thumView.delegate = nil;
//    }
    [pictImageItems removeAllObjects];
	[pictImageItems release];
    
	[_fullView release];
    
    [_drawView removeFromSuperview];
	[_drawView release];

    [_scrollView removeFromSuperview];
    _scrollView.delegate = nil;
    [_scrollView release];
	
	[_workDate release];
    if(Ovimage!=nil)[Ovimage release];
	
    [errorTags removeAllObjects];
    [errorTags release];
    [viewFunction release];
    [super dealloc];
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
// TransitionControllによる画面遷移の場合はこちらを通る
// サムネイルviewからの遷移の場合は OnSwipeLeftView / OnSwipeRightView を通る
- (UIViewController*) OnTransitionNewView:(id)sender
{
#ifdef DEBUG
	NSLog(@"OnTransitionNewView at SelectPictureViewController");
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

    if (![self checkEnableTransition]) {
        return nil;
    }

    if (btnMorphing.tag == 1) {
        if (_selectedCount >= 2)
        {
            [mainVC skipNextPage:NO];
            _windowView = WIN_VIEW_COMP_PICTURE;
        }
    }else{
        if (_selectedCount == 2)
        {
            [mainVC skipNextPage:NO];
            _windowView = WIN_VIEW_COMP_PICTURE;
        }
        else if (_selectedCount == 1)
        {
            // 選択画像数が1つの時は、画像合成画面はスキップする
            [mainVC skipNextPage:YES];
            _windowView = WIN_VIEW_EDIT_PICTURE;
        }
        else
        {
            // 遷移をキャンセル
            return (nil);
        }
    }
	
	PictureCompViewController  *pictureCompVC
		= [[[PictureCompViewController alloc]
#ifdef CALULU_IPHONE
		   initWithNibName:@"ip_PictureCompViewController" bundle:nil] autorelease];
#else
		   initWithNibName:@"PictureCompViewController" bundle:nil] autorelease];
#endif

	return (pictureCompVC);
}

// 新規View画面への遷移でViewがLoadされた後にコールされる
- (void) OnTransitionNewViewDidLoad:(id)sender transitionVC:(UIViewController*)tVC
{
	PictureCompViewController *pictureCompVC = (PictureCompViewController*)tVC;
	
	if (_selectedCount >= 2 && _selectedCount < 13)
    {
		[pictureCompVC setSkip:NO];
        // 2012 7/13 写真の透過合成
        pictureCompVC.IsOverlap = NO;
        pictureCompVC.IsUpdown = NO;
        pictureCompVC.IsMorphing = NO;
        if (btnOverlap.tag == 1) {
            pictureCompVC.IsOverlap = YES;
        }
        if (btnUpdown.tag == 1) {
            pictureCompVC.IsUpdown = YES;
        }
        
        if (_selectedCount > 2) {
            if (btnMorphing.tag == 1) {
                pictureCompVC.IsMorphing = YES;
                [pictureCompVC setWorkItemInfo:_userID workItemHistID:_histID];
                [pictureCompVC setPictImageItems:[self setWkPictImageItems]];
                [pictureCompVC setCoordinateThumbnailList];
            }
        }
        
        // Webカメラ画像の2つともHighの場合にメモリ不足になる為、合成の場合は
        // 解像度をMid以下にする
        UIImage *pict1 = [self pictImage: _selectedImageIndex1];
        UIImage *pict2 = [self pictImage: _selectedImageIndex2];
        if (pict1.size.width>WEB_CAM_MID_SIZE || pict1.size.height>WEB_CAM_MID_SIZE) {
            pict1 = [self resizeImage:pict1 maxSize:WEB_CAM_MID_SIZE];
        }
        if (pict2.size.width>WEB_CAM_MID_SIZE || pict2.size.height>WEB_CAM_MID_SIZE) {
            pict2 = [self resizeImage:pict2 maxSize:WEB_CAM_MID_SIZE];
        }

		// 写真の初期化
        [pictureCompVC initWithPicture:pict1
                         pictureImage2:pict2
							   userName:lblUserName.text nameColor:lblUserName.textColor
							   workDate:lblWorkDate.text];
    }else if (_selectedCount == 1)
	{
		[pictureCompVC setSkip:YES];

		// 写真描画の初期化
		UIImage *image = ([pictImageItems count ] > 0)? [self pictImage: _selectedImageIndex1] : nil;
		[pictureCompVC initWithPicture:image
						 pictureImage2:image 
							  userName:lblUserName.text nameColor:lblUserName.textColor
							  workDate:lblWorkDate.text];
	}
	else 
	{
		return;
	}

	// 施術情報の設定
	[pictureCompVC setWorkItemInfo:_userID workItemHistID:_histID];
	
	pictureCompVC.IsSetLayout = TRUE;
	
	//_isPicturePaintDisplaied = YES;
}

- (NSMutableArray*)setWkPictImageItems{
    
    NSMutableArray *pictImageList = [ [NSMutableArray alloc] init];
    
    if(_selectedImageIndex1 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex1]];
    if(_selectedImageIndex2 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex2]];
    if(_selectedImageIndex3 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex3]];
    if(_selectedImageIndex4 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex4]];
    if(_selectedImageIndex5 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex5]];
    if(_selectedImageIndex6 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex6]];
    if(_selectedImageIndex7 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex7]];
    if(_selectedImageIndex8 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex8]];
    if(_selectedImageIndex9 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex9]];
    if(_selectedImageIndex10 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex10]];
    if(_selectedImageIndex11 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex11]];
    if(_selectedImageIndex12 != -1)[pictImageList addObject:[pictImageItems objectAtIndex:_selectedImageIndex12]];

    return pictImageList;
    
}
// 既存View画面への遷移
// TransitionControllによる画面遷移の場合はこちらを通る
// サムネイルviewからの遷移の場合は OnSwipeLeftView / OnSwipeRightView を通る
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC
{
#ifdef DEBUG
	NSLog(@"OnTransitionExsitView at SelectPictureViewController");
#endif
    // 読み込み失敗画像が選択されている場合、次の画面に遷移しない
    if ([self checkReadError:(_selectedCount==1)]) {
        [self pageMoveAlert];
        return nil;
    }

    if (![self checkEnableTransition]) {
        return nil;
    }

	PictureCompViewController *pictureCompVC = (PictureCompViewController*)tVC;
	MainViewController* mainVC = (MainViewController*)sender;
    
    // 選択がある場合はここでViewを表示する
    //  (PictureCompViewController:OnUnloadViewメソッドで非表示にしたため)
    if (_selectedCount > 0)
    { pictureCompVC.view.hidden = NO; }
    
	if (_selectedCount >= 2 && _selectedCount < 13)
	{
        if(_selectedCount > 2 && btnMorphing.tag != 1){
            [mainVC skipNextPage:NO];
            [pictureCompVC setSkip:NO];
            
            // 遷移をキャンセル
            return (NO);
        }
        
		[mainVC skipNextPage:NO];
		[pictureCompVC setSkip:NO];
        /*
        // 2012 7/13 写真の透過合成
        pictureCompVC.IsOverlap = NO;
        pictureCompVC.IsUpdown = NO;
        if (btnOverlap.tag == 1) {
            pictureCompVC.IsOverlap = YES;
        }
        if (btnUpdown.tag == 1) {
            pictureCompVC.IsUpdown = YES;
        }*/
        
        pictureCompVC.IsOverlap = NO;
        pictureCompVC.IsUpdown = NO;
        pictureCompVC.IsMorphing = NO;
        if (btnOverlap.tag == 1) {
            pictureCompVC.IsOverlap = YES;
        }
        if (btnUpdown.tag == 1) {
            pictureCompVC.IsUpdown = YES;
        }
        if (btnMorphing.tag == 1) {
            pictureCompVC.IsMorphing = YES;
            [pictureCompVC setWorkItemInfo:_userID workItemHistID:_histID];
            [pictureCompVC setPictImageItems:[self setWkPictImageItems]];
            [pictureCompVC setCoordinateThumbnailList];
        }
        // Webカメラ画像の2つともHighの場合にメモリ不足になる為、合成の場合は
        // 解像度をMid以下にする
        UIImage *pict1 = [self pictImage: _selectedImageIndex1];
        UIImage *pict2 = [self pictImage: _selectedImageIndex2];
        if (isiPad2) {
            if (pict1.size.width>IPAD2_MAX_SIZE || pict1.size.height>IPAD2_MAX_SIZE) {
                pict1 = [self resizeImage:pict1 maxSize:IPAD2_MAX_SIZE];
            }
            if (pict2.size.width>IPAD2_MAX_SIZE || pict2.size.height>IPAD2_MAX_SIZE) {
                pict2 = [self resizeImage:pict2 maxSize:IPAD2_MAX_SIZE];
            }
        }
        else {
            if (pict1.size.width>WEB_CAM_MID_SIZE || pict1.size.height>WEB_CAM_MID_SIZE) {
                pict1 = [self resizeImage:pict1 maxSize:WEB_CAM_MID_SIZE];
            }
            if (pict2.size.width>WEB_CAM_MID_SIZE || pict2.size.height>WEB_CAM_MID_SIZE) {
                pict2 = [self resizeImage:pict2 maxSize:WEB_CAM_MID_SIZE];
            }
        }
		// 写真の初期化
        [pictureCompVC initWithPicture:pict1
                         pictureImage2:pict2
                              userName:lblUserName.text nameColor:lblUserName.textColor
                              workDate:lblWorkDate.text];
        _windowView = WIN_VIEW_COMP_PICTURE;
	}
	else if (_selectedCount == 1)
	{
        pictureCompVC.IsUpdown = NO;
        pictureCompVC.IsMorphing = NO;
        
		[mainVC skipNextPage:YES];
		[pictureCompVC setSkip:YES];

		// 写真描画の初期化
		UIImage *image = ([pictImageItems count ] > 0)?
        [self pictImage: _selectedImageIndex1] : nil;
		[pictureCompVC initWithPicture:image
						 pictureImage2:image 
							  userName:lblUserName.text nameColor:lblUserName.textColor
							  workDate:lblWorkDate.text];
        _windowView = WIN_VIEW_EDIT_PICTURE;
	}
	else 
	{
		[mainVC skipNextPage:NO];
		[pictureCompVC setSkip:NO];

		// 遷移をキャンセル
		return (NO);
	}
	
	// 施術情報の設定
	[pictureCompVC setWorkItemInfo:_userID workItemHistID:_histID];

	pictureCompVC.IsSetLayout = TRUE;
	//_isPicturePaintDisplaied = YES;
	
	return (YES);				// 画面遷移する	
}

// 画面終了の通知
- (BOOL) OnUnloadView:(id)sender
{
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
        [self setMorphingButonEnable:NO];
//        [self setFacebookUpButonEnable:NO];         // facebook投稿ボタンも無効に
    }
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:NO];
#ifdef AIKI_CUSTOM
    [self setMailSendButonEnable:(![mainVC isWindowLockState])];
#else
    [self setMailSendButonEnable:(![mainVC isWindowLockState] && [AccountManager isWebMail])];
#endif
    [self setFacebookUpButonEnable:(![mainVC isWindowLockState] && [AccountManager isFaceBook] && (_selectedCount == 1))];
    btnSwimmy.enabled = ![mainVC isWindowLockState] && [AccountManager isSwimmy];

	// 画面ロックにより、印刷ボタンを非表示にする(有効である場合のみ)
	if (btnHardCopyPrint.tag > 0)
	{	btnHardCopyPrint.hidden = isLock; }
	
	// 画面ロックにより、選択を解除する
	for (OKDClickImageView* imgVw in _drawView.subviews)
	{	
		// imgVw.delegate = (! isLock)? self : nil; 
		if (isLock)
		{	[imgVw setSelected:NO frameColor:nil numberSelected:0] ; }
	}
	if (isLock)
	{
		_selectedImageIndex1 = _selectedImageIndex2 = _selectedImageIndex3 = _selectedImageIndex4 = _selectedImageIndex5 = _selectedImageIndex6 = _selectedImageIndex7 = _selectedImageIndex8 = _selectedImageIndex9 = _selectedImageIndex10 = _selectedImageIndex11 = _selectedImageIndex12 = -1;
		_selectedCount = 0;
	}
    
    if (vcMailSend) {
        [vcMailSend OnCancelButton:nil];
    }
    if (vcSwimmy) {
        [vcSwimmy OnCancelBtn:nil];
    }
}

#pragma mark control_events

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
	// サムネイル画面の表示
	/*
	thumbnailVC = [[ThumbnailViewController alloc] initWithNibName:@"ThumbnailViewController" bundle:nil];
	thumbnailVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:thumbnailVC animated:YES];
	 */
	
	// 現時点で最上位のViewController(=self)を削除する
	_isBackCameraView = NO;
	
	if (! self.isNavigationCall)
	{
		// [ [self parentViewController] dismissModalViewControllerAnimated:YES];
	}
	else 
	{
		[self.navigationController popViewControllerAnimated:YES];
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
	
    // iOS7で時間を置かずに initWithPicture を呼ぶと、ViewDidLoadが終了していないため
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
	// 現在選択中のユーザIDを渡す
	[cameraView setSelectedUser:_userID 
					   userName:lblUserName.text
					  nameColor:lblUserName.textColor];
	
	// 重ね合わせの画像を渡す
	UIImage *image = ([pictImageItems count ] > 0)?
		[self pictImage: _selectedImageIndex1] : nil;
    if(Ovimage != nil) [Ovimage release];
    Ovimage = [[UIImage alloc]initWithCGImage:image.CGImage];
	[cameraView setOverlayImage:Ovimage];
	
	// 現在のデバイスの向きを取得
	UIInterfaceOrientation orient = [mainVC getNowDeviceOrientation];
	// デバイスの向きを設定する
	[cameraView willRotateToInterfaceOrientation:orient duration:(NSTimeInterval)0];
    });
	// 遷移画面の設定:カメラ画面
	_windowView = WIN_VIEW_CAMERA;
    
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

	
	[UtilHardCopySupport startHardCopy:btnHardCopyPrint.bounds inView:btnHardCopyPrint
					 completionHandler:completionHandler];
}

// facebook投稿
- (IBAction)OnFacebookUp
{
    // FaceBookオプション契約が無い場合
    if(![AccountManager isFaceBook]) return;
    
    // facebook機能が利用できるかをSocial Frameworkが使えるかで判断する
    BOOL isFb = (NSClassFromString(@"SLComposeViewController"));
    if (!isFb)
    {
        [Common showDialogWithTitle:@"facebook投稿について"
                            message:@"お使いのiPadでは\nご利用いただけません\n\n(最新のiOSにアップデート\nするとご利用になれます)"];
        return;
    }
    
    
    // 選択中の画像を取得
    UIImage *image = ([pictImageItems count ] > 0)?
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
        btnMorphing.tag = 0;
        [btnMorphing setBackgroundImage:[UIImage imageNamed:@"morphingIcon_unselected.png"]
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
        btnMorphing.tag = 0;
        [btnMorphing setBackgroundImage:[UIImage imageNamed:@"morphingIcon_unselected.png"]
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
        btnMorphing.tag = 0;
        [btnMorphing setBackgroundImage:[UIImage imageNamed:@"morphingIcon_unselected.png"]
                               forState:UIControlStateNormal];
    }else if(selectBtn == btnMorphing){
        btnAbreast.tag = 0;
        [btnAbreast setBackgroundImage:[UIImage imageNamed:@"compareIcon_unselected.png"]
                              forState:UIControlStateNormal];

        btnOverlap.tag = 0;
        [btnOverlap setBackgroundImage:[UIImage imageNamed:@"tranmissionIcon_unselected.png"]
                              forState:UIControlStateNormal];
        btnUpdown.tag = 0;
        [btnUpdown setBackgroundImage:[UIImage imageNamed:@"updownIcon_unselected.png"]
                             forState:UIControlStateNormal];
        btnMorphing.tag = 1;
        [btnMorphing setBackgroundImage:[UIImage imageNamed:@"morphingIcon_selected.png"]
                               forState:UIControlStateNormal];
    }
}

// 画像がない場合の画面遷移アラート表示
- (void) pageMoveAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"画面移動エラー"
                                                    message:@"画像が無いため、\n画面移動ができません。\nネットワーク環境の確認などを\n行ってください。"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];
}

#pragma mark OKDClickImageViewDelegate

// 画像Image選択イベント
- (void)OnOKDClickImageViewSelected:(NSUInteger)tagID image:(UIImage*)image
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
	if ( ([pictImageItems count] <= 1) && (! [Common isImagePortrait:image] ))
	{ return; }
	
	// 全画面表示Viewに画像を設定 -> この操作で全画面表示Viewが表示される
	[_fullView setImage:image];
    
    // 重ね合わせ画像ボタンを非表示
    // btnOverlayCamera.hidden = YES;
}

// Touchイベント
- (void)OnOKDClickImageViewTouched:(id)sender
{
	// 画面ロックモードの場合はTouchイベントを無効にする
	MainViewController *mainVC 
	= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	if ([mainVC isWindowLockState])
	{	return; }
	
	OKDClickImageView* clickImageView = (OKDClickImageView*)sender;
	
    BOOL selectFlag = FALSE;
    //画像が既に選択されているかチェック
    if (clickImageView.tag == _selectedImageIndex1) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex2) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex3) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex4) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex5) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex6) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex7) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex8) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex9) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex10) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex11) {
        selectFlag = TRUE;
    }else if (clickImageView.tag == _selectedImageIndex12) {
        selectFlag = TRUE;
    }
    
    OKDClickImageView* imgView;
    if (selectFlag) {
        //選択されている画像を非選択にする
        [clickImageView setSelected:NO frameColor:nil numberSelected:0];
        //非選択状態にする
        if (clickImageView.tag == _selectedImageIndex1) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex2 != -1) {
                //自分以外も選択状態
                _selectedImageIndex1 = _selectedImageIndex2;
                _selectedImageIndex2 = -1;
                if (_selectedImageIndex3 != -1) {
                    _selectedImageIndex2 = _selectedImageIndex3;
                    _selectedImageIndex3 = -1;
                }
                if (_selectedImageIndex4 != -1) {
                    _selectedImageIndex3 = _selectedImageIndex4;
                    _selectedImageIndex4 = -1;
                }
                if (_selectedImageIndex5 != -1) {
                    _selectedImageIndex4 = _selectedImageIndex5;
                    _selectedImageIndex5 = -1;
                }
                if (_selectedImageIndex6 != -1) {
                    _selectedImageIndex5 = _selectedImageIndex6;
                    _selectedImageIndex6 = -1;
                }
                if (_selectedImageIndex7 != -1) {
                    _selectedImageIndex6 = _selectedImageIndex7;
                    _selectedImageIndex7 = -1;
                }
                if (_selectedImageIndex8 != -1) {
                    _selectedImageIndex7 = _selectedImageIndex8;
                    _selectedImageIndex8 = -1;
                }
                if (_selectedImageIndex9 != -1) {
                    _selectedImageIndex8 = _selectedImageIndex9;
                    _selectedImageIndex9 = -1;
                }
                if (_selectedImageIndex10 != -1) {
                    _selectedImageIndex9 = _selectedImageIndex10;
                    _selectedImageIndex10 = -1;
                }
                if (_selectedImageIndex11 != -1) {
                    _selectedImageIndex10 = _selectedImageIndex11;
                    _selectedImageIndex11 = -1;
                }
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
                
                
            }else{
                //自分が赤枠の場合
                //非選択状態にする
                _selectedImageIndex1 = -1;
                _selectedCount--;
                
            }
        }else if (clickImageView.tag == _selectedImageIndex2) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex3 != -1) {
                _selectedImageIndex2 = _selectedImageIndex3;
                _selectedImageIndex3 = -1;
                if (_selectedImageIndex4 != -1) {
                    _selectedImageIndex3 = _selectedImageIndex4;
                    _selectedImageIndex4 = -1;
                }
                if (_selectedImageIndex5 != -1) {
                    _selectedImageIndex4 = _selectedImageIndex5;
                    _selectedImageIndex5 = -1;
                }
                if (_selectedImageIndex6 != -1) {
                    _selectedImageIndex5 = _selectedImageIndex6;
                    _selectedImageIndex6 = -1;
                }
                if (_selectedImageIndex7 != -1) {
                    _selectedImageIndex6 = _selectedImageIndex7;
                    _selectedImageIndex7 = -1;
                }
                if (_selectedImageIndex8 != -1) {
                    _selectedImageIndex7 = _selectedImageIndex8;
                    _selectedImageIndex8 = -1;
                }
                if (_selectedImageIndex9 != -1) {
                    _selectedImageIndex8 = _selectedImageIndex9;
                    _selectedImageIndex9 = -1;
                }
                if (_selectedImageIndex10 != -1) {
                    _selectedImageIndex9 = _selectedImageIndex10;
                    _selectedImageIndex10 = -1;
                }
                if (_selectedImageIndex11 != -1) {
                    _selectedImageIndex10 = _selectedImageIndex11;
                    _selectedImageIndex11 = -1;
                }
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex1];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex2 = -1;
                _selectedCount--;
                
            }
        }else if (clickImageView.tag == _selectedImageIndex3) {
            //他に選択状態の画像のTagを再設定
            /*
            if (_selectedImageIndex4 != -1) {
                _selectedImageIndex3 = _selectedImageIndex4;
                _selectedImageIndex4 = -1;
                _selectedCount--;
            */
            if (_selectedImageIndex4 != -1) {
                _selectedImageIndex3 = _selectedImageIndex4;
                _selectedImageIndex4 = -1;
                if (_selectedImageIndex5 != -1) {
                    _selectedImageIndex4 = _selectedImageIndex5;
                    _selectedImageIndex5 = -1;
                }
                if (_selectedImageIndex6 != -1) {
                    _selectedImageIndex5 = _selectedImageIndex6;
                    _selectedImageIndex6 = -1;
                }
                if (_selectedImageIndex7 != -1) {
                    _selectedImageIndex6 = _selectedImageIndex7;
                    _selectedImageIndex7 = -1;
                }
                if (_selectedImageIndex8 != -1) {
                    _selectedImageIndex7 = _selectedImageIndex8;
                    _selectedImageIndex8 = -1;
                }
                if (_selectedImageIndex9 != -1) {
                    _selectedImageIndex8 = _selectedImageIndex9;
                    _selectedImageIndex9 = -1;
                }
                if (_selectedImageIndex10 != -1) {
                    _selectedImageIndex9 = _selectedImageIndex10;
                    _selectedImageIndex10 = -1;
                }
                if (_selectedImageIndex11 != -1) {
                    _selectedImageIndex10 = _selectedImageIndex11;
                    _selectedImageIndex11 = -1;
                }
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex2];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex3 = -1;
                _selectedCount--;
                
            }
        }else if (clickImageView.tag == _selectedImageIndex4) {
                //他に選択状態の画像のTagを再設定
                if (_selectedImageIndex5 != -1) {
                    _selectedImageIndex4 = _selectedImageIndex5;
                    _selectedImageIndex5 = -1;
                    if (_selectedImageIndex6 != -1) {
                        _selectedImageIndex5 = _selectedImageIndex6;
                        _selectedImageIndex6 = -1;
                    }
                    if (_selectedImageIndex7 != -1) {
                        _selectedImageIndex6 = _selectedImageIndex7;
                        _selectedImageIndex7 = -1;
                    }
                    if (_selectedImageIndex8 != -1) {
                        _selectedImageIndex7 = _selectedImageIndex8;
                        _selectedImageIndex8 = -1;
                    }
                    if (_selectedImageIndex9 != -1) {
                        _selectedImageIndex8 = _selectedImageIndex9;
                        _selectedImageIndex9 = -1;
                    }
                    if (_selectedImageIndex10 != -1) {
                        _selectedImageIndex9 = _selectedImageIndex10;
                        _selectedImageIndex10 = -1;
                    }
                    if (_selectedImageIndex11 != -1) {
                        _selectedImageIndex10 = _selectedImageIndex11;
                        _selectedImageIndex11 = -1;
                    }
                    if (_selectedImageIndex12 != -1) {
                        _selectedImageIndex11 = _selectedImageIndex12;
                        _selectedImageIndex12 = -1;
                    }
                    _selectedCount--;
                }else{
                    //自分が赤枠の場合
                    //一つ前の画像を赤枠状態にする
                    imgView = [self getClickImageViewByTag:_selectedImageIndex3];
                    if (imgView)
                    {
                        [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                    }
                    //非選択状態にする
                    _selectedImageIndex4 = -1;
                    _selectedCount--;
                    
                }
        }else if (clickImageView.tag == _selectedImageIndex5) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex6 != -1) {
                _selectedImageIndex5 = _selectedImageIndex6;
                _selectedImageIndex6 = -1;
                if (_selectedImageIndex7 != -1) {
                    _selectedImageIndex6 = _selectedImageIndex7;
                    _selectedImageIndex7 = -1;
                }
                if (_selectedImageIndex8 != -1) {
                    _selectedImageIndex7 = _selectedImageIndex8;
                    _selectedImageIndex8 = -1;
                }
                if (_selectedImageIndex9 != -1) {
                    _selectedImageIndex8 = _selectedImageIndex9;
                    _selectedImageIndex9 = -1;
                }
                if (_selectedImageIndex10 != -1) {
                    _selectedImageIndex9 = _selectedImageIndex10;
                    _selectedImageIndex10 = -1;
                }
                if (_selectedImageIndex11 != -1) {
                    _selectedImageIndex10 = _selectedImageIndex11;
                    _selectedImageIndex11 = -1;
                }
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex4];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex5 = -1;
                _selectedCount--;
            }
        }else if (clickImageView.tag == _selectedImageIndex6) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex7 != -1) {
                _selectedImageIndex6 = _selectedImageIndex7;
                _selectedImageIndex7 = -1;
                if (_selectedImageIndex8 != -1) {
                    _selectedImageIndex7 = _selectedImageIndex8;
                    _selectedImageIndex8 = -1;
                }
                if (_selectedImageIndex9 != -1) {
                    _selectedImageIndex8 = _selectedImageIndex9;
                    _selectedImageIndex9 = -1;
                }
                if (_selectedImageIndex10 != -1) {
                    _selectedImageIndex9 = _selectedImageIndex10;
                    _selectedImageIndex10 = -1;
                }
                if (_selectedImageIndex11 != -1) {
                    _selectedImageIndex10 = _selectedImageIndex11;
                    _selectedImageIndex11 = -1;
                }
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex5];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex6 = -1;
                _selectedCount--;
                
            }
            
        }else if (clickImageView.tag == _selectedImageIndex7) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex8 != -1) {
                _selectedImageIndex7 = _selectedImageIndex8;
                _selectedImageIndex8 = -1;
                if (_selectedImageIndex9 != -1) {
                    _selectedImageIndex8 = _selectedImageIndex9;
                    _selectedImageIndex9 = -1;
                }
                if (_selectedImageIndex10 != -1) {
                    _selectedImageIndex9 = _selectedImageIndex10;
                    _selectedImageIndex10 = -1;
                }
                if (_selectedImageIndex11 != -1) {
                    _selectedImageIndex10 = _selectedImageIndex11;
                    _selectedImageIndex11 = -1;
                }
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex6];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex7 = -1;
                _selectedCount--;
            }
        }else if (clickImageView.tag == _selectedImageIndex8) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex9 != -1) {
                _selectedImageIndex8 = _selectedImageIndex9;
                _selectedImageIndex9 = -1;
                if (_selectedImageIndex10 != -1) {
                    _selectedImageIndex9 = _selectedImageIndex10;
                    _selectedImageIndex10 = -1;
                }
                if (_selectedImageIndex11 != -1) {
                    _selectedImageIndex10 = _selectedImageIndex11;
                    _selectedImageIndex11 = -1;
                }
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex7];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex8 = -1;
                _selectedCount--;
                
            }
        }else if (clickImageView.tag == _selectedImageIndex9) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex10 != -1) {
                _selectedImageIndex9 = _selectedImageIndex10;
                _selectedImageIndex10 = -1;
                if (_selectedImageIndex11 != -1) {
                    _selectedImageIndex10 = _selectedImageIndex11;
                    _selectedImageIndex11 = -1;
                }
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex8];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex9 = -1;
                _selectedCount--;
                
            }
        }else if (clickImageView.tag == _selectedImageIndex10) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex11 != -1) {
                _selectedImageIndex10 = _selectedImageIndex11;
                _selectedImageIndex11 = -1;
                if (_selectedImageIndex12 != -1) {
                    _selectedImageIndex11 = _selectedImageIndex12;
                    _selectedImageIndex12 = -1;
                }
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex9];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex10 = -1;
                _selectedCount--;
                
            }
        }else if (clickImageView.tag == _selectedImageIndex11) {
            //他に選択状態の画像のTagを再設定
            if (_selectedImageIndex12 != -1) {
                _selectedImageIndex11 = _selectedImageIndex12;
                _selectedImageIndex12 = -1;
                _selectedCount--;
            }else{
                //自分が赤枠の場合
                //一つ前の画像を赤枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex10];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
                }
                //非選択状態にする
                _selectedImageIndex11 = -1;
                _selectedCount--;
                
            }
        }else if (clickImageView.tag == _selectedImageIndex12) {
            //自分が赤枠の場合
            //一つ前の画像を赤枠状態にする
            imgView = [self getClickImageViewByTag:_selectedImageIndex11];
            if (imgView)
            {
                [imgView setSelected:YES frameColor:[UIColor redColor] numberSelected:0];
            }
            //非選択状態にする
            _selectedImageIndex12 = -1;
            _selectedCount--;
        }
        
        if([[clickImageView.subviews objectAtIndex:5] isKindOfClass:[UIImageView class]]){
            UIImageView *imageView = [clickImageView.subviews objectAtIndex:5];
            for (OKDClickImageView* imgVw in _drawView.subviews)
            {
                [imgVw setImageNumber:(int)imageView.tag];
            }
            [[clickImageView.subviews objectAtIndex:5]removeFromSuperview];
        }
    }else{
        //選択されている画像カウントチェック
        switch (_selectedCount) {
            case 0:
                // 新たな画像を選択された場合
                _selectedImageIndex1 = clickImageView.tag;
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:1];
                break;
            case 1:
                //二枚目選択
                _selectedImageIndex2 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex1];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:2];
                break;
            case 2:
                //三枚目選択
                _selectedImageIndex3 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex2];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:3];
                break;
            case 3:
                //四枚目選択
                _selectedImageIndex4 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex3];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor]numberSelected:4];
                break;
            case 4:
                _selectedImageIndex5 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex4];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:5];
                break;
            case 5:
                _selectedImageIndex6 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex5];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:6];
                break;
            case 6:
                _selectedImageIndex7 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex6];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:7];
                break;
            case 7:
                _selectedImageIndex8 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex7];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:8];
                break;
            case 8:
                _selectedImageIndex9 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex8];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:9];
                break;
            case 9:
                _selectedImageIndex10 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex9];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:10];
                break;
            case 10:
                _selectedImageIndex11 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex10];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:11];
                break;
            case 11:
                _selectedImageIndex12 = clickImageView.tag;
                //一つ前の画像を青枠状態にする
                imgView = [self getClickImageViewByTag:_selectedImageIndex11];
                if (imgView)
                {
                    [imgView setSelected:YES frameColor:[UIColor blueColor] numberSelected:0];
                }
                _selectedCount++;
                [clickImageView setSelected:YES frameColor:[UIColor redColor] numberSelected:12];
                break;
            default:
                [Common showDialogWithTitle:@"" message:@"選択できる画像は12枚までです"];
                [clickImageView setIsSelected:NO];
                break;
        }
    }

	// １枚選択時のみ重ね合わせカメラを有効にする
	[self setOverlayCameraButonEnable: (_selectedCount == 1)];
    // facebook投稿ボタンを有効にする
    if([AccountManager isFaceBook])
        [self setFacebookUpButonEnable: (_selectedCount == 1)];
    

    // 2枚選択時のみ透過・重ね合わせボタンを有効にする
    [self setAbreastOverlapButonEnable:(_selectedCount == 2)];
    
    // 2枚~12枚選択時のみモーフィングボタンを有効にする
    if(_selectedCount > 2) {
       [self setMorphingButonEnable:(_selectedCount > 2 && _selectedCount < 13)];
    }
    
	/*
	// 選択されたTagIDをここで保存:_selectedTagID=1始まり
	_selectedTagID = clickImageView.tag + 1;
	*/
    //2012 /6/22 伊藤 連続しての画面遷移を防ぐための処理
    //画像の選択がない場合は右ページに遷移できない
    if (_selectedCount > 0) {
        [mainVC setScrollViewWidth:YES];
    }else {
        [mainVC setScrollViewWidth:NO];
    }
}

// 読み込みエラー画像tagセット
- (void)readErrorImage:(NSUInteger)tagID;
{
    [errorTags addObject:[NSNumber numberWithInteger:tagID]];
}

// エラー画像が含まれているかをチェック
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

// 写真描画画面へ遷移
- (void)OnPicturePaintView:(id)sender
{
    if (![self checkEnableTransition]) {
        return;
    }
    
	PicturePaintViewController *picturePaintVC
		= [[PicturePaintViewController alloc] 
#ifdef CALULU_IPHONE
			initWithNibName:@"ip_PicturePaintViewController" bundle:nil];
#else
			initWithNibName:@"PicturePaintViewController" bundle:nil];
#endif
	
	picturePaintVC.IsNavigationCall = YES;
	picturePaintVC.IsCompViewSkipped = YES;
	
	// 写真描画画面の表示
	[self.navigationController pushViewController:picturePaintVC animated:YES];

    // iOS7で時間を置かずに initWithPicture を呼ぶと、ViewDidLoadが終了していないため
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        // 写真描画の初期化
        [picturePaintVC initWithPicture:[self pictImage: _selectedImageIndex1]
						   userName:lblUserName.text nameColor:lblUserName.textColor
						   workDate:(lblWorkDate.hidden) ? nil : lblWorkDate.text];
        //	[picturePaintVC setUser:_userID];
        [picturePaintVC setWorkItemInfo:_userID workItemHistID:_histID];
        
        [picturePaintVC release];
	});

	_isPicturePaintDisplaied = YES;
}

// 写真合成画面へ遷移
- (void)OnPictureCompView:(id)sender
{
    if (![self checkEnableTransition]) {
        return;
    }
    
	PictureCompViewController  *pictureCompVC
	= [[PictureCompViewController alloc]
#ifdef CALULU_IPHONE
	   initWithNibName:@"ip_PictureCompViewController" bundle:nil];
#else
	   initWithNibName:@"PictureCompViewController" bundle:nil];
#endif

	pictureCompVC.IsSetLayout = YES;
	pictureCompVC.IsNavigationCall = YES;
	
	// 写真合成画面の表示
	[self.navigationController pushViewController:pictureCompVC animated:YES];

	[pictureCompVC setSkip:NO];
    // 2012 7/13 写真の透過合成
    pictureCompVC.IsOverlap = NO;
    pictureCompVC.IsUpdown = NO;
    pictureCompVC.IsMorphing = NO;
    if (btnOverlap.tag == 1) {
        pictureCompVC.IsOverlap = YES;
    }
    if (btnUpdown.tag == 1) {
        pictureCompVC.IsUpdown = YES;
    }
    
    if (btnMorphing.tag == 1) {
        pictureCompVC.IsMorphing = YES;
        [pictureCompVC setWorkItemInfo:_userID workItemHistID:_histID];
        [pictureCompVC setPictImageItems:[self setWkPictImageItems]];
        [pictureCompVC setCoordinateThumbnailList];
    }
    
    // Webカメラ画像の2つともHighの場合にメモリ不足になる為、合成の場合は
    // 解像度をMid以下にする
    UIImage *pict1 = [self pictImage: _selectedImageIndex1];
    UIImage *pict2 = [self pictImage: _selectedImageIndex2];
    if (pict1.size.width>WEB_CAM_MID_SIZE || pict1.size.height>WEB_CAM_MID_SIZE) {
        pict1 = [self resizeImage:pict1 maxSize:WEB_CAM_MID_SIZE];
    }
    if (pict2.size.width>WEB_CAM_MID_SIZE || pict2.size.height>WEB_CAM_MID_SIZE) {
        pict2 = [self resizeImage:pict2 maxSize:WEB_CAM_MID_SIZE];
    }
    // 写真の初期化
	[pictureCompVC initWithPicture:pict1
					 pictureImage2:pict2
						  userName:lblUserName.text nameColor:lblUserName.textColor
						  workDate:(lblWorkDate.hidden) ? nil : lblWorkDate.text];

	// 施術情報の設定
	[pictureCompVC setWorkItemInfo:_userID workItemHistID:_histID];
	
	[pictureCompVC release];
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
    // メモリ不足の場合次画面への遷移を抑制する
    if (![self checkEnableTransition]) return;

	// 左方向のフリック；写真描画画面に遷移
	if (self.isFlickEnable)
	{	
        // 読み込み失敗画像が選択されている場合、次の画面に遷移しない
        if ([self checkReadError:(_selectedCount==1)]) {
            [self pageMoveAlert];
            return;
        }
		if (_selectedCount >= 2)
		{
            if (btnMorphing.tag == 1){
                 [self OnPictureCompView:nil];
            }else{
                if (_selectedCount == 2){
                    [self OnPictureCompView:nil];
                }
            }
		}
		else if (_selectedCount == 1)
		{
			[self OnPicturePaintView:nil]; 
		}
	}
}

#pragma mark-
#pragma mark public_methods

// mail機能の有効
- (void) setMailEnableIsFlag:(BOOL)isEnable
{
//    BOOL isHidden = ! isEnable;
//    
//    btnMailSend.hidden = isHidden;
    
    [self setMailSendButonEnable:isEnable];
}

#pragma mark UIFlickerButtonDelegate
// フリックイベント
- (void)OnFlicked:(id)sender flickState:(FLICK_STATE)state
{
	// tagより選択番号を取り除く
	NSInteger tag = (((UIFlickerButton*)sender).tag) & 0xffff;
	
	switch (tag)
	{
		case FLICK_NEXT_PREV_VIEW:
			// 画面遷移
			switch (state) {
				case FLICK_RIGHT:
					// 右方向のフリック:前画面に戻る
					if (self.isFlickEnable)
					{	[self OnSelectPictView]; }
					break;
				case FLICK_LEFT:
				{
					// 左方向のフリック；写真描画画面に遷移
					if (self.isFlickEnable)
					{	[self OnPicturePaintView:sender];}
					
					// 選択されたTagIDをここで保存
					NSUInteger tagID = (((UIFlickerButton*)sender).tag);
					_selectedTagID 
						= (NSUInteger)((tagID >> SELECT_NUMBER_SHIFT_BIT) & 0xffff);
						// NSLog (@"OnOKDClickImageViewSelected at tagID:%d", _selectedTagID);
				}
				default:
					break;
			} 
			break;
		default:
			break;
	}
}

// ダブルタップイベント
- (void)OnDoubleTap:(id)sender
{
	// tagより選択番号を取り除く
	NSInteger tag = (((UIFlickerButton*)sender).tag) & 0xffff;
		
	switch (tag)
	{
		case FLICK_NEXT_PREV_VIEW:
			// 前画面に戻る
			// [self OnSelectPictView];
			// 左方向のフリック；写真描画画面に遷移
			[self OnPicturePaintView:sender];
			break;
		default:
			break;
	}
}

// 長押しイベント
- (void)OnLongTouchDown:(id)sender
{
	
}

- (NSMutableArray *) getSelectImages
{
    //選択されている画像を取得して配列に追加
    NSMutableArray *selectPictItems = [NSMutableArray array];
    UIImage *selectImage;
    if (_selectedImageIndex1 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex1)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex2 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex2)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex3 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex3)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex4 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex4)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex5 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex5)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex6 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex6)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex7 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex7)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex8 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex8)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex9 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex9)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex10 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex10)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex11 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex11)];
        [selectPictItems addObject:selectImage];
    }
    if (_selectedImageIndex12 != -1) {
        selectImage = (UIImage*)[pictImageItems objectAtIndex:(_selectedImageIndex12)];
        [selectPictItems addObject:selectImage];
    }
    
    return selectPictItems;
}

- (IBAction)OnMailSend {
    // WebMailオプション契約が無い場合
#ifdef WEB_MAIL_FUNC
    if(![AccountManager isWebMail]) return;
#endif
    // 画面の縦横を取得
//    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    //選択されている画像を取得して配列に追加
    NSMutableArray *selectPictItems = [self getSelectImages];

#ifndef WEB_MAIL_FUNC
    //smtpの設定がされているかチェック
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *infoBeanArray = [manager selectMailSmtpInfo:1];
    if([infoBeanArray count] != 0){
#endif
        //smtpを設定済み
        // ユーザ情報編集のViewControllerのインスタンス生成
        vcMailSend
        = [[MailSendPopUp alloc] initWithMailSetting:selectPictItems
                                        selectUserID:_userID
                                        selectHistID:_histID
                                           pictIndex:_selectedImageIndex1
                                             popUpID:POPUP_EDIT_IMAGE_PROFILE
                                            callBack:self];
        
        // MainViewControllerの取得
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC viewScrollLock:YES];
        self.view.userInteractionEnabled = NO;
        
        //メール送信画面を表示
        popoverCntlMailSend =
        [[UIPopoverController alloc] initWithContentViewController:vcMailSend];
        vcMailSend.popoverController = popoverCntlMailSend;
        [popoverCntlMailSend presentPopoverFromRect:btnMailSend.bounds
                                             inView:btnMailSend
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                           animated:YES];
        [popoverCntlMailSend setPopoverContentSize:CGSizeMake(588.0f, 553.0f)];
        
        //画面外をタップしてもポップアップが閉じないようにする処理
        NSMutableArray *viewCof = [[NSMutableArray alloc]init];
        
        [viewCof addObject:mainVC.view];
        [viewCof addObject:self.view];
        // isNavigationCallの呼び出し時のみ
        if(self.isNavigationCall)
            [viewCof addObject:super.navigationController.view];
        popoverCntlMailSend.passthroughViews = viewCof;
        [viewCof release];
        [vcMailSend release];
        [popoverCntlMailSend release];
#ifndef WEB_MAIL_FUNC
    }else{
        //smtpを未設定
        SetUpSmtpPopUp *setupSmtpViewController = [[SetUpSmtpPopUp alloc]initWithSmtpSetting:0x8010
                                                                                    callBack:self];
        
        // MainViewControllerの取得
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC viewScrollLock:YES];
        self.view.userInteractionEnabled = NO;
        
        //Smtp設定画面表示
        popoverCntlMailSend =
        [[UIPopoverController alloc] initWithContentViewController:setupSmtpViewController];
        setupSmtpViewController.popoverController = popoverCntlMailSend;
        [popoverCntlMailSend presentPopoverFromRect:btnMailSend.bounds
                                             inView:btnMailSend
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                           animated:YES];
        
        //画面外をタップしてもポップアップが閉じないようにする処理
        NSMutableArray *viewCof = [[NSMutableArray alloc]init];
        
        [viewCof addObject:mainVC.view];
        [viewCof addObject:self.view];
        popoverCntlMailSend.passthroughViews = viewCof;
        [viewCof release];
        [popoverCntlMailSend release];
    }
#endif
    
//    if(orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown) {
//        vcMailSend.popoverController = popoverCntlMailSend;
//        [popoverCntlMailSend presentPopoverFromRect:btnMailSend.bounds
//                                             inView:btnMailSend
//                           permittedArrowDirections:UIPopoverArrowDirectionUp
//                                           animated:YES];
//    } else {
        
//    }

#ifdef AAAA
    CTCoreMessage *testMsg = [[CTCoreMessage alloc] init];
    [testMsg setTo:[NSSet setWithObject:[CTCoreAddress addressWithName:@"GNishijima" email:@"kz.jima@gmail.com"]]];
    [testMsg setFrom:[NSSet setWithObject:[CTCoreAddress addressWithName:@"Calulu4BMK" email:@"notify@calulu4bmk.jp"]]];
    [testMsg setBody:@"テストメールの本文です"];
    [testMsg setSubject:@"This is a subject"];

    // 選択中の画像を取得
    UIImage *image = ([pictImageItems count ] > 0)?
    (UIImage*)[pictImageItem/Users/macbook/Developper/iPhoneSDK/src/okada_denshi/CaLuLu/calulu_pattoru/Classes/UserInfoListViewController.xibs objectAtIndex:_selectedImageIndex1] : nil;
    // UIImageをJpeg化して、NSDATAに入れる
    NSData *jpgData = UIImageJPEGRepresentation(image, 0.8);
    NSString *contentType = @"application/octet-stream";
    
    CTCoreAttachment *attach = [[CTCoreAttachment alloc] initWithData:jpgData contentType:contentType filename:@"attach01.jpg"];
    
    [testMsg addAttachment:attach];
    
    NSError *error = nil;
    BOOL success = [CTSMTPConnection sendMessage:testMsg
                                          server:@"smtp.calulu4bmk.jp"
                                        username:@"notify@calulu4bmk.jp"
                                        password:@"aNXMgbDT"
                                            port:587
                                  connectionType:CTSMTPConnectionTypePlain
                                         useAuth:YES
                                           error:&error];
    if (!success) {
        NSLog(@"Mail send Error");
        // Present the error
    }
#endif
}

// ScrollView delegate 横画面時のスワイプ用
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    // 表示画像数
    NSInteger imgConunt = [pictImageItems count];
    // 横表示の個数
    imgConunt = ((imgConunt + 1) / 2) - 3;
    imgConunt = (imgConunt < 0)? 0 : imgConunt;

    if(scrollView.contentOffset.x < (0 - 30)) {
//        NSLog(@"right [%f]", scrollView.contentOffset.x);
        [self OnSwipeRightView:nil];
    } else if (scrollView.contentOffset.x > ((320 * imgConunt) + 40)) {
//        NSLog(@"left [%f]", scrollView.contentOffset.x);
        [self OnSwipeLeftView:nil];
    }
}

#pragma mark PopUpView Delegate
/**
 * ポップアップ画面を閉じる時に呼ばれるDelegate処理
 * (ポップアップ表示時にスクロールロックをしているので、解除を行う)
 */
- (void) OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    self.view.userInteractionEnabled = YES;
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:NO];
    
    if (popUpID==MAILSEND_POPUP_ID) {
        // 個別メール送信時に、既読情報を取りに行く
        GetWebMailUserStatus *getStatus = [[GetWebMailUserStatus alloc] initWithDelegate:self];
        [getStatus getStatus:_userID];
        [getStatus release];
    }
    
    vcMailSend = nil;
    vcSwimmy = nil;
}

/**
 * 個別メール送信終了時、即座にメールステータスを反映させる
 */
- (void)finishedGetWebMailUserStatus:(USERID_INT)_userId
							  unread:(NSInteger)unread
						  userUnread:(NSInteger)userUnread
							   check:(NSInteger)check
				  notification_error:(NSInteger)notification_error
						   exception:(NSException *)exception
{
    if (exception == nil) {
        // 一件のユーザWebMailステータスを即時更新する
        WebMailUserStatus *status = [[WebMailUserStatus alloc] init];
        status.userId = _userId;
        status.unread = unread;
        status.userUnread = userUnread;
        status.check = check;
        status.notification_error = notification_error;
        
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        UIViewController *vc
        = [ mainVC getVC4ViewControllersWithClass:[UserInfoListViewController class]];
        if (vc)
        {   [(UserInfoListViewController*)vc setWebMailUserStatus:status UserID:_userId]; }
        
        [status release];
    }
}

// DELC SASAGE PictImageItemsと添字からUIImage取得
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

- (IBAction)OnSwimmy:(id)sender {

    // 選択画像の取得
    NSMutableArray *selectPictItems = [self getSelectImages];
    
    if ([selectPictItems count]>2)
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Swimmy"
                                  message:@"スイミー送信は１度に２枚以上できません。"
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil
                                  ];
        [alertView show];
        [alertView release];
        
        return;
    }
    
    id temp = nil;
    if(self.isNavigationCall)
        temp = super.navigationController.view;

    // ユーザ情報編集のViewControllerのインスタンス生成
    vcSwimmy
    = [[SwimmyPopUp alloc]initWithSwimmySetting:selectPictItems
                                   selectUserID:_userID
                                        popUpID:POPUP_EDIT_IMAGE_PROFILE+20
                                   isNavigation:self.isNavigationCall
                                      superView:temp
                                       callBack:self];
    
    // MainViewControllerの取得
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:YES];
    self.view.userInteractionEnabled = NO;
    
    //メール送信画面を表示
    popoverCntlMailSend =
    [[UIPopoverController alloc] initWithContentViewController:vcSwimmy];
    vcSwimmy.popoverController = popoverCntlMailSend;
    
    [popoverCntlMailSend presentPopoverFromRect:btnSwimmy.bounds
                                         inView:btnSwimmy
                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                       animated:YES];
//    CGRect rect = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, 1, 1);
//
//    [popoverCntlMailSend presentPopoverFromRect:rect
//                                         inView:self.view
//                       permittedArrowDirections:UIPopoverArrowDirectionAny
//                                       animated:YES];

    [popoverCntlMailSend setPopoverContentSize:CGSizeMake(588.0f, 622.0f)];
    
    //画面外をタップしてもポップアップが閉じないようにする処理
    NSMutableArray *viewCof = [[NSMutableArray alloc]init];
    
    [viewCof addObject:mainVC.view];
    [viewCof addObject:self.view];
    // isNavigationCallの呼び出し時のみ
    if(self.isNavigationCall)
        [viewCof addObject:super.navigationController.view];
    popoverCntlMailSend.passthroughViews = viewCof;
    [viewCof release];
    [vcSwimmy release];
    [popoverCntlMailSend release];
}
@end
