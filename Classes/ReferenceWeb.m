//
//  ReferenceWeb.m
//  iPadCamera
//
//  Created by MacBook on 13/04/24.
//
//

#import "ReferenceWeb.h"

#import "Common.h"
#import "UtilHardCopySupport.h"     // 画面キャプチャのサポート
#import "MainViewController.h"      // ロック画面のサポート
#import "AccountManager.h"          // アカウントマネージャー

@interface ReferenceWeb (private_methods)

-(void)invokeNativeMethod: (NSURLRequest *)request;
-(void)closeWebViewWithAnimation:(BOOL)isAnimation;
-(void) viewAnimationWithShowFlag:(BOOL) isShow;
-(void) setSwipeGuestureWithSetup:(BOOL)isSetup;

@end

@implementation ReferenceWeb

#pragma mark private_methods

// Native処理を呼び出す
-(void)invokeNativeMethod: (NSURLRequest *)request
{
    // native://closeWebViewが指定された場合
    if ([request.URL.host isEqualToString:@"closeWebView"]) {
        [ self closeWebViewWithAnimation:YES ];
    }
    // native://showSystemInfoが指定された場合
    //    else if ([request.URL.host isEqualToString:@"showSystemInfo"]) {
    //        [ self showSystemInfo ];
    //    }
}

// WebViewを閉じる
-(void)_closeWebView
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    // [self.presentedViewController dismissModalViewControllerAnimated: YES];
    
    @try {
        // webViewを抜けるときにジェスチャーをすべて削除
        while (webView.superview.gestureRecognizers.count) {
            [webView.superview removeGestureRecognizer:[webView.superview.gestureRecognizers objectAtIndex:0]];
        }
        
        [prevWndView removeFromSuperview];
        [maskView removeFromSuperview];
        [webView removeFromSuperview];
        
        [maskView release];
        maskView = nil;
        
        [webView stopLoading];
        webView.delegate = nil;
        [webView release];
        webView = nil;
        
        prevWndView.image = nil;
        [prevWndView release];
        prevWndView = nil;
        
        [self.backUrl release];
        // self.backUrl = nil;
        
        _isFirstLoad = YES;

        // UIWebViewを回転しながら閉じると、MainViewControllerに回転イベントの通知が発生しなかったため
        // Closeイベントの通知を行い、処理を行うように修正
        // UILocalNotificationクラスのインスタンスを作成
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif == nil)
            return;
        
        // 通知を受け取るときに送付される NSDictionary を作成
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"WebView Close" forKey:@"EventKey"];
        localNotif.userInfo = infoDict;
        
        // 作成した通知イベント情報をアプリケーションに登録
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
        [localNotif release];
    }
    
    @catch (NSException *exception) {
        NSLog(@"_closeWebView Caught %@: %@", [exception name], [exception reason]);
    }
}

// WebViewを閉じる
-(void)closeWebViewWithAnimation:(BOOL)isAnimation;
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // 呼び出し元Viewサイズの復帰
    [parentView setFrame:temp_rect];
    
    [self setSwipeGuestureWithSetup:NO];
    
    if ([MainViewController isDisplayBottomModalDialog])
    {   [MainViewController closeLockWindow]; }
    
    if (isAnimation)
    { [self viewAnimationWithShowFlag:NO]; }
    else
    { [self _closeWebView]; }
}


// animation表示
-(void) viewAnimationWithShowFlag:(BOOL) isShow
{
    // webViewコントロールの幅分でスクロールイメージを作る
    CGFloat width = webView.frame.size.width;
    
    // 表示するときは早く見せる
    CGFloat time = (isShow)? 0.3f : 0.6f;
    
    [UIView animateWithDuration:time delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         // 最終移動地点
                         CGFloat xPos = (isShow)? 0.0f : width;
                         [webView setFrame:CGRectMake(xPos, 0.0f, width, webView.frame.size.height)];
                         
                     }
                     completion:^(BOOL finished) {
                         if ((! isShow) && (finished))
                         { [self _closeWebView]; }
                     }];

}

// スワイプジェスチャーのセットアップ
- (void) setSwipeGuestureWithSetup:(BOOL)isSetup
{
    // スワイプのセットアップ
	UISwipeGestureRecognizer *swipeGestue = [[UISwipeGestureRecognizer alloc]
											 initWithTarget:self action:@selector(OnSwipeRightView:)];
	swipeGestue.direction = UISwipeGestureRecognizerDirectionRight;
	swipeGestue.numberOfTouchesRequired = 1;
    if (isSetup)
	{   [webView.superview addGestureRecognizer:swipeGestue]; }     // ロック画面が非表示にできない場合を考慮
    else
    {   [webView.superview removeGestureRecognizer:swipeGestue]; }
    
	[swipeGestue release];
}

