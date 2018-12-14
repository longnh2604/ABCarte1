    //
//  MainViewController.m
//  iPadCamera
//
//  Created by MacBook on 11/04/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"

//#import "iPadCameraViewController.h"
#import "UserInfoListViewController.h"
#import "HistListViewController.h"
#import "HistDetailViewController.h"

#import "SecurityManagerView.h"
#import "PcBackupViewController.h"

#import "defines.h"

#ifdef USE_ACCOUNT_MANAGER
#import "AccountManager.h"
#endif

#import "iPadCameraAppDelegate.h"
#import "UIBottomDialogController.h"

#import "LockWindowPoupup.h"

// #ifdef AIKI_CUSTOM
#import "OKDFullScreenImageView.h"
#import "userFmdbManager.h"
// #endif

#import "EditVideoViewController.h"
#import "PictureCompViewController.h"
#import "PicturePaintViewController.h"

// #import "UICancelableScrollView.h"

static BOOL _____dbdownloadEnd_____;

@implementation MainViewController

@synthesize colorIndex;
@synthesize beforeInterfaceOrient;

#pragma mark local_methods

// ScrollViewの初期化
- (void)initScrollView
{
    pageControl.numberOfPages = PAGE_NUMS;

	// scrollView.pagingEnabled = YES;

    // デバイスの向きを取得
    int direction = self.interfaceOrientation;
    BOOL isPortrait = YES;
    if((direction == UIInterfaceOrientationPortrait) ||          // NSLog(@"縦(ホームボタン下)");
       (direction == UIInterfaceOrientationPortraitUpsideDown))  // NSLog(@"縦(ホームボタン上)");
    {
        isPortrait = YES;
    }
    else if((direction == UIInterfaceOrientationLandscapeLeft) || // NSLog(@"横(ホームボタン左)");
            (direction == UIInterfaceOrientationLandscapeRight))  // NSLog(@"横(ホームボタン右)");
    {
        isPortrait = NO;
    }
	CGFloat width  = (isPortrait)? VIEW_SIZE_WIDTH : (VIEW_SIZE_HEIGHT + STATUS_BAR_HEIGHT);
	CGFloat height = (isPortrait)? VIEW_SIZE_HEIGHT : (VIEW_SIZE_WIDTH - STATUS_BAR_HEIGHT);
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion<7.0) {
        scrollView.frame = CGRectMake(0.0f, 0.0f, width, height);
    } else {
        scrollView.frame = CGRectMake(0.0f, 20.0f, width, height);
    }

	scrollView.contentSize
	= CGSizeMake(scrollView.frame.size.width * 4 /*(CGFloat)PAGE_NUMS*/, 
				 scrollView.frame.size.height);
   
	scrollView.showsHorizontalScrollIndicator = NO;  
	scrollView.showsVerticalScrollIndicator = NO; 
	scrollView.delegate = self;
    scrollView.chacelableDelegate = self;
	
    //pagecontrol dot size
    pageControl.transform = CGAffineTransformMakeScale(1.5, 1.5);
    pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0/255.0f green:71/255.0f blue:157/255.0f alpha:1.0f];
    pageControl.currentPageIndicatorTintColor = [UIColor redColor];
	// scrollViewWidth = 768.0f;
}

// 初期表示のViewをLoadする
- (UIViewController*) loadFirstView
{
#ifndef CLOUD_SYNC
#ifdef CALULU_IPHONE
	NSString *nibName = @"ip_UserInfoListViewController";
#else
	NSString *nibName = @"UserInfoListViewController";
#endif
#else
#ifdef DEF_ABCARTE
	NSString *nibName = @"UserInfoListViewController_Cloud";
#elif CALULU_IPHONE
	NSString *nibName = @"ip_UserInfoListViewController";
#else
	NSString *nibName = @"SyncCloud_UserInfoListViewController";
#endif
#endif	
	UIViewController *vc  
		= [[UserInfoListViewController alloc] 
			initWithNibName:nibName bundle:nil];

	return (vc);
}

// viewをScrollViewに加える
- (void)addViewWithViewController:(UIViewController*)vc page:(NSInteger)page {
    
    if (! vc)
    {   return; }
	
	// Viewcontlloerのリストをここで加える
	[viewControllers addObject:vc];
    	
	UIView *loadView = vc.view;
	loadView.tag = page;
	
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
	
    loadView.frame = frame;
	
    // [contentView addSubview:loadView];
	[scrollView addSubview:loadView];
    
	loadView = nil;

	// [vc autorelease];
	// vc = nil;
#ifdef DEBUG
	NSLog (@"VC ref counter:%ld", (long)[vc retainCount]);
#endif
}

// viewのload
- (void)loadScrollViewWithPage:(NSInteger)page {
    
    if ( (page < 0) || (page >= PAGE_NUMS) ) 
        return;
    
    UIViewController *vc  = nil;
    
	switch (page)
    {
        case 0:
			vc = [[UserInfoListViewController alloc] 
				  initWithNibName:@"UserInfoListViewController" bundle:nil];
            break;
		case 1:
			vc = [[HistListViewController alloc] 
#ifdef CALULU_IPHONE
				  initWithNibName:@"ip_HistListViewController" bundle:nil];
#else
                  initWithNibName:@"HistListViewController" bundle:nil];
#endif
			break;
		case 2:
            vc = [[HistDetailViewController alloc] 
#ifdef CALULU_IPHONE
				  initWithNibName:@"ip_HistDetailViewController" bundle:nil ];
#else
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
                  initWithNibName:@"HistDetailForGrantViewController" bundle:nil];
#else
                  initWithNibName:@"HistDetailViewController" bundle:nil];
#endif
#endif
            break;
		default:
			break;
    }
    
    if (! vc)
    {   return; }
	
	// Viewcontlloerのリストをここで加える
	[viewControllers addObject:vc];
	
	UIView *loadView = vc.view;
	loadView.tag = page;
	
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
	
    loadView.frame = frame;
	
    // [contentView addSubview:loadView];
	[scrollView addSubview:loadView];
    
	loadView = nil;
	
	[vc release];
	// vc = nil;
}

// タップジェスチャーのセットアップ
- (void) tapGestureSupport
{
	// タップのセットアップ：セキュリティ画面　指２本で有効
	UITapGestureRecognizer *tapGesture 
		= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnSecurityShow)];
	tapGesture.numberOfTouchesRequired = 2;		// 指２本
	tapGesture.numberOfTapsRequired  = 2;		// ダブルタップ
	[self.view addGestureRecognizer:tapGesture];
	[tapGesture release];
}

