//
//  VideoPreviewViewController.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/12/10.
//
//

#import "VideoPreviewViewController.h"
#import "MovieResource.h"

@interface VideoPreviewViewController ()

@end

@implementation VideoPreviewViewController
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/
- (id)init {
    self = [super init];
    if (self) {
        slider = [[SingleSlider alloc] init];
        player = [[PreviewPlayerView alloc] init];
        player.playerDelegate = slider;
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        self.view.userInteractionEnabled = YES;
    }
    return self;
}
- (void)setMovie:(MovieResource *)_movie {
    movie = _movie;
    if(movie.movieIsExistsInCash) {
        [player setVideoUrl:[[NSURL alloc] initFileURLWithPath:movie.movieCashPath]];
    } else {
        [player setVideoUrl:movie.movieURL];
    }
//    [player setVideoUrl:movie.movieURL];
    self.view.hidden = NO;
    [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}
- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window == nil) {
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    }
    [window.rootViewController.view addSubview:self.view];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.view addSubview:slider];
    [self.view addSubview:player];
}
- (void)viewWillAppear:(BOOL)animated {
    [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}
- (void) didRotate:(NSNotification *)notification {
    UIDeviceOrientation orient = [(UIDevice *)[notification object] orientation];
    [self willRotateToInterfaceOrientation:orient duration:0];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect appFrame = [UIScreen mainScreen].bounds;
    CGSize naturalSize = [MovieResource naturalSizeOfAVPlayer:player.player];
    CGFloat playerW = 0.0f;
    CGFloat playerH = 0.0f;
    if (naturalSize.width < naturalSize.height) {
        playerW = 600.0f * naturalSize.width / naturalSize.height;
        playerH = 600.0f;
    } else {
        playerW = 600.0f;
        playerH = 600.0f * naturalSize.height / naturalSize.width;
    }
#ifdef DEBUG
    NSLog(@"%s  %f",__func__, [UIScreen mainScreen].applicationFrame.size.width);
#endif
    if (UIDeviceOrientationIsPortrait(self.interfaceOrientation)){
        
        // 縦向け
        self.view.frame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height);
        player.frame = CGRectMake((appFrame.size.width - playerW) * 0.5f,
                                  (appFrame.size.height - playerH) * 0.5f - 120,
                                  playerW, playerH);
    } else {
        
        self.view.frame = CGRectMake(0, 0, appFrame.size.height, appFrame.size.width);
        player.frame = CGRectMake((appFrame.size.height - playerW) * 0.5f,
                                  (appFrame.size.width - playerH) * 0.5f - 40,
                                  playerW, playerH);
    }
    slider.frame = CGRectMake(player.frame.origin.x,
                              player.frame.origin.y + player.frame.size.height,
                              player.frame.size.width, 30);
    slider.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.9f];
    self.view.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.6];
    [player setRunButton];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //[self.view removeFromSuperview];
    [player pause];
    self.view.hidden = YES;
}
- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    //[player removeFromSuperview];
    [slider removeFromSuperview];
    //[player pause];
    [player release];
    if (movie) {
        [movie release];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
@end
