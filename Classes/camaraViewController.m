//    //
//  camaraViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"

#import "camaraViewController.h"

#import "ThumbnailViewController.h"

#import "userDbManager.h"

#import "OKDImageFileManager.h"

#import "iPad2CameraSettingPopup.h"

#import "OverlayViewSettingPopup.h"
#import "UIImageView4Camera.h"

#ifdef USE_ACCOUNT_MANAGER
#import "AccountManager.h"
#define TRIAL_VERSION
#endif

#import "WebCameraDeamon.h"
#import "SonyCameraRemoteViewController.h"
#import "DeviceList.h"
#import "DeviceInfo.h"
#import "SampleDeviceDiscovery.h"

// DELC SASAGE
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIAlertView+Blocks.h"
#import "MovieResource.h"

#import "appCapacityManager.h"
#import "SVProgressHUD.h"

#define CAM_SEL_HSIZE   220

#define SEL_IPAD_CAM        0
#define SEL_AIRMICRO_CAM    1
#define SEL_WEB_CAM         2
#define SEL_IPOD_CAM        3
#define SEL_SONY_CAM        4
#define SEL_3R_CAM          5

ThumbnailViewController		*thumbnailVC;
CMMotionManager *cmm;
double degree;
UIImageView *silhouetteGuideimageView;

@implementation camaraViewController

@synthesize _peerId; // , _gkSession;
@synthesize _selectedUserID;
@synthesize workDate = _workDate;
@synthesize histID = _histID;
@synthesize isNavigationCall = _isNavigationCall;
@synthesize reInit;
@synthesize isSonySelect;
@synthesize isSaved;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

#pragma mark private_methods


// 重ね合わせ画像のFrame設定
- (void) setOverlayImageFrame:(UIInterfaceOrientation)orientation
{
	// 重ね合わせ画像なしの場合は何もしない
	if (img4CameraView.isHidden)
	{	return; }
	
	CGRect rect, guideRect;
#ifdef CALULU_IPHONE
	if (UIInterfaceOrientationIsPortrait(orientation))
	{
		// iPad2内蔵カメラ選択(プレビューが表示されている場合)で、デバイスが縦の場合のみ、プレビューの大きさが異なる
		// if (btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED)
		if ( ! iPad2InnerCameraView.isHidden)
		{   rect = CGRectMake(-125.0f,  33.0f, 570.0f, 427.0f); }     // -125 = (570-320) / 2
		else 
		{	rect = CGRectMake(0, 110, 320, 240); }
	}
	else 
	{	rect = CGRectMake(0, 0, 480, 360); }
#else
    if (UIInterfaceOrientationIsPortrait(orientation))
	{
#ifdef VER_150_LATER
		// iPad2内蔵カメラ選択(プレビューが表示されている場合)で、デバイスが縦の場合のみ、プレビューの大きさが異なる
		// if (btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED)
		if ( ! iPad2InnerCameraView.isHidden)
		{   rect = CGRectMake( -43.0f, 150.0f, 854.0f, 640.0f); }      // -43 = (854-768) / 2
        else
		{	rect = CGRectMake(64, 240, 640, 480); }
#else
        guideRect = CGRectMake(0, 0, 768.0f, 1024.0f);

        if ((btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED) ||
            (btniPadCamera.tag == CM_VC_CAMERA_SELECTED) ||
            btnVideo.isSelected || btnVideoAuto.isSelected)
        {
            // 透過画像のアスペクト比調整
            rect = [self adjustAspect:CGRectMake(0, 0, 768.0f, 1024.0f)
                          adjustImage:img4CameraView.backgroundImage];
        }
        else if (btnAirMicro.tag == CM_VC_CAMERA_SELECTED || btn3RCamera.tag == CM_VC_CAMERA_SELECTED)
        {   rect = CGRectMake(64, 240, 640, 480); }
        else if (btnWebCamera.tag == CM_VC_CAMERA_SELECTED)
        {
            rect = [self adjustAspect:CGRectMake(0.0f, 0.0f, 768.0f, 1024.0f)
                          adjustImage:img4CameraView.backgroundImage];
//            rect = CGRectMake(-298.5f, 0.0f, 1365.0f, 1024.0f);
        }
        else if (_SonyCameraDaemon.tag == CM_VC_CAMERA_SELECTED)
        {
            if (webCamRotate==0 || webCamRotate==2) {
                // 透過画像のアスペクト比調整
                rect = [self adjustAspect:CGRectMake(0, 0, 768, 768*3/4)
                              adjustImage:img4CameraView.backgroundImage];
//                rect = [self adjustAspect:CGRectMake(0, (1024 - (768*3/4))/2, 768, 768*3/4)
//                              adjustImage:img4CameraView.backgroundImage];
                guideRect = CGRectMake(0, (1024 - (768*3/4))/2, 768, 768*3/4);
            } else {
//                rect = CGRectMake(0, 0, 768, 1024);
                rect = [self adjustAspect:guideRect
                              adjustImage:img4CameraView.backgroundImage];
            }
        }
        else
        {   rect = CGRectMake(-298.5f, 0.0f, 1365.0f, 1024.0f); }
#endif
	}
	else
	{
        // 透過画像のアスペクト比が正しくなるように調整
        if (img4CameraView.backgroundImage.size.width<img4CameraView.backgroundImage.size.height)
        {   // 縦長画像の場合
            CGSize tmpSize = CGSizeMake(img4CameraView.backgroundImage.size.width,
                                        img4CameraView.backgroundImage.size.height);
            CGFloat tmpWidth = tmpSize.width * 768.0f / tmpSize.height;
            CGFloat tmpX     = (1024.0f - tmpWidth) / 2;
            rect = CGRectMake(tmpX, 0.0f, tmpWidth, 768.0f);
//            rect = CGRectMake(0.0f, 0.0f, tmpWidth, 768.0f);
        } else {
            rect = CGRectMake(0, 0, 1024, 768);
        }
        
        guideRect = CGRectMake(0, 0, 1024.0f, 768.0f);
        if (_SonyCameraDaemon.tag == CM_VC_CAMERA_SELECTED) {
            if (webCamRotate==1 || webCamRotate==3) {
                guideRect = CGRectMake((1024 - (768*3/4))/2, 0, 768*3/4, 768);
                rect = CGRectMake(0, 0, rect.size.width, rect.size.height);
            }
        }
    }
#endif
    [img4CameraView setBackgroundImageRect:rect];
    [img4CameraView setFrame:guideRect];
	
	[img4CameraView setNeedsDisplay];
    
    [gridLineView setBackgroundImageRect:rect];
    [gridLineView setFrame:guideRect];

    [gridLineView setNeedsDisplay];
    
    //3R CAMERA add check
    if (btn3RCamera.tag == CM_VC_CAMERA_SELECTED) {
        [_mjpegStreamView setFrame:guideRect];
    }
}

/**
 * 透過画像のアスペクト比が正しくなるように調整
 * @param (CGRect)baseFrame     透過画像を表示するフレーム
 * @param (UIImage *)adjustImg  調整対象のイメージ
*/
- (CGRect)adjustAspect:(CGRect)baseFrame adjustImage:(UIImage *)adjustImg
{
    CGRect rect;
    CGSize tmpSize = CGSizeMake(adjustImg.size.width, adjustImg.size.height);
    CGFloat width  = baseFrame.size.width;
    CGFloat height = baseFrame.size.height;
    CGFloat tmpY   = baseFrame.origin.y;

    if (width < height) {   // ポートレートに対して調整する場合

        if (adjustImg.size.width > adjustImg.size.height)
        {   // 横長画像の場合(縦をフィットさせて、左右をクリップ)
            CGFloat tmpWidth = tmpSize.width * height / tmpSize.height;
            CGFloat tmpX     = (tmpWidth - width) / 2 * -1;
            rect = CGRectMake(tmpX, 0.0f, tmpWidth, height);
            // 内蔵カメラ・iPodカメラ： -298.5 = (1365-768) /2
            //                rect = CGRectMake(-298.5f, 0.0f, 1365.0f, 1024.0f);
        }
        else
        {   // 縦長画像の場合
            rect = CGRectMake(0.0f, 0.0f, width, height);
        }
    } else {                // ランドスケープに対して調整する場合

        if (adjustImg.size.width < adjustImg.size.height)
        {   // 縦長画像の場合(縦をフィットさせて、左右はスペース)
            CGFloat tmpWidth = tmpSize.width * height / tmpSize.height;
            CGFloat tmpX     = (width - tmpWidth) / 2;
            rect = CGRectMake(tmpX, tmpY, tmpWidth, height);
        } else {
            rect = CGRectMake(0.0f, tmpY, width, height);
        }
    }
    
    return rect;
}

- (void) setOverlayImageFrame
{
	UIInterfaceOrientation orientation =
#ifdef CALULU_IPHONE
        ([UIScreen mainScreen].applicationFrame.size.width  == 320.0f)?
#else
        ([UIScreen mainScreen].applicationFrame.size.width  == 768.0f)?
#endif
            UIInterfaceOrientationPortrait : UIInterfaceOrientationLandscapeRight;
	
	[self setOverlayImageFrame:orientation];
}

// 下部のボタン類のコンテナViewのボタンレイアウト：重ね合わせ画像のありなしで変更
- (void) setBottomPanelLayout:(UIInterfaceOrientation)orientation
{	
	// コンテナViewの現在frmaeを取得
	CGRect btPnlFrame = vwBottomPanel.frame;
	
	// 重ね合わせ画像の有無で、コンテナViewの幅を決定
	CGFloat pnlWidth = (img4CameraView.isHidden)? 
#ifdef CALULU_IPHONE
                            222.0f : 264.0f;
#else
                            662.0f : 668.0f;
#endif
	
	// ScreenサイズよりX座標を取得
	CGFloat screenWith = (UIInterfaceOrientationIsPortrait(orientation))?
#ifdef CALULU_IPHONE
							320.0f : 480.0f;
    btPnlFrame.origin.y = (UIInterfaceOrientationIsPortrait(orientation))?  410.0f : 250.0f;
    CGFloat xPos = ((UIInterfaceOrientationIsPortrait(orientation)) && (! img4CameraView.isHidden) )? 
                        10.0f : ((screenWith - pnlWidth) / 2.0f);
#else
							768.0f : 1024.0f;
    CGFloat xPos =(screenWith - pnlWidth) / 2.0f;
#endif
	
	// コンテナViewのfrmaeを先に設定
	[vwBottomPanel setFrame:CGRectMake
	 (xPos, btPnlFrame.origin.y, pnlWidth, btPnlFrame.size.height)];

#ifdef CALULU_IPHONE
    // Randscapeでは重ね合わせ表示の設定は不可
    btnOverlayViewSetting.enabled = UIInterfaceOrientationIsPortrait(orientation);
    
    //Randscapeでは表示されている下側ダイアログを閉じる
    if (! (UIInterfaceOrientationIsPortrait(orientation)) )
    {   [MainViewController closeBottomModalDialog]; }
#endif

}

// GKPeerPickerのダイアログを消去
-(void) dissmissPeerPicker
{
	if ( (! picker) ||
		 (picker && (! picker.isVisible)) )
	{	return; }		// 既に閉じている
	
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
	
	picker = nil;	
}

// シャッターとフリーズボタンの有効／無効設定
- (void) setShutterFreezeButton
{
	if(btnAirMicro.tag == CM_VC_CAMERA_SELECTED)
	{
        btnCamShutter.hidden = NO;
		[btnCamShutter setBackgroundImage:[UIImage  imageNamed:@"camera.png" ]
								 forState:UIControlStateNormal];
        btnCamFreeze.hidden = NO;
        btnVideoRecord.hidden = YES;
		[btnCamFreeze setBackgroundImage:[UIImage  imageNamed:@"camera_pause.png" ]
								 forState:UIControlStateNormal];
	}
    else if(btnVideo.isSelected || btnVideoAuto.isSelected) {
        //        [btnCamShutter setBackgroundImage:[UIImage  imageNamed:@"camera_disable.png" ]
        //                                 forState:UIControlStateNormal];
        btnCamShutter.hidden = YES;
        btnCamFreeze.hidden = YES;
        btnVideoRecord.hidden = NO;
    }
	else if ( (btniPadCamera.tag        == CM_VC_CAMERA_SELECTED) ||
			  (btniPad2InnerCamera.tag  == CM_VC_CAMERA_SELECTED) ||
              (btnWebCamera.tag         == CM_VC_CAMERA_SELECTED) ||
              (_SonyCameraDaemon.tag    == CM_VC_CAMERA_SELECTED) ||
              (btn3RCamera.tag          == CM_VC_CAMERA_SELECTED))
	{
        btnCamShutter.hidden = NO;
		[btnCamShutter setBackgroundImage:[UIImage  imageNamed:@"camera.png" ]
								 forState:UIControlStateNormal];
        btnCamFreeze.hidden = YES;
        btnVideoRecord.hidden = YES;
		//[btnCamFreeze setBackgroundImage:[UIImage  imageNamed:@"camera_pause_disable.png" ]
		//						forState:UIControlStateNormal];
	}
//    else if(btnVideo.isSelected || btnVideoAuto.isSelected) {
////        [btnCamShutter setBackgroundImage:[UIImage  imageNamed:@"camera_disable.png" ]
////                                 forState:UIControlStateNormal];
//        btnCamShutter.hidden = YES;
//        btnCamFreeze.hidden = YES;
//        btnVideoRecord.hidden = NO;
//    }
	else
	{
        btnCamShutter.hidden = NO;
		[btnCamShutter setBackgroundImage:[UIImage  imageNamed:@"camera_disable.png" ]
								 forState:UIControlStateNormal];
        btnCamFreeze.hidden = YES;
        btnVideoRecord.hidden = YES;
		//[btnCamFreeze setBackgroundImage:[UIImage  imageNamed:@"camera_pause_disable.png" ]
		//						forState:UIControlStateNormal];
	}
	
	// iPad2内蔵カメラの選択時のみ、FrontRear切り替えボタンを表示する
    // btnFrontRearChg.hidden = (btniPad2InnerCamera.tag != CM_VC_CAMERA_SELECTED);
	// btnFrontRearChg.hidden = (btniPad2InnerCamera.tag != CM_VC_CAMERA_SELECTED) && !btnVideo.isSelected && !btnVideoAuto.isSelected;
    // btnOpenPhotoLibrary.hidden = (btnFrontRearChg.hidden == NO);
}

// iPad内蔵カメラ用の設定値を取得
- (void) get4iPad2CameraSetting
{
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	// 手ぶれ補正の有無を設定ファイルから取得
	if (! [defaluts objectForKey:@"ipad2_camera_hand_vib"])
	{
		// 初回取得
		_camViewIsHandVib = YES;
		// ここで書き込みを行う
		[defaluts setBool:_camViewIsHandVib forKey:@"ipad2_camera_hand_vib"];
	}
	else {
		_camViewIsHandVib = [defaluts boolForKey:@"ipad2_camera_hand_vib"];
	}

	// 手ぶれ防止の判定時間[sec]を設定ファイルから取得
	if (! [defaluts objectForKey:@"ipad2_camera_delay_time"])
	{
		// 初回取得
		_camViewDelayTime = 2;
		// ここで書き込みを行う
		[defaluts setInteger:_camViewDelayTime forKey:@"ipad2_camera_delay_time"];
	}
	else {
		_camViewDelayTime = [defaluts integerForKey:@"ipad2_camera_delay_time"];
	}
	
	// 手ぶれ防止の判定時間[sec]を設定ファイルから取得
	if (! [defaluts objectForKey:@"ipad2_camera_capture_speed"])
	{
		// 初回取得
		_camViewCaptureSpeed = IPAD2_CAM_CAPTURE_MIDDLE;
		// ここで書き込みを行う
		[defaluts setInteger:_camViewCaptureSpeed forKey:@"ipad2_camera_capture_speed"];
	}
	else {
		_camViewCaptureSpeed = (u_int)[defaluts integerForKey:@"ipad2_camera_capture_speed"];
	}
}

// iPad2内蔵カメラのセットアップ
- (void) setup4iPad2InnerCamera
{
	// iPad内蔵カメラ用の設定値を取得
	[self get4iPad2CameraSetting];
	
	// 内蔵カメラ用CameraViewPickerのインスタンス作成
	if (! ( _cameraViewPicker 
				= [[UICameraViewPicker alloc] initWithHandVibSetting:_camViewIsHandVib 
														  delayTimer:_camViewDelayTime]))
	{
		// 内蔵カメラはサポートされていない
		btniPad2InnerCamera.tag = CM_VC_CAMERA_DISABLE;
		return;
	}
	
	// キャプチャ速度をここで設定
	_cameraViewPicker.captureSpeed	= _camViewCaptureSpeed;
	
	// ボタンを無効にする
	btniPad2InnerCamera.hidden = YES;
	btnFrontRearChg.hidden = NO;
	// btnOpenPhotoLibrary.hidden = YES;
	// Rearカメラを使用
	_isRearCameraUse = YES;
	
	// イベントを有効にする
	_cameraViewPicker.delegate = self;
	
	// 非選択にする
	btniPad2InnerCamera.tag = CM_VC_CAMERA_NOT_SELECTED;
	
}

// スワイプと長押しのセットアップ
- (void) setupSwipLongTouchSupport
{
	// スワイプのセットアップ
	UISwipeGestureRecognizer *swipeGestue = [[UISwipeGestureRecognizer alloc]
											 initWithTarget:self action:@selector(OnSwipeRightView:)];
	swipeGestue.direction = UISwipeGestureRecognizerDirectionRight;
	swipeGestue.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeGestue];
	[swipeGestue release];
	
	// 長押しのセットアップ:iPad2内蔵カメラの設定用
	UILongPressGestureRecognizer *longPressGesture 
		= [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(OnLongPressView:)];
	longPressGesture.minimumPressDuration = 1.5f;
	[self.view addGestureRecognizer:longPressGesture];
	[longPressGesture release];

	// タップのセットアップ：1本指でフォーカス
    UITapGestureRecognizer *tapGesture 
    = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(_onViewSetFocus:)];
	tapGesture.numberOfTouchesRequired = 1;		// 指1本
    tapGesture.cancelsTouchesInView = NO;
	[self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
	
	// タップのセットアップ：カメラ関係のシャッター　指２本(1本:iPhone)で有効
/*
#ifdef CALULU_IPHONE
	UITapGestureRecognizer *tapGesture 
        = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(_onViewSingleTap:)];
	tapGesture.numberOfTouchesRequired = 1;		// 指1本
    tapGesture.cancelsTouchesInView = NO;
#else
    */
    UITapGestureRecognizer *tapGesture2 
        = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnCamShutter)];
	tapGesture2.numberOfTouchesRequired = 2;		// 指２本
    /*
#endif
     */
	[self.view addGestureRecognizer:tapGesture2];
	[tapGesture2 release];
}



// iPad2内蔵カメラの非活性への切り替え
- (void) dissmiss4iPad2Camera:(BOOL)isPrevChange
{
	// プレビュー表示の切り替え
	if (isPrevChange)
	{
		iPadTouchView.hidden = NO;
		iPad2InnerCameraView.hidden = YES;
		
		// 重ね合わせ画像のFrame設定
		[self setOverlayImageFrame];
	}
	// iPad2内蔵カメラが選択されていない場合
	if (btniPad2InnerCamera.tag != CM_VC_CAMERA_SELECTED && !btnVideoAuto.isSelected && !btnVideo.isSelected)
	{	return; }
	
	// セッションの終了
	[ _cameraViewPicker endSession];
	
	// iPad2内蔵カメラの選択状態を反転
	btniPad2InnerCamera.tag = CM_VC_CAMERA_NOT_SELECTED;
	//[btniPad2InnerCamera setImage:[UIImage imageNamed:@"iPad2Camera_off.png"]
	//					 forState:UIControlStateNormal];
    [btnVideo setSelected:NO];
    [btnVideoAuto setSelected:NO];
	
}

// iPad2用内蔵カメラ用プレビューのRectを取得
- (CGRect) get4iPad2CameraPreviewRect:(UIInterfaceOrientation)toInterfaceOrientation
{
	CGRect rect
		= ( (toInterfaceOrientation == UIInterfaceOrientationPortrait) ||
		    (toInterfaceOrientation == UIDeviceOrientationPortraitUpsideDown) )?
#ifdef CALULU_IPHONE
				CGRectMake(  0,  33, 320, 427) : CGRectMake(0, 0,  480, 360);
#else
#ifdef VER150_LATER
                CGRectMake(144, 150, 480, 640) : CGRectMake(0, 0, 1024, 768);
#else
   				CGRectMake(0, 0, 768, 1024) : CGRectMake(0, 0, 1024, 768);
#endif
#endif
	return(rect);
}

// 内蔵カメラ用CameraViewPickerにデバイス状態を通知
- (void) notify4iPad2CameraViewPicker
{
	// MainViewControllerの取得
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// 現在のデバイスの向きを取得
	UIInterfaceOrientation toInterfaceOrientation = [mainVC getNowDeviceOrientation];
	
	// iPad2用内蔵カメラ用プレビューのRectを取得
	CGRect iPad2InViewRect = [self get4iPad2CameraPreviewRect:toInterfaceOrientation];
	
	// セッション開始直後に行うとなぜかLandscape系で逆になるので、ここで反転する
	UIInterfaceOrientation flipInterfaceOrientation;
	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationPortraitUpsideDown:
			flipInterfaceOrientation = toInterfaceOrientation;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			flipInterfaceOrientation = UIInterfaceOrientationLandscapeRight;
			break;
		case UIInterfaceOrientationLandscapeRight:
			flipInterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
			break;
		default:
			flipInterfaceOrientation = toInterfaceOrientation;
			break;
	}
	
	// デバイス状態を通知
	[_cameraViewPicker notifyWillRotateToInterfaceOrientation:flipInterfaceOrientation
												  previewRect:iPad2InViewRect];
}

// airMicroにデバイス状態を通知
- (void) notify4AitMicroDeviceState
{
#ifdef DEBUG
    NSLog(@"%s : [%d]", __func__, (airmicro!=nil)? 1:0);
#endif
	if (! airmicro)
	{	return; }
	
	// MainViewControllerの取得
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// 現在のデバイスの向きを取得
	UIInterfaceOrientation toInterfaceOrientation = [mainVC getNowDeviceOrientation];
	
	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
			//NSLog(@"ボタンが下：正位置");
		case UIDeviceOrientationPortraitUpsideDown:
#ifdef CALULU_IPHONE
			[airmicro setFrame: CGRectMake(0, 110, 320, 240)];
			[indField setFrame:CGRectMake(150.0f, 220.0f, 20.0f, 20.0f)];
#else
			[airmicro setFrame: CGRectMake(64, 240, 640, 480)];
			[frzField setFrame:CGRectMake(64.0f, 210.0f, 182.0f, 22.0f)];
            [capField setFrame:CGRectMake(522.0f, 210.0f, 182.0f, 22.0f)];
			[indField setFrame:CGRectMake(374.0f, 470.0f, 20.0f, 20.0f)];
#endif
			break;
		case UIInterfaceOrientationLandscapeLeft:
			// NSLog(@"左回転：左が上");
		case UIInterfaceOrientationLandscapeRight:
			// NSLog(@"右回転：右が上");
#ifdef CALULU_IPHONE
            [airmicro setFrame: CGRectMake(0, 0, 480, 320)];
			[airMicroButton  setFrame: CGRectMake(0, 0, 480, 360)];
			[indField setFrame:CGRectMake(230.0f, 140.0f, 20.0f, 20.0f)];
#else
			[airmicro  setFrame: CGRectMake(0, 0, 1024, 768)];
			[frzField setFrame:CGRectMake(0.0f, 0.0f, 182.0f, 22.0f)];
            [capField setFrame:CGRectMake(842.0f - CamControll.frame.size.width, 0.0f, 182.0f, 22.0f)];
			[indField setFrame:CGRectMake(502.0f, 374.0f, 20.0f, 20.0f)];
#endif
			break;
        default:
            break;
	}
}

