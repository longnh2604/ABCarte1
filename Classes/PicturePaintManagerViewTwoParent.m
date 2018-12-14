//
//  PicturePaintManagerViewTwoParent.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2014/01/15.
//
//

#import "PicturePaintManagerViewTwoParent.h"

@implementation PicturePaintManagerViewTwoParent

@synthesize scrollViewParent2;

// タッチ開始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
	if (_touchMode != MODE_VOID) {
		[scrollViewParent2 setCanCancelContentTouches:NO];		//	UIScrollViewに取られないようにする。
	}
}
// ドラッグ中：
// 最初のタッチ位置からある程度（DRAG_THRESHOLD）動かない限り、ドラッグを開始しない。
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    PICTURE_PAINT_DRAW_MODE beforeMode = _touchMode;
    
     //PicturePaintManagerView参照
    [super touchesMoved:touches withEvent:event];
    
    if ((beforeMode != MODE_VOID) && (_touchMode == MODE_VOID)) {
        [scrollViewParent2 setCanCancelContentTouches:YES];	//	UIScrollViewにまかせる。
    }}
// タッチ終了
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
	if ([[event allTouches] count] == [touches count]) {
		[scrollViewParent2 setCanCancelContentTouches:YES];
	}
}

// UIScrollViewがフリックやピンチを確認した時も送られてくる。
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
	[scrollViewParent2 setCanCancelContentTouches:YES];
}
@end