// viewの配置
- (void)layoutView:(BOOL)isPortrait
{
	// scrollViewDidScrollがコールされてしまうので、阻止する
	scrollView.delegate = nil;
	
	// 以下のscrollViewの設定でcurrentPageが変わるので、ここで保存
	NSInteger curPage = pageControl.currentPage;
	
	// scrollViewの設定
	
	//CGFloat width  = (isPortrait)? 768.0f : 1024.0f;
	CGFloat width  = (isPortrait)? VIEW_SIZE_WIDTH : (VIEW_SIZE_HEIGHT + STATUS_BAR_HEIGHT);
		// CGFloat height = (isPortrait)? 794.0f : 538.0f; 
	// CGFloat height = (isPortrait)? 1004.0f : 748.0f;
	CGFloat height = (isPortrait)? VIEW_SIZE_HEIGHT : (VIEW_SIZE_WIDTH - STATUS_BAR_HEIGHT);

    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion<7.0) {
        scrollView.frame = CGRectMake(0.0f, 0.0f, width, height);
    } else {
        scrollView.frame = CGRectMake(0.0f, 20.0f, width, height);
    }
	scrollView.contentSize
		= CGSizeMake(width * (CGFloat)PAGE_NUMS, height);

	for (id loadView in scrollView.subviews)
	{
		CGFloat x = width * (((UIView*)loadView).tag);
		
		((UIView*)loadView).frame 
			= CGRectMake(x, 0.0f, width, height);
	}
	
#ifdef DEBUG
	NSLog (@"layoutView pageControl.currentPage:%ld scrview content_ofs:%f",
           (long)pageControl.currentPage, scrollView.contentOffset.x);
#endif
	scrollView.contentOffset
		= CGPointMake((CGFloat)(width * curPage), 0.0f);
	
	// scrollViewDidScrollのコールの阻止を解除する
	scrollView.delegate = self;
	
	//[self onChangePage:pageControl];
	
}

// 画面(View)の遷移
- (BOOL) transitionViewWithNewPage:(NSInteger)page
{
	if (nowViewIndex >= [viewControllers count])
	{	return (NO); }
	
	// 現在表示されているviewControllerを取得
	UIViewController *vc = [viewControllers objectAtIndex:nowViewIndex];
	
	// delegate(インターフェイス)を取得
	id<MainViewControllerDelegate> delegate = (id<MainViewControllerDelegate>)vc;
	
	BOOL isTransition = YES;

    // HistDetailViewController viewDidAppear が呼び出されない場合が有り、
    // SelectVideoViewController or SelectPictureViewController が残る場合が有るため
//    if (page==3 && [viewControllers count]==4) {
//        [self deleteViewControllersFromNextIndex];
//    }
	// 新たにViewを加えるかを確認
	if (page >= [viewControllers count])
	{
		// 実装を確認
		if (! [((NSObject*)delegate) respondsToSelector:@selector(OnTransitionNewView:)])
		{	return (YES);  }
		
		// 新規View画面への遷移
		UIViewController *nextVC = [delegate OnTransitionNewView:self];
		if (! nextVC)
		{	return (NO); }		// 画面遷移しない
		
		// 画面遷移するviewをScrollViewに加える
		[self addViewWithViewController:nextVC page:page];
		
		// ViewがLoadされた後のコール
		if ([((NSObject*)delegate) respondsToSelector:@selector(OnTransitionNewViewDidLoad:transitionVC:)])
		{	
			[delegate OnTransitionNewViewDidLoad:self transitionVC:nextVC];  
		}
	}
	else 
	{
		// ページ関係の妥当性をチェック
		if ( (page - nowViewIndex) != 1)
		{	return (NO); }
		
		// 実装を確認
		if (! [((NSObject*)delegate) respondsToSelector:@selector(OnTransitionExsitView:transitionVC:)])
		{	return (YES);  }
		
		// 遷移先の既存Viewを取得
		UIViewController *tVC = [viewControllers objectAtIndex:page];
		
		// 既存View画面への遷移
		isTransition = [delegate OnTransitionExsitView:self transitionVC:tVC];
	}

	return (isTransition);
}

// 現在の表示画面(View)を閉じる
- (BOOL) unloadViewSend
{
	if (nowViewIndex >= [viewControllers count])
	{	return (NO); }
	
	BOOL isTransition = YES;
	// 現在表示されているviewControllerを取得
	UIViewController *vc = [viewControllers objectAtIndex:nowViewIndex];
	
	// delegate(インターフェイス)を取得
	id<MainViewControllerDelegate> delegate = (id<MainViewControllerDelegate>)vc;

	if ([((NSObject*)delegate) respondsToSelector:@selector(OnUnloadView:)])
	{
		// 実装を確認して画面終了の通知
		isTransition = [delegate OnUnloadView:self];
	}
	
	return (isTransition);
	
	// scrollViewから現在表示viewを削除
	// [vc.view removeFromSuperview];
	// NSLog (@"VC ref counter:%d at removeFromSuperview", [vc retainCount]);
		
	// Viewcontlloerリストより削除
	// [viewControllers removeObjectAtIndex:nowViewIndex];
	// NSLog (@"VC ref counter:%d at removeObjectAtIndex", [vc retainCount]);
	// [vc release];
	// vc = nil;
}

- (BOOL) unloadAllViewSend
{
	if (nowViewIndex >= [viewControllers count])
	{	return (NO); }
	NSInteger i = [viewControllers count];
    BOOL isTransition = YES;
    
    while (nowViewIndex < i) {
#ifdef DEBUG
        NSLog(@"View : %ld UnLoad", (long)i);
#endif
        // 現在表示されているviewControllerを取得
        UIViewController *vc = [viewControllers objectAtIndex:i - 1];
        
        // delegate(インターフェイス)を取得
        id<MainViewControllerDelegate> delegate = (id<MainViewControllerDelegate>)vc;
        
        if ([((NSObject*)delegate) respondsToSelector:@selector(OnUnloadView:)])
        {
            // 実装を確認して画面終了の通知
            isTransition = [delegate OnUnloadView:self];
        }
        i--;
    }
	
	return (isTransition);
}

#pragma mark public_methods

// popupWindowの表示アニメーション終了時のハンドラ
- (void) showPopupWindowDidStop:(NSString*)animationID 
					   finished:(NSNumber*)finished context:(void*)context
{
	if (! context)
	{	return; }
	
	UIViewController *pushView = (UIViewController*)context;
	
	// [self presentModalViewController:context animated:YES];
	[self.navigationController pushViewController:pushView animated:NO];
	
	//[pushView release];
}
// popupWindowの表示
- (BOOL) showPopupWindow:(UIViewController*)popupVC
{
	BOOL stat = YES;
	
  @try {
	// "Pushing the same view controller"によるExceptionの対策
	for (UIViewController *vc in self.navigationController.viewControllers)
	{
		if (vc == popupVC)
		{	
			stat = NO;
			break;
		}
	}
	
	if (stat)
	{
		[self.navigationController pushViewController:popupVC animated:YES];
		
		// 画面遷移前のデバイスの向きを保存
		beforeInterfaceOrient = [self getNowDeviceOrientation];
	}

#ifndef POPUP_VIEW_ANIMATION
	  return (stat);
#else	
	#error
	// 現在表示されているView
	UIView *aView 
		= ((UIViewController*)[viewControllers objectAtIndex:nowViewIndex]).view;
	
	// ページめくり（開く）アニメーションの設定
	[UIView beginAnimations:@"showPopupWindowAnimation" context:popupVC];
	[UIView setAnimationDuration:0.25f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp 
						   forView:aView					// self.view
							 cache:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:
		@selector(showPopupWindowDidStop:finished:context:)];	// アニメ終了時のハンドラ設定
		
	[UIView commitAnimations];
#endif
  }
  @catch (NSException * e) {
	  stat = NO;
  }
	
	return (stat);
}