// デフォルトで内蔵カメラを選択
- (void) _setupDefaultInnerCamera
{
    btniPad2InnerCamera.tag = CM_VC_CAMERA_SELECTED;
	//[btniPad2InnerCamera setImage:[UIImage imageNamed:@"iPad2Camera_on.png"]
    //                     forState:UIControlStateNormal];
    
    // プレビュー表示の切り替え
	iPadTouchView.hidden = YES;
	iPad2InnerCameraView.hidden = NO;
    
    // 重ね合わせ画像のFrame設定
	[self setOverlayImageFrame];
}

#ifdef NONUSE
// 写真アルバム取り込みを非選択にする
- (void) _photeLibraryNonSelect
{
    if (btnOpenPhotoLibrary.tag == CM_VC_CAMERA_SELECTED)
    {
        btnOpenPhotoLibrary.tag = CM_VC_CAMERA_NOT_SELECTED;
        [btnOpenPhotoLibrary setBackgroundImage:[UIImage  imageNamed:@"import_photo_Library.png" ]
                                       forState:UIControlStateNormal];
        
        // imageをクリア
        iPadTouchView.image = nil;
    }
}
#endif
// GkSessionの接続初期化(WiFiモード)
- (void) _gkSessionInitWifiConnect
{
    if (_gkSession == nil){
        _gkSession = [[[GKSession alloc] initWithSessionID:_sessionName
                                               displayName:nil
                                               sessionMode:GKSessionModePeer] autorelease];
        _gkSession.delegate = self;
        _gkSession.available = YES;
        [_gkSession setDataReceiveHandler:self withContext:nil];
        [_gkSession retain];
    }
}

// 外部カメラプレビューの画像Fit
- (UIImage*) _fitToiPadTouchVwWithImage:(UIImage*)img
{
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    // デバイスの向きを取得  getNowDeviceOrientation
    UIInterfaceOrientation ort = [mainVC getNowDeviceOrientation];
    
    CGFloat left = 0.0f;
    CGFloat top = 0.0f;
    CGFloat width = 0.0f;
    CGFloat height = 0.0f;
    CGSize size = iPadTouchView.frame.size;
    
    switch (ort) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            // デバイスがポートレート（縦）で画像が横向きの場合
            if(img.size.width > img.size.height)
            {                
                // 高さを縦横比より縮小
                height = (size.width / size.height) * size.width;
                width = size.width;        // 横幅を縮小
                left = 0.0f;
                // Y位置を中央に
                top = (size.height - height) / 2.0f;
            }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            // デバイスがランドスケープ（横）で画像が縦向きの場合
            if(img.size.width < img.size.height)
            {
                // 幅を縦横比より縮小
                width = (size.height / size.width) * size.height;
                height = size.height;        // 縦高さを縮小
                // X位置を中央に
                left = (size.width - width) / 2.0f;
                top = 0.0f;
            }
        default:
            break;
    }
    
    if ((left <= 0.0f) && (top <= 0.0f) )
    {   return  (img); }        // 画像Fitの必要なし
    
    // グラフィックコンテキストをコントロールサイズで作成
	UIGraphicsBeginImageContext
        (CGSizeMake(size.width, size.height));
    
    // グラフィックコンテキストに描画
    CGRect imgRect = CGRectMake(left, top, width, height);
	[img drawInRect:imgRect];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
	return (image);    
}

// webカメラの非活性への切り替え
- (void) dissmiss4WebCamera
{
    // Webカメラが無効な場合は何もしない
    if (! _webCameraDaemon.isWebCameraEnable)
    {
        return; }
    
	// Webカメラが選択されていない場合は何もしない
//	if (btnWebCamera.tag != CM_VC_CAMERA_SELECTED)
//	{	return; }
	
	// プレビューの停止
	[_webCameraDaemon stopPreview];
	
	// Webカメラの選択状態を反転
	btnWebCamera.tag = CM_VC_CAMERA_NOT_SELECTED;
	//[btnWebCamera setImage:[UIImage imageNamed:@"camera_web_cam.png"]
	//					 forState:UIControlStateNormal];
	
}
- (void)setVideoIsRecording:(BOOL)isRecording {
    [btnVideoRecord setSelected: isRecording];
    btnOverlayViewSetting.enabled = !isRecording;   //録画中に自動停止時間を変えられないように
    CamSelect.btnEnable = !isRecording;             // 録画中にカメラ選択スライドボタンを操作されないように
}
#pragma mark trial_versio_methods
#ifdef TRIAL_VERSION
	
// 撮影可能枚数を取得し、超過していないかを確認する
- (BOOL) isTakePictureEnable
{
#define TAKE_PICT_ENABLE_NUMS_KEY	@"take_picture_enable_nums"
	
#ifdef USE_ACCOUNT_MANAGER
	// アカウントにログイン済みかを確認
	if([AccountManager isLogined])
	{	return (YES); }
#endif
	
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	NSInteger nums;
	
	// 既に撮影した枚数を取得
	if( ! [defaluts objectForKey:TAKE_PICT_ENABLE_NUMS_KEY] )
	{	nums = 0; }
	else 
	{
		nums = [defaluts integerForKey:TAKE_PICT_ENABLE_NUMS_KEY];
	}
	
	// ここで撮影したことにして枚数を加算して保存する
	nums++;
	[defaluts setInteger:nums forKey:TAKE_PICT_ENABLE_NUMS_KEY];
	
	// 撮影枚数を比較
	return (nums <= TRIAL_VER_TAKE_PICTURE_NUM);
}

// 2012/07/26 伊藤
// ライブラリから取り込み回数取得し、超過していないかを確認する
- (BOOL) isImportPictureEnable
{
	
#ifdef USE_ACCOUNT_MANAGER
	// アカウントにログイン済みかを確認
	if([AccountManager isLogined])
	{	return (YES); }
#endif
	
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	NSInteger nums;
	
	// 既にインポートした枚数を取得
	if( ! [defaluts objectForKey:IMPORT_PICT_ENABLE_NUMS_KEY] )
	{	nums = 0; }
	else 
	{
		nums = [defaluts integerForKey:IMPORT_PICT_ENABLE_NUMS_KEY];
	}
	
	// ここでインポートしたことにして枚数を加算して保存する
	nums++;
	[defaluts setInteger:nums forKey:IMPORT_PICT_ENABLE_NUMS_KEY];
	
	// インポート枚数を比較
	return (nums <= TRIAL_VER_IMPORT_PICTURE_NUM);
}

// 確認ダイアログを表示してCaLuLuホームページを開く
- (void)openCaLuLuHpWithMsg
{
	[sentHomePageAlert show];
}

#pragma mark UIAlertViewDelegate
// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == sentHomePageAlert) {
        if (buttonIndex == 0)
        {
            // OKの場合のみCaLuLuホームページを開く
            [Common openCaluLuHomePage];
        }
    }

    if (alertView == saveCheckAlert) {
        //取り込み画像の保存確認
        if (buttonIndex == 0){
#ifdef TRIAL_VERSION
            // トライアルバージョンの場合は撮影可能枚数を取得し、超過の場合は以降の処理を行わない
            if (! [self isImportPictureEnable] )
            {	
#ifndef USE_ACCOUNT_MANAGER
                // CaLuLuホームページを開く
                [ self openCaLuLuHpWithMsg];
#else
                [MainViewController showAccountNoLoginDialog:@"規定枚数以上の\n取り込みができません。"];
#endif
                /*[btnOpenPhotoLibrary setBackgroundImage:[UIImage  imageNamed:@"import_photo_Library.png" ]
                                               forState:UIControlStateNormal];*/

                iPadTouchView.image =nil;
                return; 
            }
#endif
            [self saveImageFile:iPadTouchView.image];
//            [btnOpenPhotoLibrary setBackgroundImage:[UIImage  imageNamed:@"import_photo_Library.png" ]
//                                           forState:UIControlStateNormal];
            // シャッター音を鳴らす
            [self performSelector:@selector(shutterSoundDelay) 
                       withObject:nil afterDelay:0.5f];
            
            // iPadTouchView.image =nil;
        }else {
            iPadTouchView.image =nil;
//            [self OnOpenPhotoLibrary:btnOpenPhotoLibrary];
        }
    }
}

- (void) shutterSoundDelay
{
	[Common playSoundWithResouceName:@"shutterSound" ofType:@"mp3"];
}


#endif

#pragma mark frame_work

- (id)init
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    self = [super init];
    if (self) {
        CameraButtons = nil;
        CameraSelFunc = nil;
        CamSelect = nil;
    }
    
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    gridLineView.alpha = 0.3;
    
    isSaved = false;
    isBackGround = NO;
	airmicro = nil;
	// [self initAirMicro:CGRectMake(64, 240, 640, 480)];
	
    camera3RView.hidden = YES;
    camera3RView.layer.cornerRadius = 20;
    camera3RView.clipsToBounds = true;
    
	//　ピッカーの初期化
	[self pickerInit];
	
	// GameKit初期化
	self._peerId = nil;
	_gkSession = nil;
	
	_buffer4DivedPacks = nil;
	
	thumbnailVC = nil;
	
	popoverCntlCamViewSetting = nil;
    
    videoRecLock = nil;
    reInit = NO;
    
    silhouetteGuideimageView = [[UIImageView alloc] init];
    [self.view addSubview:silhouetteGuideimageView];
    
    selectedsilhouetteGuide = 0;
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    cameraMode = [df integerForKey:@"CAM_SELECT"];;

#ifndef CALULU_IPHONE
	_isToolBarTop = NO;
#else
    _isToolBarTop = YES;
    [btnToolBarShow setBackgroundImage:[UIImage  imageNamed:@"toolbar_on.png" ]
                              forState:UIControlStateNormal];
#endif
	
	// 各Viewの角を丸くする
	[Common cornerRadius4Control:vwBottomPanel];
	[Common cornerRadius4Control:lblHandVibProc];
    [Common cornerRadius4Control:lblBlueToothState];
	
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	BOOL stat;
	
	// 設定ファイルより各カメラデバイスの有効／無効を取得
#ifndef DISABLE_AIR_MICRO
	if (! [defaluts objectForKey:@"airmicro_enable"])
	{
		stat = NO;              // デフォルトは無効
		[defaluts setBool:stat forKey:@"airmicro_enable"]; 
	}
	else {
		stat = [defaluts boolForKey:@"airmicro_enable"];
	}
#else
	// 通常版は常にAirMicroカメラを無効とする
	stat = NO;
#endif
	if (!stat)
	{
		// AirMicroカメラ無効
//		[segCtrlSwicthCamera removeSegmentAtIndex:0 animated:NO];
//		segCtrlSwicthCamera.tag &= ~(0x01);
		
		btnAirMicro.hidden = YES;
		btnAirMicro.tag = CM_VC_CAMERA_DISABLE;
	}

	// 初回起動時は設定値はNULLなので、ここで書き込み
	if (! [defaluts objectForKey:@"ipodTouch_camera_enable"])
	{	
		stat = NO;
		[defaluts setBool:stat forKey:@"ipodTouch_camera_enable"]; 
	}
	else {
		stat = [defaluts boolForKey:@"ipodTouch_camera_enable"];
	}
	
	if (! stat)
	{
		// iPod Touchカメラ無効
//		[segCtrlSwicthCamera removeSegmentAtIndex:1 animated:NO];
//		segCtrlSwicthCamera.tag &= ~(0x02);
		btniPadCamera.hidden = YES;
		btniPadCamera.tag = CM_VC_CAMERA_DISABLE;
#ifndef CALULU_IPHONE
		if (! btnAirMicro.hidden)
		{
			// AirMicroカメラボタン位置をiPodカメラボタン位置に移動
			// DELC SASAGE // btnAirMicro.frame = btniPadCamera.frame;
		}
#endif
	}
	
	// 設定ファイルよりbluetooth名を取得
	if ([defaluts stringForKey:@"ipodTouch_camera_name"])
	{
		_sessionName 
			= [NSString stringWithString:[defaluts stringForKey:@"ipodTouch_camera_name"]];
	}
	else 
	{
		_sessionName = @"OkdIPad4Camera";
		[defaluts setObject:_sessionName forKey:@"ipodTouch_camera_name"]; 
	}
	NSLog(@"sesson name -> %@", _sessionName);
	
	for (NSString *name in [defaluts volatileDomainNames])
	{	NSLog (@"volatileDomainName : %@", name); }
	for (NSString *name in [defaluts persistentDomainNames])
	{	NSLog (@"persistentDomainNames : %@", name); }
	
	// iPad2内蔵カメラのセットアップ
	[self setup4iPad2InnerCamera];
    ipadExposure = 0.0f;
    
    // Webカメラ操作のインスタンス作成
    _webCameraDaemon = [[WebCameraDeamon alloc] initWithPrevView:iPadTouchView
                                                    hStateNotify:^(BOOL isError, NSString* message){
                                                        [self bluetoothStateDisp:isError message:message];
                                                        // シャッターボタンのenableもこの通知で設定
                                                        btnCamShutter.enabled = ! isError;
                                                    }
                        ];
    // 有効の場合のみ選択ボタンを表示する
    btnWebCamera.hidden = YES;
    
    // Sonyカメラ 操作クラス
    _SonyCameraDaemon = [[SonyCameraRemoteViewController alloc] initWithPrevView:iPadTouchView
                                                                  statusDelegate:self];
    [Common cornerRadius4Control:CamZoomView];
    CamZoomView.hidden = YES;
    CamZoomView.alpha = 0.5f;
    [Common cornerRadius4Control:CamExposureView];
    CamExposureView.hidden = YES;
    CamExposureView.alpha = 0.5f;
    
    btnCamRotate.alpha = 0.5f;
    btnCamRotate.hidden = YES;
    
    // Sonyカメラの初期化フラグ
    isInitCamExposure = NO;
    isInitCamZoom = NO;
    
    CamRotate[0] = 0;   CamRotate[1] = 90;   CamRotate[2] = 180;   CamRotate[3] = 270;
    
    webCamExposure  = [defaluts integerForKey:@"web_cam_exposure"];
    webCamZoom      = [defaluts integerForKey:@"web_cam_zoom"];
    webCamRotate    = [defaluts integerForKey:@"web_cam_rotate"];
    sonyExposure    = webCamExposure;

    //ボタンの長押し設定部分
    UILongPressGestureRecognizer *gestureW = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedWide:)];
    [btnZoomWide addGestureRecognizer:gestureW];
    [gestureW release];
    UILongPressGestureRecognizer *gestureT = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedTele:)];
    [btnZoomTele addGestureRecognizer:gestureT];
    [gestureT release];
    
    // 動画契約がある場合のみ、撮影可能にする
    [self checkVideoAccount];
	
	// スワイプのセットアップ
	[self setupSwipLongTouchSupport];
	
	// 重ね合わせ画像／ガイド線も一緒に保存するかフラグをリセット
    if (! _webCameraDaemon.isWebCameraEnable) {
	_isWithOverlaySave = NO;
	_isWithGuideSave = NO;
    }
    else {
	_isWithOverlaySave = NO;
	_isWithGuideSave = YES;
    }
    lastCameraModeChange = 0;

    // デフォルトで内蔵カメラを選択
    [self _setupDefaultInnerCamera];
    
    // モーションセンサーを準備
    cmm = [CMMotionManager new];

    if (cmm.accelerometerAvailable){
        cmm.accelerometerUpdateInterval = 0.1f;
        // ハンドラを設定
        CMAccelerometerHandler handler = ^(CMAccelerometerData *data, NSError *error)
        {
            double xac = data.acceleration.x;
            double yac = data.acceleration.y;
            // 傾きを算出
            degree = fabs(( atan2(yac, xac) * 180 / M_PI ) + 90);

            if(degree <= 270 && degree > 180){
                degree = degree - ((degree - 180)*2);
            }
            // 画面に表示
            lblAttitude.text= [NSString stringWithFormat:@"%.0f°", degree];
            
        };
        
        // 加速度の取得開始
        [cmm startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    //アラート初期化
    sentHomePageAlert = [[UIAlertView alloc]
                         initWithTitle:@"ご案内"
                         message:@"お試し版では\nこれ以上の撮影ができません。\n製品版のご案内のため\nABCarteホームページを開きます。"
                         delegate:self
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:@"キャンセル", nil
                         ];
    saveCheckAlert = [[UIAlertView alloc]initWithTitle:@"写真アルバムの取り込み"
                                               message:@"この画像を取り込みますか？"
                                              delegate:self
                                     cancelButtonTitle:@"はい"
                                     otherButtonTitles:@"いいえ" ,nil];

    btnSonyCamera = [[UIButton alloc]init];
    [btnSonyCamera retain];

#ifdef NEW_CAM_LAYOUT
    [self CamButtonInit];
    vwBottomPanel.hidden = YES;
#else
    CamControll.hidden = YES;
#endif
    
    rapidFireLock = NO;
    CamSelectDot.userInteractionEnabled = YES;
    
    btniPad2InnerCamera.hidden = YES;
    btniPad2InnerCamera.enabled = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    //round 3rcamera button
    btn3RCameraSetting.layer.cornerRadius = 20;
    btn3RCameraSetting.clipsToBounds = true;
    btn3RCameraSetting.hidden = true;
    
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    if (reInit==YES) {
#ifdef DEBUG
        NSLog(@"Do CamButtonInit");
#endif
        [self CamButtonInit];
        // デフォルトで内蔵カメラを選択
//        [self _setupDefaultInnerCamera];

        reInit = NO;
    }
    // カメラ選択スライドボタンの表示位置調整
    [CamSelectDot setPos:CamSelNumber];
    [CamSelect setLabelColor:CamSelNumber];
}

- (void)viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	[super viewDidAppear : animated];
	
	/*
	NSInteger selected 
		= segCtrlSwicthCamera.selectedSegmentIndex;
	*/
	btnCameraMode.enabled = NO;
	// cameraViewのActiv
	[self didBecomeActive];
	
	// シャッターとフリーズボタンの有効／無効設定
	[self setShutterFreezeButton];
	
	// TODO:施術日の設定
	lblWorkDate.text = [self getWorkDateByLocalTime];
	// lblWorkDate.hidden = YES;
	// lblWorkDateTitle.hidden = YES;
    
    // 動画契約がある場合のみ、撮影可能にする
    [self checkVideoAccount];
    
    // Webカメラ契約がある場合の設定
    if ([AccountManager isWebCam]) {
        camaraViewController *cameraView
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView;
        if (cameraView)
        {   [cameraView setWebCameraEnableWithIsFlag:YES]; }
    }
    btnWebCamera.hidden = YES;

    // ページ戻り時にwebカメラ選択状態をクリアするように変更したので、戻った時に復帰処理を行わせるため
    for (int i=0; i<[CameraSelFunc count]; i++) {
        if (i==CamSelNumber) {
            CamSelNumber = -1;
            [self CamSelectKind:i];
            break;
        }
    }
    
    rapidFireLock = NO;
    CamSelectDot.userInteractionEnabled = YES;

    // アプリケーション使用容量設定値の自動設定を行う
    APCValueEnable valEnable = [appCapacityManager setAutoAppUsingCapacity];
    if (valEnable.freeDevSpace < 100.0f) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ご注意"
														message:@"空き容量が100MB未満になった為、\n画像・動画の撮影を中止します\niPad内の不要なコンテンツ等を\n削除し容量を確保して下さい"
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		
        [self OnUserSelect];
	} else if (valEnable.freeDevSpace < 500.0f) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ご注意"
														message:@"空き容量が500MB未満になりました\n不要なコンテンツ等を削除し、\n容量を確保して下さい\n空き容量が100MB未満になると、\nデータ保護の為に画像・動画の撮影が\n出来なくなります"
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
//        // 空き容量がないので、この画面を閉じて前画面に戻る
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^{
//            [Common showDialogWithTitle:@"ご注意"
//                                message:@"お使いのiPadには\n空き容量がありません\n\n不要なコンテンツなどを\n削除して空き容量を\n確保してください"];
//            // 前画面に戻る
//            [self OnUserSelect];
//        });
    }
}

/**
 * カメラ選択スライドボタンの初期化
 */
- (void) CamButtonInit
{
    // カメラボタン画像の配列
    NSMutableArray *btnName = [[NSMutableArray alloc] init];
    NSMutableArray *lblName = [[NSMutableArray alloc] init];
    // 各ボタンの配列
    if (CameraButtons!=nil) {
        [CameraButtons release];
    }
    CameraButtons = [[NSMutableArray alloc]init];
    // 各ボタンを押下時に呼び出す関数の配列
    if (CameraSelFunc!=nil) {
        [CameraSelFunc release];
    }
    CameraSelFunc = [[NSMutableArray alloc]init];
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = 20.0f;
    if (iOSVersion<7.0f) {
        uiOffset = 0;
    }

    // iPad内蔵カメラ
    [lblName addObject:@"写真"];
    [btnName addObject:@"iPad2Camera_on.png"];
    [CameraButtons addObject:btniPad2InnerCamera];
    [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_IPAD_CAM]];
    
    // 動画契約が有る場合
    if ([AccountManager isMovie] && iOSVersion>=6.0f) {
        [lblName addObject:@"動画"];
        [lblName addObject:@"動画\n(自動停止)"];
        [btnName addObject:@"video_record.png"];
        [btnName addObject:@"video_auto.png"];
        [CameraButtons addObject:btnVideo];
        [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_IPAD_CAM]];
        [CameraButtons addObject:btnVideoAuto];
        [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_IPAD_CAM]];
    }
#ifdef DEBUG
    // Webカメラ契約が有る場合
    if ([AccountManager isWebCam]) {
        [lblName addObject:@"Web\nカメラ"];
        [btnName addObject:@"camera_web_cam.png"];
        [CameraButtons addObject:btnWebCamera];
        [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_WEB_CAM]];
    }
    
    // Sonyカメラ
    if ([AccountManager isWebCam2]) {
        if ([AccountManager isWebCam]) {
            // 旧カメラも持っているユーザの場合
            [lblName addObject:@"Web\nカメラ2"];
        } else {
            // Sonyカメラだけのユーザの場合
            [lblName addObject:@"Web\nカメラ"];
        }
        [btnName addObject:@"camera_web_cam.png"];
        [CameraButtons addObject:btnSonyCamera];
        [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_SONY_CAM]];
    }
