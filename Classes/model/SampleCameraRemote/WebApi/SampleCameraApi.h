/**
 * @file  SampleCameraApi.h
 * @brief CameraRemoteSampleApp
 *
 * Copyright 2014 Sony Corporation
 */

#import "HttpAsynchronousRequest.h"
#import "HttpSynchronousRequest.h"
#import "SampleCameraDefinitions.h"

@interface SampleCameraApi : NSObject

+ (void)setCancel:(BOOL)val;

+ (NSData *)getAvailableApiList:
                (id<HttpAsynchronousRequestParserDelegate>)parserDelegate
                         isSync:(BOOL)isSync;

+ (NSData *)getApplicationInfo:
                (id<HttpAsynchronousRequestParserDelegate>)parserDelegate
                        isSync:(BOOL)isSync;

+ (void)getMethodTypes:
        (id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)getShootMode:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)setShootMode:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
           shootMode:(NSString *)shootMode;

+ (void)getAvailableShootMode:
        (id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)getSupportedShootMode:
        (id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)startLiveview:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)stopLiveview:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (NSData *)startRecMode:
                (id<HttpAsynchronousRequestParserDelegate>)parserDelegate
                  isSync:(BOOL)isSync;

+ (void)stopRecMode:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)actTakePicture:
        (id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)startMovieRec:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)stopMovieRec:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)actZoom:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
      direction:(NSString *)direction
       movement:(NSString *)movement;

+ (void)getEvent:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
    longPollingFlag:(BOOL)longPollingFlag;

+ (void)setCameraFunction:
            (id<HttpAsynchronousRequestParserDelegate>)parserDelegate
                 function:(NSString *)function;

+ (void)setStillSize:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
              aspect:(NSString *)aspect
                size:(NSString *)size;

+ (void)getStillSize:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)setTouchAFPosition:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
                      xpos:(double)xpos
                      ypos:(double)ypos;

+ (void)cancelTouchAFPosition:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)getAvailableStillSize:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate;

+ (void)setPostviewImageSize:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
                postViewSize:(NSString *)postViewSize;

+ (void)setExposureCompensation:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
                  exposureValue:(NSInteger)exposureValue;

+ (void)setExposureMode:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
           exposureMode:(NSString*)exposureMode;

@end
