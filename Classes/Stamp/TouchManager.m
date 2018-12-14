//
//  TouchManager.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/07/12.
//
//

#import "TouchManager.h"
#import "TouchArgs.h"

@implementation TouchManager
- (id)init{
    self = [super init];
    if (self) {
        center = CGPointZero;
        offset = CGPointZero;
        width_magn = 0;
        height_magn = 0;
        preAngle = 0;
        angle = 0;
        preSize = CGSizeZero;
        size = CGSizeZero;
        touches_ = CFDictionaryCreateMutable(NULL, MAX_TOUCHES, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (void)registerBeganTouches:(NSSet *)touches event:(UIEvent *)event stamp:(Stamp *)stamp atView:(UIView *)view{
    for (UITouch *touch in touches) {
        CGPoint touchInV = [touch locationInView:view];
        CGPoint touchInS = [stamp NVtoRV:touchInV];
        NSUInteger status = [self touchStatus:event];
        if (CGRectContainsPoint([TouchManager rectEx:stamp.rect] , touchInS)){
            for(NSUInteger flag=1; flag<= 2; flag++){
                if ((status & flag) == 0) {
#ifdef DEBUG
                    NSLog(@"status %ld add flag %ld", (long)status, (long)flag);
#endif
                    TouchArgs *ta = [[TouchArgs alloc] init];
                    ta.number = flag;
                    ta.point = touchInV;
                    ta.pointInS = touchInS;
                    CFDictionarySetValue(touches_, touch, ta);
                    break;
                }
            }
        }
    }
    [self setOffset:stamp event:event atView:view];
}

#if 1 // 不具合対応 kikuta - start - 2014/01/30
- (BOOL) isStampInRect:(NSSet*)touches
                 event:(UIEvent*)event
                 stamp:(Stamp*)stamp
                atView:(UIView*)view
{
    for (UITouch *touch in [event allTouches])
    {
        if (!CFDictionaryContainsKey(touches_, touch))
        {
            CGPoint touchInV = [touch locationInView:view];
            CGPoint touchInS = [stamp NVtoRV:touchInV];
            if (CGRectContainsPoint([TouchManager rectEx: stamp.rect], touchInS))
            {
                // スタンプの矩形内
                return true;
            }
        }
    }
    // スタンプの矩形外
    return false;
}
#endif // 不具合対応 kikuta - end - 2014/01/30

- (void)moveTouches:(NSSet *)touches event:(UIEvent *)event stamp:(Stamp *)stamp atView:(UIView *)view {
    //未登録のタッチを登録
    for (UITouch *touch in [event allTouches]) {
        if (!CFDictionaryContainsKey(touches_, touch)) {
            CGPoint touchInV = [touch locationInView:view];
            CGPoint touchInS = [stamp NVtoRV:touchInV];
            NSUInteger status = [self touchStatus:event];
            if (CGRectContainsPoint([TouchManager rectEx: stamp.rect], touchInS)){
                for(NSUInteger flag=1; flag<= 2; flag++){
                    if ((status & flag) == 0) {
                        TouchArgs *ta = [[TouchArgs alloc] init];
                        ta.number = flag;
                        ta.point = touchInV;
                        ta.pointInS = touchInS;
                        CFDictionarySetValue(touches_, touch, ta);
                        break;
                    }
                }
                [self setOffset:stamp event:event atView:view];
                preAngle = angle;
                preSize = stamp.size;
            }
        }
    }
    
    NSMutableArray *tas = [self touchArgsFromAllTouches:event];
//    NSLog(@"Tas count %d %d",[tas count], [[event allTouches] count]);
    if ([tas count] == 1) {
        // TouchArgs *ta = [tas objectAtIndex:0];
//        NSLog(@"Ta %d", ta.number);
        
        for (UITouch *touch in [event allTouches]) {
            if (CFDictionaryContainsKey(touches_, touch)) {
                
                CGPoint touchInV = [touch locationInView:view];
                center = [Stamp centerFromTap:touchInV Offset:offset];
                break;
            }
        }
    } else if ([tas count] >=2){
        CGPoint b1 = CGPointZero;
        CGPoint b2 = CGPointZero;
        CGPoint m1 = CGPointZero;
        CGPoint m2 = CGPointZero;
        CGPoint bs1 = CGPointZero;
        CGPoint bs2 = CGPointZero;
        CGPoint ms1 = CGPointZero;
        CGPoint ms2 = CGPointZero;
        for (UITouch *touch in [event allTouches]) {
            if (CFDictionaryContainsKey(touches_, touch)) {
                TouchArgs *ta = CFDictionaryGetValue(touches_, touch);
                CGPoint touchInV = [touch locationInView:view];
                CGPoint touchInS = [stamp NVtoRV:touchInV];
                if (ta.number == 1) {
                    b1 = ta.point;
                    bs1 = ta.pointInS;
                    m1 = touchInV;
                    ms1 = touchInS;
                } else if (ta.number == 2){
                    b2 = ta.point;
                    bs2 = ta.pointInS;
                    m2 = touchInV;
                    ms2 = touchInS;
                }
            }
        }
        //center
        CGPoint touchCenter = CGPointMake((m1.x + m2.x) * 0.5f, (m1.y + m2.y) * 0.5f);
        center = [Stamp centerFromTap:touchCenter Offset:offset];
        //size
        /*
        CGFloat preXDistance = abs(bs1.x - bs2.x);
        CGFloat preYDistance = abs(bs1.y - bs2.y);
        CGFloat xDistance = abs(ms1.x - ms2.x);
        CGFloat yDistance = abs(ms1.y - ms2.y);
        width_magn = (preXDistance == 0) ? 1 : xDistance / preXDistance;
        height_magn = (preYDistance == 0) ? 1 : yDistance / preYDistance;
        size = CGSizeMake(preSize.width * width_magn, preSize.height * height_magn);
        //height_magn = yDistance - preYDistance;
        */
        CGFloat preD = [Stamp distanceBetween:bs1 and:bs2];
        CGFloat aftD = [Stamp distanceBetween:ms1 and:ms2];
        CGFloat bairitsu = (preD == 0) ? 1 : aftD / preD;
        size = CGSizeMake(preSize.width * bairitsu, preSize.height * bairitsu);
        CGFloat sqrMenseki = sqrtf(size.width * size.height);
        CGFloat max = 2000;
        if (sqrMenseki > max) {
            size = CGSizeMake(size.width * max / sqrMenseki, size.height * max / sqrMenseki);
        }
        //angle
        CGFloat beforeAngle = -1 * atan2(b1.x - b2.x, b1.y - b2.y);
        CGFloat afterAngle = -1 * atan2(m1.x - m2.x, m1.y - m2.y);
        angle = preAngle + (afterAngle - beforeAngle);
        
        
        
        /*
        CGFloat width_magn = touchM.width_magn;
        CGFloat height_magn = touchM.height_magn;
        *
        if (width_magn > 0) {
            stamp.size = CGSizeMake(abs(preStamp.size.width + width_magn), preStamp.size.height);
        }
        if (height_magn > 0) {
            stamp.size = CGSizeMake(preStamp.size.width, abs(preStamp.size.height + height_magn));
        }
         */
    }
}
- (void)endTouches:(NSSet *)touches event:(UIEvent *)event stamp:(Stamp *)stamp atView:(UIView *)view{
    for (UITouch *touch in touches) {
        if (CFDictionaryContainsKey(touches_, touch)) {
            TouchArgs *ta = CFDictionaryGetValue(touches_, touch);
            [ta release];
            CFDictionaryRemoveValue(touches_, touch);
        }
    }
    [self setOffset:stamp event:event atView:view];
}
- (CGPoint)center{
    return center;
}
- (CGFloat)width_magn{
    return width_magn;
}
//
- (CGFloat)height_magn{
    return height_magn;
}
//size
- (CGSize)size{
    return size;
}
//angle
- (CGFloat)angle{
    return angle;
}

//タッチしている数に関わらずオフセットを設定
- (void)setOffset: (Stamp *)stamp event:(UIEvent *)event atView:(UIView *)view{
    NSMutableArray *tas = [self touchArgsFromAllTouches:event];
    if ([tas count] == 1) {
        for (UITouch *touch in [event allTouches]) {
            if (CFDictionaryContainsKey(touches_, touch)) {
                CGPoint point = [touch locationInView:view];
#ifdef DEBUG
                NSLog(@"offsetx %f y %f", offset.x, offset.y);
#endif
                offset = [Stamp offsetTap:point fromCenter:stamp.center];
#ifdef DEBUG
                NSLog(@"tapx %f y %f cenx %f y %f offsetx %f y %f ", point.x,point.y, stamp.center.x, stamp.center.y, offset.x, offset.y);
#endif
            }
        }
    } else if ([tas count] >= 2){
        CGPoint p1 = CGPointZero;
        CGPoint p2 = CGPointZero;
        int i = 0;
        for (UITouch *touch in [event allTouches]) {
            if (CFDictionaryContainsKey(touches_, touch)) {
                if (i == 0) {
                    p1 = [touch locationInView:view];
                    i++;
                }else{
                    p2 = [touch locationInView:view];
                }
            }
        }
        CGPoint c = CGPointMake((p1.x + p2.x) * 0.5f,
                                     (p1.y + p2.y) * 0.5f);
        offset = [Stamp offsetTap:c fromCenter:stamp.center];
    }
}
- (NSUInteger)touchNumber:(UIEvent *)event{
    NSUInteger result = 0;
    for (UITouch *touch in [event allTouches]) {
        if (CFDictionaryContainsKey(touches_, touch)) {
            result++;
        }
    }
    return result;
    
}
- (NSUInteger)touchStatus:(UIEvent *)event{
    NSUInteger result = 0;
    for (UITouch *touch in [event allTouches]) {
        if (CFDictionaryContainsKey(touches_, touch)) {
            TouchArgs *ta = CFDictionaryGetValue(touches_, touch);
            result |= ta.number;
        }
    }
    return result;
}
- (NSMutableArray *)touchArgsFromAllTouches:(UIEvent *)event{
    NSMutableArray *tas = [NSMutableArray array];
    for (UITouch *touch in [event allTouches]) {
        if (CFDictionaryContainsKey(touches_, touch)) {
            TouchArgs *ta = CFDictionaryGetValue(touches_, touch);
            [tas addObject:ta];
        }
    }
    return tas;
}
//小さい時、タッチ出来なくなるため、実際のサイズより当たり判定を緩和する。
+ (CGRect)rectEx:(CGRect)rect{
    CGFloat ex = 100;
    return CGRectMake(rect.origin.x - ex,
                      rect.origin.y - ex,
                      rect.size.width + 2 * ex,
                      rect.size.height + 2 * ex);
}
@end
