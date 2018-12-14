/**
 * @file  SampleCameraRemoteViewController.m
 * @brief CameraRemoteSampleApp
 *
 * Copyright 2014 Sony Corporation
 */

#import "SonyCameraRemoteViewController.h"
#import "SampleCameraApi.h"
#import "SampleAvContentApi.h"
#import "DeviceList.h"
#import "DeviceInfo.h"
#import <UIKit/UIKit.h>
#include <sys/sysctl.h>

@implementation SonyCameraRemoteViewController {
    NSMutableArray *_apiList;
    SampleStreamingDataManager *_streamingDataManager;
    BOOL _isViewVisible;
    BOOL _isSupportedVersion;
    BOOL _isNextZoomAvailable;
    BOOL _isMovieAvailable;
    BOOL _isContentAvailable;
    BOOL _isMediaAvailable;
}

@synthesize tag;    // ステータス保持用

@synthesize CamP_StillSize;
@synthesize CamP_Rotate;
@synthesize isViewVisible;

- (id) initWithPrevView:(UIImageView*)vwImage statusDelegate:(id)delegate
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    self = [super init];
    if (self) {
        liveviewImageView = vwImage;
        _statusDelegate = delegate;
        CamP_Rotate = 0;
        apiInitDone = NO;
        _isViewVisible = YES;
        self.isViewVisible = NO;
        
        [SampleCameraApi setCancel:NO];
    }
    return self;
}

- (void)setCancel:(BOOL)val
{
    [SampleCameraApi setCancel:val];
    if (val) _statusDelegate = nil;
}

- (void)viewDidLoad
{
//    [super viewDidLoad];
//    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
}

- (void)viewDidAppear:(BOOL)animated
{
//    [super viewDidAppear:animated];

#ifdef DEBUG
    NSLog(@"SampleCameraRemoteViewController viewDidAppear");
#endif
//    [SampleCameraApi setCancel:NO];

    // initialising objects
    _apiList = [[NSMutableArray alloc] init];
    _streamingDataManager = [[SampleStreamingDataManager alloc] init];
    [_streamingDataManager retain];
    _isNextZoomAvailable = YES;
    _isMovieAvailable = NO;
    _isContentAvailable = NO;
    _isMediaAvailable = NO;
    _isViewVisible = YES;
    waitImage = NO;
    
    isiPad2 = ([UIScreen mainScreen].scale > 1.0f)? NO : YES;

    // open initial connection for webapi
    if (eventObserver) {
        [eventObserver stop];
        [eventObserver release];
    }
    eventObserver = [SampleCameraEventObserver getInstance];
    [eventObserver setDelegate:self];

    [SampleCameraApi getMethodTypes:self];

}

- (void)viewDidDisappear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    _isViewVisible = NO;
    [self closeConnection];
//    [eventObserver stop];
//    [eventObserver destroy];
//    eventObserver = nil;
//    
//    if (_apiList) {
//        [_apiList release];
//        _apiList = nil;
//    }
//    if (_streamingDataManager) {
//        [SampleStreamingDataManager isCancel:YES];
//        [_streamingDataManager release];
//        _streamingDataManager = nil;
//    }

    // open initial connection for webapi
//    [eventObserver release];

    [super viewDidDisappear:animated];
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%s [%d]", __func__, _isViewVisible);
#endif
    if (_isViewVisible) {   // viewDidDisappearが呼ばれていない場合、強制的にストップさせる
        [self forceStop];
    }
    _takePicDelegate = nil;
    _statusDelegate = nil;
    liveviewImageView = nil;

    [super dealloc];
}

/**
 * カメラ画面が表示される前に、前画面に戻る操作をされた場合の対応
 * (表示前にWebカメラに対して送信されたメッセージへの対応キャンセル)
 */
- (void)forceStop
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    if ([self isApiAvailable:API_CAMERA_stopLiveview]) {
        [SampleCameraApi stopLiveview:nil];
    }
    [eventObserver stop];
    [eventObserver destroy];
    eventObserver = nil;
    
    if (_apiList) {
        [_apiList release];
        _apiList = nil;
    }
    if (_streamingDataManager) {
        [SampleStreamingDataManager isCancel:YES];
        [_streamingDataManager release];
        _streamingDataManager = nil;
    }
    [SampleCameraApi setCancel:YES];
}

- (void)progressIndicator:(BOOL)isVisible
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible =
        isVisible;
}

/*
 * UI event implementation
 */