// closeWindowのアニメーション終了時のハンドラ
- (void) closePopupWindowDidStop:(NSString*)animationID 
						finished:(NSNumber*)finished context:(void*)context
{
	// [ [self parentViewController] dismissModalViewControllerAnimated:YES];
	[self.navigationController popViewControllerAnimated:NO];
}

// popupWindowを閉じる
- (void) closePopupWindow:(UIViewController*)closePopupView
{
#ifndef POPUP_VIEW_ANIMATION
	[self.navigationController popViewControllerAnimated:YES];
	
	// 画面遷移前よりデバイスの向きが変更していれば、イベントを発行する
	UIInterfaceOrientation orient = [self getNowDeviceOrientation];
	if (beforeInterfaceOrient != orient)
	{
		[self willRotateToInterfaceOrientation:orient duration:(NSTimeInterval)0];
	}
	
	return;
#else	
	
	[UIView beginAnimations:@"cameraViewAnimation_Close" context:nil];
	[UIView setAnimationDuration:0.25f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown
						   forView:closePopupView.view
							 cache:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:
		@selector(closePopupWindowDidStop:finished:context:)];
	
	[UIView commitAnimations];
#endif
}

// modalViewの表示
+ (void) showModalView:(UIViewController*)modalView
{
    UINavigationController *uiNavi = [[UINavigationController alloc] 
                                      initWithRootViewController:modalView];
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    // iOS6以降 presentModalViewController が非推奨になったらしい
    [mainVC presentViewController:uiNavi animated:YES completion:nil];
//    [mainVC presentModalViewController:uiNavi animated:YES];
    [uiNavi release];
    
    // 画面遷移前のデバイスの向きを保存
    mainVC->beforeInterfaceOrient = [mainVC getNowDeviceOrientation];

}
// modalViewを閉じる
+ (void) closeModalView
{
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    [mainVC dismissViewControllerAnimated:YES completion:nil];
    
    // 画面遷移前よりデバイスの向きが変更していれば、イベントを発行する
	UIInterfaceOrientation orient = [mainVC getNowDeviceOrientation];
	if (mainVC->beforeInterfaceOrient != orient)
	{
		[mainVC willRotateToInterfaceOrientation:orient duration:(NSTimeInterval)0];
	}
}

// 下表示modalDialogの表示
+ (void) showBottomModalDialog:(UIViewController*)modalView
{
    [MainViewController showBottomModalDialog:modalView parentView:nil];
}

// 下表示modalDialogの表示
+ (void) showBottomModalDialog:(UIViewController*)modalView parentView:(UIView*)parentView
{
    // modalDialogの表示
    [MainViewController showModalDialog:modalView parentView:parentView isDispBottom:YES];
}

// modalDialogの表示
+ (void) showModalDialog:(UIViewController*)modalView parentView:(UIView*)parentView isDispBottom:(BOOL)isBottom
{
    // portrait以外では表示しない
    if (! [MainViewController isNowDeviceOrientationPortrate])
    {   return; }
    
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    if (mainVC->_bottomDialog)
    {   return; }               // 既に表示済み
    
    // デバイスの向きを取得する
	// UIInterfaceOrientation orient = [mainVC getNowDeviceOrientation];
    // landscapeの場合はデバイスをportriteにする
    /*if ( ! UIInterfaceOrientationIsPortrait(orient))
    {
        [[UIApplication sharedApplication] 
            setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
        
        CGAffineTransform tranceForm = CGAffineTransformMakeRotation(270*M_PI / 180);
        mainVC.view.transform = tranceForm;
        
        [mainVC willRotateToInterfaceOrientation:UIInterfaceOrientationPortrait 
                                        duration:(NSTimeInterval)0];
    }*/
    
    // インスタンスを生成する
    UIView* parent = (parentView)? parentView : mainVC.view;
    mainVC->_bottomDialog =
        [[UIBottomDialogController alloc]initWithParentView:parent];
    
    // 表示する
    [mainVC->_bottomDialog presentDialogViewController:modalView animated:YES isDispBottom:isBottom];
}

// modalDialogを閉じる(上／下表示ダイアログ共用)
+ (void) closeBottomModalDialog
{
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    if(! (mainVC->_bottomDialog) )
    {   return; }               // 既に閉じている
    
    // 閉じる
    [mainVC->_bottomDialog dismissDialogViewControllerAnimated:YES];
    
    // 閉じる毎にインスタンスは破棄する
    [mainVC->_bottomDialog release];
    mainVC->_bottomDialog = nil;
}

// modalDialogが表示されているか？(上／下表示ダイアログ共用)
+ (BOOL) isDisplayBottomModalDialog
{
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    BOOL disp = ((mainVC->_bottomDialog) != nil);

    return (disp);
}

+ (void) _showLockWindowWithMessage:(NSString*)msg isLockMode:(BOOL)lockMode
{
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    if( (mainVC->_bottomDialog) )
    {   
        // modalDialogを含め表示している場合はここで閉じる
        [MainViewController closeModalView];
    }               
    
    // 画面LockのVCのインスタンス生成
    LockWindowPoupup *lock = [[LockWindowPoupup alloc] initWithLockMode:lockMode message:msg];
    
    // インスタンスを生成する
    mainVC->_bottomDialog =
        [[UILockWindowController alloc]initWithParentView:mainVC.view];
    
    // 表示する:上側表示
    [mainVC->_bottomDialog presentDialogViewController:lock animated:YES isDispBottom:NO];
    
    [lock release];

}

// メッセージPopup windowの表示
+ (void) showMessagePopupWithMessage:(NSString*)msg
{
    [MainViewController _showLockWindowWithMessage:msg isLockMode:NO];
}

// ロック画面の表示
+ (void) showLockWindowWithMessage:(NSString*)msg
{
    [MainViewController _showLockWindowWithMessage:msg isLockMode:YES];
    
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    // コンテナを非表示にする
    mainVC->scrollView.hidden = YES;
}

// ロック画面を閉じる
+ (void) closeLockWindow
{
    [MainViewController closeBottomModalDialog];
    
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    // コンテナを表示にする
    mainVC->scrollView.hidden = NO;
}

// viewのスクロールのロック
- (void) viewScrollLock:(BOOL)isLock
{
	scrollView.scrollEnabled = !isLock;
//#ifdef DEBUG
    if (isLock) {
        NSLog(@"viewScrollLock ON");
    }else {
        NSLog(@"viewScrollLock OFF");
    }
//#endif
    
	// ページコントールの表示も設定
    pageControl.hidden = isLock;
}

// 次のViewControllerを取得する
- (UIViewController*) getNextControlWithSelf:(UIViewController*)myVC
{
	// タグがそのままpageとなっている
	NSInteger nextPage =(myVC.view.tag) + 1;
	
	if ( [viewControllers count] <= nextPage)
	{	return (nil); }		// 範囲外
	
	return ([viewControllers objectAtIndex:nextPage]);
}

