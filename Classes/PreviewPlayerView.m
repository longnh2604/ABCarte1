//
//  PreviewPlayerView.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/12/10.
//
//

#import "PreviewPlayerView.h"

@implementation PreviewPlayerView
@synthesize runView;
- (id)init
{
    self = [super init];
    if (self) {
        // スクロール機能をオフに
        self.maximumZoomScale = 1.0;
        self.minimumZoomScale = 1.0;
        self.scrollEnabled = NO;
        self.runView = [[VideoRunButton alloc] init];
        runView.frame = CGRectMake(0, 0, 50, 50);
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self addGestureRecognizer:tap];
        [tap release];
    }
    return self;
}
- (void)setRunButton {
    CGFloat runBtnSize = self.frame.size.width / 4.0f;
    runView.frame = CGRectMake(0, 0, runBtnSize, runBtnSize);
    runView.center = CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height / 2.0f);
    [self addSubview:runView];
    //[runView setNeedsDisplay];
}
- (void)tap:(id)selector {
    if (player.rate > 0) {
        [player pause];
        runView.hidden = NO;
    } else {
        [self play];
        runView.hidden = YES;
    }
}
- (void)afterFinish {
    runView.hidden = NO;
}
- (void)dealloc {
    //[self.runView removeFromSuperview];
    [self.runView release];
    [super dealloc];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