#pragma mark About ZOOM
// カメラZoom設定
- (void)zoomAction:(NSInteger)direction movement:(NSInteger)movement
{
    NSString *dir = (direction==0)? @"in" : @"out";
    NSString *mv;
    switch (movement) {
        case 0:
            mv = @"1shot";
            break;
        case 1:
            mv = @"start";
            break;
        case 2:
            mv = @"stop";
            break;
        default:
            mv = @"stop";
            break;
    }
    [SampleCameraApi actZoom:self direction:dir movement:mv];
}

#pragma mark Touch AF Position

- (void)touchAF:(CGPoint)point
{
    [SampleCameraApi setTouchAFPosition:self xpos:point.x ypos:point.y];
}

- (void)getStillSize;
{
    [SampleCameraApi getStillSize:self];
}

- (void)setStillSize:(NSString *)type
{
    NSString *aspect = @"4:3";
    
    if ([type isEqualToString:@"2M"]) {
        [self setPostviewImageSize:type];
    } else {
        [self setPostviewImageSize:@"Original"];
        [SampleCameraApi setStillSize:self aspect:aspect size:type];
    }
}

- (void)getAvailableStillSize
{
    [SampleCameraApi getAvailableStillSize:self];
}

- (void)setPostviewImageSize:(NSString *)postViewSize
{
    [SampleCameraApi setPostviewImageSize:self postViewSize:postViewSize];
}

- (void)setExposureCompensation:(NSInteger)exposureValue
{
    [SampleCameraApi setExposureCompensation:self exposureValue:exposureValue];
}

#pragma mark Take Picture

- (void)takePicture:(id)delegate
{
    _takePicDelegate = delegate;
    
    [SampleCameraApi actTakePicture:self];
    [self progressIndicator:YES];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"onDeleteNewCarte"];
    [defaults synchronize];
}

/*
 * Initialize client to setup liveview, camera controls and start listening to
 * camera events.
 */
- (void)initialize
{
    _isSupportedVersion = NO;

//    [SampleCameraApi setCancel:NO];

    // check available API list
    NSData *response = [SampleCameraApi getAvailableApiList:self isSync:YES];
    if (response != nil) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self parseMessage:response apiName:API_CAMERA_getAvailableApiList];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(),
                       ^{ [self openNetworkErrorDialog]; });
        return;
    }

    // check if the version of the server is supported or not
    if ([self isApiAvailable:API_CAMERA_getApplicationInfo]) {
        response = [SampleCameraApi getApplicationInfo:self isSync:YES];
        if (response != nil) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self parseMessage:response
                           apiName:API_CAMERA_getApplicationInfo];
            });
            if (!_isSupportedVersion) {
                // popup not supported version
#ifdef DEBUG
                NSLog(@"SampleCameraRemoteViewController initialize is not "
                      @"supported version");
#endif
                dispatch_async(dispatch_get_main_queue(),
                               ^{ [self openUnsupportedErrorDialog]; });
                return;
            } else {
#ifdef DEBUG
                NSLog(@"SampleCameraRemoteViewController initialize is "
                      @"supported version");
#endif
            }
        } else {
            dispatch_async(dispatch_get_main_queue(),
                           ^{ [self openNetworkErrorDialog]; });
            return;
        }
    }

    // startRecMode if necessary
    if ([self isApiAvailable:API_CAMERA_startRecMode]) {
        response = [SampleCameraApi startRecMode:self isSync:YES];
        if (response != nil) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self parseMessage:response apiName:API_CAMERA_startRecMode];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(),
                           ^{ [self openNetworkErrorDialog]; });
            return;
        }
    }

    // update available API list
    response = [SampleCameraApi getAvailableApiList:self isSync:YES];
    if (response != nil) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self parseMessage:response apiName:API_CAMERA_getAvailableApiList];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(),
                       ^{ [self openNetworkErrorDialog]; });
        return;
    }
    
    // check Exposure mode and set "Program Auto" mode
    if ([self isApiAvailable:API_CAMERA_setExposureMode]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [SampleCameraApi setExposureMode:self
                                exposureMode:@"Program Auto"];
        });
    }

    // check available shoot mode to update mode button
    if ([self isApiAvailable:API_CAMERA_getAvailableShootMode]) {
        dispatch_sync(dispatch_get_main_queue(),
                      ^{ [SampleCameraApi getAvailableShootMode:self]; });
    }

    // check method types of avContent service to update availability of movie
    if ([[DeviceList getSelectedDevice] findActionListUrl:@"avContent"] !=
        NULL) {
        dispatch_sync(dispatch_get_main_queue(),
                      ^{ [SampleAvContentApi getMethodTypes:self]; });
    }
}