// 呼び出しもと（前の）のViewControllerを取得する
- (UIViewController*) getPrevControlWithSelf:(UIViewController*)myVC
{
	// タグがそのままpageとなっている
	NSInteger prevPage =(myVC.view.tag) - 1;
	
	if ( prevPage < 0)
	{	return (nil); }		// 範囲外
	
	return ([viewControllers objectAtIndex:prevPage]);
	
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

// 現在のデバイスの向きがPortrateであるかを取得する
+ (BOOL) isNowDeviceOrientationPortrate
{
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    // 現在のデバイスの向きを取得
    UIInterfaceOrientation orientation = [mainVC getNowDeviceOrientation];
    
    return (UIInterfaceOrientationIsPortrait(orientation));
}

// 次に表示されるViewをスキップする
- (void)skipNextPage:(BOOL)isSkip
{
	if (isSkip)
	{
		CGFloat pageWidth = scrollView.frame.size.width;  
		_skippedPage = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1; 
	}
	else 
	{
		_skippedPage = 0;
	}
}
// 前ページのViewをスキップする
- (void)skipBeforePage:(BOOL)isSkip
{
	if (nowViewIndex <= 1)
	{	return; }
	
	_skippedPage = (isSkip)? nowViewIndex - 1 : 0;
}

// 現在表示中Viewから任意の位置のViewControllerを取得する
- (UIViewController*)getViewControllerFromCurrentView:(UIViewController*)myVC pageTo:(NSInteger)page
{
	// タグがそのままpageとなっている
	//NSInteger currentPage = (myVC.view.tag) + 1;
	NSInteger nextPage = (myVC.view.tag) + page;
	
	if (nextPage <= 0 || [viewControllers count] <= nextPage)
	{	return (nil); }		// 範囲外
	
	return ([viewControllers objectAtIndex:nextPage]);
}

// UserInfoViewControllerを取得する
- (UIViewController*)getUserInfoViewController
{
	if ( [viewControllers count] == 0 ) return nil;
	return ([viewControllers objectAtIndex:0]);
}

// 現在表示中ViewControllerを取得
- (UIViewController*) getNowCurrentViewController
{
    if ((nowViewIndex < 0) || (nowViewIndex >= [viewControllers count]) )
    {   return nil; }
    
    return ((UIViewController*)[viewControllers objectAtIndex:nowViewIndex]);
}

// NavigationControllerより指定クラスのVCを取得
- (UIViewController*) getVC4NaviCtrlWithClass:(Class)aClass
{
	UIViewController* searchVC = nil;
	
	for (UIViewController *vc in self.navigationController.viewControllers)
	{
		if ([vc isKindOfClass:aClass] )
		{	
			searchVC = vc;
			break;
		}
	}
	
	return (searchVC);
}

// ViewContllerのリストより指定クラスのVCを取得
- (UIViewController*) getVC4ViewControllersWithClass:(Class)aClass
{
	UIViewController* searchVC = nil;
	
	for (UIViewController *vc in viewControllers)
	{
		if ([vc isKindOfClass:aClass] )
		{	
			searchVC = vc;
			break;
		}
	}
	
	return (searchVC);
}

// 表示中のページ番号を取得
- (NSInteger) getNowPage
{
    return pageControl.currentPage;
}

// 前ページへ戻る
- (void) backBeforePage
{
	// 先頭ページは戻れない
	if (nowViewIndex <= 1)
	{	return; }
	
	// 前ページ
	NSInteger beforePage = nowViewIndex - 1;
	
	// skipするページであるかを確認
	if ( (_skippedPage > 0) && (beforePage == _skippedPage))
	{	beforePage--; }
	
	pageControl.currentPage = beforePage;
	
	// 画面幅の取得
	CGFloat width  = scrollView.frame.size.width;  
	// 画面遷移しない場合は、スクロール位置を戻す
	scrollView.contentOffset 
		= CGPointMake((CGFloat)(width * beforePage), 0.0f);
	
	scrollView.delegate = self;
	
	nowViewIndex = beforePage;
	
	// 戻り先のViewControllerにviewDidAppearイベントを発生
	if (beforePage < [viewControllers count])
	{
		UIViewController *vc = (UIViewController*)[viewControllers objectAtIndex:beforePage];
		if (vc)
		{	[vc viewDidAppear:NO]; }
	}
	
}

// 次ページへ進む
- (void) fowordNextPage
{
	// 次ページ
	NSInteger nextPage = nowViewIndex + 1;
	
	// skipするページであるかを確認
	if ( (_skippedPage > 0) && (nextPage == _skippedPage))
	{	nextPage++; }
	
	// 最終ページより先は進めない
	if ( nextPage >= [viewControllers count])
	{	return; }
	
	pageControl.currentPage = nextPage;
	
	// 画面幅の取得
	CGFloat width  = scrollView.frame.size.width;  
	// 画面遷移しない場合は、スクロール位置を戻す
	scrollView.contentOffset 
		= CGPointMake((CGFloat)(width * nextPage), 0.0f);
	
	// scrollView.delegate = self;
	
	nowViewIndex = nextPage;
	
	// 戻り先のViewControllerにviewDidAppearイベントを発生
	if (nextPage < [viewControllers count])
	{
		UIViewController *vc = (UIViewController*)[viewControllers objectAtIndex:nextPage];
		if (vc)
		{	[vc viewDidAppear:NO]; }
	}
	
}

// 画面ロック状態の取得
- (BOOL) isWindowLockState
{
	return (vwSecurityManage.securityFaze == SECURITY_WINDOW_LOCK);
}

// セキュリティーロック状態の取得
- (BOOL) isWindowLockStateALL
{
    return ((vwSecurityManage.securityFaze == SECURITY_WINDOW_LOCK) ||
            (vwSecurityManage.securityFaze == SECURITY_VIEW_LOCK));
}

- (void) deleteViewControllersFromNextIndex{
    NSInteger nextIndex = nowViewIndex + 1;
#ifdef DEBUG
    NSLog(@"%s [%ld]", __func__, (long)nextIndex);
#endif
    for (NSInteger i = nextIndex; i < viewControllers.count; i++) {
        [((UIViewController *)viewControllers[i]).view retain]; //参照カウンタが減りすぎてしまうので。
        [((UIViewController *)viewControllers[i]).view removeFromSuperview];
        //((UIViewController *)viewControllers[i]).view.hidden = YES;
    }
    while (viewControllers.count > nextIndex && viewControllers.count > 0) {
        id obj = [viewControllers lastObject];
        if ([obj isKindOfClass:[VideoCompViewController class]]) {
            [obj release];
            obj = nil;
        }
        else if([obj isKindOfClass:[EditVideoViewController class]]) {
            [obj release];
            obj = nil;
        }
        else if([obj isKindOfClass:[PicturePaintViewController class]]) {
            [(PicturePaintViewController *)obj release];
        }

        [viewControllers removeLastObject];
    }
}
/**
 * ViewControllerの最終ページのオブジェクトを取得
 * (SelectVideo画面で、VideoCompViewController or EditVideoViewControllerを判別するため)
 */
- (id)getLastViewController
{
    return [viewControllers lastObject];
}

// ユーザ一覧をリフレッシュする
- (void)refreshUserInfoList
{
	scrollView.delegate = nil;
	pageControl.currentPage = 0;
	
	// スクロール位置を先頭位置に戻す
	scrollView.contentOffset = CGPointMake(0.0f, 0.0f);
	
	// ユーザ一覧VCを取得
	UserInfoListViewController *vc = [viewControllers objectAtIndex:0];
	if (vc)
	{	
		// UserInfoListVCのrefresh:初期化
		[vc refreshUserInfoListView];
	}
	
	// 現在の表示viewの初期化
	nowViewIndex = 0;
	
	scrollView.delegate = self;
}

#ifdef USE_ACCOUNT_MANAGER
// アカウント継続でのエラーハンドラ
- (void) onAccountContinueError
{
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"アカウント継続ができませんでした"
							  message:@"誠に申し訳ございませんが\nご使用のABCarteの\n機能を制限します"
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil
							  ];
	[alertView show];
	[alertView release];
	
	// 子Viewにも通知する
	[[NSNotificationCenter defaultCenter] postNotificationName:ACCOUNT_CONTINUE_ERROR_NOIFY 
														object:nil];
}

