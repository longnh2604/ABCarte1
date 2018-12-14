//
//  VideoPreviewWideViewController.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/12/20.
//
//

#import "VideoPreviewWideViewController.h"
#import "MovieResource.h"

@interface VideoPreviewWideViewController ()

@end

@implementation VideoPreviewWideViewController
- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    closeButton.frame = CGRectMake(0, 0, 48, 48);
    [self.view addSubview:closeButton];
    [closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchDown];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    CGRect appFrame = [UIScreen mainScreen].applicationFrame;
    CGSize naturalSize = [MovieResource naturalSizeOfAVPlayer:player.player];
    NSLog(@"%s  %f",__func__, [UIScreen mainScreen].applicationFrame.size.width);
    
    if (UIDeviceOrientationIsPortrait(self.interfaceOrientation)){
        // 縦向け
        self.view.frame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height);
        // スライダーと戻るボタンの為に下に30と60空ける
        CGSize pSize = CGSizeMake(appFrame.size.width - 48, appFrame.size.height - 30 - 48);
        //if (naturalSize.width / naturalSize.height > pSize.width / pSize.height) {
        if (naturalSize.width * pSize.height > pSize.width * naturalSize.height) {
            CGFloat width = pSize.width;
            CGFloat height = pSize.width * naturalSize.height / naturalSize.width;
            player.frame = CGRectMake(24 , (appFrame.size.height - 30 - height) * 0.5f,
                                      width, height);
        } else {
            CGFloat width = pSize.height * naturalSize.width / naturalSize.height;
            CGFloat height = pSize.height;
            player.frame = CGRectMake( (appFrame.size.width - width) * 0.5f, 24,
                                      width, height);
        }
    } else {
        self.view.frame = CGRectMake(0, 0, appFrame.size.height, appFrame.size.width);
        // スライダーと戻るボタンの為に下に30と左に60空ける
        CGSize pSize = CGSizeMake(appFrame.size.height - 48, appFrame.size.width - 30 - 48);
        //if (naturalSize.width / naturalSize.height > pSize.width / pSize.height) {
        if (naturalSize.width * pSize.height > pSize.width * naturalSize.height) {
            CGFloat width = pSize.width;
            CGFloat height = pSize.width * naturalSize.height / naturalSize.width;
            player.frame = CGRectMake(24, (appFrame.size.width - 30 - height) * 0.5f,
                                      width, height);
        } else {
            CGFloat width = pSize.height * naturalSize.width / naturalSize.height;
            CGFloat height = pSize.height;
            player.frame = CGRectMake((appFrame.size.height - width) * 0.5f, (appFrame.size.width - 30 - height) * 0.5f,
                                      width, height);
        }
    }
    closeButton.center = CGPointMake(player.frame.origin.x + player.frame.size.width, player.frame.origin.y);
    slider.frame = CGRectMake(player.frame.origin.x,
                              player.frame.origin.y + player.frame.size.height,
                              player.frame.size.width, 30);
    slider.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    self.view.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.6];
    [player setRunButton];
    // オーバーレイ
    if (!overlayView) {
        UIImage *overlayImage = movie.overlayImage;
        if (!overlayImage) {
            NSLog(@"オーバーレイ画像未ダウンロード");
        }
        overlayView = [[UIImageView alloc] initWithImage:overlayImage];
    }
    overlayView.frame = CGRectMake(0, 0, player.frame.size.width, player.frame.size.height);
    [player addSubview:overlayView];
}
- (void)close {
    [player pause];
    self.view.hidden = YES;
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // タッチでは消さない
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)dealloc {
    //[closeButton removeFromSuperview];
    [closeButton release];
    [super dealloc];
}
@end