/*
 * Closing the webAPI connection from the client.
 * コネクションクローズ時には、stopLiveviewだけを行う
 */
- (void)closeConnection
{
    if ([self isApiAvailable:API_CAMERA_stopLiveview]) {
        [SampleCameraApi stopLiveview:self];
    }
//    if (_streamingDataManager) {
//        [_streamingDataManager stop];
//    }
//    if ([self isApiAvailable:API_CAMERA_stopRecMode]) {
//        [SampleCameraApi stopRecMode:nil];
//    }
//    
//    [SampleCameraApi setCancel:YES];
}

/*
 * stopLiveview webAPI
 */
- (void)stopLiveView
{
    if ([self isApiAvailable:API_CAMERA_stopLiveview]) {
        [SampleCameraApi stopLiveview:self];
    }
}

/*
 * Function to check if apiName is available at any moment.
 */
- (BOOL)isApiAvailable:(NSString *)apiName
{
    BOOL ret = NO;
    if (_apiList != nil && _apiList.count > 0 &&
        [_apiList containsObject:apiName]) {
        ret = YES;
    }
    return ret;
}

/**
 * SampleEventObserverDelegate function implementation
 */

- (void)didApiListChanged:(NSMutableArray *)API_CAMERA_list
{
#ifdef DEBUG
    NSLog(@"%s:%@", __func__, [API_CAMERA_list componentsJoinedByString:@","]);
#endif
    if (_apiList) {
        [_apiList release];
    }
    _apiList = API_CAMERA_list;
    [_apiList retain];

    // start liveview if available
    if ([self isApiAvailable:API_CAMERA_startLiveview]) {
        if (![_streamingDataManager isStarted] && _isSupportedVersion && self.isViewVisible) {
            [SampleCameraApi startLiveview:self];
        }
    }

    // getEvent start if available
    if ([self isApiAvailable:API_CAMERA_getEvent] && _isSupportedVersion) {
        if (![[SampleCameraEventObserver getInstance] isStarted]) {
            double delayInSeconds = 0.2;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [[SampleCameraEventObserver getInstance] start];
            });
        }
    }

}

- (void)didCameraStatusChanged:(NSString *)status
{
#ifdef DEBUG
    NSLog(@"%s:%@", __func__, status);
#endif

    // if status is streaming
    if ([PARAM_CAMERA_cameraStatus_streaming isEqualToString:status]) {
        [SampleAvContentApi stopStreaming:self];
    }

    if ([PARAM_CAMERA_cameraStatus_contentsTransfer isEqualToString:status]) {
        [SampleCameraApi
            setCameraFunction:self
                     function:PARAM_CAMERA_cameraFunction_remoteShooting];
    }
}

- (void)didCameraFunctionChanged:(NSString *)function
{
#ifdef DEBUG
    NSLog(@"%s:%@", __func__, function);
#endif
    if ([PARAM_CAMERA_cameraFunction_contentsTransfer
            isEqualToString:function]) {
        [SampleCameraApi
            setCameraFunction:self
                     function:PARAM_CAMERA_cameraFunction_remoteShooting];
    }

    if ([PARAM_CAMERA_cameraFunction_remoteShooting isEqualToString:function]) {
        [self performSelectorInBackground:@selector(initialize)
                               withObject:NULL];
    }
}

- (void)didZoomPositionChanged:(int)zoomPosition
{
#ifdef DEBUG
    NSLog(@"%s:%d", __func__, zoomPosition);
#endif
    _isNextZoomAvailable = YES;

    [_statusDelegate didZoomChanged:zoomPosition];
}

- (void)didStorageInformationChanged:(NSArray *)storages
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    if ([storages[0] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *storageInfo = storages[0];
        if ([storageInfo[@"storageID"] isKindOfClass:[NSString class]]) {
            NSString *storageId = storageInfo[@"storageID"];
            if ([storageId isEqualToString:PARAM_CAMERA_storageId_noMedia]) {
                _isMediaAvailable = NO;
                [self.navigationItem.rightBarButtonItem setEnabled:NO];
            } else {
                _isMediaAvailable = YES;
                if (_isContentAvailable) {
                    [self.navigationItem.rightBarButtonItem setEnabled:YES];
                }
            }
        }
    }
}