#else
    // Webカメラ契約が有る場合(旧契約だけの場合)
    if ([AccountManager isWebCam] && ![AccountManager isWebCam2]) {
        [lblName addObject:@"Web\nカメラ"];
        [btnName addObject:@"camera_web_cam.png"];
        [CameraButtons addObject:btnWebCamera];
        [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_WEB_CAM]];
    }
    
    // Sonyカメラ
    if ([AccountManager isWebCam2]) {
        // Sonyカメラだけのユーザの場合
        [lblName addObject:@"Web\nカメラ"];
        [btnName addObject:@"camera_web_cam.png"];
        [CameraButtons addObject:btnSonyCamera];
        [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_SONY_CAM]];
    }
#endif

	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // AirMicroが有効になっている場合
    if ([defaults boolForKey:@"airmicro_enable"]) {
        [lblName addObject:@"AirMicro"];
        [btnName addObject:@"AirMicro_off.png"];
        [CameraButtons addObject:btnAirMicro];
        [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_AIRMICRO_CAM]];
    }

    // AirMicroが有効になっている場合
    if ([defaults boolForKey:@"3rcamera_enable"]) {
        [CameraButtons addObject:btn3RCamera];
        [CameraSelFunc addObject:[NSNumber numberWithInteger:SEL_3R_CAM]];
    }

    CamSelSlide = NO;

    // カメラ関連の初期値をロード
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
//    img4CameraView.guideLineNum = [df integerForKey:@"CAM_GUIDE_NUM"];
    gridLineView.guideLineNum = [df integerForKey:@"CAM_GUIDE_NUM"];
//    img4CameraView.alpha        = [df floatForKey:@"CAM_OVERLAY_ALPHA"];
    _isWithOverlaySave          = [df boolForKey:@"CAM_OVERLAY_SAVE"];
    _isWithGuideSave            = [df boolForKey:@"CAM_GUIDE_SAVE"];
    camResolution               = [df integerForKey:@"CAM_RESOLUTION"];
    NSInteger camDF             = [df integerForKey:@"CAM_SELECT"];
    // 最後に選択していたカメラの種別を設定
    CamSelNumber = (camDF<[CameraButtons count])? camDF : SEL_IPAD_CAM;

    if (CamSelect!=nil) {
        [CamSelect release];
    }
    // カメラ種別選択をラベルで行う
    CamSelect = [[CamSelectView alloc] initWithFrame:CGRectMake(13, 588 + uiOffset + 110, 70, CAM_SEL_HSIZE)
                                              labelObj:lblName initSel:2];
    CamSelectDot = [[CamSelectDotView alloc]initWithFrame:CGRectMake(0, 588 + uiOffset + 110, 70+20, CAM_SEL_HSIZE)
                                                  btnName:@"red_dot.png" btnNum:[lblName count]];
    [CamSelect setLabelColor:CamSelNumber];
    // カメラ種別選択をアイコンで行う
//    CamSelect = [[CamSelectView alloc] initWithFrame:CGRectMake(13, 588 + uiOffset, 70, 210 + 40)
//                 btnObj:btnName initSel:CamSelNumber];
    for (UIView *view in [CamControll subviews]) [view removeFromSuperview];
    // 間にUIColorを挟むと、UIViewの背景のみ透過させることができる
    UIColor *color_ = [UIColor darkGrayColor];
    UIColor *alphaColor_ = [color_ colorWithAlphaComponent:0.4f];
    
    CamControll.alpha = 1.0f;
    CamControll.backgroundColor = alphaColor_;
    //[CamControll addSubview:CamSelect];
    //[CamControll addSubview:CamSelectDot];
    CamSelect.userInteractionEnabled = NO;
//    CamSelect.camselDelegate = self;
    //CamSelectDot.camselDelegate = self;
    
    [CamControll addSubview:btnCamShutter];
    [CamControll addSubview:btnVideoRecord];
    [CamControll addSubview:btnCamFreeze];
    [CamControll addSubview:btnFrontRearChg];
    [CamControll addSubview:btnOverlayViewSetting];
    [CamControll addSubview:redDot];
    [CamControll addSubview:btnSilhouetteGuide];
    [CamControll addSubview:btnCameraMode];
    
    // UIViewとは別にalphaの設定を行う
    btnFrontRearChg.alpha = 0.4f;
    btnOverlayViewSetting.alpha = 0.4f;
    btnCamFreeze.alpha = 0.0f;
    btnCamShutter.alpha = 0.8f;
    btnVideoRecord.alpha = 0.8f;
    CamSelect.alpha = 0.5f;
    
    [btnName release];
    [lblName release];
}

#pragma mark CamSelectView Delegate
/**
 * CamSelectViewのdelegate
 * 選択されたカメラのボタン押下を実行する
 */
- (void)CamSelectKind:(NSInteger)selNum
{
#ifdef DEBUG
    NSLog(@"%s [%ld]", __func__, (long)selNum);
#endif
    if (CamSelNumber == selNum) return; // 選択されたボタンに変化が無い場合、何も処理しない

    CamSelNumber = selNum;
    CamSelSlide = YES;      // スライドボタンを連続で変更された時のマスク処理
    shutterLock = YES;      // スライドボタン変更直後にシャッターボタンを押されるのを防ぐ処理
    // ずらして実行しないと、CamSelectViewのスライドアニメーションが正しく実行されない
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        /*
        [self CameraBtnFunc:[CameraButtons objectAtIndex:selNum]
                    funcNum:cameraMode];
        [CamSelect setLabelColor:selNum];*/
        [self onCameraModeSet:cameraMode];
    });
    // スライドボタン変更後1.5秒間は撮影出来ないようにロックする
    delayInSeconds = 1.5;
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        shutterLock = NO;
        rapidFireLock = NO;
        CamSelectDot.userInteractionEnabled = YES;
    });
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    [df setInteger:selNum forKey:@"CAM_SELECT"];
    [df synchronize];
}

/**
 * 各カメラ選択ボタンの呼び出し
 */
- (void)CameraBtnFunc:(id)sender funcNum:(NSInteger)funcNum
{
    [img4CameraView setBackgroundImageHidden:NO];
    camera3RView.hidden = YES;
    CamZoomView.hidden = YES;
    CamExposureView.hidden = YES;
    btnCamRotate.hidden = YES;
    btnFrontRearChg.hidden = YES;
    switch(funcNum) {
        case SEL_IPAD_CAM:
            // iPad内蔵カメラでの撮影時
            // 通常カメラ、動画撮影
            [self OniPad2InnerCameraSelect:sender];
            btnFrontRearChg.hidden = NO;
            float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            if (iOSVersion>=8.0f) {
                CamExposureView.hidden = NO;
                [_cameraViewPicker setExposure:ipadExposure];
                CamExposureSlider.value = ipadExposure;
            }
            break;
        case SEL_AIRMICRO_CAM:
            // エアマイクロ選択時
            [self OnAirMicroCameraSelect:sender];
            break;
        case SEL_WEB_CAM:
            // Webカメラ選択時
            [self OnWebCameraSelect:sender];
            break;
        case SEL_IPOD_CAM:
            // iPodカメラ選択時(ボタン非表示になっており無効)
            [self OniPadCameraSelect:sender];
            break;
        case SEL_SONY_CAM:
            // Sonyカメラ選択時
            [self OnSonyCameraSelect];
            CamZoomView.hidden = NO;
            CamExposureView.hidden = NO;
            btnCamRotate.hidden = NO;
            CamExposureSlider.value = sonyExposure;
            break;
        default:
            break;
    }
    CamSelSlide = NO;
}

// ラベル類の位置調整
- (void)uiLayout
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = 0;
    // iOS7の場合
    if (iOSVersion>=7.0f) {
        uiOffset = 20.f;
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isPortrait;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            isPortrait = YES;
            break;
        default:
            isPortrait = NO;
            break;
    }

    float xpos = 0;
    if(!isPortrait) xpos = 256;
    
    [lblUserNameTitle setFrame:CGRectMake(457 + xpos - 100, 13 + uiOffset, 87, 21)];
    [lblUserName      setFrame:CGRectMake(536 + xpos - 100, 7  + uiOffset, 200, 29)];
    [lblUserNameDim   setFrame:CGRectMake(737 + xpos - 100, 13 + uiOffset, 42, 21)];
    [lblWorkDateTitle setFrame:CGRectMake(477 + xpos - 100, 42 + uiOffset, 87, 21)];
    [lblWorkDate      setFrame:CGRectMake(572 + xpos - 100, 38 + uiOffset, 183, 29)];
    [lblCount         setFrame:CGRectMake(518 + xpos - 100, 64 + uiOffset, 237, 38)];
    [lblAttitude      setFrame:CGRectMake(20, 13 + uiOffset, 80, 40)];
    
    lblAttitude.layer.cornerRadius = 12;
    lblAttitude.clipsToBounds = true;
    
#ifdef NEW_CAM_LAYOUT
    CGFloat amOffset = 70.0f;
    if ([CameraButtons objectAtIndex:CamSelNumber]==btnAirMicro) {
        amOffset = 70.0f;
    }
    if (CurOrientation) {
        // アイコン表示の場合は 250、ラベル表示の場合 200にする
        [CamSelect              setFrame:CGRectMake(13, 588 + uiOffset + 110, 70, CAM_SEL_HSIZE)];
        [CamSelectDot           setFrame:CGRectMake(0, 588 + uiOffset + 110, 70 + 20, CAM_SEL_HSIZE)];
        [btnCamShutter          setFrame:CGRectMake(18, 400 + uiOffset + 110, 60, 60)];
        [btnVideoRecord         setFrame:CGRectMake(18, 400 + uiOffset + 110, 60, 60)];
        [btnCamFreeze           setFrame:CGRectMake(18, 400 + uiOffset + amOffset + 110, 60, 60)];
        [btnFrontRearChg        setFrame:CGRectMake(18, 200 + uiOffset + 110, 60, 60)];
        [btnOverlayViewSetting  setFrame:CGRectMake(18, 20 + uiOffset + 110, 60, 60)];
        [redDot                 setFrame:CGRectMake(6, 706 + uiOffset + 110, 10, 10)];
        [btnSilhouetteGuide     setFrame:CGRectMake(18, 580 + uiOffset + 110, 60, 60)];
        [btnCameraMode          setFrame:CGRectMake(18, 760 + uiOffset + 110, 60, 60)];
    } else {
        [CamSelect              setFrame:CGRectMake(13, 588 + uiOffset - (1024 - 768) + 50 + 110, 70, CAM_SEL_HSIZE)];
        [CamSelectDot           setFrame:CGRectMake(0, 588 + uiOffset - (1024 - 768) + 50 + 110, 70 + 20, CAM_SEL_HSIZE)];
        [btnCamShutter          setFrame:CGRectMake(18, 230 + uiOffset + 110, 60, 60)];
        [btnVideoRecord         setFrame:CGRectMake(18, 230 + uiOffset + 110, 60, 60)];
        [btnCamFreeze           setFrame:CGRectMake(18, 230 + uiOffset + amOffset + 110, 60, 60)];
        [btnFrontRearChg        setFrame:CGRectMake(18, 100 + uiOffset + 110, 60, 60)];
        [btnOverlayViewSetting  setFrame:CGRectMake(18, 10 + uiOffset + 110, 60, 60)];
        [redDot                 setFrame:CGRectMake(6, 706 + uiOffset - (1024 - 768) + 50 + 110, 10, 10)];
        [btnSilhouetteGuide     setFrame:CGRectMake(18, 320 + uiOffset + 110, 60, 60)];
        [btnCameraMode          setFrame:CGRectMake(18, 410 + uiOffset + 110, 60, 60)];
    }
    // カメラ選択スライドボタンの表示位置調整
//    [CamSelect setPos:CamSelNumber];
    [CamSelect setLabelColor:CamSelNumber];
    [CamSelectDot setPos:CamSelNumber];

    [btnZoomTele setBackgroundColor:[UIColor whiteColor]];
    [[btnZoomTele layer] setCornerRadius:5.0];
    [[btnZoomTele layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnZoomTele layer] setBorderWidth:1.0];
    [btnZoomWide setBackgroundColor:[UIColor whiteColor]];
    [[btnZoomWide layer] setCornerRadius:5.0];
    [[btnZoomWide layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnZoomWide layer] setBorderWidth:1.0];
    
    [btnCamRotate setBackgroundColor:[UIColor whiteColor]];
    [[btnCamRotate layer] setCornerRadius:5.0];
    [[btnCamRotate layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnCamRotate layer] setBorderWidth:1.0];

    btnToolBarShow.hidden = YES;
#endif
}

// 選択されたユーザ
- (void)setSelectedUser:(USERID_INT)userID userName:(NSString*)name nameColor:(UIColor*)color
{
	if (self._selectedUserID != userID)
	{
		// 前回ユーザと異なるので、iPodのimage画像を消去する
		iPadTouchView.image = nil;
		
		// ユーザIDをここで保存
		self._selectedUserID = userID;
	}
	
	lblUserName.text = name;
	lblUserName.textColor = color;
#ifdef DEBUG
	NSLog(@"userName = %@", name);
#endif
}

#pragma mark AirMicro関連
// カメラSDKの初期化
- (void)initAirMicro:(CGRect)setRect
{
    // AirMicroアドホック接続
    airmicro =  ([[AMImageView alloc] init:self.view rect:setRect]);
    
    airmicro.delegate = self;
    [airmicro setSavePictureFolderFlag:NO];		// 写真フォルダにはコピーしない
    [airmicro setCapViewTime:2.0f];
    [airmicro setIndicator:indField];
    [airmicro setWaitImage:WAIT_IMG1 next:WAIT_IMG2];
    
    [airmicro startCapture];
    
	[airmicro setBtnControl:TRUE];
	[airmicro setFrzLabel:frzField];
	[airmicro setCapLabel:capField];
	
    [self.view addSubview:frzField];
	[self.view addSubview:capField];
	[self.view addSubview:indField];
	
	// AirMicroを最背面にする
	[self.view sendSubviewToBack:airmicro];
	// [iPadTouchView bringSubviewToFront:airmicro];
	iPadTouchView.hidden = YES;
    btnSilhouetteGuide.hidden = YES;
}

// カメラSDKの終了
- (void)destroyAirMicro
{
	@try {
		if (airmicro == nil)
		{	return; }
		
		// 関連する子viewを解除
		// ：airMicroカメラ選択以外でUIActivityIndicatorViewが残る現象に対応
		[indField removeFromSuperview];
		[capField removeFromSuperview];
		[frzField removeFromSuperview];
		
		[airmicro stopCapture];
		airmicro.hidden = YES;
		airmicro.delegate = nil;
		[airmicro removeFromSuperview];
		
		[airmicro release];
		airmicro = nil;
		
		iPadTouchView.hidden = NO;
        btnSilhouetteGuide.hidden = NO;
	}
	@catch (NSException *exception) 
	{
		NSLog(@"destroyAirMicro: Caught %@: %@", [exception name], [exception reason]);
	}
}

// AirMicroを非活性にする
- (void)dismissAirMicro
{
    // airMicroを非選択にする
    if (btnAirMicro.tag == CM_VC_CAMERA_SELECTED)
    {
        // AirMicroカメラ選択状態を反転
        if (btnAirMicro.tag != CM_VC_CAMERA_DISABLE)
        {
            btnAirMicro.tag = CM_VC_CAMERA_NOT_SELECTED;
            [btnAirMicro setImage:[UIImage imageNamed:@"AirMicro_off.png"]
                         forState:UIControlStateNormal];
        }
        
        // airMicroカメラを閉じる
        [self destroyAirMicro];
        
    }
}

#pragma mark -

// ピッカーの初期化
- (void) pickerInit
{
	picker = [[GKPeerPickerController alloc] init];
	picker.delegate = self;
	// WifiとBluetoothの両方設定（WiFiのみの設定はNG）
    picker.connectionTypesMask 
        = GKPeerPickerConnectionTypeNearby | GKPeerPickerConnectionTypeOnline;
}

#pragma mark control_events

// お客様選択画面表示イベント
- (IBAction)OnUserSelect
{
#ifdef CALULU_IPHONE
    // ModalPopupが表示されている時は画面遷移しない
    if (_isShowModalPopup)
    {   return; }
#endif
    
	// サムネイル画面を経由しての遷移の場合
	if (self.isNavigationCall)
	{
		// フラグをここでリセットする
		self.isNavigationCall = NO;
		
		// 直接popViewControllerAnimatedをコールする
		[self.navigationController popViewControllerAnimated:YES];
        ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView = nil;
	}
	else 
	{
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
		// 現時点で最上位のViewController(=self)を削除する
		MainViewController *mainVC 
			= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		[mainVC closePopupWindow:self];
        ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).cameraView = nil;
        });
	}

    // Webカメラに到達出来ない場合に、遅れてエラー通知が表示されるのを防ぐ
    [self dissmiss4WebCamera];
    
    // Sonyカメラの切断
    [self dissmiss4SonyCamera];
    
    if (_cameraViewPicker.isRecording && (btnVideo.isSelected || btnVideoAuto.isSelected)) {
        [self OnVideoRecord];
    }

    // ボタン操作不可の解除
    btnWebCamera.enabled = NO;
    btniPad2InnerCamera.enabled = NO;
    btniPadCamera.enabled = NO;
    btnAirMicro.enabled = NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL saved = [defaults boolForKey:@"onDeleteNewCarte"];
    BOOL new = [defaults boolForKey:@"CarteFromNew"];
    if (saved) {
        
    } else {
        if (new) {
            [self onDeleteNewCarte];
        }
    }
    [defaults setBool:false forKey:@"onDeleteNewCarte"];
    [defaults synchronize];
}

// カメラシャッターボタンイベント
- (IBAction)OnCamShutter
{
    btnCamShutter.enabled = NO;
 
    // 連続撮影を抑制する
    if (rapidFireLock) {
        NSLog(@"vao rapidfire");
        if ((btnVideo.isSelected) || (btnVideoAuto.isSelected) ) {
            if (_cameraViewPicker.isRecording) {
                CamSelectDot.userInteractionEnabled = _cameraViewPicker.isRecording;
                [self setVideoIsRecording:!_cameraViewPicker.isRecording];
                [_cameraViewPicker takeVideo];
            }
        }
        btnCamShutter.enabled = YES;
        return;
    }
    rapidFireLock = YES;
    CamSelectDot.userInteractionEnabled = NO;
	/*NSInteger selected
		= segCtrlSwicthCamera.selectedSegmentIndex; */
  @try 
  {
#ifdef TRIAL_VERSION
	// トライアルバージョンの場合は撮影可能枚数を取得し、超過の場合は以降の処理を行わない
	if (! [self isTakePictureEnable] )
	{	
		
#ifndef USE_ACCOUNT_MANAGER
		// CaLuLuホームページを開く
		[ self openCaLuLuHpWithMsg];
#else
		[MainViewController showAccountNoLoginDialog:@"規定枚数以上の\n撮影ができません。"];
        rapidFireLock = NO;
#endif
		return; 
	}
	
#endif
      if (shutterLock==YES) {
          NSLog(@"shutterlock");
          return;
      }
	
	// if ( ((segCtrlSwicthCamera.tag & 0x01) != 0) && (selected == 0))
	if (btnAirMicro.tag == CM_VC_CAMERA_SELECTED)
	{
	// airMicroカメラ選択時
		NSLog(@"vao airmicro");
        
		// カメラボタン操作の切り替え
		[airmicro setBtnControl:NO];
	
		[airmicro savePicture];
        
        rapidFireLock = NO;
        CamSelectDot.userInteractionEnabled = YES;
        btnCamRotate.userInteractionEnabled = YES;
	}
	/*else if  ( (((segCtrlSwicthCamera.tag & 0x01) == 0) && (selected == 0)) ||
			   ((segCtrlSwicthCamera.tag == 0x03) && (selected == 1)))*/
      
    else if (btn3RCamera.tag == CM_VC_CAMERA_SELECTED)
    {
        rapidFireLock = NO;
        NSLog(@"vao 3r camera");
        UIImage *image = [_mjpegStreamView getImage];
        [self saveImageFile:image];
        [_mjpegStreamView play];
//        UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
    }
      
	else if (btniPadCamera.tag == CM_VC_CAMERA_SELECTED)
    {
	// iPodTouchカメラ選択時
		// iPodTpuchへファイル送信を要求する
        NSLog(@"vao ipodtouch");
		[self sendIpodTouchCommand:IPOD_SEND_COMMAND_FILE_SEND_REQUEST sendData:nil];
	}
	else if (btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED)
	{
        [SVProgressHUD showWithStatus:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
        NSLog(@"vao innercamera");
	// iPad2内蔵カメラ選択時
		// 手ぶれ補正中ラベルを表示する
		if (_camViewIsHandVib)
		{
			lblHandVibProc.alpha = 1.0f;
		}			
		
		// 内蔵カメラで撮影する
		[_cameraViewPicker takePicture];
	}
    else if (btnWebCamera.tag == CM_VC_CAMERA_SELECTED)
    {
        [SVProgressHUD showWithStatus:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
        NSLog(@"vao webcamera");
        btnCamShutter.enabled = NO;  // ２重防止のため
        [_webCameraDaemon savePhoteWithSaveHandler:^(BOOL isError, UIImage *pictureImage)
         {
             btnCamShutter.enabled = YES;
             
             if ( (isError) || (! pictureImage) )
             {
                 [Common showDialogWithTitle:@"画像保存エラー" 
                                     message:@"Webカメラより画像が\n取得できませんでした\n(誠に恐れ入りますが\n再度操作をお願いいたします)"];
                 [SVProgressHUD dismiss];
             }
             else 
             {
                 [self saveImageFile:pictureImage];
             }
             rapidFireLock = NO;
             CamSelectDot.userInteractionEnabled = YES;
         }];
    }
    else if ((btnVideo.isSelected) || (btnVideoAuto.isSelected) )
    {
        // 動画撮影選択時（手動・自動共）:動画撮影開始または停止
        NSLog(@"vao video");
        [self OnVideoRecord];
    }
    else if(_SonyCameraDaemon.tag == CM_VC_CAMERA_SELECTED) {
        NSLog(@"vao sony");
        if (!isSonyConnected)
        {   // カメラ切り替え後で、接続中の場合
            rapidFireLock = NO;
        } else {
            // Sonyカメラでの写真撮影
            [self OnSonyCameraTakePicture];
        }
    }
    btnCamShutter.enabled = YES;
  }
  @catch (NSException* exception) {
		NSLog(@"onCamShutter: Caught %@: %@", 
			  [exception name], [exception reason]);
  }
}

// カメラフリーズボタンイベント
- (IBAction)OnCamFreeze
{
    if (shutterLock==YES) {
        return;
    }

	// 状態を反転
	_freezeStat = !_freezeStat;

	if (btnAirMicro.tag == CM_VC_CAMERA_SELECTED)
	{
		// airMicroカメラ選択時
		[airmicro setFreeze:_freezeStat];
	}
}

// FrontRear切替(iPad2用)ボタンイベント
- (IBAction)OniPad2FrontRearChange
{
	// Rearカメラ使用中フラグを反転
	_isRearCameraUse = ! _isRearCameraUse;
	
	// セッションの終了
	[ _cameraViewPicker endSession];
	
    // セッションの開始
    if ( btnVideoAuto.isSelected )
    {
        [_cameraViewPicker startVideoSessionWithPrevView:iPad2InnerCameraView
                                         isRearCameraUse:_isRearCameraUse
                                                  isAuto:YES];
    }
    else if ( btnVideo.isSelected )
    {
        [_cameraViewPicker startVideoSessionWithPrevView:iPad2InnerCameraView
                                         isRearCameraUse:_isRearCameraUse
                                                  isAuto:NO];
    }
    else
    {
        [_cameraViewPicker startSessionWithPrevView:iPad2InnerCameraView
								isRearCameraUse:_isRearCameraUse];
	
	}
    
    //Set back exposure to default when change front camera
    [_cameraViewPicker setExposure:0];
    CamExposureSlider.value = 0;

    // デバイス状態を通知
    [self notify4iPad2CameraViewPicker];
}

#ifdef NONUSE
// 選択画面ボタン表示イベント
- (IBAction)OnSelectedWindowShow
{
	// サムネイル画面の表示
	if (! thumbnailVC)
	{
		thumbnailVC = [[ThumbnailViewController alloc] 
				initWithNibName:@"ThumbnailViewController" bundle:nil];
	}
	// 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
	[thumbnailVC setSelectedUserID:_selectedUserID];
	
	thumbnailVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//	[self presentModalViewController:thumbnailVC animated:YES];
    [self presentViewController:thumbnailVC animated:YES completion:nil];
	
	[thumbnailVC setSelectedUserName:lblUserName.text
						   nameColor:lblUserName.textColor];
	
	// [thumbnailVC release];
	// thumbnailVC = nil;
	
	// 現時点で最上位のViewController(=self)を削除する
	// [ [self parentViewController] dismissModalViewControllerAnimated:YES];	
	
}
- (IBAction)OnSelectedWindowShow__
{
	ThumbnailViewController *_thumbnailVC = [[ThumbnailViewController alloc] 
				   initWithNibName:@"ThumbnailViewController" bundle:nil];
	
	// 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
	[_thumbnailVC setSelectedUserID:_selectedUserID];
	
	// サムネイル画面の表示
	[self.navigationController pushViewController:_thumbnailVC animated:YES];
	
	[_thumbnailVC setSelectedUserName:lblUserName.text 
							nameColor:lblUserName.textColor];
	
	[_thumbnailVC release];
	
	// 現時点で最上位のViewController(=self)を削除する
	// [ [self parentViewController] dismissModalViewControllerAnimated:YES];
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC closePopupWindow:self];

	
}
#endif

// 3R Camera
- (void)dismiss3RCamera {
    NSLog(@"in view %@",self.view.subviews);
    [_mjpegStreamView removeFromSuperview];
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSLog(@"success to save");
    [self saveImageFile:image];
    [_mjpegStreamView play];
}

-(void)callBack{
    if (lock3R == NO) {
        [SVProgressHUD showWithStatus:@"しばらくお待ちください"];
        UIImage *image = [_mjpegStreamView getImage];
        lock3R = YES;
        [self saveImageFile:image];
        [_mjpegStreamView play];
//        UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
    } else {
        
    }
}

- (void)init3RCamera {
    //init
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callBack) name:@"snapSignal" object:nil];
    lock3R = NO;
    
    camera3RSlider.minimumValue = 0;
    camera3RSlider.maximumValue = 100;
    camera3RSlider.value = 50;
    camera3RSlider.continuous = NO;
    
    _mjpegStreamSetting = [[MjpegStreamSetting alloc] init];
    [_mjpegStreamSetting initWebContent];
    
    int mainScreenViewx = [[UIScreen mainScreen] bounds].size.width;
    int mainScreenViewy = [[UIScreen mainScreen] bounds].size.height;
