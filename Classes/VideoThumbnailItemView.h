//
//  VideoThumbnailItemView.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/11/18.
//
//

#import "OKDThumbnailItemView.h"

@protocol VideoThumbnailItemViewDelegate;

@interface VideoThumbnailItemView : OKDThumbnailItemView
@property(nonatomic, retain) UIImageView *overlayIV;
@property(nonatomic, retain) UIImageView *videoIcon;
@property(nonatomic, retain) UIImageView *cloudIcon;
@property(nonatomic, retain) UILabel *lbl;
@end
@protocol VideoThumbnailItemViewDelegate <OKDThumbnailItemViewDelegate>
@optional
- (void)doubleTapVideoThumbnail:(NSURL *)url;
@end
