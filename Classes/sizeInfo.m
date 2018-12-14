//
//  sizeInfo.m
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "sizeInfo.h"

@implementation sizeInfo

@synthesize Height;
@synthesize Weight;
@synthesize TopBreast;
@synthesize UnderBreast;
@synthesize Waist;
@synthesize Hip;
@synthesize Thigh;
@synthesize HipHeight;
@synthesize WaistHeight;
@synthesize TopBreastHeight;


-(void) _initialize
{
    self.Height = 0;
    self.Weight = 0;
    self.TopBreast = 0;
    self.UnderBreast = 0;
    self.Waist = 0;
    self.Hip = 0;
    self.Thigh = 0;
    self.HipHeight = 0;
    self.WaistHeight = 0;
    self.TopBreastHeight = 0;
}

-(id)init{
    [super init];
    
    [self _initialize];

    return self;
}

// データのクリア
-(void) allDataClaer
{
    [self _initialize];
}

@end