//    _mjpegStreamView = [[MjpegStreamView alloc] initWithFrame:CGRectMake(0, 0, mainScreenViewx - CamControll.frame.size.width, mainScreenViewy)];
    _mjpegStreamView = [[MjpegStreamView alloc] initWithFrame:CGRectMake(0, 0, mainScreenViewx, mainScreenViewy)];
    NSLog(@"mainscreen x = %d y = %d",mainScreenViewx,mainScreenViewy);
    NSLog(@"print mpeg view %@",_mjpegStreamView);
    [img4CameraView addSubview:_mjpegStreamView];
    [_mjpegStreamView play];
    
//    double delayInSeconds = 5.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        //code to be executed on the main queue after delay
//        property_control_info_t property = [_mjpegStreamSetting getProperty:@"Brightness"];
//        _brightnessID = property.pId;
//        camera3RSlider.minimumValue = property.pMin;
//        camera3RSlider.maximumValue = property.pMax;
//        camera3RSlider.value = property.pDefaultValue;
//        NSLog(@"cammera minumum = %d max = %d property = %d",property.pMin,property.pMax,property.pDefaultValue);
//        camera3RView.hidden = NO;
//    });
}

- (void)on3RCameraSelect:(id)sender {
    if (_cameraViewPicker.isRecording) {
        return;
    } else
    {
        // 選択状態を反転
        btn3RCamera.tag = CM_VC_CAMERA_SELECTED;
//        [btn3RCamera setImage:[UIImage imageNamed:@"AirMicro_on.png"]
//                     forState:UIControlStateNormal];
        if (btniPadCamera.tag != CM_VC_CAMERA_DISABLE)
        {
            btniPadCamera.tag = CM_VC_CAMERA_NOT_SELECTED;
            [btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_off.png"]
                           forState:UIControlStateNormal];
        }
        lblAttitude.hidden = YES;
        iPadTouchView.hidden = YES;
        // メッセージを消去
        lblBlueToothState.alpha = 0.0f;
        //hidden Silhouette
        btnSilhouetteGuide.hidden = YES;
        
        // 先に サーバ(iPod touch)より切断する
        [_gkSession disconnectFromAllPeers];
        
        // iPad2内蔵カメラの非活性への切り替え:非選択では何もしない
        [self dissmiss4iPad2Camera:YES];
        
        // Webカメラの非活性:非選択では何もしない
        [self dissmiss4WebCamera];
        
        // Sonyカメラを非活性にする
        [self dissmiss4SonyCamera];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callBack) name:@"snapSignal" object:nil];
        
        //init
        [self init3RCamera];
        btnVideoRecord.hidden = YES;
        btnCamShutter.hidden = NO;
        btnCamFreeze.hidden = YES;
        btn3RCameraSetting.hidden = YES;
    }
}

// AirMicroカメラ切り替え(カスタムボタン)
- (IBAction)OnAirMicroCameraSelect:(id)sender
{
    if (_cameraViewPicker.isRecording) {
        return;
    }
	if (btnAirMicro.tag == CM_VC_CAMERA_SELECTED)
	{	
		// airMicroカメラを閉じる
		[self destroyAirMicro];
		
		// airMicroの選択状態を反転
		btnAirMicro.tag = CM_VC_CAMERA_NOT_SELECTED;
		[btnAirMicro setImage:[UIImage imageNamed:@"AirMicro_off.png"] 
					 forState:UIControlStateNormal];
	}
	else 
	{
		// 選択状態を反転
		btnAirMicro.tag = CM_VC_CAMERA_SELECTED;
		[btnAirMicro setImage:[UIImage imageNamed:@"AirMicro_on.png"] 
					 forState:UIControlStateNormal];
		if (btniPadCamera.tag != CM_VC_CAMERA_DISABLE)
		{ 
			btniPadCamera.tag = CM_VC_CAMERA_NOT_SELECTED; 
			[btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_off.png"] 
						   forState:UIControlStateNormal];
		}
        
        lblAttitude.hidden = YES;
        // メッセージを消去(webカメラ接続ステータス)
        lblBlueToothState.alpha = 0.0f;
        
		// 先に サーバ(iPod touch)より切断する
		[_gkSession disconnectFromAllPeers];
		
		// iPad2内蔵カメラの非活性への切り替え:非選択では何もしない
		[self dissmiss4iPad2Camera:YES]; 
        
        // 写真アルバム取り込みを非選択にする
//        [self _photeLibraryNonSelect];
        
        // Webカメラの非活性:非選択では何もしない
        [self dissmiss4WebCamera];
        
        // Sonyカメラを非活性にする
        [self dissmiss4SonyCamera];
        
        [self dismiss3RCamera];
        
		// airMicroカメラの初期化
#ifdef CALULU_IPHONE
		[self initAirMicro:CGRectMake( 0, 110, 320, 240)];
#else
   		[self initAirMicro:CGRectMake(64, 240, 640, 480)];
#endif
		
		// 重ね合わせ画像のFrame設定
		[self setOverlayImageFrame];

		// airMicroにデバイス状態を通知
		[self notify4AitMicroDeviceState];
        
        //hidden Silhouette
        btnSilhouetteGuide.hidden = YES;
	}
	
	// シャッターとフリーズボタンの有効／無効設定
	[self setShutterFreezeButton];
}

// iPodTouchカメラ切り替え(カスタムボタン)
- (IBAction)OniPadCameraSelect:(id)sender
{
    // AirMicroを非選択にする
    [self dismissAirMicro];

#ifdef BLUETOOTH_WIFI_NOT_ENABLE
	else if (btniPadCamera.tag != CM_VC_CAMERA_SELECTED)  {
		// iPadカメラボタンの表示のみ変更
		[btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_on.png"] 
					   forState:UIControlStateNormal];
		
	}
#endif
	
	// iPad2内蔵カメラの非活性への切り替え:非選択では何もしない
	[self dissmiss4iPad2Camera:YES]; 
    
    // 写真アルバム取り込みを非選択にする
//    [self _photeLibraryNonSelect];
    
    // Webカメラの非活性:非選択では何もしない
    [self dissmiss4WebCamera];
    
    [self dismiss3RCamera];
	
	if (self._peerId == nil)
	{
#ifdef BLUETOOTH_WIFI_NOT_ENABLE
		if (picker == nil)
		{  [self pickerInit]; }
		
		// ピッカーの表示
		[picker show]; 
#else
        if (! _gkSession) 
        {
        // 接続を開始
            [btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_on.png"] 
                           forState:UIControlStateNormal];
            
            // bluetooth状況を表示
            [self bluetoothStateDisp : YES message:@"外部カメラからの接続を待っています....."];
            
            // GkSessionの接続初期化(WiFiモード)
            [self _gkSessionInitWifiConnect];
        }
        else {
        // 接続をキャンセル
            [_gkSession release];
            _gkSession = nil;
            
            [btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_off.png"] 
                           forState:UIControlStateNormal];
            
            // bluetooth状況を表示
            [self bluetoothStateDisp : NO message:@"外部カメラの接続をキャンセルします"];
            
        }
#endif
	}
	else {
		// サーバ(iPod touch)より切断する
		[_gkSession disconnectFromAllPeers];
	}
	
	// シャッターとフリーズボタンの有効／無効設定
	[self setShutterFreezeButton];
	
}

// iPad2内蔵カメラ切り替え(カスタムボタン)
// 動画ボタンなどでも呼ぶように DELC SASAGE
- (IBAction)OniPad2InnerCameraSelect:(id)sender
{
    if (_cameraViewPicker.isRecording) {
        return;
    }
   UIButton *pushButton = (UIButton *)sender;
	if (! _cameraViewPicker)
	{
        float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        // 設定->一般->機能制限でカメラをOffにした場合にここを通る
        if (iOSVersion < 8.0f) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"カメラオープンエラー"
                                      message:@"カメラの起動に失敗しました。\n設定->一般->機能制限 の\nカメラ機能制限の解除を\n確認してください。"
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil
                                      ];
            [alertView show];
            [alertView release];
        } else {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"カメラオープンエラー"
                                                  message:@"カメラの起動に失敗しました。\n設定->一般->機能制限 の\nカメラ機能制限の解除を\n確認してください。"
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController
             addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                                  // 何もしない
                                              }]];
            
            [self presentViewController:alertController animated:YES completion:nil];

        }
        btnCamShutter.enabled = NO;
        btnVideoRecord.enabled = NO;

        return;
    }		// 内蔵カメラなし：念のため
    
    // iOS5以下の場合、下記の機能に対応していないため無効とする
    // AVVideoComposition videoCompositionWithPropertiesOfAsset
    if((pushButton == btnVideo) || (pushButton == btnVideoAuto) ){
        float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if(iOSVersion<6.0f) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"iOSバージョンエラー"
                                      message:@"動画撮影はiOS6以降で\nご利用できます。\nお使いのiPadのOSバージョンをアップしてください。"
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil
                                      ];
            [alertView show];
            [alertView release];
            
            return;
        }
        [img4CameraView setBackgroundImageHidden:YES];
    }
	
    long long time = [[NSDate date] timeIntervalSince1970];
    if (time < lastCameraModeChange + 2) {
        // 連打防止のため２秒は押せない
        return;
    }
    lastCameraModeChange = time;
    if (![self _oniPad2InnerCameraSelect:sender]) {
        // プライバシー設定で、カメラの許可が無い場合の処理
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"カメラオープンエラー"
                                              message:@"カメラの起動に失敗しました。\nカメラアクセスの許可を\n確認してください。"
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController
         addAction:[UIAlertAction actionWithTitle:@"キャンセル"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                              // 何もしない
                                          }]];
        
        [alertController
         addAction:[UIAlertAction actionWithTitle:@"設定"
                                            style:UIAlertActionStyleCancel
                                          handler:^(UIAlertAction *action) {
                                              // 設定画面へのURLスキーム
                                              NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                              [[UIApplication sharedApplication] openURL:url];
                                          }]];
        
        [self presentViewController:alertController animated:YES completion:nil];

        btnCamShutter.enabled = NO;
        btnVideoRecord.enabled = NO;
    } else {
        btnCamShutter.enabled = YES;
        btnVideoRecord.enabled = YES;
    }
    lblAttitude.hidden = NO;
}

- (BOOL)_oniPad2InnerCameraSelect:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    UIButton *pushButton = (UIButton *)sender;
	if (! _cameraViewPicker)
	{	return NO; }		// 内蔵カメラなし：念のため

	// iPad2内蔵カメラが選択されていた場合(スライドボタンによるカメラ選択変更の場合はカメラOFFしない)
	if (CamSelSlide==NO &&
        (((btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED) && (pushButton == btniPad2InnerCamera))
        || (btnVideo.isSelected && (pushButton == btnVideo))
        || (btnVideoAuto.isSelected && (pushButton == btnVideoAuto))))
	{
		// iPad2内蔵カメラの非活性への切り替え(プレビューはそのまま)
		[self dissmiss4iPad2Camera:NO];
		
        //2012 6/27 伊藤 カメラ終了時に取り込みボタン表示
        /*iPadTouchView.hidden = NO;
        iPad2InnerCameraView.hidden = YES;
        btnOpenPhotoLibrary.hidden = NO;*/
        
		// シャッターとフリーズボタンの有効／無効設定
		[self setShutterFreezeButton];
		
		return YES;
	}
    // iPad2内蔵カメラの非活性への切り替え(プレビューはそのまま)
    [self dissmiss4iPad2Camera:NO];
    if (pushButton == btniPad2InnerCamera) {
        // iPad2内蔵カメラを選択状態にする
        btniPad2InnerCamera.tag = CM_VC_CAMERA_SELECTED;
        //[btniPad2InnerCamera setImage:[UIImage imageNamed:@"iPad2Camera_on.png"]
        //                     forState:UIControlStateNormal];
	} else if(pushButton == btnVideo){
        [btnVideo setSelected:YES];
    } else if(pushButton == btnVideoAuto){
        [btnVideoAuto setSelected:YES];
    }
	// iPodカメラを非選択にする
	// if (btniPadCamera.tag == CM_VC_CAMERA_SELECTED)
	{
		btniPadCamera.tag = CM_VC_CAMERA_NOT_SELECTED; 
		[btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_off.png"] 
					   forState:UIControlStateNormal];
		
        // メッセージを消去
        lblBlueToothState.alpha = 0.0f;
        
		// サーバ(iPod touch)より切断する
		[_gkSession disconnectFromAllPeers];		
	}
	
	// airMicroを非選択にする
    [self dismissAirMicro];
    
    [self dismiss3RCamera];
    
    // 写真アルバム取り込みを非選択にする
//    [self _photeLibraryNonSelect];
    
    // Webカメラの非活性:非選択では何もしない
    [self dissmiss4WebCamera];
    
    // Sonyカメラの切断と、非選択状態
    [self dissmiss4SonyCamera];

    // プレビュー表示の切り替え
	iPadTouchView.hidden = YES;
	iPad2InnerCameraView.hidden = NO;
	
	// 重ね合わせ画像のFrame設定
	[self setOverlayImageFrame];
	
	// シャッターとフリーズボタンの有効／無効設定
	[self setShutterFreezeButton];
	
	// セッションの開始
    if (pushButton == btniPad2InnerCamera) {
        if (![_cameraViewPicker startSessionWithPrevView:iPad2InnerCameraView
                                    isRearCameraUse:_isRearCameraUse])
            return NO;
    } else if(pushButton == btnVideo){
        if (![_cameraViewPicker startVideoSessionWithPrevView:iPad2InnerCameraView
                                         isRearCameraUse:_isRearCameraUse
                                                  isAuto:NO])
            return NO;
    } else if(pushButton == btnVideoAuto){
        if (![_cameraViewPicker startVideoSessionWithPrevView:iPad2InnerCameraView
                                         isRearCameraUse:_isRearCameraUse
                                                  isAuto:YES])
            return NO;
    }
	// デバイス状態を通知
	[self notify4iPad2CameraViewPicker];
    
    return YES;
}

// Webカメラ選択ボタンイベント
- (IBAction)OnWebCameraSelect:(id)sender
{
    if (_cameraViewPicker.isRecording) {
        return;
    }
    // iPodカメラを非選択にする
	if (btniPadCamera.tag == CM_VC_CAMERA_SELECTED)
	{
		btniPadCamera.tag = CM_VC_CAMERA_NOT_SELECTED; 
		[btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_off.png"] 
					   forState:UIControlStateNormal];
		
        // メッセージを消去
        lblBlueToothState.alpha = 0.0f;
        
		// サーバ(iPod touch)より切断する
		[_gkSession disconnectFromAllPeers];		
	}
    lblAttitude.hidden = YES;
    // AirMicroを非選択にする
    [self dismissAirMicro];
	
	// iPad2内蔵カメラの非活性への切り替え:非選択では何もしない
	[self dissmiss4iPad2Camera:YES];
    
    // Sonyカメラを非選択にする
    [self dissmiss4SonyCamera];
    
    [self dismiss3RCamera];
    
    // 写真アルバム取り込みを非選択にする
    // [self _photeLibraryNonSelect];
    
    // Webカメラのプレビュー中の場合は、プレビューを停止
    // if (_webCameraDaemon.isPreview)
    if (btnWebCamera.tag == CM_VC_CAMERA_SELECTED)
    {
        // エラーメッセージはとりあえず非表示にする
        // if (lblBlueToothState.alpha > 0.0f)
        // 転送が早く終わった場合にも、「転送完了しました」メッセージが表示されるように
        if (isBlueToothStateAnimating) {
            [lblBlueToothState.layer removeAllAnimations];
            isBlueToothStateAnimating = NO;
        }
        {   [self bluetoothStateDisp:NO message:@"Webカメラより切断します"]; }
        
        // Webカメラの非活性
        [self dissmiss4WebCamera];
        
        // シャッターボタンのenableをここで解除（状態通知ハンドラで無効のままの場合もあるため）
        btnCamShutter.enabled = YES;
        // シャッターとフリーズボタンの有効／無効設定
		[self setShutterFreezeButton];
    }
    else {
        // ２重タップ防止のため一旦、ボタン操作を不可にする
        btnWebCamera.enabled = NO;
        btniPad2InnerCamera.enabled = NO;
        btniPadCamera.enabled = NO;
        btnAirMicro.enabled = NO;
        
        [self bluetoothStateDisp:YES message:@"Webカメラに接続しています....."];
        
        // Webカメラのプレビュー開始
        [ _webCameraDaemon startPreviewWithReachNotify:^(BOOL isError, NSString* msg)
         {
             if (! isError)
             {
                 // 正常に接続
                 btnWebCamera.tag = CM_VC_CAMERA_SELECTED;
                 [btnWebCamera setImage:[UIImage imageNamed:@"camera_web_cam_on.png"] 
                               forState:UIControlStateNormal];
                 // シャッターとフリーズボタンの有効／無効設定
                 [self setShutterFreezeButton];
                 
                 // ガイド線を補正のため重ね合わせ画像のFrame設定
                 [self setOverlayImageFrame];
                 
                 if (isBlueToothStateAnimating) {
                     [lblBlueToothState.layer removeAllAnimations];
                     isBlueToothStateAnimating = NO;
                 }
                 [self bluetoothStateDisp:NO message:@"Webカメラに接続しました"];
                 btnCamShutter.enabled = YES;
                 btnVideoRecord.enabled = YES;
             }
             else {
                 [lblBlueToothState setAlpha: 0.0f];
                 // [Common showDialogWithTitle:@"Webカメラへの接続" message:msg];
                 if (isBlueToothStateAnimating) {
                     [lblBlueToothState.layer removeAllAnimations];
                     isBlueToothStateAnimating = NO;
                 }
                 // 接続に失敗した場合、ステータス表示を消えないように変更
                 [self bluetoothStateDisp:YES message:msg];
             }
             
             // ボタン操作不可の解除
             btnWebCamera.enabled = NO;
             btniPad2InnerCamera.enabled = NO;
             btniPadCamera.enabled = NO;
             btnAirMicro.enabled = NO;
         }];
        
        btnWebCamera.tag = CM_VC_CAMERA_SELECTED;
    }
	
}

- (IBAction)OnCameraModePopupShow:(id)sender{
    // カメラモード切り替えポップアップの表示
    CameraModePopup *cameraModePopup
    = [[CameraModePopup alloc]initWithPopUpViewContoller:cameraMode                                              popOverController:nil
                                                       callBack:self];
    // ポップアップViewの表示
    UIPopoverController *rPopoverCntl = [[UIPopoverController alloc]
                                         initWithContentViewController:cameraModePopup];
    cameraModePopup.popoverController = rPopoverCntl;
    [rPopoverCntl presentPopoverFromRect:btnCameraMode.bounds
                                  inView:btnCameraMode
                permittedArrowDirections:UIPopoverArrowDirectionRight
                                animated:YES];
    [rPopoverCntl setPopoverContentSize:CGSizeMake(512.0f, 100.0f)];
    
    //カメラモードの設定
    [cameraModePopup setCameraMode:cameraMode];
    
    [rPopoverCntl release];
    [cameraModePopup release];
}

