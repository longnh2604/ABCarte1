//
//  UICameraViewPicker.m
//  iPadCamera
//
//  Created by MacBook on 11/04/24.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UICameraViewPicker.h"

#import "SVProgressHUD.h"

/// 内蔵カメラ用CameraViewPickerクラス
///
@implementation UICameraViewPicker

@synthesize imageBuffer;
@synthesize captureSession;
@synthesize stillImageOutput;
@synthesize delegate;

@synthesize isHandVibEnable = _isHandVibEnable;
@synthesize delayTime = _delayTime;
@synthesize captureSpeed = _captureSpeed;

//2012 6/18 位等 タッチフォーカス修正処理用
@synthesize adjustingFocus;
@synthesize adjustingExposure;
@synthesize focusCursor;
@synthesize timeOutTimer;
@synthesize countTimer;
// takePictureメソッドのハンドラのローカル保存
// void (*_handler)(UIImage *pictureImage, NSError *error);
// SEL _handler;

#pragma mark private_methods

// 画像を回転させる
- (UIImage*) rotateImage:(UIImage*)oriImage
{
	CGSize cntxtSize;
	CGPoint transPoint;	
	CGFloat rtRadian;
	
	// メンバに保存されたImage方向にて回転を決める
	switch (imageOrientation) {
		case UIImageOrientationRight:
			// Portrait(上向き):C.W. -90.0 
			cntxtSize	= CGSizeMake(cam_picture_height, cam_picture_width);
			transPoint	= CGPointZero;
			rtRadian	= -M_PI_2;		// PI/2
			break;
		case UIImageOrientationLeft:
			// PortraitUpsideDown(下向き):C.C.W. +90.0 
			cntxtSize	= CGSizeMake(cam_picture_height, cam_picture_width);
			transPoint	= CGPointMake(cam_picture_height, cam_picture_width);
			rtRadian	= M_PI_2;		// PI/2
			break;
		case UIImageOrientationUp:
			// LandscapeLeft(左向き):C.W. 0.0 回転なし
			cntxtSize	= CGSizeMake(cam_picture_width, cam_picture_height);
            transPoint  = CGPointZero;
            rtRadian    = 0;
			break;
		case UIImageOrientationDown:
			// LandscapeLeft(右向き):C.W. 180.0
			cntxtSize	= CGSizeMake(cam_picture_width, cam_picture_height);
			transPoint	= CGPointMake(cam_picture_width, 0.0f);
			rtRadian	= -M_PI;	
			break;
		default:
			// 回転なし
			cntxtSize	= CGSizeZero;
            rtRadian    = 0;
			break;
	}
	
	// 回転なしの場合はそのまま返す
	if (CGSizeEqualToSize(cntxtSize, CGSizeZero))
	{
        return (oriImage);
    }
    else if (rtRadian == 0)
    {   // 回転なし・サイズ変更あり
        // グラフィックコンテキストを作成
        UIGraphicsBeginImageContext(cntxtSize);
        
        // グラフィックコンテキストに描画
        [oriImage drawInRect:CGRectMake(0, 0, cntxtSize.width, cntxtSize.height)];
        // グラフィックコンテキストから縮小版のImageを取得
        UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
        // グラフィックコンテキストを解放
        UIGraphicsEndImageContext();

        return reSizeImage;
    }
	
	// グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(cntxtSize);
	// contextを取得
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// 回転処理
	if (! CGPointEqualToPoint(transPoint, CGPointZero))
		CGContextTranslateCTM(context, transPoint.x, transPoint.y);
	CGContextScaleCTM(context, 1.0f, -1.0f);
	CGContextRotateCTM(context, rtRadian);
		
	// ImageRefの取得
	CGImageRef imgRef = oriImage.CGImage;
	
	// CGContextへの描画
	CGContextDrawImage(context, 
					   CGRectMake(0.0f, 0.0f, cam_picture_width, cam_picture_height),
					   imgRef);
	// 回転後のImageを取得
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
	
	return (image);
}

// 横長Imageに変換する（portrait系のみ）
- (UIImage*) convWideSizeImage:(UIImage*)oriImage
{

	if ( (imageOrientation == UIImageOrientationDown) ||
		 (imageOrientation == UIImageOrientationUp) )
	{	return (oriImage); }		// Landscape系はそのまま返す
		
	// グラフィックコンテキストを作成:横長で作成
	UIGraphicsBeginImageContext
		(CGSizeMake(cam_picture_width, cam_picture_height));
	
	// 描画サイズ
	CGFloat cWidth
		= (cam_picture_height / cam_picture_width) * cam_picture_height;
	CGFloat cHeight = cam_picture_height;	// 縦高さを横幅に縮小
	CGFloat cLeft = (cam_picture_width - cWidth) / 2.0f;
	CGRect imgRect 
		= CGRectMake(cLeft, 0.0f, cWidth, cHeight);
	
	// グラフィックコンテキストに描画
	[oriImage drawInRect:imgRect];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
		
	return (image);
}

