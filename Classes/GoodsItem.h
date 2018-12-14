//
//  GoodsItem.h
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

typedef enum {
    S1      = 0,
    S2      = 1,
    SII     = 2,
    S3      = 3
    
}SIZE_TYPE_NAME;

#import <Foundation/Foundation.h>
#import "GoodsColorItem.h"
@interface GoodsItem : NSObject{
    NSInteger       GenreID;
    NSInteger       goodsID;
    UILabel         *goodsName;
    NSInteger       selectColorNum;
    UILabel         *colorName;
    UIButton        *selectBtn;
    UIImageView     *selectImageView;
    NSMutableArray  *ColorList;
    NSInteger       selectSize;
    NSInteger       sizeType;
    UIButton        *sizeBtn;
}
@property(nonatomic,assign)     NSInteger       GenreID;
@property(nonatomic,assign)     NSInteger       goodsID;
@property(nonatomic,retain)     UILabel         *goodsName;
@property(nonatomic,retain)     UIButton        *selectBtn;

@property(nonatomic,assign)     NSInteger       selectColorNum;
@property(nonatomic,retain)     UILabel         *colorName;
@property(nonatomic,retain)     UIImageView     *selectImageView;
@property(nonatomic,retain)     NSMutableArray  *ColorList;
@property(nonatomic)            NSInteger       selectSize;
@property(nonatomic)            NSInteger       sizeType;
@property(nonatomic,retain)     UIButton        *sizeBtn;



-(void)setColorItem:(NSString *)setColorName
         colorImage:(NSString *)colorImage;
@end