- (void)onCameraModeSet:(id)sender{
    btnCameraMode.enabled = NO;
    NSInteger mode = (NSInteger)sender;
    [img4CameraView setBackgroundImageHidden:NO];
    CamZoomView.hidden = YES;
    CamExposureView.hidden = YES;
    btnCamRotate.hidden = YES;
    btnFrontRearChg.hidden = YES;
    camera3RView.hidden = YES;
    //Set back exposure to default when change front camera
    ipadExposure = 0;
    
    float iOSVersion;
    switch (mode) {
        case 0:
            [self OniPad2InnerCameraSelect:btniPad2InnerCamera];
            btn3RCameraSetting.hidden = YES;
            btnFrontRearChg.hidden = NO;
            iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            if (iOSVersion>=8.0f) {
                CamExposureView.hidden = NO;
                [_cameraViewPicker setExposure:ipadExposure];
                CamExposureSlider.value = ipadExposure;
            }
            break;
        case 1:
            [self OniPad2InnerCameraSelect:btnVideo];
            btn3RCameraSetting.hidden = YES;
            btnFrontRearChg.hidden = NO;
            iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            if (iOSVersion>=8.0f) {
                CamExposureView.hidden = NO;
                [_cameraViewPicker setExposure:ipadExposure];
                CamExposureSlider.value = ipadExposure;
            }
            break;
        case 2:
            [self OniPad2InnerCameraSelect:btnVideoAuto];
            btn3RCameraSetting.hidden = YES;
            btnFrontRearChg.hidden = NO;
            iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            if (iOSVersion>=8.0f) {
                CamExposureView.hidden = NO;
                [_cameraViewPicker setExposure:ipadExposure];
                CamExposureSlider.value = ipadExposure;
            }
            break;
        case 3:
            [self OnWebCameraSelect:btnWebCamera];
            btn3RCameraSetting.hidden = YES;
            break;
        case 4:
            [self OnSonyCameraSelect];
            btn3RCameraSetting.hidden = YES;
            CamZoomView.hidden = NO;
            CamExposureView.hidden = NO;
            btnCamRotate.hidden = NO;
            CamExposureSlider.value = sonyExposure;
            //mode = mode - 1;
            break;
        case 5:
            if (btnAirMicro.tag == CM_VC_CAMERA_DISABLE) {
                mode = 0;
                [self onCameraModeSet:mode];
            } else {
                btn3RCameraSetting.hidden = YES;
                [self OnAirMicroCameraSelect:sender];
            }
            
            /*
            if ([AccountManager isWebCam] || [AccountManager isWebCam2]) {
                mode = mode - 1;
            }else{
                mode = mode - 2;
            }*/
            break;
        case 6:
            if (btn3RCamera.tag == CM_VC_CAMERA_DISABLE) {
                mode = 0;
                [self onCameraModeSet:mode];
            } else {
                
                [self on3RCameraSelect:mode];
            }
            
        default:
            break;
    }
    cameraMode = mode;
    
    if(selectedsilhouetteGuide != 0){
        NSInteger *inSelectedsilhouetteGuide = selectedsilhouetteGuide - 1;
            [self OnShowSilhouetteGuide:inSelectedsilhouetteGuide];
    }

    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    [df setInteger:mode forKey:@"CAM_SELECT"];
    [df synchronize];
    
    btnCameraMode.enabled = YES;
}

- (IBAction)OnSilhouetteGuideShow:(id)sender{
    SilhouetteGuidePopupViewController *vc = [[[SilhouetteGuidePopupViewController alloc] init] autorelease];
    vc.delegate = self;
    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    [nc setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:nc animated:YES completion:nil];
}

/**
 シルエットガイドの表示
 */
- (void)OnShowSilhouetteGuide:(id)sender
{
    
    NSInteger index = (NSInteger)sender;
    
    if(index == -1){
        [self OnHideSilhouetteGuide];
        return;
    }
    
    // MainViewControllerの取得
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    // デバイスの向きを取得  getNowDeviceOrientation
    UIInterfaceOrientation ort = [mainVC getNowDeviceOrientation];
    
    UIImage *img = nil;
    CGRect rect;
    if (cameraMode < 4){
        switch (ort) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown:
                img = [UIImage imageNamed:[NSString stringWithFormat:@"silhouette_%ld.png",(long)index]];
                rect = CGRectMake(0, 0, 768, 1024);
                break;
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                img = [UIImage imageNamed:[NSString stringWithFormat:@"silhouette_sideways_%ld.png",(long)index]];
                rect = CGRectMake(0, 0, 1024, 768);
                break;
            default:
                img = [UIImage imageNamed:[NSString stringWithFormat:@"silhouette_%ld.png",(long)index]];
                rect = CGRectMake(0, 0, 768, 1024);
                break;
        }
    }else if (cameraMode == 4){
            switch (ort) {
                case UIInterfaceOrientationPortrait:
                case UIInterfaceOrientationPortraitUpsideDown:
                    img = [UIImage imageNamed:[NSString stringWithFormat:@"silhouette_%ld.png",(long)index]];
                    rect = CGRectMake(168, 224, 432, 576);
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                case UIInterfaceOrientationLandscapeRight:
                    img = [UIImage imageNamed:[NSString stringWithFormat:@"silhouette_%ld.png",(long)index]];
                    rect = CGRectMake(224, 0, 576, 768);
                    break;
                default:
                    img = [UIImage imageNamed:[NSString stringWithFormat:@"silhouette_%ld.png",(long)index]];
                    rect = CGRectMake(168, 224, 432, 576);
                    break;
            }
    }else{
        [self OnHideSilhouetteGuide];
        selectedsilhouetteGuide = index + 1;
        return;
    }

    //silhouetteGuideimageView = [[UIImageView alloc] initWithImage:img];
    silhouetteGuideimageView.image = img;
    [silhouetteGuideimageView setFrame:rect];
    silhouetteGuideimageView.alpha = 0.4;

    selectedsilhouetteGuide = index + 1;
}

- (void)OnHideSilhouetteGuide{
    if(silhouetteGuideimageView){
        silhouetteGuideimageView.image = nil;
        /*
        [silhouetteGuideimageView removeFromSuperview];
        //[silhouetteGuideimageView release];
        //silhouetteGuideimageView = nil;
         */
    }
    selectedsilhouetteGuide = 0;
}

#pragma mark-
#pragma mark SonyCameraSDK

- (void)OnSonyCameraSelect
{
    
    isSonyConnected = NO;
    // AirMicroを非選択にする
    [self dismissAirMicro];
    
    // iPad2内蔵カメラの非活性への切り替え:非選択では何もしない
    [self dissmiss4iPad2Camera:YES];
    
    [self dissmiss4WebCamera];
    
    [_SonyCameraDaemon setCancel:NO];
    
    [DeviceList reset];
    SampleDeviceDiscovery *deviceDiscovery =
    [[SampleDeviceDiscovery alloc] init];
    [deviceDiscovery performSelectorInBackground:@selector(discover:)
                                      withObject:self];
//    [_SonyCameraDaemon getStillSize];
//    [_SonyCameraDaemon setStillSize:@"aa"];
//    [_SonyCameraDaemon getAvailableStillSize];
//    [_SonyCameraDaemon setPostviewImageSize:@"Original"];
    
    _SonyCameraDaemon.tag = CM_VC_CAMERA_SELECTED;
    _SonyCameraDaemon.CamP_Rotate = CamRotate[webCamRotate];
    _SonyCameraDaemon.isViewVisible = YES;
    isSonySelect = YES;
    
    // シャッターとフリーズボタンの有効／無効設定
    [self setShutterFreezeButton];
    
    // シャッターボタンのenableをここで解除（状態通知ハンドラで無効のままの場合もあるため）
//    btnCamShutter.enabled = YES;
    
    // 重ね合わせ画像のFrame設定
    [self setOverlayImageFrame];
    
    [self bluetoothStateDisp:YES message:@"Webカメラに接続しています....."];
    
    [deviceDiscovery release];
}

- (void)OnSonyCameraTakePicture
{
    // メッセージPopup windowの表示
    [self bluetoothStateDisp:YES message:@"写真データ転送中..."];
    btnCamRotate.userInteractionEnabled = NO;

    UIApplication *app = [UIApplication sharedApplication];
    
    backgroundTaskIdentifer = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Do the work associated with the task.
            [app endBackgroundTask:backgroundTaskIdentifer];
            backgroundTaskIdentifer = UIBackgroundTaskInvalid;
        });
    }];
    
    [_SonyCameraDaemon takePicture:self];
    isSaved = true;
    
}

/**
 * Delegate implementation for receiving device list
 */
- (void)didReceiveDeviceList:(BOOL)isReceived
{
#ifdef DEBUG
    NSLog(@"%s: %@", __func__, isReceived ? @"YES" : @"NO");
#endif
    if (!_SonyCameraDaemon.isViewVisible) {
#ifdef DEBUG
        NSLog(@"WebCam Stop!!");
#endif
        return;
    }
    if (isReceived && isSonySelect) {
        [DeviceList selectDeviceAt:0];
        [_SonyCameraDaemon viewDidAppear:NO];
        if (isBlueToothStateAnimating) {
            [lblBlueToothState.layer removeAllAnimations];
            isBlueToothStateAnimating = NO;
        }
        [self bluetoothStateDisp:NO message:@"Webカメラに接続しました"];
        btnCamShutter.enabled = YES;
        btnVideoRecord.enabled = YES;

        isSonyConnected = YES;
    } else if (!isReceived) {
        [self bluetoothStateDisp:YES message:@"Webカメラに接続出来ませんでした"];
    }
}

// Sonyカメラの非活性への切り替え
- (void) dissmiss4SonyCamera
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    isSonySelect = NO;
    isSonyConnected = NO;
    if (!_SonyCameraDaemon) {
        return;
    }
    if (_SonyCameraDaemon.tag == CM_VC_CAMERA_SELECTED)
        [_SonyCameraDaemon viewDidDisappear:NO];
    
    _SonyCameraDaemon.tag = CM_VC_CAMERA_NOT_SELECTED;
    _SonyCameraDaemon.isViewVisible = NO;
}

// Sony カメラ撮影delegate
- (void)didReceiveSonyCameraPicture:(UIImage *)image
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [self saveImageFile:image];
    
    // 転送が早く終わった場合にも、「転送完了しました」メッセージが表示されるように
    if (isBlueToothStateAnimating) {
        [lblBlueToothState.layer removeAllAnimations];
        isBlueToothStateAnimating = NO;
    }
    [self bluetoothStateDisp : NO message:@"転送完了しました。"];
    CamSelectDot.userInteractionEnabled = YES;
    btnCamRotate.userInteractionEnabled = YES;
    rapidFireLock = NO;
    
    if (isBackGround) {
        [_SonyCameraDaemon viewDidDisappear:NO];
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // 「アプリがバックグラウンドに入っても実行し続けたい処理」が終わったと通知
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifer];
        backgroundTaskIdentifer = UIBackgroundTaskInvalid;
        });
    } else {
    // 「アプリがバックグラウンドに入っても実行し続けたい処理」が終わったと通知
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifer];
    backgroundTaskIdentifer = UIBackgroundTaskInvalid;
    }
}

// カメラZoom delegate
- (void)didZoomChanged:(int)zoomPosition
{
#ifdef DEBUG
    NSLog(@"%s [%d]", __func__, zoomPosition);
#endif
    // ズームポジションの初期化完了時
    if (isInitCamZoom || webCamZoom==zoomPosition) {
        webCamZoom = zoomPosition;
        [CamZoomSlider setValue:(float)zoomPosition];
        isInitCamZoom = YES;
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        [df setInteger:zoomPosition forKey:@"web_cam_zoom"];
        [df synchronize];
    } else {
        // ズームポジションの初期化がまだのとき
        if (webCamZoom<zoomPosition) {
            [self OnZoomWide:nil];
        } else {
            [self OnZoomTele:nil];
        }
    }
}

// カメラ露出補正 delegate
- (void)didExposureChanged:(int)exposure
{
    // 露出補正の初期化完了時
    if (isInitCamExposure || webCamExposure==exposure) {
        webCamExposure = exposure;
        CamExposureSlider.value = exposure;
        isInitCamExposure = YES;
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        [df setInteger:exposure forKey:@"web_cam_exposure"];
        [df synchronize];
    } else {
        // 露出補正の初期化がまだのとき
        if (webCamExposure>exposure) {
            [self OnExposureBright:nil];
        } else {
            [self OnExposureDark:nil];
        }
    }
}

#define ZOOM_IN     0
#define ZOOM_OUT    1

#define MOVEMENT_1SHOT  0
#define MOVEMENT_START  1
#define MOVEMENT_STOP   2

- (IBAction)OnZoomWide:(id)sender {
    [_SonyCameraDaemon zoomAction:ZOOM_OUT movement:MOVEMENT_1SHOT];
}
- (IBAction)OnZoomTele:(id)sender {
    [_SonyCameraDaemon zoomAction:ZOOM_IN movement:MOVEMENT_1SHOT];
}

- (IBAction)OnExposureChange:(id)sender {
    //if ([[CameraSelFunc objectAtIndex:CamSelNumber] integerValue]==SEL_IPAD_CAM) {
    if (cameraMode <= 3){
        [_cameraViewPicker setExposure:CamExposureSlider.value/2];
        ipadExposure = CamExposureSlider.value;
    } else {
        [_SonyCameraDaemon setExposureCompensation:(NSInteger)CamExposureSlider.value];
        sonyExposure = CamExposureSlider.value;
    }
}

- (IBAction)OnExposureDark:(id)sender {
    if (cameraMode <= 3){
    //if ([[CameraSelFunc objectAtIndex:CamSelNumber] integerValue]==SEL_IPAD_CAM) {
        float tmpExp = CamExposureSlider.value;
        
        tmpExp -= 0.1f;
        if (tmpExp<-6) {
            tmpExp = -6;
        }
        [_cameraViewPicker setExposure:tmpExp/2];

        ipadExposure = CamExposureSlider.value = tmpExp;
    } else {
        NSInteger tmpExp = (NSInteger)CamExposureSlider.value;
        
        tmpExp--;
        if (tmpExp<-6) {
            tmpExp = -6;
        }
        [_SonyCameraDaemon setExposureCompensation:tmpExp];
        
        sonyExposure = CamExposureSlider.value = tmpExp;
    }
}

- (IBAction)OnExposureBright:(id)sender {
    if (cameraMode <= 3){
    //if ([[CameraSelFunc objectAtIndex:CamSelNumber] integerValue]==SEL_IPAD_CAM) {
        float tmpExp = CamExposureSlider.value;
        
        tmpExp += 0.1f;
        if (tmpExp>6) {
            tmpExp = 6;
        }
        [_cameraViewPicker setExposure:tmpExp/2];
        
        ipadExposure = CamExposureSlider.value = tmpExp;
    } else {
        NSInteger tmpExp = (NSInteger)CamExposureSlider.value;
    
        tmpExp++;
        if (tmpExp>6) {
            tmpExp = 6;
        }
        [_SonyCameraDaemon setExposureCompensation:tmpExp];
        
        sonyExposure = CamExposureSlider.value = tmpExp;
    }
}

- (IBAction)OnCamRotate:(id)sender {
    webCamRotate = (webCamRotate>=3)? 0 : ++webCamRotate;
    _SonyCameraDaemon.CamP_Rotate = CamRotate[webCamRotate];
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    [df setInteger:webCamRotate forKey:@"web_cam_rotate"];
    [df synchronize];
    
    // 重ね合わせ画像のFrame設定
    [self setOverlayImageFrame];
}

-(void)longPressedWide:(UILongPressGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [_SonyCameraDaemon zoomAction:ZOOM_OUT movement:MOVEMENT_START];
            break;
        case UIGestureRecognizerStateEnded:
            [_SonyCameraDaemon zoomAction:ZOOM_OUT movement:MOVEMENT_STOP];
            break;
        default:
            break;
    }
}

-(void)longPressedTele:(UILongPressGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [_SonyCameraDaemon zoomAction:ZOOM_IN movement:MOVEMENT_START];
            break;
        case UIGestureRecognizerStateEnded:
            [_SonyCameraDaemon zoomAction:ZOOM_IN movement:MOVEMENT_STOP];
            break;
        default:
//            [_SonyCameraDaemon zoomAction:ZOOM_IN movement:MOVEMENT_STOP];
            break;
    }
}

#pragma mark-

// 重ね合わせ透過画像(カスタムボタン)
- (IBAction)OnOverlayViewSetting:(id)sender
{
	if (popoverCntlOverlayViewSetting)
	{
		[popoverCntlOverlayViewSetting release];
		popoverCntlOverlayViewSetting = nil;
	}
	
	// 重ね合わせ画像設定ポップアップViewControllerのインスタンス生成
//    OverlayViewSettingPopup *overlayPopUp
//        =[[OverlayViewSettingPopup alloc]initWithSetParams:img4CameraView.alpha
//                                             guideLineNums:img4CameraView.guideLineNum
//                                         isWithOverlaySave:_isWithOverlaySave
//                                           isWithGuideSave:_isWithGuideSave
//                                             camResolution:camResolution
//                                                   lblText:(btnVideo.isSelected || btnVideoAuto.isSelected)? @"動画撮影の設定を行います" : @"写真撮影の設定を行います"
//                                                      mode:(btnVideo.isSelected || btnVideoAuto.isSelected)? 1: 0
//                                         popOverController:nil
//                                          callBackDelegate:self];
    
    OverlayViewSettingPopup *overlayPopUp
    =[[OverlayViewSettingPopup alloc]initWithSetParams:img4CameraView.alpha
                                         guideLineNums:gridLineView.guideLineNum
                                     isWithOverlaySave:_isWithOverlaySave
                                       isWithGuideSave:_isWithGuideSave
                                         camResolution:camResolution
                                               lblText:(btnVideo.isSelected || btnVideoAuto.isSelected)? @"動画撮影の設定を行います" : @"写真撮影の設定を行います"
                                                  mode:(btnVideo.isSelected || btnVideoAuto.isSelected)? 1: 0
                                     popOverController:nil
                                      callBackDelegate:self];
    
#ifndef CALULU_IPHONE
	
	// ポップアップViewの表示
#ifdef NEW_CAM_LAYOUT
	popoverCntlOverlayViewSetting =
			[[UIPopoverController alloc] initWithContentViewController:overlayPopUp];
	overlayPopUp.popoverController = popoverCntlOverlayViewSetting;
	[popoverCntlOverlayViewSetting presentPopoverFromRect:btnOverlayViewSetting.frame
											   inView:CamControll
							 permittedArrowDirections:UIPopoverArrowDirectionRight
											 animated:YES];
    [popoverCntlOverlayViewSetting setPopoverContentSize:CGSizeMake(385.0f, 550.0f)];
#else
	popoverCntlOverlayViewSetting =
    [[UIPopoverController alloc] initWithContentViewController:overlayPopUp];
	overlayPopUp.popoverController = popoverCntlOverlayViewSetting;
	[popoverCntlOverlayViewSetting presentPopoverFromRect:btnOverlayViewSetting.frame
                                                   inView:vwBottomPanel
                                 permittedArrowDirections:UIPopoverArrowDirectionDown
                                                 animated:YES];
#endif // NEW_CAM_LAYOUT
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:overlayPopUp parentView:self.view];
    
    // ModalPopupの表示を設定
    _isShowModalPopup = YES;
    
#endif
	
	[overlayPopUp release];
		
}

- (IBAction)OnVideoRecord{
    if (videoRecLock || shutterLock==YES) {
        return;
    }
    videoRecLock = YES;
    CamSelectDot.userInteractionEnabled = _cameraViewPicker.isRecording;
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    [self setVideoIsRecording:!_cameraViewPicker.isRecording];
    [_cameraViewPicker takeVideo];

    // 録画開始・停止ボタンの連打を防ぐ
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
    videoRecLock = NO;
    });
}

- (IBAction)on3RCameraPressed:(id)sender {
    Camera3RSettingPopup *settingPopup = [[Camera3RSettingPopup alloc] init];
    settingPopup.modalPresentationStyle = UIModalPresentationFormSheet;
    settingPopup.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:settingPopup animated:YES completion:nil];
    settingPopup.view.superview.center = self.view.center;
}

- (IBAction)on3RSliderChange:(UISlider *)paramSender {
    [_mjpegStreamSetting setProperty:@"Brightness" ID:_brightnessID Value:paramSender.value];
}

- (NSString *)getVideoName {
    // ユーザIDによるフォルダの存在確認
	NSString *folderByID = [NSString stringWithFormat:@"%@/Documents/User%08d",
							NSHomeDirectory(), _selectedUserID ];
	NSFileManager *fileMng = [NSFileManager defaultManager];
	BOOL isFolder;
	if ( ! [fileMng fileExistsAtPath:folderByID isDirectory:&isFolder] )
	{
		// 存在しないので、フォルダを作成
		if ([fileMng createDirectoryAtPath:folderByID
               withIntermediateDirectories:YES attributes:nil error:NULL])
		{
			NSLog(@"created directory at %@", folderByID);
		}
		else
		{
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:@"フォルダ作成エラー"
									  message:@"フォルダ作成に失敗しました\n(誠に恐れ入りますが\n再度操作をお願いいたします)"
									  delegate:nil
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil
									  ];
			[alertView show];
			[alertView release];
			return (NO);
		}
	}
	// 現在の日付を取得する
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter setDateFormat:@"yyMMdd_HHmmss"];
	NSString *fileName = [formatter stringFromDate:[NSDate date]];
	NSString* filePath = [NSString stringWithFormat:@"%@/%@.mp4",
						  folderByID, fileName];
#ifdef DEBUG
	NSLog(@"video file name : %@", filePath);
#endif
    [formatter release];
    
    return filePath;
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    NSLog(@"Get Image");
#ifndef CALULU_IPHONE
    [imagePopController dismissPopoverAnimated:YES];
#else
    [self dismissModalViewControllerAnimated:YES]; 
#endif
    UIImage *oriImage = image;
    
    // MainViewControllerの取得
	MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	// 現在のデバイスの向きを取得
	UIInterfaceOrientation iOrientation = [mainVC getNowDeviceOrientation];
    // Viewサイズを取得:portraitのときは縦横反転
    CGSize ctrlSize = ((iOrientation == UIInterfaceOrientationPortrait) ||
                       (iOrientation == UIInterfaceOrientationPortraitUpsideDown) )? 
        CGSizeMake(iPadTouchView.frame.size.height, iPadTouchView.frame.size.width) : iPadTouchView.frame.size;
    
    // 縦と横の倍率でいずれか大きいほうで画像の倍率を求める
    CGFloat widthRatio = oriImage.size.width / ctrlSize.width;
    CGFloat heightRatio = oriImage.size.height / ctrlSize.height;
    CGFloat raito = (widthRatio >= heightRatio)? widthRatio : heightRatio;
    
    // 倍率より縮小後のサイズを求める
    CGFloat width  = oriImage.size.width / raito;
    CGFloat height = oriImage.size.height / raito;

    // グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(CGSizeMake(ctrlSize.width, ctrlSize.height));
    
    // グラフィックコンテキストに描画
	[oriImage drawInRect:CGRectMake((ctrlSize.width / 2) - (width / 2),
                                    (ctrlSize.height / 2) - (height / 2), width, height)];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
    iPadTouchView.image = reSizeImage;
    [saveCheckAlert show];
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    if(popoverController == imagePopController){
        /*[btnOpenPhotoLibrary setBackgroundImage:[UIImage  imageNamed:@"import_photo_Library.png" ]
                                       forState:UIControlStateNormal];*/
    }
}