//保存用にサイズを縮小する（Landscape系のみ）
- (UIImage*) convSizedownImage:(UIImage*)oriImage
{
    if ( (imageOrientation == UIImageOrientationLeft) ||
        (imageOrientation == UIImageOrientationRight) )
	{	return (oriImage); }		// portrait系はそのまま返す

    // 縦と横の倍率でいずれか大きいほうで画像の倍率を求める
    CGFloat widthRatio = oriImage.size.width / CAM_VIEW_PICTURE_WIDTH;
    CGFloat heightRatio = oriImage.size.height / CAM_VIEW_PICTURE_HEIGHT;
    CGFloat raito = (widthRatio >= heightRatio)? widthRatio : heightRatio;
    
    // 倍率より縮小後のサイズを求める
    CGFloat width  = oriImage.size.width / raito;
    CGFloat height = oriImage.size.height / raito;
    
    // グラフィックコンテキストを、倍率からの縮小サイズで作成
	UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // グラフィックコンテキストに描画
	[oriImage drawInRect:CGRectMake(0.0f, 0.0f, width, height)];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
	return (image);

}

// 保存用Imageを作成
- (UIImage*) makeImage4SaveWithData:(NSData*)data
{
	// NSData -> UIImageへ変換
	UIImage *oriImage = [UIImage imageWithData:data];
	
	// 画像を回転させる
	UIImage *rotateImage = [self rotateImage:oriImage];
	
    // 横長変換、サイズ変換を行わない
    return rotateImage;
    
	// 横長Imageに変換する（portrait系のみ）
	UIImage *saveImage = [self convWideSizeImage:rotateImage];
#ifdef VER125_LATER
#ifdef CALULU_IPHONE
    //保存用にサイズを縮小する（Landscape系のみ）
    UIImage *convSizedownImage = [self convSizedownImage:saveImage];
    return (convSizedownImage);
#else
    return (saveImage);
#endif
#else
    if (imageOrientation == UIImageOrientationUp)
    {
        // iOS6にてLandscapeLeft(左向き)にて画像サイズが高解像度カメラの場合に写真サイズが５MB以上になるのを回避
        UIImage *convSizedownImage = [self convSizedownImage:saveImage];
        return (convSizedownImage);
    }
    else {
        return (saveImage);
    }
    
#endif  
}

// 写真を撮る
- (void) _takePicture
{
	// 静止画撮影処理
	AVCaptureConnection *connection = [self.stillImageOutput.connections lastObject];
	[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection
													   completionHandler:
	 ^(CMSampleBufferRef imageDataSmpleBuffer, NSError *error)
	 {
		 UIImage *image = nil;
		 
		 if (error)
		 {
             NSLog (@"takePicture error -> %@", error.localizedDescription);
         }
		 else {
			 
			 NSData *data = [AVCaptureStillImageOutput 
							 jpegStillImageNSDataRepresentation:imageDataSmpleBuffer];
             
             // 画像保存解像度の設定
             [self setResolusion];
			 
			 // image = [UIImage imageWithData:data];
			 image = [self makeImage4SaveWithData:data];
#ifdef DEBUG
			 NSLog (@"takePicture success!!");
             
#endif
		 }
		 
		 // クライアントクラスへのコールバック
		 if ( (self.delegate) &&
			 ([self.delegate respondsToSelector:@selector(onCompletePictureWithImage:error:)]))
		 {
			 [self.delegate onCompletePictureWithImage:image error:error];
			 
			 /* 以下は、mainスレッドのため必要なし
			  [self performSelectorOnMainThread:@selector(handler:)
			  withObject:image waitUntilDone:YES];
			  */
		 }
	 }
	 ];	
}

