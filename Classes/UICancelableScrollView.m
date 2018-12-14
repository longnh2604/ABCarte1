//
//  UICancelableScrollView.m
//  iPadCamera
//
//  Created by OP075 on 2013/12/21.
//
//

#import "UICancelableScrollView.h"

@implementation UICancelableScrollView

#pragma mark life_cycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

#pragma mark override_methods

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{

    // タッチされたビューを取得する
    UIView *hitView = [super hitTest:point withEvent:event];

    // NSLog(@"%s", __func__);
    
    BOOL isScroll = YES;
    
    if ([((NSObject*)self.chacelableDelegate)
         respondsToSelector:@selector(isTouchDeliverd: touchPoint: touchView:)]) {
        
        isScroll =  [self.chacelableDelegate isScrollPerformed:self touchView:hitView];
    }
    
    self.scrollEnabled = isScroll;
    
    return (hitView);
}

// override points for subclasses to control delivery of touch events to subviews of the scroll view
// called before touches are delivered to a subview of the scroll view. if it returns NO the touches will not be delivered to the subview
// default returns YES
- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    BOOL isDelivered = YES;
    
    if ([((NSObject*)self.chacelableDelegate)
                respondsToSelector:@selector(isTouchDeliverd: touchPoint: touchView:)]) {
        
        UITouch *touch = [touches anyObject];
        CGPoint pt = [touch locationInView:self.superview];
        
        isDelivered =  [self.chacelableDelegate isTouchDeliverd:self touchPoint:pt touchView:touch.view];
    }
    
    return (isDelivered);
}

// called before scrolling begins if touches have already been delivered to a subview of the scroll view. if it returns NO the touches will continue to be delivered to the subview and scrolling will not occur
// not called if canCancelContentTouches is NO. default returns YES if view isn't a UIControl
/*- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    BOOL isScroll = YES;
    
    if ([((NSObject*)self.chacelableDelegate)
         respondsToSelector:@selector(isTouchDeliverd: touchPoint: touchView:)]) {
        
        isScroll =  [self.chacelableDelegate isScrollPerformed:self touchView:view];
    }
    
    return (isScroll);
}*/

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