// 右方向のスワイプイベント
- (void)OnSwipeRightView:(id)sender
{
    if (rapidFireLock) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"撮影中"
                                                            message:@"写真撮影中です。\nデータ保存終了するまで\nお待ちください。"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        return;
    }
    
    if (_cameraViewPicker.isRecording) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"撮影中"
                                                            message:@"動画撮影中です。\nデータ保存終了するまで\nお待ちください。"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        return;
    }

	// 前画面に戻る
	[self OnUserSelect];
}

// 長押しのイベント:iPad2内蔵カメラの設定用
- (void)OnLongPressView:(id)sender
{
	if (btniPad2InnerCamera.tag != CM_VC_CAMERA_SELECTED)
	{	return; }		// iPad2内蔵カメラが選択されていない場合は何もしない
#ifdef CALULU_IPHONE
    
    // Randscape表示では設定は不可
    if (! [MainViewController isNowDeviceOrientationPortrate])
    {   return; }
    
#endif


#ifndef CALULU_IPHONE
	// 既にポップアップViewが表示されている場合は、何もしない
	if ( (popoverCntlCamViewSetting) &&
		 (popoverCntlCamViewSetting.popoverVisible) )
	{	return; }
	
	if (popoverCntlCamViewSetting)
	{
		[popoverCntlCamViewSetting release];
		popoverCntlCamViewSetting =nil;
	}
#endif
    
	// iPad内蔵カメラの設定用popupコントローラのインスタンス生成
	iPad2CameraSettingPopup *iPad2PopUp
		=[[iPad2CameraSettingPopup alloc]initWithSetParams:POPUP_IPAD2_CAM_SET 
										 popOverController:nil 
												  callBack:self 
												 isHandVid:_camViewIsHandVib 
												 delayTime:_camViewDelayTime 
											  captureSpeed:(IPAD2_CAM_SET_CAPTURE_SPEED)_camViewCaptureSpeed];
#ifndef CALULU_IPHONE
    
	// ポップアップViewの表示
#ifdef NEW_CAM_LAYOUT
	popoverCntlCamViewSetting =
    [[UIPopoverController alloc] initWithContentViewController:iPad2PopUp];
	iPad2PopUp.popoverController = popoverCntlCamViewSetting;
	[popoverCntlCamViewSetting presentPopoverFromRect:btnOverlayViewSetting.bounds
                                               inView:btnOverlayViewSetting
                             permittedArrowDirections:UIPopoverArrowDirectionRight
                                             animated:YES];
    [popoverCntlCamViewSetting setPopoverContentSize:CGSizeMake(384.0f, 250.0f)];
#else
	popoverCntlCamViewSetting =
		[[UIPopoverController alloc] initWithContentViewController:iPad2PopUp];
	iPad2PopUp.popoverController = popoverCntlCamViewSetting;
	[popoverCntlCamViewSetting presentPopoverFromRect:vwBottomPanel.bounds
										 inView:vwBottomPanel
					   permittedArrowDirections:UIPopoverArrowDirectionDown
									   animated:YES];
#endif
#else
    iPad2PopUp.view.frame = CGRectMake(0.0f, 0.0f, 320.0f, 250.0f);
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:iPad2PopUp parentView:self.view];
#endif
	[iPad2PopUp release];
}

// 外部カメラのフォーカス用の定義
#define IPHONE_DEVICE_WIDTH     320.0f
#define IPHONE_DEVICE_HEIGHT    480.0f
#define LANNDSCAPE_OFFSET_X     576.0f      // (768÷1024)×768 = 576

// タップのイベント
- (void) _onViewSetFocus:(UITapGestureRecognizer *)sender
{	
    //カメラが起動していない場合は処理を抜ける
    // if (iPad2InnerCameraView.hidden){
#ifndef CALULU_IPHONE
    if ((btniPad2InnerCamera.tag    != CM_VC_CAMERA_SELECTED) &&
        (btniPadCamera.tag          != CM_VC_CAMERA_SELECTED) &&
        !btnVideo.isSelected &&     !btnVideoAuto.isSelected &&
        _SonyCameraDaemon.tag       != CM_VC_CAMERA_SELECTED)
#else
    // iPhone版は外部カメラに対応しない
    if (btniPad2InnerCamera.tag != CM_VC_CAMERA_SELECTED)
#endif
    {
        return;
    }
    // 下表示ダイアログが表示されている場合は、処理の対象外
    if([MainViewController isDisplayBottomModalDialog])
    {   return; }
    CGPoint point = [sender locationInView:sender.view];
    CGPoint LocatePoint = point;
    // MainViewControllerの取得
	MainViewController *mainVC 
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	// 現在のデバイスの向きを取得
	UIInterfaceOrientation toInterfaceOrientation = [mainVC getNowDeviceOrientation];
    //画面外の場合、処理しない(外周100ドットも処理しない)
    CGRect viewRect = [self get4iPad2CameraPreviewRect:(toInterfaceOrientation)];
    if(point.x < viewRect.origin.x + 100|| point.x > (viewRect.origin.x + viewRect.size.width - 100) ||
       point.y < viewRect.origin.y + 100 || point.y > (viewRect.origin.y + viewRect.size.height - 100)){
        return;
    }
    //カーソルビューを設定
    CursorBaseView.frame = viewRect;
    //パネル内の場合、処理しない
    CGRect btPnlFrame = vwBottomPanel.frame;
    if(point.x > btPnlFrame.origin.x && point.x < (btPnlFrame.origin.x + btPnlFrame.size.width) &&
       point.y > btPnlFrame.origin.y && point.y < (btPnlFrame.origin.y + btPnlFrame.size.height)){
        return;
    }
    // ツールバー表示・非表示ボタンの場合、処理しない
    CGRect btnTlbShowFrame = btnToolBarShow.frame;
    if(point.x > btnTlbShowFrame.origin.x && point.x < (btnTlbShowFrame.origin.x + btnTlbShowFrame.size.width) &&
       point.y > btnTlbShowFrame.origin.y && point.y < (btnTlbShowFrame.origin.y + btnTlbShowFrame.size.height)){
        return;
    }
    
    // 外部カメラで横向きの場合は範囲外は処理しない
    if (btniPadCamera.tag == CM_VC_CAMERA_SELECTED)
    {
        if ( (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
             (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) )
        {
            CGFloat ofs = (self.view.frame.size.width - LANNDSCAPE_OFFSET_X) / 2.0f;
            if ((point.x < ofs) || (point.x > (ofs + LANNDSCAPE_OFFSET_X) ) )
            {   return; }
        }
    }
    // 外部カメラでフォーカス中の場合は処理しない
    if (btniPadCamera.tag == CM_VC_CAMERA_SELECTED)
    {
        if (_isFocus4iPodCamera)
        {   return; }
    }
    
    CGPoint focusTaget = [self calcAFTouchPoint:point];

#ifdef DEBUG
    NSLog(@"x:%f/y:%f",focusTaget.x,focusTaget.y);
#endif
    if (!cameraFocusCursor) {
        cameraFocusCursor = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"camera_forcusTarget.png"]];
        [cameraFocusCursor setAnimationImages:[[NSArray alloc]initWithObjects:
                                               [UIImage imageNamed:@"camera_forcusTarget.png"],
                                               [UIImage imageNamed:@"camera_forcusTarget2.png"],nil]];
        cameraFocusCursor.animationDuration = 0.3;
        _cameraViewPicker.focusCursor = cameraFocusCursor;
        cameraFocusCursor.hidden = YES;
        [CursorBaseView addSubview:cameraFocusCursor];
        
    }
    [cameraFocusCursor stopAnimating];
    cameraFocusCursor.hidden = NO;
    cameraFocusCursor.alpha = 0;
    cameraFocusCursor.frame = CGRectMake(LocatePoint.x - 80 - CursorBaseView.frame.origin.x, LocatePoint.y -80 - CursorBaseView.frame.origin.y, 160, 160);
    
    [UIView animateWithDuration:0.5f animations:^{
        if (cameraFocusCursor.hidden){
            cameraFocusCursor.hidden = NO;
        }
        cameraFocusCursor.alpha = 0.5f;
        cameraFocusCursor.frame = CGRectMake(LocatePoint.x - 40 -CursorBaseView.frame.origin.x, LocatePoint.y - 40 - CursorBaseView.frame.origin.y, 80, 80);
        cameraFocusCursor.alpha = 0.5f;
        
    } completion:^(BOOL finished) {
        [cameraFocusCursor startAnimating];
        if (btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED || btnVideo.isSelected || btnVideoAuto.isSelected)
        {
            // 内蔵カメラの場合
            [_cameraViewPicker setFocus:focusTaget];
//            [_cameraViewPicker setExposure:CamExposureSlider.value];
        }
        else if (btniPadCamera.tag == CM_VC_CAMERA_SELECTED)
        {
            // 外部カメラの場合、フォーカスを要求する
            NSMutableArray *dat = [NSMutableArray array];
            
            // 指定点をiPhone用に正規化する
            CGFloat px, py;
            if ( (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
                (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) )
            {
                CGFloat ofs = (self.view.frame.size.width - LANNDSCAPE_OFFSET_X) / 2.0f;
                px = ((point.x - ofs) / LANNDSCAPE_OFFSET_X) * IPHONE_DEVICE_WIDTH;
                py = (point.y / 768.0f) * IPHONE_DEVICE_HEIGHT;
            }
            else {
                px = (point.x / 768.0f) * IPHONE_DEVICE_WIDTH;
                py = (point.y / 1004.0f) * IPHONE_DEVICE_HEIGHT;
            }
            
            [dat addObject:[NSNumber numberWithFloat:px]];
            [dat addObject:[NSNumber numberWithFloat:py]];
            [self sendIpodTouchCommand:IPOD_SEND_COMMAND_FOCUS_REQUEST sendData:dat];
            
            // フォーカス中フラグを設定
            _isFocus4iPodCamera = YES;
            
            // 一定時間後にフォーカスのアイコンを非表示
            [self performSelector:@selector(__focusIconHidden:) withObject:nil afterDelay:3.0f];
        }
        else if (_SonyCameraDaemon.tag == CM_VC_CAMERA_SELECTED)
        {
#ifdef DEBUG
            NSLog(@"Touch %.2f : %.2f  [%.2f : %.2f]", point.x, point.y, focusTaget.x, focusTaget.y);
#endif
            CGPoint pt;
            pt.x = focusTaget.x * 100;
            pt.y = focusTaget.y * 100;
            [_SonyCameraDaemon touchAF:focusTaget];
            
            // フォーカス中フラグを設定
            _isFocus4iPodCamera = YES;
            
            // 一定時間後にフォーカスのアイコンを非表示
            [self performSelector:@selector(__focusIconHidden:) withObject:nil afterDelay:2.0f];
        }
    }];
}

// AFポジションのタッチ座標の変換
- (CGPoint)calcAFTouchPoint:(CGPoint)point
{
    CGPoint focusTaget;
    
    // MainViewControllerの取得
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    // 現在のデバイスの向きを取得
    UIInterfaceOrientation toInterfaceOrientation = [mainVC getNowDeviceOrientation];

    // Sonyカメラ以外
    if (_SonyCameraDaemon.tag != CM_VC_CAMERA_SELECTED) {
        switch (toInterfaceOrientation) {
            case UIInterfaceOrientationPortrait:
                focusTaget = CGPointMake(point.y  / CAM_VIEW_PICTURE_WIDTH,1 - point.x  / CAM_VIEW_PICTURE_HEIGHT);
                break;
            case UIInterfaceOrientationLandscapeLeft:
                focusTaget = CGPointMake(point.x / CAM_VIEW_PICTURE_WIDTH, point.y  / CAM_VIEW_PICTURE_HEIGHT);
                break;
            case UIInterfaceOrientationLandscapeRight:
                focusTaget = CGPointMake(1 - point.x / CAM_VIEW_PICTURE_WIDTH,1 - point.y  / CAM_VIEW_PICTURE_HEIGHT);
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                focusTaget = CGPointMake(1 - point.y / CAM_VIEW_PICTURE_WIDTH, point.x / CAM_VIEW_PICTURE_HEIGHT);
                break;
            default:
                focusTaget = point;
                break;
        }
    } else {    // Sonyカメラの場合
        CGFloat pwidth = 768;
        CGFloat pheight = pwidth * 3 / 4;
        CGFloat lheight = 768;
        CGFloat lwidth = lheight * 4 / 3;

        switch (toInterfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown:
                switch (webCamRotate) {
                    case 0:     // デフォルト０度
                        focusTaget.x = (point.x / pwidth) * 100;
                        focusTaget.y = ((point.y - ((1024 - pheight) / 2)) / pheight) * 100;
                        break;
                    case 1:     // 時計回り90度
                        focusTaget.x = (point.y / lwidth) * 100;
                        focusTaget.y = ((768 - point.x) / lheight) * 100;
                        break;
                    case 2:     // 時計回り180度
                        focusTaget.x = ((768 - point.x) / pwidth) * 100;
                        focusTaget.y = ((1024 - point.y - ((1024 - pheight) / 2)) / pheight) * 100;
                        break;
                    default:    // 時計回り270度
                        focusTaget.x = ((1024 - point.y) / lwidth) * 100;
                        focusTaget.y = (point.x / lheight) * 100;
                        break;
                }
                break;
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                switch (webCamRotate) {
                    case 0:     // デフォルト０度
                        focusTaget.x = (point.x / lwidth) * 100;
                        focusTaget.y = (point.y / lheight) * 100;
                        break;
                    case 1:     // 時計回り90度
                        focusTaget.x = (point.y / lwidth) * 100;
                        focusTaget.y = ((1024 - point.x - ((1024 - pheight) / 2)) / pheight) * 100;
                        break;
                    case 2:     // 時計回り180度
                        focusTaget.x = ((768 - point.x) / lwidth) * 100;
                        focusTaget.y = ((1024 - point.y) / lheight) * 100;
                        break;
                    default:    // 時計回り270度
                        focusTaget.x = ((1024 - point.y) / pwidth) * 100;
                        focusTaget.y = ((point.x - ((1024 - pheight) / 2)) / lheight) * 100;
                        break;
                }
                break;
            default:
                focusTaget = CGPointMake(50.0, 50.0);
                break;
        }
        if (focusTaget.x < 0)
            focusTaget.x = 0;
        else if (focusTaget.x > 100)
            focusTaget.x = 100;
        
        if (focusTaget.y < 0)
            focusTaget.y = 0;
        else if (focusTaget.y > 100)
            focusTaget.y = 100;
    }

    return focusTaget;
}

- (void) __focusIconHidden:(id)param
{
    [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         cameraFocusCursor.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [cameraFocusCursor stopAnimating];
                         cameraFocusCursor.hidden = YES;
                         
                         // フォーカス中フラグをクリア
                         _isFocus4iPodCamera = NO;
                     }];
}

#ifdef CALULU_IPHONE

// タップのイベント
- (void) _onViewSingleTap:(id)sender
{
    // 下表示ダイアログが表示されている場合は、処理の対象外
    if([MainViewController isDisplayBottomModalDialog])
    {   return; }
    
    UIGestureRecognizer* ges = sender;
    // タップされた位置
    CGPoint pt = [ges locationInView:ges.view];
    // 判定するY座標
    CGFloat judgeYpos = ([MainViewController isNowDeviceOrientationPortrate])?
        410.0f : 250.0f;
    
    // 判定Y座標より大きい場合はボタン類のコンテナViewをタップと判定する
    if (pt.y < judgeYpos)
    {   [self OnCamShutter]; }  // 判定Y座標より小さい場合はシャッターと判定する
}

#endif

#pragma mark AMImageViewDelegate

// キャプチャー時のCallback
- (void)captureDone:(UIImage*)image
{
	NSLog(@"Capture Done");
		
	// カメラボタン操作の切り替え
	[airmicro setBtnControl:YES];
	
	[self saveImageFile:image];
	
	// setSavePictureFolderFlagをYESにするとキャプチャー時の表示Labelが表示されないので
	// ここで、それをシュミレートする
	//frzField.hidden = NO;
	/*
	capField.hidden = NO;
	[NSTimer scheduledTimerWithTimeInterval:
		(NSTimeInterval)2.5 target:self selector:@selector(onTimerLable:) 
				userInfo:nil repeats:NO];
	
	 */
	
	// また、フリーズも解除しないのでここで行う
	// [airmicro setFreeze:NO];
	
}
// フリーズ時のcallback
- (void)freezeDone:(bool)isFreeze
{
	[camFreeze setTitle: (isFreeze)?
							@"ホールドOFF" : @"ホールドON"];
	
	// フリーズが解除すればカメラボタンを機側に戻す
	[airmicro setBtnControl:YES];
	
	NSLog(@"freeze Done");
}

// 接続時のcallback from v124
- (void)connected
{
    NSLog(@"air micro connected!!");
}
// 切断時のcallback from v124
- (void)disconnected
{
    NSLog(@"air micro disconnected!!");
}
    
// カメラ画像と重ね合わせ画像を合成する
- (UIImage*) makeCombinedWithCamImage:(UIImage*)cameraImage overlayImage:(UIImage*)overlayImg
{
	// 重ね合わせ画像に何も設定されていない場合はカメラ画像をそのまま使う
	if (! overlayImg)
	{	return (cameraImage); }
	
	// グラフィックコンテキストをカメラ画像のサイズで作成
	CGRect rect = CGRectMake(0.0, 0.0, cameraImage.size.width, cameraImage.size.height);
	UIGraphicsBeginImageContext(rect.size);
	
	// グラフィックコンテキストにカメラ画像と重ね合わせ画像を書き込む
	[cameraImage drawInRect:rect];
	[overlayImg drawInRect:rect];
	
	// 合成後のImageを取得
	UIImage* img = UIGraphicsGetImageFromCurrentImageContext();	
 
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
	
	// 取得したUIImageを返す:img= autorelease
	return (img);
}

// Imageの保存
- (bool)saveImageFile:(UIImage*)cameraImage
{
	UIImage *image = nil;
    UIImage *front = nil;
	
	// 重ね合わせ画像／ガイド線も一緒に保存する場合：画像を合成する
	if ( (_isWithOverlaySave) || (_isWithGuideSave) )
	{
		// 重ね合わせ画像ViewよりImageを取得：何も設定されていないときはnil
        UIImage *gridImg
            = [gridLineView getOverlayImageWithbackgroud:NO
                                           isWithGuideLine:_isWithGuideSave];
        
        UIImage *overlayImg
        = [img4CameraView getOverlayImageWithbackgroud:_isWithOverlaySave
                                       isWithGuideLine:NO];
        if (gridImg != nil) {
            if (img4CameraView.alpha != 1) {
                front = [self makeCombinedWithCamImage:gridImg overlayImage:overlayImg];
                image = [self makeCombinedWithCamImage:cameraImage overlayImage:front];
            } else {
                if (overlayImg != nil) {
                    front = [self makeCombinedWithCamImage:overlayImg overlayImage:gridImg];
                    image = [self makeCombinedWithCamImage:cameraImage overlayImage:front];
                } else {
                    image = [self makeCombinedWithCamImage:cameraImage overlayImage:gridImg];
                }
            }
        } else {
            image = [self makeCombinedWithCamImage:cameraImage overlayImage:overlayImg];
        }
	}
	// 通常の場合：合成なし
	else 
	{	image = cameraImage; }
		
	// Imageファイル管理を選択ユーザIDで作成する
	OKDImageFileManager *imgFileMng 
		= [[OKDImageFileManager alloc] initWithUserID:_selectedUserID];
	
	// Imageの保存：実サイズ版と縮小版の保存
	//		fileName：パスなしの実サイズ版のファイル名
	NSString *fileName = [imgFileMng saveImageWithCheckSameFileName:image lastFileName:lastImageFileName];
    if (!lastImageFileName) {
        [lastImageFileName release];
    }
    lastImageFileName = [fileName copy];
	
	if (! fileName)
	{
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"写真保存エラー"
								  message:@"写真の保存に失敗しました\n(誠に恐れ入りますが\n再度操作をお願いいたします)"
								  delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil
								  ];
		[alertView show];
		[alertView release];
		
		[ imgFileMng release];
        [SVProgressHUD dismiss];
		
		return (NO);
	}
//#ifdef DEBUG
	NSLog(@"save file: => %@", fileName);
//#endif
	// データベース内の写真urlはDocumentフォルダ以下で設定 -> TODO:変更必要
	NSString *docPictUrl = 
		[NSString stringWithFormat:@"Documents/User%08d/%@",
			_selectedUserID, fileName];
    
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	// 保存したファイル名（パスなしの実サイズ版）でデータベースの履歴用のユーザ写真を追加
	bool stat = [usrDbMng insertHistUserPicture:self.histID 
									 pictureURL:docPictUrl];	// docPictUrl -> fileName
	
	// 保存したファイル名（パスなしの実サイズ版でデータベースの履歴テーブルの代表画像の更新:既設の場合は何もしない
	stat |= [usrDbMng updateHistHeadPicture:self.histID pictureURL:docPictUrl	// docPictUrl -> fileName
							isEnforceUpdate:NO];
	
	[usrDbMng release];
	
	[ imgFileMng release];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@""
                              message:@"写真を保存しました"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil
                              ];
    [alertView show];
    [alertView release];
    
	[SVProgressHUD dismiss];
    lock3R = NO;
    isSaved = true;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isSaved forKey:@"onDeleteNewCarte"];
    [defaults synchronize];
    
	return (stat);
}

// Imageの保存
- (bool)saveImageFile_:(UIImage*)image
{
	// ユーザIDによるフォルダの存在確認
	NSString *folderByID = [NSString stringWithFormat:@"%@/Documents/User%08d",
							NSHomeDirectory(), _selectedUserID ];
	NSFileManager *fileMng = [NSFileManager defaultManager];
	BOOL isFolder;
	if ( ! [fileMng fileExistsAtPath:folderByID isDirectory:&isFolder] )
	{
		// 存在しないので、フォルダを作成
		if ([fileMng createDirectoryAtPath:folderByID 
				withIntermediateDirectories:YES attributes:nil error:NULL])
		{
			NSLog(@"created directory at %@", folderByID);
		}
		else 
		{
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:@"フォルダ作成エラー"
									  message:@"フォルダ作成に失敗しました\n(誠に恐れ入りますが\n再度操作をお願いいたします)"
									  delegate:nil
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil
									  ];
			[alertView show];
			[alertView release];
			
			return (NO);
		}
	}
	
	/*
	 NSString* filePath = [NSString stringWithFormat:@"%@/%@",
	 [NSHomeDirectory() stringByAppendingFormat:@"Document"], fileName ];
	 */
	
	// 現在の日付を取得する
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"yyMMdd_HHmmss"];
	NSString *fileName = [formatter stringFromDate:[NSDate date]];
	
	/*
	NSString* filePath = [NSString stringWithFormat:@"%@/Documents/%@.jpg",
						  NSHomeDirectory(), fileName ];
	*/
	NSString* filePath = [NSString stringWithFormat:@"%@/%@.jpg",
						  folderByID, fileName];
	
	NSData *data = UIImagePNGRepresentation(image);
	
	bool stat = [data writeToFile:filePath atomically:YES];
#ifdef DEBUG
	NSLog(@"save file: => %@ : %@", filePath, (stat)? @"OK" : @"ERROR");
