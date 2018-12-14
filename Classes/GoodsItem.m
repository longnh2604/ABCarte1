//
//  GoodsItem.m
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "GoodsItem.h"

@implementation GoodsItem
@synthesize GenreID;

@synthesize goodsID;
@synthesize goodsName;

@synthesize selectColorNum;
@synthesize colorName;

@synthesize ColorList;
@synthesize selectBtn;
@synthesize selectImageView;
@synthesize selectSize;
@synthesize sizeType;
@synthesize sizeBtn;

-(id)init{
    [super init];
    ColorList = [[NSMutableArray alloc]init];
    return self;
}

-(void)setColorItem:(NSString *)setColorName
         colorImage:(NSString *)colorImage{
    GoodsColorItem *colorItem = [[GoodsColorItem alloc]init];
    colorItem.GoodsImage = [UIImage imageNamed:colorImage];
    colorItem.ColorName = setColorName;
    [ColorList addObject:colorItem];
}

@end