// 2012 6/18 伊藤 タッチ時のフォーカス修正
- (void)setFocus:(CGPoint)point{
    animationStarted = NO;
    if (!videoCaptureDevice) {
        NSLog(@"No Camera");
        return;
    }
    
    NSError *error = nil;
    if ([videoCaptureDevice isFocusPointOfInterestSupported] &&
     [videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
        self.adjustingFocus =YES;
        [videoCaptureDevice lockForConfiguration:&error];
        videoCaptureDevice.focusPointOfInterest = point;
        videoCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
#ifdef DEBUG
        NSLog(@"Set Focus");
#endif
    }
    if( [videoCaptureDevice isExposurePointOfInterestSupported] &&
        [videoCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        self.adjustingExposure =YES;
        [videoCaptureDevice lockForConfiguration:&error];
        videoCaptureDevice.exposurePointOfInterest = point;
        videoCaptureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
#ifdef DEBUG
        NSLog(@"Set Exposure");
#endif
    }
    if (self.adjustingFocus || self.adjustingExposure) {
        if(self.focusCursor && !animationStarted){
            if(self.timeOutTimer){
                if ([self.timeOutTimer isValid]) {
                    [self.timeOutTimer invalidate];
                }
                self.timeOutTimer = nil;
            }
            self.timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                                 target:self
                                                               selector:@selector(timerTimeOut:)
                                                               userInfo:nil
                                                                repeats:YES];
        }
    }
}

/**
 * マニュアル露出補正(iOS8以降)
 */
- (void)setExposure:(float)bias
{
    NSError *error = nil;

    if ([videoCaptureDevice lockForConfiguration:&error]) {
        float exposure = videoCaptureDevice.exposureTargetBias;
        [videoCaptureDevice setExposureTargetBias:bias completionHandler:nil];
#ifdef DEBUG
        NSLog(@"curExposure[%.03f] [%.03f : %.03f]", exposure,
              videoCaptureDevice.maxExposureTargetBias,
              videoCaptureDevice.minExposureTargetBias);
#endif
    }
}

/**
 * 画像の保存解像度取得
 */
- (void)setResolusion
{
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSInteger resolution = [df integerForKey:@"CAM_RESOLUTION"];
#ifdef DEBUG
    NSLog(@"CamPicture Resolution [%ld]", (long)resolution);
#endif
    switch (resolution) {
        case 0: // 解像度 Low (960 x 720) 今までと同様
            cam_picture_width  = CAM_VIEW_PICTURE_WIDTH;
            cam_picture_height = CAM_VIEW_PICTURE_HEIGHT;
            break;
        case 1: // 解像度 Middle (1280 x 960)
            cam_picture_width  = 1280;
            cam_picture_height = 960;
            break;
        case 2: // 解像度 High   (2592 x 1936)
            cam_picture_width  = 2592;
            cam_picture_height = 1936;
            break;
        default:
            cam_picture_width  = CAM_VIEW_PICTURE_WIDTH;
            cam_picture_height = CAM_VIEW_PICTURE_HEIGHT;
            break;
    }
}

#pragma mark life_cycle

// 初期化
- (id) initWithHandVibSetting:(BOOL)isHandVibEnable delayTimer:(NSInteger)timer
{
	// 内蔵カメラの使用可／不可を確認
	if (! [UIImagePickerController isSourceTypeAvailable:
			   UIImagePickerControllerSourceTypeCamera])
	{
		self = nil;
		return (self);
	}
	
	if ( (self = [super init]) )
	{
		self.isHandVibEnable = isHandVibEnable;
		self.delayTime = timer;
        count = 0;
        
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        camResolution = [df integerForKey:@"CAM_RESOLUTION"];
        cam_picture_width = CAM_VIEW_PICTURE_WIDTH;
        cam_picture_height = CAM_VIEW_PICTURE_HEIGHT;
    }
	
	return (self);
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	// セッションの終了
	[self endSession];
		
	[super dealloc];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
#ifndef __i386__
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// NSLog (@" raize didOutputSampleBuffer");
	
	CVImageBufferRef imageBuf = CMSampleBufferGetImageBuffer(sampleBuffer);     
	
	/*Lock the image buffer*/    
	CVPixelBufferLockBaseAddress(imageBuf,0);     
	
	/*Get information about the image*/    
	uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuf);     
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuf);     
	size_t width = CVPixelBufferGetWidth(imageBuf);     
	size_t height = CVPixelBufferGetHeight(imageBuf);          
	
	/*Create a CGImageRef from the CVImageBufferRef*/    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();     
	CGContextRef newContext = CGBitmapContextCreate
	(baseAddress, width, height, 8, bytesPerRow, colorSpace, 
	 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);    
	
	CGImageRef newImage = CGBitmapContextCreateImage(newContext);     
	
	/*We release some components*/    
	CGContextRelease(newContext);     
	CGColorSpaceRelease(colorSpace); 
	
	
	UIImage *image
	= [UIImage imageWithCGImage:newImage scale:1.0 orientation:imageOrientation];
	self.imageBuffer = image;
	
	/*We relase the CGImageRef*/	
	CGImageRelease(newImage);	
	// [self.imageView performSelectorOnMainThread:
	// @selector(setImage:) withObject:image waitUntilDone:YES];	
	
	/*We unlock the  image buffer*/	
	CVPixelBufferUnlockBaseAddress(imageBuf,0);	
	
	[pool drain];
}
#endif

