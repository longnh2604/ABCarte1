//
//  PullScrollView.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/21.
//
//

#import <UIKit/UIKit.h>

@protocol PullScrollViewDelegate;

const int pullDistance = 60;
@interface PullScrollView : UIScrollView<UIScrollViewDelegate>{
    BOOL inProcess;
    BOOL untilStop;
    UIActivityIndicatorView *indicator;
    id<PullScrollViewDelegate> pullScrollViewDelegate;
}
- (id)initWithDelegate:(id)pullDelegate;
- (BOOL)inProcess;
- (void)processEnd;
@end

@protocol PullScrollViewDelegate <NSObject>
@optional
- (void)pullDownDidEnd;
- (void)pullUpDidEnd;
@end
