//
//  TouchArgs.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/07/09.
//


#import <Foundation/Foundation.h>

@interface TouchArgs : NSObject{
    NSUInteger number;
    CGPoint point;
    CGPoint pointInS;
}
@property(nonatomic) NSUInteger number;
@property(nonatomic) CGPoint point;
@property(nonatomic) CGPoint pointInS;

@end