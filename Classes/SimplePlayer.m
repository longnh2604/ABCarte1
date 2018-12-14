//
//  SimplePlayer.m
//
//  Created by 捧 隆二 on 2013/09/29.
//  Copyright (c) 2013年 捧 隆二. All rights reserved.
//
//   PlayerLayer
//  PlayerView
// ScrollView
#import "SimplePlayer.h"

@implementation SimplePlayer

const int TIME_SCALE = 100;

@synthesize player, ready;
- (id)init{
    self = [super init];
    if (self) {
        ready = NO;
        isPlay = NO;
        backV = [[UIView alloc] init];
        backV.backgroundColor = [UIColor blackColor];
        
        slider = [[UISlider alloc] init];
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        slider.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    }
    return self;
}
- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    backV.frame = CGRectMake(0, 0, frame.size.width, frame.size.height - 30);
    playerLayer.frame = backV.frame;
    slider.frame = CGRectMake(0, frame.size.height - 30, frame.size.width, 30);
}
//動画の準備ができたらフラグをたてる
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"readyForDisplay"]) {
        [playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
        [player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        ready = YES;
        isPlay = NO;
        // 以前のsetSlider
        
        slider.minimumValue = .0f;
        slider.maximumValue = CMTimeGetSeconds(player.currentItem.duration) * TIME_SCALE;
        slider.value = .0f;
    }
}
- (void)setVideoUrl:(NSURL *)url{
    // 前の動画があれば除く
    NSArray *subviews =  self.subviews;
    for (UIView *subview in subviews) {
        [subview removeFromSuperview];
    }
    //video
    CGRect playerFrame = playerLayer.frame;
    ////player = nil;
    ////player = [AVPlayer playerWithURL:url];
    if  (! self.player){
        // player = [[AVPlayer alloc] init];
        // _avPlayerItem = [AVPlayerItem playerItemWithURL:url];
        _avPlayerItem = [[AVPlayerItem alloc] initWithURL:url];
        if (CMTimeGetSeconds(_avPlayerItem.duration) == 0) {
            return;
        }
        self.player = [AVPlayer playerWithPlayerItem:_avPlayerItem];
    } else {
        NSLog(@"okk");
        // 再利用時
        // TODO: 以下の処理により、プレビュー表示でexceptionが発生するので、保留する
        /*[playerLayer removeFromSuperlayer];
         [playerLayer release];
         playerLayer = nil;
         [_avPlayerItem release];
         [playerView removeFromSuperview];
         [playerView release];
         _avPlayerItem = nil;
         _avPlayerItem = [[AVPlayerItem alloc] initWithURL:url];
         [timer release];
         if (CMTimeGetSeconds(_avPlayerItem.duration) == 0) {
         return;
         }
         [player release];
         //player = nil;
         //player = [AVPlayer playerWithPlayerItem:_avPlayerItem];
         [player replaceCurrentItemWithPlayerItem:_avPlayerItem];*/
    }
    
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = playerFrame;
    playerView = [[UIView alloc] initWithFrame:playerFrame];
    playerView.backgroundColor = [UIColor blackColor];
    [self addSubview:backV];
    [backV addSubview:playerView];
    [playerView.layer addSublayer:playerLayer];
    [playerLayer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self addSubview:slider];
}

-(void)sliderValueChanged:(id)sender{
    // NSLog(@"slidervaluechanged");
    [player seekToTime:CMTimeMake(slider.value,TIME_SCALE) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)setIsSliderHidden:(BOOL)isSliderHidden {
    slider.hidden = isSliderHidden;
}
- (BOOL)isSliderHidden {
    return slider.hidden;
}
- (void)dealloc {
    //if (player){
    [player pause];
    
    //[playerLayer removeFromSuperlayer];
    [playerLayer release];
    [playerView removeFromSuperview];
    //playerLayer = nil;
    //[playerView release];
    [_avPlayerItem release];
    [player release];
    [slider release];
    
    //player = nil;
    //[self.playerDelegate release];
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
    //}
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}
@end