#endif
	// データベース内の写真urlはDocumentフォルダ以下で設定
	NSString *docPictUrl = 
		[NSString stringWithFormat:@"Documents/User%08d/%@.jpg",
				_selectedUserID, fileName];
	
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	// 保存したファイル名でデータベースの履歴用のユーザ写真を追加
	stat = [usrDbMng insertHistUserPicture:self.histID 
						pictureURL:docPictUrl];
	
	// 保存したファイル名でデータベースの履歴テーブルの代表画像の更新:既設の場合は何もしない
	stat |= [usrDbMng updateHistHeadPicture:self.histID pictureURL:docPictUrl 
							isEnforceUpdate:NO];
	
	[usrDbMng release];
	
	return (stat);
}

// キャプチャー時のタイマーイベント
- (void)onTimerLable:(NSTimer*)timer 
{
	// frzField.hidden = YES;
	capField.hidden = YES;
	
}

// 施術日を和暦で取得
-(NSString*) getWorkDateByLocalTime
{
	if (! self.workDate)
	{
		// 未だ設定されていない
		// return (@"----年--月--日　--曜日");
		
		lblWorkDate.hidden = YES;
		lblWorkDateTitle.hidden = YES;
		
		return (@"(施術なし)");
	}
	
	lblWorkDate.hidden = NO;
	lblWorkDateTitle.hidden = NO;
	
	// 時刻書式指定子を設定
    NSDateFormatter* form = [[NSDateFormatter alloc] init];
    [form setDateStyle:NSDateFormatterFullStyle];
    [form setTimeStyle:NSDateFormatterNoStyle];
    
    // ロケールを設定
    NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    [form setLocale:loc];
    
    // カレンダーを指定
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar];
    [form setCalendar: cal];
    
    // 和暦を出力するように書式指定
    //[form setDateFormat:@"GGyy年MM月dd日　EEEE"];	// 曜日まで出す場合；@"GGyy年MM月dd日EEEE"
	[form setDateFormat:@"年MM月dd日 EEEE"];
	
	//西暦出力用format
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy"];	
	
	NSString *wDate = [NSString stringWithFormat:@"%@%@",
						  [formatter stringFromDate:self.workDate],
						  [form stringFromDate:self.workDate]];
	
    [formatter release];	
	[loc release];
    [form release];
    [cal release];
	
	return(wDate);
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

// 縦横切り替え後のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIDeviceOrientationLandscapeLeft) {
        CurOrientation = NO;
    } else if (toInterfaceOrientation == UIDeviceOrientationLandscapeRight) {
        CurOrientation = NO;
    } else if (toInterfaceOrientation == UIDeviceOrientationPortraitUpsideDown) {
        CurOrientation = YES;
    } else if (toInterfaceOrientation == UIDeviceOrientationPortrait) {
        CurOrientation = YES;
    }
	// iPad2用内蔵カメラ用プレビューのRectを取得
	CGRect iPad2InViewRect = [self get4iPad2CameraPreviewRect:toInterfaceOrientation];
	
	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
			//NSLog(@"ボタンが下：正位置");
		case UIDeviceOrientationPortraitUpsideDown:
			// NSLog(@"ボタンが上：逆位置");
#ifdef CALULU_IPHONE
			[airmicro setFrame: CGRectMake(0, 110, 320, 240)];
			[airMicroButton  setFrame: CGRectMake(0, 110, 320, 240)];
			[indField setFrame:CGRectMake(150.0f, 220.0f, 20.0f, 20.0f)];
			
			// [iPadTouchView setFrame: CGRectMake(0, 110, 320, 240)];
            [iPadTouchView setFrame: iPad2InViewRect];
			[iPad2InnerCameraView setFrame:iPad2InViewRect];
			[ReConnectBluetooth setFrame: CGRectMake(0, 110, 320, 240)];
            // [vwBottomPanel setFrame:CGRectMake(10.0f, 410.0f, 264.0f, 46.0f)];
#else
            [airmicro setFrame: CGRectMake(64, 240, 640, 480)];
			[airMicroButton  setFrame: CGRectMake(64, 240, 640, 480)];
			[frzField setFrame:CGRectMake(64.0f, 210.0f, 182.0f, 22.0f)];
			[capField setFrame:CGRectMake(522.0f, 210.0f, 182.0f, 22.0f)];
			[indField setFrame:CGRectMake(374.0f, 470.0f, 20.0f, 20.0f)];
			
			// [iPadTouchView setFrame: CGRectMake(64, 240, 640, 480)];
            [iPadTouchView setFrame:iPad2InViewRect];
			[iPad2InnerCameraView setFrame:iPad2InViewRect];
			[ReConnectBluetooth setFrame: CGRectMake(64, 240, 640, 480)];
			[lblBlueToothState setFrame: CGRectMake(224, 468, 320, 50)];		// 728
			[lblMessage setFrame: CGRectMake(280, 470, 208, 22)];
			[progreBar setFrame: CGRectMake(204, 498, 360, 9)];
			[lblHandVibProc setFrame:CGRectMake(286, 876, 196, 22)];

			_isToolBarTop = NO;
			
			btnToolBarShow.hidden = YES;
			vwBottomPanel.alpha = 1.0f;
#endif
			
			break;
		case UIInterfaceOrientationLandscapeLeft:
			// NSLog(@"左回転：左が上");
		case UIInterfaceOrientationLandscapeRight:
			// NSLog(@"右回転：右が上");
#ifdef CALULU_IPHONE
            [airmicro setFrame: CGRectMake(0, 0, 480, 320)];
			[airMicroButton  setFrame: CGRectMake(0, 0, 480, 360)];
			[indField setFrame:CGRectMake(230.0f, 140.0f, 20.0f, 20.0f)];
			
			[iPadTouchView setFrame: CGRectMake(0, 0, 480, 360)];
			[iPad2InnerCameraView setFrame:iPad2InViewRect];
			[ReConnectBluetooth setFrame: CGRectMake(0, 0, 480, 360)];
            // [vwBottomPanel setFrame:CGRectMake(108.0f, 250.0f, 264.0f, 46.0f)];
#else
			[airMicroButton  setFrame: CGRectMake(0, 0, 1024, 724)];
			[airmicro setFrame: CGRectMake(0, 0, 1024, 768)];
			[frzField setFrame:CGRectMake(0.0f, 0.0f, 182.0f, 22.0f)];
			[capField setFrame:CGRectMake(842.0f - CamControll.frame.size.width, 0.0f, 182.0f, 22.0f)];
			[indField setFrame:CGRectMake(502.0f, 374.0f, 20.0f, 20.0f)];
			
			[iPadTouchView setFrame: CGRectMake(0, 0, 1024, 768)];
			[iPad2InnerCameraView setFrame:iPad2InViewRect];
			[ReConnectBluetooth setFrame: CGRectMake(0, 0, 1024, 724)];
			[lblBlueToothState setFrame: CGRectMake(352, 350, 320, 50)];        // 350
			[lblMessage setFrame: CGRectMake(408, 373, 208, 22)];
			[progreBar setFrame: CGRectMake(332, 405, 360, 9)];
			[lblHandVibProc setFrame:CGRectMake(414, 628, 196, 22)];
            
			btnToolBarShow.hidden = NO;
			[btnToolBarShow setBackgroundImage:[UIImage  imageNamed:@"toolbar_off.png" ]
									 forState:UIControlStateNormal];
			vwBottomPanel.alpha = CM_VC_BOTTOM_PANEL_LAND_ALPHA;
#endif			
			break;
		default:
			break;
	}
	
	// iPad2内蔵カメラ選択時はデバイス状態を通知
	if (btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED || btnVideo.isSelected || btnVideoAuto.isSelected)
	{
		[_cameraViewPicker notifyWillRotateToInterfaceOrientation:toInterfaceOrientation 
													  previewRect:iPad2InViewRect];
	}
    
    // Webカメラにデバイス状態を設定：選択に関わらず設定する
    _webCameraDaemon.deviceOrientation = toInterfaceOrientation;
	
	// 重ね合わせ画像のFrame設定
	[self setOverlayImageFrame:toInterfaceOrientation];
	
	// 下部のボタン類のコンテナViewのボタンレイアウト：重ね合わせ画像のありなしで変更
	[self setBottomPanelLayout:toInterfaceOrientation];
    
    [self uiLayout];
    
    if(selectedsilhouetteGuide != 0){
        NSInteger *inSelectedsilhouetteGuide = selectedsilhouetteGuide - 1;
        [self OnShowSilhouetteGuide:(id)inSelectedsilhouetteGuide];
    }
}

// コンテナViewとユーザ名の表示ボタン（横表示のみ）
- (IBAction)onShowToolBarUserName
//- (void)onAirMicroButton
{
#ifndef CALULU_IPHONE
	// 縦画面の時は何もしない
	UIScreen *screen = [UIScreen mainScreen];
	if (screen.applicationFrame.size.width == 768.0f)
	{	return; }
#endif
    
	_isToolBarTop = !_isToolBarTop;
	
	if (_isToolBarTop)
	{
		// ツールバーを最前面へ
//		[self.view bringSubviewToFront:toolBar];
		
		// お客様名関連を最前面へ
		[self.view bringSubviewToFront:lblUserNameTitle];
		[self.view bringSubviewToFront:lblUserName];
		[self.view bringSubviewToFront:lblUserNameDim];
		[self.view bringSubviewToFront:lblWorkDateTitle];
		[self.view bringSubviewToFront:lblWorkDate];
		
		[btnToolBarShow setBackgroundImage:[UIImage  imageNamed:@"toolbar_on.png" ]
								  forState:UIControlStateNormal];
		vwBottomPanel.alpha = 1.0f;
	}
	else 
	{
		// ツールバーを最背面へ
//		[self.view sendSubviewToBack:toolBar];
		
		// お客様名関連を最背面へ
		[self.view sendSubviewToBack:lblUserNameTitle];
		[self.view sendSubviewToBack:lblUserName];
		[self.view sendSubviewToBack:lblUserNameDim];
		[self.view sendSubviewToBack:lblWorkDateTitle];
		[self.view sendSubviewToBack:lblWorkDate];
		
		[btnToolBarShow setBackgroundImage:[UIImage  imageNamed:@"toolbar_off.png" ]
								  forState:UIControlStateNormal];
		vwBottomPanel.alpha = CM_VC_BOTTOM_PANEL_LAND_ALPHA;
	}

}

- (void)viewWillDisappear:(BOOL)animated
{
	// 現時点で最上位のViewController(=self)を削除する
	/*MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;*/
	// [mainVC closePopupWindow:self];
	
	// cameraViewのInActive
	[self willResignActive];
	
	// 重ね合わせ画像のリセット（cameraVC内での自動リセット）
	[img4CameraView resetBackgroundImage];
	// img4CameraView.hidden = YES;
    [gridLineView resetBackgroundImage];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidDisappear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s [%ld]", __func__, (long)[self retainCount]);
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [CamSelect removeFromSuperview];
    [CamSelectDot removeFromSuperview];
    [btnCamShutter removeFromSuperview];
    [btnVideoRecord removeFromSuperview];
    [btnCamFreeze removeFromSuperview];
    [btnFrontRearChg removeFromSuperview];
    [btnOverlayViewSetting removeFromSuperview];
    [redDot removeFromSuperview];
    [btnSilhouetteGuide removeFromSuperview];
    [btnCameraMode removeFromSuperview];
    
//    [CamControll release];
//    CamControll = nil;
//    [CamSelect release];
//    CamSelect = nil;
//    [redDot release];
//    redDot = nil;
    CamSelectDot.camselDelegate = nil;
    [CamSelectDot release];
    CamSelectDot = nil;
    
//    [CamZoomView release];
//    CamZoomView = nil;
//    [CamZoomSlider release];
//    CamZoomSlider = nil;
//    [btnZoomWide release];
//    btnZoomWide = nil;
//    [btnZoomTele release];
//    btnZoomTele = nil;
    
//    [CamExposureView release];
//    CamExposureView = nil;
//    [CamExposureSlider release];
//    CamExposureSlider = nil;
//    [btnDark release];
//    btnDark = nil;
//    [btnBright release];
//    btnBright = nil;
//    [btnCamRotate release];
//    btnCamRotate = nil;
    
    [_webCameraDaemon release];
    _webCameraDaemon = nil;
    [_SonyCameraDaemon release];
    _SonyCameraDaemon = nil;
    [btnSonyCamera release];
    btnSonyCamera = nil;

    [capField release];
    capField = nil;
    [frzField release];
    frzField = nil;
    [indField release];
    indField = nil;
    [camShutter release];
    camShutter = nil;
    [camFreeze release];
    camFreeze = nil;
    iPadTouchView.image = nil;
    [iPadTouchView release];
    iPadTouchView = nil;
    [iPad2InnerCameraView release];
    iPad2InnerCameraView = nil;
    [lblBlueToothState release];
    lblBlueToothState = nil;
    [lblMessage release];
    lblMessage = nil;
    [progreBar release];
    progreBar = nil;
    [ReConnectBluetooth release];
    ReConnectBluetooth = nil;
    [lblHandVibProc release];
    lblHandVibProc = nil;
    [vwBottomPanel release];
    vwBottomPanel = nil;
    [btnPrevView release];
    btnPrevView = nil;
    [lblUserNameTitle release];
    lblUserNameTitle = nil;
    [lblUserName release];
    lblUserName = nil;
    [lblUserNameDim release];
    lblUserNameDim = nil;
    [lblWorkDateTitle release];
    lblWorkDateTitle = nil;
    [lblWorkDate release];
    lblWorkDate = nil;
    [lblCount release];
    lblCount = nil;
    
    if (cmm.accelerometerActive) {
        [cmm stopAccelerometerUpdates];
    }
    
    [super viewDidDisappear:animated];
}

- (void)viewDidUnload {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif

    [CamControll release];
    CamControll = nil;
    [CamSelect release];
    CamSelect = nil;
    [redDot release];
    redDot = nil;

    [CamZoomView release];
    CamZoomView = nil;
    [CamZoomSlider release];
    CamZoomSlider = nil;
    [btnZoomWide release];
    btnZoomWide = nil;
    [btnZoomTele release];
    btnZoomTele = nil;

    [CamExposureView release];
    CamExposureView = nil;
    [CamExposureSlider release];
    CamExposureSlider = nil;
    [btnDark release];
    btnDark = nil;
    [btnBright release];
    btnBright = nil;
    [btnCamRotate release];
    btnCamRotate = nil;
    
    if (cmm.accelerometerActive) {
        [cmm stopAccelerometerUpdates];
    }
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	// [airMicroButton release];
	
	if (airmicro != nil)
	{ 
		[airmicro release]; 
		airmicro = nil;
	}
    if (imagePopController) {
        [imagePopController release];
    }
    if (sentHomePageAlert) {
        [sentHomePageAlert release];
    }
    if (saveCheckAlert){
        [saveCheckAlert release];
    }
//    [_webCameraDaemon release];
    
    [img4CameraView release];
    [CursorBaseView release];
    _cameraViewPicker.delegate = nil;
    [_cameraViewPicker release];
    [CameraButtons removeAllObjects];
    [CameraSelFunc removeAllObjects];
    picker.delegate = nil;
    [picker release];
    if (_gkSession) {
        _gkSession.delegate = nil;
        [_gkSession release];
    }

    [CamControll release];
    [CamSelect release];
    [redDot release];

    [CamZoomView release];
    [CamZoomSlider release];
    [btnZoomWide release];
    [btnZoomTele release];

    [CamExposureView release];
    [CamExposureSlider release];
    [btnDark release];
    [btnBright release];
    [btnCamRotate release];
    
    if (cmm.accelerometerActive) {
        [cmm stopAccelerometerUpdates];
    }
    
    [btn3RCamera release];
    [btn3RCameraSetting release];
    [camera3RView release];
    [camera3RSlider release];
    [gridLineView release];
    [super dealloc];
}

#ifdef BLUETOOTH_WIFI_NOT_ENABLE
// bluetooth状況表示
- (void) bluetoothStateDisp:(bool) isDisplay
{
	CGFloat start, end;
	if (isDisplay)
	{
		start = 0.0f;
		end = 0.74f;
	}
	else 
	{
		start = 0.74f;
		end = 0.0f;
	}
	
	[lblBlueToothState setAlpha: start];

	// アニメーションの開始
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:2.5];
	
	[lblBlueToothState setAlpha: end];
	
	// アニメーションの完了と実行
	[UIView commitAnimations];
}
#else
// bluetooth状況表示
- (void) bluetoothStateDisp:(bool) isDisplay message:(NSString*)msg
{
#ifdef DEBUG
    NSLog(@"%s [%d/%d]{%@}", __func__, isDisplay, isBlueToothStateAnimating, msg);
#endif
    if (isBlueToothStateAnimating) {
        return;     // ラベル表示アニメーション中であれば、何もしない
    }
    isBlueToothStateAnimating = YES;    // webカメラ接続ステータス表示の二重起動防止フラグ

    CGFloat start, end;
	if (isDisplay)
	{
		start = 0.0f;
		end = 0.74f;
	}
	else 
	{
		start = 0.74f;
		end = 0.0f;
	}
    
    CGFloat delay = (isDisplay)? 2.5f : 5.0f;
	
    lblBlueToothState.text = @"";
	[lblBlueToothState setAlpha: start];
    
	// アニメーションの開始
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:delay];

    lblBlueToothState.text = msg;
    
	[lblBlueToothState setAlpha: end];
	
	// アニメーションの完了と実行
	[UIView commitAnimations];
}
#endif

/**
 * Webカメラ接続ステータス表示の二重起動防止用フラグ制御
 */
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    isBlueToothStateAnimating = NO;
}
    
#pragma mark-
#pragma mark public_methids

// ファイル保存進行状況表示
- (void) fileSaveStateDisp:(bool) isDisplay
{
	CGFloat start, end;
	if (isDisplay)
	{
		start = 0.0f;
		end = 1.0f;
	}
	else 
	{
		start = 1.0f;
		end = 0.0f;
	}
	
	[lblMessage setAlpha: start];
	[progreBar setAlpha: start];
	
	// アニメーションの開始
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:2.5];
	
	[lblMessage setAlpha: end];
	[progreBar setAlpha: end];
	
	// アニメーションの完了と実行
	[UIView commitAnimations];
}

// iPad Touchへのコマンド送信
- (void) sendIpodTouchCommand:(IPOD_SEND_COMMAND)command sendData:(NSArray*)sData
{
	if (self._peerId == nil)
	{ return; }		// 接続が切れている
	
	NSError* error = nil;
	NSArray* peers = [NSArray arrayWithObject:self._peerId];

	NSString* cmd = [NSString stringWithFormat:@"%ld", (long)command];
#ifdef IPAD_SEND_DATA_NSSTRING
	NSData* data = [cmd dataUsingEncoding:NSUTF8StringEncoding];
#else
    NSMutableArray *arData = [NSMutableArray array];
    [arData addObject:cmd];
    if (sData)
    {
        // 送信するデータの追加
        for (id obj in sData)
        {
            [arData addObject:obj];
        }
    }
    // NSDataに変換
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:arData];
#endif
	// iPodTouchへ送信
	[_gkSession sendData:data toPeers:peers 
			withDataMode: GKSendDataUnreliable error:&error];
	
	if (error)
	{ NSLog(@" sendIpodTouchCommand error -> %@", [error localizedDescription]);}
    
    btnCamShutter.enabled = YES;
}

// cameraViewのActive
// viewDidAppearまたはForegroundActiveに遷移
- (void) didBecomeActive
{
    isBackGround = NO;
	// if ( ((segCtrlSwicthCamera.tag & 0x01) != 0) && (selected == 0))
	if(btnAirMicro.tag == CM_VC_CAMERA_SELECTED)
	{
		// 画面遷移前にairMicroカメラが表示されていたので、airMicroカメラの初期化
		[self initAirMicro:CGRectMake(64, 240, 640, 480)];
		
		// airMicroにデバイス状態を通知
		[self notify4AitMicroDeviceState];
	}
	/*else if ( (((segCtrlSwicthCamera.tag & 0x01) == 0) && (selected == 0)) ||
	 ((segCtrlSwicthCamera.tag == 0x03) && (selected == 1)))*/
	else if (btniPadCamera.tag == CM_VC_CAMERA_SELECTED)
	{
		// 画面遷移前にiPadTouchカメラが表示されていたので、bluetooth選択画面を表示
		if (self._peerId == nil)
		{
#ifdef BLUETOOTH_WIFI_NOT_ENABLE
			if (picker == nil)
			{  [self pickerInit]; }
			
			// ピッカーの表示
			[picker show]; 
#else
            // 一旦、プレビュー画面をクリア
            iPadTouchView.image = nil;
            
            if (! _gkSession) 
            {
            // 接続を開始
                // bluetooth状況を表示
                [self bluetoothStateDisp : YES message:@"外部カメラからの接続を待っています....."];
                
                // GkSessionの接続初期化(WiFiモード)
                [self _gkSessionInitWifiConnect];
            }
#endif
		}
		else 
		{
			// iPodTouchへbusy状態を解除する
			[self sendIpodTouchCommand:IPOD_SEND_COMMAND_BUSY_RESET sendData:nil];
		}
		
    } else if (btn3RCamera.tag == CM_VC_CAMERA_SELECTED) {
        [self init3RCamera];
    }
	else if (btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED)
	{
		// 画面遷移前にiPad2内蔵カメラが選択されていた
		
		// 初期状態はRearカメラ
		_isRearCameraUse = YES;
		
		//セッションを開始する
		[_cameraViewPicker startSessionWithPrevView:iPad2InnerCameraView 
									isRearCameraUse:_isRearCameraUse];
		
		// デバイス状態を通知
		[self notify4iPad2CameraViewPicker];
    }
    else if (btnWebCamera.tag == CM_VC_CAMERA_SELECTED)
	{
		// 画面遷移前にWebカメラが選択されていた
        
        // Webカメラのプレビュー開始
        [ _webCameraDaemon startPreviewWithReachNotify:^(BOOL isError, NSString* msg)
         {
            if (isError)
            {
                // 画面に戻ってきたときに接続できなかったので、Webカメラを非活性にする
                [self dissmiss4WebCamera];
            }
         }];
    }else if(btnVideo.isSelected || btnVideoAuto.isSelected){
        //セッションを開始する
		[_cameraViewPicker startVideoSessionWithPrevView:iPad2InnerCameraView
                                         isRearCameraUse:_isRearCameraUse
                                                  isAuto:btnVideoAuto.isSelected];
        CamSelectDot.userInteractionEnabled = YES;
		
		// デバイス状態を通知
		[self notify4iPad2CameraViewPicker];
    }
    else if(_SonyCameraDaemon.tag == CM_VC_CAMERA_SELECTED)
    {
        [self OnSonyCameraSelect];
    }
}

