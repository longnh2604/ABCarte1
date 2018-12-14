//
//  MjpegStreamSetting.h
//  acquisitionstream
//
//  Created by june on 8/5/16.
//  Copyright (c) 2016 cosview. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct {
    
    int pId;
    int pMin;
    int pMax;
    int pDefaultValue;
    
} property_control_info_t;

@interface MjpegStreamSetting : NSObject

//init
-(void)initWebContent;

//分辨率
-(NSArray*)getResolutions;
-(void)setResolution:(int)resolutionindex casefps:(int)fps;

//帧率
-(NSArray*)getFps;
-(void)setFps:(int)resolutionindex casefps:(int)fps;

//属性设置
-(property_control_info_t)getProperty:(NSString *)name;
-(void)setProperty:(NSString*)propertyName ID:(int)propertyId Value:(int)propertyValue;

-(void)snap; //设置按键拍照

@end