- (void)didFailParseMessageWithError:(NSError *)error
{
    [self openNetworkErrorDialog];
}

- (void)didExposureCompensationChanged:(int)exposure
{
    [_statusDelegate didExposureChanged:exposure];
}

/**
 * SampleStreamingDataDelegate implementation
 */
- (void)didFetchImage:(UIImage *)image
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
//    UIImageOrientationUp : 0°/360°
//    UIImageOrientationRight : 90°
//    UIImageOrientationLeft : 270°
//    UIImageOrientationDown : 180°
//    UIImage *rotate_img = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationRight];

    if (waitImage) {
        return;     // 処理待ちフラグが立っている場合は、ストリームデータを飛ばす
    }
    waitImage = YES;
#ifdef STOP_LIVEVIEW
    DeviceInfo *devInfo = (DeviceInfo *)[DeviceList getDeviceAt:0];
    BOOL isDevHX400V = NO;
    if (devInfo) {
        if ([devInfo respondsToSelector:@selector(getFriendlyName)]) {
            if ([[devInfo getFriendlyName] isEqualToString:@"DSC-HX400V"])
                isDevHX400V = YES;
        }
    }
    // HX400Vの場合、stopLiveviewを呼ぶとうまく動作しないため
    if ([self isApiAvailable:API_CAMERA_stopLiveview] && !isDevHX400V) {
        [SampleCameraApi stopLiveview:self];
    }
#endif
    if (!self.isViewVisible) {
        return;
    }

    UIImageOrientation orient;
    orient = (CamP_Rotate==0)?   UIImageOrientationUp :
             (CamP_Rotate==90)?  UIImageOrientationRight:
             (CamP_Rotate==180)? UIImageOrientationDown:UIImageOrientationLeft;
    
    // こっちの方が若干処理が軽い
    UIImage *rotate_img = [UIImage imageWithCGImage:image.CGImage
                                              scale:image.scale
                                        orientation:orient];
//    UIImage *rotate_img = [self rotateImage:image angle:CamP_Rotate];
    
    [self paintLiveviewImage:rotate_img];
    
    double delayInSeconds = (isiPad2)? 0.2 : 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
#ifdef STOP_LIVEVIEW
        [SampleCameraApi startLiveview:self];
#endif
        waitImage = NO;
    });
}

// uiimageを回転させる
- (UIImage*)rotateImage:(UIImage*)img angle:(NSInteger)angle
{
    CGImageRef      imgRef = [img CGImage];
    CGContextRef    context;
    
    switch (angle) {
        case 270:
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(img.size.height, img.size.width), YES, img.scale);
            context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, img.size.height, img.size.width);
            CGContextScaleCTM(context, 1, -1);
            CGContextRotateCTM(context, M_PI_2);
            break;
        case 180:
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(img.size.width, img.size.height), YES, img.scale);
            context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, img.size.width, 0);
            CGContextScaleCTM(context, 1, -1);
            CGContextRotateCTM(context, -M_PI);
            break;
        case 90:
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(img.size.height, img.size.width), YES, img.scale);
            context = UIGraphicsGetCurrentContext();
            CGContextScaleCTM(context, 1, -1);
            CGContextRotateCTM(context, -M_PI_2);
            break;
        default:
            return img;
            break;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, img.size.width, img.size.height), imgRef);
    UIImage*    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (void)didStreamingStopped
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [SampleCameraApi startLiveview:self];
}

/*
 * get the scale of the image with regard to the screen size
 */
- (float)getScale:(CGSize)imageSize
{
    NSInteger imageHeight = imageSize.height;
    NSInteger imageWidth = imageSize.width;
    float hRatio = imageHeight / self.view.frame.size.height;
    float wRatio =
        imageWidth / (self.view.frame.size.width);
    if (hRatio > wRatio) {
        return hRatio;
    } else {
        return wRatio;
    }
}

- (void)paintLiveviewImage:(UIImage *)image
{
    [liveviewImageView setImage:image];
    image = NULL;
}

/**
 * Parses response of WebAPI requests.
 */

/*
 * Parser of actTakePicture response
 */
- (void)parseActTakePicture:(NSArray *)resultArray
                  errorCode:(NSInteger)errorCode
               errorMessage:(NSString *)errorMessage
{
    if (resultArray.count > 0 && errorCode < 0) {
        NSArray *pictureList = resultArray[0];
        [self didTakePicture:pictureList[0]];
    }
    // For developer : if errorCode>=0, handle the error according to
    // requirement.
}

