//
//  RotateDot.h
//  Synthesis
//
//  Created by 捧 隆二 on 2013/06/19.
//  Copyright (c) 2013年 捧 隆二. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RotateDot : NSObject{
    CGPoint point;
    CGFloat radius;
    CGFloat angle;//=>いらないかも
}
@property(nonatomic) CGPoint point;
@property(nonatomic) CGFloat radius;
@property(nonatomic) CGFloat angle;

- (CGRect)rect;
@end
