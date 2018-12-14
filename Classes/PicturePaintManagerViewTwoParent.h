//
//  PicturePaintManagerViewTwoParent.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2014/01/15.
//
//

#import "PicturePaintManagerView.h"

@interface PicturePaintManagerViewTwoParent : PicturePaintManagerView {
    
	UIScrollView	*scrollViewParent2;			// 親スクロールビュー スクロールの可否を切り替える
}

@property(nonatomic, retain) UIScrollView	*scrollViewParent2;
@end
