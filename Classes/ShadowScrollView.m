//
//  ShadowScrollView.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/10.
//
//

#import "ShadowScrollView.h"

@implementation ShadowScrollView
@synthesize shadowSize;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef con = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(con, [UIColor colorWithWhite:0.8f alpha:0.8f].CGColor);
    CGContextSetShadow(con, shadowSize, 0.1f);
    CGContextFillRect(con, CGRectMake(0, 0, self.frame.size.width - shadowSize.width, self.frame.size.height - shadowSize.height));
}

@end