// アカウントの未ログインでのダイアログ表示
+ (BOOL) showAccountNoLoginDialog:(NSString *)content
{
	if([AccountManager isLogined])
	{	return (YES); }
	
	UIAlertView *alert
		= [[UIAlertView alloc]
		   initWithTitle:@"今すぐログインしてください"
		   message:[NSString stringWithFormat: @"ログインをしないと\n%@", content]
		   delegate:self
		   cancelButtonTitle:@"OK"
		   otherButtonTitles: nil
		   ];

	[alert show];
	[alert release];
	
	return (NO);
}

#endif

// Indicatorの表示
+ (void) showIndicator
{
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    [MainViewController showIndicatorWithViewController:mainVC];
}

// Indicatorの表示
+ (void) showIndicatorWithViewController:(UIViewController*)parentVc
{
    // 既に表示済みか？
    if ([parentVc.view viewWithTag:INDICATOR_VIEW_TAG] )
    {   return; }
    
    // インスタンス生成
    UIActivityIndicatorView *activityIndicator 
    = [[UIActivityIndicatorView alloc]  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    // 画面の真ん中の表示するように設定
    activityIndicator.center = parentVc.view.center;
    // あとで取り出せるようにタグを設定
    activityIndicator.tag = INDICATOR_VIEW_TAG;
   
    // subview に追加する
    [parentVc.view addSubview:activityIndicator];
    // グルグルスタート
    [activityIndicator startAnimating];
    // 解放
    [activityIndicator release];

}

// Indicatorを閉じる
+ (void) closeIndicator
{
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    [MainViewController closeIndicatorWithViewController:mainVC];
}

// Indicatorを閉じる
+ (void) closeIndicatorWithViewController:(UIViewController*)parentVc
{
    // タグ指定で追加したUIActivityIndicatorViewを取得する
    UIView *indVw = [parentVc.view viewWithTag:INDICATOR_VIEW_TAG];
    if (!indVw)
    {   return; }
    
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)indVw;
    
    // グルグルストップ
    [activityIndicator stopAnimating];
    // 解放
    [activityIndicator removeFromSuperview];
}

// Web参照画像の表示
+ (void) showReferenseWeb
{
    MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    if (! mainVC->_viewReferenceWeb)
    {   mainVC->_viewReferenceWeb = [[ReferenceWeb alloc] init]; }
    
    [mainVC->_viewReferenceWeb showReferencePageWithParent:mainVC.view];
}

// カラーテーブルの取得
- (UIColor*) getColorTable:(NSInteger) index
{
	return [bkColorTable objectForKey:[[NSNumber numberWithInteger:index] description]];
	//	return (UIColor*)[bkColorTable objectAtIndex:index];
}

#pragma mark Http_server_notification

// Httpサーバよりの完了通知
- (void)notifyUpDownLoadComplite:(NSNotification *) notification
{
#ifdef DEBUG
	NSLog(@"notifyUpDownLoadComplite:");
#endif
	/*
	 *	完了種別		|PCバックアップと復元のVC
	 *  ------------+-------------------+----------------
	 *	DOWN_LOAD	| OPEN				| AlertView表示（確認なし）
	 *	DOWN_LOAD	| CLOSE				| なにもしない
	 *	UP_LOAD		| OPEN				| AlertView表示 -> 復元情報の更新
	 *	UP_LOAD		| CLOSE				| AlertView表示（確認あり）-> パスワード入力
	 *
	 */
	
	if(notification)
	{
		NSArray *posts = notification.object;
		HTTP_COMPLITE_KIND kind 
			= [((NSNumber*)([posts objectAtIndex:0])) longValue];
		
		// PCバックアップと復元のVCが表示されているかを確認
		BOOL otBtn 
				= ( ([self getVC4NaviCtrlWithClass:[PcBackupViewController class]] == nil) &
				    (kind == HTTP_UP_LOAD_COMPLITE) );
		
		NSString *message = (! otBtn)?
				([NSString stringWithString:[posts objectAtIndex: 1]]) :
				([NSString stringWithFormat:@"%@\n(今すぐ復元しますか？)", [posts objectAtIndex:1]]);
		
		UIAlertView *alert;
		if (otBtn)
		{
			alert =[ [UIAlertView alloc]initWithTitle:@"通知" 
											   message:message
											  delegate:(kind == HTTP_UP_LOAD_COMPLITE)? self : nil 
									 cancelButtonTitle:@"は い"
									 otherButtonTitles:@"いいえ", nil];
		}
		else {
			alert =[ [UIAlertView alloc]initWithTitle:@"通知"
											   message:message
											  delegate:(kind == HTTP_UP_LOAD_COMPLITE)? self : nil 
									 cancelButtonTitle:@"O K"
									 otherButtonTitles:nil];
		}
		
		alert.tag = kind;

		[alert show];
		[alert release];
	}
}

#pragma mark - View lifecycle

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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    // カラーテーブルの作成
	// defaultテーブル
	colorIndex = BK_COLOR_DEFAULT;
	bkColorTable = [[NSMutableDictionary alloc] init];
	[bkColorTable setValue:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]
					forKey:[[NSNumber numberWithInt:BK_COLOR_DEFAULT] description]];

	[bkColorTable setValue:[UIColor colorWithRed:0 green:(122.0f/255.0f) blue:1.0 alpha:1.0]
					forKey:[[NSNumber numberWithInt:BK_SELECTED_CELL] description]];

	[bkColorTable setValue:[UIColor colorWithRed:0.941 green:1.0 blue:1.0 alpha:1.0]
					forKey:[[NSNumber numberWithInt:BK_NOSELECT_CELL] description]];
	
    // 背景色の変更 RGB:D8BFD8
