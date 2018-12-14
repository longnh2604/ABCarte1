//
//  ResizeDot.m
//  Synthesis
//
//  Created by 捧 隆二 on 2013/06/19.
//  Copyright (c) 2013年 捧 隆二. All rights reserved.
//

#import "ResizeDot.h"

@implementation ResizeDot
@synthesize point, radius, longRadius, x, y, active;
- (id)init{
    if (self = [super init]) {
        self.point = CGPointMake(0.0f, 0.0f);
        self.radius = 0.0f;
        self.longRadius = 0.0f;
        self.x = 0;
        self.y = 0;
        self.active = true;
    }
    return  self;
}
@end
