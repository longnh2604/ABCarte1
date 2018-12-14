//
//  PullScrollView.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/21.
//
//

#import "PullScrollView.h"

@implementation PullScrollView
#pragma mark public
- (id)initWithDelegate:(id)pullDelegate{
    self = [super init];
    if (self) {
        self.delegate = self; // UIScrollViewのdelegate
        pullScrollViewDelegate = pullDelegate; // PullScrollViewのdelegate
        indicator = [[UIActivityIndicatorView alloc] init];
        indicator.frame = CGRectMake(0, -1 * pullDistance, 50, pullDistance);
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        inProcess = NO;
        untilStop = NO;
    }
    return self;
}
- (BOOL)inProcess{
    return inProcess;
}
- (void)processEnd{
    inProcess = NO;
    [UIView animateWithDuration:0.2f
                     animations:^(void){
                         self.contentInset = UIEdgeInsetsZero;
                         [indicator stopAnimating];
                     }];
}
#pragma mark private
// 自らの高さよりも常に高くして、スクロール可能とする。
- (void)setContentSize:(CGSize)contentSize{
    CGSize sz = self.frame.size;
    sz = CGSizeMake(sz.width, MAX(contentSize.height, sz.height + 1));
    [super setContentSize: sz];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y < -1 * pullDistance && !inProcess && !untilStop) {
        inProcess = YES;
        untilStop = YES;
        indicator.center = CGPointMake(self.frame.size.width * 0.5f, -0.5f * pullDistance);
        [self addSubview:indicator];
        self.contentInset = UIEdgeInsetsMake(pullDistance, 0, 0, 0);
        [indicator startAnimating];
        [pullScrollViewDelegate pullDownDidEnd];
    } else if (scrollView.contentOffset.y + self.frame.size.height >
               self.contentSize.height + pullDistance && !inProcess && !untilStop) {
        inProcess = YES;
        untilStop = YES;
        indicator.center = CGPointMake(self.frame.size.width * 0.5f, self.contentSize.height + 0.5f * pullDistance);
        [self addSubview:indicator];
        self.contentInset = UIEdgeInsetsMake(0, 0, pullDistance, 0);
        [indicator startAnimating];
        [pullScrollViewDelegate pullUpDidEnd];
    }
}
//動いている途中にprocessEndが呼ばれるともう一度scrollViewDidScrollのif文を通過してしまうのでその対策。
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    untilStop = NO;
}
@end
