//
//  UISelectedButton.m
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "UISelectedButton.h"

@implementation UISelectedButton

#pragma mark life_cycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark override

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 同列のUISelectButtonを探して、枠を消す
    for (UIView *vw in self.superview.subviews) {
        if (! [vw isKindOfClass:[UISelectedButton class]]) {
            continue;
        }
        if (vw == self) {
            continue;
        }

        // 枠を消す
        [(UISelectedButton*)vw setBorder:NO];
    }

    // このボタンに枠をつける
    [self setBorder:YES];
 
    [super touchesEnded:touches withEvent:event];
}

#pragma mark- public_methods

// 枠の設定
- (void) setBorder:(BOOL)isSet
{
    UIImage * img =(isSet)? [UIImage imageNamed:BORDER_RESOUCE_NAME] : nil;
    
    [self setImage:img forState:UIControlStateNormal];
}

@end
