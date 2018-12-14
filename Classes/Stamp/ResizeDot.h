//
//  ResizeDot.h
//  Synthesis
//
//  Created by 捧 隆二 on 2013/06/19.
//  Copyright (c) 2013年 捧 隆二. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResizeDot : NSObject{
    CGPoint point;
    CGFloat radius;
    CGFloat longRadius;
    int x;
    int y;
    BOOL active;
}
@property(nonatomic) CGPoint point;
@property(nonatomic) CGFloat radius;
@property(nonatomic) CGFloat longRadius;
@property(nonatomic) int x;
@property(nonatomic) int y;
@property(nonatomic) BOOL active;
-(id)init;
@end
