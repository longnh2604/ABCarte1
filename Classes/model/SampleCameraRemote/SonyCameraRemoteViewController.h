/**
 * @file  SampleCameraRemoteViewController.h
 * @brief CameraRemoteSampleApp
 *
 * Copyright 2014 Sony Corporation
 */

#import "SampleCameraEventObserver.h"
#import "SampleStreamingDataManager.h"
#import "ImageIO/ImageIO.h"

@protocol takePicDelegate <NSObject>

- (void)didReceiveSonyCameraPicture:(UIImage *)image;

@end

@protocol statusPicDelegate <NSObject>

- (void)didZoomChanged:(int)zoomPosition;
- (void)didExposureChanged:(int)exposure;

@end

@interface SonyCameraRemoteViewController : UIViewController
<
        SampleEventObserverDelegate,
        HttpAsynchronousRequestParserDelegate,
        SampleStreamingDataDelegate
>
{
    UIImageView *liveviewImageView;
    
    id          _takePicDelegate;       // 撮影デリゲート
    id          _statusDelegate;        // その他カメラステータスデリゲート
    
    SampleCameraEventObserver *eventObserver;
    
    BOOL        apiInitDone;
    
    BOOL        waitImage;              // イメージ表示処理待ちフラグ
    BOOL        isiPad2;                // iPad2か？
}

@property (nonatomic) NSInteger tag;    // ステータス保持用

@property (nonatomic) NSInteger CamP_ZoomPos;
@property (nonatomic) CGSize    CamP_StillSize;
@property (nonatomic) NSInteger CamP_Rotate;

@property (nonatomic) BOOL      isViewVisible;

//@property (weak, nonatomic) IBOutlet UIButton *modeButtonText;
//@property (weak, nonatomic) IBOutlet UIButton *actionButtonText;
//@property (weak, nonatomic) IBOutlet UIImageView *liveviewImageView;
//@property (weak, nonatomic) IBOutlet UIImageView *takePictureView;
//@property (weak, nonatomic) IBOutlet UILabel *cameraStatusView;
//@property (weak, nonatomic) IBOutlet UIView *sideView;
//@property (weak, nonatomic) IBOutlet UIButton *zoomInButton;
//@property (weak, nonatomic) IBOutlet UIButton *zoomOutButton;

// 初期化（ライブView指定 / デリゲート指定）
- (id) initWithPrevView:(UIImageView*)vwImage statusDelegate:(id)delegate;

- (void)takePicture:(id)delegate;               // 写真撮影

// カメラZoom設定
- (void)zoomAction:(NSInteger)direction movement:(NSInteger)movement;

/*
 * Function to check if apiName is available at any moment.
 */
- (BOOL)isApiAvailable:(NSString *)apiName;

- (void)touchAF:(CGPoint)point;

- (void)getStillSize;

- (void)setStillSize:(NSString *)type;

- (void)getAvailableStillSize;

- (void)setPostviewImageSize:(NSString *)postViewSize;

- (void)setExposureCompensation:(NSInteger)exposureValue;

- (void)stopLiveView;

- (void)setCancel:(BOOL)val;

@end