#pragma mark CoreMotion_methods
- (void)initAccelerometer
{
#define EVENT_PERIOD	50
    if (mManager) {
        [mManager release];
    }
    mManager = [[CMMotionManager alloc] init];
    [mManager setAccelerometerUpdateInterval:(float)EVENT_PERIOD/1000.0f];
    
    [mManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                   withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                       dispatch_sync(dispatch_get_main_queue(), ^{
                                           [self didAccelerateWithData:accelerometerData];
                                       });
                                   }];
    
    // 最小の加速度の値を最大値でリセット
    _accelMin = MAXFLOAT;
    
    // 加速度センサーイベント 0.05秒間隔タイマーで算出
    // ex) _delayTime=2で _delayTimerCounter=40 -> 40回カウント
    _delayTimerCounter = ((_delayTime * 1000) / EVENT_PERIOD);
    
    _delayLimitCounter = _delayMaxCounter = 0;
}

- (void)didAccelerateWithData:(CMAccelerometerData *)accelerometerData {
    // 加速度センサーの処理
    
    float accelX, accelY, accelZ;
    
    // インスタンス変数に加速度の値を代入
    //	フィルタなし
    
    accelX = accelerometerData.acceleration.x;
    accelY = accelerometerData.acceleration.y;
    accelZ = accelerometerData.acceleration.z;
    
    // ハイパス・フィルタを掛けて、瞬間的な動きを取り除く
#define kFilteringFactor 0.1
    /*
     float x = acceleration.x;
     float y = acceleration.y;
     float z = acceleration.z;
     
     accelX = x - ((x * kFilteringFactor) + (accelX * (1.0 - kFilteringFactor)));
     accelY = y - ((y * kFilteringFactor) + (accelY * (1.0 - kFilteringFactor)));
     accelZ = z - ((z * kFilteringFactor) + (accelZ * (1.0 - kFilteringFactor)));
     */
    // 加速度センサーの和
    float accelMin
    = (fabs(accelX) + fabs(accelY) + fabs(accelZ*1.0f));
#ifdef DEBUG
    NSLog(@"accel x=%f y=%f z=%f min=%f",
          accelX, accelY, accelZ, accelMin);
#endif
    
#define DELAY_LIMIT_COUNT		5
#define DELAY_MAX_COUNT			10
    
    if (accelMin < _accelMin)
    {
        // サンプリング中の最小の加速度
        
        // 最小値を保存
        _accelMin = accelMin;
        
        if ( ++_delayLimitCounter > DELAY_LIMIT_COUNT)
        {	[self termnaiteAccelerometer]; }
        
        if (_delayMaxCounter > DELAY_MAX_COUNT)
        {
            [self termnaiteAccelerometer];
        }
#ifdef DEBUG
        NSLog(@"accel min %f at count=%ld", _accelMin, (long)_delayTimerCounter);
#endif
    }
    
    _delayMaxCounter++;
    
    // サンプリング期間終了
    if ( (--_delayTimerCounter) <= 0)
    {
        [self termnaiteAccelerometer];
    }
}

- (void) termnaiteAccelerometer
{
    // 加速度センサのイベントを停止
    if (mManager.accelerometerActive) {
        [mManager stopAccelerometerUpdates];
    }
    [mManager release];
    mManager = nil;
    
    // 写真を撮る
    [self _takePicture];
#ifdef DEBUG
    NSLog(@"terminate hand vibration proc.");
#endif
}

#pragma mark public_methods

// セッションの開始
- (BOOL) startSessionWithPrevView:(UIView*)prevView isRearCameraUse:(BOOL)isRear
{
    iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

    if ([self setInput:prevView isRearCameraUse:isRear]) {
        [self setPhotoOutput];
        
        // セッションスタート
        [self.captureSession startRunning];
        //2012 6/18 伊藤 タッチフォーカス使用時、変更完了通知を受け取るオブジェクト設定
        [videoCaptureDevice addObserver:self
                             forKeyPath:@"adjustingExposure"
                                options:NSKeyValueObservingOptionNew
                                context:nil];
        [videoCaptureDevice addObserver:self
                             forKeyPath:@"adjustingFocus"
                                options:NSKeyValueObservingOptionNew
                                context:nil];
        return (YES);
    } else {
        return (NO);
    }
}