//    [self.view setBackgroundColor:[bkColorTable objectForKey:[[NSNumber numberWithInteger:colorIndex] description]]];
    
    self.view.backgroundColor = [UIColor colorWithRed:255/255.0f green:186/255.0f blue:234/255.0f alpha:1.0f];
    
    // iPadの言語設定確認
    // ユーザ設定を取得
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSString *country = [df stringForKey:@"USER_COUNTRY"];
    if (country==nil) {
        //選択可能な言語設定の配列を取得
        NSArray *langs = [NSLocale preferredLanguages];
        //取得した配列から先頭の文字列を取得（先頭が現在の設定言語）
        NSString *currentLanguage = [langs objectAtIndex:0];
        // 国の設定
        [df setValue:currentLanguage forKey:@"USER_COUNTRY"];
    }
	
	// ScrollViewの初期化
    [self initScrollView];
	
	// Viewcontlloerリストの初期化
	viewControllers = [NSMutableArray array];
	[viewControllers retain];
    
    // viewのload
	/*for (NSInteger i = 0; i < PAGE_NUMS; i++)
		{	[self loadScrollViewWithPage:i]; } */
	
	// 初期表示のviewをloadする
	UIViewController *vc = [self loadFirstView];
	[self addViewWithViewController:vc page:0];
	
	// 履歴一覧と履歴詳細も事前にloadする
	[self loadScrollViewWithPage:1];
	[self loadScrollViewWithPage:2];
	
	// タップジェスチャーのセットアップ
	// [self tapGestureSupport];
	
	// セキュリティ管理Viewのセットアップ 
	[vwSecurityManage initInstanceWithDelegate:self];
	
	// 現在の表示viewの初期化
	nowViewIndex = 0;
	
	// 横向き起動対応
	UIInterfaceOrientation orient = [self getNowDeviceOrientation];
	if ((orient == UIDeviceOrientationLandscapeLeft) ||
		(orient == UIDeviceOrientationLandscapeRight))
	{	[self willRotateToInterfaceOrientation:orient 
									duration:(NSTimeInterval)0]; }
	
	// Httpサーバよりの完了通知設定：起動していない場合でも設定しておく
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(notifyUpDownLoadComplite:) 
												 name:HTTP_UP_DOWN_LOAD_COMPLITE object:nil];
	// 下表示ダイアログの初期化
	_bottomDialog = nil;

    // 参照画像のViewの初期化
    _viewReferenceWeb = nil;
// #ifdef AIKI_CUSTOM
    //BMK版の場合はsmtp情報はデフォルトを設定
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *infoBeanArray = [manager selectMailSmtpInfo:1];
    if([infoBeanArray count] == 0){
        [manager insertMailSmtpInfo:@"notify@calulu4bmk.jp" SmtpServer:@"smtp.calulu4bmk.jp" SmtpUser:@"notify@calulu4bmk.jp" SmtpPass:@"aNXMgbDT" SmtpPort:587 SmtpAuth:0];
    }
    [manager release];
// #endif
    // 下部のページコントロールの白点が誤操作につながるため操作不可にする
    pageControl.userInteractionEnabled = NO;
    preventScroll = NO;
#ifdef DEBUG
	NSLog(@"MainViewController : viewDidLoad");
#endif
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


+ (void)setDbdownloadEnd:(BOOL)stat{
    _____dbdownloadEnd_____ = stat;
}

+ (BOOL)getDbdownloadEnd{
    return _____dbdownloadEnd_____;
}

- (void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
	NSLog(@"MainViewController : viewWillAppear");
#endif
	UIViewController *vc
		= (UIViewController*)[viewControllers objectAtIndex:nowViewIndex];
	if (vc)
	{	
		// 現在の表示されているViewControllerにviewWillAppearイベントを発生
		[vc viewWillAppear:animated]; 
	}	
	
}

- (void)viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
	NSLog(@"MainViewController : viewDidAppear");
#endif
    // UserInfoListViewController以外の画面では無視
    if (nowViewIndex!=0) return;
	UIViewController *vc 
		= (UIViewController*)[viewControllers objectAtIndex:nowViewIndex];
	if (vc)
	{	
		// 現在の表示されているViewControllerにviewDidAppearイベントを発生
		[vc viewDidAppear:animated];
        
        // セキュリティ画面ロックがかかっていた場合、パスワード入力を求める
        if (vwSecurityManage.securityFaze)
            [vwSecurityManage openPwdPopup];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    if (_bottomDialog)
    {
        // 下表示ダイアログの場合はPortraitのみ有効
        return ( UIInterfaceOrientationIsPortrait(interfaceOrientation));
    }
    
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
	
	// viewの配置
    [self layoutView: isPortrait];
	
	// 各ViewControllerにイベントを渡す
	for (UIViewController* vc in viewControllers)
	{
		if (vc)
		{	
			[vc willRotateToInterfaceOrientation:toInterfaceOrientation
										duration:duration];
		}
	}

	// Web参考資料
    [_viewReferenceWeb refresh:isPortrait];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
//    [_viewReferenceWeb reload];
//    [_viewReferenceWeb refresh:fromInterfaceOrientation];
}

