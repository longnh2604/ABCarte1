//
//  VideoPreviewViewController.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/12/10.
//
//

#import <UIKit/UIKit.h>
#import "PreviewPlayerView.h"
#import "SingleSlider.h"
#import "MovieResource.h"

@interface VideoPreviewViewController : UIViewController {
    PreviewPlayerView *player;
    SingleSlider *slider;
    MovieResource *movie;
    UIImageView *overlayView;
}
- (void)setMovie:(MovieResource *)_movie;
- (void)show;
@end
