//
//  RotateDot.m
//  Synthesis
//
//  Created by 捧 隆二 on 2013/06/19.
//  Copyright (c) 2013年 捧 隆二. All rights reserved.
//

#import "RotateDot.h"

@implementation RotateDot
@synthesize point, radius, angle;

- (CGRect)rect{
    //return CGRectMake(point.x - radius, point.y - radius, 2 * radius, 2 * radius);
    return CGRectMake(point.x - 10, point.y - 9, 20, 18);
}

@end
