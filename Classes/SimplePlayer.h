//
//  SimplePlayer.h
//
//  Created by 捧 隆二 on 2013/09/29.
//  Copyright (c) 2013年 捧 隆二. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SimplePlayer : UIView {
    
    UIView *playerView;
    AVPlayerLayer *playerLayer;
    AVPlayer *player;
    AVPlayerItem *_avPlayerItem;
    UISlider *slider;
    UIView *backV;
    BOOL ready;
    BOOL isPlay;
}
@property(nonatomic,retain) AVPlayer *player;
@property(nonatomic) BOOL ready;
@property(nonatomic) CGFloat playRate;
@property(nonatomic) BOOL isSliderHidden;
- (void)setVideoUrl:(NSURL*)url;
@end
