//
//  VideoRunButton.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/12/10.
//
//

#import "VideoRunButton.h"

@implementation VideoRunButton

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGFloat alpha = 0.65f;
    
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    //CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetRGBFillColor(context, 1, 1, 1, alpha);
    
    // 内接円の直径
    CGFloat max = MAX(rect.size.width, rect.size.height);
    // 中心
    CGPoint center = CGPointMake(rect.size.width * 0.5f, rect.size.height * 0.5f);
    // 正三角形の周りに描く円の半径
    CGFloat r = max * 0.5f * 0.5f;
    // 正三角形の外接円の半径
    CGFloat tri = max * 0.5f * 0.3333f;
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, center.x + tri * cos(- 120.0f / 180 * M_PI), center.y + tri * sin(- 120.0f / 180 * M_PI));
    CGContextAddLineToPoint(context, center.x + tri * cos(0 / 180 * M_PI), center.y + tri * sin(0 / 180 * M_PI));
    CGContextAddLineToPoint(context, center.x + tri * cos(120.0f / 180 * M_PI), center.y + tri * sin(120.0f / 180 * M_PI));
    CGContextAddLineToPoint(context, center.x + tri * cos(- 120.0f / 180 * M_PI), center.y + tri * sin(- 120.0f / 180 * M_PI));

    CGContextDrawPath(context, kCGPathFill);
    CGContextClosePath(context);
    CGContextSetRGBStrokeColor(context, 1, 1, 1, alpha);
    CGContextSetLineWidth(context, 8);
    CGContextAddEllipseInRect(context, CGRectMake(center.x - r, center.y - r, 2 * r, 2 * r));
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context);
    
    // CFRelease(context);
}

@end
