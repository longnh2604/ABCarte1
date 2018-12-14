//
//  MjpegStreamView.h
//  acquisitionstream
//
//  Created by june on 8/3/16.
//  Copyright (c) 2016 cosview. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MjpegStreamView : UIImageView

//control
-(void)play;
-(void)pause;
-(void)clear;
-(void)stop;

//拍照
-(UIImage*)getImage;
//录制视频
-(void)recordVideo:(NSInteger)sender;

@end