- (BOOL) startVideoSessionWithPrevView:(UIView*)prevView isRearCameraUse:(BOOL)isRear isAuto:(BOOL)isAuto
{
    if ([self setInput:prevView isRearCameraUse:isRear]) {
        [self setVideoOutput:isAuto];
        
        // セッションスタート
        [self.captureSession startRunning];
        //2012 6/18 伊藤 タッチフォーカス使用時、変更完了通知を受け取るオブジェクト設定
        [videoCaptureDevice addObserver:self
                             forKeyPath:@"adjustingExposure"
                                options:NSKeyValueObservingOptionNew
                                context:nil];
        [videoCaptureDevice addObserver:self
                             forKeyPath:@"adjustingFocus"
                                options:NSKeyValueObservingOptionNew
                                context:nil];
        return (YES);
    } else {
        return (NO);
    }
}

- (void) cameraSetOutputProperties
{
	//SET THE CONNECTION PROPERTIES (output properties)
	AVCaptureConnection *CaptureConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
	
	//Set landscape (if required)
	if ([CaptureConnection isVideoOrientationSupported])
	{
		AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;		//<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
		[CaptureConnection setVideoOrientation:orientation];
	}
	
    NSError *error = nil;
    if (iOSVersion<7.0f) {
        //Set frame rate (if requried)
        CMTimeShow(CaptureConnection.videoMinFrameDuration);
        CMTimeShow(CaptureConnection.videoMaxFrameDuration);
        
        if (CaptureConnection.supportsVideoMinFrameDuration)
            CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
        if (CaptureConnection.supportsVideoMaxFrameDuration)
            CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
        
        CMTimeShow(CaptureConnection.videoMinFrameDuration);
        CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    } else {
        if ([videoCaptureDevice lockForConfiguration:&error]) {
            videoCaptureDevice.activeVideoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
            videoCaptureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
            CMTimeShow(videoCaptureDevice.activeVideoMinFrameDuration);
            CMTimeShow(videoCaptureDevice.activeVideoMaxFrameDuration);
            [videoCaptureDevice unlockForConfiguration];
        }
    }
}
- (BOOL)setInput:(UIView*)prevView isRearCameraUse:(BOOL)isRear{
    
#ifndef __i386__
	// セッションオープン
	if (! (captureSession = [[AVCaptureSession alloc] init]) )
	{
		NSLog(@"capture session init error");
		return (NO);
	}
	
    // NSLog(@"capture session start");
    
    //videoCaptureDeviceをインスタンス変数化
	videoCaptureDevice = nil;
	NSArray *cameraArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *camera in cameraArray) {
		if (isRear)
		{
			if (camera.position == AVCaptureDevicePositionBack) {
				// 背面カメラを使用
				videoCaptureDevice = camera;
                _useFrontCamera = NO;
			}
		}
		else
		{
			if (camera.position == AVCaptureDevicePositionFront) {
				// 前面カメラを使用
				videoCaptureDevice = camera;
                _useFrontCamera = YES;
			}
		}
        
	}
	
	//Inputデバイスを作成
	NSError *error = nil;
	AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
	if (videoInput)
	{
		[self.captureSession addInput:videoInput];
		
		// config (session)
		[self.captureSession beginConfiguration];
        /*
         #ifdef CALULU_IPHONE
         self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;  // 2592*1936  AVCaptureSessionPresetHigh;  // 1280 * 720
         #else
         self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto; // AVCaptureSessionPreset640x480;	// AVCaptureSessionPresetHigh;
         #endif
         */
		[self.captureSession commitConfiguration];
		// config (input)
		if ([videoCaptureDevice lockForConfiguration:&error]) {
			// AFモード
			if ([videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
				videoCaptureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
			}else {
				if ([videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
					videoCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
				}
			}
			if ([videoCaptureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
				videoCaptureDevice.flashMode = AVCaptureFlashModeAuto;							// フラッシュ
			}
			if ([videoCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
				videoCaptureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;	// 露出
			}
			if ([videoCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
				videoCaptureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;			// ホワイトバランス
			}
			if ([videoCaptureDevice isTorchModeSupported:AVCaptureTorchModeOff]){
				videoCaptureDevice.torchMode = AVCaptureTorchModeOff;							// ビデオライト
			}
            if (iOSVersion>=7.0f) {
                [videoCaptureDevice setActiveVideoMinFrameDuration:CMTimeMake(1,self.captureSpeed)];
            }

			[videoCaptureDevice unlockForConfiguration];
		}else {
			NSLog(@"input config ERROR:%@", error);
		}
		// プレビューレイヤ取得
		previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
		[previewLayer retain];
        if ([previewLayer respondsToSelector:@selector(setAutomaticallyAdjustsVideoMirroring:)]) {
            [[previewLayer connection] setAutomaticallyAdjustsVideoMirroring:YES];
        }
		previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;	// ぴっちり全面
		previewLayer.frame = prevView.bounds;
		[prevView.layer insertSublayer:previewLayer atIndex:0];
	}
	else
	{
		// AVCaptureDeviceInput Handle the failure.
		NSLog(@"AVCaptureDeviceInput init ERROR:%@", error);
		
        if (self.captureSession) {
//            [self.captureSession release];
            self.captureSession = nil;
        }
		
		return (NO);
	}
#endif
    return YES;
}
- (void)setPhotoOutput {
#ifdef CALULU_IPHONE
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;  // 2592*1936  AVCaptureSessionPresetHigh;  // 1280 * 720
#else
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto; // AVCaptureSessionPreset640x480;	// AVCaptureSessionPresetHigh;
#endif
#ifdef IPAD_CAMERA_IOS4
	// ビデオデータ取得の方法 -> Code Snippet SP16
	AVCaptureVideoDataOutput *videoOutput = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
	videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
															forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    videoOutput.minFrameDuration = CMTimeMake(1, self.captureSpeed);	// 20 -> 36fps
	videoOutput.alwaysDiscardsLateVideoFrames = YES;
	queue = dispatch_queue_create("jp.okada-denshi.iPadCamera2", NULL);
	[videoOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
	[self.captureSession addOutput:videoOutput];
#endif
    
	// NSLog(@"delegate = %@", videoOutput.sampleBufferDelegate);
	
	// stillImageOutputの設定
	stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	[self.captureSession addOutput:self.stillImageOutput];
    
#ifdef CALULU_IPHONE
    //    ((AVCaptureConnection*)[videoOutput.connections objectAtIndex:0]).videoMinFrameDuration = CMTimeMake(1, self.captureSpeed);	// 20 -> 36fps
    ((AVCaptureConnection*)[self.stillImageOutput.connections objectAtIndex:0]).videoMinFrameDuration = CMTimeMake(1, self.captureSpeed);	// 20 -> 36fps
    // NSLog (@"end videoMinFrameDuration set");
#else
    AVCaptureConnection* avCon = [self.stillImageOutput.connections objectAtIndex:0];
    if (iOSVersion>=6.0f) {
        [avCon setAutomaticallyAdjustsVideoMirroring:YES];
    }
    if (iOSVersion<7.0f) {
        if ([avCon respondsToSelector:@selector(setVideoMinFrameDuration:)])
        {   [avCon setVideoMinFrameDuration:CMTimeMake(1, self.captureSpeed)];}
    }
    /*else if ([avCon respondsToSelector:@selector(setMinFrameDuration:)])
     {   [avCon setMinFrameDuration:CMTimeMake(1, self.captureSpeed)];}*/
#endif

}
- (void)setVideoOutput:(BOOL)isAuto{
    NSError *error = nil;
    //ADD AUDIO INPUT
	NSLog(@"Adding audio input");
	AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
	if (audioInput)
	{
		[captureSession addInput:audioInput];
	}
    
    //ADD MOVIE FILE OUTPUT
	NSLog(@"Adding movie file output");
	movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
	
	Float64 TotalSeconds = 5 * 60;			//最大でも5分
    if (isAuto) {
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        TotalSeconds = [df floatForKey:@"video_max_duration"];
        // 未設定の場合、0.00になる
        if (TotalSeconds <= 0) {
            TotalSeconds = 10.0f;
            [df setFloat:TotalSeconds forKey:@"video_max_duration"]; // 初期値は10秒
            [df synchronize];
        }
    }
	int32_t preferredTimeScale = 30;	//Frames per second
	CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
	movieFileOutput.maxRecordedDuration = maxDuration;
	
	movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;	//<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
	
	if ([captureSession canAddOutput:movieFileOutput])
		[captureSession addOutput:movieFileOutput];
    
	//SET THE CONNECTION PROPERTIES (output properties)
	[self cameraSetOutputProperties];			//(We call a method as it also has to be done after changing camera)
	//----- SET THE IMAGE QUALITY / RESOLUTION -----
	//Options:
	//	AVCaptureSessionPresetHigh - Highest recording quality (varies per device)
	//	AVCaptureSessionPresetMedium - Suitable for WiFi sharing (actual values may change)
	//	AVCaptureSessionPresetLow - Suitable for 3G sharing (actual values may change)
	//	AVCaptureSessionPreset640x480 - 640x480 VGA (check its supported before setting it)
	//	AVCaptureSessionPreset1280x720 - 1280x720 720p HD (check its supported before setting it)
	//	AVCaptureSessionPresetPhoto - Full photo resolution (not supported for video output)
	NSLog(@"Setting image quality");
	[captureSession setSessionPreset:AVCaptureSessionPresetMedium];
	if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])		//Check size based configs are supported before setting them
		[captureSession setSessionPreset:AVCaptureSessionPreset640x480];
}
// セッションの終了
- (void) endSession
{
	if (! self.captureSession)
	{	return; }		// セッション終了済みまたは開始時に失敗している
	
#ifndef __i386__
	
	// セッションの停止
	[self.captureSession stopRunning];
	
	// inputとoutputを取り除く
	for (AVCaptureOutput *output in self.captureSession.outputs) {
		[self.captureSession removeOutput:output];
	}
	for (AVCaptureInput *input in self.captureSession.inputs) {
		[self.captureSession removeInput:input];
	}
    
    [videoCaptureDevice removeObserver:self forKeyPath:@"adjustingExposure"];
    [videoCaptureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
	
	[stillImageOutput release];
	stillImageOutput = nil;
	self.stillImageOutput = nil;
	
	[captureSession release];
	captureSession = nil;
	self.captureSession = nil;
	
	if (previewLayer)
	{
		[previewLayer removeFromSuperlayer];
		[previewLayer release];
		previewLayer = nil;
	}
	
#endif
	
}

// デバイス回転時の通知
- (void) notifyWillRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
									previewRect:(CGRect)rect
{
	if (! self.captureSession)
	{	return; }		// セッション終了済みまたは開始時に失敗している
	
	// デバイスの向きににてデータ方向を設定する
	AVCaptureVideoOrientation videoOrient;
	
	switch (toInterfaceOrientation)
	{
		case UIInterfaceOrientationPortrait :
			videoOrient = AVCaptureVideoOrientationPortrait;
			imageOrientation = UIImageOrientationRight;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			videoOrient = AVCaptureVideoOrientationPortraitUpsideDown;
			imageOrientation = UIImageOrientationLeft;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			videoOrient = AVCaptureVideoOrientationLandscapeLeft;
            //2012 6/15 伊藤 内カメラだと反転するため
            if (_useFrontCamera) {
                imageOrientation = UIImageOrientationUp;
            }else{
			imageOrientation = UIImageOrientationDown;
            }
			break;
		case UIInterfaceOrientationLandscapeRight:
			videoOrient = AVCaptureVideoOrientationLandscapeRight;
            if (_useFrontCamera) {
            //2012 6/15 伊藤 内カメラだと反転するため

                imageOrientation = UIImageOrientationDown;
            }else{
			imageOrientation = UIImageOrientationUp;
            }
			break;
		default:
			videoOrient = AVCaptureVideoOrientationLandscapeLeft;
			imageOrientation = UIImageOrientationDown;
			break;
	}
	
	// for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    // NSLog (@"start connection set");
	for (AVCaptureOutput *output in self.captureSession.outputs)
	{
		for (AVCaptureConnection *connection in output.connections)
		{
			if (connection.supportsVideoOrientation)
			{
				
                // NSLog(@"start set connection.videoOrientation: %@->%d",connection, videoOrient);
                // 撮影時のデータ方向を設定
				connection.videoOrientation = videoOrient;
				// NSLog(@"done set connection.videoOrientation: %@->%d",connection, videoOrient);
			}
		}
	}
    // NSLog (@"end connection set");
	
    if ([previewLayer respondsToSelector:@selector(connection)]) {
        if ([previewLayer.connection isVideoOrientationSupported]) {
            [previewLayer.connection setVideoOrientation:videoOrient];
            [previewLayer setFrame:CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height)];
        }
    }
}

// 写真を撮る
//- (void)takePicture:completionHandler:(void (^)(UIImage *pictureImage, NSError *error))handler
- (void)takePicture
{
	// self.delegate = @selector(handler);
	
	// 手ぶれ防止無効の場合は即時、写真を撮る
	if (! _isHandVibEnable)
	{
		[self _takePicture];
		return;
	}
	
	// 手ぶれ防止処理開始
	[self initAccelerometer];
}
- (void)takeVideo {
	if (!isRecording)
	{
		//----- START RECORDING -----
#ifdef DEBUG
		NSLog(@"START RECORDING");
#endif
		isRecording = YES;
        // 録画開始音を鳴らす
        AudioServicesPlaySystemSound(1117);
		
		//Create temporary URL to record to
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
#ifdef DEBUG
        NSLog(@"%@",outputPath);
#endif
		NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath:outputPath])
		{
			NSError *error = nil;
			if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
			{
                NSLog(@"%@",error.localizedDescription);
				//Error - handle if requried
			}
		}
		[outputPath release];
		//Start recording
		[movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
		[outputURL release];
        
        if ( (self.delegate) &&
            ([self.delegate respondsToSelector:@selector(lblCountHidden:)]))
        {
            [self.delegate lblCountHidden:NO];
        }
        if(self.countTimer){
            if ([self.countTimer isValid]) {
                [self.countTimer invalidate];
            }
            self.countTimer = nil;
        }
        count = 0;
        self.countTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                             target:self
                                                           selector:@selector(countTime)
                                                           userInfo:nil
                                                            repeats:YES];
	}
	else
	{
		//----- STOP RECORDING -----
#ifdef DEBUG
		NSLog(@"STOP RECORDING");
#endif
		isRecording = NO;
        
		[movieFileOutput stopRecording];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            // 録画開始音を鳴らす
            AudioServicesPlaySystemSound(1118);
        });
	}
}
- (void)countTime{
    count++;
    if ( (self.delegate) &&
        ([self.delegate respondsToSelector:@selector(lblCount:)]))
    {
        [self.delegate lblCount:count];
    }
}
- (BOOL)isRecording {
    return isRecording;
}
//2012 6/19 伊藤 videoCaptureDevice.adjusting〇〇の監視
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{    
    if ([keyPath isEqual:@"adjustingExposure"] && self.adjustingExposure) {

        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == NO) {
            NSError *error = nil;
            if ([videoCaptureDevice lockForConfiguration:&error]) {
                self.adjustingExposure = NO;
                [videoCaptureDevice setExposureMode:AVCaptureExposureModeLocked];
                [videoCaptureDevice unlockForConfiguration];
                NSLog(@"adjustingExposure");
            }
        }

    }
    if ([keyPath isEqual:@"adjustingFocus"] && self.adjustingFocus) {
        
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == NO) {
            NSError *error = nil;
            if ([videoCaptureDevice lockForConfiguration:&error]) {
                self.adjustingFocus = NO;
                [videoCaptureDevice setExposureMode:AVCaptureFocusModeLocked];
                [videoCaptureDevice unlockForConfiguration];
                NSLog(@"adjustingFocus");
            }
        }
        
    }
    //カーソルのフェードアウトアニメーション
    if (!self.adjustingExposure && !self.adjustingFocus){
        if(self.focusCursor && !animationStarted){
            animationStarted = YES;
            NSLog(@"Focus Cursor Animaiton");

            [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.focusCursor.alpha = 0;
                             }
                             completion:^(BOOL finished) {
                                 [self.focusCursor stopAnimating];
                                 self.focusCursor.hidden = YES;
                             }];
        }
    }  
}