/*
 * Get the taken picture and show
 */
- (void)didTakePicture:(NSString *)url
{
#ifdef DEBUG
    NSLog(@"%s:%@", __func__, url);
#endif
    NSData *downloadedImage = [self download:url];
    if (downloadedImage) {
        // 内部のorientationだけで回転させている。width,heightは変わらないので
        // exifの回転情報を読む必要が有るため、不採用
//        UIImage *rotate_img = [UIImage imageWithCGImage:downloadedImage.CGImage
//                                                  scale:downloadedImage.scale
//                                            orientation:UIImageOrientationRight];
        UIImage *imageToPost = [UIImage imageWithData:downloadedImage];
        // カメラの設置向きに関わらず、Orientationを固定する
        UIImage *rotate_img0 = [UIImage imageWithCGImage:imageToPost.CGImage
                                                  scale:imageToPost.scale
                                            orientation:UIImageOrientationUp];
        /*  // exif情報取得方法
        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)downloadedImage, nil);
        NSDictionary *metadata = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, nil);
        NSInteger Orientation = [[metadata objectForKey:@"Orientation"] intValue];
        CGSize size = CGSizeMake([[metadata objectForKey:@"PixelWidth"] intValue],
                                 [[metadata objectForKey:@"PixelHeight"] intValue]);
        [metadata setValue:1 forKey:@"Orientation"];
        NSMutableData *concatData = [[NSMutableData alloc] init];
        CGImageDestinationRef dest = CGImageDestinationCreateWithData((CFMutableDataRef)concatData,
                                                                      kUnknownType,
                                                                      1,
                                                                      nil);
        CGImageDestinationAddImage(dest,
                                   imageToPost.CGImage,
                                   (CFDictionaryRef)metadata);
        CGImageDestinationFinalize(dest);
         */
        UIImage *rotate_img = [self rotateImage:rotate_img0 angle:CamP_Rotate];
        if (_takePicDelegate) {
            [_takePicDelegate didReceiveSonyCameraPicture:[self resizeImg:rotate_img]];
        }
    }

    [self progressIndicator:NO];
}

- (UIImage *)resizeImg:(UIImage*)inImg
{
    if (![[self platformName] hasPrefix:@"iPad2"]) {
        return inImg;
    }
    
    CGRect rect;
    CGSize size = inImg.size;
    if (size.width>size.height) {
        rect = CGRectMake(0, 0, 1280, 960);
    } else {
        rect = CGRectMake(0, 0, 960, 1280);
    }

    UIGraphicsBeginImageContext(rect.size);     // 合成後画像の枠生成

    [inImg drawInRect:rect];
    UIImage *outImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outImg;
}

- (NSString *)platformName
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platformName = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
#ifdef DEBUG
    NSLog(@"%s : %@", __func__, platformName);
#endif
    
    return platformName;
}

/*
 * get the scale of the taken image
 */
- (float)getScaleForTakenImage:(CGSize)imageSize
{
    NSInteger imageHeight = imageSize.height;
    NSInteger imageWidth = imageSize.width;
    float hRatio = imageHeight / (self.view.frame.size.height * 0.2);
    float wRatio = imageWidth / (self.view.frame.size.width * 0.2);
    if (hRatio > wRatio) {
        return hRatio;
    } else {
        return wRatio;
    }
}

/**
 * Download image from the received URL
 */
- (NSData *)download:(NSString *)requestURL
{
    NSURL *downoadUrl = [NSURL URLWithString:requestURL];
    NSData *urlData = [NSData dataWithContentsOfURL:downoadUrl];
    if (urlData) {
        return urlData;
//        UIImage *imageToPost = [UIImage imageWithData:urlData];
//        return imageToPost;
    }
    return nil;
}

/*
 * Parser of getAvailableApiList response
 */
- (void)parseGetAvailableApiList:(NSArray *)resultArray
                       errorCode:(NSInteger)errorCode
                    errorMessage:(NSString *)errorMessage
{
    if (resultArray.count > 0 && errorCode < 0) {
        NSArray *availableApiList = resultArray[0];
        if (availableApiList != nil) {
            [self didApiListChanged:availableApiList];
        }
    }
    // For developer : if errorCode>=0, handle the error according to
    // requirement.
}

/*
 * Parser of getApplicationInfo response
 */