- (void)viewDidUnload
{
	// カラーテーブル
	[bkColorTable removeAllObjects];
	[bkColorTable release];

 	[scrollView release];
    scrollView = nil;
    [pageControl release];
    pageControl = nil;
	
	// [viewControllers release];
	viewControllers = nil;
	
	[super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - memory control

- (void)dealloc {
    [_viewReferenceWeb release];
	[scrollView release];
    [pageControl release];
	
	[viewControllers release];
	
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}



#pragma mark -scrollview events

// スクロールされる毎にコールされる
//2012 6/22 伊藤 ページ戻りの際、unloadを行うタイミングを変更
- (void)scrollViewDidScroll:(UIScrollView *)sender
{  
	CGFloat pageWidth = scrollView.frame.size.width; 
	BOOL isSkipped = NO;
	
	NSInteger page = (NSInteger)(((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 0.5);
    NSInteger backPage = (NSInteger)(((scrollView.contentOffset.x - pageWidth / 20) / pageWidth) + 0.5);
    // 背景色の変更 RGB:D8BFD8
//    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:204/255.0f green:149/255.0f blue:187/255.0f alpha:1.0f];
	// 表示するviewの変化を検出
	if (pageControl.currentPage > backPage || pageControl.currentPage < page)
	{
        // 素早くスクロールさせた場合に、scrollViewDidEndDeceleratingが呼び出されない場合が有るので
        // ここで処理を行わせる
        if (inScroll) {
            [self scrollViewDidEndDecelerating:nil];
        }
        inScroll = YES; // ページ切り替えのスクロール中フラグを設定
//#ifdef DEBUG
		NSLog (@"pageControl.currentPage change -> newPage:%ld backPage:%ld oldPage:%ld atNowIndex:%ld",
               (long)page, (long)backPage, (long)pageControl.currentPage, (long)nowViewIndex);
//#endif
        
        // 素早くスワイプして、直前の遷移でscrollViewDidEndDeceleratingがコールされていないので、
        // nowIndexをここで再設定する。（但し、前画面->次画面に遷移する場合のみ）
        if ((page == nowViewIndex) && (backPage == nowViewIndex)
                && (pageControl.currentPage < nowViewIndex))
        {
//#ifdef DEBUG
            NSLog(@"skip called scrollViewDidEndDecelerating at %ld page..... ", (long)page);
//#endif
            
            nowViewIndex = pageControl.currentPage;
        }
		
		BOOL isTransition = YES;
		
        // 画面を閉じる:現在表示Page > スクロールにより現れたPage	NSInteger page 
        if (nowViewIndex > backPage)
		{
            page = backPage;
			isTransition = [self unloadViewSend];
			
			//if ((_skippedPage > 0) && (page == _skippedPage)) 
			if (isTransition && (_skippedPage > 0) && (page == _skippedPage)) 
			{
				isSkipped = YES;
				page--;
#ifdef DEBUG
				NSLog (@"pageControl.currentPage skipped -> newPage:%ld skippedPage:%ld atNowIndex:%ld",
                       (long)page, (long)_skippedPage, (long)nowViewIndex);
#endif
				nowViewIndex--;
				
				isTransition = [self unloadViewSend];
			}
            //二つ以上先の画面に遷移できなくする
            [self setScrollViewWidth:YES];
		} 
		// 画面の遷移:現在表示Page < スクロールにより現れたPage
		 else if (nowViewIndex < page)
		{
			isTransition = [self transitionViewWithNewPage:page];
			
            // isTransition==NO の時は画面遷移を行わない(画像がない)
			if (page == _skippedPage && isTransition)
			{
				isSkipped = YES;
				page++;
//#ifdef DEBUG
				NSLog (@"pageControl.currentPage skipped -> newPage:%ld currentPage:%ld skippedPage:%ld atNowIndex:%ld",
                       (long)page, (long)pageControl.currentPage, (long)_skippedPage, (long)nowViewIndex);
//#endif
				nowViewIndex++;
				
				isTransition = [self transitionViewWithNewPage:page];
			}
		}
		
		// 画面遷移の可否を確認
		if (isTransition)
		{
			if (isSkipped) 
			{
				scrollView.delegate = nil;

				// 指定のページへScrollPosを移動する
				[self performSelector:@selector(moveScrollPos:) 
						   withObject:[NSNumber numberWithInt:(int)page] 
						   afterDelay:(NSTimeInterval)0.1f];
			}
			else 
			{
				scrollView.delegate = self;
				
				// PageControlに保存
				pageControl.currentPage = page;
			}
		}
		else 
		{
			scrollView.delegate = nil;
			
			// performSelectorを起動してScrollPosを戻す
			[self performSelector:@selector(remainedScrollPos:) 
					   withObject:[NSNumber numberWithInt:(int)pageControl.currentPage] 
					   afterDelay:(NSTimeInterval)0.1f];

		}
	}
}

// ScrollPosを戻す
- (void) remainedScrollPos:(id)befoerPage
{
	NSInteger page = (NSInteger)[((NSNumber*)befoerPage) intValue];
	
	scrollView.delegate = nil;
	
	pageControl.currentPage = page;
	
	// 画面幅の取得
	CGFloat width  = scrollView.frame.size.width;  
	// 画面遷移しない場合は、スクロール位置を戻す
	scrollView.contentOffset 
		= CGPointMake((CGFloat)(width * page), 0.0f);
	
	scrollView.delegate = self;
//#ifdef DEBUG
	NSLog (@"remainedScrollPos at page:%ld nowViewIndex:%ld",
           (long)page, (long)nowViewIndex);
//#endif
	nowViewIndex = page;
    [self setScrollViewWidth:YES];
}

// 指定のページへScrollPosを移動する
- (void) moveScrollPos:(id)pageMoveTo
{
	NSInteger page = (NSInteger)[((NSNumber*)pageMoveTo) intValue];

	scrollView.delegate = nil;
	pageControl.currentPage = page;
	
	// 画面幅の取得
	CGFloat width  = scrollView.frame.size.width;  
	// 画面遷移しない場合は、スクロール位置を戻す
	scrollView.contentOffset 
		= CGPointMake((CGFloat)(width * page), 0.0f);
	
	scrollView.delegate = self;
#ifdef DEBUG
	NSLog (@"moveScrollPos at page:%ld nowViewIndex:%ld",
		   (long)page, (long)nowViewIndex);
#endif
	
	// 表示されているページに変化があるかを確認
	if ( (page != nowViewIndex) && (page < [viewControllers count]) )
	{
		nowViewIndex = page;
		UIViewController *vc = (UIViewController*)[viewControllers objectAtIndex:page];
		if (vc)
		{	
			// 現在の表示されているViewControllerにviewDidAppearイベントを発生
			[vc viewDidAppear:NO]; 
		}
	}
}

/**
 * スクロールされてページ単位で動きがあった場合にコールされる
 * (素早くスクロールさせた場合、呼び出されない場合が有る)
*/
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
#ifdef DEBUG
	NSLog (@"scrollViewDidEndDecelerating:currentPage : %ld", (long)pageControl.currentPage);
#endif
	
	NSInteger page = pageControl.currentPage;
	
	// 表示されているページに変化があるかを確認
	if ( (page != nowViewIndex) && (page < [viewControllers count]) )
	{
		nowViewIndex = page;
		UIViewController *vc = (UIViewController*)[viewControllers objectAtIndex:page];
		if (vc)
		{
            // 現在の表示されているViewControllerにviewDidAppearイベントを発生
			[vc viewDidAppear:NO]; 
		}
	}
    // scrollViewDidEndDeceleratingが呼ばれた時は、ここでフラグを解除する
    inScroll = NO;
}

//6/22 伊藤 連続でページめくりを防ぐ処理
- (void)setScrollViewWidth:(BOOL)nextViewSet{
    NSInteger page = (scrollView.contentOffset.x/ scrollView.frame.size.width) + 1;
#ifdef DEBUG
    NSLog(@"nextPage : %ld", (long)page);
#endif
    if(nextViewSet){
        page++;
    }
    if (page > PAGE_NUMS) {
        page = PAGE_NUMS;
    }else if(page == 3){
        page = 4;
    }else if(page == 1){
        page = 2;
    }

    scrollView.contentSize =  CGSizeMake(scrollView.frame.size.width * page,
                                         scrollView.frame.size.height) ;
}

//scrollview bounce
- (void)setScrollViewBounce:(BOOL)bounce {
    if (bounce) {
        scrollView.bounces = true;
    } else {
        scrollView.bounces = false;
    }
}

#pragma mark UICancelableScrollViewDelegate
- (BOOL) isTouchDeliverd:(UICancelableScrollView*)scrollView touchPoint:(CGPoint)pt touchView:(UIView *)vw
{
    BOOL isDeliverd = YES;
    
    // 現在表示されているviewControllerを取得
	UIViewController *vc = [viewControllers objectAtIndex:nowViewIndex];
	
	// delegate(インターフェイス)を取得
	id<MainViewControllerDelegate> delegate = (id<MainViewControllerDelegate>)vc;
    
	if ([((NSObject*)delegate) respondsToSelector:@selector(OnCheckTouchDeleverd: touchPoint: touchView:)])
	{
		// Touchイベントを伝えるか：NOを返すと伝えない
		isDeliverd = [delegate OnCheckTouchDeleverd:self touchPoint:pt touchView:vw];
	}

    return (isDeliverd);
}
- (BOOL) isScrollPerformed:(UICancelableScrollView*) scrollView touchView:(UIView*)vw
{
    // 現在のスクロールのロック状態で初期化する
//    BOOL isPerformed =  ! pageControl.hidden;
    BOOL isPerformed =  YES;

    // 現在表示されているviewControllerを取得
	UIViewController *vc = [viewControllers objectAtIndex:nowViewIndex];
	
	// delegate(インターフェイス)を取得
	id<MainViewControllerDelegate> delegate = (id<MainViewControllerDelegate>)vc;
    
    if ([((NSObject*)delegate) respondsToSelector:@selector(OnCheckScrollPerformed: touchView:)])
	{
		// スクロール実施の確認 : NOを返すとスクロールをキャンセル
		isPerformed = [delegate OnCheckScrollPerformed:self touchView:vw];
	}
    
    if (preventScroll) {
        isPerformed = NO;
    }
    
    return (isPerformed);
}

// メインViewを返す
- (UIView *)getMainViewController
{
    return scrollView;
}

#pragma mark - control_events
- (IBAction)onChangePage:(id)sender 
{
	CGRect frame = scrollView.frame;
    
    frame.origin.x = frame.size.width * (CGFloat)pageControl.currentPage;
    frame.origin.y = 0.0f;

    // scrollViewを移動して表示する -> scrollViewDidScrollが２回走るので取りやめ
    // [scrollView scrollRectToVisible:frame animated:YES];
	
	// 上記の対策の為、表示ページを元に戻す
	NSInteger beforePage = pageControl.currentPage - 1;
	if ( beforePage >= 0)
	{	pageControl.currentPage = beforePage; }
#ifdef DEBUG
	NSLog (@"onChangePage at currentPage:%ld nowViewIndex:%ld",
           (long)pageControl.currentPage, (long)nowViewIndex);
#endif
}

#pragma mark SecurityManagerViewDelegate

// 画面ロックモード変更
- (void) windowLockModeChange:(BOOL)isLock
{
	// ViewContllerのリストを繰り返し
	for (UIViewController *vc in viewControllers)
	{
		// delegate(インターフェイス)を取得
		id<MainViewControllerDelegate> delegate = (id<MainViewControllerDelegate>)vc;
		
		if ([delegate respondsToSelector:@selector(OnWindowLockModeChange:)])
		{
			// VCで画面ロックモードイベントの実装あり
			[delegate OnWindowLockModeChange:isLock];
		}
		else {
			// VCで画面ロックモードイベントの実装なし:viewの表示／非表示を切り替え
			vc.view.hidden = isLock;
		}
	}
}

// フェーズの変更
- (void) securityManager:(id)sender onChangeFaze:(SECURITY_FAZE)faze
{
	switch (faze) {
		// セキュリティなし：通常状態
		case SECURITY_NONE:
		// セキュリティあり：Window Lock
		case SECURITY_WINDOW_LOCK:	
			// 画面ロックモード変更
			[self windowLockModeChange:(faze == SECURITY_WINDOW_LOCK)];
			break;
		default:
			break;
	}
}

// 遷移の確認
- (BOOL) isDisplayChnageEnable:(NSMutableString*) errMessage
{
	if (nowViewIndex >= [viewControllers count])
	{	return (YES); }
	
	BOOL stat = YES;
	
	// 現在表示中のVCを取得
	UIViewController *vc = (UIViewController*)[viewControllers objectAtIndex:nowViewIndex];
	
	if(vc)
	{
		// delegate(インターフェイス)を取得
		id<MainViewControllerDelegate> delegate = (id<MainViewControllerDelegate>)vc;
		
		// 遷移できるかを確認:VCで実装していない場合は遷移可とみなす
		if ([delegate respondsToSelector:@selector(OnDisplayChangeEnable:disableReason:)])
		{	stat = [delegate OnDisplayChangeEnable:self disableReason:errMessage]; }
	}
		
	return (stat);
}

// PCバックアップ／レストア画面への遷移要求
- (void) pcBackupRestoreViewRequest:(id)sender pcBackUpPwd:(NSString*)pwd
{
// 要求に対し、無条件で遷移する

	// PCバックアップ／復元ViewControllerのインスタンス作成
	PcBackupViewController *vc = [[PcBackupViewController alloc]
									initWithPassword:pwd
										  ownerView:self
								  restoreCompleteHandler:^void (id sender)
								  {
									  // まずは、PCバックアップ／復元VCを閉じる
									  [self closePopupWindow:sender];
									  
									  // データの復元の完了時のハンドラの実行:sender = PcBackupVC
									  [self refreshUserInfoList];	// ユーザ一覧をリフレッシュする
								  }];
	
	// PCバックアップ／レストア画面の表示
	[self showPopupWindow:vc];
	
	[vc release];
}

// データの復元完了
- (void) OnCompleteRestore:(id)sender
{
	// まずは、PCバックアップ／復元VCを閉じる
	[self closePopupWindow:sender];
	
	// データの復元の完了時のハンドラの実行:sender = PcBackupVC
	[self refreshUserInfoList];	// ユーザ一覧をリフレッシュする
}

#pragma mark tap_gesture
 
// タップジェスチャー：セキュリティ画面
- (void) OnSecurityShow
{
	/*UIAlertView *alertView 
	= [[UIAlertView alloc] initWithTitle:@"セキュリティ画面"
								 message:@"OnSecurityShow:セキュリティ画面"
								delegate:nil
					   cancelButtonTitle:@"OK"
					   otherButtonTitles:nil];
	[alertView show];
	[alertView release];*/
}

#pragma mark UIAlertViewDelegate
// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	PcBackupViewController *vc;
	switch (alertView.tag)
	{
		// アップロード完了
		case HTTP_UP_LOAD_COMPLITE:
			// PCバックアップと復元のVCが表示されているかを確認
			vc = (PcBackupViewController*)[self getVC4NaviCtrlWithClass:[PcBackupViewController class]];
			if (vc)
			{	[vc restoreInfoSetting]; }		// 復元情報の更新
			else  
			{
				// VCが表示されていなくて、はいの場合
				if (buttonIndex == 0)
				{
					// PCバックアップのパスワード入力画面を表示
					if (! [vwSecurityManage openPasswordInput4PcBackup])
					{
						// 画面ロックモードなどのためパスワード入力画面が開けない
						NSString* alertMsg = @"画面がロックされているので\nデータ復元画面を開けません";
						[self performSelector:@selector(onAlertNoOpnPwdWindow:) 
								   withObject:alertMsg afterDelay:0.05f];
					}
				}
			}
			break;
			
		// ダウンロード完了
		case HTTP_DOWN_LOAD_COMPLITE:
			// 何もしない
			break;
	}
}

- (void)onAlertNoOpenPwdWindow:(NSString*)message
{
	UIAlertView *alert =[ [UIAlertView alloc]initWithTitle:@"ご確認" 
												   message:message
												  delegate:nil 
										 cancelButtonTitle:@"O K"
										 otherButtonTitles:nil];
	[alert show];
	[alert release];
}

@end
