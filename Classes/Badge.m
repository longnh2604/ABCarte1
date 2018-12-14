//
//  Badge.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/10.
//
//

#import "Badge.h"
#import <QuartzCore/QuartzCore.h>

@implementation Badge
@synthesize color;//, number;
@synthesize status;     // バッジ内容文字列

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (id)init{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.frame = CGRectMake(0, 0, 26, 26);
    }
    return self;
}
- (void)setNumber:(NSInteger)_number{
    number = _number;
    if (number > 0) {
        self.hidden = NO;
    } else{
        self.hidden = YES;
    }
}
- (NSInteger)number{
    return number;
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    if (number > 0) {
        NSString *numStr = [NSString stringWithFormat:@"%ld", (long)number];
        CGContextRef con = UIGraphicsGetCurrentContext();
        CGContextSaveGState(con);
        //色
        CGContextSetFillColorWithColor(con, color.CGColor);
        CGContextBeginPath(con);
        //右半分の円
        //CGContextAddArc(con, self.center.x, self.center.y, 10, -1 * M_PI_4, M_PI_4, 1);
        //CGContextAddArc(con, self.center.x, self.center.y, 10, M_PI_4, 3 * M_PI_4, 1);
        CGContextAddArc(con, 13, 13, 10, -1 * M_PI_4, M_PI_4, 1);
        CGContextAddArc(con, 13, 13, 10, M_PI_4, 3 * M_PI_4, 1);
        CGContextDrawPath(con, kCGPathFill);
        CGContextRestoreGState(con);
        //枠線
        /*
         CGContextSaveGState(con);
         CGContextSetStrokeColorWithColor(con, [UIColor grayColor].CGColor);
         CGContextAddArc(con, self.center.x, self.center.y, 10, -1 * M_PI_4, M_PI_4, 1);
         CGContextAddArc(con, self.center.x, self.center.y, 10, M_PI_4, 3 * M_PI_4, 1);
         CGContextDrawPath(con, kCGPathStroke);
         CGContextRestoreGState(con);
         */
        //文字描画
        CGContextSetFillColorWithColor(con, [UIColor whiteColor].CGColor);
        //CGPoint sp = self.frame.origin;
        CGPoint sp = CGPointZero;
        [numStr drawInRect:CGRectMake(sp.x + 6, sp.y + 6, 14.0f, 14.0f)
                  withFont:[UIFont boldSystemFontOfSize:12.0f]
             lineBreakMode:NSLineBreakByClipping
                 alignment:NSTextAlignmentCenter];
        CGContextSetFillColorWithColor(con, [UIColor blackColor].CGColor);
        [status drawInRect:CGRectMake(sp.x + 24, sp.y + 5, 70.0f, 16.0f)
                  withFont:[UIFont boldSystemFontOfSize:14.0f]
             lineBreakMode:NSLineBreakByClipping
                 alignment:NSTextAlignmentCenter];
    }
}

@end