- (void) OnSwipeRightView:(id)sender
{
    
    if (! self.backUrl)
    {
        // 戻り先URLの指定がない　(=index.html)場合のは、WebViewを閉じる
        [self closeWebViewWithAnimation:YES];
    }
    else
    {
        NSString *query = ([self.backUrl isEqualToString:@"index"])?
            @"" : @"?back_page=index";

        // アカウントマネージャーより登録Web参考資料URLを取得する
        NSString *refurl = [AccountManager isReference];
        if(refurl==NULL)
            refurl = REFERENCE_PAGE_URL;
        
        // 戻り先URLに従う
        NSString *url = [NSString stringWithFormat:@"%@%@.html%@",
                         refurl, self.backUrl, query];
        NSURL *uurl = [NSURL URLWithString:url];
        NSURLRequest *req = [NSURLRequest requestWithURL:uurl];
        dispatch_async(dispatch_get_main_queue(), ^{
            { [webView loadRequest:req]; }
        });

    }
}

// 戻り先のURLをクエリより取得
- (NSString*) getBackUrlWithQuery:(NSString*)query
{
    if (! query)
    {   return (nil); }
    
    /*
               1         2         3         4
     01234567890123456789012345678901234567890123456789
     src=madoka-sokumen1.jpg&back_page=madoka_picture
     */
    
    NSArray *queries = [query componentsSeparatedByString:@"&"];
    if (! queries)
    {   return (nil); }
    
    NSString* url = nil;
    for (NSUInteger i = 0; i < [queries count]; i++)
    {
        NSString *aQuery = [queries objectAtIndex:i];
        NSRange range = [aQuery rangeOfString:@"back_page="];
        
        if (range.location != NSNotFound)
        {
            NSInteger pos = range.location + range.length;
            if (pos < [aQuery length])
            { url = [aQuery substringFromIndex:pos]; }
        }
    }
    
    return (url);
}

// 現在のページImage(画面キャプチャ)を取得
- (UIImage*) _getNowPageImage
{
    // 画面のキャプチャ
    UIImage *img = [UtilHardCopySupport getScreenCapture];
    
    // ステータスバー部分を除去 = ページ遷移アニメーション用ImageViewのコントロールサイズ
    ///////////////////////////////
    CGSize imgSize = prevWndView.frame.size;
    
#ifdef DEBUG
    NSLog(@"window capture size => %f x %f / dc size => %f x %f",
          img.size.width, img.size.height, imgSize.width, imgSize.height);
#endif
    
    // グラフィックコンテキストを画面全体からステータスバーを除いたサイズで作成
	UIGraphicsBeginImageContext
            (CGSizeMake(imgSize.width, imgSize.height));
    
    // グラフィックコンテキストに描画 ： 20.0f => ステータスバー高さ
    CGRect imgRect = CGRectMake(0.0f, -20.0f, imgSize.width, imgSize.height);
	[img drawInRect:imgRect];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
	return (image);
}

// ページ遷移アニメーションの開始
-(void) doPageAnimation
{
    // 最初にアニメーションImageViewを表示
    prevWndView.hidden = NO; 
    
    // 前画面が中央に集まる（縮小する）アニメーション
    CGSize sz = prevWndView.frame.size;
    CGRect targetRect = CGRectMake(sz.width/2, sz.height/2, 10.0f, 10.0f);
    
    [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         // 最終移動地点
                         [prevWndView setFrame:targetRect];
                         prevWndView.alpha = 0.3f;
                     }
                     completion:^(BOOL finished) {
                         if (finished)
                         {
                             // アニメーション完了時にImageViewを非表示にする
                             prevWndView.image = nil;
                             prevWndView.hidden = YES;
                             prevWndView.alpha = 1.0f;
                         }
                     }];
}

#pragma mark life_cycle

- (id)init
{
    if ((self = [super init]))
    {
        webView = nil;
        maskView = nil;
        prevWndView = nil;
        self.backUrl = nil;
        
        webAccessFlag = NO;
    }
    
    return (self);
}

- (void)dealloc {

    [self _closeWebView];
    
    [super dealloc];
}

#pragma mark  UIWebViewDelegate