- (void)parseGetApplicationInfo:(NSArray *)resultArray
                      errorCode:(NSInteger)errorCode
                   errorMessage:(NSString *)errorMessage
{
    if (resultArray.count > 0 && errorCode < 0) {
        NSString *serverVersion = resultArray[1];
#ifdef DEBUG
        NSString *serverName = resultArray[0];
        NSLog(@"%s serverName    = %@", __func__, serverName);
        NSLog(@"%s serverVersion = %@", __func__, serverVersion);
#endif
        if (serverVersion != nil) {
            _isSupportedVersion = [self isSupportedServerVersion:serverVersion];
//            [self setStillSize:nil];
        }
    }
    // For developer : if errorCode>=0, handle the error according to
    // requirement.
}

- (BOOL)isSupportedServerVersion:(NSString *)version
{
    NSArray *versionModeList = [version componentsSeparatedByString:@"."];
    if (versionModeList.count > 0) {
        long major = [versionModeList[0] integerValue];
        if (2 <= major) {
            return YES;
        } else {
        }
    }
    return NO;
}

/*
 * Parser of getAvailableShootMode response
 */
- (void)parseGetAvailableShootMode:(NSArray *)resultArray
                         errorCode:(NSInteger)errorCode
                      errorMessage:(NSString *)errorMessage
{
    // For developer : if errorCode>=0, handle the error according to
    // requirement.
    [self progressIndicator:NO];
}

/*
 * Parser of startLiveview response
 */
- (void)parseStartLiveView:(NSArray *)resultArray
                 errorCode:(NSInteger)errorCode
              errorMessage:(NSString *)errorMessage
{
    if (resultArray.count > 0 && errorCode < 0) {
        NSString *liveviewUrl = resultArray[0];
#ifdef DEBUG
        NSLog(@"%s liveview = %@", __func__, liveviewUrl);
#endif
        [_streamingDataManager start:liveviewUrl viewDelegate:self];
    }
}

/*
 * Parser of Camera getmethodTypes response
 */
- (void)parseCameraGetMethodTypes:(NSArray *)resultArray
                        errorCode:(NSInteger)errorCode
                     errorMessage:(NSString *)errorMessage
{
    if (resultArray.count > 0 && errorCode < 0) {
        BOOL isSetCameraFunctionAvailable = NO;
        BOOL isGetEventAvailable = NO;

        // check setCameraFunction and getEvent
        for (int i = 0; i < resultArray.count; i++) {
            NSArray *result = resultArray[i];
            if ([(NSString *)result[0]
                    isEqualToString:API_CAMERA_setCameraFunction] &&
                [(NSString *)result[3] isEqualToString:@"1.0"]) {
                isSetCameraFunctionAvailable = YES;
            }
            if ([(NSString *)result[0] isEqualToString:API_CAMERA_getEvent] &&
                [(NSString *)result[3] isEqualToString:@"1.0"]) {
                isGetEventAvailable = YES;
            }
        }

        if (isSetCameraFunctionAvailable) {
            if (!isGetEventAvailable) {
                return;
            }
            if ([[SampleCameraEventObserver getInstance] isStarted]) {
                [[SampleCameraEventObserver getInstance] getCurrentState];
            } else {
                [[SampleCameraEventObserver getInstance] start];
            }
        } else {
            [self performSelectorInBackground:@selector(initialize)
                                   withObject:NULL];
        }
    }
}

/*
 * Parser of AvContent getmethodTypes response
 */