//2012 6/26 伊藤 タッチフォーカス・露出タイムアウト処理(特に変更がない場合、デバイスから返信がないようなので)
-(void)timerTimeOut:(NSTimer*)timer{
    if(self.focusCursor && !animationStarted){
        animationStarted = YES;
        NSLog(@"adjusting TimeOut");
        
        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.focusCursor.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [self.focusCursor stopAnimating];
                             self.focusCursor.hidden = YES;
                         }];
    }
    if(self.timeOutTimer){
        if ([self.timeOutTimer isValid]) {
            [self.timeOutTimer invalidate];
        }
        self.timeOutTimer = nil;
    }
}
// 動画撮影の完了
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
#ifdef DEBUG
	NSLog(@"didFinishRecordingToOutputFileAtURL - enter");
#endif
    // 撮影時間計測の終了
    if(self.countTimer){
        if ([self.countTimer isValid]) {
            [self.countTimer invalidate];
        }
        self.countTimer = nil;
    }
    isRecording = NO;
#ifdef DEBUG
    NSLog(@"Output File URL: %@", outputFileURL);
#endif
    // クライアントクラスへのコールバック
    if ( (self.delegate) &&
        ([self.delegate respondsToSelector:@selector(onCompleteVideoWithURL:error:)]))
    {
        [self.delegate onCompleteVideoWithURL:outputFileURL error:error];
    }
    if ( (self.delegate) &&
        ([self.delegate respondsToSelector:@selector(lblCountHidden:)]))
    {
        [self.delegate lblCountHidden:YES];
        [self.delegate lblCount:0];
    }
}
@end