// WebViewでリクエストが読み込まれた時に呼ばれるイベント
-(BOOL)webView:(UIWebView *)_webView shouldStartLoadWithRequest:(NSURLRequest *)request
                                    navigationType:(UIWebViewNavigationType)navigationType
{
    // schemeがnativeの場合は、処理をフックしてNative処理を呼び出す
    if ([ request.URL.scheme isEqualToString:@"native" ]) {
        // フック処理
        [ self invokeNativeMethod: request ];
        
        // WebViewの読み込みは中断する。
        return NO;
    }
    // 通常のschemeの場合は、フックせずそのまま処理を続ける
    else {
#ifdef DEBUG
        NSLog(@"request web page => %@ query => %@",
            [[request URL] path], [[request URL] query]);
        NSLog(@"request web navigation type => %ld", (long)navigationType);
#endif
        // 戻り先のURLを保存
        if (! _isFirstLoad)
        {   self.backUrl = [self getBackUrlWithQuery:[[request URL] query]]; }
        
        // デバイス回転によるリクエストか？
        _isReqest2Rotataiton = (navigationType == UIWebViewNavigationTypeReload);
        
        // アニメーション用に現在のページImage(画面キャプチャ)を表示
        if (! _isFirstLoad)
        {
            [prevWndView setFrame:webView.frame];
            prevWndView.image = [self _getNowPageImage];
        }
        
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
#ifdef DEBUG
    // NSLog(@"webViewDidStartLoad");
#endif
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // リクエスト完了フラグの初期化
    _isRequestCompleted = NO;
    
    webAccessFlag = YES;
    
    // Mainスレッドにて遅延処理でロック画面を表示
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (! _isRequestCompleted && webAccessFlag) {
            maskView.hidden = YES;
            [MainViewController showMessagePopupWithMessage:@"参考資料の情報を取得しています....."];
        }
    });
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
#ifdef DEBUG
    // NSLog(@"webViewDidFinishLoad");
#endif
    
     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // ページ遷移アニメーションの開始 => 但し、デバイス回転によるリクエストは除く
    if ( (! _isFirstLoad) && (! _isReqest2Rotataiton) )
    {   [self doPageAnimation]; }
    
    // 初回ページロードフラグを解除
    _isFirstLoad = NO;
    
    // リクエスト完了フラグのセット
    _isRequestCompleted = YES;
    
    if ([MainViewController isDisplayBottomModalDialog])
    {
        // ロック画面が表示されていれば非表示にする
        [MainViewController closeLockWindow];
        maskView.hidden = NO;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"web view error => %@, code => %ld",
              [error localizedDescription], (long)error.code);
    }
    
    /* he operation couldn’t be completed. (NSURLErrorDomain error -999.) 対応　*/
    if (error.code == -999)
    {   return; }
    
    webAccessFlag = NO;
    
    [Common showDialogWithTitle:@"参考資料"
                        message:@"コンテンツ（画面）が\n表示できませんでした\n\n(ネットワークの接続を\n確認願います)"];
    
    [self closeWebViewWithAnimation:NO];
}

#pragma mark public_methods

// 参考資料Webページ表示
-(void) showReferencePageWithParent:(UIView*)myview
{
    NSString *refurl = [AccountManager isReference];
#ifdef DEBUG
    NSLog(@"ref_url[%@]", refurl);
    NSLog(@"ref_default[%@]", REFERENCE_PAGE_URL);
#endif
    if(refurl==NULL)
        refurl = REFERENCE_PAGE_URL;
    [self showWebPage:refurl parentView:myview];
    
    BOOL isPortrait;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
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
    
    [self _refresh:isPortrait];
    
}

- (void)showWebPage:(NSString *)url parentView:(UIView*)myview
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    // iOS7以降の場合のUI調整
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = (iOSVersion<7.0f)? 0.0f : 20.0f;

    temp_rect = myview.frame;   // 元画面サイズ保存
    parentView = myview;        // 呼び出し元Viewの保存
    CGRect webrect = myview.frame;
    webrect.origin.y += uiOffset;
    webrect.size.height -= uiOffset;
    
    [myview setFrame:webrect];
    
    // マスクViewの設置
    maskView = [[UIView alloc]initWithFrame:webrect];
    [maskView setBackgroundColor:[UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:0.5f]];
    [myview addSubview:maskView];
    
    // ネットワーク接続の確認を行う
    

    // アニメーション用に初期表示位置をずらす
    webView = [[UIWebView alloc] initWithFrame:webrect];
   
    [webView setDelegate:self];
    [myview addSubview:webView];
    webView.scalesPageToFit = YES;
    
    [webView setBackgroundColor:[UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:0.5f]];
    [webView setOpaque:NO];
    
    webView.scrollView.bounces = NO;
    webView.scrollView.bouncesZoom = NO;
    
    // ページ遷移アニメーション用ImageViewの作成
    prevWndView = [[UIImageView alloc]initWithFrame:webrect];
    [prevWndView setBackgroundColor:[UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.0f]];
    [myview addSubview:prevWndView];
    prevWndView.hidden = YES;
    
    // 初回ページロードフラグの設定
    _isFirstLoad = YES;
    
    // リクエスト完了フラグのセット
    _isRequestCompleted = YES;
    
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    // 初期ページ（index.html）の読み込み
    NSURL *uurl = [NSURL URLWithString:url];
    NSURLRequest *req = [NSURLRequest requestWithURL:uurl];
    dispatch_async(dispatch_get_main_queue(), ^{
       [webView loadRequest:req];
    });
    
    // アニメーション
    [self viewAnimationWithShowFlag:YES];
    
    [self setSwipeGuestureWithSetup:YES];
    
    }