- (void)parseAvContentGetMethodTypes:(NSArray *)resultArray
                           errorCode:(NSInteger)errorCode
                        errorMessage:(NSString *)errorMessage
{
    BOOL isContentValid = NO;
    if (resultArray.count > 0 && errorCode < 0) {
        // check getSchemeList
        for (int i = 0; i < resultArray.count; i++) {
            NSArray *result = resultArray[i];
            if ([(NSString *)result[0]
                    isEqualToString:API_AVCONTENT_getSchemeList] &&
                [(NSString *)result[3] isEqualToString:@"1.0"]) {
                isContentValid = YES;
            }
        }
        // check getSourceList
        if (isContentValid) {
            isContentValid = NO;
            for (int i = 0; i < resultArray.count; i++) {
                NSArray *result = resultArray[i];
                if ([(NSString *)result[0]
                        isEqualToString:API_AVCONTENT_getSourceList] &&
                    [(NSString *)result[3] isEqualToString:@"1.0"]) {
                    isContentValid = YES;
                }
            }
        }
        // check getContentList
        if (isContentValid) {
            isContentValid = NO;
            for (int i = 0; i < resultArray.count; i++) {
                NSArray *result = resultArray[i];
                if ([(NSString *)result[0]
                        isEqualToString:API_AVCONTENT_getContentList] &&
                    [(NSString *)result[3] isEqualToString:@"1.3"]) {
                    isContentValid = YES;
                }
            }
        }
        if (isContentValid) {
            // Content is available
            _isContentAvailable = YES;
            if (_isMediaAvailable) {
                [self.navigationItem.rightBarButtonItem setEnabled:YES];
            }
            isContentValid = NO;

            // check for video : setStreamingContent

            for (int i = 0; i < resultArray.count; i++) {
                NSArray *result = resultArray[i];
                if ([(NSString *)result[0]
                        isEqualToString:API_AVCONTENT_setStreamingContent] &&
                    [(NSString *)result[3] isEqualToString:@"1.0"]) {
                    isContentValid = YES;
                }
            }
            // check startStreaming
            if (isContentValid) {
                isContentValid = NO;
                for (int i = 0; i < resultArray.count; i++) {
                    NSArray *result = resultArray[i];
                    if ([(NSString *)result[0]
                            isEqualToString:API_AVCONTENT_startStreaming] &&
                        [(NSString *)result[3] isEqualToString:@"1.0"]) {
                        isContentValid = YES;
                    }
                }
            }
            // check stopStreaming
            if (isContentValid) {
                isContentValid = NO;
                for (int i = 0; i < resultArray.count; i++) {
                    NSArray *result = resultArray[i];
                    if ([(NSString *)result[0]
                            isEqualToString:API_AVCONTENT_stopStreaming] &&
                        [(NSString *)result[3] isEqualToString:@"1.0"]) {
                        isContentValid = YES;
                    }
                }
            }
            if (isContentValid) {
                // video is available
                _isMovieAvailable = YES;
            }
        }
    }
}

/*
 * Parser of getApplicationInfo response
 */
- (void)parseGetStillSize:(NSArray *)resultArray
                errorCode:(NSInteger)errorCode
             errorMessage:(NSString *)errorMessage
{
    if (resultArray.count > 0 && errorCode < 0) {
#ifdef DEBUG
        NSString *aspect = resultArray[0];
        NSString *size = resultArray[1];
        NSLog(@"%s aspect [%@] size [%@]", __func__, aspect, size);
#endif
    }
    // For developer : if errorCode>=0, handle the error according to
    // requirement.
}

/*
 * Delegate parser implementation for WebAPI requests
 */
