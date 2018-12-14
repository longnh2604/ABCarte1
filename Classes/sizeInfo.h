//
//  sizeInfo.h
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface sizeInfo : NSObject
//サイズ
@property(nonatomic)			CGFloat                 Height;
@property(nonatomic)			CGFloat                 Weight;
@property(nonatomic)			CGFloat                 TopBreast;
@property(nonatomic)			CGFloat                 UnderBreast;
@property(nonatomic)			CGFloat                 Waist;
@property(nonatomic)			CGFloat                 Hip;
@property(nonatomic)			CGFloat                 Thigh;
@property(nonatomic)			CGFloat                 HipHeight;
@property(nonatomic)			CGFloat                 WaistHeight;
@property(nonatomic)			CGFloat                 TopBreastHeight;

// データのクリア
-(void) allDataClaer;

@end
