//
//  UICameraViewPicker.h
//  iPadCamera
//
//  Created by MacBook on 11/04/24.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// #import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>

#define		CAM_VIEW_PICTURE_WIDTH		960.0f			// 画像横サイズ(for iPad2)
#define		CAM_VIEW_PICTURE_HEIGHT		720.0f			// 画像縦サイズ(for iPad2)

#define     CAPTURE_FRAMES_PER_SECOND		20
@protocol UICameraViewPickerDelegate;

///
/// 内蔵カメラ用CameraViewPickerクラス
///
@interface UICameraViewPicker : NSObject
	<AVCaptureVideoDataOutputSampleBufferDelegate, UIAccelerometerDelegate,UIApplicationDelegate, AVCaptureFileOutputRecordingDelegate>
{
	UIImage				*imageBuffer;			// プレビュー用ImageBufffer
	UIImageOrientation	imageOrientation;		// プレビューの方向
	
	// 手ぶれ防止関連設定値
	BOOL		_isHandVibEnable;			// 手ぶれ防止有効フラグ
	NSInteger	_delayTime;					// 手ぶれ防止の判定時間[sec]
	u_int       _captureSpeed;				// キャプチャ速度（IPAD2_CAM_SET_CAPTURE_SPEED）
	
	float		_accelMin;					// 最小の加速度：xyz成分の和
	NSInteger	_delayTimerCounter;			// ディレイタイマーカウンタ
	NSInteger	_delayLimitCounter;
	NSInteger	_delayMaxCounter;
    
    CMMotionManager *mManager;              // CoreMotion（手振れ補正用）

	BOOL        _useFrontCamera;            //どちらのカメラか。YES:前面 NO:背面
#ifndef __i386__
	AVCaptureSession *captureSession;
    AVCaptureDevice  *videoCaptureDevice;

	AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureStillImageOutput *stillImageOutput;		// 静止画撮影用のOutput
	dispatch_queue_t queue;
#endif
    
    UIImageView     *focusCursor;
    
    BOOL            animationStarted;                    //アニメーション中か
    NSTimer         *timeOutTimer;                       //露出合わせタイムアウト処理
    NSTimer         *countTimer;                         //撮影秒数のカウント
    // 動画機能
    BOOL            isRecording;                        // 動画録画中か
    AVCaptureMovieFileOutput *movieFileOutput;          // 動画出力
    NSInteger count;
    float           iOSVersion;                         // iOSバージョン
    CGFloat         cam_picture_height;                 // 画像高さ
    CGFloat         cam_picture_width;                  // 画像幅
    NSInteger       camResolution;                      // 画像保存解像度
}

@property (nonatomic, retain) UIImage *imageBuffer;
// @property (nonatomic, retain) IBOutlet UIView *previewView;
#ifndef __i386__
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
#endif

@property (nonatomic, assign) id<UICameraViewPickerDelegate> delegate;

@property (nonatomic) BOOL isHandVibEnable;
@property (nonatomic) NSInteger	delayTime;
@property (nonatomic) u_int captureSpeed;

// 6/19 伊藤 タッチ時のフォーカス修正
@property (nonatomic) BOOL adjustingExposure;               //露出度調整中
@property (nonatomic) BOOL adjustingFocus;                  //フォーカス調整中
@property (nonatomic, retain) UIImageView *focusCursor;     //カーソルUI
@property (nonatomic,assign)  NSTimer     *timeOutTimer;    //タイムアウト用
@property (nonatomic,assign)  NSTimer     *countTimer;    //タイムアウト用

// 初期化
//		isHandVibEnable	:手ぶれ防止の有効／無効
//		delayTimer		:手ぶれ防止の判定時間[sec]
- (id) initWithHandVibSetting:(BOOL)isHandVibEnable delayTimer:(NSInteger)timer;

// セッションの開始
- (BOOL) startSessionWithPrevView:(UIView*)prevView isRearCameraUse:(BOOL)isRear;
// 動画用セッションの開始
- (BOOL) startVideoSessionWithPrevView:(UIView*)prevView isRearCameraUse:(BOOL)isRear isAuto:(BOOL)isAuto;
// セッションの終了
- (void) endSession;

// デバイス回転時の通知
- (void) notifyWillRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
									previewRect:(CGRect)rect;

// 写真を撮る
// - (void)takePicture:completionHandler:(void (^)(UIImage *pictureImage, NSError *error))handler;
- (void)takePicture;

// 6/19 伊藤 タッチ時のフォーカス修正
- (void)setFocus:(CGPoint)point;

// マニュアル露出補正
- (void)setExposure:(float)bias;

// 動画撮影
- (void)takeVideo;
- (BOOL)isRecording;
@end

@protocol UICameraViewPickerDelegate<NSObject>

@optional

// 撮影後の画像通知
- (void) onCompletePictureWithImage:(UIImage*)pictureImage error:(NSError*)error;
- (void) onCompleteVideoWithURL:(NSURL *)videoURL error:(NSError*)error;
// 撮影時間の通知
- (void)lblCountHidden:(BOOL)isHidden;
- (void)lblCount:(CGFloat)num;
@end

