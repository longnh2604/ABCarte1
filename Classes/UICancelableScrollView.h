//
//  UICancelableScrollView.h
//  iPadCamera
//
//  Created by OP075 on 2013/12/21.
//
//

#import <UIKit/UIKit.h>

@protocol UICancelableScrollViewDelegate;


/**
 * 取り消し可能なScrollView
 */
@interface UICancelableScrollView : UIScrollView

@property(nonatomic,assign) id<UICancelableScrollViewDelegate>      chacelableDelegate;

@end

@protocol UICancelableScrollViewDelegate<NSObject>
@optional

- (BOOL) isTouchDeliverd:(UICancelableScrollView*)scrollView touchPoint:(CGPoint)pt touchView:(UIView*)vw;

- (BOOL) isScrollPerformed:(UICancelableScrollView*) scrollView touchView:(UIView*)vw;

@end