// cameraViewのInActive
// viewWillDisappearまたはForegroundInActiveに遷移
- (void) willResignActive
{
    isBackGround = YES;
	// airMicroカメラを閉じる
	[self destroyAirMicro];
    [self dismiss3RCamera];
	
    if (_SonyCameraDaemon.tag == CM_VC_CAMERA_SELECTED) {
        if (rapidFireLock)
        {   // 写真転送中
            [_SonyCameraDaemon stopLiveView];
        }
        else
        {   // その他：LiveView中
            [_SonyCameraDaemon viewDidDisappear:NO];
        }
    }

    // サーバ(iPod touch)より切断する
	// [_gkSession disconnectFromAllPeers];
	
	// iPodTouchへbusy状態を設定する
	[self sendIpodTouchCommand:IPOD_SEND_COMMAND_BUSY_SET sendData:nil];
	
	// iPad2内蔵カメラが選択されている場合は一旦、セッションを終了する
	if (btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED || btnVideo.isSelected || btnVideoAuto.isSelected)
	{	[ _cameraViewPicker endSession]; }
    
    // 写真アルバム取り込みを非選択にする
//    [self _photeLibraryNonSelect];
    
    // Webカメラが選択されている場合は一旦プレビュー停止
    if (btniPad2InnerCamera.tag == CM_VC_CAMERA_SELECTED)
    {   [_webCameraDaemon stopPreview]; }
}

// 重ね合わせ画像の設定:camera画面を閉じるたびに自動でリセットされる
- (void) setOverlayImage:(UIImage*)img
{
	[img4CameraView setBackgroundImage:img];
	// img4CameraView.hidden = NO;
	
	// 重ね合わせ画像も一緒に保存するかフラグをここでリセット
	// _isWithOverlaySave  = NO;
}

// Webカメラの有効化
- (void) setWebCameraEnableWithIsFlag:(BOOL)isEnable
{
//#ifndef AIKI_CUSTOM         // BMKバージョンは無効になることはない（常に有効）
    if (! _webCameraDaemon)
    {   return; }       // 未初期化
    
    if (_webCameraDaemon.isWebCameraEnable == isEnable)
    {   return; }       //変更の必要なし
    
    // deamon側の設定を行う
    [_webCameraDaemon setWebCameraEnableWithFlag:isEnable];
    
    // 有効の場合のみ選択ボタンを表示する
    btnWebCamera.hidden = YES;
//#endif
}

#pragma mark GKSessionDelegate

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
	NSError* error = nil;
	NSLog(@"session:didReceiveConnectionRequestFromPeer: from=\"%@\"",peerID);
	self._peerId = peerID;
	[session acceptConnectionFromPeer:peerID error:&error];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state { 
	NSLog(@"session:peer:\"%@\" didChangeState:%d",peerID,state );
	
	switch (state) 
    {
        case GKPeerStateAvailable :
        // 接続が可能になる : WiFi
        ///////////////////////////////
            
            NSLog(@"pattoru WiFi connecting to %@ ...", [_gkSession displayNameForPeer:peerID]);
            
            // 接続を行う
            [_gkSession connectToPeer:peerID withTimeout:30];
            
            break;
        
        case GKPeerStateConnected :
	
		// 接続が確立した場合 : bluetooth & WiFi
		///////////////////////////////
		
            // perrIDをここで保存する
            self._peerId = 	peerID;
            
            // GKPeerPickerのダイアログを消去
            [self dissmissPeerPicker];
#ifdef BLUETOOTH_WIFI_NOT_ENABLE
            // bluetooth状況を表示する
            [self bluetoothStateDisp : YES];
#else
            // bluetooth状況を表示
            [self bluetoothStateDisp : NO message:@"外部カメラに接続しました"];
#endif
            // iPadカメラボタンのTagをここで変更
            btniPadCamera.tag = CM_VC_CAMERA_SELECTED;
            // シャッターとフリーズボタンの有効／無効設定
            [self setShutterFreezeButton];
            
            // ここでフォーカス中フラグをクリア
            _isFocus4iPodCamera = NO;
            
            break;
		
        case GKPeerStateDisconnected :
		// 接続が切断した場合: bluetooth
		///////////////////////////////
        case GKPeerStateUnavailable:
        // 接続が切断した場合: WiFi
        ///////////////////////////////
            [_gkSession release];
            _gkSession = nil;
            
            // peerIDをここでリセット
            self._peerId = nil;
#ifdef BLUETOOTH_WIFI_NOT_ENABLE
            // bluetooth状況を非表示に
            [self bluetoothStateDisp : NO];
#else
            // bluetooth状況を表示
            [self bluetoothStateDisp : NO message:@"外部カメラの接続が切断しました"];
#endif
            // ファイル保存進行状況が表示されていれば非表示にする
            if (lblMessage.alpha > 0)
            { [self fileSaveStateDisp : NO]; }
            
            // 選択なしにする
            // segCtrlSwicthCamera.selectedSegmentIndex = -1;
            btniPadCamera.tag = CM_VC_CAMERA_NOT_SELECTED; 
            [btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_off.png" ]
                           forState:UIControlStateNormal];
            // シャッターとフリーズボタンの有効／無効設定
            [self setShutterFreezeButton];
            
            // GKPeerPickerのダイアログを消去
            [self dissmissPeerPicker];
            
            // プレビューを消去
            iPadTouchView.image = nil;
            
            NSLog(@"state = GKPeerStateDisconnected");
            // [peers removeObjectForKey:peerID];
            
            break;
            
        default:
            NSLog(@"GkSession didChangeState unkwon state:%d", state);
            break;
	}
	
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
	NSLog(@"session:didFailWithError:%@",error );
	
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
	NSLog(@"session:(GKSession *)session connectionWithPeerFailed: peerId = %@, error = %@",peerID,error);
    
    [Common showDialogWithTitle:@"外部カメラへの接続" 
                        message:[NSString stringWithFormat: @"接続に失敗しました\n(%@)", [error localizedDescription]]];
    
    [_gkSession release];
    _gkSession = nil;
    
    // peerIDをここでリセット
    self._peerId = nil;
#ifdef BLUETOOTH_WIFI_NOT_ENABLE
    // bluetooth状況を非表示に
    [self bluetoothStateDisp : NO];
#else
    // bluetooth状況を表示
    [self bluetoothStateDisp : NO message:@"外部カメラの接続が切断しました"];
#endif
    // ファイル保存進行状況が表示されていれば非表示にする
    if (lblMessage.alpha > 0)
    { [self fileSaveStateDisp : NO]; }
    
    // 選択なしにする
    // segCtrlSwicthCamera.selectedSegmentIndex = -1;
    btniPadCamera.tag = CM_VC_CAMERA_NOT_SELECTED; 
    [btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_off.png" ]
                   forState:UIControlStateNormal];
    // シャッターとフリーズボタンの有効／無効設定
    [self setShutterFreezeButton];
    
}

// 接続先からのデータ受信
- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context {
	
	/*
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"yyMMdd_HHmmss"];
	
	[self._lblMessage setText: 
	 [NSString stringWithFormat:@" recv data from %@ datasize=%d at %@", 
	  peer, [data length], [formatter stringFromDate:[NSDate date]]]];
	*/
	
	@try 
	{
		NSArray *arData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
		if ( [arData count] < 2)
		{
			NSLog(@" recv data from %@ datasize=%ld array index error!",
				  peer, (long)[data length]);
			return;
		}
		
		/////////////////////////////////////////////
		//	コマンド一覧 : Arrayの[0]に格納されていること
		//		0x01	: リアルタイム表示
		//				  [1]:データ本体
		//		--------------------------------------
		//		
		//		0x8000	: ファイル保存
		//				  [1] : 全個数 16個（固定）
		//				  [2] : このパケットの番号(1始まり)
		//				  [3] : データ部分のパケットサイズ
		//				  [4] : 分割データ
		/////////////////////////////////////////////
		
		// コマンドの取り出し
		NSString* cmd = (NSString*)[arData objectAtIndex:0];
		NSUInteger cmdVal = (NSUInteger)[cmd intValue];
		
		NSInteger allPackNums;
		NSInteger packNum;
		
		UIImage* img; 
		switch (cmdVal) {
			case 0x01:
				// リアルタイム画像表示
#ifdef BLUETOOTH_WIFI_NOT_ENABLE
				img = [[UIImage alloc] 
					   initWithData:(NSData*)[arData objectAtIndex:1]];
#else
                // iPodTouchへプレビューのリトライ回数を解除する
                [self sendIpodTouchCommand:IPOD_SEND_COMMAND_PREV_RETRY_RESET sendData:nil];
                
                // 外部カメラプレビューの画像Fitを行う
                img = [self _fitToiPadTouchVwWithImage: 
                            [UIImage imageWithData:(NSData*)[arData objectAtIndex:1]] ];
                
#endif
                iPadTouchView.image = img;
				break;
			case 0x8000:
				// ファイル保存
				allPackNums
					= [(NSString*)[arData objectAtIndex:1] intValue];
				packNum
					= [(NSString*)[arData objectAtIndex:2] intValue];
				
				if (packNum == 1)
				{
					// 分割パケットの最初パケットなのでバッファを初期化する
					_buffer4DivedPacks 
						= [ [NSMutableData alloc] initWithLength:0];
					
					// ファイル保存進行状況表示
					[self fileSaveStateDisp : YES];
					
					// iPodTouchへbusy状態を設定する
					[self sendIpodTouchCommand:IPOD_SEND_COMMAND_BUSY_SET sendData:nil];

				}
				
				// バッファに分割データを追加
				[_buffer4DivedPacks appendData:
				 (NSData*)[arData objectAtIndex:4] ];
				
				// ファイル保存進行状況設定
				progreBar.progress = (CGFloat)(packNum) / (CGFloat)(allPackNums);
				
				if (packNum >= allPackNums)
				{
					// 最終パケットなので、ファイルを保存する
					img = [[UIImage alloc] initWithData:_buffer4DivedPacks];
					// UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
					[self saveImageFile:img];
					
					// 分割パケットのバッファを初期化する
					if (_buffer4DivedPacks)
					{	
						[_buffer4DivedPacks release]; 
						_buffer4DivedPacks = nil;
					}
					
					// ファイル保存進行状況を非表示に
					[self fileSaveStateDisp : NO];
					
					// iPodTouchへbusy状態を解除する
					[self sendIpodTouchCommand:IPOD_SEND_COMMAND_BUSY_RESET sendData:nil];

				}
				break;
			default:
				break;
		}
	}
	@catch (NSException* exception) {
		NSLog(@"receiveData: Caught %@: %@", 
		  [exception name], [exception reason]);
	}
	
}

#pragma mark GKPeerPickerControllerDelegate
- (void)peerPickerController:(GKPeerPickerController *)aPicker
     didSelectConnectionType:(GKPeerPickerConnectionType)type
{
    if (type == GKPeerPickerConnectionTypeOnline) {
        
        if (_gkSession == nil){
            _gkSession = [[[GKSession alloc] initWithSessionID:_sessionName
                                                     displayName:nil
                                                     sessionMode:GKSessionModePeer] autorelease];
            _gkSession.delegate = self;
            _gkSession.available = YES;
            [_gkSession setDataReceiveHandler:self withContext:nil];
            [_gkSession retain];
        }
        
        
        // GKPeerPickerのダイアログを消去
        [self dissmissPeerPicker];
    }
}
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
	NSLog(@"peerPickerControllerDidCancel");
	
	// 選択なしにする
	// segCtrlSwicthCamera.selectedSegmentIndex = -1;
	btniPadCamera.tag = CM_VC_CAMERA_NOT_SELECTED; 
	[btniPadCamera setImage:[UIImage imageNamed:@"iPodCamera_off.png"] 
				   forState:UIControlStateNormal];
	// シャッターとフリーズボタンの有効／無効設定
	[self setShutterFreezeButton];
	
	// GKPeerPickerのダイアログを消去
	[self dissmissPeerPicker];
	
	//[self._lblMessage setText: @"接続がiPad touchで拒否されました"];
}

// これからはじめる通信セッションの識別情報
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type { 
	// GameKitは文字列(OkdIPad4Camera)と同じ文字列で作成された通信セッションで待ち受けているサーバ(iPod)を探す
	GKSession *session = [[GKSession alloc] 
						  initWithSessionID:_sessionName displayName:nil 
						  sessionMode: GKSessionModePeer]; 
	return [session autorelease]; // peer picker retains a reference, so autorelease ours so we don't leak.
}

// サーバとの接続が確立した時にコールされるメソッド
- (void)peerPickerController:(GKPeerPickerController *)_picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session { 
	self._peerId = peerID;  // copy
	
	// Make sure we have a reference to the game session and it is set up
	if (_gkSession == nil)
	{ 
		_gkSession = session;  // retain 
		_gkSession.delegate = self; 
		[_gkSession setDataReceiveHandler:self withContext:NULL];
		[_gkSession retain];
	}
	
#ifdef BLUETOOTH_WIFI_NOT_ENABLE
	// GKPeerPickerのダイアログを消去
	[self dissmissPeerPicker];
	
	// bluetooth状況を表示する
	[self bluetoothStateDisp : YES];
	
	// iPadカメラボタンのTagをここで変更
	btniPadCamera.tag = CM_VC_CAMERA_SELECTED;
	// シャッターとフリーズボタンの有効／無効設定
	[self setShutterFreezeButton];
#endif
}

#pragma mark UICameraViewPickerDelegate

// 撮影後の画像通知
- (void) onCompletePictureWithImage:(UIImage*)pictureImage error:(NSError*)error
{
    // 写真撮影の連射を抑制する
    // (１秒以内に撮影されると、同じファイル名の写真を複数作成してしまうことになるため)
    double delayInSeconds = 1.2f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        rapidFireLock = NO;
        CamSelectDot.userInteractionEnabled = YES;
    });
    
    btnCamShutter.enabled = YES;
	
    if (error)
	{
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"画像保存エラー"
								  message:@"内蔵カメラの画像保存に失敗しました\n(誠に恐れ入りますが\n再度操作をお願いいたします)"
								  delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil
								  ];
		[alertView show];
		[alertView release];
		[SVProgressHUD dismiss];
		return;
	}
	
	// 手ぶれ補正中ラベルを消す
	if (_camViewIsHandVib)
	{
		// アニメーションの開始
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3f];
		
		lblHandVibProc.alpha = 0.0f;
		
		// アニメーションの完了と実行
		[UIView commitAnimations];
	}
	// 画像をファイル保存する
	[self saveImageFile:pictureImage];
}
- (void)onCompleteVideoWithURL:(NSURL *)videoURL error:(NSError *)error {
    
    // 自動停止で録画終了した場合に、カメラ種別選択が出来るようにする
    rapidFireLock = NO;
    CamSelectDot.userInteractionEnabled = YES;
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully)
    {
        // プレビューを止める => 止めない
        //BOOL tempBtnVideoIsSelected = btnVideo.isSelected;
        //BOOL tempBtnVideoAutoIsSelected = btnVideoAuto.isSelected;
		//[self dissmiss4iPad2Camera:NO];
        //[btnVideo setSelected:tempBtnVideoIsSelected];
        //[btnVideoAuto setSelected:tempBtnVideoAutoIsSelected];
        VideoSaveViewController *saveView = [[VideoSaveViewController alloc]
                                             initWithNibName:@"VideoSaveViewController" bundle:nil];
        saveView.saveDelegate = self;
        // 赤の枠線も保存
//        saveView.overlayImage = [img4CameraView getOverlayImageWithbackgroud:NO
//                                                               isWithGuideLine:_isWithGuideSave];
        
        saveView.overlayImage = [gridLineView getOverlayImageWithbackgroud:NO
                                                             isWithGuideLine:_isWithGuideSave];
        
        [saveView show];
        MovieResource *movieResource = [[MovieResource alloc] initNewMovieWithUserId:_selectedUserID];
        [saveView setVideoUrl:videoURL movie:movieResource histId:self.histID];
        
        [movieResource release];
        //----- RECORDED SUCESSFULLY -----
#ifdef DEBUG
        NSLog(@"didFinishRecordingToOutputFileAtURL - success");
#endif
    }
    [self setVideoIsRecording:NO];
}
#pragma mark PopUpViewContollerBaseDelegate
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
	iPad2CameraSettingPopup *popUp;
	switch (popUpID)
	{
		case POPUP_IPAD2_CAM_SET:
		// iPad2内蔵カメラの設定用popup
			 popUp = (iPad2CameraSettingPopup*)object;
			
			// 設定された値をメンバに設定
			_camViewIsHandVib = popUp.isHandVib;
			_camViewDelayTime = popUp.delayTime;
			_camViewCaptureSpeed = popUp.captureSpeed;
			
			// 設定ファイルに保存
			NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
			[defaluts setBool:_camViewIsHandVib forKey:@"ipad2_camera_hand_vib"];
			[defaluts setInteger:_camViewDelayTime forKey:@"ipad2_camera_delay_time"];
			[defaluts setInteger:_camViewCaptureSpeed forKey:@"ipad2_camera_capture_speed"];
			
			// 内蔵カメラ用CameraViewPickerに設定
			_cameraViewPicker.isHandVibEnable	= _camViewIsHandVib;
			_cameraViewPicker.delayTime			= _camViewDelayTime;
			_cameraViewPicker.captureSpeed		= _camViewCaptureSpeed;
			
			break;
		default:
			break;
	}
}
// 重ね合わせ画像設定ポップアップViewControllerのDelegate
#pragma mark OverlayViewSettingPopupDelegate
    
// 透過率の設定
- (void)OverlayView:(OverlayViewSettingPopup*)sender OnAlphaChange:(CGFloat)alpha
{
	if (! img4CameraView.hidden)
	{
		// 重ね合わせ透過画像に透過率の設定
        NSLog(@"in alpha = %f",alpha);
		img4CameraView.alpha = alpha;
//        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
//        [df setFloat:alpha  forKey:@"CAM_OVERLAY_ALPHA"];
//        [df synchronize];
	}
}

- (void)OverlayView:(OverlayViewSettingPopup*)sender OnGuideLineAlphaChange:(CGFloat)alpha
{
    if (! gridLineView.hidden)
    {
        // 重ね合わせ透過画像に透過率の設定
        NSLog(@"in alpha = %f",alpha);
        gridLineView.alpha = alpha;
    }
}

// ガイド線本数の設定
- (void)OverlayView:(OverlayViewSettingPopup*)sender OnGuideLineNumsChange:(NSInteger)nums
{
//    if (! img4CameraView.hidden)
//    {
//        // 重ね合わせ透過画像にガイド線本数の設定
//        [img4CameraView setGuideLineNums:nums];
//        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
//        [df setFloat:nums   forKey:@"CAM_GUIDE_NUM"];
//        [df synchronize];
//    }
    
    if (! gridLineView.hidden)
    {
        // 重ね合わせ透過画像にガイド線本数の設定
        [gridLineView setGuideLineNums:nums];
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        [df setFloat:nums   forKey:@"CAM_GUIDE_NUM"];
        [df synchronize];
    }

}

// 本Popupを閉じる時
- (void)OverlayViewOnClose:(OverlayViewSettingPopup*)sender
{
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    [df setFloat:sender.maxRecTime          forKey:@"video_max_rectime"]; // 初期値は10秒
    [df setFloat:sender.maxDuration         forKey:@"video_max_duration"]; // 初期値は10秒
    [df setFloat:sender.localCapacity       forKey:@"local_capacity"];    // 最大値は空き容量にて検証済み
//    [df setFloat:sender.guideLineNums       forKey:@"CAM_GUIDE_NUM"];
    [df setFloat:sender.isWithGuideSave     forKey:@"CAM_GUIDE_SAVE"];
    [df setFloat:sender.isWithOverlaySave   forKey:@"CAM_OVERLAY_SAVE"];
//    [df setFloat:sender.viewAlpha           forKey:@"CAM_OVERLAY_ALPHA"];
    [df setInteger:sender.camResolution     forKey:@"CAM_RESOLUTION"];
    [df setInteger:sender.webCamRotate      forKey:@"web_cam_rotate"];
    [df setInteger:sender.webCamResolution  forKey:@"web_cam_resolution"];
    
    [df synchronize];

    // 空き容量チェックは別スレッドで実施する(ファイル数が増えると時間がかかるため)
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [MovieResource removeVideosUntilCapacityLimit];
    });
    
    if (btnVideoAuto.isSelected) {
        // 再起動して、自動停止時間を適用する。
        [self _oniPad2InnerCameraSelect:btnVideoAuto];  // 一旦ボタンを押してdisableにする
        [self _oniPad2InnerCameraSelect:btnVideoAuto];  // 再度ボタンを押してenableにする
    }
	// 重ね合わせ画像／ガイド線も一緒に保存するか？を保存
	_isWithOverlaySave = sender.isWithOverlaySave;
	_isWithGuideSave = sender.isWithGuideSave;
    
    camResolution = sender.camResolution;
    webCamRotate  = sender.webCamRotate;
    webCamResolution = sender.webCamResolution;
    
    // 重ね合わせ画像のFrame設定
    [self setOverlayImageFrame];
    
    _SonyCameraDaemon.CamP_Rotate = CamRotate[webCamRotate];
    NSArray *resolutionArray = [NSArray arrayWithObjects:
                                @"2M", @"5M", @"18M", nil];

    [_SonyCameraDaemon setStillSize:[resolutionArray objectAtIndex:webCamResolution]];
    
#ifdef CALULU_IPHONE
    // ModalPopupの表示を解除
    _isShowModalPopup = NO;
#endif
}

- (void)onDeleteNewCarte {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"CarteFromNew"]) {
        userDbManager *usrDbMng = [[userDbManager alloc] init];
        NSLog(@"print histid = %d",self.histID);
        [usrDbMng deleteHistWithHistID:self.histID];
        
        [defaults setBool:false forKey:@"CarteFromNew"];
    }
    [defaults synchronize];
}

- (void)finishVideoSave:(BOOL)isSaved {
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isSaved forKey:@"onDeleteNewCarte"];
    [defaults synchronize];
    
    // 動画アップロードスレッドの動作確認と（動作していない場合）開始を行う
    @try {
        VideoUploader *videoUploader
            = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).videoUploader;
        if (! [videoUploader uploadThreadCheckAndStart] ) {
            NSLog(@"video upload thread ended... so , now restart thread!!");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%s: Caught %@: %@",
              __func__, [exception name], [exception reason]);
    }
    /*
    if (btnVideo.isSelected) {
        [btnVideo setSelected:NO]; //非活性化しないように一時的に
        [self OniPad2InnerCameraSelect:btnVideo];
    } else if(btnVideoAuto.isSelected){
        [btnVideoAuto setSelected:NO]; //非活性化しないように一時的に
        [self OniPad2InnerCameraSelect:btnVideoAuto];
    }
     */
}
- (void)lblCountHidden:(BOOL)isHidden {
    lblCount.hidden = isHidden;
}
- (void)lblCount:(CGFloat)num {
    CGFloat sec = (num / 10.0f);
    lblCount.text = [NSString stringWithFormat:@"録画時間：%.1f0 [秒]",sec];
}

// ビデオ撮影ボタンのON/OFF
- (void)checkVideoAccount{
    // 動画契約がある場合のみ、撮影可能にする
    if([AccountManager isMovie]==YES){
        btnVideo.enabled = NO;
        btnVideoAuto.enabled = NO;
    } else {
        btnVideo.enabled = NO;
        btnVideoAuto.enabled = NO;
    }
}

@end