- (void) refresh:(BOOL)isPortrait
{
 	// 非表示の場合は更新しない
//	if (self.hidden == YES)
//	{	return; }
    
#ifdef CALULU_IPHONE
	CGFloat scrWidth  = (isPortrait)? 320.0f : 480.0f;
	CGFloat scrHeigth = (isPortrait)? 460.0f : 300.0f;
#else
    CGFloat scrWidth  = (isPortrait)? 768.0f : 1024.0f;
	CGFloat scrHeigth = (isPortrait)? 1004.0f : 748.0f;
#endif
    
	// 本体のサイズ変更
//	[self setFrame:CGRectMake(0.0f, 0.0f, scrWidth, scrHeigth)];
    
	// ImageViewとボタンのサイズ変更
	CGFloat imgWidth;
	CGFloat imgHeight;
	if (isPortrait)
	{
#ifdef CALULU_IPHONE
		// Image縦長： 614 -> 960×(460 / 720)   画像の元サイズ(960×720)
		imgWidth  = (isPortrait)? 614.0f : 480.0f;
		imgHeight = (isPortrait)? 460.0f : 320.0f;
#else
        // Image縦長： 1365 -> 960×(1024 / 720)   画像の元サイズ(960×720)
		imgWidth  = (isPortrait)? 768.0f : 1024.0f;
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
		imgHeight = (isPortrait)? 480.0f : 748.0f;
#endif
	}
    
    // iOS7以降の場合のUI調整
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = (iOSVersion<7.0f)? 0.0f : 20.0f;
    
	CGFloat wm = (scrWidth - imgWidth) / 2.0f;
	CGFloat hm = (scrHeigth - imgHeight) / 2.0f;
	CGRect rect = CGRectMake(wm, hm + uiOffset, imgWidth, imgHeight);

	[webView setFrame:rect];
    [maskView setFrame:rect];
    [prevWndView setFrame:rect];

    // [webView reload];
}

- (void) _refresh:(BOOL)isPortrait
{
#ifdef CALULU_IPHONE
	CGFloat scrWidth  = (isPortrait)? 320.0f : 480.0f;
	CGFloat scrHeigth = (isPortrait)? 460.0f : 300.0f;
#else
    CGFloat scrWidth  = (isPortrait)? 768.0f : 1024.0f;
	CGFloat scrHeigth = (isPortrait)? 1004.0f : 748.0f;
#endif
    
	// ImageViewとボタンのサイズ変更
	CGFloat imgWidth;
	CGFloat imgHeight;
	if (isPortrait)
	{
#ifdef CALULU_IPHONE
		// Image縦長： 614 -> 960×(460 / 720)   画像の元サイズ(960×720)
		imgWidth  = (isPortrait)? 614.0f : 480.0f;
		imgHeight = (isPortrait)? 460.0f : 320.0f;
#else
        // Image縦長： 1365 -> 960×(1024 / 720)   画像の元サイズ(960×720)
		imgWidth  = (isPortrait)? 768.0f : 1024.0f;
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
		imgHeight = (isPortrait)? 480.0f : 748.0f;
#endif
	}
    
	CGFloat wm = (scrWidth - imgWidth) / 2.0f;
	CGFloat hm = (scrHeigth - imgHeight) / 2.0f;
	CGRect rect = CGRectMake(wm, hm, imgWidth, imgHeight);
    
	[webView setFrame:rect];
    [maskView setFrame:rect];
    [prevWndView setFrame:rect];
    
    temp_rect = rect;
}

-(void) reload
{
    //NSString* cururl = [webView stringByEvaluatingJavaScriptFromString:@"document.URL"];
    //[self showWebPage:cururl :nil];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [webView reloadInputViews];
    [webView reload];
}

@end