- (void)parseMessage:(NSData *)response apiName:(NSString *)apiName
{
#ifdef DEBUG
    NSString *responseText =
        [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSLog(@"%s = %@ apiName = %@", __func__, responseText, apiName);
    [responseText release];
#endif
    NSError *e = nil;
    NSDictionary *dict =
        [NSJSONSerialization JSONObjectWithData:response
                                        options:NSJSONReadingMutableContainers
                                          error:&e];
    if (e) {
#ifdef DEBUG
        NSLog(@"%s error parsing JSON string", __func__);
        NSLog(@"%@ %ld %@",[e domain],(long)[e code],[[e userInfo] description]);
#endif
        [self openNetworkErrorDialog];
        return;
    }

    NSArray *resultArray = [[NSArray alloc] init];
    if ([dict[@"result"] isKindOfClass:[NSArray class]]) {
        resultArray = dict[@"result"];
    }

    NSArray *resultsArray = [[NSArray alloc] init];
    if ([dict[@"results"] isKindOfClass:[NSArray class]]) {
        resultsArray = dict[@"results"];
    }

    NSArray *errorArray = nil;
    NSString *errorMessage = @"";
    NSInteger errorCode = -1;
    if ([dict[@"error"] isKindOfClass:[NSArray class]]) {
        errorArray = dict[@"error"];
    }
    if (errorArray != nil && errorArray.count >= 2) {
        errorCode = [(NSNumber *)errorArray[0] intValue];
        errorMessage = errorArray[1];
#ifdef DEBUG
        NSLog(@"SampleCameraRemoteViewController parseMessage API=%@, "
              @"errorCode=%ld, errorMessage=%@",
              apiName, (long)errorCode, errorMessage);
#endif
        // This error is created in HttpAsynchronousRequest
        if (errorCode == 16) {
            [self openNetworkErrorDialog];
            return;
        }
    }

    if ([apiName isEqualToString:API_CAMERA_getAvailableApiList]) {
        [self parseGetAvailableApiList:resultArray
                             errorCode:errorCode
                          errorMessage:errorMessage];
    } else if ([apiName isEqualToString:API_CAMERA_getApplicationInfo]) {
        [self parseGetApplicationInfo:resultArray
                            errorCode:errorCode
                         errorMessage:errorMessage];
    } else if ([apiName isEqualToString:API_CAMERA_getShootMode]) {

    } else if ([apiName isEqualToString:API_CAMERA_setShootMode]) {

    } else if ([apiName isEqualToString:API_CAMERA_getAvailableShootMode]) {
        [self parseGetAvailableShootMode:resultArray
                               errorCode:errorCode
                            errorMessage:errorMessage];
    } else if ([apiName isEqualToString:API_CAMERA_getSupportedShootMode]) {

    } else if ([apiName isEqualToString:API_CAMERA_startLiveview]) {
        [self parseStartLiveView:resultArray
                       errorCode:errorCode
                    errorMessage:errorMessage];
    } else if ([apiName isEqualToString:API_CAMERA_stopLiveview]) {
        // LiveViewが止まってから、下記の処理を行うように変更
        if (_streamingDataManager) {
            [_streamingDataManager stop];
        }
//        if ([self isApiAvailable:API_CAMERA_stopRecMode]) {
//            [SampleCameraApi stopRecMode:nil];
//        }
        
        [SampleCameraApi setCancel:YES];

        [eventObserver stop];
        [eventObserver destroy];
        eventObserver = nil;
        
        if (_apiList) {
            [_apiList release];
            _apiList = nil;
        }
        if (_streamingDataManager) {
            [SampleStreamingDataManager isCancel:YES];
            [_streamingDataManager release];
            _streamingDataManager = nil;
        }

    } else if ([apiName isEqualToString:API_CAMERA_startRecMode]) {

    } else if ([apiName isEqualToString:API_CAMERA_stopRecMode]) {

    } else if ([apiName isEqualToString:API_CAMERA_actTakePicture]) {
        [self parseActTakePicture:resultArray
                        errorCode:errorCode
                     errorMessage:errorMessage];
    } else if ([apiName isEqualToString:API_CAMERA_startMovieRec]) {

    } else if ([apiName isEqualToString:API_CAMERA_stopMovieRec]) {

    } else if ([apiName isEqualToString:API_CAMERA_getMethodTypes]) {
        [self parseCameraGetMethodTypes:resultsArray
                              errorCode:errorCode
                           errorMessage:errorMessage];
    } else if ([apiName isEqualToString:API_CAMERA_actZoom]) {

    } else if ([apiName isEqualToString:API_AVCONTENT_getMethodTypes]) {
        [self parseAvContentGetMethodTypes:resultsArray
                                 errorCode:errorCode
                              errorMessage:errorMessage];
    } else if ([apiName isEqualToString:API_CAMERA_getStillSize]) {
        
    } else if ([apiName isEqualToString:API_CAMERA_setTouchAFPosition]) {
        // AFが完了したらキャンセルしないと、受け付けないコマンドが有る
        [SampleCameraApi cancelTouchAFPosition:self];
    }
}

- (void)openNetworkErrorDialog
{
#ifdef DEBUG
    UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"NETWORK_ERROR_HEADING",
                                            @"NETWORK_ERROR_HEADING")
                  message:NSLocalizedString(@"NETWORK_ERROR_MESSAGE",
                                            @"NETWORK_ERROR_MESSAGE")
                 delegate:nil
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
    [alert show];
#endif
    [self progressIndicator:NO];
}

- (void)openUnsupportedErrorDialog
{
#ifdef DEBUG
    UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"UNSUPPORTED_HEADING",
                                            @"UNSUPPORTED_HEADING")
                  message:NSLocalizedString(@"UNSUPPORTED_MESSAGE",
                                            @"UNSUPPORTED_MESSAGE")
                 delegate:nil
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
    [alert show];
#endif
    [self progressIndicator:NO];
}

- (void)openUnsupportedShootModeErrorDialog
{
#ifdef DEBUG
    UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"UNSUPPORTED_HEADING",
                                            @"UNSUPPORTED_HEADING")
                  message:NSLocalizedString(@"UNSUPPORTED_SHOOT_MODE_MESSAGE",
                                            @"UNSUPPORTED_SHOOT_MODE_MESSAGE")
                 delegate:nil
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
    [alert show];
#endif
}

@end
